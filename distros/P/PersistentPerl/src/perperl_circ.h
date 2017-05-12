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

/* Circular Buffer */

typedef struct {
    char 	*buf;
    int		buf_len;
    int		data_beg;
    int		data_len;
} CircBuf;

#define perperl_circ_data_len(circ)	((circ)->data_len + 0)
#define perperl_circ_buf_len(circ)	((circ)->buf_len + 0)
#define perperl_circ_free_len(circ)	((circ)->buf_len - (circ)->data_len)
#define perperl_circ_buf(circ)		((circ)->buf + 0)

void perperl_circ_init(CircBuf *circ, const PersistentBuf *contents);
int  perperl_circ_data_segs(const CircBuf *circ, struct iovec iov[2]);
int  perperl_circ_free_segs(const CircBuf *circ, struct iovec iov[2]);
void perperl_circ_adj_len(CircBuf *circ, int adjust);
void perperl_circ_realloc(CircBuf *circ, char *buf, int new_buf_len);
