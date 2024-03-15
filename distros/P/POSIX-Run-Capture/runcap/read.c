/* runcap - run program and capture its output
   Copyright (C) 2019-2024 Sergey Poznyakoff

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
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include "runcap.h"

ssize_t
runcap_read(struct runcap *rc, int sd, char *buf, size_t size)
{
	struct stream_capture *cap;
	ssize_t nread = 0;
	
	if (!buf) {
		errno = EINVAL;
		return -1;
	}
	if (size == 0)
		return 0;

	cap = runcap_get_capture(rc, sd);
	if (!cap)
		return -1;
	
	while (size) {
		size_t avail = cap->sc_level - cap->sc_cur;
		if (avail == 0) {
			if (cap->sc_storfd != -1) {
				ssize_t r = read(cap->sc_storfd,
						 cap->sc_base,
						 cap->sc_size);
				if (r < 0)
					return -1;
				else if (r == 0)
					break;
				avail = r;
				cap->sc_level = r;
				cap->sc_cur = 0;
			} else {
				break;
			}
		}

		if (avail > size)
			avail = size;
		memcpy(buf + nread, cap->sc_base + cap->sc_cur, avail);

		cap->sc_cur += avail;
		nread += avail;
		size -= avail;
	}
	
	return nread;
}
