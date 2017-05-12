#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <sys/types.h>
#include <sys/processor.h>
#include <sys/procset.h>
#include <sys/pset.h>

#include <unistd.h>

#include <errno.h>

/*

CPU affinity on solaris:

Solaris 11.2 allows "Multi-CPU Binding" through the
processor_affinity(2) system call. Using it is superior
to the  pset_XXX  suite of functions or the  psrset  
utility, as it typically requires privileges to set up
a processor set.

processor_bind(2) is a backwards-compatible wrapper
around process_affinity() that can bind threads to a 
single processor, and is available on systems prior
to 11.2.

processor_affinity usage:

  int processor_affinity(procset_t *ps, uint_t *nids, id_t *ids, uint32_t *flags)

  ps: procset structure that identifies which LWPs are affected by the call

  nids: pointer to size of ids

  ids: array of processor IDs

  flags: combo of bit masks:
      PA_QUERY     to query flags and affinities
      PA_CLEAR     to clear existing affinity
      PA_TYPE_CPU  ids is array of processor IDs (default)
      PA_TYPE_PG   ids is array of processor group IDs (not interesting)
      PA_TYPE_LGRP ids is array of Locality Group IDs (not interesting)
      PA_AFF_WEAK  set weak affinity (preference for CPUs, not interesting)
      PA_AFF_STRONG set strong affinity (required to run on CPUs)
      PA_NEGATIVE  used with AFF_WEAK/STRONG to *avoid* certain CPUs
      PA_INH_EXEC  affinity should not be inherited across an exec call
      PA_INH_FORK  affinity should not be inherited across a fork call
      PA_INH_THR   affinity should not be inherited by a new thread

   on a query (PA_QUERY), *nids will be # of processors that PID has affinity for,
   ids will contain "the IDs of the indicated type", flags will have info
   about affinity strength and inheritance

 */

int getaffinity_processor_affinity(int pid,AV *mask)
{
  int r,i;
  uint_t np = sysconf(_SC_NPROCESSORS_ONLN);
  uint32_t flags = PA_QUERY | PA_TYPE_CPU;
  id_t *ids = malloc(sizeof(id_t) * np);
  uint_t n = np;  

  procset_t ps;
  setprocset(&ps, POP_AND, P_PID, pid, P_ALL, 0);

  r = processor_affinity(&ps, &n, ids, &flags);
  if (r != 0) { /* error */
    fprintf(stderr,"xs_getaffinity_processor_affinity: "
                   "processor_affinity() returned %d errno=%d\n", r, errno);
    return 0;
  }
  if (n == 0) { /* unbound */
    av_clear(mask);
    for (i=0; i<np; i++) {
      av_push(mask, newSViv(i));
    }
    return 1;
  }
  /* n != 0: bound to processors in ids[0 .. n-1] */
  av_clear(mask);
  for (i=0; i<n; i++) {
    av_push(mask, newSViv(ids[i]));
  }
  return 1;
}

int setaffinity_processor_affinity(int pid, AV *mask)
{
  int r = -999,i;
  uint_t np = sysconf(_SC_NPROCESSORS_ONLN);
  uint32_t flags = PA_TYPE_CPU | PA_AFF_STRONG;
  id_t *ids = malloc(sizeof(id_t) * np);
  uint_t n = av_len(mask) + 1;

  procset_t ps;
  setprocset(&ps, POP_AND, P_PID, pid, P_ALL, 0);

  if (n > np) {
    fprintf(stderr,"xs_setaffinity_processor_affinity: cpu mask is larger "
                   "than num cpus (%d > %d)\n", n, np);
    return 0;
  }
  if (n == 0) {
    fprintf(stderr,"xs_setaffinity_processor_affinity: no CPU mask specified!");
    return 0;
  }
  if (n == np) {
    /* unbind processor */
    flags |= PA_CLEAR;
    r = processor_affinity(&ps, &n, ids, &flags);
  } else {
    for (i=0; i<n; i++) {
      ids[i] = SvIV(*av_fetch(mask, i, 0));
    }
    r = processor_affinity(&ps, &n, ids, &flags);
  }
  if (r == 0) {
    return 1;
  }
  fprintf(stderr,"xs_setaffinity_processor_affinity: "
          "processor_affinity() call returned %d errno=%d\n", r, errno);
  return 0;
}

MODULE = Sys::CpuAffinity        PACKAGE = Sys::CpuAffinity


int
xs_getaffinity_processor_affinity(pid, maskarray)
	int pid
        AV* maskarray
    CODE:
        RETVAL = getaffinity_processor_affinity(pid,maskarray);
    OUTPUT:
	RETVAL

int
xs_setaffinity_processor_affinity(pid, maskarray)
	int pid
        AV* maskarray
    CODE:
        RETVAL = setaffinity_processor_affinity(pid,maskarray);
    OUTPUT:
	RETVAL

int
xs_solaris_numCpus()
    CODE:
        RETVAL = sysconf(_SC_NPROCESSORS_ONLN);
    OUTPUT:
	RETVAL

