/*
**  Linux quotactl wrapper
**  Required to support 3 official and intermediate quotactl() versions
*/

#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <signal.h>

#include "myconfig.h"

/* API v1 command definitions */
#define Q_V1_GETQUOTA  0x0300
#define Q_V1_SYNC      0x0600
#define Q_V1_SETQLIM   0x0700
#define Q_V1_GETSTATS  0x0800
/* API v2 command definitions */
#define Q_V2_SYNC      0x0600
#define Q_V2_SETQLIM   0x0700
#define Q_V2_GETQUOTA  0x0D00
#define Q_V2_GETSTATS  0x1100
/* proc API command definitions */
#define Q_V3_SYNC      0x800001
#define Q_V3_GETQUOTA  0x800007
#define Q_V3_SETQUOTA  0x800008

/* Interface versions */
#define IFACE_UNSET 0
#define IFACE_VFSOLD 1
#define IFACE_VFSV0 2
#define IFACE_GENERIC 3

/* format supported by current kernel */
static int kernel_iface = IFACE_UNSET;


/*
 * Quota structure used for communication with userspace via quotactl
 * Following flags are used to specify which fields are valid
 */
#define QIF_BLIMITS     1
#define QIF_SPACE       2
#define QIF_ILIMITS     4
#define QIF_INODES      8
#define QIF_BTIME       16
#define QIF_ITIME       32
#define QIF_LIMITS      (QIF_BLIMITS | QIF_ILIMITS)
#define QIF_USAGE       (QIF_SPACE | QIF_INODES)
#define QIF_TIMES       (QIF_BTIME | QIF_ITIME)
#define QIF_ALL         (QIF_LIMITS | QIF_USAGE | QIF_TIMES)


/*
** Copy of struct declarations in the v2 quota.h header file
** (with structure names changed to avoid conflicts with v2 headers).
** This is required to be able to compile with v1 kernel headers.
*/

/*
** Packed into wrapper for compatibility of 32-bit clients with 64-bit kernels:
** 64-bit compilers add 4 padding bytes at the end of the struct, so a memcpy
** corrupts the 4 bytes following the struct in the 32-bit clients userspace
*/
union dqblk_v3_wrap {
  struct dqblk_v3 {
    u_int64_t dqb_bhardlimit;
    u_int64_t dqb_bsoftlimit;
    u_int64_t dqb_curspace;
    u_int64_t dqb_ihardlimit;
    u_int64_t dqb_isoftlimit;
    u_int64_t dqb_curinodes;
    u_int64_t dqb_btime;
    u_int64_t dqb_itime;
    u_int32_t dqb_valid;
  } dqblk;
  u_int64_t foo[9];
};


struct dqstats_v2 {
  u_int32_t lookups;
  u_int32_t drops;
  u_int32_t reads;
  u_int32_t writes;
  u_int32_t cache_hits;
  u_int32_t allocated_dquots;
  u_int32_t free_dquots;
  u_int32_t syncs;
  u_int32_t version;
};


struct dqblk_v2 {
  unsigned int dqb_ihardlimit;
  unsigned int dqb_isoftlimit;
  unsigned int dqb_curinodes;
  unsigned int dqb_bhardlimit;
  unsigned int dqb_bsoftlimit;
  qsize_t dqb_curspace;
  time_t dqb_btime;
  time_t dqb_itime;
};

struct dqblk_v1 {
  u_int32_t dqb_bhardlimit;
  u_int32_t dqb_bsoftlimit;
  u_int32_t dqb_curblocks;
  u_int32_t dqb_ihardlimit;
  u_int32_t dqb_isoftlimit;
  u_int32_t dqb_curinodes;
  time_t dqb_btime;
  time_t dqb_itime;
};



/*
**  Check kernel quota version
**  Taken from quota-tools 3.08 by Jan Kara <jack@suse.cz>
*/
static void linuxquota_get_api( void )
{
#ifndef LINUX_API_VERSION
    struct stat st;

    if (stat("/proc/sys/fs/quota", &st) == 0) {
        kernel_iface = IFACE_GENERIC;
    }
    else {
        struct dqstats_v2 v2_stats;
        struct sigaction  sig;
        struct sigaction  oldsig;

        /* This signal handling is needed because old kernels send us SIGSEGV as they try to resolve the device */
        sig.sa_handler   = SIG_IGN;
        sig.sa_sigaction = NULL;
        sig.sa_flags     = 0;
        sigemptyset(&sig.sa_mask);
        if (sigaction(SIGSEGV, &sig, &oldsig) < 0) {
            fprintf(stderr, "linuxapi.c warning: cannot set SEGV signal handler: %s\n", strerror(errno));
            goto failure;
        }
        if (quotactl(QCMD(Q_V2_GETSTATS, 0), NULL, 0, (void *)&v2_stats) >= 0) {
            kernel_iface = IFACE_VFSV0;
        }
        else if (errno != ENOSYS && errno != ENOTSUP) {
            /* RedHat 7.1 (2.4.2-2) newquota check 
             * Q_V2_GETSTATS in it's old place, Q_GETQUOTA in the new place
             * (they haven't moved Q_GETSTATS to its new value) */
            int err_stat = 0;
            int err_quota = 0;
            char tmp[1024];         /* Just temporary buffer */

            if (quotactl(QCMD(Q_V1_GETSTATS, 0), NULL, 0, tmp))
                err_stat = errno;
            if (quotactl(QCMD(Q_V1_GETQUOTA, 0), "/dev/null", 0, tmp))
                err_quota = errno;

            /* On a RedHat 2.4.2-2 	we expect 0, EINVAL
             * On a 2.4.x 		we expect 0, ENOENT
             * On a 2.4.x-ac	we wont get here */
            if (err_stat == 0 && err_quota == EINVAL) {
                kernel_iface = IFACE_VFSV0;
            }
            else {
                kernel_iface = IFACE_VFSOLD;
            }
        }
        else {
            /* This branch is *not* in quota-tools 3.08
            ** but without it quota version is not correctly
            ** identified for the original SuSE 8.0 kernel */
            unsigned int vers_no;
            FILE * qf;

            if ((qf = fopen("/proc/fs/quota", "r"))) {
                if (fscanf(qf, "Version %u", &vers_no) == 1) {
                    if ( (vers_no == (6*10000 + 5*100 + 0)) ||
                         (vers_no == (6*10000 + 5*100 + 1)) ) {
                        kernel_iface = IFACE_VFSV0;
                    }
                }
                fclose(qf);
            }
        }
        if (sigaction(SIGSEGV, &oldsig, NULL) < 0) {
            fprintf(stderr, "linuxapi.c warning: cannot reset signal handler: %s\n", strerror(errno));
            goto failure;
        }
    }

failure:
    if (kernel_iface == IFACE_UNSET)
       kernel_iface = IFACE_VFSOLD;

#else /* defined LINUX_API_VERSION */
    kernel_iface = LINUX_API_VERSION;
#endif
}


/*
** Wrapper for the quotactl(GETQUOTA) call.
** For API v2 the results are copied back into a v1 structure.
*/
int linuxquota_query( const char * dev, int uid, int isgrp, struct dqblk * dqb )
{
  int ret;

  if (kernel_iface == IFACE_UNSET)
    linuxquota_get_api();

  if (kernel_iface == IFACE_GENERIC)
  {
    union dqblk_v3_wrap dqb3;

    ret = quotactl(QCMD(Q_V3_GETQUOTA, (isgrp ? GRPQUOTA : USRQUOTA)),
                   dev, uid, (caddr_t) &dqb3.dqblk);
    if (ret == 0)
    {
      dqb->dqb_bhardlimit = dqb3.dqblk.dqb_bhardlimit;
      dqb->dqb_bsoftlimit = dqb3.dqblk.dqb_bsoftlimit;
      dqb->dqb_curblocks  = dqb3.dqblk.dqb_curspace / DEV_QBSIZE;
      dqb->dqb_ihardlimit = dqb3.dqblk.dqb_ihardlimit;
      dqb->dqb_isoftlimit = dqb3.dqblk.dqb_isoftlimit;
      dqb->dqb_curinodes  = dqb3.dqblk.dqb_curinodes;
      dqb->dqb_btime      = dqb3.dqblk.dqb_btime;
      dqb->dqb_itime      = dqb3.dqblk.dqb_itime;
    }
  }
  else if (kernel_iface == IFACE_VFSV0)
  {
    struct dqblk_v2 dqb2;

    ret = quotactl(QCMD(Q_V2_GETQUOTA, (isgrp ? GRPQUOTA : USRQUOTA)),
                   dev, uid, (caddr_t) &dqb2);
    if (ret == 0)
    {
      dqb->dqb_bhardlimit = dqb2.dqb_bhardlimit;
      dqb->dqb_bsoftlimit = dqb2.dqb_bsoftlimit;
      dqb->dqb_curblocks  = dqb2.dqb_curspace / DEV_QBSIZE;
      dqb->dqb_ihardlimit = dqb2.dqb_ihardlimit;
      dqb->dqb_isoftlimit = dqb2.dqb_isoftlimit;
      dqb->dqb_curinodes  = dqb2.dqb_curinodes;
      dqb->dqb_btime      = dqb2.dqb_btime;
      dqb->dqb_itime      = dqb2.dqb_itime;
    }
  }
  else /* if (kernel_iface == IFACE_VFSOLD) */
  {
    struct dqblk_v1 dqb1;

    ret = quotactl(QCMD(Q_V1_GETQUOTA, (isgrp ? GRPQUOTA : USRQUOTA)),
                   dev, uid, (caddr_t) &dqb1);
    if (ret == 0)
    {
      dqb->dqb_bhardlimit = dqb1.dqb_bhardlimit;
      dqb->dqb_bsoftlimit = dqb1.dqb_bsoftlimit;
      dqb->dqb_curblocks  = dqb1.dqb_curblocks;
      dqb->dqb_ihardlimit = dqb1.dqb_ihardlimit;
      dqb->dqb_isoftlimit = dqb1.dqb_isoftlimit;
      dqb->dqb_curinodes  = dqb1.dqb_curinodes;
      dqb->dqb_btime      = dqb1.dqb_btime;
      dqb->dqb_itime      = dqb1.dqb_itime;
    }
  }
  return ret;
}

/*
** Wrapper for the quotactl(GETQUOTA) call.
** For API v2 and v3 the parameters are copied into the internal structure.
*/
int linuxquota_setqlim( const char * dev, int uid, int isgrp, struct dqblk * dqb )
{
  int ret;

  if (kernel_iface == IFACE_UNSET)
    linuxquota_get_api();

  if (kernel_iface == IFACE_GENERIC)
  {
    union dqblk_v3_wrap dqb3;

    dqb3.dqblk.dqb_bhardlimit = dqb->dqb_bhardlimit;
    dqb3.dqblk.dqb_bsoftlimit = dqb->dqb_bsoftlimit;
    dqb3.dqblk.dqb_curspace   = 0;
    dqb3.dqblk.dqb_ihardlimit = dqb->dqb_ihardlimit;
    dqb3.dqblk.dqb_isoftlimit = dqb->dqb_isoftlimit;
    dqb3.dqblk.dqb_curinodes  = 0;
    dqb3.dqblk.dqb_btime      = dqb->dqb_btime;
    dqb3.dqblk.dqb_itime      = dqb->dqb_itime;
    dqb3.dqblk.dqb_valid      = (QIF_BLIMITS | QIF_ILIMITS);

    ret = quotactl (QCMD(Q_V3_SETQUOTA, (isgrp ? GRPQUOTA : USRQUOTA)),
                    dev, uid, (caddr_t) &dqb3.dqblk);
  }
  else if (kernel_iface == IFACE_VFSV0)
  {
    struct dqblk_v2 dqb2;

    dqb2.dqb_bhardlimit = dqb->dqb_bhardlimit;
    dqb2.dqb_bsoftlimit = dqb->dqb_bsoftlimit;
    dqb2.dqb_curspace   = 0;
    dqb2.dqb_ihardlimit = dqb->dqb_ihardlimit;
    dqb2.dqb_isoftlimit = dqb->dqb_isoftlimit;
    dqb2.dqb_curinodes  = 0;
    dqb2.dqb_btime      = dqb->dqb_btime;
    dqb2.dqb_itime      = dqb->dqb_itime;

    ret = quotactl (QCMD(Q_V2_SETQLIM, (isgrp ? GRPQUOTA : USRQUOTA)),
                    dev, uid, (caddr_t) &dqb2);
  }
  else /* if (kernel_iface == IFACE_VFSOLD) */
  {
    struct dqblk_v1 dqb1;

    dqb1.dqb_bhardlimit = dqb->dqb_bhardlimit;
    dqb1.dqb_bsoftlimit = dqb->dqb_bsoftlimit;
    dqb1.dqb_curblocks  = 0;
    dqb1.dqb_ihardlimit = dqb->dqb_ihardlimit;
    dqb1.dqb_isoftlimit = dqb->dqb_isoftlimit;
    dqb1.dqb_curinodes  = 0;
    dqb1.dqb_btime      = dqb->dqb_btime;
    dqb1.dqb_itime      = dqb->dqb_itime;

    ret = quotactl (QCMD(Q_V1_SETQLIM, (isgrp ? GRPQUOTA : USRQUOTA)),
                    dev, uid, (caddr_t) &dqb1);
  }

  return ret;
}

/*
** Wrapper for the quotactl(SYNC) call.
*/
int linuxquota_sync( const char * dev, int isgrp )
{
  int ret;

  if (kernel_iface == IFACE_UNSET)
    linuxquota_get_api();

  if (kernel_iface == IFACE_GENERIC)
  {
    ret = quotactl (QCMD(Q_V3_SYNC, (isgrp ? GRPQUOTA : USRQUOTA)), dev, 0, NULL);
  }
  else if (kernel_iface == IFACE_VFSV0)
  {
    ret = quotactl (QCMD(Q_V2_SYNC, (isgrp ? GRPQUOTA : USRQUOTA)), dev, 0, NULL);
  }
  else /* if (kernel_iface == IFACE_VFSOLD) */
  {
    ret = quotactl (QCMD(Q_V1_SYNC, (isgrp ? GRPQUOTA : USRQUOTA)), dev, 0, NULL);
  }

  return ret;
}

#if 0
#define DEVICE_PATH  "/dev/hda6"
main()
{
  struct dqblk dqb;

  linuxquota_get_api();
  printf("API=%d\n", kernel_iface);

  if (linuxquota_sync(DEVICE_PATH, FALSE) != 0)
     perror("Q_SYNC");

  if (linuxquota_query(DEVICE_PATH, getuid(), 0, &dqb) == 0)
  {
     printf("blocks: usage %d soft %d hard %d expire %s",
            dqb.dqb_curblocks, dqb.dqb_bhardlimit, dqb.dqb_bsoftlimit,
            ((dqb.dqb_btime != 0) ? (char*)ctime(&dqb.dqb_btime) : "n/a\n"));
     printf("inodes: usage %d soft %d hard %d expire %s",
            dqb.dqb_curinodes, dqb.dqb_ihardlimit, dqb.dqb_isoftlimit,
            ((dqb.dqb_itime != 0) ? (char*)ctime(&dqb.dqb_itime) : "n/a\n"));
  }
  else
     perror("Q_GETQUOTA");
}
#endif

