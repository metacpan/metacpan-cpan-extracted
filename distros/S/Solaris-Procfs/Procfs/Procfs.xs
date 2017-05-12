#ifdef __cplusplus
extern "C" {
#endif

#include "Procfs.h"

#ifdef __cplusplus
}
#endif

/* With typemap, maps HvObject to a blessed HV */
typedef HV HvObject;

/* Convert a struct of type prheader_t (sys/procfs.h) to a Perl hash */
SV *
_prheader2hash(prheader_t * prheader) 
{
	HV*   hash = newHV();

	SAVE_INT32( hash, prheader, pr_nent );
	SAVE_INT32( hash, prheader, pr_entsize );

	return ( newRV_noinc( (SV*) hash ) );
}

/* Convert a struct of type timespec_t to a Perl hash */
SV *
_timespec2hash(timespec_t * time) 
{
	HV*   hash = newHV();

	SAVE_INT32( hash, time, tv_sec );
	SAVE_INT32( hash, time, tv_nsec );

	return ( newRV_noinc( (SV*) hash ) );
}

/* Convert a struct of type sigset_t (signal.h) to a Perl hash */
SV *
_sigset2hash(sigset_t * sigset) 
{
	AV*   __sigbits = newAV();
	HV*   hash      = newHV();
	int   i = 0;
	int   n = 4;

	for (i = 0; i < n; i++)
	{
		av_push(__sigbits, (SV *) NEW_UIV( *(sigset->__sigbits + i) )); 
	}

	SAVE_REF(hash, __sigbits); 

	return ( newRV_noinc( (SV*) hash ) );
}

/* Convert a struct of type fltset_t (fault.h) to a Perl hash */
SV *
_fltset2hash(fltset_t * fltset) 
{
	AV*   word = newAV();
	HV*   hash = newHV();
	int   i = 0;
	int   n = 4;

	for (i = 0; i < n; i++)
	{
		av_push(word, (SV *) NEW_UIV( *(fltset->word + i) ));
	}

	SAVE_REF(hash, word);

	return ( newRV_noinc( (SV*) hash ) );
}


/* Convert a struct of type sysset_t (syscall.h) to a Perl hash */
SV *
_sysset2hash(sysset_t * sysset) 
{
	AV*   word = newAV();
	HV*   hash = newHV();
	int   i = 0;
	int   n = 16;

	for (i = 0; i < n; i++)
	{
		av_push(word, (SV *) NEW_UIV( *(sysset->word + i) ));
	}

	SAVE_REF(hash, word);

	return ( newRV_noinc( (SV*) hash ) );
}


/* Convert a value of type prgreg_t (procfs_isa.h) (a simple array) 
 * to a Perl list  
 */
SV *
_prgregset2list(prgregset_t * prgregset) 
{
	AV*   list = newAV();
	int   i = 0;
	int   n = NPRGREG;  /* preprocessor alias defined in sys/procfs_isa.h */
	char  address[ HEXVAL_AS_STRING ];

	for (i = 0; i < n; i++)
	{

/*#ifdef __sparc*/
		/* av_push(list, (SV *) NEW_UIV( (IV) *(prgregset+i) ) ); */
 		sprintf(address, "%08X", *(prgregset+i)); 
		av_push(list, newSVpv(address, 0)); 
/*#endif*/

		SAVE_HEXVAL_TO_LIST(list, *(prgregset+i), address);
	}

	return ( newRV_noinc( (SV*) list ) );
}

#ifdef __sparc
#ifdef __SunOS_5_7
/* Convert the struct fq (sys/regset.h) to a Perl hash. */
SV *
_fq2hash(struct fq * fq) 
{
	HV*  hash = newHV();
	HV*  FQu  = newHV();
	HV*  fpq  = newHV();

	/* fpq_addr is a pointer to type unsigned int -- we store the literal address */
	hv_store( fpq, "fpqinstr", sizeof("fpqinstr") - 1, newSViv(         (IV) fq->FQu.fpq.fpq_addr  ), 0 );
	hv_store( fpq, "fpqaddr",  sizeof("fpqaddr")  - 1, newSViv(              fq->FQu.fpq.fpq_instr ), 0 );

	hv_store( FQu, "fpq",      sizeof("fpq")   - 1,    newRV_noinc(    (SV*) fpq                   ), 0 );
	hv_store( FQu, "whole",    sizeof("whole") - 1,    newSVnv(     (double) fq->FQu.whole         ), 0 );

	hv_store( hash, "FQu",     sizeof("FQu") - 1,      newRV_noinc(    (SV*) FQu                   ), 0 );

	return ( newRV_noinc( (SV*) hash ) );
}
#endif  /* ifdef __SunOS_5_7 */
#endif  /* ifdef __sparc     */


/* Convert the struct prfpregset_t (sys/procfs_isa.h) to a Perl hash. */
/* or is it sys/regset.h? */
SV *
_prfpregset2hash(prfpregset_t * prfpregset) 
{
	char  address[ HEXVAL_AS_STRING ];
	int   i; 

#ifdef __i386

	/*  x86  */

	AV*   state     = newAV();
	AV*   f_wregs   = newAV();
	AV*   f_fpregs  = newAV();

	HV*   fpchip_state  = newHV();
	HV*   fp_emul_space = newHV();
	HV*   fp_reg_set    = newHV();

	HV*   hash          = newHV();

	/* Handle the embedded union fp_reg_set -- 
	 * render it as a reference to a hash 
	 */
	for (i = 0; i < 27; i++)
	{
		SAVE_HEXVAL_TO_LIST(state, prfpregset->fp_reg_set.fpchip_state.state[i], address);
	}

	SAVE_REF(   fpchip_state, state );
	hv_store(   fpchip_state, "status", sizeof("status") - 1, 
		newSViv(prfpregset->fp_reg_set.fpchip_state.status), 0);

	hv_store(   fp_emul_space, "fp_emul",  sizeof("fp_emul") - 1, 
		newSVpv(  prfpregset->fp_reg_set.fp_emul_space.fp_emul, 1), 0); 
	hv_store(   fp_emul_space, "fp_emul",  sizeof("fp_epad") - 1, 
		newSVpv(  prfpregset->fp_reg_set.fp_emul_space.fp_epad, 1), 0); 

	for (i = 0; i < 62; i++)
	{
		SAVE_HEXVAL_TO_LIST(f_fpregs, prfpregset->fp_reg_set.f_fpregs[i], address);
	}

	SAVE_REF(   fp_reg_set, fpchip_state  );
	SAVE_REF(   fp_reg_set, fp_emul_space );
	SAVE_REF(   fp_reg_set, f_fpregs );

	for (i = 0; i < 33; i++)
	{
		SAVE_HEXVAL_TO_LIST(f_wregs, prfpregset->f_wregs[i], address);
	}

	SAVE_REF(   hash, fp_reg_set );
	SAVE_REF(   hash, f_wregs );

#else   /* if not defined __i386  */
	/* SPARC */

	AV*   pr_regs  = newAV();
	AV*   pr_dregs = newAV();
	AV*   pr_q     = newAV();

	HV*   pr_fr    = newHV();
	HV*   hash     = newHV();

	/* Handle the embedded union pr_fr -- 
	 * render it as a reference to a hash 
	 */
	for (i = 0; i < 32; i++)
	{
		SAVE_HEXVAL_TO_LIST(pr_regs, prfpregset->pr_fr.pr_regs[i], address);
	}

	for (i = 0; i < 16; i++)
	{
		SAVE_HEXVAL_TO_LIST(pr_dregs, prfpregset->pr_fr.pr_dregs[i], address);
	}

	SAVE_REF( pr_fr, pr_regs );
	SAVE_REF( pr_fr, pr_dregs );
	SAVE_REF( hash,  pr_fr );

	SAVE_UINT32( hash, prfpregset, pr_fsr );
	SAVE_INT32(  hash, prfpregset, pr_qcnt );
	SAVE_INT32(  hash, prfpregset, pr_q_entrysize );
	SAVE_INT32(  hash, prfpregset, pr_en );

#ifdef __SunOS_5_6
	for (i = 0; i < 64; i++)
	{
		av_push(pr_q, newSViv( (IV) prfpregset->pr_q[i] ) );
	}
#endif

#ifdef __SunOS_5_7
	for (i = 0; i < 32; i++)
	{
		av_push(pr_q, _fq2hash( prfpregset->pr_q + i ) );
	}
#endif

	SAVE_REF(hash, pr_q);

#endif   /* if defined __i386  */
         /* SPARC & x86 */

	return ( newRV_noinc( (SV*) hash ) );
}

/* Convert the struct stack_t (sys/types.h) to a Perl hash. */
SV *
_stack2hash(stack_t * stack) 
{
	HV*   hash = newHV();

	/* ss_sp is a pointer to type void -- we store the literal address */
	hv_store( hash, "ss_sp",    sizeof("ss_sp") - 1,    newSViv( (IV) stack->ss_sp),    0 );
	hv_store( hash, "ss_size",  sizeof("ss_size") - 1,  newSViv(      stack->ss_size),  0 );
	hv_store( hash, "ss_flags", sizeof("ss_flags") - 1, newSViv(      stack->ss_flags), 0 );

	/*
	SAVE_INT32( hash, stack, ss_sp    );
	SAVE_INT32( hash, stack, ss_size  );
	SAVE_INT32( hash, stack, ss_flags );
	*/

	return ( newRV_noinc( (SV*) hash ) );
}


/* Convert the struct sigaction (sys/signal.h) to a Perl hash. */
SV *
_sigaction2hash(struct sigaction * sigaction) 
{
	HV*   hash    = newHV();
	AV*   sa_resv = newAV();
	int i;

	hv_store( hash, "sa_flags", sizeof("sa_flags") - 1, newSViv(sigaction->sa_flags),       0 );
	hv_store( hash, "sa_mask",  sizeof("sa_mask") - 1,  _sigset2hash(& sigaction->sa_mask), 0 );

	for (i = 0; i < 2; i++)
	{
		av_push(sa_resv, (SV*) newSViv( sigaction->sa_resv[i] ) );
	}
	hv_store( hash, "sa_resv",  sizeof("sa_resv")  - 1, newRV_noinc( (SV*) sa_resv   ), 0 );


	/* _funcptr is a pointer to a function -- we render this as the string "NOT IMPLEMENTED".
	 */
	  hv_store( hash, "_funcptr", sizeof("_funcptr") - 1,   
		newSVsv( perl_get_sv( "Solaris::Procfs::not_implemented", 0)), 0);

	return ( newRV_noinc( (SV*) hash ) );
}



/* Convert a struct of type pstatus_t (sys/procfs.h) to a Perl hash */
SV *
_lwpstatus2hash(lwpstatus_t * lwpstatus) 
{
	HV*   hash      = newHV();
	AV*   pr_sysarg = newAV();
	int i;


	SAVE_INT32(hash, lwpstatus, pr_flags);
	SAVE_INT32(hash, lwpstatus, pr_lwpid);
	SAVE_INT32(hash, lwpstatus, pr_why);
	SAVE_INT32(hash, lwpstatus, pr_what);
	SAVE_INT32(hash, lwpstatus, pr_cursig);


	SAVE_STRUCT(hash, lwpstatus, pr_lwppend, _sigset2hash );
	SAVE_STRUCT(hash, lwpstatus, pr_lwphold, _sigset2hash );
	SAVE_STRUCT(hash, lwpstatus, pr_action, _sigaction2hash );
	SAVE_STRUCT(hash, lwpstatus, pr_altstack, _stack2hash );
/*	SAVE_STRUCT(hash, lwpstatus, pr_info,    _siginfo2hash );  */

	hv_store(hash, "pr_oldcontext", sizeof("pr_oldcontext") - 1, newSViv( (IV) lwpstatus->pr_oldcontext),  0 );

	SAVE_INT32(hash, lwpstatus, pr_syscall);
	SAVE_INT32(hash, lwpstatus, pr_nsysarg);
	SAVE_INT32(hash, lwpstatus, pr_errno);



	for (i = 0; i < PRSYSARGS ; i++) /* Constant defined in sys/procfs.h */
	{
		av_push(pr_sysarg, (SV *) NEW_UIV( lwpstatus->pr_sysarg[i] ));
	}
	hv_store(hash, "pr_sysarg",  sizeof("pr_sysarg") - 1, newRV_noinc( (SV*) pr_sysarg ), 0 );

	SAVE_UINT32(hash, lwpstatus, pr_rval1);
	SAVE_UINT32(hash, lwpstatus, pr_rval2);
	SAVE_STRING(hash, lwpstatus, pr_clname );
	SAVE_STRUCT(hash, lwpstatus, pr_tstamp, _timespec2hash  );
	SAVE_UINT32(hash, lwpstatus, pr_instr);
	SAVE_STRUCT(hash, lwpstatus, pr_reg,   _prgregset2list  );
	SAVE_STRUCT(hash, lwpstatus, pr_fpreg, _prfpregset2hash );

	return ( newRV_noinc( (SV*) hash ) );
}


/* Convert a struct of type prmap_t (sys/procfs.h) to a Perl hash */
SV *
_prmap2hash(prmap_t * prmap) 
{
	HV*   hash = newHV();
	char  address[ HEXVAL_AS_STRING ];

	SAVE_INT32(hash,  prmap, pr_size);
	SAVE_HEXVAL(hash, prmap, pr_vaddr, address);
	SAVE_STRING(hash, prmap, pr_mapname );

	SAVE_INT(hash, prmap, pr_offset);

	/*SAVE_INT32(hash,  prmap, pr_mflags);*/
	SAVE_HEXVAL(hash, prmap, pr_mflags, address);
	SAVE_INT32(hash,  prmap, pr_pagesize);
	SAVE_INT32(hash,  prmap, pr_shmid);

	return ( newRV_noinc( (SV*) hash ) );
}

/* Convert a struct of type prxmap_t (sys/procfs.h) to a Perl hash */
SV *
_prxmap2hash(prxmap_t * prxmap) 
{
	HV*   hash = newHV();
	char  address[ HEXVAL_AS_STRING ];

	SAVE_INT32(hash,  prxmap, pr_size);
	SAVE_HEXVAL(hash, prxmap, pr_vaddr, address);
	SAVE_STRING(hash, prxmap, pr_mapname );

	SAVE_INT(hash, prxmap, pr_offset);

	/*SAVE_INT32(hash,  prxmap, pr_mflags);*/
	SAVE_HEXVAL(hash, prxmap, pr_mflags, address);
	SAVE_INT32(hash,  prxmap, pr_pagesize);
	SAVE_INT32(hash,  prxmap, pr_shmid);
	SAVE_INT32(hash,  prxmap, pr_dev);
	SAVE_INT64(hash,  prxmap, pr_ino);
	SAVE_UINT32(hash,  prxmap, pr_anon);
#ifndef __SunOS_5_9
	SAVE_UINT32(hash,  prxmap, pr_ashared);
	SAVE_UINT32(hash,  prxmap, pr_aref);
	SAVE_UINT32(hash,  prxmap, pr_amod);
	SAVE_UINT32(hash,  prxmap, pr_vnode);
	SAVE_UINT32(hash,  prxmap, pr_vshared);
	SAVE_UINT32(hash,  prxmap, pr_vref);
	SAVE_UINT32(hash,  prxmap, pr_vmod);
#endif

	return ( newRV_noinc( (SV*) hash ) );
}


/* Convert a struct of type pstatus_t (sys/procfs.h) to a Perl hash */
SV *
_prusage2hash(prusage_t * prusage) 
{
	HV*   hash = newHV();

	SAVE_INT32(hash, prusage, pr_lwpid);
	SAVE_INT32(hash, prusage, pr_count);

	SAVE_STRUCT(hash, prusage, pr_tstamp,   _timespec2hash );
	SAVE_STRUCT(hash, prusage, pr_create,   _timespec2hash );
	SAVE_STRUCT(hash, prusage, pr_term,     _timespec2hash );
	SAVE_STRUCT(hash, prusage, pr_rtime,    _timespec2hash );
	SAVE_STRUCT(hash, prusage, pr_utime,    _timespec2hash );
	SAVE_STRUCT(hash, prusage, pr_stime,    _timespec2hash );
	SAVE_STRUCT(hash, prusage, pr_ttime,    _timespec2hash );
	SAVE_STRUCT(hash, prusage, pr_tftime,   _timespec2hash );
	SAVE_STRUCT(hash, prusage, pr_dftime,   _timespec2hash );
	SAVE_STRUCT(hash, prusage, pr_kftime,   _timespec2hash );
	SAVE_STRUCT(hash, prusage, pr_ltime,    _timespec2hash );
	SAVE_STRUCT(hash, prusage, pr_slptime,  _timespec2hash );
	SAVE_STRUCT(hash, prusage, pr_wtime,    _timespec2hash );
	SAVE_STRUCT(hash, prusage, pr_stoptime, _timespec2hash );

	SAVE_INT(hash, prusage, pr_minf);
	SAVE_INT(hash, prusage, pr_majf);
	SAVE_INT(hash, prusage, pr_nswap);
	SAVE_INT(hash, prusage, pr_inblk);
	SAVE_INT(hash, prusage, pr_oublk);
	SAVE_INT(hash, prusage, pr_msnd);
	SAVE_INT(hash, prusage, pr_mrcv);
	SAVE_INT(hash, prusage, pr_sigs);
	SAVE_INT(hash, prusage, pr_vctx);
	SAVE_INT(hash, prusage, pr_ictx);
	SAVE_INT(hash, prusage, pr_sysc);
	SAVE_INT(hash, prusage, pr_ioch);

	return ( newRV_noinc( (SV*) hash ) );
}

/* Convert a struct of type pstatus_t (sys/procfs.h) to a Perl hash */
SV *
_pstatus2hash(pstatus_t * pstatus) 
{
	HV*   hash = newHV();
	char  address[ HEXVAL_AS_STRING ];

	SAVE_INT32(hash, pstatus, pr_flags);
	SAVE_INT32(hash, pstatus, pr_nlwp);
	SAVE_INT32(hash, pstatus, pr_pid);
	SAVE_INT32(hash, pstatus, pr_pgid);
	SAVE_INT32(hash, pstatus, pr_ppid);
	SAVE_INT32(hash, pstatus, pr_sid);

	SAVE_INT32(hash, pstatus, pr_aslwpid);
	SAVE_INT32(hash, pstatus, pr_agentid);
	/* SAVE_INT32(hash, pstatus, pr_brkbase); */
	SAVE_HEXVAL(hash, pstatus, pr_brkbase, address);
	SAVE_INT32(hash, pstatus, pr_brksize);

	/* SAVE_INT32(hash, pstatus, pr_stkbase);*/
	SAVE_HEXVAL(hash, pstatus, pr_stkbase, address);
	SAVE_INT32(hash, pstatus, pr_stksize);

	SAVE_STRUCT(hash, pstatus, pr_sigpend,  _sigset2hash );
	SAVE_STRUCT(hash, pstatus, pr_sigtrace, _sigset2hash );
	SAVE_STRUCT(hash, pstatus, pr_sysentry, _sysset2hash );
	SAVE_STRUCT(hash, pstatus, pr_sysexit,  _sysset2hash );

	SAVE_STRUCT(hash, pstatus, pr_flttrace, _fltset2hash );

	SAVE_STRUCT(hash, pstatus, pr_utime,  _timespec2hash );
	SAVE_STRUCT(hash, pstatus, pr_stime,  _timespec2hash );
	SAVE_STRUCT(hash, pstatus, pr_cutime, _timespec2hash );
	SAVE_STRUCT(hash, pstatus, pr_cstime, _timespec2hash );

	SAVE_STRUCT(hash, pstatus, pr_lwp,    _lwpstatus2hash );

	return ( newRV_noinc( (SV*) hash ) );
}


/* Convert a struct of type lwpsinfo_t (sys/procfs.h) to a Perl hash */
SV *
_lwpsinfo2hash(lwpsinfo_t * lwpsinfo) 
{
	HV*   hash    = newHV();

	SAVE_INT32(hash, lwpsinfo, pr_flag);
	SAVE_INT32(hash, lwpsinfo, pr_lwpid);
/*	SAVE_INT32(hash, lwpsinfo, pr_addr);  */
/*	SAVE_INT32(hash, lwpsinfo, pr_wchan);  */
	SAVE_INT32(hash, lwpsinfo, pr_stype);
	SAVE_INT32(hash, lwpsinfo, pr_state);

	hv_store(hash, "pr_sname", sizeof("pr_sname") - 1, newSVpv( ttyname(lwpsinfo->pr_sname), 1), 0); 

	SAVE_INT32(hash, lwpsinfo, pr_nice);
	SAVE_INT32(hash, lwpsinfo, pr_syscall);
	SAVE_INT32(hash, lwpsinfo, pr_oldpri);
	SAVE_INT32(hash, lwpsinfo, pr_cpu);

	/* pr_pctcpu is a  16-bit binary fractions in  the
	 * range  0.0  to 1.0 with the binary point to the right of the
	 * high-order bit (1.0 == 0x8000). Here, we divide it by
	 * 32768 and multply by 100 to get a percentage value. 
	 * The maximium value for pr_pctcpu is 1/N, where N is the
	 * number of processes on the machine. 
	 */
	hv_store(hash, "pr_pctcpu", sizeof("pr_pctcpu") - 1, newSVnv( lwpsinfo->pr_pctcpu / 327.68 ), 0);

	SAVE_STRUCT(hash, lwpsinfo, pr_start,  _timespec2hash );
	SAVE_STRUCT(hash, lwpsinfo, pr_time,   _timespec2hash );

	SAVE_STRING(hash, lwpsinfo, pr_clname );
	SAVE_STRING(hash, lwpsinfo, pr_name );

	SAVE_INT32(hash, lwpsinfo, pr_onpro);
	SAVE_INT32(hash, lwpsinfo, pr_bindpro);
	SAVE_INT32(hash, lwpsinfo, pr_bindpset);

	return ( newRV_noinc( (SV*) hash ) );
}

/* Given a tty device number, return a scalar containing a string
 * which is the name of that device.  We grab this from the hash
 * called %Solaris::Procfs::TTYDEVS, which is filled by Procfs.pm
 * at module load time.
 */
SV *
_get_ttyname(dev_t * ttydev)
{
	SV*   ttynum   = newSViv(* ttydev); 
	SV**  ttyname;
	HV*   Ttydevs  = perl_get_hv( "Solaris::Procfs::TTYDEVS", 0);
	STRLEN len;
	
       	sv_2mortal(ttynum);	
	if (*ttydev == PRNODEV) {
		/* if the controlling terminal is not defined */
		return newSVpv("?", 0);
	} else if (
		/* Look up the ttydev in the Ttydevs hash */
		Ttydevs != NULL &&
		(ttyname = hv_fetch( Ttydevs, SvPV(ttynum, len), sv_len(ttynum), 0)) != NULL
	) {
		return newSVsv(*ttyname);
	} else {

		/* Can't determine the ttydev */
		return newSVpv("??", 0);
	}
}


/* Convert a struct of type psinfo_t (sys/procfs.h) to a Perl hash */
SV *
_psinfo2hash(psinfo_t * psinfo) 
{
	HV*   hash    = newHV();
	AV*   pr_argv = newAV();
	AV*   pr_envp = newAV();
	int i;
	char fdesc;
	char filepath[MAXPATHLEN];
	char error_mesg[1024 + MAXPATHLEN];
	char **argvp = NULL;
	char *buf = NULL;
	char *envp;
	uid_t	euid;
	long maxsize;
	off_t envloc;
	int n;

	SAVE_INT32(hash, psinfo, pr_flag);
	SAVE_INT32(hash, psinfo, pr_nlwp);
	SAVE_INT32(hash, psinfo, pr_pid);
	SAVE_INT32(hash, psinfo, pr_pgid);
	SAVE_INT32(hash, psinfo, pr_ppid);
	SAVE_INT32(hash, psinfo, pr_sid);
	SAVE_INT32(hash, psinfo, pr_uid);
	SAVE_INT32(hash, psinfo, pr_euid);
	SAVE_INT32(hash, psinfo, pr_gid);
/*	SAVE_INT32(hash, psinfo, pr_addr);  */ 
	SAVE_INT32(hash, psinfo, pr_size);
	SAVE_INT32(hash, psinfo, pr_rssize);

	SAVE_STRUCT(hash, psinfo, pr_ttydev,  _get_ttyname );

	/* pr_pctcpu and pr_pctmem are 16-bit binary fractions in  the
	 * range  0.0  to 1.0 with the binary point to the right of the
	 * high-order bit (1.0 == 0x8000). pr_pctcpu is  the  summation
	 * over all lwps in the process.    Here, we divide them by
	 * 32768 and multply by 100 to get a percentage value. 
	 */
	hv_store(hash, "pr_pctcpu", sizeof("pr_pctcpu") - 1, newSVnv( psinfo->pr_pctcpu / 327.68 ), 0);
	hv_store(hash, "pr_pctmem", sizeof("pr_pctmem") - 1, newSVnv( psinfo->pr_pctmem / 327.68 ), 0);

	SAVE_STRUCT(hash, psinfo, pr_start,  _timespec2hash );
	SAVE_STRUCT(hash, psinfo, pr_time,   _timespec2hash );
	SAVE_STRUCT(hash, psinfo, pr_ctime,  _timespec2hash );
	SAVE_STRING(hash, psinfo, pr_fname );
	SAVE_STRING(hash, psinfo, pr_psargs );
	SAVE_INT32( hash, psinfo, pr_wstat);
	SAVE_INT32( hash, psinfo, pr_argc);

	/*
	 * To get the argv vector and environment variables for the process you need to 
	 * be either root or the owner of the process.  Otherwise you will not be able
	 * to open the processes memory.
	 */
	euid = geteuid();
	if ((euid == 0) || (euid == psinfo->pr_euid)) {

		/*
		 * Find the maximum length of the ARG information.
		 */

		if ((maxsize=sysconf(_SC_ARG_MAX)) < 0) {
        		perror("error calling sysconf");
			hv_store(hash, "pr_argv", sizeof("pr_argv") - 1, 
				newSVsv(perl_get_sv( "Solaris::Procfs::insufficient_memory", 0)), 0);
			hv_store(hash, "pr_envp", sizeof("pr_envp") - 1, 
				newSVsv(perl_get_sv( "Solaris::Procfs::insufficient_memory", 0)), 0);
		}

		/* 
		 * If we are root, or if we are opening our own process space,
		 * then we should be able to open up the address space to find out
		 * the arguments and the environment for the process.
		 *
		 * They are located at the memory locations specified by psinfo->pr_argv and psinfo->pr_envp
		 * respectively and ar stored/accessed like they are for the main line of the program.
		 *
		 * ie: int main(char *argv[],argc, char *envp[]);
		 *
		 * The memory location is the offset in the memory space file (/proc/<pid>/as).
		 *
		 */
		sprintf(filepath, "/proc/%d/%s", psinfo->pr_pid,"as");
		if ( (fdesc = open(filepath, O_RDONLY)) < 0 ) {

			sprintf(error_mesg, "Error opening file /proc/%d/%s", psinfo->pr_pid,"as");
			perror(error_mesg);
			FORGET_STRUCT(hash, pr_argv, Solaris::Procfs::not_owner);
			FORGET_STRUCT(hash, pr_envp, Solaris::Procfs::not_owner);

		} else {

			/*
			 * First find all of the command line arguments
			 * (the memory location for *argv[])
			 */

			/*
			 *   Using the argc from the psinfo structure, create an array
			 *   and store the argv pointers.
			 */
			argvp = (char **) malloc(sizeof(char *) * (psinfo->pr_argc + 1));

			if (pread(fdesc,argvp,(sizeof(char *) * (psinfo->pr_argc + 1)),psinfo->pr_argv) <= 0) {
				perror("pread when getting command line arguments from memory for process");
				close(fdesc);
				FORGET_STRUCT(hash, pr_argv, Solaris::Procfs::read_failed);
				FORGET_STRUCT(hash, pr_envp, Solaris::Procfs::read_failed);
			} else {

				/*
				 *   Loop through the argv values upto a count of argc.  Save  
				 *   each argument in a separate memory location.
				 */
				buf = (char *)malloc(maxsize);
				if (buf == NULL) {
					perror("malloc failed for initial storage buffer");
					close(fdesc);
					FORGET_STRUCT(hash, pr_argv, Solaris::Procfs::insufficient_memory);
					FORGET_STRUCT(hash, pr_envp, Solaris::Procfs::insufficient_memory);
				} else {
					for (n = 0; n < psinfo->pr_argc; n++) {
						if (pread(fdesc,buf,maxsize-1,(off_t)argvp[n]) <= 0) {
							perror("pread error reading command line arguments");
							close(fdesc);
							FORGET_STRUCT(hash, pr_argv, Solaris::Procfs::read_failed);
							FORGET_STRUCT(hash, pr_envp, Solaris::Procfs::read_failed);
						} else {
							av_push(pr_argv, newSVpv(   buf , 0   ));
						}
					}
				}

				SAVE_REF(hash, pr_argv);
	
				/* now the environment */
				envloc = psinfo->pr_envp;
	
				/* prime the pump by finding the first env location */
				if (pread(fdesc,&envp,sizeof(char *),envloc) <= 0) {
					perror("pread of initial environment location");
					close(fdesc);
					FORGET_STRUCT(hash, pr_argv, Solaris::Procfs::read_failed);
					FORGET_STRUCT(hash, pr_envp, Solaris::Procfs::read_failed);
				} else {
					do {
						if (pread(fdesc,buf,maxsize-1,(off_t)envp) <= 0) {
							perror("pread of environment pointer location");
							close(fdesc);
							FORGET_STRUCT(hash, pr_argv, Solaris::Procfs::read_failed);
							FORGET_STRUCT(hash, pr_envp, Solaris::Procfs::read_failed);
							continue;
						}
					
						av_push(pr_envp, newSVpv(   buf , 0   ));
	
						/* step through the *envp pointer list to point to where the next pointer location would be */
						envloc = envloc + sizeof(char *);
	
						/* get the next environment pointer */
						if (pread(fdesc,&envp,sizeof(char *),envloc) <= 0) {
							perror("pread of environment location");
							close(fdesc);
							FORGET_STRUCT(hash, pr_argv, Solaris::Procfs::read_failed);
							FORGET_STRUCT(hash, pr_envp, Solaris::Procfs::read_failed);
							continue;
						}
					} while (envp != NULL );
				}
			}
			SAVE_REF(hash, pr_envp);

			close(fdesc);

		} /* end if ( (fdesc = open(filepath, O_RDONLY)) < 0 )  */

	} else {   
		/*
		 * this should only happen if the process died or you don't have permission to
		 * read the "/proc/<pid>/as file.  Which means you are either not root or
		 * you are not the owner of the process
				av_push(pr_envp, newSVpv(   buf , 0   ));
		 */
		FORGET_STRUCT(hash, pr_argv, Solaris::Procfs::not_owner);
		FORGET_STRUCT(hash, pr_envp, Solaris::Procfs::not_owner);

	} /* end if ((euid == 0) || (euid == psinfo->pr_euid))  */
	
	SAVE_STRUCT(hash, psinfo, pr_lwp,  _lwpsinfo2hash );  
	free(buf);
	free(argvp);

	return ( newRV_noinc( (SV*) hash ) );
}

/* Convert a struct of type prcred_t (sys/procfs.h) to a Perl hash */
SV *
_prcred2hash(prcred_t * prcred) 
{
	HV*   hash = newHV();
	AV*   groups = newAV();
	gid_t i;

	SAVE_INT32(hash, prcred, pr_euid);
	SAVE_INT32(hash, prcred, pr_ruid);
	SAVE_INT32(hash, prcred, pr_suid);

	SAVE_INT32(hash, prcred, pr_egid);
	SAVE_INT32(hash, prcred, pr_rgid);
	SAVE_INT32(hash, prcred, pr_sgid);
	
	SAVE_INT32(hash, prcred, pr_ngroups);

	for (i = 0; i < prcred->pr_ngroups ; i++) 
	{
		av_push(groups, (SV *) newSViv(     prcred->pr_groups[i] ));
	}
	hv_store(hash, "pr_groups",  sizeof("pr_groups") - 1, newRV_noinc( (SV*) groups ), 0 );

	return ( newRV_noinc( (SV*) hash ) );
}


/* Convert a struct of type auxv_t (sys/auxv.h) to a Perl hash */
SV *
_auxv2hash(auxv_t * auxv) 
{
	HV*  hash = newHV();
	HV*  a_un = newHV();
	char address[HEXVAL_AS_STRING];

	SAVE_INT(hash, auxv, a_type);

	sprintf(address, "%08X", auxv->a_un.a_ptr); 
	hv_store(a_un, "a_ptr", sizeof("a_ptr") - 1, newSVpv(address, 0), 0); 
	hv_store(a_un, "a_fcn", sizeof("a_fcn") - 1, 
		newSVsv(perl_get_sv( "Solaris::Procfs::not_implemented", 0)), 0);

	hv_store(hash, "a_un",  sizeof("a_un")  - 1, newRV_noinc( (SV*) a_un ), 0 );

	return ( newRV_noinc( (SV*) hash ) );
}



/* Generic function for opening a file and reading in an aribtrary number
 * of structs, which are of an arbitrary type.  We accept as parameters
 * the number of structs we expect to read in, a pointer to a buffer
 * of the correct type for that struct, a size_t indicating the size
 * of the buffer, a pointer to the name (basename) of the file we want to open,
 * the process id, and a pointer to a function for converting that struct 
 * into a Perl hash or list.  This function must take as parameters a pointer and an int,
 * and we expect it to return a Perl reference. 
 *
 * If expected_count equals 1, then we return the reference returned by the call
 * to the function pointer. 
 *
 * If expected_count is anything else, then we return a reference to a list consisting
 * of references to eash converted struct that we read in from the file. 
 */
SV *
read_proc_file(int code, void * buffer, size_t buffsize, 
	char * filename, int pid, SV* (*func)(void *) )      
{

	int             fdesc;
	int             bytes = 0;
	/*SV*             retval = newSVpv("", 0);*/
	SV*             retval = NULL;

	/* Fixed-length buffer will hold the name of the file 
	 * under the /proc hierarchy which we want to access. 
	 */
	char            filepath[MAXPATHLEN];

	/* For debugging */
	/* printf("/proc/%d/%s\n", pid, filename); */

	/* Pid = pid; */

	sprintf(filepath, "/proc/%d/%s", pid, filename);

	if ( (fdesc = open(filepath, O_RDONLY)) > -1 ) {

		/* Just read in one copy of the given struct. 
		 */
		if (code == 1) {

			if ((bytes = read( fdesc, buffer, buffsize )) > 0 )
			{
				retval = func(buffer);
			}
			/*
			else
				printf("Read zero bytes from %s\n",filepath);
			*/

		/* Read in one prheader_t, then a list of structs of the given type. 
		 */
		} else if (code == 2) {

			AV* list = newAV();
			prheader_t prheader;

			bytes = read( fdesc, &prheader, sizeof(prheader_t) );

			av_push(list, _prheader2hash(&prheader));

			while( (bytes = read( fdesc, buffer, buffsize )) > 0)
			{
				av_push(list, func(buffer));
			}
			retval = newRV_noinc( (SV*) list );

		/* Read in a list of structs of the given type. 
		 */
		} else {

			AV* list = newAV();

			while( (bytes = read( fdesc, buffer, buffsize )) > 0)
			{
				av_push(list, func(buffer));
			}
			retval = newRV_noinc( (SV*) list );
		}
	}
	close(fdesc);

	return retval;
}



/******************************************************************************/
/**                                                                          **/
/** XS code begins here                                                      **/
/**                                                                          **/
/******************************************************************************/
/******************************************************************************/

MODULE = Solaris::Procfs	PACKAGE = Solaris::Procfs
PROTOTYPES: ENABLE

int
_hello()
   CODE:
   printf("Hello, world!\n");

SV *
_sigact(pid) 
	int             pid;
	PREINIT:
	struct sigaction sigact;
	CODE:
	RETVAL = read_proc_file(
		0, (void *) &sigact, sizeof(struct sigaction), 
		"sigact", pid, (SV* (*)(void *)) &_sigaction2hash);

	if (RETVAL == NULL) XSRETURN_UNDEF;

	OUTPUT:
	RETVAL


SV *
_status(pid) 
	int             pid;
	PREINIT:
	pstatus_t       pstatus;
	CODE:
	RETVAL = read_proc_file( 
		1, (void *) &pstatus, sizeof(pstatus_t), 
		"status", pid, (SV* (*)(void *)) &_pstatus2hash);

	if (RETVAL == NULL) XSRETURN_UNDEF;

	OUTPUT:
	RETVAL


SV *
_prcred(pid) 
	int             pid;
	PREINIT:
	/* We need a big buffer, because a prcred struct contains
	 * an array of gid_t, of up to NGROUPS_MAX in length. 
	 */
        char            prcred_buffer[( sizeof(prcred_t) + ((NGROUPS_MAX) * sizeof(gid_t)) )];
	CODE:
	RETVAL = read_proc_file( 
		1, (void *) prcred_buffer, sizeof(prcred_t) + ((NGROUPS_MAX) * sizeof(gid_t)), 
		"cred", pid, (SV* (*)(void *)) &_prcred2hash);

	if (RETVAL == NULL) XSRETURN_UNDEF;

	OUTPUT:
	RETVAL


SV *
_psinfo(pid) 
	int             pid;
	PREINIT:
	psinfo_t        psinfo;
	CODE:
	RETVAL = read_proc_file( 
		1, (void *) &psinfo, sizeof(psinfo_t), 
		"psinfo", pid, (SV* (*)(void *)) &_psinfo2hash);

	if (RETVAL == NULL) XSRETURN_UNDEF;

	OUTPUT:
	RETVAL


SV *
_lpsinfo(pid) 
	int             pid;
	PREINIT:
	lwpsinfo_t        lwpsinfo;
	CODE:

	RETVAL = read_proc_file( 
		2, (void *) &lwpsinfo, sizeof(lwpsinfo_t), 
		"lpsinfo", pid, (SV* (*)(void *)) &_lwpsinfo2hash);

	if (RETVAL == NULL) XSRETURN_UNDEF;

	OUTPUT:
	RETVAL



SV *
_lstatus(pid) 
	int             pid;
	PREINIT:
	lwpstatus_t        lwpstatus;
	CODE:

	RETVAL = read_proc_file( 
		2, (void *) &lwpstatus, sizeof(lwpstatus), 
		"lstatus", pid, (SV* (*)(void *)) &_lwpstatus2hash);

	if (RETVAL == NULL) XSRETURN_UNDEF;

	OUTPUT:
	RETVAL



SV *
_lusage(pid) 
	int             pid;
	PREINIT:
	prusage_t        prusage;
	CODE:

	RETVAL = read_proc_file( 
		2, (void *) &prusage, sizeof(prusage), 
		"lusage", pid, (SV* (*)(void *)) &_prusage2hash);

	if (RETVAL == NULL) XSRETURN_UNDEF;

	OUTPUT:
	RETVAL



SV *
_usage(pid) 
	int             pid;
	PREINIT:
	prusage_t        prusage;
	CODE:

	RETVAL = read_proc_file( 
		1, (void *) &prusage, sizeof(prusage), 
		"usage", pid, (SV* (*)(void *)) &_prusage2hash);

	if (RETVAL == NULL) XSRETURN_UNDEF;

	OUTPUT:
	RETVAL



SV *
_map(pid) 
	int             pid;
	PREINIT:
	prmap_t         prmap;
	CODE:

	RETVAL = read_proc_file( 
		0, (void *) &prmap, sizeof(prmap), 
		"map", pid, (SV* (*)(void *)) &_prmap2hash);

	if (RETVAL == NULL) XSRETURN_UNDEF;

	OUTPUT:
	RETVAL

SV *
_xmap(pid) 
	int             pid;
	PREINIT:
	prxmap_t        prxmap;
	CODE:

	RETVAL = read_proc_file( 
		0, (void *) &prxmap, sizeof(prxmap), 
		"xmap", pid, (SV* (*)(void *)) &_prxmap2hash);

	if (RETVAL == NULL) XSRETURN_UNDEF;

	OUTPUT:
	RETVAL


SV *
_auxv(pid) 
	int             pid;
	PREINIT:
	auxv_t		auxv;
	CODE:

	RETVAL = read_proc_file( 
		0, (void *) &auxv, sizeof(auxv), 
		"auxv", pid, (SV* (*)(void *)) &_auxv2hash);

	if (RETVAL == NULL) XSRETURN_UNDEF;

	OUTPUT:
	RETVAL



SV *
_writectl(pid,...)
	int         pid;

	CODE:
	int         i;
	long int    args[32];
	int         fdesc;
	char        filepath[MAXPATHLEN];

	for(i = 0; i < items - 1; i++) {

		args[i] = (long) SvIV( ST(i+1) );
	}
	sprintf(filepath,"/proc/%d/ctl", pid);

	if ((fdesc = open(filepath,O_WRONLY)) > -1) 
	{
		int bytes_written = 0;

		bytes_written = write(fdesc, args, sizeof(long) * (items - 1));
		close(fdesc);

		RETVAL = newSViv( bytes_written ); 

	} else {
		/* Return false ("") on any errors */
		RETVAL = newSVpv("", 0);
	}

	OUTPUT:
	RETVAL


SV *
_rmap(pid) 
	int             pid;
	PREINIT:
	prmap_t         prmap;
	CODE:

	RETVAL = read_proc_file( 
		0, (void *) &prmap, sizeof(prmap), 
		"rmap", pid, (SV* (*)(void *)) &_prmap2hash);

	if (RETVAL == NULL) XSRETURN_UNDEF;

	OUTPUT:
	RETVAL



SV *
_lwp(pid)
	int		pid;

	PREINIT:

	DIR             *dp;
	struct dirent   *de;
#ifdef _POSIX_PTHREAD_SEMANTICS
	struct dirent   *dr;
#endif

	/* We need a big buffer here, because a dirent struct
	 * contains a variable-length name field.
	 */
	char            de_buffer[(sizeof(struct dirent) + MAXNAMELEN)];

	char            filepath[MAXPATHLEN];
	HV *		hash = newHV();

	lwpstatus_t	lwpstatus;
	lwpsinfo_t	lwpsinfo;
	prusage_t	prusage;

	SV *		val = NULL;

	CODE:

	sprintf( filepath, "/proc/%d/lwp", pid );

	if ((dp = opendir(filepath)) == NULL) { 
		hv_undef(hash);
		XSRETURN_UNDEF;
	}

	de = (struct dirent *) de_buffer;

	while (
#ifdef _POSIX_PTHREAD_SEMANTICS
		( (struct dirent *) readdir_r(dp,de,&dr)) != NULL
#else
		( (struct dirent *) readdir_r(dp,de)) != NULL
#endif
	) {

		/* Only look at pid dirs */
		if (de->d_name[0] >= '0' && de->d_name[0] <= '9') {
			HV* lwp = newHV();

			sprintf( filepath, "lwp/%s/lwpstatus", de->d_name );
			val = read_proc_file(  
				1, (void *) &lwpstatus, sizeof(lwpstatus),  
				filepath, pid, (SV* (*)(void *)) &_lwpstatus2hash); 

			if (val != NULL)  
				hv_store( lwp, "lwpstatus", sizeof("lwpstatus") - 1, val, 0 ); 

			sprintf( filepath, "lwp/%s/lwpsinfo", de->d_name );
			val = read_proc_file( 
				1, (void *) &lwpsinfo, sizeof(lwpsinfo), 
				filepath, pid, (SV* (*)(void *)) &_lwpsinfo2hash);

			if (val != NULL) 
				hv_store( lwp, "lwpsinfo", sizeof("lwpsinfo") - 1, val, 0 );
			

			sprintf( filepath, "lwp/%s/lwpusage", de->d_name );
			val = read_proc_file(    
				1, (void *) &prusage, sizeof(prusage),    
				filepath, pid, (SV* (*)(void *)) &_prusage2hash);   
 
			if (val != NULL)
				hv_store( lwp, "lwpusage", sizeof("lwpusage") - 1, val, 0 );   

			hv_store( hash, de->d_name, strlen(de->d_name), newRV_noinc( (SV*) lwp  ), 0 );
		}
	}
	closedir(dp);

	RETVAL = newRV_noinc( (SV *) hash );

	OUTPUT:
	RETVAL


