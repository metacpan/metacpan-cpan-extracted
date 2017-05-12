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

#ifdef USE_POLL

/*
 * Poll Section
 */

void perperl_poll_init(PollInfo *pi, int maxfd) {
    pi->maxfd	= maxfd;
    perperl_new(pi->fds,   maxfd+1, struct pollfd);
    perperl_new(pi->fdmap, maxfd+1, struct pollfd*);
    perperl_poll_reset(pi);
}

void perperl_poll_free(PollInfo *pi) {
    perperl_free(pi->fds);
    perperl_free(pi->fdmap);
}

void perperl_poll_reset(PollInfo *pi) {
    pi->numfds = 0;
    perperl_bzero(pi->fdmap, (pi->maxfd + 1) * sizeof(struct pollfd *));
}

void perperl_poll_set(PollInfo *pi, int fd, int flags) {
    struct pollfd **fdm = pi->fdmap;
    struct pollfd *pfd = fdm[fd];

    if (!pfd) {
	/* Allocate new */
	pfd = fdm[fd] = pi->fds + pi->numfds++;
	pfd->fd = fd;
	pfd->events = pfd->revents = 0;
    }
    pfd->events |= flags;
    pfd->revents |= flags;
}

static int poll_wait(PollInfo *pi, int msecs) {
    return poll(pi->fds, pi->numfds, msecs);
}

int perperl_poll_isset(const PollInfo *pi, int fd, int flag) {
    struct pollfd *pfd = (pi->fdmap)[fd];
    return pfd ? ((pfd->revents & flag) != 0) : 0;
}

#else

/*
 * Select Section
 */

void perperl_poll_init(PollInfo *pi, int maxfd) {
    pi->maxfd = maxfd;
    perperl_poll_reset(pi);
}

void perperl_poll_reset(PollInfo *pi) {
    FD_ZERO(pi->fdset + 0);
    FD_ZERO(pi->fdset + 1);
}

void perperl_poll_set(PollInfo *pi, int fd, int flags) {
    if (flags & (1<<0)) {
	FD_SET(fd, pi->fdset + 0);
    }
    if (flags & (1<<1)) {
	FD_SET(fd, pi->fdset + 1);
    }
}

static int poll_wait(PollInfo *pi, int msecs) {
    struct timeval tv, *tvp;
    if (msecs == -1) {
	tvp = NULL;
    } else {
	tv.tv_sec  = msecs / 1000;
	tv.tv_usec = (msecs % 1000) * 1000;
	tvp = &tv;
    }
    return select(pi->maxfd+1, pi->fdset + 0, pi->fdset + 1, NULL, tvp);
}

int perperl_poll_isset(const PollInfo *pi, int fd, int flag) {
    if (flag & (1<<0)) {
	return FD_ISSET(fd, pi->fdset + 0);
    }
    if (flag & (1<<1)) {
	return FD_ISSET(fd, pi->fdset + 1);
    }
    return 0;
}

#endif

/*
 * Common Section
 */

int perperl_poll_wait(PollInfo *pi, int msecs) {
    int retval;

    retval = poll_wait(pi, msecs);
    perperl_util_time_invalidate();
    return retval;
}

int perperl_poll_quickwait(PollInfo *pi, int fd, int flags, int msecs) {
    perperl_poll_reset(pi);
    perperl_poll_set(pi, fd, flags);
    return perperl_poll_wait(pi, msecs);
}
