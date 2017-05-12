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

typedef struct _CopyBuf {
    CircBuf	circ;
    int		maxsz;
    int		eof;
    int		rdfd;
    int		wrfd;
    int		write_err;
} CopyBuf;

#define perperl_cb_write_err(cb)	((cb)->write_err + 0)
#define perperl_cb_eof(cb)	((cb)->eof + 0)
#define perperl_cb_seteof(cb)	do { (cb)->eof = 1;} while (0)
#define perperl_cb_data_len(cb)	(perperl_circ_data_len(&(cb)->circ))
#define perperl_cb_free_len(cb)	((cb)->maxsz - perperl_cb_data_len(cb))
#define perperl_cb_canread(cb)	\
    (perperl_cb_free_len(cb) && !perperl_cb_eof(cb) && !perperl_cb_write_err(cb))
#define perperl_cb_canwrite(cb)	\
    (perperl_cb_data_len(cb) && !perperl_cb_write_err(cb))
#define perperl_cb_copydone(cb)	\
    ((perperl_cb_eof(cb) && !perperl_cb_data_len(cb)) || perperl_cb_write_err(cb))
#define perperl_cb_set_write_err(cb, e) \
    do {(cb)->write_err = (e);} while (0)
#define perperl_cb_setfd(cb, r, w) \
    do { (cb)->rdfd = (r); (cb)->wrfd = (w); } while (0)
	

void perperl_cb_init(
    CopyBuf *cb, int maxsz, int rdfd, int wrfd, const PersistentBuf *contents
);
void perperl_cb_free(CopyBuf *cb);
void perperl_cb_read(CopyBuf *cb);
void perperl_cb_write(CopyBuf *cb);
int  perperl_cb_shift(CopyBuf *cb);
