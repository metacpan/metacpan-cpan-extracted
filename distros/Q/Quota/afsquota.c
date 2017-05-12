/*
 *  Interface to OpenAFS
 *
 *  Contributed 1998,2003 by Wolfgang Friebel <friebel@ifh.de>
 */

#if defined( __hpux)
#define IGNORE_STDS_H
#endif
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <sys/ioctl.h>

#define MAXSIZE 2048
#define MAXDNAME 2048

#include <afs/afsint.h>
#include <afs/venus.h>
#include <resolv.h>

#ifdef SunOS4
#define _VICEIOCTL(id)  ((unsigned int ) _IOW(V, id, struct ViceIoctl))
#endif


/*
 *  Check if AFS is installed
 */

int afs_check(void)
{
  struct  ViceIoctl vi;
  int32_t code;
  char space[MAXSIZE];
 
  vi.in_size = 0;
  vi.out_size = MAXSIZE;
  vi.out = (caddr_t) space;
  code = pioctl(NULL, VIOC_GET_WS_CELL, &vi, 0);
  return  ! code;
}


/*
 *  report quota
 */

int afs_getquota(char *path, int *maxQuota, int *blocksUsed)
{
    struct ViceIoctl a_params;
    struct VolumeStatus *vs;

    a_params.in_size  = 0;
    a_params.out_size = MAXSIZE;
    a_params.in       = NULL;
    a_params.out      = malloc(MAXSIZE);

    if (a_params.out == NULL) {
	errno = ENOMEM;
	return -1;
    }

    if (pioctl(path, VIOCGETVOLSTAT,&a_params,1) == -1) {
	free(a_params.out);
	return -1;
    }
  
    vs = (struct VolumeStatus *) a_params.out;

    *maxQuota   = vs->MaxQuota;
    *blocksUsed = vs->BlocksInUse;

    free(a_params.out);
    return 0;
}

/*
 * Usage: fs sq <path> <max quota in kbytes>
 */

int afs_setqlim(char *path, int maxQuota)
{
    struct ViceIoctl a_params;
    struct VolumeStatus *vs;
    int insize;

    a_params.in_size  = 0;
    a_params.out_size = MAXSIZE;
    a_params.in       = NULL;
    a_params.out      = malloc(MAXSIZE);

    if (a_params.out == NULL) {
	errno = ENOMEM;
	return -1;
    }

    /* Read the old volume status */
    if(pioctl(path,VIOCGETVOLSTAT,&a_params,1) == -1) {
	free(a_params.out);
	return -1;
    }

    insize = sizeof(struct VolumeStatus) + strlen(path) + 2;

    a_params.in_size  = ((MAXSIZE < insize) ? MAXSIZE : insize);
    a_params.out_size = 0;
    a_params.in       = a_params.out;
    a_params.out      = NULL;
  
    vs = (struct VolumeStatus *) a_params.in;
    vs->MaxQuota = maxQuota;

    if(pioctl(path,VIOCSETVOLSTAT,&a_params,1) == -1) {
	free(a_params.in);
	return -1;
    }

    free(a_params.in);
    return 0;
}

#ifdef __hpux
int sigvec( int sig, struct sigvec *vec, struct sigvec *ovec )
{
  return sigvector(sig, vec, ovec);
}
#endif

#ifdef STAND_ALONE
int main(int argc, char **argv)
{
    int usage, limit;

    if (afs_check()) {
      if (afs_getquota("/afs/ifh.de/user/z/zorner", &limit, &usage) == 0) {
        printf("limit=%d  usage=%d\n", limit, usage);
      }
      else
        perror("Not an AFS filesystem");
    }
    else {
      printf("No AFS available\n");
    }
}
#endif

/*
 *  Compiler options for standalone compilation
 */

/*
AIX:
cc afsquota.c -L/products/security/athena/lib -lkafs -ldes -lkrb -lroken -lld

IRIX:
cc afsquota.c -L/products/security/athena/lib -lkafs -ldes -lkrb   \
              -Wl,-rpath -Wl,/products/security/athena/lib

Linux:
cc afsquota.c -L/products/security/athena/lib -lkafs -ldes -lkrb  \
              -Wl,-rpath -Wl,/products/security/athena/lib

HP-UX:
cc -Ae afsquota.c -L/products/security/athena/lib -lkafs -ldes -lkrb

Solaris: (Workshop compiler)
cc afsquota.c -L/products/security/athena/lib -lkafs -ldes -lkrb  \
              -Wl,-R -Wl,/products/security/athena/lib

SunOS:
acc afsquota.c -U__STDC__ -DSunOS4 \
               -L/products/security/athena/lib -lkafs -ldes -lkrb
*/
