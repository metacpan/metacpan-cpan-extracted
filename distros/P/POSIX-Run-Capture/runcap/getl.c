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

ssize_t
runcap_getline(struct runcap *rc, int sd, char **pstr, size_t *psize)
{
	char *str;
	size_t size;
	size_t n;
	char c;
	int res;
	
	if (!pstr || !psize) {
		errno = EINVAL;
		return -1;
	}

	str = *pstr;
	size = *psize;

	if (!str || size == 0) {
		/* Initial allocation */
		size = 16;
		str = malloc(size);
		if (!str)
			return -1;
		*pstr = str;
		*psize = size;
	}
	
	n = 0;
	while ((res = runcap_getc(rc, sd, &c)) == 1) {
		if (n == size) {
			char *p;
			size_t sz;
			
			if (size >= (size_t) -1 / 3 * 2) {
				errno = ENOMEM;
				return -1;
			}
			sz = size + (size + 1) / 2;
			p = realloc(str, sz);
			if (!p)
				return -1;
			*pstr = str = p;
			*psize = size = sz;
		}
		str[n++] = c;
		if (c == '\n')
			break;
	}

	if (res == -1)
		return -1;
	
	if (n == size) {
		char *p = realloc(str, size + 1);
		if (!p)
			return -1;
		*pstr = str = p;
		*psize = ++size;
	}
	str[n] = 0;
	return n;
}
		
