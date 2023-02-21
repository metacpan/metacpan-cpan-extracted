#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/random.h>
#include <sys/types.h>
#include <errno.h>

#define MY_PKG "Sys::GetRandom"

#ifndef PERL_VERSION_GE
    #define PERL_VERSION_GE(R, V, S) (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && PERL_SUBVERSION >= (S)))))
#endif

MODULE = Sys::GetRandom  PACKAGE = Sys::GetRandom  PREFIX = sgr_
PROTOTYPES: ENABLE

BOOT:
    {
        HV *const stash = gv_stashpvs(MY_PKG, GV_ADD);
        newCONSTSUB(stash, "GRND_NONBLOCK", newSVuv(GRND_NONBLOCK));
        newCONSTSUB(stash, "GRND_RANDOM",   newSVuv(GRND_RANDOM));
    }

ssize_t
sgr_getrandom(buffer, length, flags = 0, offset = 0)
        SV *buffer
        size_t length
        unsigned int flags
        STRLEN offset
    PREINIT:
        char *p;
    CODE:
        if (length >= SSIZE_MAX || length >= (STRLEN)-1 - offset) {
            errno = EFAULT;
            XSRETURN_UNDEF;
        }
        if (!SvOK(buffer)) {
#if PERL_VERSION_GE(5, 25, 6)
            SvPVCLEAR(buffer);
#else
            sv_setpvs(buffer, "");
#endif
        } else {
            STRLEN curlen;
            SvPVbyte_force(buffer, curlen);
            (void)curlen;
        }
        p = offset + SvGROW(buffer, offset + length + 1u);
        RETVAL = getrandom(p, length, flags);
        if (RETVAL == -1) {
            XSRETURN_UNDEF;
        }
        p[RETVAL] = '\0';
        SvCUR_set(buffer, offset + RETVAL);
        SvUTF8_off(buffer);
        SvSETMAGIC(buffer);
    OUTPUT:
        RETVAL
