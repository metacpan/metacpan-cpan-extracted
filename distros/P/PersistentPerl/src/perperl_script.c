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

static struct stat	script_stat;
static int		script_fd;
static time_t		last_open;

void perperl_script_close(void) {
    if (last_open)
	close(script_fd);
    last_open = 0;
}

void perperl_script_missing(void) {
    DIE_QUIET("Missing script filename.  "
	"Type \"perldoc " PERPERL_PKGNAME "\" for PersistentPerl documentation.");
}

int perperl_script_open_failure(void) {
    time_t now = perperl_util_time();
    const char *fname;

    if (!last_open || now - last_open > OPTVAL_RESTATTIMEOUT) {

	perperl_script_close();

	if (!(fname = perperl_opt_script_fname()))
	    return 1;

	if ((script_fd = perperl_util_open_stat(fname, &script_stat)) == -1)
	    return 2;

	last_open = now;
    }
    return 0;
}

int perperl_script_open(void) {
    switch (perperl_script_open_failure()) {
	case 1:
	    perperl_script_missing();
	    break;
	case 2:
	    perperl_util_die(perperl_opt_script_fname());
	    break;
    }
    return script_fd;
}

#ifdef PERPERL_FRONTEND
int perperl_script_changed(void) {
    struct stat stbuf;

    if (!last_open)
	return 0;
    stbuf = script_stat;
    (void) perperl_script_open();
    return
	stbuf.st_mtime != script_stat.st_mtime ||
	stbuf.st_ino != script_stat.st_ino ||
	stbuf.st_dev != script_stat.st_dev;
}
#endif

const struct stat *perperl_script_getstat(void) {
    perperl_script_open();
    return &script_stat;
}

slotnum_t perperl_script_find(void) {
    slotnum_t gslotnum, next, name_match = 0;
    int single_script = DOING_SINGLE_SCRIPT;
    
    (void) perperl_script_getstat();

    /* Find the slot for this script in the file */
    for (gslotnum = FILE_HEAD.group_head; gslotnum; gslotnum = next) {
	gr_slot_t *gslot = &FILE_SLOT(gr_slot, gslotnum);
	slotnum_t sslotnum = 0;
	next = perperl_slot_next(gslotnum);

	/* The end of the list contains only invalid groups */
	if (!perperl_group_isvalid(gslotnum)) {
	    gslotnum = 0;
	    break;
	}

	if (!single_script) {
	    if (perperl_group_name_match(gslotnum))
		name_match = gslotnum;
	    else
		/* Reject group names that don't match */
		continue;
	}

	/* Search the script list */
	for (sslotnum = gslot->script_head; sslotnum;
	     sslotnum = perperl_slot_next(sslotnum))
	{
	    scr_slot_t *sslot = &FILE_SLOT(scr_slot, sslotnum);
	    if (sslot->dev_num == script_stat.st_dev &&
		sslot->ino_num == script_stat.st_ino)
	    {
		if (sslot->mtime != script_stat.st_mtime) {

		    /* Invalidate group */
		    perperl_group_invalidate(gslotnum);
		    sslotnum = 0;
		} else {
		    /* Move this script to the front */
		    perperl_slot_move_head(
			sslotnum, &(gslot->script_head), NULL
		    );
		}

		/* Done with this group */
		break;
	    }
	}

	/* If we found the slot, all done */
	if (sslotnum)
	    break;
    }

    /* Slot not found... */
    if (!gslotnum) {
	slotnum_t sslotnum;
	scr_slot_t *sslot;

	/* Get the group-name match from the previous search */
	gslotnum = name_match;

	/* If group not found create one */
	if (!gslotnum || !perperl_group_isvalid(gslotnum))
	    gslotnum = perperl_group_create();

	/* Create a new script slot */
	sslotnum = SLOT_ALLOC("script (perperl_script_find)");
	sslot = &FILE_SLOT(scr_slot, sslotnum);
	sslot->dev_num = script_stat.st_dev;
	sslot->ino_num = script_stat.st_ino;
	sslot->mtime = script_stat.st_mtime;

	/* Add script to this group */
	perperl_slot_insert(
	    sslotnum, &(FILE_SLOT(gr_slot, gslotnum).script_head), NULL
	);

    }

    /* Move this group to the beginning of the list */
    perperl_slot_move_head(gslotnum,
	&(FILE_HEAD.group_head), &(FILE_HEAD.group_tail));

    return gslotnum;
}

static PersistentMapInfo *script_mapinfo;

void perperl_script_munmap(void) {
    if (script_mapinfo) {
	perperl_util_mapout(script_mapinfo);
	script_mapinfo = NULL;
    }
}

PersistentMapInfo *perperl_script_mmap(int max_size) {
    perperl_script_munmap();
    script_mapinfo = perperl_util_mapin(
	perperl_script_open(), max_size, perperl_script_getstat()->st_size
    );
    return script_mapinfo;
}
