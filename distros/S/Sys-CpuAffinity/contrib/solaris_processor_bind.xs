#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <sys/types.h>
#include <sys/processor.h>
#include <sys/procset.h>
#include <sys/pset.h>


int setaffinity_processor_unbind(int pid)
{
  int r;
  r = processor_bind(P_PID, (id_t) pid, PBIND_NONE, NULL);
  if (r != 0) {
    if (errno == EFAULT) {
      fprintf(stderr,"setaffinity_processor_unbind: error code EFAULT\n");
      return 0;
    } else if (errno == EINVAL) {
      fprintf(stderr,"setaffinity_processor_unbind: error code EINVAL\n");
      return 0;
    } else if (errno == EPERM) {
      fprintf(stderr,"setaffinity_processor_unbind: no permission to bind %d\n",
	      pid);
      return 0;
    } else if (errno == ESRCH) {
      fprintf(stderr,"setaffinity_processor_unbind: no such PID %d\n", pid);
      return 0;
    } else {
      fprintf(stderr,"setaffinity_processor_unbind: unknown error %d\n", errno);
      return 0;
    }
  }
  return 1;
}

int setaffinity_processor_bind(int pid,AV* mask)
{
  int r,z;
  idtype_t idtype = P_PID;
  id_t id = (id_t) pid;
  processorid_t processorid = (processorid_t) mask;
  processorid_t obind = (processorid_t) mask;
  int ncpus = sysconf(_SC_NPROCESSORS_ONLN);
  int len_mask = av_len(mask) + 1;
  if (len_mask > ncpus) {
    fprintf(stderr,"setaffinity_processor_bind: too many items in cpu mask!\n");
    return 0;
  }
  if (len_mask == ncpus || len_mask == 0) { /* unbind */
    return setaffinity_processor_unbind(pid);
  }
  if (len_mask > 1) {
    fprintf(stderr,"setaffinity_processor_bind: processor_bind() can only bind a process to a single cpu. Your complete set of desired CPU affinities will not be respected.\n");
  }
  z = SvIV(*av_fetch(mask, 0, 0));
  if (z < 0 || z >= ncpus) {
    fprintf(stderr,"setaffinity_processor_bind: invalid cpu spec %d\n", z);
    return 0;
  }

  r = processor_bind(P_PID, (id_t) pid, (processorid_t) z, NULL);
  if (r != 0) {
    if (errno == EFAULT) {
      fprintf(stderr,"setaffinity_processor_bind: error code EFAULT\n");
      return 0;
    } else if (errno == EINVAL) {
      fprintf(stderr,"setaffinity_processor_bind: error code EINVAL\n");
      return 0;
    } else if (errno == EPERM) {
      fprintf(stderr,"setaffinity_processor_bind: no permission to bind %d\n",
	      pid);
      return 0;
    } else if (errno == ESRCH) {
      fprintf(stderr,"setaffinity_processor_bind: no such PID %d\n", pid);
      return 0;
    } else {
      fprintf(stderr,"setaffinity_processor_bind: unknown error %d\n", errno);
      return 0;
    }
  }
  return 1;
}

int getaffinity_processor_bind(int pid, AV* mask)
{
  int r,z;
  processorid_t obind;
  r = processor_bind(P_PID, (id_t) pid, PBIND_QUERY, &obind);
  if (r != 0) {
    if (errno == EFAULT) {
      fprintf(stderr,"getaffinity_processor_bind: error code EFAULT %d\n",r);
      return 0;
    } else if (errno == EINVAL) {
      fprintf(stderr,"getaffinity_processor_bind: error code EINVAL %d\n",r);
      return 0;
    } else if (errno == EPERM) {
      fprintf(stderr,
	      "getaffinity_processor_bind: no permission to pbind %d (%d)\n",
	      pid, r);
      return 0;
    } else if (errno == ESRCH) {
      fprintf(stderr,"getaffinity_processor_bind: no such PID %d (%d)\n", 
	             pid, r);
      return 0;
    } else {
      fprintf(stderr,"getaffinity_processor_bind: unknown error %d %d\n",
                     errno, r);
      return 0;
    }
  }
  if (obind == PBIND_NONE) {
    /* process is unboud */
    int i, n;
    n = sysconf(_SC_NPROCESSORS_ONLN);
    av_clear(mask);
    for (i=0; i<n; i++) {
      av_push(mask, newSvIV(i));
    }
    return 1;
  }
  av_clear(mask);
  av_push(mask, newSvIV(obind));
  return 1;
}




MODULE = Sys::CpuAffinity        PACKAGE = Sys::CpuAffinity


int
  xs_getaffinity_processor_bind(pid,mask)
	int pid
        AV *mask
    CODE:
	RETVAL = getaffinity_processor_bind(pid);
    OUTPUT:
	RETVAL


int
xs_setaffinity_processor_bind(pid,mask)
        int pid
	AV *mask
    CODE:
	/* Bind a process to a single CPU. For Solaris. */
	RETVAL = setaffinity_processor_bind(pid,mask);
    OUTPUT:
	RETVAL

int
xs_setaffinity_processor_unbind(pid)
	int pid
    CODE:
	/* Allow a process to run on all CPUs. For Solaris. */
	RETVAL = setaffinity_processor_unbind(pid);
    OUTPUT:
	RETVAL


