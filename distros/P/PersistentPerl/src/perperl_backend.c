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

#include "perperl.h"

void perperl_backend_dispose(slotnum_t gslotnum, slotnum_t bslotnum) {
    if (gslotnum && bslotnum) {
	gr_slot_t *gslot = &FILE_SLOT(gr_slot, gslotnum);

	if (FILE_SLOT(be_slot, bslotnum).fe_running)
	    perperl_backend_died(bslotnum);
	
	perperl_slot_remove(bslotnum, &(gslot->be_head), &(gslot->be_tail));
	perperl_ipc_cleanup(bslotnum);
	SLOT_FREE(bslotnum, "backend (perperl_backend_dispose)");
    }
}

#ifdef PERPERL_FRONTEND
slotnum_t perperl_backend_be_wait_get(slotnum_t gslotnum) {
    gr_slot_t *gslot = &FILE_SLOT(gr_slot, gslotnum);
    slotnum_t head = gslot->be_head;

    /* Don't grab a backend while a backend is starting */
    if (perperl_group_be_starting(gslotnum) ||
	!head || FILE_SLOT(be_slot, head).fe_running)
    {
	return 0;
    }
    perperl_slot_move_tail(head, &(gslot->be_head), &(gslot->be_tail));
    return head;
}
#endif /* PERPERL_FRONTEND */

#ifdef PERPERL_BACKEND

/* Move waiting be to the begining of the list, order reverse by maturity.
 * We also want waiting be's to go before non-waiting be's.
 * We want to go at the beginning of our maturity list to preserve LIFO
 * ordering so inactive be's will die off.
 */

static int do_sort(slotnum_t bslotnum_a, slotnum_t bslotnum_b) {
    be_slot_t *a = &FILE_SLOT(be_slot, bslotnum_a);
    be_slot_t *b = &FILE_SLOT(be_slot, bslotnum_b);
    int diff;

    /* We want waiting be's to go before non-waiting.
     * If we return < 0, a will go before b.
     * If A is waiting and B is not, we return (B=0) - (A=1) == -1
     *    and A is first.
     * If B is waiting and A is not, we return (B=1) - (A=0) ==  1
     *    and B is first.
     */
    diff = ((b->fe_running ? 0 : 1) - (a->fe_running ? 0 : 1));
    if (diff != 0)
	return diff;

    /* We want higher maturity#'s at the beginning.
     * If we return < 0, a will go before b
     * if A = 2 and B = 1, then we return -1 (B=1) - (A=2) == -1.
     * If A = 1 and B = 2, then we return  1 (B=2) - (A=1) ==  1.
     */
    return b->maturity - a->maturity;
}

void perperl_backend_be_wait_put(slotnum_t gslotnum, slotnum_t bslotnum) {
    gr_slot_t *gslot = &FILE_SLOT(gr_slot, gslotnum);

    FILE_SLOT(be_slot, bslotnum).fe_running = 0;
    perperl_slot_remove(bslotnum, &(gslot->be_head), &(gslot->be_tail));
    perperl_slot_insert_sorted(
	bslotnum, &(gslot->be_head), &(gslot->be_tail), &do_sort
    );
}

slotnum_t perperl_backend_create_slot(slotnum_t gslotnum) {
    gr_slot_t *gslot = &FILE_SLOT(gr_slot, gslotnum);
    slotnum_t bslotnum;

    /* Create our backend slot */
    bslotnum = SLOT_ALLOC("backend (perperl_backend_create_slot)");
    FILE_SLOT(be_slot, bslotnum).fe_running = bslotnum;

    /* Put our slot at the end of group's be list */
    perperl_slot_append(bslotnum, &(gslot->be_head), &(gslot->be_tail));

    return bslotnum;
}
#endif /* PERPERL_BACKEND */

/* Kill and remove all be's in the be_wait list */
void perperl_backend_remove_be_wait(slotnum_t gslotnum) {
    gr_slot_t *gslot = &FILE_SLOT(gr_slot, gslotnum);
    slotnum_t bslotnum, next;

    for (bslotnum = gslot->be_head;
         bslotnum && !FILE_SLOT(be_slot, bslotnum).fe_running;
	 bslotnum = next)
    {
	next = perperl_slot_next(bslotnum);
	perperl_util_kill(FILE_SLOT(be_slot, bslotnum).pid, SIGTERM);
    }
}

static int count_bes(slotnum_t gslotnum, int max) {
    slotnum_t bslotnum;
    int count;

    for (bslotnum = FILE_SLOT(gr_slot, gslotnum).be_head, count = 0;
         bslotnum && count < max;
	 bslotnum = perperl_slot_next(bslotnum))
    {
	++count;
    }
    return count;
}

int perperl_backend_below_maxbe(slotnum_t gslotnum) {
    return !OPTVAL_MAXBACKENDS ||
	count_bes(gslotnum, OPTVAL_MAXBACKENDS) < OPTVAL_MAXBACKENDS;
}

void perperl_backend_exited(slotnum_t bslotnum, int exit_on_sig, int exit_val) {
    be_slot_t *bslot = &FILE_SLOT(be_slot, bslotnum);
    slotnum_t fslotnum;

    if ((fslotnum = bslot->fe_running)) {
	bslot->fe_running = bslotnum;
	if (fslotnum != bslotnum) {
	    fe_slot_t *fslot = &FILE_SLOT(fe_slot, fslotnum);
	    fslot->backend = 0;
	    fslot->exit_on_sig = exit_on_sig;
	    fslot->exit_val = exit_val;
	    if (perperl_util_kill(fslot->pid, SIGUSR1) == -1)
		perperl_frontend_remove_running(fslotnum);
	}
    }
}
