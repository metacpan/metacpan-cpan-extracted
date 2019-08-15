/* runcap - run program and capture its output
   Copyright (C) 2017 Sergey Poznyakoff

   Runcap is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the
   Free Software Foundation; either version 3 of the License, or (at your
   option) any later version.

   Runcap is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along
   with Runcap. If not, see <http://www.gnu.org/licenses/>. */

#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <sys/select.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>

#include "runcap.h"

int
stream_capture_init(struct stream_capture *cap, size_t size)
{
	if (!cap) {
		errno = EINVAL;
		return -1;
	}

	if (size) {
		cap->sc_base = malloc(size);
		if (!cap->sc_base)
			return -1;
	} else
		cap->sc_base = NULL;
	cap->sc_size = size;
	cap->sc_leng = 0;
	cap->sc_level = 0;
	cap->sc_nlines = 0;
	cap->sc_cur = 0;
	cap->sc_storfd = -1;
	cap->sc_fd = -1;
	return 0;
}

static void
stream_capture_reset(struct stream_capture *cap)
{
	cap->sc_leng = 0;
	cap->sc_level = 0;
	cap->sc_nlines = 0;
	cap->sc_cur = 0;

	if (cap->sc_storfd >= 0) {
		close(cap->sc_storfd);
		cap->sc_storfd = -1;
	}
	if (cap->sc_fd >= 0) {
		close(cap->sc_fd);
		cap->sc_fd = -1;
	}
}

void
stream_capture_free(struct stream_capture *cap)
{
	stream_capture_reset(cap);
	free(cap->sc_base);
	cap->sc_base = NULL;
	cap->sc_size = 0;

	cap->sc_linemon = NULL;
	cap->sc_monarg = NULL;
}

static int
full_write(int fd, char *buf, size_t size)
{
	while (size) {
		ssize_t n = write(fd, buf, size);
		if (n == -1)
			return -1;
		if (n == 0) {
			errno = ENOSPC;
			return -1;
		}
		buf += n;
		size -= n;
	}
	return 0;
}

static int
stream_capture_flush(struct stream_capture *cap)
{
	int res;
		
	if (cap->sc_level == 0)
		return 0;
	if (cap->sc_linemon && cap->sc_cur < cap->sc_level)
		cap->sc_linemon(cap->sc_base + cap->sc_cur,
				cap->sc_level - cap->sc_cur,
				cap->sc_monarg);
	if (cap->sc_storfd == -1) {
		int fd;
		char tmpl[] = "/tmp/rcXXXXXX";
		fd = mkstemp(tmpl);
		if (fd == -1)
			return -1;
		unlink(tmpl);
		cap->sc_storfd = fd;
	}
	res = full_write(cap->sc_storfd, cap->sc_base, cap->sc_level);
	if (res)
		return -1;
	cap->sc_level = 0;
	cap->sc_cur = 0;
	return 0;
}

static int
stream_capture_get(struct stream_capture *cap, int *feof)
{
	int rc;
	size_t i;
	
	if (cap->sc_level == cap->sc_size) {
		if (stream_capture_flush(cap))
			return -1;
	}
		
	rc = read(cap->sc_fd, cap->sc_base + cap->sc_level, cap->sc_size - cap->sc_level);
	if (rc == -1) {
	        if (errno == EINTR)
		      return 0;
		return -1;
	}
	if (rc == 0) {
		if (cap->sc_linemon && cap->sc_level > cap->sc_cur) {
			cap->sc_linemon(cap->sc_base + cap->sc_cur,
					cap->sc_level - cap->sc_cur,
					cap->sc_monarg);
			cap->sc_cur = cap->sc_level;
			cap->sc_nlines++;
		}
		*feof = 1;
		return 0;
	} else
		*feof = 0;

	i = cap->sc_level;

	cap->sc_level += rc;
	cap->sc_leng  += rc;
	
	for (; i < cap->sc_level; i++) {
		if (cap->sc_base[i] == '\n') {
			if (cap->sc_linemon)
				cap->sc_linemon(cap->sc_base + cap->sc_cur,
						i - cap->sc_cur + 1,
						cap->sc_monarg);
			cap->sc_cur = i + 1;
			cap->sc_nlines++;
		}
	}
	

	return 0;
}

static int
stream_capture_put(struct stream_capture *cap, int *feof)
{
	if (cap->sc_cur < cap->sc_level) {
		int n = write(cap->sc_fd, &cap->sc_base[cap->sc_cur], 1);
		if (n == -1) {
		        if (errno == EINTR)
			      return 0;
			return -1;
		}
		if (n == 0) {
			errno = ENOSPC;
			return -1;
		}
		cap->sc_cur++;
	}
	*feof = cap->sc_cur == cap->sc_level;
	return 0;
}

void
runcap_free(struct runcap *rc)
{
	stream_capture_free(&rc->rc_cap[RUNCAP_STDIN]);
	stream_capture_free(&rc->rc_cap[RUNCAP_STDOUT]);
	stream_capture_free(&rc->rc_cap[RUNCAP_STDERR]);
}

static inline int
timeval_after(struct timeval const *a, struct timeval const *b)
{
	if (a->tv_sec == b->tv_sec)
		return a->tv_usec < b->tv_usec;
	else
		return a->tv_sec < b->tv_sec;
}

static inline struct timeval
timeval_diff(struct timeval const *a, struct timeval const *b)
{
	struct timeval res;

	res.tv_sec = a->tv_sec - b->tv_sec;
	res.tv_usec = a->tv_usec - b->tv_usec;
	if (res.tv_usec < 0) {
		--res.tv_sec;
		res.tv_usec += 1000000;
	}

	return res;
}

static int
runcap_start(struct runcap *rc)
{
	int p[RUNCAP_NBUF][2] = { { -1, -1}, { -1, -1 }, { -1, -1 } };
	int i;
	
	for (i = 0; i < RUNCAP_NBUF; i++)
		if (rc->rc_cap[i].sc_size) {
			if (pipe(p[i])) {
				goto err;
			}
		}

	switch (rc->rc_pid = fork()) {
	case 0: /* Child */
		if (p[RUNCAP_STDIN][0] >= 0) {
			dup2(p[RUNCAP_STDIN][0], RUNCAP_STDIN);
			close(p[RUNCAP_STDIN][1]);
		} else if (rc->rc_cap[RUNCAP_STDIN].sc_fd >= 0) {
			dup2(rc->rc_cap[RUNCAP_STDIN].sc_fd, RUNCAP_STDIN);
		}

		if (p[RUNCAP_STDOUT][0] >= 0) {
			dup2(p[RUNCAP_STDOUT][1], RUNCAP_STDOUT);
			close(p[RUNCAP_STDOUT][0]);
		}
		
		if (p[RUNCAP_STDERR][0] >= 0) {
			dup2(p[RUNCAP_STDERR][1], RUNCAP_STDERR);
			close(p[RUNCAP_STDERR][0]);
		}

		i = open("/dev/null", O_RDONLY);
		if (i == -1)
			i = sysconf(_SC_OPEN_MAX) - 1;
		while (i > RUNCAP_STDERR) {
			close(i);
			i--;
		}

		execvp(rc->rc_program ? rc->rc_program : rc->rc_argv[0],
		       rc->rc_argv);
		_exit(127);

		/* Parent branches */
	case -1:
		break;
		
	default:
		if (p[RUNCAP_STDIN][0] >= 0) {
			close(p[RUNCAP_STDIN][0]);
			rc->rc_cap[RUNCAP_STDIN].sc_fd = p[RUNCAP_STDIN][1];
		}
		if (p[RUNCAP_STDOUT][0] >= 0) {
			close(p[RUNCAP_STDOUT][1]);
			rc->rc_cap[RUNCAP_STDOUT].sc_fd = p[RUNCAP_STDOUT][0];
		}
		if (p[RUNCAP_STDERR][0] >= 0) {
			close(p[RUNCAP_STDERR][1]);
			rc->rc_cap[RUNCAP_STDERR].sc_fd = p[RUNCAP_STDERR][0];
		}
		return 0;
	}
  err:
	rc->rc_errno = errno;
	for (i = 0; i < RUNCAP_NBUF; i++) {
		close(p[i][0]);
		close(p[i][1]);
	}
	return -1;
}

static void
runcap_loop(struct runcap *rc)
{
	int nfd;
	fd_set rds, wrs;
	struct timeval finish, tv, *tvp;
		
	gettimeofday(&finish, NULL);
	finish.tv_sec += rc->rc_timeout;

	while (1) {
		int nready;
		int eof;

		nfd = -1;
		FD_ZERO(&rds);
		FD_ZERO(&wrs);

		if (rc->rc_cap[RUNCAP_STDIN].sc_size
		    && rc->rc_cap[RUNCAP_STDIN].sc_fd >= 0) {
			nfd = rc->rc_cap[RUNCAP_STDIN].sc_fd;
			FD_SET(rc->rc_cap[RUNCAP_STDIN].sc_fd, &wrs);
		}
		if (rc->rc_cap[RUNCAP_STDOUT].sc_fd >= 0) {
			if (rc->rc_cap[RUNCAP_STDOUT].sc_fd > nfd)
				nfd = rc->rc_cap[RUNCAP_STDOUT].sc_fd;
			FD_SET(rc->rc_cap[RUNCAP_STDOUT].sc_fd, &rds);
		}
		if (rc->rc_cap[RUNCAP_STDERR].sc_fd >= 0) {
			if (rc->rc_cap[RUNCAP_STDERR].sc_fd > nfd)
				nfd = rc->rc_cap[RUNCAP_STDERR].sc_fd;
			FD_SET(rc->rc_cap[RUNCAP_STDERR].sc_fd, &rds);
		}
		nfd++;

		if (rc->rc_pid != (pid_t) -1) {
			int flags = WNOHANG;
			pid_t pid;

			if (nfd == 0 && rc->rc_timeout == 0)
				flags = 0;
			pid = waitpid(rc->rc_pid, &rc->rc_status, flags);
			if (pid == -1) {
			        if (errno == EINTR)
				      continue;
				rc->rc_errno = errno;
				kill(rc->rc_pid, SIGKILL);
				break;
			}
			if (pid == rc->rc_pid)
				rc->rc_pid = (pid_t) -1;
		}

		if (nfd == 0 && rc->rc_pid == (pid_t) -1)
			break;
		
		if (rc->rc_timeout) {
			struct timeval now;
			gettimeofday(&now, NULL);
			tv = timeval_diff(&finish, &now);
			if (!timeval_after(&now, &finish)) {
				if (rc->rc_pid == (time_t) -1)
					break;
				kill(rc->rc_pid, SIGKILL);
				rc->rc_errno = ETIMEDOUT;
				continue;
			}
			tvp = &tv;
		} else {
			tvp = NULL;
		}

		nready = select(nfd, &rds, &wrs, NULL, tvp);
		if (nready == 0) {
			if (rc->rc_status)
				break;
			continue;
		}
		if (nready == -1) {
			if (errno == EINTR || errno == EAGAIN)
				/* retry */;
			else {
				rc->rc_errno = errno;
				break;
			}
			continue;
		}

		if (rc->rc_cap[RUNCAP_STDIN].sc_fd >= 0
		    && FD_ISSET(rc->rc_cap[RUNCAP_STDIN].sc_fd, &wrs)) {
			if (stream_capture_put(&rc->rc_cap[RUNCAP_STDIN], &eof)) {
				rc->rc_errno = errno;
				break;
			}
			if (eof) {
				/* FIXME: */
				close(rc->rc_cap[RUNCAP_STDIN].sc_fd);
				rc->rc_cap[RUNCAP_STDIN].sc_fd = -1;
			}
		}
		
		if (rc->rc_cap[RUNCAP_STDOUT].sc_fd >= 0
		    && FD_ISSET(rc->rc_cap[RUNCAP_STDOUT].sc_fd, &rds)) {
			if (stream_capture_get(&rc->rc_cap[RUNCAP_STDOUT], &eof)) {
				rc->rc_errno = errno;
				break;
			}
			if (eof) {
				close(rc->rc_cap[RUNCAP_STDOUT].sc_fd);
				rc->rc_cap[RUNCAP_STDOUT].sc_fd = -1;
			}
		}
		if (rc->rc_cap[RUNCAP_STDERR].sc_fd >= 0
		    && FD_ISSET(rc->rc_cap[RUNCAP_STDERR].sc_fd, &rds)) {
			if (stream_capture_get(&rc->rc_cap[RUNCAP_STDERR], &eof)) {
				rc->rc_errno = errno;
				break;
			}
			if (eof) {
				close(rc->rc_cap[RUNCAP_STDERR].sc_fd);
				rc->rc_cap[RUNCAP_STDERR].sc_fd = -1;
			}
		}
	}

	if (rc->rc_pid != (pid_t)-1) {
		kill(rc->rc_pid, SIGKILL);
		waitpid(rc->rc_pid, &rc->rc_status, 0);
		rc->rc_pid = (pid_t) -1;
	}
}

static int
runcap_init(struct runcap *rc, int flags)
{
	int res;
	
	if (!(flags & RCF_PROGRAM))
		rc->rc_program = NULL;
	if (!(flags & RCF_TIMEOUT))
		rc->rc_timeout = 0;

	if (flags & RCF_STDIN) {
		if (rc->rc_cap[RUNCAP_STDIN].sc_size > 0
		    && rc->rc_cap[RUNCAP_STDIN].sc_fd != -1) {
			errno = EINVAL;
			return -1;
		}
		rc->rc_cap[RUNCAP_STDIN].sc_level =
			rc->rc_cap[RUNCAP_STDIN].sc_size;
		rc->rc_cap[RUNCAP_STDIN].sc_cur = 0;
		rc->rc_cap[RUNCAP_STDIN].sc_storfd = -1;
	} else if (stream_capture_init(&rc->rc_cap[RUNCAP_STDIN], 0))
		return -1;
	
	res = stream_capture_init(&rc->rc_cap[RUNCAP_STDOUT],
				  (flags & RCF_STDOUT_SIZE)
				    ? rc->rc_cap[RUNCAP_STDOUT].sc_size
				    : STRCAP_BUFSIZE);
	if (res)
		return res;
	
	if (!(flags & RCF_STDOUT_LINEMON)) {
		rc->rc_cap[RUNCAP_STDOUT].sc_linemon = NULL;
		rc->rc_cap[RUNCAP_STDOUT].sc_monarg = NULL;
	}
	
	res = stream_capture_init(&rc->rc_cap[RUNCAP_STDERR],
				  (flags & RCF_STDERR_SIZE)
				    ? rc->rc_cap[RUNCAP_STDERR].sc_size
				    : STRCAP_BUFSIZE);
	if (res)
		return res;

	if (!(flags & RCF_STDERR_LINEMON)) {
		rc->rc_cap[RUNCAP_STDERR].sc_linemon = NULL;
		rc->rc_cap[RUNCAP_STDERR].sc_monarg = NULL;
	}
	
	rc->rc_pid = (pid_t) -1;
	rc->rc_status = 0;
	rc->rc_errno = 0;

	return 0;
}

static void
set_signals(void (*handler)(int signo), int sigc, int *sigv,
	    struct sigaction *oldact)
{
	int i;
	struct sigaction act;

	act.sa_flags = 0;
	sigemptyset(&act.sa_mask);
	for (i = 0; i < sigc; i++)
		sigaddset(&act.sa_mask, i);

	for (i = 0; i < sigc; i++) {
		act.sa_handler = handler;
		sigaction(sigv[i], &act, &oldact[i]);
	}
}

static void
restore_signals(int sigc, int *sigv, struct sigaction *oldact)
{
	int i;
	for (i = 0; i < sigc; i++)
		sigaction(sigv[i], &oldact[i], NULL);
}	

static void
sighan(int signo)
{
	/* nothing */
}

int
runcap(struct runcap *rc, int flags)
{
	int sig[] = { SIGCHLD, SIGPIPE };
#define NUMSIGNALS (sizeof(sig)/sizeof(sig[0]))
	struct sigaction oldact[NUMSIGNALS];
	
	if (runcap_init(rc, flags)) {
		rc->rc_errno = errno;
		return -1;
	}
	
	set_signals(sighan, NUMSIGNALS, sig, oldact);
	if (runcap_start(rc) == 0)
		runcap_loop(rc);
	restore_signals(NUMSIGNALS, sig, oldact);
	if (rc->rc_errno == 0) {
		if (rc->rc_cap[RUNCAP_STDOUT].sc_storfd != -1) {
			stream_capture_flush(&rc->rc_cap[RUNCAP_STDOUT]);
			lseek(rc->rc_cap[RUNCAP_STDOUT].sc_storfd, 0, SEEK_SET);
		}
		if (rc->rc_cap[RUNCAP_STDERR].sc_storfd != -1) {
			stream_capture_flush(&rc->rc_cap[RUNCAP_STDERR]);
			lseek(rc->rc_cap[RUNCAP_STDERR].sc_storfd, 0, SEEK_SET);
		}
	}
	if (rc->rc_errno) {
		errno = rc->rc_errno;
		return -1;
	}
	runcap_rewind(rc, RUNCAP_STDOUT);
	runcap_rewind(rc, RUNCAP_STDERR);
	return 0;
}
	

