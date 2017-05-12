#ifdef __cplusplus
extern "C" {
#endif
#include <os2.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

SV *
proc_info_int(int pid, int flags)
{
    PQTOPLEVEL top;
    PQPROCESS	procdata;
    PQTHREAD threads;
    PQMODULE	moddata;
    SV *sv;
    AV *top_av, *procs_av, *mods_av;
    ULONG rc;

    /*  It is not safe to get an info about a non-existing PID until
	circa W3fp18.  This call is available starting from Warp3.  */
    if (pid && CheckOSError(DosVerifyPidTid(pid,1)))
	return Nullsv;
    top = get_sysinfo(	pid, (flags & 1 ? QSS_PROCESS : 0)
			     | (flags & 2 ? QSS_MODULE : 0)
			     | (flags & 4 ? QSS_SEMAPHORES : 0)
			     | (flags & 8 ? QSS_SHARED : 0)
			     | (flags & 256 ? QSS_FILE : 0)
			);
    if (top == NULL) return 0;
    top_av = newAV();
    procs_av = newAV();
    mods_av = newAV();

    sv = newRV((SV*)top_av);
    SvREFCNT_dec(top_av);		/* Ouch! */
    
    av_push(top_av, newRV((SV*)procs_av));
    SvREFCNT_dec(procs_av);		/* Ouch! */
    av_push(top_av, newRV((SV*)mods_av));
    SvREFCNT_dec(mods_av);		/* Ouch! */

    procdata = top->procdata;
    while (procdata && procdata->rectype == 0x01) {
	AV *proc_av = newAV();
	AV *threads_av = newAV();
	AV *dlls_av = newAV();
	int dll_c = 0;
	
	av_push(procs_av, newRV_noinc((SV*)proc_av));
	
	av_push(proc_av, newRV_noinc((SV*)threads_av));
	av_push(proc_av, newSViv(procdata->pid));
	av_push(proc_av, newSViv(procdata->ppid));
	av_push(proc_av, newSViv(procdata->type));
	av_push(proc_av, newSViv(procdata->state));
	av_push(proc_av, newSViv(procdata->sessid));
	av_push(proc_av, newSViv(procdata->hndmod));
	av_push(proc_av, newSViv(procdata->threadcnt));
	av_push(proc_av, newSViv(procdata->privsem32cnt));
	av_push(proc_av, newSViv(procdata->sem16cnt));
	av_push(proc_av, newSViv(procdata->dllcnt));
	av_push(proc_av, newSViv(procdata->shrmemcnt));
	av_push(proc_av, newSViv(procdata->fdscnt));
	av_push(proc_av, newRV_noinc((SV*)dlls_av));
	while (dll_c < procdata->dllcnt) {
	    av_push(dlls_av, newSViv(procdata->dlls[dll_c++]));
	}
	threads = procdata->threads;
	while (threads && threads->rectype == 0x100) { /* Thread block. */
	    AV *thread_av = newAV();

	    av_push(threads_av, newRV_noinc((SV*)thread_av));

	    av_push(thread_av, newSViv(threads->threadid));
	    av_push(thread_av, newSViv(threads->slotid));
	    av_push(thread_av, newSViv(threads->sleepid));
	    av_push(thread_av, newSViv(threads->priority));
	    av_push(thread_av, newSViv(threads->systime));
	    av_push(thread_av, newSViv(threads->usertime));
	    av_push(thread_av, newSViv(threads->state));
	    threads++;
	}
	procdata = (PQPROCESS) threads;	/* Next process data. */
    }
/*
    if (procdata) 
	warn("After: procdata->rectype = 0x%x", procdata->rectype);
 */
    moddata = top->moddata;
    while (moddata) {
	AV *mod_av = newAV();
	int handles = moddata->refcnt;

	av_push(mods_av, newRV((SV*)mod_av));
	SvREFCNT_dec(mod_av);		/* Ouch! */

	av_push(mod_av, newSViv(moddata->hndmod));
	av_push(mod_av, newSViv(moddata->type));
	av_push(mod_av, newSViv(moddata->refcnt));
	av_push(mod_av, newSViv(moddata->segcnt));
	av_push(mod_av, newSVpv(moddata->name,0));
	while (handles--) {
	    av_push(mod_av, newSViv(moddata->modref[handles]));
	}
	moddata = moddata->next;
    }

    Safefree(top);
    return sv;
}

SV *
global_info_int()
{
    PQTOPLEVEL top = get_sysinfo(getpid(), QSS_PROCESS);
    SV *sv;
    AV *av;
    
    if (top == NULL) return 0;
    av = newAV();
    sv = newRV((SV*)av);
    SvREFCNT_dec(av);			/* Oups! */
    av_extend(av, 3);
    av_push(av, newSViv(top->gbldata->threadcnt));
    av_push(av, newSViv(top->gbldata->proccnt));
    av_push(av, newSViv(top->gbldata->modulecnt));
    Safefree(top);
    return sv;
}


MODULE = OS2::Proc		PACKAGE = OS2::Proc		

SV *
proc_info_int(pid = getpid(), flags = 3)
    int pid
    int flags

SV *
global_info_int()

