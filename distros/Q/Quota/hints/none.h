/*
 *   Configuration options
 */

#include <sys/param.h>

/* Defines all kinds of standard types (e.g. ulong). You may have to add
 * types.h include files from other /usr/include/ subdirectories */
#include <sys/types.h>

/* This is needed for the quotactl syscall. See man quotactl(2) */
#include <ufs/quota.h>

/* This is needed for the mntent library routines. See man getmntent(3)
   another probable name is mnttab or mtab. Basically that's the name
   of the file where mount(1m) keeps track of the current mounts.
   See FILES section of man mount for the name of that file */
#include <mntent.h>

/* See includes list man callrpc(3) and man rquota(3) */
#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>

/* Select one of the following, preferring the first */
#include <rpcsvc/rquota.h> /**/
/* #include "include/rquota.h" /**/

/* See man socket(2) and man gethostbyname(3) */
#include <sys/socket.h>
#include <netdb.h>

/* Needed for definition of type FILE for set/getmntent(3) routines */
#include <stdio.h>

/* Needed (at least) for memcpy */
#include <string.h>

/* These factors depend on the blocksize of your filesystem.
   Scale it in a way that quota values are in kB */
#define Q_DIV(X) ((X) / 2)
#define Q_MUL(X) ((X) * 2)

/* Specify what parameters the quotactl call expects (see man quotactl) */
/* group quotas are supported only with BSD and Linux (see INSTALL) */

/* BSD style: quotactl(dev, QCMD(Q_GETQUOTA, USRQUOTA), uid, &dqblk); */
/* #define Q_CTL_V2 */

/* Linux special: quotactl(QCMD(Q_GETQUOTA, USRQUOTA), dev, uid, &dqblk); */
/* #define Q_CTL_V3 */

/* Solaris uses ioctl() instead of quotactl() */
/* #define USE_IOCTL */

/* if none of the above defined:
 * old style: quotactl(Q_GETQUOTA, dev, uid, CADR &dqblk); */

/* Normally quota should be reported in file system block sizes.
 * On Linux though all values are converted to 1k blocks. So we
 * must not use DEV_BSIZE (usually 512) but 1024 instead. On all
 * other systems use the file system block size. This value is
 * used only with RPC, else only Q_DIV and Q_MUL are relevant. */
#define DEV_QBSIZE DEV_BSIZE

/* Turn off attempt to convert remote quota block reports to 1k sizes.
 * This assumes that the remote system always reports in 1k blocks.
 * Only needed when the remote system also reports a bogus block
 * size value in the rquota structure (like Linux does).  */
/* #define LINUX_RQUOTAD_BUG /**/

/* Some systems need to cast the dqblk structure
   Do change only if your compiler complains */
#define CADR (caddr_t)

/* define if you don't want the RPC query functionality,
   i.e. you want to operate on the local host only */
/* #define NO_RPC /**/

/* This is for systems that lack librpcsvc and don't have xdr_getquota_args
   et. al. in libc either. If you do have /usr/include/rpcsvc/rquota.x
   you can generate these routines with rpcgen, too */
/* #define MY_XDR /**/

/* define this to enable support for extended quota RPC (i.e. quota RPC
 * version 2), which is needed to allow querying group quotas via RPC. To
 * check if your OS supports it, search for EXT_RQUOTAVERS in the system
 * header files. If not, you can define MY_XDR to use module internal
 * support. */
/* #define USE_EXT_RQUOTA /**/

/* needed only if MOUNTED is not defined in <mnttab.h> (see above) */
/* define MOUNTED mnttab /**/

/* name of the structure used by getmntent(3) */
#define MNTENT mntent

/* on some systems setmntent/endmntend do not exist  */
/* #define NO_OPEN_MNTTAB /**/

/* if your system doesn't have /etc/mnttab, and hence no getmntent,
   use getmntinfo instead then (e.g. in OSF) */
/* #define NO_MNTENT /**/

/* With USE_EXT_RQUOTA these constants distinguish queries for user and
 * group quota respectively. Only BSD defines these constants properly. For
 * others use USRQUTA and GRPQUOTA, or simply the real constants (these must
 * be the same for all OS to allow inter-operability.) */
#define GQA_TYPE_USR 0 /* RQUOTA_USRQUOTA */
#define GQA_TYPE_GRP 1 /* RQUOTA_GRPQUOTA */

/* name of the status entry in struc getquota_rslt and name of the struct
 * or union that contains the quota values. See include <rpcsvc/rquota.h>
 * or "include/rquota.h" if you're using MY_XDR */
#define GQR_STATUS gqr_status
#define GQR_RQUOTA gqr_rquota

/* members of the dqblk structure, see the include named in man quotactl */
#define QS_BHARD dqb_bhardlimit
#define QS_BSOFT dqb_bsoftlimit
#define QS_BCUR  dqb_curblocks
#define QS_FHARD dqb_fhardlimit
#define QS_FSOFT dqb_fsoftlimit
#define QS_FCUR  dqb_curfiles
#define QS_BTIME dqb_btimelimit
#define QS_FTIME dqb_ftimelimit

/* SFIO_VERSION should get defined automatically if sfio routines
 * are used with Perl instead of stdio; but you might wanna define
 * it here if you are using PerlIO and experience problems with
 * Quota::getqcarg() or the Quota::getmntent() family.
 * If PerlIO is used, PERLIO_IS_STDIO is not defined */
/* #ifndef PERLIO_IS_STDIO /**/
/* #define SFIO_VERSION x.x /**/
/* #endif /**/


/* If you have AFS (e.g. arla-0.13) then modify the lines below
 * and insert your paths to the Kerberos libraries and header files.
 * Depending on your compiler you may have to change the compiler
 * and linker arguments. See man cc(1)
 */
