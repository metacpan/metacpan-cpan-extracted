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

/*
 * Program that starts backends
 */

#include "perperl.h"

#ifdef PERPERL_DEBUG
    static int dont_fork;
#   define NORMAL_RUN (!dont_fork)
#else
#   define NORMAL_RUN 1
#endif

extern char **environ;

static const int oursigs[] = {SIGCHLD, SIGUSR1, SIGALRM};
#define NUM_OURSIGS (sizeof(oursigs) / sizeof(oursigs[0]))

static slotnum_t find_pid(slotnum_t gslotnum, pid_t pid) {
    slotnum_t bslotnum;
    be_slot_t *bslot;

    /* Find bslotnum by pid */
    for (bslotnum = FILE_SLOT(gr_slot, gslotnum).be_head;
	 bslotnum; bslotnum = perperl_slot_next(bslotnum))
    {
        bslot = &FILE_SLOT(be_slot, bslotnum);
        if (bslot->pid == pid)
            return bslotnum;
    }
    return 0;
}

static void collect_child(slotnum_t gslotnum) {
    int pid, exit_val;

    while ((pid = waitpid(-1, &exit_val, WNOHANG)) > 0) {
	slotnum_t bslotnum = 0;

	/* Get bslotnum */
	bslotnum = find_pid(gslotnum, pid);

	if (bslotnum) {
	    int exit_on_sig = WIFSIGNALED(exit_val);

	    /* Tell frontend its exit status */ 
	    perperl_backend_exited(bslotnum, exit_on_sig,
		exit_on_sig ? WTERMSIG(exit_val) : WEXITSTATUS(exit_val));

	    /* Remove it */
	    perperl_backend_dispose(gslotnum, bslotnum);
	}
    }
}

static void start_child(slotnum_t gslotnum, SigList *sl) {
    pid_t pid;
    slotnum_t bslotnum;

    /* Don't spawn while another be is spawning */
    pid = perperl_group_be_starting(gslotnum);
    if (pid && pid != perperl_util_getpid())
	return;

    /* Don't spawn beyond maximum backends */
    if (!perperl_backend_below_maxbe(gslotnum))
	return;

    /* Create backend record */
    bslotnum = perperl_backend_create_slot(gslotnum);

    /* Fork */
    pid = NORMAL_RUN ?  perperl_perl_fork() : perperl_util_getpid();

    if (pid != 0) {
	/* PARENT */

	if (pid == -1) {
	    FILE_SLOT(gr_slot, gslotnum).be_starting = 0;
	    perperl_backend_dispose(gslotnum, bslotnum);
	} else {

	    /* List this be as starting */
	    FILE_SLOT(gr_slot, gslotnum).be_starting = pid;

	    /* Store pid */
	    FILE_SLOT(be_slot, bslotnum).pid = pid;
	}
    }

    if (!NORMAL_RUN || pid == 0) {
	/* CHILD */

	/* Cleanup after fork */
	perperl_util_pid_invalidate();
	if (NORMAL_RUN)
	    perperl_file_fork_child();
	perperl_file_set_state(FS_CLOSED);

	/* Restore signals */
	perperl_sig_free(sl);

	/* Do perl */
	perperl_perl_run(gslotnum, bslotnum);
	perperl_util_exit(0,0);
    }
}

static void do_cleanup(slotnum_t gslotnum) {

    /* Find the prev group, wrap around the end */
    {
	slotnum_t prev;

	if (!(prev = perperl_slot_prev(gslotnum)))
	    prev = FILE_HEAD.group_tail;

	/* Don't check ourself or slot-0 */
	if (!prev || prev == gslotnum)
	    return;

	gslotnum = prev;
    }

    /* Check the group to see if be_parent is alive.  If so, done */
    if (perperl_group_parent_sig(gslotnum, 0))
	return;

    /* Invalidate this group.  This should kill any waiting be's. */
    perperl_group_invalidate(gslotnum);

    /* Check for and clean up any dead bes */
    {
	slotnum_t next, bslotnum;

	for (bslotnum = FILE_SLOT(gr_slot, gslotnum).be_head;
	     bslotnum; bslotnum = next)
	{
	    next = perperl_slot_next(bslotnum);
	    if (perperl_backend_dead(bslotnum))
		perperl_backend_dispose(gslotnum, bslotnum);
	}
    }

    /* Try to delete this group altogether */
    perperl_group_cleanup(gslotnum);
}

int main(int argc, char **argv, char **_junk) {
    slotnum_t gslotnum;
    int i;
    SigList sl;

    perperl_util_unlimit_core();

    if (!(my_perl = perl_alloc()))
        DIE_QUIET("Cannot allocate perl");
    perl_construct(my_perl);

#ifdef PERPERL_DEBUG
    dont_fork = getenv("PERPERL_NOPARENT") != NULL;
#endif

    /*
     * Make sure fd's 0 and 1 are open.
     * Fix for bug where STDOUT couldn't be duped during perl init
     * Tested in begin_dup.t
     */
    if (open("/dev/null", O_RDONLY) == -1 || open("/dev/null", O_WRONLY) == -1)
	perperl_util_die("Cannot open /dev/null");

    /* Initialize options */
    perperl_opt_init((const char * const *)argv, (const char * const *)environ);
    
    /* Open/Stat the script - this could hang */
    perperl_opt_read_shbang();

    /* Initialize interpreter with this script */
    perperl_perl_init();

    /* Close off all I/O except for stderr (close it later) */
    for (i = 32; i >= 0; --i) {
	if (i != 2 && i != PREF_FD_LISTENER)
	    (void) close(i);
    }

    /* Set up sigs */
    perperl_sig_init(&sl, oursigs, NUM_OURSIGS, SIG_BLOCK);

    /* Make sure script is opened before acquiring the lock so we don't hang */
    perperl_script_open();

    /* Lock/mmap our temp file */
    perperl_file_set_state(FS_CORRUPT);

    /* Locate our script in the temp file */
    gslotnum = perperl_script_find();

    /* Close the script file */
    perperl_script_close();

    /* Install our pid as the be_parent */
    if (NORMAL_RUN) {
	gr_slot_t *gslot = &FILE_SLOT(gr_slot, gslotnum);
	int pid = gslot->be_parent;
	int ourpid = perperl_util_getpid();

	/* If not us, signal the real parent that a backend should start */
	if (pid && pid != ourpid && perperl_group_start_be(gslotnum)) {
	    perperl_file_set_state(FS_CLOSED);
	    perperl_util_exit(0, 0);
	}
	gslot->be_parent = ourpid;
    }

    /* Start one child */
    start_child(gslotnum, &sl);

    while (1) {
	int have_children;

	/* Unlock file */
	perperl_file_set_state(FS_HAVESLOTS);

	/* Wait for sig from dead child or from frontend */
	perperl_sig_wait(&sl);

	/* Get ready to write file */
	perperl_file_set_state(FS_CORRUPT);

	/* Look for children to collect */
	collect_child(gslotnum);

	/* Look to see if we should start a child */
	if (perperl_group_isvalid(gslotnum) && perperl_sig_got(&sl, SIGUSR1))
	    start_child(gslotnum, &sl);

	/* Check other groups in the file for cleanup */
	do_cleanup(gslotnum);

	/* Do we have any children left? */
	have_children = FILE_SLOT(gr_slot, gslotnum).be_head;

	/* If no children and got an alarm, exit */
	if (perperl_sig_got(&sl, SIGALRM) && !have_children)
	    break;

	/* If no children, set an alarm */
	alarm(have_children ? 0 : 10);
    }
    perperl_file_set_state(FS_CORRUPT);
    perperl_group_cleanup(gslotnum);
    perperl_file_set_state(FS_CLOSED);
    perperl_util_exit(0, 0);
    return 0;
}

