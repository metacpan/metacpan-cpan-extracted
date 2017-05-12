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

void perperl_group_invalidate(slotnum_t gslotnum) {
    gr_slot_t *gslot = &FILE_SLOT(gr_slot, gslotnum);

    /* Don't invalidate twice */
    if (!perperl_group_isvalid(gslotnum))
	return;

    /* Remove scripts from the script list */
    {
	slotnum_t snum, next;

	for (snum = gslot->script_head; snum; snum = next) {
	    next = perperl_slot_next(snum);
	    SLOT_FREE(snum, "script (perperl_group_invalidate)");
	}
	gslot->script_head = 0;
    }

    /* Remove the group name if any */
    if (gslot->name_slot) {
	SLOT_FREE(gslot->name_slot, "name (perperl_group_invalidate)");
	gslot->name_slot = 0;
    }

    /* Remove backends from the be_wait queue */
    perperl_backend_remove_be_wait(gslotnum);

    /* Move this group to the tail of the group list */
    perperl_slot_move_tail(gslotnum,
	&(FILE_HEAD.group_head), &(FILE_HEAD.group_tail));
}

pid_t perperl_group_be_starting(slotnum_t gslotnum) {
    gr_slot_t *gslot = &FILE_SLOT(gr_slot, gslotnum);
    pid_t be_pid = gslot->be_starting;

    if (be_pid) {
	if (perperl_util_kill(be_pid, 0) != -1)
	    return be_pid;
	gslot->be_starting = 0;
    }
    return 0;
}

void perperl_group_sendsigs(slotnum_t gslotnum) {
    gr_slot_t *gslot = &FILE_SLOT(gr_slot, gslotnum);
    slotnum_t fslotnum, bslotnum;

    /* Get first slot in the fe list */
    fslotnum = gslot->fe_head;

    /* Loop over each backend slot in the wait list */
    for (bslotnum = gslot->be_head;
	 bslotnum && fslotnum && !FILE_SLOT(be_slot, bslotnum).fe_running;
         bslotnum = perperl_slot_next(bslotnum))
    {
	slotnum_t next;

	for (; fslotnum; fslotnum = next) {
	    /* Get next FE */
	    fe_slot_t *fslot = &FILE_SLOT(fe_slot, fslotnum);
	    next = perperl_slot_next(fslotnum);

	    /* If it's not us send an ALRM signal */
	    if (perperl_util_kill(fslot->pid, SIGALRM) != -1) {
		fslot->sent_sig = 1;
		break;
	    }

	    /* Failed, remove this FE and try again */
	    perperl_frontend_dispose(gslotnum, fslotnum);
	}

	/* Only wake up one FE at a time.. */
	break;
    }
}

/* Cleanup this group after an fe/be has been removed */
void perperl_group_cleanup(slotnum_t gslotnum) {

    /* No cleanup if there are still be's or fe's */
    if (FILE_SLOT(gr_slot, gslotnum).be_head ||
        FILE_SLOT(gr_slot, gslotnum).fe_head)
    {
	return;
    }

    /* Kill the parent */
    perperl_util_kill(FILE_SLOT(gr_slot, gslotnum).be_parent, SIGKILL);

    /* Invalidate - cleans up resources belonging to the group */
    perperl_group_invalidate(gslotnum);

    /* Remove our group from the list */
    perperl_slot_remove(gslotnum, &(FILE_HEAD.group_head), &(FILE_HEAD.group_tail));

    SLOT_FREE(gslotnum, "group (perperl_group_cleanup)");
}

slotnum_t perperl_group_create(void) {
    slotnum_t gslotnum;

    gslotnum = SLOT_ALLOC("group (perperl_group_create)");

    perperl_slot_insert(gslotnum, &(FILE_HEAD.group_head), &(FILE_HEAD.group_tail));

    if (!DOING_SINGLE_SCRIPT) {
	register slotnum_t nslotnum;

	nslotnum = SLOT_ALLOC("name (perperl_group_create)");
	FILE_SLOT(gr_slot, gslotnum).name_slot = nslotnum;
	strncpy(FILE_SLOT(grnm_slot, nslotnum).name, OPTVAL_GROUP, GR_NAMELEN);
    }
    return gslotnum;
}


int perperl_group_parent_sig(slotnum_t gslotnum, int sig) {
    gr_slot_t *gslot = &FILE_SLOT(gr_slot, gslotnum);

    if (perperl_util_kill(gslot->be_parent, sig) == -1) {
	perperl_group_invalidate(gslotnum);
	gslot->be_parent = 0;
	return 0;
    }
    return 1;
}

int perperl_group_start_be(slotnum_t gslotnum) {
    gr_slot_t *gslot = &FILE_SLOT(gr_slot, gslotnum);

    /* If the parent is still starting up, then consider it signalled */
    if (gslot->be_parent && gslot->be_parent == gslot->be_starting)
	return 1;
    
    return perperl_group_parent_sig(gslotnum, SIGUSR1);
}

int perperl_group_lock(slotnum_t gslotnum) {
    perperl_file_set_state(FS_CORRUPT);
    return perperl_group_isvalid(gslotnum);
}
