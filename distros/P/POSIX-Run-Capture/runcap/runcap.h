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

#ifndef _RUNCAP_H_
# define _RUNCAP_H_ 1

struct stream_capture
{
	int    sc_fd;        /* Input descriptor */
	char  *sc_base;      /* buffer space */
	size_t sc_size;      /* size of the buffer */
	size_t sc_level;     /* number of characters currently in buffer */
	size_t sc_cur;       /* current offset in buffer */
	off_t  sc_leng;      /* total length of captured data */
	size_t sc_nlines;    /* number of captured lines */
	int    sc_storfd;    /* Storage file descriptor */
	
	void (*sc_linemon)(const char *, size_t, void *);
  	                     /* Line monitor function */
	void  *sc_monarg;    /* Line monitor argument */
	int    sc_flags;     /* Stream flags */
};

#define STRCAP_BUFSIZE 4096

enum {
	RUNCAP_STDIN,
	RUNCAP_STDOUT,
	RUNCAP_STDERR,
	RUNCAP_NBUF
};

struct runcap
{
	char *rc_program; /* [IN] (Path)name of the program to run */ 
	char **rc_argv;   /* [IN] Argument vector */
	char **rc_env;    /* [IN] Environment variables */
	unsigned rc_timeout; /* [IN] Execution timeout */
	struct stream_capture rc_cap[RUNCAP_NBUF];
	/* rc_cap[RUNCAP_STDIN] - [IN], rest - [OUT] */
	pid_t rc_pid;     /* PID of the process */
	int rc_status;    /* [OUT] - Termination status */
	int rc_errno;     /* [OUT] - Value of errno, if terminated on error */
};

#define RCF_PROGRAM 0x0001 /* rc_program is set */
#define RCF_TIMEOUT 0x0002 /* rc_timeout is set */
#define RCF_STDIN   0x0004 /* rc_cap[RUNCAP_STDIN] is set */
#define RCF_ENV     0x0008 /* rc_env is set */

#define RCF_SC_SIZE        0x1 /* sc_size is set */
#define RCF_SC_LINEMON     0x2 /* sc_linemon is set*/
#define RCF_SC_NOCAP       0x4 /* capturing is disabled */
#define RCF_SC_STORFD      0x8 /* sc_storfd is set */

#define RCF_SC_TO_FLAG(f,s) ((f) << (4*(s)))
#define RCF_FLAG_TO_SC(f,s) (((f) >> (4*(s))) & 0xf)

#define RCF_STDOUT_SIZE    RCF_SC_TO_FLAG(RCF_SC_SIZE, RUNCAP_STDOUT)
#define RCF_STDOUT_LINEMON RCF_SC_TO_FLAG(RCF_SC_LINEMON, RUNCAP_STDOUT)
#define RCF_STDOUT_NOCAP   RCF_SC_TO_FLAG(RCF_SC_NOCAP, RUNCAP_STDOUT)
#define RCF_STDOUT_STORFD  RCF_SC_TO_FLAG(RCF_SC_STORFD, RUNCAP_STDOUT)

#define RCF_STDERR_SIZE    RCF_SC_TO_FLAG(RCF_SC_SIZE, RUNCAP_STDERR)
#define RCF_STDERR_LINEMON RCF_SC_TO_FLAG(RCF_SC_LINEMON, RUNCAP_STDERR)
#define RCF_STDERR_NOCAP   RCF_SC_TO_FLAG(RCF_SC_NOCAP, RUNCAP_STDERR)
#define RCF_STDERR_STORFD  RCF_SC_TO_FLAG(RCF_SC_STORFD, RUNCAP_STDERR)

int runcap(struct runcap *rc, int flags);
void runcap_free(struct runcap *rc);

static inline struct stream_capture *
runcap_get_capture(struct runcap *rc, int stream)
{
	struct stream_capture *fp;
	
	if (stream != RUNCAP_STDOUT && stream != RUNCAP_STDERR) {
		errno = EINVAL;
		return NULL;
	}

	fp = &rc->rc_cap[stream];
	
	if (!fp->sc_base || fp->sc_size == 0 || (fp->sc_flags & RCF_SC_NOCAP)) {
		errno = EINVAL;
		return NULL;
	}
	return fp;
}

ssize_t runcap_read(struct runcap *rc, int sd, char *buf, size_t size);
int runcap_getc(struct runcap *rc, int stream, char *cp);
ssize_t runcap_getline(struct runcap *rc, int stream, char **pstr, size_t *psize);
off_t runcap_tell(struct runcap *rc, int stream);
off_t runcap_seek(struct runcap *rc, int stream, off_t off, int whence);

static inline int
runcap_rewind(struct runcap *rc, int stream)
{
	return runcap_seek(rc, stream, 0, 0) != 0;
}	

#endif
