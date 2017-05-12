#include "Kstat.h"
#include <kstat.h>
#include <2.6/sysinfo.h>
#include <2.6/var.h>

/******************************************************************************/

void save_2_6_cpu_stat(HV *self, kstat_t *kp)
{
cpu_stat_t    *statp;
cpu_sysinfo_t *sysinfop;
cpu_syswait_t *syswaitp;
cpu_vminfo_t  *vminfop;

/* PERL_ASSERT(kp->ks_ndata == 1); */
PERL_ASSERT(kp->ks_data_size == sizeof(cpu_stat_t));
statp = (cpu_stat_t*)(kp->ks_data);
sysinfop = &statp->cpu_sysinfo;
syswaitp = &statp->cpu_syswait;
vminfop  = &statp->cpu_vminfo;

hv_store(self, "idle", 4, NEW_UIV(sysinfop->cpu[CPU_IDLE]), 0);
hv_store(self, "user", 4, NEW_UIV(sysinfop->cpu[CPU_USER]), 0);
hv_store(self, "kernel", 6, NEW_UIV(sysinfop->cpu[CPU_KERNEL]), 0);
hv_store(self, "wait", 4, NEW_UIV(sysinfop->cpu[CPU_WAIT]), 0);
hv_store(self, "wait_io", 7, NEW_UIV(sysinfop->wait[W_IO]), 0);
hv_store(self, "wait_swap", 9, NEW_UIV(sysinfop->wait[W_SWAP]), 0);
hv_store(self, "wait_pio",  8, NEW_UIV(sysinfop->wait[W_PIO]), 0);
SAVE_UINT32(self, sysinfop, bread);
SAVE_UINT32(self, sysinfop, bwrite);
SAVE_UINT32(self, sysinfop, lread);
SAVE_UINT32(self, sysinfop, lwrite);
SAVE_UINT32(self, sysinfop, phread);
SAVE_UINT32(self, sysinfop, phwrite);
SAVE_UINT32(self, sysinfop, pswitch);
SAVE_UINT32(self, sysinfop, trap);
SAVE_UINT32(self, sysinfop, intr);
SAVE_UINT32(self, sysinfop, syscall);
SAVE_UINT32(self, sysinfop, sysread);
SAVE_UINT32(self, sysinfop, syswrite);
SAVE_UINT32(self, sysinfop, sysfork);
SAVE_UINT32(self, sysinfop, sysvfork);
SAVE_UINT32(self, sysinfop, sysexec);
SAVE_UINT32(self, sysinfop, readch);
SAVE_UINT32(self, sysinfop, writech);
SAVE_UINT32(self, sysinfop, rcvint);
SAVE_UINT32(self, sysinfop, xmtint);
SAVE_UINT32(self, sysinfop, mdmint);
SAVE_UINT32(self, sysinfop, rawch);
SAVE_UINT32(self, sysinfop, canch);
SAVE_UINT32(self, sysinfop, outch);
SAVE_UINT32(self, sysinfop, msg);
SAVE_UINT32(self, sysinfop, sema);
SAVE_UINT32(self, sysinfop, namei);
SAVE_UINT32(self, sysinfop, ufsiget);
SAVE_UINT32(self, sysinfop, ufsdirblk);
SAVE_UINT32(self, sysinfop, ufsipage);
SAVE_UINT32(self, sysinfop, ufsinopage);
SAVE_UINT32(self, sysinfop, inodeovf);
SAVE_UINT32(self, sysinfop, fileovf);
SAVE_UINT32(self, sysinfop, procovf);
SAVE_UINT32(self, sysinfop, intrthread);
SAVE_UINT32(self, sysinfop, intrblk);
SAVE_UINT32(self, sysinfop, idlethread);
SAVE_UINT32(self, sysinfop, inv_swtch);
SAVE_UINT32(self, sysinfop, nthreads);
SAVE_UINT32(self, sysinfop, cpumigrate);
SAVE_UINT32(self, sysinfop, xcalls);
SAVE_UINT32(self, sysinfop, mutex_adenters);
SAVE_UINT32(self, sysinfop, rw_rdfails);
SAVE_UINT32(self, sysinfop, rw_wrfails);
SAVE_UINT32(self, sysinfop, modload);
SAVE_UINT32(self, sysinfop, modunload);
SAVE_UINT32(self, sysinfop, bawrite);
#ifdef STATISTICS
SAVE_UINT32(self, sysinfop, rw_enters);
SAVE_UINT32(self, sysinfop, win_uo_cnt);
SAVE_UINT32(self, sysinfop, win_uu_cnt);
SAVE_UINT32(self, sysinfop, win_so_cnt);
SAVE_UINT32(self, sysinfop, win_su_cnt);
SAVE_UINT32(self, sysinfop, win_suo_cnt);
#endif

SAVE_INT32(self, syswaitp, iowait);
SAVE_INT32(self, syswaitp, swap);
SAVE_INT32(self, syswaitp, physio);

SAVE_UINT32(self, vminfop, pgrec);
SAVE_UINT32(self, vminfop, pgfrec);
SAVE_UINT32(self, vminfop, pgin);
SAVE_UINT32(self, vminfop, pgpgin);
SAVE_UINT32(self, vminfop, pgout);
SAVE_UINT32(self, vminfop, pgpgout);
SAVE_UINT32(self, vminfop, swapin);
SAVE_UINT32(self, vminfop, pgswapin);
SAVE_UINT32(self, vminfop, swapout);
SAVE_UINT32(self, vminfop, pgswapout);
SAVE_UINT32(self, vminfop, zfod);
SAVE_UINT32(self, vminfop, dfree);
SAVE_UINT32(self, vminfop, scan);
SAVE_UINT32(self, vminfop, rev);
SAVE_UINT32(self, vminfop, hat_fault);
SAVE_UINT32(self, vminfop, as_fault);
SAVE_UINT32(self, vminfop, maj_fault);
SAVE_UINT32(self, vminfop, cow_fault);
SAVE_UINT32(self, vminfop, prot_fault);
SAVE_UINT32(self, vminfop, softlock);
SAVE_UINT32(self, vminfop, kernel_asflt);
SAVE_UINT32(self, vminfop, pgrrun);
}

/******************************************************************************/

void save_2_6_var(HV *self, kstat_t *kp)
{
struct var *varp;

/* PERL_ASSERT(kp->ks_ndata == 1); */
PERL_ASSERT(kp->ks_data_size == sizeof(struct var));
varp = (struct var*)(kp->ks_data);

SAVE_INT32(self, varp, v_buf);
SAVE_INT32(self, varp, v_call);
SAVE_INT32(self, varp, v_proc);
SAVE_INT32(self, varp, v_maxupttl);
SAVE_INT32(self, varp, v_nglobpris);
SAVE_INT32(self, varp, v_maxsyspri);
SAVE_INT32(self, varp, v_clist);
SAVE_INT32(self, varp, v_maxup);
SAVE_INT32(self, varp, v_hbuf);
SAVE_INT32(self, varp, v_hmask);
SAVE_INT32(self, varp, v_pbuf);
SAVE_INT32(self, varp, v_sptmap);
SAVE_INT32(self, varp, v_maxpmem);
SAVE_INT32(self, varp, v_autoup);
SAVE_INT32(self, varp, v_bufhwm);
}

/******************************************************************************/
