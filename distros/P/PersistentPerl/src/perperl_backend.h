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

void perperl_backend_dispose(slotnum_t gslotnum, slotnum_t bslotnum);
slotnum_t perperl_backend_be_wait_get(slotnum_t gslotnum);
void perperl_backend_be_wait_put(slotnum_t gslotnum, slotnum_t bslotnum);
slotnum_t perperl_backend_create_slot(slotnum_t gslotnum);
void perperl_backend_remove_be_wait(slotnum_t gslotnum);
int perperl_backend_below_maxbe(slotnum_t gslotnum);
void perperl_backend_exited(slotnum_t bslotnum, int exit_on_sig, int exit_val);

#define perperl_backend_alive(b) \
	(perperl_util_kill(FILE_SLOT(be_slot, (b)).pid, 0) != -1)

#define perperl_backend_dead(b) (!perperl_backend_alive(b))

/* Backend is dead, simulate sigkill */
#define perperl_backend_died(b) perperl_backend_exited((b),1,SIGKILL)
