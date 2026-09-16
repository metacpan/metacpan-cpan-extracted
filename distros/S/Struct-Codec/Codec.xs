/*
 * Codec.xs - root XS file for Struct::Codec.
 *
 * The perl headers, then the format, the codec, the public ABI header and the
 * table behind it, then the per-package XS fragments from xs/ via INCLUDE:.
 *
 * This file sits at the TOP of the dist rather than under lib/. An XSMULTI
 * build from lib/Struct/Codec.xs writes its linker export list to
 * lib/Struct/Codec.def, while the import-library rule Strawberry adds for MinGW
 * reads $(EXPORT_LIST), which is always $(BASEEXT).def in the top directory -
 * the two names never meet and dlltool fails the build.
 *
 * The rules every header under include/sc/ follows:
 *
 *  1. C89 declarations at block top. No VLAs, no designated initialisers, no
 *     %zu, no //.
 *  2. Every function takes pTHX_ - there is no perl-free half here, because a
 *     codec that builds SVs has nothing to do without an interpreter.
 *  3. Corrupt input is a croak with a reason and a byte offset, never a crash.
 *     Every read is bounds-checked first and every container is attached to
 *     its parent before it is filled, so a croak frees what was built.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "sc/sc_format.h"    /* the tags and the header: what the bytes mean */
#include "sc/sc_codec.h"     /* the encoder and the decoder                  */
#include "sc_abi.h"          /* the PUBLIC table a consumer resolves         */
#include "sc/sc_abi_impl.h"  /* and what it points at                        */

/* GvCV_set arrived after 5.12, and before it the glob's CV slot was assigned
 * directly. Without this the import XSUB compiles as an IMPLICIT DECLARATION
 * on 5.10 and 5.12 - a warning today, an error on a stricter compiler, and a
 * call through a guessed prototype either way. Found by the docker matrix;
 * the Mac's 5.42 has the macro and said nothing. */
#ifndef GvCV_set
#  define GvCV_set(gv, cv) (GvCV(gv) = (cv))
#endif

MODULE = Struct::Codec    PACKAGE = Struct::Codec

PROTOTYPES: DISABLE

# An owned byte string. The UTF-8 flag is off: this is a byte string whatever
# the value held, and a caller that treats it as characters gets it wrong.
#
# struct_encode is the name; encode is the same XSUB under the short name for
# a caller who writes Struct::Codec::encode in full. Only the long names are
# ever exported, so neither collides with Encode's in a caller's namespace.
SV *
struct_encode(value)
        SV *value
    ALIAS:
        encode = 1
    CODE:
        PERL_UNUSED_VAR(ix);
        RETVAL = sc_encode(aTHX_ value);
    OUTPUT:
        RETVAL

# The value back. Croaks on anything that is not a stream this build wrote:
# the message names the reason and the byte it was found at.
SV *
struct_decode(bytes)
        SV *bytes
    ALIAS:
        decode = 1
    PREINIT:
        const char *p;
        STRLEN len;
    CODE:
        PERL_UNUSED_VAR(ix);
        p = SvPV(bytes, len);
        RETVAL = sc_decode(aTHX_ p, len);
    OUTPUT:
        RETVAL

# `use Struct::Codec qw(struct_encode struct_decode)`. Exports on request only,
# and only those two names: an unknown name is an error at compile time of the
# caller, not a silent no-op. The caller's package is the one compiling the
# `use`, which is what PL_curcop names while import runs.
void
import(class, ...)
        SV *class
    PREINIT:
        const char *pkg;
        I32 i;
    CODE:
        PERL_UNUSED_VAR(class);
        pkg = CopSTASHPV(PL_curcop);
        for (i = 1; i < items; i++) {
            STRLEN nlen;
            const char *name = SvPV(ST(i), nlen);
            GV *gv;
            CV *cv;
            if (!(nlen == 13 && memEQ(name, "struct_encode", 13))
             && !(nlen == 13 && memEQ(name, "struct_decode", 13)))
                croak("Struct::Codec does not export '%" SVf "'", SVfARG(ST(i)));
            cv = get_cv(name[7] == 'e' ? "Struct::Codec::struct_encode"
                                       : "Struct::Codec::struct_decode", 0);
            gv = gv_fetchpv(Perl_form(aTHX_ "%s::%s", pkg, name), GV_ADD, SVt_PVCV);
            SvREFCNT_inc_simple_void_NN((SV *)cv);
            GvCV_set(gv, cv);
            GvIMPORTED_CV_on(gv);
        }

# Private. Compiles a pattern with RXf_PMf_* flags for the decoder, which
# calls it under G_EVAL: that is the one clean way to catch the regexp
# engine's croak from C, so a pattern that will not compile is reported with
# the byte it was found at like every other refusal. A reference to the
# compiled regexp, unblessed; the decoder blesses it.
SV *
_regcomp(pattern, flags)
        SV *pattern
        UV flags
    PREINIT:
        REGEXP *rx;
    CODE:
#if SC_HAVE_REGEXP
        rx = pregcomp(pattern, (U32)flags);
        if (!rx) croak("Struct::Codec: regexp did not compile");
        RETVAL = newRV_noinc((SV *)rx);
#else
        PERL_UNUSED_VAR(pattern);
        PERL_UNUSED_VAR(flags);
        rx = NULL;
        croak("Struct::Codec: a regexp needs perl 5.12 or later");
        RETVAL = &PL_sv_undef;
#endif
    OUTPUT:
        RETVAL

# Private, for the tests: encode_to into a buffer of exactly `cap` bytes, as a
# fixed-slot consumer does through the ABI. (bytes, need) when it fit, (undef,
# need) when it did not.
void
_encode_to(value, cap)
        SV *value
        UV cap
    PREINIT:
        SV *buf;
        STRLEN need = 0, got;
    PPCODE:
        buf = sv_2mortal(newSV((STRLEN)cap + 1));
        got = sc_encode_to(aTHX_ value, SvPVX(buf), (STRLEN)cap, &need);
        EXTEND(SP, 2);
        if (got) {
            SvPOK_only(buf);
            SvCUR_set(buf, got);
            SvPVX(buf)[got] = '\0';
            PUSHs(buf);
        }
        else {
            PUSHs(&PL_sv_undef);
        }
        mPUSHu((UV)need);

INCLUDE: xs/abi.xs
