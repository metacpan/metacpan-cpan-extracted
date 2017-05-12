/*
 * Copyright (C) 2003  Sam Horrocks
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 */

#include "perperl.h"

static struct timeval saved_time;
static int my_euid = -1;
static int saved_pid;
#ifdef PERPERL_DEBUG
static int savecore;
#endif

extern char **environ;

int perperl_util_pref_fd(int oldfd, int newfd) {
    if (newfd == oldfd || newfd == PREF_FD_DONTCARE || oldfd == -1)
	return oldfd;
    (void) dup2(oldfd, newfd);
    (void) close(oldfd);
    return newfd;
}

#ifdef PERPERL_PROFILING
static void end_profiling(int dowrites) {
    char *cwd;
    
    if (dowrites)
	cwd = getcwd(NULL, 0);

    mkdir(PERPERL_PROFILING, 0777);
    chdir(PERPERL_PROFILING);

    if (dowrites) {
	_mcleanup();
	__bb_exit_func();
	chdir(cwd);
	free(cwd);
    }
}
#endif

PERPERL_INLINE int perperl_util_geteuid(void) {
    if (my_euid == -1)
	my_euid = geteuid();
    return my_euid;
}

#ifdef IAMSUID
int perperl_util_seteuid(int id) {
    int retval = seteuid(id);
    if (retval != -1)
	my_euid = id;
    return retval;
}
#endif

PERPERL_INLINE int perperl_util_getuid(void) {
    static int uid = -1;
    if (uid == -1)
	uid = getuid();
    return uid;
}

#ifdef PERPERL_BACKEND
int perperl_util_argc(const char * const * argv) {
    int retval;
    for (retval = 0; *argv++; ++retval) 
	;
    return retval;
}
#endif

PERPERL_INLINE int perperl_util_getpid(void) {
    if (!saved_pid) saved_pid = getpid();
    return saved_pid;
}

void perperl_util_pid_invalidate(void) {
    saved_pid = 0;
}

static void just_die(const char *fmt, va_list ap) {
    char buf[2048];

    sprintf(buf, "%s[%u]: ", PERPERL_PROGNAME, (int)getpid());
    vsprintf(buf + strlen(buf), fmt, ap);
    if (errno) {
	strcat(buf, ": ");
	strcat(buf, strerror(errno));
    }
    strcat(buf, "\n");
#   ifdef PERPERL_DEBUG
	savecore = 1;
#   endif
    perperl_abort(buf);
}

void perperl_util_die(const char *fmt, ...) {
    va_list ap;

    va_start(ap, fmt);
    just_die(fmt, ap);
    va_end(ap);
}

void perperl_util_die_quiet(const char *fmt, ...) {
    va_list ap;

    errno = 0;
    va_start(ap, fmt);
    just_die(fmt, ap);
    va_end(ap);
}

int perperl_util_execvp(const char *filename, const char *const *argv) {

    /* Get original argv */
    environ = (char **)perperl_opt_exec_envp();

#ifdef PERPERL_PROFILING
    end_profiling(1);
#endif

    /* Exec the backend */
    return perperl_execvp(filename, argv);
}

char *perperl_util_strndup(const char *s, int len) {
    char *buf;
    perperl_new(buf, len+1, char);
    perperl_memcpy(buf, s, len);
    buf[len] = '\0';
    return buf;
}

PERPERL_INLINE void perperl_util_gettimeofday(struct timeval *tv) {
    if (!saved_time.tv_sec)
	gettimeofday(&saved_time, NULL);
    *tv = saved_time;
}

PERPERL_INLINE int perperl_util_time(void) {
    struct timeval tv;
    perperl_util_gettimeofday(&tv);
    return tv.tv_sec;
}

void perperl_util_time_invalidate(void) {
    saved_time.tv_sec = 0;
}

char *perperl_util_fname(int num, char type) {
    char *fname;
    int uid = perperl_util_getuid(), euid = perperl_util_geteuid();

    perperl_new(fname, strlen(OPTVAL_TMPBASE) + 80, char);

    if (euid == uid)
	sprintf(fname, "%s.%x.%x.%c", OPTVAL_TMPBASE, num, euid, type);
    else
	sprintf(fname, "%s.%x.%x.%x.%c", OPTVAL_TMPBASE, num, euid, uid, type);

    return fname;
}

char *perperl_util_getcwd(void) {
    char *buf, *cwd_ret;
    int size = 512, too_small;

    /* TEST - see if memory alloc works */
    /* size = 10; */

    while (1) {
	perperl_new(buf, size, char);
	cwd_ret = getcwd(buf, size);

	/* TEST - simulate getcwd failure due to unreable directory */
	/* cwd_ret = NULL; errno = EACCES; */

	if (cwd_ret != NULL)
	    break;

	/* Must test errno here in case perperl_free overwrites it */
	too_small = (errno == ERANGE);

	perperl_free(buf);

	if (!too_small)
	    break;

	size *= 2;
    }
    return cwd_ret;
}

void perperl_util_mapout(PersistentMapInfo *mi) {
    if (mi->addr) {
	if (mi->is_mmaped)
	    (void) munmap(mi->addr, mi->maplen);
	else
	    perperl_free(mi->addr);
	mi->addr = NULL;
    }
    perperl_free(mi);
}

static int readall(int fd, void *addr, int len) {
    int numread, n;

    for (numread = 0; len - numread; numread += n) {
	n = read(fd, ((char*)addr) + numread, len - numread);
	if (n == -1)
	    return -1;
	if (n == 0)
	    break;
    }
    return numread;
}

PersistentMapInfo *perperl_util_mapin(int fd, int max_size, int file_size)
{
    PersistentMapInfo *mi;
    
    perperl_new(mi, 1, PersistentMapInfo);

    if (file_size) {
	mi->maplen = max_size == -1 ? file_size : min(file_size, max_size);
	mi->addr = mmap(0, mi->maplen, PROT_READ, MAP_SHARED, fd, 0);
	mi->is_mmaped = (mi->addr != (void*)MAP_FAILED);

	if (!mi->is_mmaped) {
	    perperl_new(mi->addr, mi->maplen, char);
	    lseek(fd, 0, SEEK_SET);
	    mi->maplen = readall(fd, mi->addr, mi->maplen);
	    if (mi->maplen == -1) {
		perperl_util_mapout(mi);
		return NULL;
	    }
	}
    } else {
	mi->maplen = 0;
	mi->addr = NULL;
	mi->is_mmaped = 0;
    }
    return mi;
}

PERPERL_INLINE PersistentDevIno perperl_util_stat_devino(const struct stat *stbuf) {
    PersistentDevIno retval;
    retval.d = stbuf->st_dev;
    retval.i = stbuf->st_ino;
    return retval;
}

PERPERL_INLINE int perperl_util_open_stat(const char *path, struct stat *stbuf)
{
    int fd = open(path, O_RDONLY);
    if (fd != -1 && fstat(fd, stbuf) == -1) {
       close(fd);
       fd = -1;
    }
    return fd;
}

void perperl_util_exit(int status, int underbar_exit) {

#   ifdef PERPERL_PROFILING
	end_profiling(underbar_exit);
#   endif

#   ifdef PERPERL_DEBUG
	if (savecore) {
	    char buf[200];
	    struct timeval tv;

	    mkdir("/tmp/perperl_core", 0777);
	    gettimeofday(&tv, NULL);
	    sprintf(buf, "/tmp/perperl_core/%s.%d.%06d.%d", PERPERL_PROGNAME, (int)tv.tv_sec, (int)tv.tv_usec, getpid());
	    mkdir(buf, 0777);
	    chdir(buf);
	    kill(getpid(), SIGFPE);
	}
#   endif

    if (underbar_exit)
	_exit(status);
    else
	exit(status);
}

int perperl_util_kill(pid_t pid, int sig) {
    return pid
	? (pid == perperl_util_getpid() ? 0 : kill(pid, sig))
	: -1;
}
