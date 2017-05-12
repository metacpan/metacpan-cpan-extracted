/*
 *   Configuration for Solaris 2.4 & 2.5.x & 2.6 - NOT 2.7
 *   (this is for use with SYSV flavour, not /usr/bsd)
 *
 *   For AFS support look at the end of this file
 */

/*   See hints/none.h for a complete list of options with explanations */

#include <sys/param.h>
#include <sys/fs/ufs_quota.h>
#include <sys/mnttab.h>

#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>
#include <rpcsvc/rquota.h>
#include <sys/socket.h>
#include <netdb.h>

#include <stdio.h>
#include <string.h>

#define USE_IOCTL
#define Q_DIV(X) ((X) / 2)
#define Q_MUL(X) ((X) * 2)
#define DEV_QBSIZE DEV_BSIZE
#define CADR (caddr_t)

/* Haven't found definition of quotactl-struct in any include,
   just mentioned in man quotactl(7) */
struct quotactl {
  int op;
  uid_t uid;
  caddr_t addr;
};

#define NO_OPEN_MNTTAB
#define MOUNTED MNTTAB
#define MNTENT mnttab

/*
 *   Solaris seems to lack xdr routines for rquota. Use my own.
 */
#define MY_XDR

#define GQA_TYPE_USR USRQUOTA  /* RQUOTA_USRQUOTA */
#define GQA_TYPE_GRP GRPQUOTA  /* RQUOTA_GRPQUOTA */
#define GQR_STATUS status
#define GQR_RQUOTA getquota_rslt_u.gqr_rquota

#define QS_BHARD dqb_bhardlimit
#define QS_BSOFT dqb_bsoftlimit
#define QS_BCUR  dqb_curblocks
#define QS_FHARD dqb_fhardlimit
#define QS_FSOFT dqb_fsoftlimit
#define QS_FCUR  dqb_curfiles
#define QS_BTIME dqb_btimelimit
#define QS_FTIME dqb_ftimelimit
