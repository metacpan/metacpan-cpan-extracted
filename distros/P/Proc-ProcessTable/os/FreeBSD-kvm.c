/* perl's struct cv conflicts with the definition in sys/condvar.h (included by sys/proc.h) */
#define cv perl_cv
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#undef cv

#include "os/FreeBSD-kvm.h"
#include <unistd.h>
#include <sys/sysctl.h>
#include <sys/proc.h>
#include <sys/times.h>
#include <sys/user.h>                                                          
#include <fcntl.h>
#include <kvm.h>
#include <paths.h>



/* Make sure /proc is mounted and initialize some global vars */
char* OS_initialize(){
  return NULL;
}

void OS_get_table(){

  kvm_t *kd;
  char errbuf[2048];
  struct kinfo_proc *procs;          /* array of processes */
  int count;                         /* returns number of processes */
  int i, j;
  char ** argv;

  char state[20];
  char start[20];
  char time[20];
  char utime[20];
  char stime[20];
  char ctime[20];
  char cutime[20];
  char cstime[20];
  char flag[20];
  char sflag[20];
  char pctcpu[20];

  static char format[128];
  char cmndline[ARG_MAX];
  int priority;

  int pagesize;

  AV *group_array;
  SV *group_ref;
  SV *oncpu;

  /* Open the kvm interface, get a descriptor */
  if ((kd = kvm_openfiles(_PATH_DEVNULL, _PATH_DEVNULL, NULL, O_RDONLY, errbuf)) == NULL) {
     /*fprintf(stderr, "kvm_open: %s\n", errbuf);*/
     ppt_croak("kvm_open: ", errbuf);
  }  

  /* Get the list of processes. */
  if ((procs = kvm_getprocs(kd, KERN_PROC_PROC, 0, &count)) == NULL) {
     kvm_close(kd);
     /*fprintf(stderr, "kvm_getprocs: %s\n", kvm_geterr(kd));*/
     ppt_croak("kvm_getprocs: ", kvm_geterr(kd));
  }

  pagesize = getpagesize();

  /* Iterate through the processes in kinfo_proc, sending proc info */
  /* to bless_into_proc for each proc */

  for (i=0; i < count; i++) {
     static struct pstats ps;
     static struct session seslead;
     strcpy(format, Defaultformat);

     // retrieve the arguments
     cmndline[0] = '\0';
     argv = kvm_getargv(kd, (const struct kinfo_proc *) &(procs[i]) , 0);
     if (argv) {
       int j = 0;
       while (argv[j] && strlen(cmndline)+strlen(argv[j])+1 <= ARG_MAX) {
         strcat(cmndline, argv[j]);
	 if (argv[j+1]) {
	   strcat(cmndline, " ");
	 }
         j++;
       }
     }

     switch (procs[i].ki_stat) {
        case SSTOP:
            strcpy(state, "stop");
            break;
        case SSLEEP:
            strcpy(state, "sleep");
            break;
        case SRUN:
            strcpy(state, "run");
            break;
        case SIDL:
            strcpy(state, "idle");
            break;
        case SWAIT:
            strcpy(state, "wait");
            break;
        case SLOCK:
            strcpy(state, "lock");
            break;
        case SZOMB:
            strcpy(state, "zombie");
            break;
        default:
            strcpy(state, "???");
            break;
     }


     sprintf(start, "%d.%06d", procs[i].ki_start.tv_sec, procs[i].ki_start.tv_usec);
     sprintf(time, "%.6f", procs[i].ki_runtime/1000000.0);
     sprintf(utime, "%d.%06d", procs[i].ki_rusage.ru_utime.tv_sec, procs[i].ki_rusage.ru_utime.tv_usec);
     sprintf(stime, "%d.%06d", procs[i].ki_rusage.ru_stime.tv_sec, procs[i].ki_rusage.ru_stime.tv_usec);
     sprintf(ctime, "%d.%06d", procs[i].ki_childtime.tv_sec, procs[i].ki_childtime.tv_usec);
     sprintf(cutime, "%d.%06d", procs[i].ki_rusage_ch.ru_utime.tv_sec, procs[i].ki_rusage_ch.ru_utime.tv_usec);
     sprintf(cstime, "%d.%06d", procs[i].ki_rusage_ch.ru_stime.tv_sec, procs[i].ki_rusage_ch.ru_stime.tv_usec);
     sprintf(flag, "0x%04x", procs[i].ki_flag);
     sprintf(sflag, "0x%04x", procs[i].ki_sflag);

     /* create groups array */
     group_array = newAV();
     for (j = 0; j < procs[i].ki_ngroups; j++) {
	 av_push(group_array, newSViv(procs[i].ki_groups[j]));
     }
     group_ref = newRV_noinc((SV *) group_array);

     oncpu = procs[i].ki_oncpu == 0xff ? &PL_sv_undef : newSViv(procs[i].ki_oncpu);

     /* get the current CPU percent usage for this process      */
     /* copied from FreeBSD sources bin/ps/ps.c and friends     */
     #define fxtofl(fixpt) ((double)(fixpt) / fscale)
     int fscale;
     size_t oldlen;
     fixpt_t ccpu;
     oldlen = sizeof(ccpu);
     if (sysctlbyname("kern.ccpu", &ccpu, &oldlen, NULL, 0) == -1)
             ppt_croak("cannot get kern.ccpu");
     if (sysctlbyname("kern.fscale", &fscale, &oldlen, NULL, 0) == -1)
             ppt_croak("cannot get kern.fscale");
     double pcpu;
     if (procs[i].ki_swtime == 0 || (procs[i].ki_flag & P_INMEM) == 0)
             pcpu = 0.0;
     else
             pcpu = (100.0 * fxtofl(procs[i].ki_pctcpu) / (1.0 - exp(procs[i].ki_swtime * log(fxtofl(ccpu)))));
     sprintf(pctcpu,"%.1f",pcpu);

     bless_into_proc( format,
                      Fields,

                      procs[i].ki_pid,
                      procs[i].ki_ppid,
                      procs[i].ki_ruid,
                      procs[i].ki_uid,
                      procs[i].ki_rgid,
                      procs[i].ki_pgid,
                      procs[i].ki_sid,
		      procs[i].ki_jid,

                      flag,
                      sflag,

                      start,
 
                      time,
		      utime,
		      stime,
                      ctime,
		      cutime,
		      cstime,
                      pctcpu,

                      procs[i].ki_wmesg,
                      state,

                      "??", // will be resolved automatically
                      procs[i].ki_tdev,

                      procs[i].ki_comm,
                      cmndline,

                      procs[i].ki_pri.pri_user,
                      procs[i].ki_nice,

                      procs[i].ki_size,              // virtual size
                      procs[i].ki_size,              // alias
                      procs[i].ki_rssize,              // current resident set size in pages
                      procs[i].ki_rssize*pagesize,     // rss in bytes
                      procs[i].ki_tsize,               // text size (pages) XXX
                      procs[i].ki_dsize,               // data size (pages) XXX
                      procs[i].ki_ssize,               // stack size (pages)   

		      procs[i].ki_rusage.ru_majflt,
		      procs[i].ki_rusage.ru_minflt,
		      procs[i].ki_rusage_ch.ru_majflt, // XXX - most fields in ki_rusage_ch are not (yet) filled in
		      procs[i].ki_rusage_ch.ru_minflt, // XXX - most fields in ki_rusage_ch are not (yet) filled in

		      procs[i].ki_numthreads,
		      oncpu,

		      group_ref
              );


   }
   if (kd) kvm_close(kd);
}

