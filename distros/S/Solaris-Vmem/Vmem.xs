#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/mman.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Solaris::Vmem		PACKAGE = Solaris::Vmem		

unsigned long
alloc(var,size)
   size_t size;
   SV*    var;
PREINIT:
   size_t pagesize;
   size_t vmsize;
   void*  ptr;
   int    fd;
CODE:
   if(size <= 0)
      croak("invalid size (%d)", size);
   pagesize = sysconf(_SC_PAGESIZE);
   vmsize   = (size+pagesize-1) & -pagesize;
#if defined MAP_ANON
   ptr = mmap(0, vmsize, PROT_READ|PROT_WRITE,
      MAP_PRIVATE|MAP_NORESERVE|MAP_ANON, -1, 0);
#else
   fd  = open("/dev/zero", O_RDWR);
   ptr = mmap(0, vmsize, PROT_READ|PROT_WRITE,
      MAP_PRIVATE|MAP_NORESERVE, fd, 0);
   (void)close(fd);
#endif
   if(ptr == MAP_FAILED)
      croak("allocation failed (%s)", strerror(errno));
   ST(0) = &PL_sv_undef;
   SvUPGRADE(var, SVt_PV);
   SvPVX(var) = (char*)ptr;
   SvCUR_set(var, vmsize);
   SvLEN_set(var, 0);
   SvPOK_only(var);
   ST(0) = sv_2mortal(newSVnv(vmsize));

void
release(var)
   SV*    var;
PREINIT:
   size_t vmsize;
   void*  ptr;
CODE:
   ptr    = (void*)SvPV(var,vmsize);
   if(munmap(ptr, vmsize) != 0)
      croak("deallocation failed (%s)", strerror(errno));
   SvPVX(var) = 0;
   SvCUR_set(var, 0);
   SvLEN_set(var, 0);
   SvOK_off(var);

SV*
trim(var,size)
   SV*    var;
   size_t size;
PREINIT:
   size_t vmsize;
   size_t newsize;
   size_t pagesize;
   void*  ptr;
CODE:
   ST(0)    = &PL_sv_undef;
   ptr      = (void*)SvPV(var,vmsize);
   pagesize = sysconf(_SC_PAGESIZE);
   newsize  = (size+pagesize-1) & -pagesize;
   if(newsize < vmsize) {
      if(munmap((char*)ptr+newsize, (vmsize-newsize)) != 0)
	 croak("reallocation failed (%s)", strerror(errno));
      SvCUR_set(var, newsize);
      SvLEN_set(var, 0);
   }
   ST(0) = sv_2mortal(newSVnv(newsize));
