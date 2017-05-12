/*
 *   Configuration for Linux - kernel version 2.0.22 and later
 *
 *   For AFS support look at the end of this file
 */

/*   See hints/none.h for a complete list of options with explanations */

#include <sys/param.h>
#include <sys/types.h>
/* #include <linux/types.h> */
/* <asm/types.h> is required only on some distributions (Debian 2.0, RedHat)
   if your's doesn't have it you can simply remove the following line */
#include <asm/types.h>
#include <sys/syscall.h>
#include <mntent.h>

#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>
#include <rpcsvc/rquota.h>
/* #include "include/rquota.h" */
#include <sys/socket.h>
#include <netdb.h>

#include <string.h>
#include <stdio.h>

/* definitions from sys/quota.h */
#define USRQUOTA  0             /* element used for user quotas */
#define GRPQUOTA  1             /* element used for group quotas */

/*
 * Command definitions for the 'quotactl' system call.
 * The commands are broken into a main command defined below
 * and a subcommand that is used to convey the type of
 * quota that is being manipulated (see above).
 */
#define SUBCMDMASK  0x00ff
#define SUBCMDSHIFT 8
#define QCMD(cmd, type)  (((cmd) << SUBCMDSHIFT) | ((type) & SUBCMDMASK))

/* declare an internal version of the quota block struct */
typedef u_int64_t qsize_t;
struct dqblk {
  qsize_t dqb_ihardlimit;   /* absolute limit on allocated inodes */
  qsize_t dqb_isoftlimit;   /* preferred inode limit */
  qsize_t dqb_curinodes;    /* current # allocated inodes */
  qsize_t dqb_bhardlimit;   /* absolute limit on disk blks alloc */
  qsize_t dqb_bsoftlimit;   /* preferred limit on disk blks */
  qsize_t dqb_curblocks;    /* current block count */
  time_t  dqb_btime;        /* time limit for excessive disk use */
  time_t  dqb_itime;        /* time limit for excessive inode use */
};
/* you can use this switch to hard-wire the quota API if it's not identified correctly */
/* #define LINUX_API_VERSION 1 */  /* API range [1..3] */

int linuxquota_query( const char * dev, int uid, int isgrp, struct dqblk * dqb );
int linuxquota_setqlim( const char * dev, int uid, int isgrp, struct dqblk * dqb );
int linuxquota_sync( const char * dev, int isgrp );


#define Q_DIV(X) (X)
#define Q_MUL(X) (X)
#define DEV_QBSIZE 1024

#define Q_CTL_V3
#define CADR (caddr_t)

#define MY_XDR

#define MNTENT mntent

#define GQA_TYPE_USR USRQUOTA  /* RQUOTA_USRQUOTA */
#define GQA_TYPE_GRP GRPQUOTA  /* RQUOTA_GRPQUOTA */
#define GQR_STATUS status
#define GQR_RQUOTA getquota_rslt_u.gqr_rquota

#define QS_BHARD dqb_bhardlimit
#define QS_BSOFT dqb_bsoftlimit
#define QS_BCUR  dqb_curblocks
#define QS_FHARD dqb_ihardlimit
#define QS_FSOFT dqb_isoftlimit
#define QS_FCUR  dqb_curinodes
#define QS_BTIME dqb_btime
#define QS_FTIME dqb_itime

/* uncomment this is you're using NFS with a version of the quota tools < 3.0 */
/* #define LINUX_RQUOTAD_BUG */

/* enable support for extended quota RPC (i.e. quota RPC version 2) */
/* note: could also be enabled by defining MY_XDR (and including "include/rquota.h") */
#if defined (EXT_RQUOTAVERS)
#define USE_EXT_RQUOTA
#endif

/* optional: for support of SGI XFS file systems - comment out if not needed */
#define SGI_XFS
#define QX_DIV(X) ((X) / 2)
#define QX_MUL(X) ((X) * 2)
#include "include/quotaio_xfs.h"

