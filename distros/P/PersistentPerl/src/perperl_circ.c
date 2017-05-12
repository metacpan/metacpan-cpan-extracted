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

#ifdef TESTPROG

#include <stdio.h>
#include <string.h>
#include <sys/uio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/time.h>

#define perperl_memcpy memcpy
#define perperl_memmove memmove
#define DIE_QUIET printf

#include "perperl_inc.h"

#else

#include "perperl.h"

#endif

/* Circular Buffer */

void perperl_circ_init(CircBuf *circ, const PersistentBuf *contents) {
    if (contents) {
	circ->buf	= contents->buf;
	circ->buf_len	= contents->alloced;
	circ->data_len	= contents->len;;
    } else {
	circ->buf	= NULL;
	circ->buf_len	= 0;
	circ->data_len	= 0;
    }
    circ->data_beg	= 0;
}

static int get_segs
    (struct iovec iov[2], char *buf, int buf_len, int beg, int len)
{
    register int first_seg_len;

    if (len == 0)
	return 0;

    iov[0].iov_base = buf + beg;

    first_seg_len = buf_len - beg;

    if (len <= first_seg_len) {
	iov[0].iov_len = len;
	return 1;
    }

    iov[0].iov_len = first_seg_len;
    iov[1].iov_base = buf;
    iov[1].iov_len = len - first_seg_len;
    return 2;
}

int perperl_circ_data_segs(const CircBuf *circ, struct iovec iov[2]) {
    return get_segs(iov, circ->buf, circ->buf_len, circ->data_beg, circ->data_len);
}

int perperl_circ_free_segs(const CircBuf *circ, struct iovec iov[2]) {
    if (!circ->buf_len)
	return 0;

    return get_segs(iov, circ->buf, circ->buf_len,
	(circ->data_beg + circ->data_len) % circ->buf_len,
	(circ->buf_len - circ->data_len)
    );
}

void perperl_circ_adj_len(CircBuf *circ, int adjust) {
    circ->data_len += adjust;
    if (adjust < 0) {
	if (circ->data_len == 0) {
	    circ->data_beg = 0;
	} else {
	    circ->data_beg = (circ->data_beg - adjust) % circ->buf_len;
	}
    }
}

void perperl_circ_realloc(CircBuf *circ, char *new_buf, int new_buf_len) {
    struct iovec data[2];

    circ->buf = new_buf;

    if (new_buf_len > circ->buf_len && perperl_circ_data_segs(circ, data) == 2) {
	int nsegs;

	if (data[0].iov_len <= data[1].iov_len) {
	    struct iovec *d = &(data[0]);

	    /* Move the data at the beginning of the circ (end of real buf) */
	    circ->data_beg = new_buf_len - d->iov_len;
	    perperl_memmove(circ->buf + circ->data_beg, d->iov_base, d->iov_len);
	} else {
	    struct iovec fr[2], *d = &(data[1]);

	    /* Move the data at the end of the circ (beg of real buf) */
	    nsegs = get_segs(
		fr, circ->buf, new_buf_len, circ->buf_len, d->iov_len
	    );
	    if (nsegs > 0) {
		perperl_memcpy(fr[0].iov_base, d->iov_base, fr[0].iov_len);
		if (nsegs > 1) {
		    perperl_memmove(
			fr[1].iov_base,
			(char*)d->iov_base + fr[0].iov_len,
			fr[1].iov_len
		    );
		}
	    }
	}
    }
    circ->buf_len = new_buf_len;
}

#ifdef TESTPROG

static char buf[32768];

static void dump_segs(const struct iovec iov[2], int nsegs) {
    int i;
    for (i = 0; i < nsegs; ++i) {
	printf(" seg[%d]='", (char*)(iov[i].iov_base) - buf);
	fwrite(iov[i].iov_base, 1, iov[i].iov_len, stdout);
	printf("'(len=%d)", iov[i].iov_len);
    }
    printf("\n");
}

int main(int argc, char **argv) {
    char input[100], *s;
    PersistentBuf sb;
    CircBuf circ;
    struct iovec iov[2];

    {
	sb.buf = buf;
	sb.alloced = 10;
	sb.len = 0;
	if (*(++argv)) {
	    sb.alloced = atoi(*argv);
	    if (*(++argv)) {
		sb.len = strlen(*argv);
		perperl_memcpy(buf, *argv, sb.len);
	    }
	}
	perperl_circ_init(&circ, sb.alloced ? &sb : NULL);
    }

    while (1) {
	printf("buf_len=%d data_len=%d free_len=%d\n",
	    perperl_circ_buf_len(&circ),
	    perperl_circ_data_len(&circ),
	    perperl_circ_free_len(&circ)
	);
	printf("free:");
	dump_segs(iov, perperl_circ_free_segs(&circ, iov));
	printf("data:");
	dump_segs(iov, perperl_circ_data_segs(&circ, iov));
	printf("\n? ");
	gets(input);

	s = strtok(input, " ");

	switch(s ? s[0] : ' ') {
	case 'q':
	    exit(0);
	    break;
	case 'a':
	    if ((s = strtok(NULL, " "))) {
		int l = strlen(s);
		if (l > perperl_circ_free_len(&circ)) {
		    printf("too big\n");
		} else {
		    int i, l2 = l, nsegs = perperl_circ_free_segs(&circ, iov);
		    for (i = 0; i < nsegs && l2; ++i) {
			perperl_memcpy(iov[i].iov_base, s, iov[i].iov_len);
			s += iov[i].iov_len;
			l2 -= iov[i].iov_len;
		    }
		    perperl_circ_adj_len(&circ, l);
		    printf("added %d bytes\n", l);
		}
	    }
	    break;
	case 'r':
	    if ((s = strtok(NULL, " "))) {
		int l = atoi(s);
		if (l > perperl_circ_data_len(&circ)) {
		    printf("too big\n");
		} else {
		    perperl_circ_adj_len(&circ, -l);
		    printf("removed %d bytes\n", l);
		}
	    }
	    break;
	case 'e':
	    if ((s = strtok(NULL, " "))) {
		int l = atoi(s);
		if (l > sizeof(buf)) {
		    printf("too big\n");
		} else {
		    perperl_circ_realloc(&circ, buf, l);
		    printf("new size %d bytes\n", l);
		}
	    }
	case 'i':
	    if ((s = strtok(NULL, " "))) {
		sb.buf = buf;
		sb.alloced = atoi(s);
		sb.len = 0;
		if ((s = strtok(NULL, " "))) {
		    sb.len = strlen(s);
		    memcpy(buf, s, sb.len);
		}
		perperl_circ_init(&circ, sb.alloced ? &sb : NULL);
	    }
	}
    }
}

#endif
