/* runcap - run program and capture its output
   Copyright (C) 2017-2024 Sergey Poznyakoff

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
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <errno.h>
#include <inttypes.h>
#include <assert.h>
#include "runcap.h"

static char *progname;

void
error(char const *fmt, ...)
{
	va_list ap;
	
	fprintf(stderr, "%s: ", progname);
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);
	fputc('\n', stderr);
}

void
usage(int code)
{
	FILE *fp = code ? stderr : stdout;
	fprintf(fp, "%s [OPTIONS] COMMAND [ARG...]\n", progname);
	fprintf(fp, "tests the runcap library\n");
	fprintf(fp, "OPTIONS are:\n\n");
	fprintf(fp, "  -S all|stderr|stdout   selects capture for the next -m, -N, or -s option\n");
	fprintf(fp, "  -e VAR=NAME            set environment variable\n");
	fprintf(fp, "  -e -VAR                unset environment variable\n");
	fprintf(fp, "  -e -                   clear environment (except for PATH,\n");
	fprintf(fp, "                         HOME, and LOGNAME)\n");
	fprintf(fp, "  -f FILE                reads stdin from FILE\n");
	fprintf(fp, "  -i                     inline read (use before -f)\n");
	fprintf(fp, "  -N                     disable capturing\n");
	fprintf(fp, "  -n all|stderr|stdout   print lines from the requested capture\n");
	fprintf(fp, "  -m                     monitors each line recevied from the program (see -S)\n");
	fprintf(fp, "  -p PROGNAME            sets program name to use instead of COMMAND\n");
	fprintf(fp, "  -r STREAM[:COUNT:OFF:WHENCE:FULL]\n");
	fprintf(fp, "                         read and print COUNT bytes from STREAM (stdout or\n");
	fprintf(fp, "                         stderr) starting from OFFset located using WHENCE\n");
	fprintf(fp, "                         (0, 1, 2).  Use runcap_getc if FULL is 't' and\n");
	fprintf(fp, "                         runcap_read if it is 'f'.  Default is MAX:0:0:f.\n");
	fprintf(fp, "  -s SIZE                sets capture size (see -S)\n");
	fprintf(fp, "  -t SECONDS             sets execution timeout\n");
	fputc('\n', fp);
	exit(code);
}

#define WA_NONE   0
#define WA_STDOUT 0x01
#define WA_STDERR 0x02
#define WA_ALL (WA_STDOUT|WA_STDERR)

static int
whatarg(char const *arg)
{
	if (strcmp(arg, "all") == 0)
		return WA_ALL;
	else if (strcmp(arg, "stdout") == 0)
		return WA_STDOUT;
	else if (strcmp(arg, "stderr") == 0)
		return WA_STDERR;
	error("unreconginzed option argument: %s", arg);
	exit(1);
}

struct linemon_closure
{
	char const *prefix;
	int cont;
};

static void
linemon(const char *ptr, size_t len, void *data)
{
	struct linemon_closure *clos = data;

	if (len) {
		if (!clos->cont) {
			printf("%s:", clos->prefix);
			if (!(len == 1 && ptr[0] == '\n'))
				putchar(' ');
		}
		fwrite(ptr, len, 1, stdout);
	} else
		fflush(stdout);
	clos->cont = !(len == 0 || ptr[len-1] == '\n');
}

static void
nl(struct runcap *rc, int stream)
{
	int width;
	size_t n;
	char *buf = NULL;
	size_t size = 0;
	ssize_t res;
	char const *what = stream == RUNCAP_STDOUT ? "stdout" : "stderr";
	
	for (n = rc->rc_cap[stream].sc_nlines, width = 1; n > 0; n /= 10)
		width++;

	printf("%s listing:\n", what);
	runcap_rewind(rc, stream);
	n = 1;
	while ((res = runcap_getline(rc, stream, &buf, &size)) > 0) {
		buf[res-1] = 0;
		printf("%*zu:", width, n);
		if (buf[0])
			printf(" %s", buf);
		putchar('\n');
		n++;
	}
	if (res)
		error("error getting lines: %s", strerror(errno));
	printf("%s listing ends\n", what);
}

struct readreq
{
	int what;
	unsigned long count;
	long off;
	int whence;
	int full;
};

void
readreq_parse(struct readreq *req, char *arg)
{
	char *s;
	int i = 0;

	s = strchr(arg, ':');
	if (s)
		*s++ = 0;
	req->what = whatarg(arg);
	req->count = 0;
	req->off = 0;
	req->whence = 0;
	req->full = 0;
	if (!s)
		return;
	arg = s;
	while (*arg) {
		switch (i++) {
		case 0:
			if (*arg == ':')
				s = arg;
			else
				req->count = strtoul(arg, &s, 10);
			break;

		case 1:
			if (*arg == ':')
				s = arg;
			else
				req->off = strtol(arg, &s, 10);
			break;

		case 2:
			if (*arg == ':')
				s = arg;
			else {
				req->whence = strtol(arg, &s, 10);
				if (!(0 <= req->whence && req->whence <= 2)) {
					error("bad whence: %s", arg);
					exit(1);
				}
			}
			break;

		case 3:
			if (*arg == 't')
				req->full = 1;
			else if (*arg == 'f')
				req->full = 0;
			else {
				error("bad full: %s", arg);
				exit(1);
			}
			s = arg + 1;
			break;
			
		default:
			error("too many parts in argument: %s", arg);
			exit(1);
		}
		
		if (*s == ':')
			arg = s + 1;
		else if (*s) {
			error("malformed argument: %s", arg);
			exit(1);
		} else
			arg = s;
	}
}

void
readreq_do(struct runcap *rc, struct readreq *req)
{
	int res;
	size_t i;
	
	if (runcap_seek(rc, req->what, req->off, req->whence) == -1) {
		perror("runcap_seek");
		exit(1);
	}

	if (req->count == 0) 
		req->count = rc->rc_cap[req->what].sc_leng;

	if (req->full) {
		char *buf = malloc(req->count);
		ssize_t n;

		assert(buf != NULL);

		n = runcap_read(rc, req->what, buf, req->count);
		if (n < 0) {
			perror("runcap_read");
			exit(1);
		}
		if (n > 0)
			fwrite(buf, n, 1, stdout);
		free(buf);
	} else {
		for (i = 0; i < req->count; i++) {
			char c;
		
			res = runcap_getc(rc, req->what, &c);
			if (res == 0) {
				error("unexpected eof at byte %zu\n", i);
				break;
			}
			if (res == -1) {
				error("%s at byte %zu\n", strerror(errno), i);
				break;
			}
			putchar(c);
		}
	}
}

void
open_outfile(char *file, int stream, struct runcap *rc, int *flags)
{
	int fd;

	fd = open(file, O_CREAT|O_TRUNC|O_RDWR, 0644);
	if (fd == -1) {
		error("can't open %s: %s\n", file, strerror(errno));
		exit(1);
	}
	rc->rc_cap[stream].sc_storfd = fd;
	*flags |= RCF_SC_TO_FLAG(RCF_SC_STORFD, stream);
}

static int
getenvind(char **env, char const *name)
{
        size_t i;
        for (i = 0; env[i]; i++) {
                char const *p;
                char *q;

                for (p = name, q = env[i]; *p == *q; p++, q++)
                        ;
                if (*p == 0 && *q == '=') {
                        return i;
                }
        }
        return -1;
}

char **
envdup(char **env)
{
	int i;
	char **new_env;

	for (i = 0; env[i]; i++)
		;

	new_env = calloc(i+1, sizeof(env[0]));
	assert(new_env != NULL);

	for (i = 0; env[i]; i++) {
		new_env[i] = strdup(env[i]);
		assert(new_env[i] != NULL);
	}
	new_env[i] = NULL;

	return new_env;
}

char **envupdate(char **, char *);

char **
envclear(char **env)
{
	int i, j;
	static char *keep[] = {
		"PATH",
		"HOME",
		"LOGNAME",
		NULL
	};
	char **new_env = calloc(1, sizeof(new_env[0]));
	assert(new_env != NULL);
	for (i = 0; keep[i]; i++) {
		j = getenvind(env, keep[i]);
		if (j != -1)
			new_env = envupdate(new_env, env[j]);
	}
	for (i = 0; env[i]; i++)
		free(env[i]);
	free(env);
	return new_env;
}

char **
envappend(char **env, char *arg)
{
	int i;

	for (i = 0; env[i]; i++)
		;
	env = realloc(env, (i+2) * sizeof(env[0]));
	assert(env != NULL);
	env[i] = strdup(arg);
	assert(env[i] != NULL);
	env[i+1] = NULL;
	return env;
}

char **
envdelete(char **env, char *arg)
{
	int i = getenvind(env, arg);
	if (i != -1) {
		int n;
		for (n = 0; env[n]; n++)
			;
		free(env[i]);
		memmove(env + i, env + i + 1, (n - i) * sizeof(env[0]));
	}
	return env;
}

extern char **environ;

char **
envupdate(char **env, char *arg)
{
	if (env == NULL)
		env = envdup(environ);
	if (*arg == '-') {
		if (arg[1] == 0)
			env = envclear(env);
		else
			env = envdelete(env, arg+1);
	} else {
		int i = getenvind(env, arg);
		if (i == -1)
			env = envappend(env, arg);
		else {
			free(env[i]);
			env[i] = strdup(arg);
			assert(env[i] != NULL);
		}
	}
	return env;
}

int
main(int argc, char **argv)
{
	struct runcap rc;
	int rcf = 0;
	int what = WA_ALL;
	int inopt = 0;
	int numlines = WA_NONE;
	struct readreq rq[10];
	int rqn = 0, i;
	
	int c;
	int fd;
	unsigned long size;

	static struct linemon_closure cl[] = {
		{ "stdout" },
		{ "stderr" }
	};

	char *outfile[RUNCAP_NBUF] = { NULL, NULL, NULL };
	
	progname = strrchr(argv[0], '/');
	if (progname)
		progname++;
	else
		progname = argv[0];
	memset(&rc, 0, sizeof(rc));
	while ((c = getopt(argc, argv, "?e:f:iNn:mo:p:r:S:s:t:")) != EOF) {
		switch (c) {
		case 'e':
			rc.rc_env = envupdate(rc.rc_env, optarg);
			rcf |= RCF_ENV;
			break;
		case 'f':
			fd = open(optarg, O_RDONLY);
			if (fd == -1) {
				error("can't open \"%s\": %s",
				      optarg, strerror(errno));
				exit(1);
			}
			if (inopt) {
				struct stat st;
				char *buffer;
				if (fstat(fd, &st)) {
					error("can't fstat \"%s\": %s",
					      optarg, strerror(errno));
					exit(1);
				}
				size = st.st_size;
				buffer = malloc(size + 1);
				assert(buffer != NULL);
				
				rc.rc_cap[RUNCAP_STDIN].sc_size = size;
				rc.rc_cap[RUNCAP_STDIN].sc_base = buffer;
				while (size) {
					ssize_t n = read(fd, buffer, size);
					if (n < 0) {
						error("error reading from \"%s\": %s",
						      optarg, strerror(errno));
						exit(1);
					}
					if (n == 0) {
						error("unexpected eof on \"%s\"",
						      optarg);
						exit(1);
					}
					size -= n;
					buffer += n;
				}
				close(fd);
				rc.rc_cap[RUNCAP_STDIN].sc_fd = -1;
			} else {				 
				rc.rc_cap[RUNCAP_STDIN].sc_fd = fd;
				rc.rc_cap[RUNCAP_STDIN].sc_size = 0;
			}
			rcf |= RCF_STDIN;
			break;
		case 'i':
			inopt = 1;
			break;
		case 'S':
			what = whatarg(optarg);
			break;
		case 'N':
			if (what & WA_STDOUT) {
				rcf |= RCF_STDOUT_NOCAP;
			}
			if (what & WA_STDERR) {
				rcf |= RCF_STDERR_NOCAP;
			}
			break;
		case 'o':
			if (what & WA_STDOUT) {
				outfile[RUNCAP_STDOUT] = optarg;
			}
			if (what & WA_STDERR) {
				outfile[RUNCAP_STDERR] = optarg;
			}
			break;
		case 'n':
			numlines = whatarg(optarg);
			break;
		case 'r':
			/* -r WHAT:N[:OFF:WHENCE:FULL] */
			if (rqn == sizeof(rq)/sizeof(rq[0])) {
				error("too many read requests");
				break;
			}
			readreq_parse(&rq[rqn++], optarg);
			break;
		case 'm':
			if (what & WA_STDOUT) {
				rc.rc_cap[RUNCAP_STDOUT].sc_linemon = linemon;
				rc.rc_cap[RUNCAP_STDOUT].sc_monarg =
					&cl[RUNCAP_STDOUT-1];
				rcf |= RCF_STDOUT_LINEMON;
			}
			if (what & WA_STDERR) {
				rc.rc_cap[RUNCAP_STDERR].sc_linemon = linemon;
				rc.rc_cap[RUNCAP_STDERR].sc_monarg =
					&cl[RUNCAP_STDERR-1];
				rcf |= RCF_STDERR_LINEMON;
			}
			break;
		case 'p':
			rc.rc_program = optarg;
			rcf |= RCF_PROGRAM;
			break;
		case 's':
			size = strtoul(optarg, NULL, 10);
			if (what & WA_STDOUT) {
				rc.rc_cap[RUNCAP_STDOUT].sc_size = size;
				rcf |= RCF_STDOUT_SIZE;
			}
			if (what & WA_STDERR) {
				rc.rc_cap[RUNCAP_STDERR].sc_size = size;
				rcf |= RCF_STDERR_SIZE;
			}
			break;
		case 't':
			rc.rc_timeout = strtoul(optarg, NULL, 10);
			rcf |= RCF_TIMEOUT;
			break;
		default:
			usage(optopt != '?');
		}
	}

	if (argc == optind) {
		static char *xargv[2];
		if (rcf & RCF_PROGRAM) {
			xargv[0] = rc.rc_program;
			xargv[1] = NULL;
			rc.rc_argv = xargv;
		} else
			usage(1);
	} else
		rc.rc_argv = argv + optind;

	if (outfile[RUNCAP_STDOUT])
		open_outfile(outfile[RUNCAP_STDOUT], RUNCAP_STDOUT, &rc, &rcf);
	if (outfile[RUNCAP_STDERR])
		open_outfile(outfile[RUNCAP_STDERR], RUNCAP_STDERR, &rc, &rcf);

	c = runcap(&rc, rcf);

	printf("res=%d\n", c);
	if (c) {
		error("system error: %s", strerror(rc.rc_errno));
		exit(1);
	}

	if (WIFEXITED(rc.rc_status)) {
                printf("exit code: %d\n", WEXITSTATUS(rc.rc_status));
        } else if (WIFSIGNALED(rc.rc_status)) {
                printf("got signal: %d\n", WTERMSIG(rc.rc_status));
        } else if (WIFSTOPPED(rc.rc_status)) {
                printf("stopped by signal %d\n", WSTOPSIG(rc.rc_status));
        } else
                printf("unrecognized status: %d\n", rc.rc_status);

	printf("stdout: %zu lines, %jd bytes\n",
               rc.rc_cap[RUNCAP_STDOUT].sc_nlines,
               (intmax_t)rc.rc_cap[RUNCAP_STDOUT].sc_leng);
        printf("stderr: %zu lines, %jd bytes\n",
               rc.rc_cap[RUNCAP_STDERR].sc_nlines,
               (intmax_t)rc.rc_cap[RUNCAP_STDERR].sc_leng);

	if (numlines & WA_STDOUT)
		nl(&rc, RUNCAP_STDOUT);
	if (numlines & WA_STDERR)
		nl(&rc, RUNCAP_STDERR);	

	for (i = 0; i < rqn; i++) {
		printf("READ %d:\n", i);
		readreq_do(&rc, &rq[i]);
		putchar('\n');
	}
			
	return 0;
}
