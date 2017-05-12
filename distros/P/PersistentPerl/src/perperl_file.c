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

/* Open/create, mmap and lock the perperl temp file */

#include "perperl.h"

perperl_file_t		*perperl_file_maddr;
static int		file_fd = -1;
static int		maplen;
static int		file_locked;
static char		*file_name, *saved_tmpbase;
static struct stat	file_stat;
static int		cur_state;
static time_t		last_reopen;
#ifdef PERPERL_BACKEND
static int		fd_is_suspect;
#endif

#define fillin_fl(fl)		\
    fl.l_whence	= SEEK_SET;	\
    fl.l_start	= 0;		\
    fl.l_len	= 0

static void file_unmap(void) {
    if (maplen) {
#	if defined(__APPLE__) && defined(MS_INVALIDATE)
	    /*
	     * This makes Mac OS-X 10.1 pass all the tests, where it was failing
	     * alarm/2 and others intermittently.  The problem seems to happen
	     * when the temp file is expanded, and might be due to some
	     * memory flushing problem in the OS, but I can't isolate it.
	     * This change might slow things down due to more disk i/o.
	     *
	     * Reproduce the bug by removing the perperl temp file and running:
	     *   print "$$";
	     * twice.  The first backend will die, and the second run will
	     * output a different pid.
	     */
	    msync(perperl_file_maddr, maplen, MS_INVALIDATE);
#	endif
	(void) munmap((void*)perperl_file_maddr, maplen);
	perperl_file_maddr = 0;
	maplen = 0;
    }
}

static void file_map(unsigned int len) {
    if (maplen != len) {
	file_unmap();
	maplen = len;
	if (len) {
	    perperl_file_maddr = (perperl_file_t*)mmap(
		0, len, PROT_READ | PROT_WRITE, MAP_SHARED, file_fd, 0
	    );
	    if (perperl_file_maddr == (perperl_file_t*)MAP_FAILED)
		perperl_util_die("mmap failed");
	}
    }
}

static void file_unlock(void) {
    struct flock fl;

    if (!file_locked)
	return;

    FILE_HEAD.lock_owner = 0;

    fillin_fl(fl);
    fl.l_type = F_UNLCK;
    if (fcntl(file_fd, F_SETLK, &fl) == -1) perperl_util_die("unlock file");
    file_locked = 0;

    perperl_sig_blockall_undo();
}

/* Only call this if you're sure the fd is not suspect */
static void file_close2(void) {

#ifdef PERPERL_BACKEND
    if (fd_is_suspect)
	DIE_QUIET("file_close2: assertion failed - fd_is_suspect");
#endif

    file_unlock();
    file_unmap();
    if (file_fd != -1) {
	(void) close(file_fd);
	file_fd = -1;
    }
}


#ifdef PERPERL_BACKEND
PERPERL_INLINE void perperl_file_fd_is_suspect(void) {
    fd_is_suspect = 1;
}

static void fix_suspect_fd(void) {
    if (fd_is_suspect) {
	if (file_fd != -1) {
	    struct stat stbuf;

	    if (fstat(file_fd, &stbuf) == -1 ||
		stbuf.st_dev != file_stat.st_dev ||
		stbuf.st_ino != file_stat.st_ino)
	    {
		file_unmap();
		file_fd = -1;
	    }
	}
	fd_is_suspect = 0;
    }
}
#endif


#define get_stat() \
    if (fstat(file_fd, &file_stat) == -1) perperl_util_die("fstat")

static void remove_file(int is_corrupt) {
#ifdef PERPERL_DEBUG
    if (is_corrupt) {
	/* Keep the file for debugging */
	char newname[200];
	struct timeval tv;

	gettimeofday(&tv, NULL);
	sprintf(newname, "%s.corrupt.%d.%06d.%d",
	    file_name, (int)tv.tv_sec, (int)tv.tv_usec, getpid());
	if (rename(file_name, newname) == -1)
	    perperl_util_die("rename temp file");
	FILE_HEAD.file_removed = 1;
	DIE_QUIET("temp file corrupt");
    }
#endif
    if (unlink(file_name) == -1 && errno != ENOENT)
	perperl_util_die("unlink temp file");
    FILE_HEAD.file_removed = 1;
}

static void str_replace(char **ptr, char *newval) {
    if (*ptr)
	perperl_free(*ptr);
    *ptr = newval;
}

static void file_lock(void) {
    static struct timeval file_create_time;
    struct flock fl;
    int tries;
    time_t now;

    if (file_locked)
	return;

#ifdef PERPERL_BACKEND
    fix_suspect_fd();
#endif

    /* Re-open the temp file occasionally or if tmpbase changed */
    if ((now = perperl_util_time()) - last_reopen > OPTVAL_RESTATTIMEOUT ||
	!saved_tmpbase || strcmp(saved_tmpbase, OPTVAL_TMPBASE) != 0)
    {
	last_reopen = now;
	file_close2();
    }

    for (tries = 5; tries; --tries) {
	/* If file is not open, open it */
	if (file_fd == -1) {
	    str_replace(&saved_tmpbase, perperl_util_strdup(OPTVAL_TMPBASE));
	    str_replace(&file_name, perperl_util_fname(FILE_REV, 'F'));
	    file_fd = perperl_util_pref_fd(
		open(file_name, O_RDWR | O_CREAT, 0600), PREF_FD_FILE
	    );
	    if (file_fd == -1) perperl_util_die("open temp file");
	    fcntl(file_fd, F_SETFD, FD_CLOEXEC);
	}

	/* Lock the file */
	fillin_fl(fl);
	fl.l_type = F_WRLCK;
	if (fcntl(file_fd, F_SETLKW, &fl) == -1) perperl_util_die("lock file");

	/* Fstat the file, now that it's locked down */
	get_stat();

	/* Map into memory */
	file_map(file_stat.st_size);

	/* If file is too small (0 or below MIN_SLOTS_FREE), extend it */
	if (file_stat.st_size < sizeof(file_head_t) ||
	    file_stat.st_size < sizeof(file_head_t) +
		sizeof(slot_t) * (FILE_HEAD.slots_alloced + MIN_SLOTS_FREE))
	{
	    if (ftruncate(file_fd, file_stat.st_size + FILE_ALLOC_CHUNK) == -1)
		perperl_util_die("ftruncate");
	    get_stat();
	    file_map(file_stat.st_size);
	}

	/* Initialize file's create time if necessary */
	if (!FILE_HEAD.create_time.tv_sec)
	    perperl_util_gettimeofday(&(FILE_HEAD.create_time));
	
	/* Initialize our copy of the create-time if necessary */
	if (!file_create_time.tv_sec || cur_state < FS_HAVESLOTS) {
	    file_create_time = FILE_HEAD.create_time;
	}
	/* Check whether this file is a different version  */
	else if ((file_create_time.tv_sec  != FILE_HEAD.create_time.tv_sec ||
	          file_create_time.tv_usec != FILE_HEAD.create_time.tv_usec))
	{
	    remove_file(1);
	}

	/* If file is corrupt (didn't finish all writes), remove it */
	if (FILE_HEAD.lock_owner)
	    remove_file(1);

	/* If file has not been removed then all done */
	if (!FILE_HEAD.file_removed)
	    break;

	/* File is invalid */
	if (cur_state >= FS_HAVESLOTS) {
	    /* Too late for this proc - slotnums have changed, can't recover */
	    DIE_QUIET("temp file is corrupt");
	} else {
	    /* Bad luck - the file was unlinked after we opened it (possibly
	     * by us because it was corrupt), but before we locked it.
	     * Try again.
	     */
	    file_close2();
	}
    }
    if (!tries) {
	DIE_QUIET("could not open temp file");
    }

    /* Block all sigs while writing to file */
    perperl_sig_blockall();
    file_locked = 1;
    FILE_HEAD.lock_owner = perperl_util_getpid();
}

static void file_close(void) {
    /* If no groups left, remove the file */
    if (cur_state >= FS_HAVESLOTS) {
	file_lock();
	if (!FILE_HEAD.group_head && !FILE_HEAD.fe_run_head)
	    remove_file(0);
    }
    file_close2();
}

int perperl_file_size(void) {
    return maplen;
}

static void switch_state(int new_state) {
    switch(new_state) {
    case FS_CLOSED:
	file_close();
	break;
    case FS_OPEN:
	file_unlock();
	break;
    case FS_HAVESLOTS:
	file_unlock();
	break;
    case FS_CORRUPT:
	file_lock();
	break;
    }
}

PERPERL_INLINE int perperl_file_set_state(int new_state) {
    int retval = cur_state;

    if (new_state != cur_state) {
	switch_state(new_state);
	cur_state = new_state;
    }
    return retval;
}

void perperl_file_fork_child(void) {
    if (file_locked)
	perperl_sig_blockall_undo();
    file_locked = 0;
    if (cur_state > FS_HAVESLOTS)
	perperl_file_set_state(FS_HAVESLOTS);
}

#ifdef PERPERL_BACKEND
void perperl_file_need_reopen(void) {
    last_reopen = 0;
}
#endif
