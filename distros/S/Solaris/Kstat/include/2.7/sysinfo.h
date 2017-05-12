/*	Copyright (c) 1984, 1986, 1987, 1988, 1989 AT&T	*/
/*	  All Rights Reserved  	*/

/*	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF AT&T	*/
/*	The copyright notice above does not evidence any   	*/
/*	actual or intended publication of such source code.	*/

/*
 * Copyright (c) 1996-1997, by Sun Microsystems, Inc.
 * All rights reserved.
 */

#ifndef _SYS_SYSINFO_H
#define	_SYS_SYSINFO_H

#pragma ident	"@(#)sysinfo.h	1.24	98/06/10 SMI"	/* SVr4.0 11.14 */

#include <sys/types.h>
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
	uint_t	cpu[CPU_STATES]; /* CPU utilization			*/
	uint_t	wait[W_STATES];	/* CPU wait time breakdown		*/
	uint_t	bread;		/* physical block reads			*/
	uint_t	bwrite;		/* physical block writes (sync+async)	*/
	uint_t	lread;		/* logical block reads			*/
	uint_t	lwrite;		/* logical block writes			*/
	uint_t	phread;		/* raw I/O reads			*/
	uint_t	phwrite;	/* raw I/O writes			*/
	uint_t	pswitch;	/* context switches			*/
	uint_t	trap;		/* traps				*/
	uint_t	intr;		/* device interrupts			*/
	uint_t	syscall;	/* system calls				*/
	uint_t	sysread;	/* read() + readv() system calls	*/
	uint_t	syswrite;	/* write() + writev() system calls	*/
	uint_t	sysfork;	/* forks				*/
	uint_t	sysvfork;	/* vforks				*/
	uint_t	sysexec;	/* execs				*/
	uint_t	readch;		/* bytes read by rdwr()			*/
	uint_t	writech;	/* bytes written by rdwr()		*/
	uint_t	rcvint;		/* XXX: UNUSED				*/
	uint_t	xmtint;		/* XXX: UNUSED				*/
	uint_t	mdmint;		/* XXX: UNUSED				*/
	uint_t	rawch;		/* terminal input characters		*/
	uint_t	canch;		/* chars handled in canonical mode	*/
	uint_t	outch;		/* terminal output characters		*/
	uint_t	msg;		/* msg count (msgrcv()+msgsnd() calls)	*/
	uint_t	sema;		/* semaphore ops count (semop() calls)	*/
	uint_t	namei;		/* pathname lookups			*/
	uint_t	ufsiget;	/* ufs_iget() calls			*/
	uint_t	ufsdirblk;	/* directory blocks read		*/
	uint_t	ufsipage;	/* inodes taken with attached pages	*/
	uint_t	ufsinopage;	/* inodes taked with no attached pages	*/
	uint_t	inodeovf;	/* inode table overflows		*/
	uint_t	fileovf;	/* file table overflows			*/
	uint_t	procovf;	/* proc table overflows			*/
	uint_t	intrthread;	/* interrupts as threads (below clock)	*/
	uint_t	intrblk;	/* intrs blkd/prempted/released (swtch)	*/
	uint_t	idlethread;	/* times idle thread scheduled		*/
	uint_t	inv_swtch;	/* involuntary context switches		*/
	uint_t	nthreads;	/* thread_create()s			*/
	uint_t	cpumigrate;	/* cpu migrations by threads 		*/
	uint_t	xcalls;		/* xcalls to other cpus 		*/
	uint_t	mutex_adenters;	/* failed mutex enters (adaptive)	*/
	uint_t	rw_rdfails;	/* rw reader failures			*/
	uint_t	rw_wrfails;	/* rw writer failures			*/
	uint_t	modload;	/* times loadable module loaded		*/
	uint_t	modunload;	/* times loadable module unloaded 	*/
	uint_t	bawrite;	/* physical block writes (async)	*/
/* Following are gathered only under #ifdef STATISTICS in source 	*/
	uint_t	rw_enters;	/* tries to acquire rw lock		*/
	uint_t	win_uo_cnt;	/* reg window user overflows		*/
	uint_t	win_uu_cnt;	/* reg window user underflows		*/
	uint_t	win_so_cnt;	/* reg window system overflows		*/
	uint_t	win_su_cnt;	/* reg window system underflows		*/
	uint_t	win_suo_cnt;	/* reg window system user overflows	*/
} cpu_sysinfo_t;

typedef struct sysinfo {	/* (update freq) update action		*/
	uint_t	updates;	/* (1 sec) ++				*/
	uint_t	runque;		/* (1 sec) += num runnable procs	*/
	uint_t	runocc;		/* (1 sec) ++ if num runnable procs > 0	*/
	uint_t	swpque;		/* (1 sec) += num swapped procs		*/
	uint_t	swpocc;		/* (1 sec) ++ if num swapped procs > 0	*/
	uint_t	waiting;	/* (1 sec) += jobs waiting for I/O	*/
} sysinfo_t;

typedef struct cpu_syswait {
	int	iowait;		/* procs waiting for block I/O		*/
	int	swap;		/* XXX: UNUSED				*/
	int	physio;		/* XXX: UNUSED 				*/
} cpu_syswait_t;

typedef struct cpu_vminfo {
	uint_t	pgrec;		/* page reclaims (includes pageout)	*/
	uint_t	pgfrec;		/* page reclaims from free list		*/
	uint_t	pgin;		/* pageins				*/
	uint_t	pgpgin;		/* pages paged in			*/
	uint_t	pgout;		/* pageouts				*/
	uint_t	pgpgout;	/* pages paged out			*/
	uint_t	swapin;		/* swapins				*/
	uint_t	pgswapin;	/* pages swapped in			*/
	uint_t	swapout;	/* swapouts				*/
	uint_t	pgswapout;	/* pages swapped out			*/
	uint_t	zfod;		/* pages zero filled on demand		*/
	uint_t	dfree;		/* pages freed by daemon or auto	*/
	uint_t	scan;		/* pages examined by pageout daemon	*/
	uint_t	rev;		/* revolutions of the page daemon hand	*/
	uint_t	hat_fault;	/* minor page faults via hat_fault()	*/
	uint_t	as_fault;	/* minor page faults via as_fault()	*/
	uint_t	maj_fault;	/* major page faults			*/
	uint_t	cow_fault;	/* copy-on-write faults			*/
	uint_t	prot_fault;	/* protection faults			*/
	uint_t	softlock;	/* faults due to software locking req	*/
	uint_t	kernel_asflt;	/* as_fault()s in kernel addr space	*/
	uint_t	pgrrun;		/* times pager scheduled		*/
	uint_t  execpgin;	/* executable pages paged in		*/
	uint_t  execpgout;	/* executable pages paged out		*/
	uint_t  execfree;	/* executable pages freed		*/
	uint_t  anonpgin;	/* anon pages paged in			*/
	uint_t  anonpgout;	/* anon pages paged out			*/
	uint_t  anonfree;	/* anon pages freed			*/
	uint_t  fspgin;		/* fs pages paged in			*/
	uint_t  fspgout;	/* fs pages paged out			*/
	uint_t  fsfree;		/* fs pages free			*/
} cpu_vminfo_t;

typedef struct vminfo {		/* (update freq) update action		*/
	uint64_t freemem; 	/* (1 sec) += freemem in pages		*/
	uint64_t swap_resv;	/* (1 sec) += reserved swap in pages	*/
	uint64_t swap_alloc;	/* (1 sec) += allocated swap in pages	*/
	uint64_t swap_avail;	/* (1 sec) += unreserved swap in pages	*/
	uint64_t swap_free;	/* (1 sec) += unallocated swap in pages	*/
} vminfo_t;

/*
 * Per-CPU statistics structure
 */
typedef struct cpu_stat {
	uint_t		__cpu_stat_lock[2];	/* 32-bit kstat compat. */
	cpu_sysinfo_t	cpu_sysinfo;
	cpu_syswait_t	cpu_syswait;
	cpu_vminfo_t	cpu_vminfo;
} cpu_stat_t;

#ifdef	__cplusplus
}
#endif

#endif	/* _SYS_SYSINFO_H */
