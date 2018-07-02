#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <sys/mount.h>
 
MODULE = Sys::Linux::Mount  PACKAGE = Sys::Linux::Mount
PROTOTYPES: ENABLE
 
 # XS code goes here
 
 # XS comments begin with " #" to avoid them being interpreted as pre-processor
 # directives
 
SV *_mount_sys(const char *source, const char *target, const char *filesystem, unsigned long mountflags, const char *data)
	CODE:
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), mount(source, target, filesystem, mountflags, (void *) data));

SV *_umount_sys(const char *target)
	CODE:
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), umount(target));

SV *_umount2_sys(const char *target, int umountflags)
	CODE:
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), umount2(target, umountflags));