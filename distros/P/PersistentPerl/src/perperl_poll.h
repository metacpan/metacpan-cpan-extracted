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

#if defined(USE_POLL) || ((defined(sun) || defined(SYSV)) && !defined(USE_SELECT))
#   define USE_POLL
#   undef  USE_SELECT
#else
#   define USE_SELECT
#   undef  USE_POLL
#endif

#ifdef USE_POLL

/*******************
 * Poll Section
 *******************/

#define PERPERL_POLLIN	(POLLIN  | POLLHUP | POLLERR | POLLNVAL)
#define PERPERL_POLLOUT	(POLLOUT | POLLHUP | POLLERR | POLLNVAL)

typedef struct _PollInfo {
    struct pollfd	*fds, **fdmap;
    int			maxfd, numfds;
} PollInfo;

void perperl_poll_free(PollInfo *pi);

#else

/*******************
 * Select Section
 *******************/

#define PERPERL_POLLIN	1
#define PERPERL_POLLOUT	2

typedef struct _PollInfo {
    fd_set	fdset[2];
    int		maxfd;
} PollInfo;

#define perperl_poll_free(pi)

#endif

/*******************
 * Common to Both
 *******************/

void perperl_poll_init(PollInfo *pi, int maxfd);
void perperl_poll_reset(PollInfo *pi);
void perperl_poll_set(PollInfo *pi, int fd, int flags);
int perperl_poll_wait(PollInfo *pi, int msecs);
int perperl_poll_isset(const PollInfo *pi, int fd, int flag);
int perperl_poll_quickwait(PollInfo *pi, int fd, int flags, int msecs);
