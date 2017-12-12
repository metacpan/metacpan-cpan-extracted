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

#include <sys/types.h>
#include <unistd.h>
#include <errno.h>
#include "runcap.h"

off_t
runcap_seek(struct runcap *rc, int sd, off_t off, int whence)
{
	struct stream_capture *cap;
	off_t cur;
	
	cap = runcap_get_capture(rc, sd);
	if (!cap)
		return -1;

	cur = runcap_tell(rc, sd);
	switch (whence) {
	case SEEK_CUR:
		off = cur + off;
		break;

	case SEEK_END:
		off = cap->sc_leng + off;
		break;

	case SEEK_SET:
		break;

	default:
		errno = EINVAL;
		return -1;
	}
	
	if (off < 0) {
		errno = EINVAL;
		return -1;
	}

	cur -= cap->sc_cur;

	if (cur <= off && off <= cur + cap->sc_level) {
		cap->sc_cur = off - cur;
	} else if (cap->sc_storfd != -1) {
		if (lseek(cap->sc_storfd, off, SEEK_SET) == -1)
			return -1;
		cap->sc_level = 0;
		cap->sc_cur = 0;
	} else {
		errno = EINVAL;
		return -1;
	}
	return off;
}

		
	
	
