#ifndef SA_SERIALISE_H
#define SA_SERIALISE_H

/* sa_serialise.h - a map or cache value as a Perl structure. NOT perl-free:
 * this is the one header under include/sa/ besides sa_xop.h that needs an
 * interpreter, because a codec has nothing to do without one.
 *
 * A map or cache made with `serialise => 1` stores a Perl structure and gives
 * THE SAME structure back: types, the UTF-8 flag, a blessing, shared and
 * cyclic references. Struct::Codec is the encoding and the decoder, reached
 * through its ABI table so a set or a get costs no Perl frame; the table is
 * resolved once at BOOT, in xs/cache.xs, on the Frozen model in Arena.xs.
 *
 * The flag itself lives in the SHARED tenant header (sa_cache.h, sa_hash.h),
 * because a process that treats a cache as bytes and another that treats it
 * as encoded values are two caches that disagree about every value. A bind
 * that asks for the other setting is refused with SA_E_SHAPE.
 *
 * The C ABI in sa_abi.h stays bytes-level: a serialised tenant's values are
 * Struct::Codec's encoding, and a C consumer writing one encodes through
 * sc_abi.h or not at all.
 */

#include "sc_abi.h"

static const sc_abi *SA_SC = NULL;

/* A value encodes onto the caller's stack when the room left in the slot is at
 * most this. That is where the small-value win is: no allocation on a set. */
#define SA_SER_STACK 4096

/* Encode `value` for a slot whose key already takes `klen` of `pair_max`.
 *
 * Up to SA_SER_STACK bytes of room it is `encode_to` straight into `stack`,
 * which allocates nothing on the too-small path either. Past that it is
 * `encode`, which allocates what the value needs rather than what the slot
 * could hold, into a mortal.
 *
 * Returns the length and sets *out, or 0 when the value will not fit: the
 * same refusal an oversized byte value gets, so a caller sees one behaviour
 * for "too big" whatever the value was. A value that cannot be encoded at all
 * croaks through the codec, before anything is stored.
 *
 * Both entries can run Perl (an anonymous sub is deparsed), which may
 * reallocate the value stack. A door that captured `sp` or `mark` before
 * calling this must SPAGAIN and re-derive `mark` from TOPMARK afterwards. */
static STRLEN sa_ser_encode(pTHX_ SV *value, uint64_t pair_max, STRLEN klen,
                            char *stack, const char **out)
{
    STRLEN cap = pair_max > klen ? (STRLEN)(pair_max - klen) : 0;
    if (cap <= SA_SER_STACK) {
        STRLEN n = (SA_SC->encode_to)(aTHX_ value, stack, cap, NULL);
        *out = stack;
        return n;
    }
    {
        SV *enc = sv_2mortal((SA_SC->encode)(aTHX_ value));
        *out = SvPVX(enc);
        return SvCUR(enc) <= cap ? SvCUR(enc) : 0;
    }
}

/* The structure back from a slot's bytes, as a mortal. Corrupt bytes croak
 * with the codec's reason; nothing here ever hands bytes back as a value. The
 * same warning about the value stack applies: decoding an anonymous sub runs
 * Perl. */
#define SA_SER_DECODE(p, len) \
    sv_2mortal((SA_SC->decode)(aTHX_ (p), (STRLEN)(len)))

/* One message from the XSUB and both incr doors. */
#define SA_SER_INCR_MSG "Shared::Arena::Map: incr on a serialised map"

#endif /* SA_SERIALISE_H */
