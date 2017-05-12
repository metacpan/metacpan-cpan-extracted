/*
 *   Configuration for AIX 4.1
 *
 *   For AFS support look at the end of this file
 */

/*   See hints/none.h for a complete list of options with explanations */


#include <sys/param.h>
#include <sys/socket.h>
#include <netdb.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>
#include "include/rquota.h"

#include <jfs/quota.h>
#include <sys/statfs.h>
#include <sys/mntctl.h>
#include <sys/vmount.h>

#define AIX
#define Q_CTL_V2

#if defined(_AIXVERSION_530)
#include "j2/j2_quota.h"
#define HAVE_JFS2
#endif

#define Q_DIV(X) (X)
#define Q_MUL(X) (X)
#define DEV_QBSIZE DEV_BSIZE

#define CADR (caddr_t)

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
