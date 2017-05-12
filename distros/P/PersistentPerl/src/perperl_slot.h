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

typedef unsigned short slotnum_t;

#define GR_NAMELEN	12

typedef struct _scr_slot { /* 18/20 bytes for a 64-bit dev_t, 14/16 if 32-bit */
    perperl_dev_t	dev_num;
    perperl_ino_t	ino_num;
    time_t		mtime;
} scr_slot_t;

typedef struct _be_slot { /* 13/16 bytes */
    pid_t	pid;
    slotnum_t	fe_running;
    char	maturity;
} be_slot_t;

typedef struct _fe_slot { /* 9/12 bytes */
    pid_t	pid;
    int		exit_val;
    slotnum_t	backend;
    char	exit_on_sig;
    char	sent_sig;
} fe_slot_t;

typedef struct _gr_slot { /* 24 bytes */
    pid_t	be_starting;
    pid_t	be_parent;
    slotnum_t	script_head;
    slotnum_t	name_slot;
    slotnum_t	be_head;
    slotnum_t	be_tail;
    slotnum_t	fe_head;
    slotnum_t	fe_tail;
} gr_slot_t;

typedef struct _grnm_slot {
    char name[GR_NAMELEN];
} grnm_slot_t;

typedef union _slot_u {
    scr_slot_t	scr_slot;
    be_slot_t	be_slot;
    fe_slot_t	fe_slot;
    gr_slot_t	gr_slot;
    grnm_slot_t	grnm_slot;
} slot_u_t;

typedef struct _slot {
    slot_u_t	slot_u;
    slotnum_t	next_slot;
    slotnum_t	prev_slot;
} slot_t;

/* For perperl_dump to get the right size of a slot */
typedef struct _dummy_slot {
    char slot		[sizeof(slot_t)];
    char scr_slot	[sizeof(scr_slot_t)];
    char be_slot	[sizeof(be_slot_t)];
    char fe_slot	[sizeof(fe_slot_t)];
    char gr_slot	[sizeof(gr_slot_t)];
    char grnm_slot	[sizeof(grnm_slot_t)];
} dummy_slot_t;

#define MAX_SLOTS ((1<<(sizeof(slotnum_t)*8))-6)
#define BAD_SLOTNUM(n) ((n) == 0 || (n) > FILE_HEAD.slots_alloced)
#define SLOT_CHECK(n) (BAD_SLOTNUM(n) ?  perperl_slot_check(n) : (n))
#define SLOT(n) (FILE_SLOTS[SLOT_CHECK(n)-1])

#define perperl_slot_next(n) (SLOT(n).next_slot + 0)
#define perperl_slot_prev(n) (SLOT(n).prev_slot + 0)
#define perperl_slot_move_head(s,h,t) \
    do { \
	if (*(h) != (s)) { \
	    perperl_slot_remove((s),(h),(t)); \
	    perperl_slot_insert((s),(h),(t)); \
	} \
    } while (0)
#define perperl_slot_move_tail(s,h,t) \
    do { \
	if (*(t) != (s)) { \
	    perperl_slot_remove((s),(h),(t)); \
	    perperl_slot_append((s),(h),(t)); \
	} \
    } while (0)

slotnum_t perperl_slot_alloc(void);
void perperl_slot_free(slotnum_t slotnum);
slotnum_t perperl_slot_check(slotnum_t slotnum);
void perperl_slot_remove(slotnum_t slotnum, slotnum_t *head, slotnum_t *tail);
void perperl_slot_insert(slotnum_t slotnum, slotnum_t *head, slotnum_t *tail);
void perperl_slot_append(slotnum_t slotnum, slotnum_t *head, slotnum_t *tail);
void perperl_slot_insert_sorted(
    slotnum_t slotnum, slotnum_t *head, slotnum_t *tail,
    int (*compar)(slotnum_t, slotnum_t)
);

/* #define SLOT_ALLOC_DEBUG */

#if defined(PERPERL_DEBUG) && defined(SLOT_ALLOC_DEBUG)

static int SLOT_ALLOC(const char *t) {
    int n = perperl_slot_alloc();
    fprintf(stderr, "%s[%d]: slot_alloc(%d, %s)\n", PERPERL_PROGNAME, getpid(), n, t);
    return n;
}
#define SLOT_FREE(n,t) \
    do { \
	fprintf(stderr, "%s[%d]: slot_free(%d, %s)\n", PERPERL_PROGNAME, getpid(), (n), (t)); \
	perperl_slot_free(n); \
    } while (0)

#else

#define SLOT_ALLOC(t) perperl_slot_alloc()
#define SLOT_FREE(n,t) perperl_slot_free(n)

#endif
