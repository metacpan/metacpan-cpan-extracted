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

typedef struct _file_head {
    struct timeval	create_time;
    pid_t		lock_owner;
    slotnum_t		group_head;
    slotnum_t		group_tail;
    slotnum_t		slot_free;
    slotnum_t		slots_alloced;
    slotnum_t		fe_run_head;
    slotnum_t		fe_run_tail;
    unsigned char	file_removed;
} file_head_t;

typedef struct _file {
    file_head_t		file_head;
    slot_t		slots[MAX_SLOTS];
} perperl_file_t;

#define FILE_ALLOC_CHUNK	512
#define FILE_REV		6
#define FILE_HEAD		(perperl_file_maddr->file_head)
#define FILE_SLOTS		(perperl_file_maddr->slots)
#define FILE_SLOT(member, n)	(FILE_SLOTS[SLOT_CHECK(n)-1].slot_u.member)
#define MIN_SLOTS_FREE		5

/* File access states */
#define FS_CLOSED	0	/* File is closed, not mapped */
#define FS_OPEN		1	/* Unlocked.  Keep open for performance only */
#define FS_HAVESLOTS	2	/* Unlocked.  We are holding onto slots in 
				   this file */
#define FS_CORRUPT	3	/* Locked, mmaped, non-atomic writes to file */

extern perperl_file_t *perperl_file_maddr;
PERPERL_INLINE void perperl_file_fd_is_suspect(void);
int perperl_file_size(void);
PERPERL_INLINE int perperl_file_set_state(int new_state);
void perperl_file_need_reopen(void);
void perperl_file_fork_child(void);
