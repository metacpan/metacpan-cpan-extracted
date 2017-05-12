/*
 *   Configuration for SunOS 4.1.3
 *
 *   For AFS support look at the end of this file
 *   For arla AFS an ANSI C compiler is required (SC1.0 acc or gcc)
 */

/*   See hints/none.h for a complete list of options with explanations */

#include <sys/param.h>
#include <ufs/quota.h>
#include <mntent.h>

#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>
#include <rpcsvc/rquota.h>
#include <sys/socket.h>
#include <netdb.h>

#include <strings.h>
#include <stdio.h>

#define Q_DIV(X) ((X) / 2)
#define Q_MUL(X) ((X) * 2)
#define DEV_QBSIZE DEV_BSIZE
#define CADR

#define MNTENT mntent

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
