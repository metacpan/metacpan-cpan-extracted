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

#define PERPERL_MAXSIG 3

typedef struct {
    int			signum[PERPERL_MAXSIG];
    struct sigaction	sigact_save[PERPERL_MAXSIG];
    int			sig_rcvd[PERPERL_MAXSIG];
    sigset_t		unblock_sigs;
    sigset_t		sigset_save;
    int			numsigs;
} SigList;

int perperl_sig_got(const SigList *sl, int sig);
void perperl_sig_wait(SigList *sl);
void perperl_sig_init(SigList *sl, const int *sigs, int numsigs, int how);
void perperl_sig_free(const SigList *sl);
void perperl_sig_blockall(void);
void perperl_sig_blockall_undo(void);
