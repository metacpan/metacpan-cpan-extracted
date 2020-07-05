#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <unistd.h>
#include <fcntl.h>

#include <stdbool.h>

// CopSTASH isn’t documented as part of the API but is heavily used
// on CPAN. There is PL_curstash, but that doesn’t work with, e.g.,
// “perl -e'package Foo; _print_pl_curstash()'”, whereas PL_curcop does.
#define SP_CUR_STASH ( (HV*)CopSTASH(PL_curcop) )

#define SP_CUR_PKGNAME HvNAME( SP_CUR_STASH )

//----------------------------------------------------------------------

static inline void _fd2sv( pTHX_ int fd, bool is_read, SV* sv ) {
    PerlIO *pio = PerlIO_fdopen(fd, is_read ? "r" : "w");

    GV* gv = newGVgen( SP_CUR_PKGNAME );
    IO* io = GvIOn(gv);

    SvUPGRADE(sv, SVt_IV);
    SvROK_on(sv);
    SvRV_set(sv, (SV*)gv);

    IoTYPE(io) = is_read ? '<' : '>';
    IoIFP(io) = pio;
    IoOFP(io) = pio;
}

int _sp_pipe( pTHX_ SV* infh, SV* outfh, int flags ) {
    int fds[2];

// This macro comes from Makefile.PL:
#ifdef SP_HAS_PIPE2
    int ret = pipe2(fds, flags);
#else
    if (flags != 0) {
        croak("This system lacks pipe2 support, so pipe() cannot accept flags.");
    }

    int ret = pipe(fds);
#endif

    if (!ret) {

        // These don’t seem to be available to extensions,
        // but apparently they’re unneeded anyway.
        //
        // Perl_setfd_cloexec_for_nonsysfd(fds[0]);
        // Perl_setfd_cloexec_for_nonsysfd(fds[1]);

        _fd2sv( aTHX_ fds[0], true, infh );
        _fd2sv( aTHX_ fds[1], false, outfh );
    }

    return ret;
}

//----------------------------------------------------------------------
//----------------------------------------------------------------------

MODULE = Sys::Pipe          PACKAGE = Sys::Pipe

PROTOTYPES: DISABLE

BOOT:
    HV *stash = gv_stashpv("Sys::Pipe", FALSE);
    newCONSTSUB(stash, "has_pipe2", newSVuv(
#if SP_HAS_PIPE2
        1
#else
        0
#endif
    ));

SV*
pipe( SV *infh, SV *outfh, int flags = 0 )
    CODE:
        if (_sp_pipe(aTHX_ infh, outfh, flags)) {
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = newSVuv(1);
        }

    OUTPUT:
        RETVAL

