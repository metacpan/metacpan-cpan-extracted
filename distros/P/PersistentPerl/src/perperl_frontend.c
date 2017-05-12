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

void perperl_frontend_dispose(slotnum_t gslotnum, slotnum_t fslotnum) {
    if (fslotnum) {
	gr_slot_t *gslot = &FILE_SLOT(gr_slot, gslotnum);

	perperl_slot_remove(fslotnum, &(gslot->fe_head), &(gslot->fe_tail));
	SLOT_FREE(fslotnum, "frontend (perperl_frontend_dispose)");
    }
}

void perperl_frontend_remove_running(const slotnum_t fslotnum) {
    fe_slot_t *fslot = &FILE_SLOT(fe_slot, fslotnum);

    if (fslot->backend) {
	be_slot_t *bslot = &FILE_SLOT(be_slot, fslot->backend);
	if (bslot->fe_running == fslotnum)
	    bslot->fe_running = fslot->backend;
    }
    perperl_slot_remove(fslotnum, &(FILE_HEAD.fe_run_head), &(FILE_HEAD.fe_run_tail));
    SLOT_FREE(fslotnum, "frontend (remove_running)");
}

#ifdef PERPERL_FRONTEND

int perperl_frontend_collect_status
    (const slotnum_t fslotnum, int *exit_on_sig, int *exit_val)
{
    fe_slot_t *fslot = &FILE_SLOT(fe_slot, fslotnum);

    if (fslot->backend && perperl_backend_dead(fslot->backend))
	perperl_backend_died(fslot->backend);

    if (fslot->backend == 0) {
	*exit_on_sig = fslot->exit_on_sig;
	*exit_val = fslot->exit_val;
	perperl_frontend_remove_running(fslotnum);
	return 1;
    }
    return 0;
}

void perperl_frontend_clean_running(void) {
    /* See if we can kill some dead frontends in the fe_run list */
    while (FILE_HEAD.fe_run_tail && perperl_frontend_dead(FILE_HEAD.fe_run_tail))
	perperl_frontend_remove_running(FILE_HEAD.fe_run_tail);
}


/*
 * Signal handling routines
 */

#define NUMSIGS (sizeof(signum) / sizeof(int))

static const int	signum[] = {SIGALRM};
static char		sig_setup_done;
static time_t		next_alarm;
static SigList		sl;

static void sig_handler_teardown(int put_back_alarm) {

    if (!sig_setup_done)
	return;
    
    alarm(0);

    perperl_sig_free(&sl);

    /* Put back alarm */
    if (put_back_alarm && next_alarm) {
	next_alarm -= perperl_util_time();
	alarm(next_alarm > 0 ? next_alarm : 1);
    }

    sig_setup_done = 0;
}

static void sig_handler_setup(void) {
    sig_handler_teardown(1);

    /* Save alarm for later */
    if ((next_alarm = alarm(0))) {
	next_alarm += perperl_util_time();
    }

    perperl_sig_init(&sl, signum, NUMSIGS, SIG_BLOCK);

    sig_setup_done = 1;
}

/*
 * End of Signal handling routines
 */

#define BE_SUFFIX "_backend"

/* Spawn the be_parent process */
static void be_parent_spawn(slotnum_t gslotnum) {
    int pid;
    const char * const *argv;

    /* Get args for exec'ing backend */
    argv = perperl_opt_exec_argv();

    /* Fork */
    pid = fork();

    if (pid > 0) {
	/* Parent */

	int child_status;

	if (waitpid(pid, &child_status, 0) == -1)
	    perperl_util_die("wait");
    }
    else if (pid == 0) {
	/* Child */

	/* Get rid of alarm handler and any alarms */
	sig_handler_teardown(0);

	/* Unblock any signals due to file lock */
	perperl_file_fork_child();

	/* Fork again */
	pid = fork();

	if (pid == -1) {
	    perperl_util_exit(1,1);
	}
	else if (pid) {
	    /* Parent of Grandchild */

	    /* We don't hold the lock on the temp file, but our parent does,
	     * and it's waiting for us to exit before proceeding, so it's
	     * safe to write to the file here
	     */
	    FILE_SLOT(gr_slot, gslotnum).be_parent = pid;
	    FILE_SLOT(gr_slot, gslotnum).be_starting = pid;

	    perperl_util_exit(0,1);
	}
	else {
	    /* Grandchild */

	    /* We should be in our own session */
	    setsid();

	    /* Exec the backend */
	    perperl_util_execvp(argv[0], argv);

	    /* Failed.  Try the original argv[0] + "_backend" */
	    {
		const char *orig_file = perperl_opt_orig_argv()[0];
		if (orig_file && *orig_file) {
		    char *fname;
		    
		    perperl_new(
			fname, strlen(orig_file)+sizeof(BE_SUFFIX)+1, char
		    );
		    sprintf(fname, "%s%s", orig_file, BE_SUFFIX);
		    perperl_util_execvp(fname, argv);
		}
	    }
	    perperl_util_die(argv[0]);
	}
    } else {
	perperl_util_die("fork");
    }
}

/* Check on / spawn backends.  Should only be done by the fe at the
 * head of the list (think 100+ fe's in the queue)
 */
static int backend_check(slotnum_t gslotnum, int *did_spawn) {
    gr_slot_t *gslot = &FILE_SLOT(gr_slot, gslotnum);

    /* Don't spawn a backend while a backend is starting */
    if (perperl_group_be_starting(gslotnum))
	return 1;

    /* If we already did this once, it didn't work */
    if (*did_spawn)
	return 0;

    /* Start up a be_parent if necessary */
    if (!gslot->be_parent)
	be_parent_spawn(gslotnum);

    /* Are we below the maxbackends limit? */
    if (perperl_backend_below_maxbe(gslotnum)) {

	/* Signal the be parent to start a new backend */
	if (perperl_group_start_be(gslotnum)) {
	    /* Let it start one before spawning again */
	    gslot->be_starting = gslot->be_parent;
	    *did_spawn = 1;
	}
    } else {
	/* If we're above the maxbaceknds limit, we still need to ping the
	 * be parent to make sure it's alive.
	 */
	perperl_group_parent_sig(gslotnum, 0);
    }
    return 1;
}

/* Go up the fe list, going to the next group if we're at the
 * begininng of the list.  Wrap to the first group if we go off the end
 * of the group list.  Worst case we wrap around and return ourself.
 */
static void fe_prev(slotnum_t *gslotnum, slotnum_t *fslotnum) {
    *fslotnum = perperl_slot_prev(*fslotnum);
    while (!*fslotnum) {
	if (!(*gslotnum = perperl_slot_next(*gslotnum)) &&
	    !(*gslotnum = FILE_HEAD.group_head))
	{
	    DIE_QUIET("Group list or frontend lists are corrupt");
	}
	*fslotnum = FILE_SLOT(gr_slot, *gslotnum).fe_tail;
    }
}

static void frontend_check_prev(slotnum_t gslotnum, slotnum_t fslotnum) {
    fe_prev(&gslotnum, &fslotnum);

    while (perperl_frontend_dead(fslotnum)) {
	slotnum_t g_prev = gslotnum, f_prev = fslotnum;

	/* Must do "prev" function while this slot/group is still valid */
	fe_prev(&g_prev, &f_prev);

	/* This frontend is not running so dispose of it */
	perperl_frontend_dispose(gslotnum, fslotnum);

	/* Try to remove this group if possible */
	perperl_group_cleanup(gslotnum);

	/* If we wrapped around to ourself, then all done */
	if (f_prev == fslotnum)
	    break;

	gslotnum = g_prev;
	fslotnum = f_prev;
    }
}

/* Check that the frontend in front of is running.  Also run backend check
 * if we are the head frontend
 */
static int frontend_ping
    (slotnum_t gslotnum, slotnum_t fslotnum, int *did_spawn)
{
    /* Check the frontend previous to us.  This may remove it */
    frontend_check_prev(gslotnum, fslotnum);

    /* If we're not the head of the list, then all done */
    if (perperl_slot_prev(fslotnum))
	return 1;

    /* Do a check of backends.  Returns false if we cannot start be */
    return backend_check(gslotnum, did_spawn);
}


/* Get a backend the hard-way - by queueing up
*/
static int get_a_backend_hard
    (slotnum_t gslotnum, slotnum_t fslotnum, slotnum_t *bslotnum)
{
    int file_changed, did_spawn = 0, spawn_working = 1, sent_sig;
    *bslotnum = 0;

    /* Install sig handlers */
    sig_handler_setup();

    /* Put ourself at the end of the fe queue */
    perperl_slot_append(fslotnum,
	&(FILE_SLOT(gr_slot, gslotnum).fe_head),
	&(FILE_SLOT(gr_slot, gslotnum).fe_tail));

    while (1) {
	/* Send signals to frontends */
	perperl_group_sendsigs(gslotnum);

	sent_sig = FILE_SLOT(fe_slot, fslotnum).sent_sig;
	FILE_SLOT(fe_slot, fslotnum).sent_sig = 0;

	/* If our sent_sig flag is set, and there are be's for us to use ,
	 * then all done.
	*/
	if (sent_sig &&
	    (*bslotnum = perperl_backend_be_wait_get(gslotnum)))
	{
	    break;
	}

	/* Check on frontends/backends running */
	spawn_working = frontend_ping(gslotnum, fslotnum, &did_spawn);

	/* Frontend ping may have invalidated our group */
	if (!spawn_working || !perperl_group_isvalid(gslotnum))
	    break;

	/* Unlock the file */
	perperl_file_set_state(FS_HAVESLOTS);

	/* Set an alarm for one-second or so. */
	alarm(OPTVAL_BECHECKTIMEOUT);

	/* Wait for a timeout or signal from backend */
	perperl_sig_wait(&sl);

	/* Find out if our file changed.  Do this while unlocked */
	file_changed = perperl_script_changed();

	/* Acquire lock.  If group bad or file changed, then done */
	if (!perperl_group_lock(gslotnum) || file_changed)
	    break;
    }

    /* Remove our FE slot from the queue.  */
    perperl_slot_remove(fslotnum,
	&(FILE_SLOT(gr_slot, gslotnum).fe_head),
	&(FILE_SLOT(gr_slot, gslotnum).fe_tail));

    /* Put sighandlers back to their original state */
    sig_handler_teardown(1);

    return spawn_working;
}

static int get_a_backend(slotnum_t fslotnum, slotnum_t *gslotnum) {
    slotnum_t bslotnum = 0;
    int spawn_working = 1;

    /* Locate the group for our script */
    *gslotnum = perperl_script_find();

    /* Try to quickly grab a backend without queueing */
    if (!FILE_SLOT(gr_slot, *gslotnum).fe_head)
	bslotnum = perperl_backend_be_wait_get(*gslotnum);

    /* If that failed, use the queue */
    if (!bslotnum)
	spawn_working = get_a_backend_hard(*gslotnum, fslotnum, &bslotnum);
    
    /* Clean up the group if necessary */
    perperl_group_cleanup(*gslotnum);

    FILE_SLOT(fe_slot, fslotnum).backend = bslotnum;
    return spawn_working;
}


int perperl_frontend_connect(int socks[NUMFDS], slotnum_t *fslotnum_p) {
    static int did_clean;
    int connected = 0, spawn_working = 1, sockets_open = 0;

    /* May need options from the #! line in the script.  This also
     * opens the script file
     */
    perperl_opt_read_shbang();

    while (spawn_working && !connected) {
	slotnum_t gslotnum, bslotnum, fslotnum;

	/* Create sockets in preparation for connect.  This may take a while,
	 * esp on FreeBSD, when it's out of sockets.
	 */
	if (!sockets_open++)
	    perperl_ipc_connect_prepare(socks);

	/* Lock temp file */
	perperl_file_set_state(FS_CORRUPT);

	/* Need to clean out the fe_run list, once per frontend execution */
	if (!did_clean++)
	    perperl_frontend_clean_running();

	/* Allocate a frontend slot */
	fslotnum = SLOT_ALLOC("frontend (perperl_frontend_connect)");
	FILE_SLOT(fe_slot, fslotnum).pid = perperl_util_getpid();

	/* Try to find a backend.  Bad return status if cannot spawn */
	spawn_working = get_a_backend(fslotnum, &gslotnum);

	/* Did we get a backend slot to connect to? */
	if (spawn_working && (bslotnum = FILE_SLOT(fe_slot, fslotnum).backend))
	{
	    /* Try to connect to this backend. */
	    connected = perperl_ipc_connect(bslotnum, socks);

	    if (!connected) {
		/* Failed to connect */
		sockets_open = 0;

		/* Make sure to get rid of backend record */
		perperl_backend_dispose(gslotnum, bslotnum);
	    }
	} else {
	    connected = 0;
	}

	if (fslotnum_p)
	    *fslotnum_p = 0;

	if (connected) {
	    be_slot_t *bslot = &FILE_SLOT(be_slot, bslotnum);

	    /* See if caller wants to hold onto fslot for exit status */
	    if (fslotnum_p) {
		*fslotnum_p = fslotnum;

		/* Link our frontend to that backend */
		bslot->fe_running = fslotnum;

		/* Add our frontend to the list of running fe's */
		perperl_slot_insert(fslotnum, &(FILE_HEAD.fe_run_head), &(FILE_HEAD.fe_run_tail));
	    } else {
		/* Fe_running must be non-zero while backend is running */
		bslot->fe_running = bslotnum;
	    }

	    /* Prevent further spawns until this backend starts to run */
	    FILE_SLOT(gr_slot, gslotnum).be_starting = bslot->pid;
	}

	if (fslotnum_p && *fslotnum_p) {
	    perperl_file_set_state(FS_HAVESLOTS);
	} else {
	    /* Jettison this frontend */
	    SLOT_FREE(fslotnum, "frontend (perperl_frontend_connect)");
	    perperl_file_set_state(FS_OPEN);
	}
    }
    if (sockets_open && !connected) {
	int i;
	for (i = 0; i < NUMFDS; ++i)
	    close(socks[i]);
    }
    perperl_script_close();
    return spawn_working;
}

/* Return size of the buffer needed to send a string of the given length */
#define STR_BUFSIZE(l) (1 + (l >= MAX_SHORT_STR ? sizeof(int) : 0) + l)

/* Add something to the buffer */
#define BUF_ENLARGE(b,l) \
    if ((b)->len + (l) > (b)->alloced) \
	enlarge_buf((b),(l))

#define ADD2(b,s,l) \
    perperl_memcpy((b)->buf + (b)->len, (s), (l)); \
    (b)->len += (l)

#define ADD(b,s,l) BUF_ENLARGE(b,l); ADD2(b,s,l)

#define ADDCHAR2(b,c) ((b)->buf)[(b)->len++] = (char)c
    
#define ADDCHAR(b,c) BUF_ENLARGE(b,1); ADDCHAR2(b,c)

#define ADD_DEVINO(b,stbuf) \
    do { \
	PersistentDevIno devino = perperl_util_stat_devino(stbuf); \
	ADD((b), &devino, sizeof(PersistentDevIno)); \
    } while (0)

#define ADD_STRING(b, s, l) \
    do { \
	if ((l) >= MAX_SHORT_STR) { \
	    BUF_ENLARGE(b, (sizeof(int)+1)); \
	    ADDCHAR2(b, MAX_SHORT_STR); \
	    ADD2(b, &(l), sizeof(int)); \
	} else { \
	    ADDCHAR(b, l); \
	} \
	ADD(b, s, l); \
    } while (0)

static void enlarge_buf(PersistentBuf *b, int min_to_add) {
    int new_size = b->alloced * PERPERL_REALLOC_MULT;
    int min_size = b->len + min_to_add;
    if (new_size < min_size)
	new_size = min_size;
    b->alloced = new_size;
    perperl_renew(b->buf, new_size, char);
}

static void alloc_buf(PersistentBuf *b, int bytes) {
    b->len = 0;
    b->alloced = bytes;
    if (bytes)
	perperl_new(b->buf, bytes, char);
    else
	b->buf = NULL;
}

/* Add a string to the buffer */
static void add_string(PersistentBuf *b, const char *s, int l) {
    ADD_STRING(b, s, l);
}

/* Copy a block of strings into the buffer,  */
/* Profiling shows this is the top function for cpu time */
static void add_strings(register PersistentBuf *b, register const char * const * p)
{
    int l;
    register const char *s;

    /* Add strings in p array */
    for (; (s = *p); ++p) {
	if ((l = strlen(s))) {
	    ADD_STRING(b, s, l);
	}
    }

    /* Terminate with zero-length string */
    ADDCHAR(b, 0);
}

void perperl_frontend_mkenv(
    const char * const * envp, const char * const * scr_argv, int min_alloc,
    PersistentBuf *sb, int script_has_cwd
)
{
    struct stat dir_stat;
    const char *script_fname = perperl_opt_script_fname();

    if (!script_fname)
	perperl_script_missing();

    /* Create buffer */
#ifdef PERPERL_EFENCE
    alloc_buf(sb, min_alloc);
#else
    alloc_buf(sb, max(512, min_alloc));
#endif

    /* Add env and argv */
    add_strings(sb, envp);
    add_strings(sb, scr_argv+1);

    /* Put script filename into buffer */
    add_string(sb, script_fname, strlen(script_fname));

    /* Put script device/inode into buffer */
    ADD_DEVINO(sb, perperl_script_getstat());

    /* Handle passing over cwd */
    if (script_has_cwd) {
	ADDCHAR(sb, PERPERL_CWD_IN_SCRIPT);
    }
    else if (stat(".", &dir_stat) != -1) {
	ADDCHAR(sb, PERPERL_CWD_DEVINO);
	ADD_DEVINO(sb, &dir_stat);
    } else {
	ADDCHAR(sb, PERPERL_CWD_UNKNOWN);
    }
}

void perperl_frontend_proto2(int err_sock, int first_byte) {
    int n, cwd_len, buflen;
    char *bp, *cwd;
    PollInfo pi;
    PersistentBuf b;

    if (!first_byte)
	return;

    /* Get current directory */
    cwd = perperl_util_getcwd();
    cwd_len = cwd ? strlen(cwd) : 0;

    /* Create buffer for the string */
    alloc_buf(&b, STR_BUFSIZE(cwd_len));

    /* Put cwd into the buffer */
    if (cwd) {
	add_string(&b, cwd, cwd_len);
	perperl_free(cwd);
    } else {
	add_string(&b, "", 0);
    }

    /* Send it over */
    perperl_poll_init(&pi, err_sock);
    bp = b.buf;
    buflen = b.len;
    while (1) {

	/* TEST - send over one byte at a time to test the poll */
	/* n = write(err_sock, bp, 1); */

	n = write(err_sock, bp, buflen);
	if (n == -1 && SP_NOTREADY(errno))
	    n = 0;
	if (n == -1)
	    break;

	if (!(buflen -= n))
	    break;
	bp += n;

	/* Do this instead of bothering to change socket to non-blocking */
	perperl_poll_quickwait(&pi, err_sock, PERPERL_POLLOUT, 1000);
    }
    perperl_poll_free(&pi);
    perperl_free(b.buf);

    shutdown(err_sock, 1);
}

#endif /* PERPERL_FRONTEND */
