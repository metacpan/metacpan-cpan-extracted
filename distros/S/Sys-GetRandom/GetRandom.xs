#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>
#include <sys/types.h>
#ifdef __OpenBSD__
    #include <unistd.h>
    #define GRND_NONBLOCK 1u
    #define GRND_RANDOM 2u
#else
    #include <sys/random.h>
#endif

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
#ifdef __OpenBSD__
        if (flags & ~(GRND_NONBLOCK | GRND_RANDOM)) {
            errno = EINVAL;
            XSRETURN_UNDEF;
        }
#endif
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
#ifdef __OpenBSD__
        {
            int r = getentropy(p, length);
            assert(r == -1 || r == 0);
            RETVAL = r == -1 ? r : length;
        }
#else
        RETVAL = getrandom(p, length, flags);
#endif
        if (RETVAL == -1) {
            XSRETURN_UNDEF;
        }
        p[RETVAL] = '\0';
        SvCUR_set(buffer, offset + RETVAL);
        SvUTF8_off(buffer);
        SvSETMAGIC(buffer);
    OUTPUT:
        RETVAL
