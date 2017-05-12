/*
 *   Configuration for DEC OSF/1 V3.2 - 4.0
 */

/*   See hints/none.h for a complete list of options with explanations */

#include <sys/types.h>
#include <sys/param.h>
#include <ufs/quota.h>
#include <sys/mount.h>
#include <malloc.h>
#include <alloca.h>

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
#define Q_CTL_V2
#define CADR

#define NO_MNTENT
#define OSF_QUOTA
extern char *getvfsbynumber();  /* prototype missing!? */

#define GQA_TYPE_USR USRQUOTA  /* RQUOTA_USRQUOTA */
#define GQA_TYPE_GRP GRPQUOTA  /* RQUOTA_GRPQUOTA */
#define GQR_STATUS gqr_status
#define GQR_RQUOTA gqr_rquota

#define QS_BHARD dqb_bhardlimit
#define QS_BSOFT dqb_bsoftlimit
#define QS_BCUR  dqb_curblocks
#define QS_FHARD dqb_ihardlimit
#define QS_FSOFT dqb_isoftlimit
#define QS_FCUR  dqb_curinodes
#define QS_BTIME dqb_btime
#define QS_FTIME dqb_itime

