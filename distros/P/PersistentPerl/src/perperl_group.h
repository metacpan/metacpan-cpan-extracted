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

void perperl_group_invalidate(slotnum_t gslotnum);
void perperl_group_sendsigs(slotnum_t gslotnum);
void perperl_group_cleanup(slotnum_t gslotnum);
int perperl_group_connect_locked(slotnum_t gslotnum);
slotnum_t perperl_group_create(void);
pid_t perperl_group_be_starting(slotnum_t gslotnum);
int perperl_group_parent_sig(slotnum_t gslotnum, int sig);
int perperl_group_start_be(slotnum_t gslotnum);
int perperl_group_lock(slotnum_t gslotnum);

#define perperl_group_name_match(gslotnum) \
    (FILE_SLOT(gr_slot, (gslotnum)).name_slot && \
    !strncmp(FILE_SLOT(grnm_slot, FILE_SLOT(gr_slot, (gslotnum)).name_slot).name, OPTVAL_GROUP, GR_NAMELEN))

#define DOING_SINGLE_SCRIPT \
    (OPTVAL_GROUP[0] == 'n' && \
    OPTVAL_GROUP[1] == 'o' && \
    OPTVAL_GROUP[2] == 'n' && \
    OPTVAL_GROUP[3] == 'e' && \
    OPTVAL_GROUP[4] == '\0')

#define perperl_group_isvalid(g) (FILE_SLOT(gr_slot, (g)).script_head != 0)
