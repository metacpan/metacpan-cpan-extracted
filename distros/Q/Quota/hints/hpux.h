/*
 *   Configuration for HP-UX 9.0.x & HP-UX 10.10 & HP-UX 10.20 & HP-UX 11.00
 *
 *   For AFS support look at the end of this file
 */

/*   See hints/none.h for a complete list of options with explanations */

#include <sys/param.h>
#include <sys/quota.h>
#include <sys/vfs.h>
#include <mntent.h>

#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>
#include <rpcsvc/rquota.h>
#include <sys/socket.h>
#include <netdb.h>

#include <stdio.h>
#include <string.h>

#define Q_DIV(X) (X)
#define Q_MUL(X) (X)
#define DEV_QBSIZE DEV_BSIZE
#define CADR (caddr_t)

#define MNTENT mntent

/*  HP-UX has no shared librpcsvc. So we need to include the
 *  XDR routines supplied with this module.
 */
#define MY_XDR

#define GQA_TYPE_USR USRQUOTA  /* RQUOTA_USRQUOTA */
#define GQA_TYPE_GRP GRPQUOTA  /* RQUOTA_GRPQUOTA */
#define GQR_STATUS gqr_status
#define GQR_RQUOTA gqr_rquota

#define QS_BHARD dqb_bhardlimit
#define QS_BSOFT dqb_bsoftlimit
#define QS_BCUR  dqb_curblocks
#define QS_FHARD dqb_fhardlimit
#define QS_FSOFT dqb_fsoftlimit
#define QS_FCUR  dqb_curfiles
#define QS_BTIME dqb_btimelimit
#define QS_FTIME dqb_ftimelimit
