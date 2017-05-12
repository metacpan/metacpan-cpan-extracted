/*	Copyright (c) 1984, 1986, 1987, 1988, 1989 AT&T	*/
/*	  All Rights Reserved  	*/

/*	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF AT&T	*/
/*	The copyright notice above does not evidence any   	*/
/*	actual or intended publication of such source code.	*/

#ifndef _SYS_VAR_H
#define	_SYS_VAR_H

#pragma ident	"@(#)var.h	1.9	95/08/22 SMI"	/* SVr4.0 11.18 */

#ifdef	__cplusplus
extern "C" {
#endif

/*
 * System Configuration Information
 */
struct var {
	int	v_buf;		/* Nbr of I/O buffers.			*/
	int	v_call;		/* Nbr of callout (timeout) entries.	*/
	int	v_proc;		/* Max processes system wide		*/
	int	v_maxupttl;	/* Max user processes system wide	*/
	int	v_nglobpris;	/* Nbr of global sched prios configured	*/
	int	v_maxsyspri;	/* Max global pri used by sys class.	*/
	int	v_clist;	/* Nbr of clists allocated.		*/
	int	v_maxup;	/* Max number of processes per user.	*/
	int	v_hbuf;		/* Nbr of hash buffers to allocate.	*/
	int	v_hmask;	/* Hash mask for buffers.		*/
	int	v_pbuf;		/* Nbr of physical I/O buffers.		*/
	int	v_sptmap;	/* Size of system virtual space		*/
				/* allocation map.			*/
	int	v_maxpmem;	/* The maximum physical memory to use.	*/
				/* If v_maxpmem == 0, then use all	*/
				/* available physical memory.		*/
				/* Otherwise, value is amount of mem to	*/
				/* use specified in pages.		*/
	int	v_autoup;	/* The age a delayed-write buffer must	*/
				/* be in seconds before bdflush will	*/
				/* write it out.			*/
	int	v_bufhwm;	/* high-water-mark of buffer cache	*/
				/* memory usage, in units of K Bytes	*/
/* #ifdef MERGE */
	int	v_xsdsegs;	/* Number of XENIX shared data segs */
	int	v_xsdslots;	/* Number of slots in xsdtab[] per segment */
/* #endif MERGE */
};

extern struct var v;

#ifdef	__cplusplus
}
#endif

#endif	/* _SYS_VAR_H */
