#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/resource.h>

MODULE = Proc::Wait3		PACKAGE = Proc::Wait3		

PROTOTYPES: DISABLE

void
wait3(block)
  int block
  PPCODE:
    int stat;
    struct rusage r;
    pid_t pid;
    pid = wait3(&stat, block ? 0 : WNOHANG, &r);
    if (pid > 0)
    {
	EXTEND(sp, 18);
        PUSHs(sv_2mortal(newSViv(pid)));
        PUSHs(sv_2mortal(newSViv(stat)));
        PUSHs(sv_2mortal(newSVnv(r.ru_utime.tv_sec
	                         + r.ru_utime.tv_usec/1000000.0)));
        PUSHs(sv_2mortal(newSVnv(r.ru_stime.tv_sec
	                         + r.ru_stime.tv_usec/1000000.0)));
        PUSHs(sv_2mortal(newSViv(r.ru_maxrss)));
        PUSHs(sv_2mortal(newSViv(r.ru_ixrss)));
        PUSHs(sv_2mortal(newSViv(r.ru_idrss)));
        PUSHs(sv_2mortal(newSViv(r.ru_isrss)));
        PUSHs(sv_2mortal(newSViv(r.ru_minflt)));
        PUSHs(sv_2mortal(newSViv(r.ru_majflt)));
        PUSHs(sv_2mortal(newSViv(r.ru_nswap)));
        PUSHs(sv_2mortal(newSViv(r.ru_inblock)));
        PUSHs(sv_2mortal(newSViv(r.ru_oublock)));
        PUSHs(sv_2mortal(newSViv(r.ru_msgsnd)));
        PUSHs(sv_2mortal(newSViv(r.ru_msgrcv)));
        PUSHs(sv_2mortal(newSViv(r.ru_nsignals)));
        PUSHs(sv_2mortal(newSViv(r.ru_nvcsw)));
        PUSHs(sv_2mortal(newSViv(r.ru_nivcsw)));
    }    
