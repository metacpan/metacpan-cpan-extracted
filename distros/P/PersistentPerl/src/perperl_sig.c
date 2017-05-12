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

/*
 * Signal handling routines
 */

static volatile int got_sig[PERPERL_MAXSIG];
static sigset_t blockall_save;
static int all_blocked;

void perperl_sig_blockall(void) {
    sigset_t full_set;

    sigfillset(&full_set);
    sigprocmask(SIG_BLOCK, &full_set, &blockall_save);
    all_blocked = 1;
}

void perperl_sig_blockall_undo(void) {
    sigprocmask(SIG_SETMASK, &blockall_save, NULL);
    all_blocked = 0;
}

static int sig_find(const volatile int sig_rcvd[PERPERL_MAXSIG], int sig) {
    register int i;

    for (i = 0; i < PERPERL_MAXSIG && sig_rcvd[i]; ++i) {
	if (sig_rcvd[i] == sig)
	    return -1;
    }
    return i;
}

static void sig_handler(int sig) {
    int i;

    if ((i = sig_find(got_sig, sig)) >= 0 && i < PERPERL_MAXSIG) {
	got_sig[i++] = sig;
	if (i < PERPERL_MAXSIG)
	    got_sig[i] = 0;
    }
}

static void sig_wait_basic(const SigList *sl) {
    for (got_sig[0] = 0; !got_sig[0];)
	sigsuspend(&sl->unblock_sigs);
}

void perperl_sig_wait(SigList *sl) {
    sig_wait_basic(sl);
    perperl_util_time_invalidate();
    perperl_memcpy(sl->sig_rcvd, got_sig, sizeof(got_sig));
}

int perperl_sig_got(const SigList *sl, int sig) {
    return sig_find(sl->sig_rcvd, sig) == -1;
}

static void sig_init2(SigList *sl, int how) {
    int i;

    /* Set up handlers and save old action setting */
    {
	struct sigaction sigact;
	sigact.sa_handler = &sig_handler;
	sigact.sa_flags = 0;
	sigemptyset(&sigact.sa_mask);
	for (i = 0; i < sl->numsigs; ++i)
	    sigaction(sl->signum[i],  &sigact, &(sl->sigact_save[i]));
    }

    /* Block or unblock our signals.  Save original mask */
    if (all_blocked) {
	sl->sigset_save = blockall_save;
	for (i = 0; i < sl->numsigs; ++i) {
	    if (how == SIG_BLOCK)
		sigaddset(&blockall_save, sl->signum[i]);
	    else
		sigdelset(&blockall_save, sl->signum[i]);
	}
    } else {
	sigset_t block_sigs;
	sigemptyset(&block_sigs);
	for (i = 0; i < sl->numsigs; ++i)
	    sigaddset(&block_sigs, sl->signum[i]);
	sigprocmask(how, &block_sigs, &sl->sigset_save);
    }

    /* Make an unblock mask for our signals */
    sl->unblock_sigs = sl->sigset_save;
    for (i = 0; i < sl->numsigs; ++i)
	sigdelset(&sl->unblock_sigs, sl->signum[i]);
}

void perperl_sig_init(SigList *sl, const int *sigs, int numsigs, int how) {

    /* Copy in args */
    if (numsigs > PERPERL_MAXSIG)
	DIE_QUIET("Too many sigs passed to sig_init");
    perperl_memcpy(sl->signum, sigs, numsigs * sizeof(int));
    sl->numsigs = numsigs;

    /* Finish init */
    sig_init2(sl, how);
}

void perperl_sig_free(const SigList *sl) {
    int i;
    
    /* Get rid of any pending signals.  On Sun/apache-2 we don't get pending
     * signals as soon as they are unblocked - instead they get delivered
     * after the action is restored, which is not what we want.
     */
    do {
	sigset_t set;
	
	/* Bug in Mac OS X 10.1 and earlier - sigpending is essentially a
	 * no-op, so we get garbage, and get stuck in sigsuspend.
	 * Workaround by clearing out the set initially so we get no pending
	 * signals back.
	 */
	sigemptyset(&set);

	if (sigpending(&set) == -1)
	    break;
	for (i = 0; i < sl->numsigs; ++i) {
	    if (sigismember(&set, sl->signum[i])) {
		sig_wait_basic(sl);
		break;
	    }
	}
    } while (i < sl->numsigs);

    /* Unblock sigs */
    if (all_blocked)
	blockall_save = sl->sigset_save;
    else
	sigprocmask(SIG_SETMASK, &sl->sigset_save, NULL);

    /* Install old handlers */
    for (i = 0; i < sl->numsigs; ++i)
	sigaction(sl->signum[i], &(sl->sigact_save[i]), NULL);
}
