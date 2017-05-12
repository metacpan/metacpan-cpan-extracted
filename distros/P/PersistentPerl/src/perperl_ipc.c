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

#ifdef ENOBUFS
#   define NO_BUFSPC(e) ((e) == ENOBUFS || (e) == ENOMEM)
#else
#   define NO_BUFSPC(e) ((e) == ENOMEM)
#endif

static char *get_fname(slotnum_t slotnum, int do_unlink) {
    char *fname = perperl_util_fname(slotnum, 'S');
    if (do_unlink)
	unlink(fname);
    return fname;
}

static void make_sockname(
    slotnum_t slotnum, struct sockaddr_un *sa, int do_unlink
)
{
    char *fname = get_fname(slotnum, do_unlink);
    perperl_bzero(sa, sizeof(*sa));
    sa->sun_family = AF_UNIX;
    if (strlen(fname)+1 > sizeof(sa->sun_path))
	DIE_QUIET("Socket path %s is too long", fname);
    strcpy(sa->sun_path, fname);
    perperl_free(fname);
}

static int make_sock(void) {
    int i, fd;

    for (i = 0; i < 300; ++i) {
	fd = socket(AF_UNIX, SOCK_STREAM, 0);
	if (fd != -1)
	    return fd;
	else if (NO_BUFSPC(errno)) {
	    sleep(1);
	    perperl_util_time_invalidate();
	}
	else
	    break;
    }
    perperl_util_die("cannot create socket");
    return -1;
}

void perperl_ipc_cleanup(slotnum_t slotnum) {
    perperl_free(get_fname(slotnum, 1));
}

#ifdef PERPERL_BACKEND

static int		listener;
static struct stat	listener_stbuf;
static PollInfo		listener_pi;

void perperl_ipc_listen(slotnum_t slotnum) {
    struct sockaddr_un sa;

    listener = -1;
    if (PREF_FD_LISTENER != -1) {
	int namelen = sizeof(sa);
	char *fname = get_fname(slotnum, 0);
	struct stat stbuf;

	if (getsockname(PREF_FD_LISTENER, (struct sockaddr *)&sa, &namelen) != -1 &&
	    sa.sun_family == AF_UNIX &&
	    strcmp(sa.sun_path, fname) == 0 &&
	    stat(fname, &stbuf) != -1 &&
	    stbuf.st_uid == perperl_util_geteuid())
	{
	    listener = PREF_FD_LISTENER;
	}
	perperl_free(fname);
    }
    if (listener == -1) {
	mode_t saved_umask = umask(077);
	listener = make_sock();
	make_sockname(slotnum, &sa, 1);
	if (bind(listener, (struct sockaddr*)&sa, sizeof(sa)) == -1)
	    perperl_util_die("cannot bind socket");
	umask(saved_umask);
    }
    if (listen(listener, LISTEN_BACKLOG) == -1)
	perperl_util_die("cannot listen on socket");
    fstat(listener, &listener_stbuf);
    listener = perperl_util_pref_fd(listener, PREF_FD_LISTENER);
    fcntl(listener, F_SETFD, FD_CLOEXEC);
    perperl_poll_init(&listener_pi, listener);
}

static void ipc_unlisten(void) {
    close(listener);
    listener = -1;
    perperl_poll_free(&listener_pi);
}

void perperl_ipc_listen_fixfd(slotnum_t slotnum) {
    struct stat stbuf;

    /* Odd compiler bug - Solaris 2.7 plus gcc 2.95.2, can't put all of
     * this into one big "if" statment - returns false constantly.  Probably
     * has something to do with 64-bit values in st_dev/st_ino
     * 2.7 bug was found on sparc. Bug does not exist on Solaris-8/intel.
     */
#ifdef WANT_SOLARIS_BUG
    if ((fstat(listener, &stbuf) == -1) ||
	(stbuf.st_dev != listener_stbuf.st_dev) ||
	(stbuf.st_ino != listener_stbuf.st_ino))
#else
    int status, test1, test2;
    status = fstat(listener, &stbuf);
    test1 = stbuf.st_dev != listener_stbuf.st_dev;
    test2 = stbuf.st_ino != listener_stbuf.st_ino;
    if (status == -1 || test1 || test2)
#endif
    {
	ipc_unlisten();
	perperl_ipc_listen(slotnum);
    }
}

static void do_accept(int pref_fd) {
    struct sockaddr_un sa;
    int namelen, sock;

    namelen = sizeof(sa);
    sock = perperl_util_pref_fd(
	accept(listener, (struct sockaddr*)&sa, &namelen), pref_fd
    );
    if (sock == -1)
	perperl_util_die("accept failed");
}

static int accept_ready(int wakeup) {
    return perperl_poll_quickwait(&listener_pi, listener, PERPERL_POLLIN, wakeup)
	> 0;
}

int perperl_ipc_accept(int wakeup) {
    if (accept_ready(wakeup)) {
	do_accept(PREF_FD_ACCEPT_I);
	do_accept(PREF_FD_ACCEPT_O);
	do_accept(PREF_FD_ACCEPT_E);
	return 1;
    }
    return 0;
}

#endif /* PERPERL_BACKEND */

#ifdef PERPERL_FRONTEND

static int do_connect(slotnum_t slotnum, int fd) {
    struct sockaddr_un sa;

    make_sockname(slotnum, &sa, 0);
    return connect(fd, (struct sockaddr *)&sa, sizeof(sa)) != -1;
}

void perperl_ipc_connect_prepare(int socks[NUMFDS]) {
    int i;
    for (i = 0; i < NUMFDS; ++i)
	socks[i] = make_sock();
}

int perperl_ipc_connect(slotnum_t slotnum, const int socks[NUMFDS]) {
    int i;
    for (i = 0; i < NUMFDS; ++i) {
	if (!do_connect(slotnum, socks[i])) {
	    for (i = 0; i < NUMFDS; ++i)
		close(socks[i]);
	    return 0;
	}
    }
    return 1;
}

#endif /* PERPERL_FRONTEND */
