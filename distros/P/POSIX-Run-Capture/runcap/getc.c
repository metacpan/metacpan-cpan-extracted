/* runcap - run program and capture its output
   Copyright (C) 2017-2020 Sergey Poznyakoff

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

#include "runcap.h"

int
runcap_getc(struct runcap *rc, int sd, char *cp)
{
	struct stream_capture *cap;

	if (!cp) {
		errno = EINVAL;
		return -1;
	}
	
	cap = runcap_get_capture(rc, sd);
	if (!cap)
		return -1;
	
	if (cap->sc_level == cap->sc_cur) {
		if (cap->sc_storfd != -1) {
			ssize_t r = read(cap->sc_storfd, cap->sc_base,
					 cap->sc_size);
			if (r < 0)
				return -1;
			else if (r == 0)
				return 0;
			cap->sc_level = r;
			cap->sc_cur = 0;
		} else {
			return 0;
		}
	}
	*cp = cap->sc_base[cap->sc_cur++];
	return 1;
}
	
