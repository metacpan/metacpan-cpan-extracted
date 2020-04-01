/*
 *   Configuration example for BSD-based systems -
 *   BSDi, FreeBSD, NetBSD, OpenBSD
 *
 *   Ported to BSDI 2.0 by Jim Hribnak (hribnak@nucleus.com) Aug 28 1997
 *   with the help of the original author Tom Zoerner
 *   OpenBSD 2.0 mods provided by James Shelburne (reilly@eramp.net)
 *   FreeBSD mods provided by Kurt Jaeger <pi@complx.LF.net>
 *           and Jon Schewe <schewe@tcfreenet.org>
 *   NetBSD mods and merge of *BSD-related hints provided by
 *           Jaromir Dolecek <jdolecek@NetBSD.org>
 *   NetBSD libquota mods by David Holland <dholland@netbsd.org>
 */

/*   See hints/none.h for a complete list of options with explanations */

#include <sys/param.h>
#include <sys/mount.h>
#include <fstab.h>

#if defined(__NetBSD__) && __NetBSD_Version__ >= 599004800 && __NetBSD_Version__ < 599005900
#error "NetBSD 5.99 proplib-based quotas not supported"
#endif

#if defined(__NetBSD__) && (__NetBSD_Version__ >= 599005900) /* NetBSD 5.99.59 */
#include <quota.h>
/* defining this will force the XS to use the libquota API for all file systems
 * except RPC; defines below such as Q_CTL_V2 have no effect */
#define NETBSD_LIBQUOTA
#else  /* !__NetBSD__ */
#if defined(__APPLE__)
#include <sys/quota.h>
#else
#include <ufs/ufs/quota.h>
#endif
#endif  /* !__NetBSD__ */

#if defined(__NetBSD__) && (__NetBSD_Version__ >= 299000900) /* NetBSD 2.99.9 */
/* NetBSD 3.0 has no statfs anymore */
#include <sys/types.h>
#include <sys/statvfs.h>
#define HAVE_STATVFS
#endif

#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>
#include <rpc/svc.h>

#if defined(__APPLE__) || defined(__FreeBSD__) || defined(__NetBSD__) || defined(__OpenBSD__)
#include <rpcsvc/rquota.h>
#else /* BSDi */
#include "include/rquota.h"
#endif

#include <sys/socket.h>
#include <netdb.h>

#include <stdio.h>
#include <string.h>

#define Q_DIV(X) ((X) / 2)
#define Q_MUL(X) ((X) * 2)
#define DEV_QBSIZE DEV_BSIZE
#define Q_CTL_V2
#define Q_SETQLIM Q_SETQUOTA
#define CADR (caddr_t)

#define QCARG_MNTPT

#define MY_XDR

#if defined (EXT_RQUOTAVERS)
#define USE_EXT_RQUOTA  /* RPC version 2 aka extended quota RPC */
#endif

#define NO_MNTENT

#define GQA_TYPE_USR RQUOTA_USRQUOTA
#define GQA_TYPE_GRP RQUOTA_GRPQUOTA
#define GQR_STATUS status
#define GQR_RQUOTA getquota_rslt_u.gqr_rquota

#define QS_BHARD dqb_bhardlimit
#define QS_BSOFT dqb_bsoftlimit
#if defined(__APPLE__)
#define QS_BCUR  dqb_curbytes
#else
#define QS_BCUR  dqb_curblocks
#endif
#define QS_FHARD dqb_ihardlimit
#define QS_FSOFT dqb_isoftlimit
#define QS_FCUR  dqb_curinodes
#define QS_BTIME dqb_btime
#define QS_FTIME dqb_itime

