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

void perperl_slot_remove(slotnum_t slotnum, slotnum_t *head, slotnum_t *tail) {
    slotnum_t n = SLOT(slotnum).next_slot;
    slotnum_t p = SLOT(slotnum).prev_slot;

    if (n)
	SLOT(n).prev_slot = p;
    
    if (p)
	SLOT(p).next_slot = n;

    if (*head == slotnum)
	*head = n;

    if (tail && *tail == slotnum)
	*tail = p;
}

void perperl_slot_insert(slotnum_t slotnum, slotnum_t *head, slotnum_t *tail) {
    SLOT(slotnum).next_slot = *head;
    SLOT(slotnum).prev_slot = 0;
    if (*head)
	SLOT(*head).prev_slot = slotnum;
    *head = slotnum;
    if (tail && !*tail)
	*tail = slotnum;
}

void perperl_slot_append(slotnum_t slotnum, slotnum_t *head, slotnum_t *tail) {
    SLOT(slotnum).prev_slot = *tail;
    SLOT(slotnum).next_slot = 0;
    if (*tail)
	SLOT(*tail).next_slot = slotnum;
    *tail = slotnum;
    if (!*head)
	*head = slotnum;
}

#ifdef PERPERL_BACKEND
void perperl_slot_insert_sorted(
    slotnum_t slotnum, slotnum_t *head, slotnum_t *tail,
    int (*compar)(slotnum_t, slotnum_t)
)
{
    slotnum_t *next_ptr;
    for (next_ptr = head; *next_ptr; next_ptr = &(SLOT(*next_ptr).next_slot)) {
	if (compar(slotnum, *next_ptr) <= 0) {
	    SLOT(slotnum).next_slot = *next_ptr;
	    SLOT(slotnum).prev_slot = SLOT(*next_ptr).prev_slot;
	    SLOT(*next_ptr).prev_slot = slotnum;
	    *next_ptr = slotnum;
	    return;
	}
    }
    perperl_slot_append(slotnum, head, tail);
}
#endif

/* Allocate a slot */
slotnum_t perperl_slot_alloc(void) {
    slotnum_t slotnum;

    /* Try to get a slot from the beginning of the free list */
    if ((slotnum = FILE_HEAD.slot_free)) {

	/* Got it - remove it from the free list */
	FILE_HEAD.slot_free = SLOT(slotnum).next_slot;

    } else {
	/* Allocate a new slot */
	slotnum = FILE_HEAD.slots_alloced + 1;

	/* Abort if too many slots */
	if (slotnum >= MAX_SLOTS)
	    DIE_QUIET("Out of slots");

	/* Check here if the file is large enough to hold this slot.
	 * The perperl_file code is supposed to allocate enough extra
	 * slots (MIN_SLOTS_FREE) when the file is locked to satisfy
	 * all slot_alloc's until the file is unlocked.  But if the
	 * code starts allocating too many slots for whatever reason,
	 * that will not work, and we'll drop off the end of the file.
	 * In that case, either fix the code or bump MIN_SLOTS_FREE
         */
	if (sizeof(file_head_t)+slotnum*sizeof(slot_t) > perperl_file_size()) {
	    perperl_util_die(
		"File too small for another slot while allocating slotnum %d. File size=%d. Try increasing MIN_SLOTS_FREE.",
		slotnum, perperl_file_size()
	    );
	}

	/* Successfully got a slot, so bump the count in the header */
	FILE_HEAD.slots_alloced++;
    }
    perperl_bzero(FILE_SLOTS + (slotnum-1), sizeof(slot_t));
    return slotnum;
}

/* Free a slot */
void perperl_slot_free(slotnum_t slotnum) {
    if (slotnum) {
	/* See if this is a previously freed slot */
	if (SLOT(slotnum).prev_slot == slotnum)
	    DIE_QUIET("Freeing free slot %d", slotnum);

	/* Mark this slot free by pointing prev to itself */
	SLOT(slotnum).prev_slot = slotnum;

	/* Put at beginning of free list */
	SLOT(slotnum).next_slot = FILE_HEAD.slot_free;
	FILE_HEAD.slot_free = slotnum;
    }
    else
	DIE_QUIET("Attempted free of slotnum 0");
}

slotnum_t perperl_slot_check(slotnum_t slotnum) {
    if (BAD_SLOTNUM(slotnum)) {
	DIE_QUIET("slotnum %d out of range, only %d alloced",
	    slotnum, FILE_HEAD.slots_alloced
	);
    }
    return slotnum;
}
