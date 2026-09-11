#ifndef PUNK_FROZEN_H
#define PUNK_FROZEN_H

/* Frozen's C ABI, resolved once at first use.
 *
 * Frozen holds an immutable block of nested data addressed by offset and
 * read without touching a reference count. Punk's catalogues live in one,
 * and the read path goes through this table rather than through Frozen's
 * Perl surface: a Perl frame per lookup is the cost punk_i18n.h exists to
 * avoid, so reaching Frozen by method call would make i18n slower rather
 * than faster.
 *
 * Its own header documents a different resolution idiom - eval_pv in a
 * BOOT: block. Punk does not do that anywhere, and the reason is not
 * style: Perl_eval_sv leaks immortal refcounts on perls up to 5.20, which
 * t/0012-immortal-refcount.t catches, so every provider here goes through
 * pk_require_once instead. A reader comparing the two headers would
 * otherwise assume this one had it wrong.
 *
 * Separate from punk_i18n.h so a later consumer - a frozen config, a
 * frozen routing table - can reuse it without dragging i18n in.
 */

#include "fz_abi.h"          /* Frozen's public ABI, via ExtUtils::Depends */

static const fz_abi *PUNK_FZ = NULL;
static int PUNK_FZ_TRIED = 0;

/* Resolve (once) Frozen's ABI table, or NULL. PUNK_FAKE_FZ_BAD simulates a
 * version mismatch for the guard test. */
static const fz_abi *punk_fz_try(pTHX) {
    if (!PUNK_FZ_TRIED) {
        dSP; int count; UV p = 0;
        PUNK_FZ_TRIED = 1;
        if (pk_require_once(aTHX_ "Frozen", FALSE)) {
            SPAGAIN;   /* the require may have reallocated the value stack */
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            count = call_pv("Frozen::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            /* SvUV, not SvIV: Frozen::_abi_ptr returns a UV deliberately,
             * because where the loader maps the object decides the sign
             * bit and a 32-bit perl above 0x7fffffff hands back a negative
             * from PTR2IV.
             *
             * And popped ONCE, into an SV*, because SvUV is a macro that
             * mentions its argument more than once: SvUV(POPs) pops twice
             * and reads the address off the wrong slot. punk_blob.h:77-89
             * carries the same warning and the release it cost. */
            if (count > 0) {
                SV *sv = POPs;
                if (!SvTRUE(ERRSV)) p = SvUV(sv);
            }
            PUTBACK; FREETMPS; LEAVE;
            if (p) {
                const fz_abi *a = INT2PTR(const fz_abi *, p);
                /* >= and never ==: the table is append-only, so a later
                 * one is a superset whose prefix stays valid. Equality
                 * would make every Frozen release break Punk, which is
                 * what Reverse::Proxy 0.04 did against Fetch. */
                if (a && !getenv("PUNK_FAKE_FZ_BAD")
                    && a->abi_version >= FZ_ABI_VERSION)
                    PUNK_FZ = a;
            }
        }
    }
    return PUNK_FZ;
}

/* The table, croaking if it is missing or too old.
 *
 * Frozen is a HARD dependency: there is no arena to fall back to, because
 * the block IS the arena. Called from the plugin's register, so this is a
 * boot-environment error rather than a surprise mid-request. */
static const fz_abi *punk_fz(pTHX) {
    const fz_abi *a = punk_fz_try(aTHX);
    if (!a)
        croak("Punk::Plugin::I18n needs Frozen with a compatible C ABI "
              "(FZ_ABI_VERSION %d); upgrade Frozen to 0.06+", FZ_ABI_VERSION);
    return a;
}

#endif /* PUNK_FROZEN_H */
