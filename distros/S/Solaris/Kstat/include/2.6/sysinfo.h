/*	Copyright (c) 1984, 1986, 1987, 1988, 1989 AT&T	*/
/*	  All Rights Reserved  	*/

/*	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF AT&T	*/
/*	The copyright notice above does not evidence any   	*/
/*	actual or intended publication of such source code.	*/

/*
 * Copyright (c) 1996, by Sun Microsystems, Inc.
 * All rights reserved.
 */

#ifndef _SYS_SYSINFO_H
#define	_SYS_SYSINFO_H

#pragma ident	"@(#)sysinfo.h	1.21	96/05/16 SMI"	/* SVr4.0 11.14 */

#include <sys/t_lock.h>

#ifdef	__cplusplus
extern "C" {
#endif

/*
 *	System Information.
 */
#define	CPU_IDLE	0
#define	CPU_USER	1
#define	CPU_KERNEL	2
#define	CPU_WAIT	3
#define	CPU_STATES	4

#define	W_IO		0
#define	W_SWAP		1
#define	W_PIO		2
#define	W_STATES	3

typedef struct cpu_sysinfo {
	ulong	cpu[CPU_STATES]; /* CPU utilization			*/
	ulong	wait[W_STATES];	/* CPU wait time breakdown		*/
	ulong	bread;		/* physical block reads			*/
	ulong	bwrite;		/* physical block writes (sync+async)	*/
	ulong	lread;		/* logical block reads			*/
	ulong	lwrite;		/* logical block writes			*/
	ulong	phread;		/* raw I/O reads			*/
	ulong	phwrite;	/* raw I/O writes			*/
	ulong	pswitch;	/* context switches			*/
	ulong	trap;		/* traps				*/
	ulong	intr;		/* device interrupts			*/
	ulong	syscall;	/* system calls				*/
	ulong	sysread;	/* read() + readv() system calls	*/
	ulong	syswrite;	/* write() + writev() system calls	*/
	ulong	sysfork;	/* forks				*/
	ulong	sysvfork;	/* vforks				*/
	ulong	sysexec;	/* execs				*/
	ulong	readch;		/* bytes read by rdwr()			*/
	ulong	writech;	/* bytes written by rdwr()		*/
	ulong	rcvint;		/* XXX: UNUSED				*/
	ulong	xmtint;		/* XXX: UNUSED				*/
	ulong	mdmint;		/* XXX: UNUSED				*/
	ulong	rawch;		/* terminal input characters		*/
	ulong	canch;		/* chars handled in canonical mode	*/
	ulong	outch;		/* terminal output characters		*/
	ulong	msg;		/* msg count (msgrcv()+msgsnd() calls)	*/
	ulong	sema;		/* semaphore ops count (semop() calls)	*/
	ulong	namei;		/* pathname lookups			*/
	ulong	ufsiget;	/* ufs_iget() calls			*/
	ulong	ufsdirblk;	/* directory blocks read		*/
	ulong	ufsipage;	/* inodes taken with attached pages	*/
	ulong	ufsinopage;	/* inodes taked with no attached pages	*/
	ulong	inodeovf;	/* inode table overflows		*/
	ulong	fileovf;	/* file table overflows			*/
	ulong	procovf;	/* proc table overflows			*/
	ulong	intrthread;	/* interrupts as threads (below clock)	*/
	ulong	intrblk;	/* intrs blkd/prempted/released (swtch)	*/
	ulong	idlethread;	/* times idle thread scheduled		*/
	ulong	inv_swtch;	/* involuntary context switches		*/
	ulong	nthreads;	/* thread_create()s			*/
	ulong	cpumigrate;	/* cpu migrations by threads 		*/
	ulong	xcalls;		/* xcalls to other cpus 		*/
	ulong	mutex_adenters;	/* failed mutex enters (adaptive)	*/
	ulong	rw_rdfails;	/* rw reader failures			*/
	ulong	rw_wrfails;	/* rw writer failures			*/
	ulong	modload;	/* times loadable module loaded		*/
	ulong	modunload;	/* times loadable module unloaded 	*/
	ulong	bawrite;	/* physical block writes (async)	*/
/* Following are gathered only under #ifdef STATISTICS in source 	*/
	ulong	rw_enters;	/* tries to acquire rw lock		*/
	ulong	win_uo_cnt;	/* reg window user overflows		*/
	ulong	win_uu_cnt;	/* reg window user underflows		*/
	ulong	win_so_cnt;	/* reg window system overflows		*/
	ulong	win_su_cnt;	/* reg window system underflows		*/
	ulong	win_suo_cnt;	/* reg window system user overflows	*/
} cpu_sysinfo_t;

typedef struct sysinfo {	/* (update freq) update action		*/
	ulong	updates;	/* (1 sec) ++				*/
	ulong	runque;		/* (1 sec) += num runnable procs	*/
	ulong	runocc;		/* (1 sec) ++ if num runnable procs > 0	*/
	ulong	swpque;		/* (1 sec) += num swapped procs		*/
	ulong	swpocc;		/* (1 sec) ++ if num swapped procs > 0	*/
	ulong	waiting;	/* (1 sec) += jobs waiting for I/O	*/
} sysinfo_t;

typedef struct cpu_syswait {
	long	iowait;		/* procs waiting for block I/O		*/
	long	swap;		/* XXX: UNUSED				*/
	long	physio;		/* XXX: UNUSED 				*/
} cpu_syswait_t;

typedef struct cpu_vminfo {
	ulong	pgrec;		/* page reclaims (includes pageout)	*/
	ulong	pgfrec;		/* page reclaims from free list		*/
	ulong	pgin;		/* pageins				*/
	ulong	pgpgin;		/* pages paged in			*/
	ulong	pgout;		/* pageouts				*/
	ulong	pgpgout;	/* pages paged out			*/
	ulong	swapin;		/* swapins				*/
	ulong	pgswapin;	/* pages swapped in			*/
	ulong	swapout;	/* swapouts				*/
	ulong	pgswapout;	/* pages swapped out			*/
	ulong	zfod;		/* pages zero filled on demand		*/
	ulong	dfree;		/* pages freed by daemon or auto	*/
	ulong	scan;		/* pages examined by pageout daemon	*/
	ulong	rev;		/* revolutions of the page daemon hand	*/
	ulong	hat_fault;	/* minor page faults via hat_fault()	*/
	ulong	as_fault;	/* minor page faults via as_fault()	*/
	ulong	maj_fault;	/* major page faults			*/
	ulong	cow_fault;	/* copy-on-write faults			*/
	ulong	prot_fault;	/* protection faults			*/
	ulong	softlock;	/* faults due to software locking req	*/
	ulong	kernel_asflt;	/* as_fault()s in kernel addr space	*/
	ulong	pgrrun;		/* times pager scheduled		*/
} cpu_vminfo_t;

typedef struct vminfo {		/* (update freq) update action		*/
	longlong_t freemem; 	/* (1 sec) += freemem in pages		*/
	longlong_t swap_resv;	/* (1 sec) += reserved swap in pages	*/
	longlong_t swap_alloc;	/* (1 sec) += allocated swap in pages	*/
	longlong_t swap_avail;	/* (1 sec) += unreserved swap in pages	*/
	longlong_t swap_free;	/* (1 sec) += unallocated swap in pages	*/
} vminfo_t;

/*
 * Per-CPU statistics structure
 */
typedef struct cpu_stat {
	kmutex_t	cpu_stat_lock;
	cpu_sysinfo_t	cpu_sysinfo;
	cpu_syswait_t	cpu_syswait;
	cpu_vminfo_t	cpu_vminfo;
} cpu_stat_t;

#ifdef	__cplusplus
}
#endif

#endif	/* _SYS_SYSINFO_H */
