#ifndef SC_ABI_H
#define SC_ABI_H

/* Public C ABI for Struct::Codec (the provider) and its XS consumers.
 *
 * It is resolved at RUNTIME via Struct::Codec::_abi_ptr - a DBI-style versioned
 * function-pointer table - so there is no link-time symbol coupling and each
 * dist builds and upgrades independently. A consumer reaches this header
 * through ExtUtils::Depends, or vendors a copy pinned at SC_ABI_VERSION, and
 * checks abi_version at boot; a mismatch means "fall back", never a crash.
 *
 * The table only ever grows at the end. SC_ABI_VERSION bumps on any append, and
 * a consumer requires abi_version >= the version it was written against,
 * treating a later table as a superset it uses a prefix of.
 *
 * NOT ==. An equality check turns every provider release into a breaking change
 * for every consumer: a sibling dist in this workspace chose equality against
 * another's ABI and stopped loading everywhere the moment that provider
 * appended one member, croaking "please upgrade" at installations whose
 * provider was already newer than required.
 *
 * ---- EVERY ENTRY NEEDS PERL --------------------------------------------------
 *
 * Unlike a reader ABI, a codec has nothing to do without an interpreter: the
 * one side is an SV and the other is bytes it built from one. So every entry
 * takes pTHX_ and this header must be included after perl.h. There is no
 * perl-free half to look for.
 *
 * ---- names ---------------------------------------------------------------------
 *
 * No member is called open, close, read, write, free, time or anything else
 * XSUB.h turns into a function-like macro under PERL_IMPLICIT_SYS, which every
 * Strawberry perl is. Call through the table with the member in parentheses
 * anyway - (SC->encode)(aTHX_ v) - because the habit costs nothing and the
 * sibling that shipped a member called `close` learned why on a smoker.
 *
 * ---- ownership -----------------------------------------------------------------
 *
 *   - Every SV an entry returns has a refcount of ONE, owned by the caller.
 *     It may also be on the temps stack, so that a croak part-way through
 *     could free it; that pending decrement is the calling frame's, exactly
 *     as for an XSUB's return value, and a consumer that keeps the SV beyond
 *     the current statement holds its own reference as it would anyway.
 *   - `encode_to` writes only inside [buf, buf + cap). It allocates nothing on
 *     the too-small path, which is why a fixed-slot store calls it rather than
 *     `encode`: an oversized value is refused without a malloc.
 *   - Nothing is retained between calls. The table is stateless.
 *
 * ---- resolving the table --------------------------------------------------------
 *
 * At BOOT, once, never per call:
 *
 *     static const sc_abi *SC = NULL;
 *
 *     BOOT:
 *     {
 *         SV *err;
 *         SV *sv = eval_pv("require Struct::Codec; Struct::Codec::_abi_ptr()", 0);
 *         err = get_sv("@", 0);
 *         if (sv && SvOK(sv) && (!err || !SvTRUE(err))) {
 *             const sc_abi *t = INT2PTR(const sc_abi *, SvUV(sv));
 *             if (t && t->abi_version >= SC_ABI_VERSION) SC = t;
 *         }
 *     }
 *
 * The VALUE eval_pv returns, not the top of the stack: eval_pv has already
 * popped what it evaluated, and reading PL_stack_sp instead finds whatever was
 * there before. And if the BOOT captured SP with dSP before calling eval_pv
 * and uses it afterwards, SPAGAIN first: eval_pv runs arbitrary Perl, which can
 * reallocate the value stack. SvUV into a UV, never SvIV: an address is
 * unsigned, and where the loader maps the object high the sign bit is set.
 *
 * A NULL SC means Struct::Codec is absent or too old. What a consumer does
 * about that is its own policy; Shared::Arena treats it as a hard prerequisite
 * and croaks at load naming both versions.
 *
 * ---- what the bytes promise ------------------------------------------------------
 *
 * `decode(encode(v))` is v: strings stay strings and numbers stay numbers, the
 * UTF-8 flag survives, a blessed referent is blessed into the same class, and
 * references that were shared or cyclic are shared or cyclic again. Weak
 * references come back strong and a dualvar keeps its string. A closure, an
 * anonymous XSUB and a nameless empty glob are refused with a croak naming
 * the type, and so is a pointer object: a blessed scalar holding only an
 * integer in a class with a DESTROY, which is how XS hands out a handle to a
 * C struct. The table has no option to drop those; the Perl surface does.
 *
 * Contents are TRUSTED, as Storable's are: a class name in the stream is
 * blessed into, creating the stash. Corrupt bytes are a different matter and
 * are always a croak, never a crash.
 */

#define SC_ABI_VERSION 1

typedef struct sc_abi {
    int abi_version;                  /* consumers compare >= what they need */

    /* An owned SV of bytes, UTF-8 flag off. Croaks on a value that cannot be
     * encoded, naming the type. */
    SV     *(*encode)(pTHX_ SV *value);

    /* Into caller memory. Returns the bytes written, or 0 with *need set to
     * what would have been written when `cap` is too small; on that path
     * nothing past `cap` is touched and nothing is allocated. `need` may be
     * NULL. Croaks only on a value that cannot be encoded at any size. */
    STRLEN  (*encode_to)(pTHX_ SV *value, char *buf, STRLEN cap, STRLEN *need);

    /* An owned SV. Croaks on corrupt input with the reason and the byte
     * offset it was found at. */
    SV     *(*decode)(pTHX_ const char *bytes, STRLEN len);
} sc_abi;

#endif /* SC_ABI_H */
