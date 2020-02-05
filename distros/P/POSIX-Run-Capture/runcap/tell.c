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

#include <sys/types.h>
#include <unistd.h>
#include <errno.h>
#include "runcap.h"

off_t
runcap_tell(struct runcap *rc, int sd)
{
	struct stream_capture *cap;
	off_t off;
	
	cap = runcap_get_capture(rc, sd);
	if (!cap)
		return -1;

	if (cap->sc_storfd != -1) {
		off = lseek(cap->sc_storfd, 0, SEEK_CUR);
		if (off == -1)
			return -1;
		off -= cap->sc_level;
	} else
		off = 0;

	return off + cap->sc_cur;
}

