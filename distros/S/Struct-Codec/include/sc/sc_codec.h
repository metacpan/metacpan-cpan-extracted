#ifndef SC_CODEC_H
#define SC_CODEC_H

/* sc_codec.h - the encoder and the decoder. Needs perl.h and sc_format.h.
 *
 * ---- the encoder's seen table is the design ---------------------------------
 *
 * A round-trip codec has to notice a reference it has already written. The
 * obvious way is a pointer-keyed hash of every SV met, and it costs a hash
 * insert per value, which on a five-key hash is more than the encoding. The
 * observation that removes it: a referent reachable only once has a refcount
 * of exactly one from the structure being encoded, so ONLY an SV with a
 * refcount above one can ever be met twice, and only those go into the table.
 * A plain tree does no table work at all.
 *
 * Immortals - PL_sv_undef, PL_sv_yes, PL_sv_no, PL_sv_zero - have enormous
 * refcounts and an identity nobody wants preserved; they are written by kind
 * and never tracked.
 *
 * ---- what is tracked, and under which offset -----------------------------------
 *
 * Two things can be shared: a REFERENT (two references to one hash) and a slot
 * SCALAR (the same SV in two array elements, which aliasing can produce). Both
 * are keyed by address in one table, and each entry records which it is:
 *
 *   - a referent is entered under the offset of the REF or OBJECT tag that
 *     introduced it. Meeting it again behind another reference writes REFP to
 *     that offset (a new reference to it); meeting it as a slot value writes
 *     ALIAS to that offset (the scalar itself, placed in the slot).
 *   - a slot scalar is entered under its own value tag's offset. Meeting it
 *     again as a slot value writes ALIAS; meeting it behind a reference writes
 *     REFP (a reference to it).
 *
 * A reference SV that is itself in two slots is NOT tracked as a scalar; it
 * comes back as two references to one referent, which is what a reader of the
 * structure sees anyway. That is the one identity this format gives up, and
 * the POD says so.
 *
 * ---- the decoder builds nothing it cannot free ---------------------------------
 *
 * Every container is stored into its parent, or made the mortal root, BEFORE
 * its elements are decoded, and a scalar is made, attached, then filled the
 * same way. A croak anywhere inside then frees the whole partial structure
 * through the root's mortality: nothing is leaked and nothing is unwound by
 * hand. The one thing that cannot be filled in place is an ALIAS - the slot
 * must hold an SV that already exists - so sc_dec_value returns that SV when it
 * meets one and the parent swaps it into the slot it had already attached.
 *
 * The rules for input that lies are numbered in plan_struct_codec/04, and each
 * is marked where it is enforced below with its number.
 */

#include "sc/sc_format.h"

#ifdef SvIsBOOL
#  define SC_HAVE_BOOL 1
#else
#  define SC_HAVE_BOOL 0
#endif

/* A regexp became its own SV type in 5.12, and SVt_REGEXP is an enumerator
 * rather than a macro, so this is a version test and not an #ifdef. */
#if PERL_REVISION > 5 || (PERL_REVISION == 5 && PERL_VERSION >= 12)
#  define SC_HAVE_REGEXP 1
#else
#  define SC_HAVE_REGEXP 0
#endif
/* The character-set modifiers, /a /aa /l /u /d, came in 5.14, and their
 * names are enumerators too. */
#if PERL_REVISION > 5 || (PERL_REVISION == 5 && PERL_VERSION >= 14)
#  define SC_HAVE_CHARSET 1
#else
#  define SC_HAVE_CHARSET 0
#endif

/* A reference was its own SV type until 5.12 merged it into SVt_IV. An SV
 * upgraded to SVt_IV with ROK set is not a reference on 5.10: `ref` answers
 * the empty string and every dereference finds nothing. */
#if PERL_REVISION > 5 || (PERL_REVISION == 5 && PERL_VERSION >= 12)
#  define SC_SVt_REF SVt_IV
#else
#  define SC_SVt_REF SVt_RV
#endif

#ifndef HvNAMEUTF8
#  define HvNAMEUTF8(hv) 0
#endif
#ifndef HvNAMELEN_get
#  define HvNAMELEN_get(hv) (HvNAME(hv) ? strlen(HvNAME(hv)) : 0)
#endif

#define SC_UV_BITS ((int)(sizeof(UV) * 8))

/* ---- floats on the wire ------------------------------------------------------
 *
 * An IEEE-754 double in little-endian order, so a stream reads the same on every
 * machine. Little-endian is the common case and there the conversion is a
 * memcpy; a big-endian host swaps. perl.h defines BYTEORDER on every build.
 *
 * A perl whose NV is wider than a double writes SC_T_NV_STR instead for the
 * values these 8 bytes cannot hold - see below. */
typedef char sc_assert_double[(sizeof(double) == SC_NV_BYTES) ? 1 : -1];

#if defined(BYTEORDER) && (BYTEORDER == 0x4321 || BYTEORDER == 0x87654321)
#  define SC_BIG_ENDIAN 1
#else
#  define SC_BIG_ENDIAN 0
#endif

static void sc_nv_to_wire(NV nv, unsigned char *out) {
    double dv = (double)nv;
    memcpy(out, &dv, SC_NV_BYTES);
#if SC_BIG_ENDIAN
    {
        int i;
        for (i = 0; i < SC_NV_BYTES / 2; i++) {
            unsigned char t = out[i];
            out[i] = out[SC_NV_BYTES - 1 - i];
            out[SC_NV_BYTES - 1 - i] = t;
        }
    }
#endif
}

static NV sc_nv_from_wire(const unsigned char *in) {
    double dv;
#if SC_BIG_ENDIAN
    unsigned char tmp[SC_NV_BYTES];
    int i;
    for (i = 0; i < SC_NV_BYTES; i++) tmp[i] = in[SC_NV_BYTES - 1 - i];
    memcpy(&dv, tmp, SC_NV_BYTES);
#else
    memcpy(&dv, in, SC_NV_BYTES);
#endif
    return (NV)dv;
}

/* ---- an NV that a double cannot hold -------------------------------------------
 *
 * Written as its decimal digits, not as the native bytes, because "an NV wider
 * than a double" is three different types across the perls that exist - the x87
 * 80-bit extended one, IEEE binary128, and on some PowerPC builds a pair of
 * doubles - and the bytes of one are not readable as another. Digits are
 * readable by all three, and by a plain double perl, which reads them to the
 * nearest double and so lands on the same value the 8-byte form would have
 * given it.
 *
 * NV_DIG + 3 is DECIMAL_DIG for the NV this perl was built with: 21 digits for
 * x87 extended, 36 for binary128. That is the shortest precision at which a
 * binary float of that width survives the trip out to decimal and back, which
 * t/25-wide-nv.t asserts directly rather than trusting the arithmetic.
 *
 * Both ends of that trip have to be the RIGHT primitive, and the obvious
 * spelling of each is wrong on one of the two wide widths. Gconvert is wrong on
 * both - config.h defines it as a plain "%.*g" even on a quadmath perl, where it
 * reads a __float128 through a double conversion - and perl's own sv.c goes
 * around it for that reason. What replaces it:
 *
 *   OUT. my_snprintf with the precision written INTO the format string, never
 *   passed as "%.*". Perl_my_snprintf hands any format ending "Qg" straight to
 *   quadmath_snprintf with ONE variadic argument (util.c, guarded by
 *   quadmath_format_valid, which does not reject a "*"), so a "*" there takes
 *   the precision from a slot nothing was pushed into. 0.03 wrote "%.*" NVgf
 *   and on the quadmath smokers printed ONE significant digit - a third came
 *   back 0.3 - while on the 32-bit one the garbage precision overran the buffer
 *   and perl panicked "my_snprintf buffer overflow". Perl's sv.c builds the
 *   digits into the format for the same reason; sc_nv_fmt is that, in one line.
 *
 *   BACK. strtod's family, not Atof. Atof is perl's own numifier and only
 *   became correctly rounded in 5.30: before that, on a perl whose NV is a long
 *   double, my_atof accumulates the digits and scales by a power of ten built
 *   from repeated squaring (S_mulexp10 in numeric.c), which is a ULP or two out
 *   at the full width of the NV, so the encoder's own DECIMAL_DIG digits did not
 *   read back as the number they were printed from. Perl fixed that for itself
 *   in 5.30 by numifying through strtod (perl RT #41202); every
 *   -Duselongdouble smoker below it failed eight subtests of t/25-wide-nv.t on
 *   0.03. A quadmath perl was never affected - my_atof3 has read through
 *   strtoflt128 since USE_QUADMATH existed - which is why the two widths
 *   reported different failures from the one tag.
 *
 * The radix is always '.' on the wire. my_snprintf formats under the locale
 * perl would print a number with, so inside "use locale" with a comma radix it
 * writes 0,333; the stream promises to say the same thing on every machine, and
 * the reader below parses a '.'.
 *
 * All of this is compiled out where NV is a double, so that encoder is the same
 * function it was before, byte for byte. */
#if defined(NVSIZE)
#  define SC_NV_WIDE (NVSIZE > 8)
#elif defined(USE_LONG_DOUBLE) || defined(USE_QUADMATH)
#  define SC_NV_WIDE 1
#else
#  define SC_NV_WIDE 0
#endif

#if SC_NV_WIDE

/* True when the 8-byte form would come back as a different number.
 *
 * A NaN is answered first because nv != nv is true of it, which would otherwise
 * send every NaN down the decimal path, and a NaN has no decimal spelling that
 * reads back as a NaN on every platform; narrowing one loses nothing anyway. An
 * infinity and a negative zero convert exactly and keep the 8-byte path.
 *
 * The double is volatile so the narrowing happens to a real 64-bit location: on
 * an x87 build without it the compiler may keep the value in an 80-bit register
 * and compare it against itself, which is always equal and would answer no. */
static int sc_nv_needs_str(NV nv) {
    volatile double dv;
    /* NVgf is a bare "g" on a -Duselongdouble build whose Configure found no
     * long double format, and then there is no way to print the NV at all:
     * "%g" would read a double out of a long double argument. Narrowing is
     * wrong, garbage digits are worse, so such a build keeps the 8-byte form.
     * Perl's own sv.c carries a FIXME for the same hole. Folded at compile
     * time; every build anyone smokes has the format. */
    if (sizeof(NVgf) == 2) return 0;
    if (nv != nv) return 0;
    dv = (double)nv;
    return (NV)dv != nv;
}

/* "%.21Lg" or "%.36Qg", whichever this build is. NV_DIG is a float.h value and
 * not a token the preprocessor can paste into a literal, so the precision is
 * printed in; THIS format has no float conversion of its own, which is what
 * keeps it off quadmath_snprintf's one-argument path. */
static void sc_nv_fmt(char *fmt, STRLEN cap) {
    my_snprintf(fmt, cap, "%s%d%s", "%.", (int)(NV_DIG + 3), NVgf);
}

/* Whatever the locale wrote for a radix becomes a single '.'. In the C locale,
 * which is where perl keeps LC_NUMERIC unless "use locale" is in effect, there
 * is nothing to do. A radix is more than one byte in some locales, so the run
 * is replaced and not the byte, and %g of a finite number has at most one.
 * Returns the length, which the replacement can shorten. */
static int sc_nv_radix(char *s, int n) {
    int i, j = 0;
    for (i = 0; i < n; i++) {
        char c = s[i];
        if (isDIGIT(c) || c == '-' || c == '+' || c == 'e' || c == 'E') continue;
        for (j = i + 1; j < n; j++) {
            c = s[j];
            if (isDIGIT(c) || c == '-' || c == '+' || c == 'e' || c == 'E') break;
        }
        s[i] = '.';
        if (j > i + 1) {
            Move(s + j, s + i + 1, n - j, char);
            n -= j - i - 1;
        }
        break;
    }
    s[n] = '\0';
    return n;
}

#else

#define sc_nv_needs_str(nv) (0)

#endif

/* The parser named directly, because Atof is not one below 5.30 (above). Where
 * a build has no wide parser Atof is still all there is, and it is at least as
 * wide as the NV - a bare strtod there would narrow, which is the bug 0.02 was
 * written to fix. Reached on a double perl too, reading a wide perl's stream. */
#if defined(USE_QUADMATH)
#  define SC_NV_FROM_STR(s) strtoflt128((s), (char **)NULL)
#elif defined(USE_LONG_DOUBLE) && defined(HAS_STRTOLD)
#  define SC_NV_FROM_STR(s) strtold((s), (char **)NULL)
#elif !SC_NV_WIDE && defined(HAS_STRTOD)
#  define SC_NV_FROM_STR(s) strtod((s), (char **)NULL)
#else
#  define SC_NV_FROM_STR(s) Atof(s)
#endif

/* ============================================================================
 * the encoder
 * ==========================================================================*/

typedef struct {
    SV     *sv;        /* tracked because its refcount is above one          */
    STRLEN  off;       /* the tag a REFP or ALIAS names                       */
    int     isref;     /* entered as a referent (under a REF tag) or as a slot */
} sc_seen;

/* ---- everything the encoder allocates is a mortal ----------------------------
 *
 * The output is built INSIDE the SV that will be returned, so there is no
 * private buffer and no copy at the end, and the seen table lives in the
 * body of a mortal SV. A croak anywhere then frees both at the next FREETMPS
 * with no destructor to register: measured, the ENTER/SAVEDESTRUCTOR pair, the
 * malloc and the final copy were most of the 86ns it took to encode one
 * integer, against 34ns to decode it. */
/* struct_encode(..., strip_pointers => 1): a pointer object is written as
 * undef instead of refused. See sc_is_pointer_obj. */
#define SC_STRIP_POINTERS 1u

typedef struct {
    char    *buf;
    STRLEN   len;      /* bytes written, or that WOULD have been in a fixed buffer */
    STRLEN   cap;
    SV      *bufsv;    /* the SV `buf` points into, NULL for a fixed buffer  */
    int      fixed;    /* encode_to: never grow, keep counting past cap      */
    U32      flags;    /* SC_STRIP_POINTERS                                  */
    sc_seen *seen;     /* open addressing keyed on the SV's address          */
    STRLEN   nseen;
    STRLEN   seen_cap; /* a power of two, 0 until the first shared SV        */
    int      depth;
} sc_enc;

/* Room for n more bytes. In a fixed buffer the length keeps counting past the
 * capacity so the caller learns what would have fit, and nothing is written
 * once it is exceeded. */
static void sc_enc_grow(pTHX_ sc_enc *e, STRLEN n) {
    STRLEN want = e->len + n;
    if (want <= e->cap || e->fixed) return;
    if (!e->bufsv) {
        /* Outgrowing the stack buffer: the first and usually only allocation,
         * a mortal so a croak from here on frees it. */
        e->bufsv = sv_2mortal(newSV(want * 2 + 1));
        SvPOK_only(e->bufsv);
        memcpy(SvPVX(e->bufsv), e->buf, e->len);
        e->buf = SvPVX(e->bufsv);
    }
    else {
        e->buf = SvGROW(e->bufsv, want * 2 + 1);
    }
    e->cap = SvLEN(e->bufsv) - 1;
}

/* Below this the encoder allocates nothing at all until the one SV it
 * returns. Every fixture in the benchmark fits it. */
#define SC_ENC_STACK 512

#define SC_PUT(e, c)                                              \
    do {                                                          \
        sc_enc_grow(aTHX_ (e), 1);                                \
        if ((e)->len < (e)->cap) (e)->buf[(e)->len] = (char)(c);  \
        (e)->len++;                                               \
    } while (0)

static void sc_enc_bytes(pTHX_ sc_enc *e, const char *p, STRLEN n) {
    sc_enc_grow(aTHX_ e, n);
    if (e->len + n <= e->cap) memcpy(e->buf + e->len, p, n);
    else if (e->len < e->cap) memcpy(e->buf + e->len, p, e->cap - e->len);
    e->len += n;
}

static void sc_enc_varint(pTHX_ sc_enc *e, UV v) {
    while (v >= 0x80) { SC_PUT(e, (unsigned char)(v | 0x80)); v >>= 7; }
    SC_PUT(e, (unsigned char)v);
}

/* A key or a class name: one varint of (len << 1 | utf8), then the bytes. */
static void sc_enc_key(pTHX_ sc_enc *e, const char *p, STRLEN n, int utf8) {
    sc_enc_varint(aTHX_ e, ((UV)n << 1) | (utf8 ? 1u : 0u));
    sc_enc_bytes(aTHX_ e, p, n);
}

static void sc_enc_str(pTHX_ sc_enc *e, const char *p, STRLEN n, int utf8) {
    if (n <= SC_SHORT_MAX) {
        SC_PUT(e, (utf8 ? SC_T_SHORT_UTF8 : SC_T_SHORT_BYTES) | (unsigned char)n);
    }
    else {
        SC_PUT(e, utf8 ? SC_T_UTF8 : SC_T_BYTES);
        sc_enc_varint(aTHX_ e, (UV)n);
    }
    sc_enc_bytes(aTHX_ e, p, n);
}

/* ---- the seen table --------------------------------------------------------
 *
 * Open addressing on the address, mixed so consecutive arena slots do not all
 * land in one run. Consulted only for an SV whose refcount is above one, so on
 * most encodes it is never even allocated. */
static UV sc_addr_mix(const SV *sv) {
    UV h = PTR2UV(sv) >> 4;
    h ^= h >> 17; h *= (UV)0x9E3779B1u; h ^= h >> 13;
    return h;
}

static sc_seen *sc_seen_find(sc_enc *e, const SV *sv) {
    UV i, mask;
    if (!e->seen_cap) return NULL;
    mask = e->seen_cap - 1;
    for (i = sc_addr_mix(sv) & mask; e->seen[i].sv; i = (i + 1) & mask)
        if (e->seen[i].sv == sv) return &e->seen[i];
    return NULL;
}

static void sc_seen_put(pTHX_ sc_enc *e, SV *sv, STRLEN off, int isref);

/* The table's storage is the body of a mortal SV, so a croak frees it. The old
 * table is simply left to its own mortality when a bigger one replaces it. */
static void sc_seen_grow(pTHX_ sc_enc *e) {
    sc_seen *old = e->seen;
    STRLEN   oldcap = e->seen_cap, i;
    SV      *holder;
    e->seen_cap = oldcap ? oldcap * 2 : 8;
    holder  = sv_2mortal(newSV(e->seen_cap * sizeof(sc_seen)));
    e->seen = (sc_seen *)SvPVX(holder);
    memset(e->seen, 0, e->seen_cap * sizeof(sc_seen));
    e->nseen = 0;
    for (i = 0; i < oldcap; i++)
        if (old[i].sv) sc_seen_put(aTHX_ e, old[i].sv, old[i].off, old[i].isref);
}

static void sc_seen_put(pTHX_ sc_enc *e, SV *sv, STRLEN off, int isref) {
    UV i, mask;
    if ((e->nseen + 1) * 2 > e->seen_cap) sc_seen_grow(aTHX_ e);
    mask = e->seen_cap - 1;
    for (i = sc_addr_mix(sv) & mask; e->seen[i].sv; i = (i + 1) & mask) ;
    e->seen[i].sv    = sv;
    e->seen[i].off   = off;
    e->seen[i].isref = isref;
    e->nseen++;
}

/* Mark the earlier tag as referenced again. It is inside the buffer already,
 * so this works in a fixed buffer too - unless that tag fell past the
 * capacity, in which case nothing was written there and the caller is
 * refusing the whole value anyway. */
static void sc_enc_track(sc_enc *e, STRLEN off) {
    if (off < e->cap) e->buf[off] = (char)((unsigned char)e->buf[off] | SC_TRACK);
}

static void sc_enc_croak_type(pTHX_ const char *what) {
    croak("Struct::Codec: cannot encode a %s", what);
}

static int sc_is_regexp(pTHX_ SV *sv) {
#if SC_HAVE_REGEXP
    if (SvTYPE(sv) == SVt_REGEXP) return 1;
#endif
    return SvOBJECT(sv) && HvNAME(SvSTASH(sv)) && strEQ(HvNAME(SvSTASH(sv)), "Regexp");
}

/* The magic that ties a container or a scalar, or NULL. Found by kind rather
 * than by SvRMAGICAL alone, because a scalar with other magic is not tied. */
static MAGIC *sc_tie_magic(pTHX_ SV *sv) {
    if (!SvRMAGICAL(sv)) return NULL;
    if (SvTYPE(sv) == SVt_PVAV || SvTYPE(sv) == SVt_PVHV)
        return mg_find(sv, PERL_MAGIC_tied);
    return mg_find(sv, PERL_MAGIC_tiedscalar);
}

/* An object whose whole state is one integer, in a class whose DESTROY is an
 * XSUB, is the shape the typemap gives a handle: T_PTROBJ stores the address
 * of a C struct as the IV and the generated DESTROY frees it. Compress::Raw::
 * Zlib's streams and XML::LibXML's nodes are this shape. The SV itself says
 * nothing, which is why Storable carries one happily unless the class
 * installs a STORABLE_freeze that croaks; a faithful copy in another process
 * hands its DESTROY an address that was never allocated there, and a copy in
 * the same process frees the original's struct under it. So the encoder
 * refuses the shape (or, asked to, writes undef) and the decoder refuses to
 * bless it, and no DESTROY ever sees the integer.
 *
 * The DESTROY must be XS: a blessed integer with a DESTROY written in Perl is
 * an ordinary object - Tie::StdScalar's tie object is exactly that, and its
 * DESTROY only undefs the scalar - and Perl code cannot free C memory, so a
 * Perl DESTROY that does so calls an XSUB to do it, which is the one shape
 * this cannot see. A class without a DESTROY frees nothing and is carried as
 * before; a string, a float, a reference or a container in any class is
 * data, not an address. The DESTROY is looked up through the class's
 * inheritance, as perl will look it up. */
#ifndef CvISXSUB
#  define CvISXSUB(cv) (CvXSUB(cv) != NULL)
#endif

/* An address that has been printed still has a public POK on perls before
 * 5.36, where caching the digits set it, so POK alone cannot say "string".
 * The PV that spells the integer back is the cached spelling and says nothing
 * the IV did not; any other PV is a string, and a string is data. The cost is
 * one ambiguous shape on those perls: a blessed "7" that has also been used
 * as a number carries the same flags and the same bytes as a printed 7, and
 * is refused with it. */
static int sc_pv_spells_the_iv(pTHX_ SV *sv) {
    char buf[64];
    int blen;
    PERL_UNUSED_CONTEXT;
    blen = SvIsUV(sv) ? my_snprintf(buf, sizeof(buf), "%" UVuf, SvUVX(sv))
                          : my_snprintf(buf, sizeof(buf), "%" IVdf, SvIVX(sv));
    return blen > 0 && (STRLEN)blen == SvCUR(sv)
           && memEQ(SvPVX_const(sv), buf, (STRLEN)blen);
}

static int sc_is_pointer_obj(pTHX_ SV *sv, HV *stash) {
    GV *gv;
    if (SvTYPE(sv) >= SVt_PVAV || SvTYPE(sv) == SVt_PVGV) return 0;
    if (!SvIOK(sv) || SvNOK(sv) || SvROK(sv)) return 0;
    if (SvPOK(sv) && !sc_pv_spells_the_iv(aTHX_ sv)) return 0;
    gv = gv_fetchmeth(stash, "DESTROY", 7, 0);
    return gv && GvCV(gv) && CvISXSUB(GvCV(gv)) ? 1 : 0;
}

static void sc_enc_value(pTHX_ sc_enc *e, SV *sv);
static void sc_enc_body(pTHX_ sc_enc *e, SV *sv);

/* ---- the kinds that are not data -------------------------------------------------
 *
 * Each is written from what perl already knows about it, and none of them is
 * read through: a tied hash is never iterated (that would call FETCH), a
 * regexp is its pattern and flags rather than a match, a sub is its name or
 * its source. */

/* The tie object, as a value. Perl allows a tie with no object only through
 * XS, and there is nothing to write for one. */
static void sc_enc_tie(pTHX_ sc_enc *e, MAGIC *mg, unsigned char tag,
                       const char *what)
{
    if (!mg->mg_obj) {
        croak("Struct::Codec: cannot encode a tied %s with no object", what);
    }
    SC_PUT(e, tag);
    sc_enc_value(aTHX_ e, mg->mg_obj);
}

#if SC_HAVE_REGEXP
/* The flag letters as re::regexp_pattern spells them: the modifiers in the
 * order "msixxnp", then the character set. Read back by sc_dec_regexp, which
 * accepts exactly this alphabet and nothing else. */
static STRLEN sc_rx_flags(REGEXP *rx, char *out) {
    U32 fl = RX_EXTFLAGS(rx);
    STRLEN n = 0;
    if (fl & RXf_PMf_MULTILINE)  out[n++] = 'm';
    if (fl & RXf_PMf_SINGLELINE) out[n++] = 's';
    if (fl & RXf_PMf_FOLD)       out[n++] = 'i';
    if (fl & RXf_PMf_EXTENDED)   out[n++] = 'x';
#  ifdef RXf_PMf_EXTENDED_MORE
    if (fl & RXf_PMf_EXTENDED_MORE) out[n++] = 'x';
#  endif
#  ifdef RXf_PMf_NOCAPTURE
    if (fl & RXf_PMf_NOCAPTURE)  out[n++] = 'n';
#  endif
    if (fl & RXf_PMf_KEEPCOPY)   out[n++] = 'p';
#  if SC_HAVE_CHARSET
    switch (get_regex_charset(fl)) {
    case REGEX_LOCALE_CHARSET:           out[n++] = 'l'; break;
    case REGEX_UNICODE_CHARSET:          out[n++] = 'u'; break;
    case REGEX_ASCII_RESTRICTED_CHARSET: out[n++] = 'a'; break;
    case REGEX_ASCII_MORE_RESTRICTED_CHARSET:
        out[n++] = 'a'; out[n++] = 'a'; break;
    default: break;
    }
#  endif
    return n;
}
#endif

static void sc_enc_regexp(pTHX_ sc_enc *e, SV *rv) {
#if SC_HAVE_REGEXP
    REGEXP *rx = SvRX(rv);
    char flags[16];
    STRLEN nf;
    if (!rx) sc_enc_croak_type(aTHX_ "Regexp with no pattern");
    nf = sc_rx_flags(rx, flags);
    SC_PUT(e, SC_T_REGEXP);
    sc_enc_key(aTHX_ e, RX_PRECOMP(rx), (STRLEN)RX_PRELEN(rx), RX_UTF8(rx) ? 1 : 0);
    sc_enc_key(aTHX_ e, flags, nf, 0);
#else
    (void)e; (void)rv;
    croak("Struct::Codec: a regexp needs perl 5.12 or later");
#endif
}

/* "Package::name" for a glob, into a mortal; the flag says whether either
 * half is UTF-8. NULL for a glob with no stash, which is one perl made for
 * its own use and nobody else can find. */
static SV *sc_gv_name(pTHX_ GV *gv, int *utf8) {
    HV *stash = GvSTASH(gv);
    SV *name;
    if (!stash || !HvNAME(stash) || !GvNAME(gv)) return NULL;
    name = sv_2mortal(newSVpvn(HvNAME(stash), (STRLEN)HvNAMELEN_get(stash)));
    if (HvNAMEUTF8(stash)) SvUTF8_on(name);
    sv_catpvs(name, "::");
    {
        SV *tail = sv_2mortal(newSVpvn(GvNAME(gv), (STRLEN)GvNAMELEN(gv)));
#ifdef GvNAMEUTF8
        if (GvNAMEUTF8(gv)) SvUTF8_on(tail);
#endif
        sv_catsv(name, tail);
    }
    *utf8 = SvUTF8(name) ? 1 : 0;
    return name;
}

/* A named sub is its name. An anonymous one is its source, from B::Deparse,
 * which is slow and is the only way there is; one that captured a lexical is
 * refused, because its source without the lexical is a different sub. The
 * deparser's temporaries live inside their own ENTER/SAVETMPS, and the source
 * is copied out before that scope closes, because the encoder's own mortals
 * (the buffer, the seen table) were made before it and must not be swept. */
static void sc_enc_code(pTHX_ sc_enc *e, CV *cv) {
    GV *gv = CvGV(cv);
    SV *src;

    if (!CvANON(cv) && gv) {
        int utf8 = 0;
        SV *name = sc_gv_name(aTHX_ gv, &utf8);
        if (name) {
            SC_PUT(e, SC_T_CODE_NAME);
            sc_enc_key(aTHX_ e, SvPVX(name), SvCUR(name), utf8);
            return;
        }
    }
    if (CvISXSUB(cv)) sc_enc_croak_type(aTHX_ "anonymous XSUB");
    if (CvCLONED(cv)) croak("Struct::Codec: cannot encode a closure: "
                            "it captured a lexical that would not come with it");

    {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("B::Deparse"), NULL);
        /* load_module runs perl (B::Deparse's own compilation), which can
         * GROW and so reallocate the argument stack. dSP was taken before it,
         * so SP may now dangle into the freed old stack; writing args through
         * it corrupts the heap. It only bites when the load happens to trigger
         * a realloc, which depends on how deep the stack already is - hence a
         * crash from inside a test and not from a bare one-line encode. */
        SPAGAIN;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("B::Deparse")));
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        if (count != 1) croak("Struct::Codec: B::Deparse->new returned nothing");
        {
            SV *deparser = POPs;
            PUSHMARK(SP);
            XPUSHs(deparser);
            XPUSHs(sv_2mortal(newRV_inc((SV *)cv)));
            PUTBACK;
            count = call_method("coderef2text", G_SCALAR);
            SPAGAIN;
            if (count != 1) croak("Struct::Codec: B::Deparse returned nothing");
            src = newSVsv(POPs);            /* owned: it outlives the scope */
            PUTBACK;
        }
        FREETMPS;
        LEAVE;
        sv_2mortal(src);
    }
    SC_PUT(e, SC_T_CODE_SRC);
    sc_enc_key(aTHX_ e, SvPVX(src), SvCUR(src), SvUTF8(src) ? 1 : 0);
}

/* A glob that a name finds again is its name. One that no name finds - a
 * lexical filehandle, a gensym - is its descriptor, if it has one open. The
 * test is on the GP and not the SV: `$x = *STDOUT` makes a second SV that
 * shares the first's GP, and by name is what it means. */
static void sc_enc_glob(pTHX_ sc_enc *e, GV *gv) {
    int utf8 = 0;
    SV *name = sc_gv_name(aTHX_ gv, &utf8);
    IO *io;
    if (name) {
        GV *found = gv_fetchpvn_flags(SvPVX(name), SvCUR(name),
                                      utf8 ? SVf_UTF8 : 0, SVt_PVGV);
        if (found && GvGP(found) == GvGP(gv)) {
            SC_PUT(e, SC_T_GLOB);
            sc_enc_key(aTHX_ e, SvPVX(name), SvCUR(name), utf8);
            return;
        }
    }
    io = GvIO(gv);
    if (io && IoIFP(io) && PerlIO_fileno(IoIFP(io)) >= 0) {
        SC_PUT(e, SC_T_FD_GLOB);
        SC_PUT(e, IoTYPE(io));
        sc_enc_varint(aTHX_ e, (UV)PerlIO_fileno(IoIFP(io)));
        return;
    }
    sc_enc_croak_type(aTHX_ "GLOB that has no name and no open filehandle");
}

static void sc_enc_io(pTHX_ sc_enc *e, IO *io) {
    if (!IoIFP(io) || PerlIO_fileno(IoIFP(io)) < 0)
        sc_enc_croak_type(aTHX_ "IO that is not open");
    SC_PUT(e, SC_T_FD_IO);
    SC_PUT(e, IoTYPE(io));
    sc_enc_varint(aTHX_ e, (UV)PerlIO_fileno(IoIFP(io)));
}

/* A format lives in a glob's FORMAT slot and has no other identity. */
static void sc_enc_format(pTHX_ sc_enc *e, CV *fm) {
    GV *gv = CvGV(fm);
    int utf8 = 0;
    SV *name = gv ? sc_gv_name(aTHX_ gv, &utf8) : NULL;
    if (!name) sc_enc_croak_type(aTHX_ "FORMAT with no name");
    SC_PUT(e, SC_T_FORMAT);
    sc_enc_key(aTHX_ e, SvPVX(name), SvCUR(name), utf8);
}

/* The thing behind a reference: an array, a hash, a scalar, or one of the
 * kinds that are not data. The referent has already been entered in the seen
 * table by the caller, so a scalar referent goes straight to its body and is
 * not looked up again. */
static void sc_enc_referent(pTHX_ sc_enc *e, SV *rv) {
    MAGIC *tie;
    switch (SvTYPE(rv)) {
    case SVt_PVAV: {
        AV *av = (AV *)rv;
        SSize_t n, i;
        if ((tie = sc_tie_magic(aTHX_ rv))) {
            sc_enc_tie(aTHX_ e, tie, SC_T_TIED_ARRAY, "ARRAY");
            return;
        }
        n = av_len(av) + 1;
        SC_PUT(e, SC_T_ARRAY);
        sc_enc_varint(aTHX_ e, (UV)n);
        for (i = 0; i < n; i++) {
            SV **slot = av_fetch(av, i, 0);
            sc_enc_value(aTHX_ e, slot ? *slot : &PL_sv_undef);
        }
        return;
    }
    case SVt_PVHV: {
        HV *hv = (HV *)rv;
        HE *he;
        if ((tie = sc_tie_magic(aTHX_ rv))) {
            sc_enc_tie(aTHX_ e, tie, SC_T_TIED_HASH, "HASH");
            return;
        }
        /* HvUSEDKEYS is the count of REAL keys. A restricted hash keeps a
         * placeholder for each locked-but-absent key, and hv_iterinit counts
         * those while hv_iternext skips them, so a count taken from it is
         * larger than what follows and the decoder finds the stream short. */
        SC_PUT(e, SC_T_HASH);
        hv_iterinit(hv);
        sc_enc_varint(aTHX_ e, (UV)HvUSEDKEYS(hv));
        while ((he = hv_iternext(hv))) {
            STRLEN kl;
            const char *k = HePV(he, kl);
            sc_enc_key(aTHX_ e, k, kl, HeUTF8(he) ? 1 : 0);
            sc_enc_value(aTHX_ e, HeVAL(he));
        }
        return;
    }
    case SVt_PVCV: sc_enc_code(aTHX_ e, (CV *)rv);   return;
    case SVt_PVGV: sc_enc_glob(aTHX_ e, (GV *)rv);   return;
    case SVt_PVIO: sc_enc_io(aTHX_ e, (IO *)rv);     return;
    case SVt_PVFM: sc_enc_format(aTHX_ e, (CV *)rv); return;
    default:
        if (sc_is_regexp(aTHX_ rv)) { sc_enc_regexp(aTHX_ e, rv); return; }
        sc_enc_body(aTHX_ e, rv);
        return;
    }
}

/* The value itself, after the slot has been checked for sharing. */
static void sc_enc_body(pTHX_ sc_enc *e, SV *sv) {
    MAGIC *tie;

    /* Before any magic is invoked: reading a tied scalar would call FETCH,
     * and what is written is the tie, not what FETCH would have said. */
    if (SvTYPE(sv) != SVt_PVGV && (tie = sc_tie_magic(aTHX_ sv))) {
        sc_enc_tie(aTHX_ e, tie, SC_T_TIED_SCALAR, "scalar");
        return;
    }
    /* A glob copied into a slot, as `$x = *STDOUT` does. Not a reference, and
     * not a string either, though it stringifies as one. */
    if (SvTYPE(sv) == SVt_PVGV && isGV_with_GP(sv)) {
        sc_enc_glob(aTHX_ e, (GV *)sv);
        return;
    }

    SvGETMAGIC(sv);

    if (SvROK(sv)) {
        SV *rv = SvRV(sv);
        STRLEN tag_off = e->len;
        sc_seen *prev = sc_seen_find(e, rv);
        if (prev) {
            sc_enc_track(e, prev->off);
            SC_PUT(e, SC_T_REFP);
            sc_enc_varint(aTHX_ e, (UV)prev->off);
            return;
        }
        /* qr// is blessed into Regexp, and that class is implied by the tag;
         * a regexp reblessed elsewhere keeps its class through OBJECT. */
        if (SvOBJECT(rv)
            && !(sc_is_regexp(aTHX_ rv) && HvNAME(SvSTASH(rv))
                 && strEQ(HvNAME(SvSTASH(rv)), "Regexp"))) {
            HV *stash = SvSTASH(rv);
            const char *nm = HvNAME(stash);
            if (!nm) sc_enc_croak_type(aTHX_ "reference blessed into an anonymous stash");
            if (sc_is_pointer_obj(aTHX_ rv, stash)) {
                /* Not entered in the seen table, so a second reference to it
                 * arrives here again and is dropped again. */
                if (e->flags & SC_STRIP_POINTERS) { SC_PUT(e, SC_T_UNDEF); return; }
                croak("Struct::Codec: cannot encode a %.*s object that holds a pointer"
                      " (strip_pointers => 1 drops it)",
                      (int)HvNAMELEN_get(stash), nm);
            }
            SC_PUT(e, SC_T_OBJECT);
            sc_enc_key(aTHX_ e, nm, (STRLEN)HvNAMELEN_get(stash),
                       HvNAMEUTF8(stash) ? 1 : 0);
        }
        else {
            SC_PUT(e, SC_T_REF);
        }
        /* The referent is what a second reference shares, so it is what is
         * tracked, under the REF tag's offset. One with refcount 1 cannot be
         * shared and is not entered. */
        if (SvREFCNT(rv) > 1 && !SvIMMORTAL(rv)) sc_seen_put(aTHX_ e, rv, tag_off, 1);
        sc_enc_referent(aTHX_ e, rv);
        return;
    }

    /* The PUBLIC flags decide the kind, in the order string, integer, float.
     * A private flag alone is a cached conversion that may be lossy: Storable
     * leaves pIOK on the NV 1.5 after freezing it, and an encoder that read
     * IOKp there would write the integer 1. A public POK on a number that was
     * stringified is not set, so 5 stays 5 after being printed, and "007"
     * stays "007" because its POK is public. Only when no public flag is set
     * do the private ones get a say, in the same order. A boolean is checked
     * first because PL_sv_yes is also POK and IOK. */
#if SC_HAVE_BOOL
    if (SvIsBOOL(sv)) {
        SC_PUT(e, SvTRUE(sv) ? SC_T_TRUE : SC_T_FALSE);
    }
    else
#endif
    if (SvPOK(sv) || (!SvIOK(sv) && !SvNOK(sv) && SvPOKp(sv))) {
        STRLEN n;
        const char *p = SvPV_nomg(sv, n);
        sc_enc_str(aTHX_ e, p, n, SvUTF8(sv) ? 1 : 0);
    }
    else if (SvIOK(sv) || (!SvNOK(sv) && SvIOKp(sv))) {
        if (SvIsUV(sv)) {
            UV u = SvUVX(sv);
            if (u <= (UV)SC_SMALL_MAX) SC_PUT(e, SC_T_SMALL_POS | (unsigned char)u);
            else { SC_PUT(e, SC_T_UV); sc_enc_varint(aTHX_ e, u); }
        }
        else {
            IV i = SvIVX(sv);
            if (i >= 0 && i <= SC_SMALL_MAX) SC_PUT(e, SC_T_SMALL_POS | (unsigned char)i);
            else if (i < 0 && i >= SC_SMALL_MIN) SC_PUT(e, SC_T_SMALL_NEG | (unsigned char)(i + 16));
            else if (i >= 0) { SC_PUT(e, SC_T_UV); sc_enc_varint(aTHX_ e, (UV)i); }
            else { SC_PUT(e, SC_T_NEG); sc_enc_varint(aTHX_ e, (UV)(-(i + 1))); }
        }
    }
    else if (SvNOK(sv) || SvNOKp(sv)) {
        NV nv = SvNVX(sv);
#if SC_NV_WIDE
        if (sc_nv_needs_str(nv)) {
            /* buf is an array and not a pointer on purpose: it is sized for the
             * widest NV plus a sign, a point, an exponent and the NUL. */
            char buf[SC_NV_STR_MAX + 1];
            char fmt[16];
            int blen;
            sc_nv_fmt(fmt, sizeof(fmt));
            blen = my_snprintf(buf, sizeof(buf), fmt, nv);
            if (blen > 0 && blen <= SC_NV_STR_MAX) {
                blen = sc_nv_radix(buf, blen);
                SC_PUT(e, SC_T_NV_STR);
                sc_enc_varint(aTHX_ e, (UV)blen);
                sc_enc_bytes(aTHX_ e, buf, (STRLEN)blen);
                return;
            }
            /* Unreachable at any NV width perl builds on: 36 digits is 44 bytes
             * with the sign, the point and a five-byte exponent. A buffer that
             * really did not fit never arrives here anyway - my_snprintf croaks
             * "my_snprintf buffer overflow" rather than returning the length it
             * wanted - so this covers a formatter that failed and returned
             * negative, and the 8-byte form below is still a valid stream. */
        }
#endif
        {
            unsigned char raw[SC_NV_BYTES];
            sc_nv_to_wire(nv, raw);
            SC_PUT(e, SC_T_NV);
            sc_enc_bytes(aTHX_ e, (const char *)raw, SC_NV_BYTES);
        }
    }
    else {
        SC_PUT(e, SC_T_UNDEF);
    }
}

/* A slot value: something in an array element, a hash value, or the root. */
static void sc_enc_value(pTHX_ sc_enc *e, SV *sv) {
    if (++e->depth > SC_DEPTH_MAX)
        croak("Struct::Codec: structure deeper than %d", SC_DEPTH_MAX);

    /* A scalar that can be met twice. A reference SV is not entered as a
     * scalar - see the header - and an immortal never is. */
    if (SvREFCNT(sv) > 1 && !SvIMMORTAL(sv) && !SvROK(sv)) {
        sc_seen *prev = sc_seen_find(e, sv);
        if (prev) {
            sc_enc_track(e, prev->off);
            SC_PUT(e, SC_T_ALIAS);
            sc_enc_varint(aTHX_ e, (UV)prev->off);
            e->depth--;
            return;
        }
        sc_seen_put(aTHX_ e, sv, e->len, 0);
    }

    sc_enc_body(aTHX_ e, sv);
    e->depth--;
}

static void sc_enc_run(pTHX_ sc_enc *e, SV *value) {
    SC_PUT(e, SC_MAGIC);
    SC_PUT(e, SC_VERSION);
    SC_PUT(e, SC_FLOAT);
    sc_enc_value(aTHX_ e, value);
}

/* An owned byte SV with a refcount of one.
 *
 * A small value is encoded on the stack and copied once into an SV of exactly
 * its size, with no allocation before that and nothing to free on a croak. A
 * large one moves into a mortal SV when it outgrows the stack; that SV is
 * then handed back with the caller's reference added, and the pending mortal
 * decrement belongs to the caller's frame as it does for any XSUB's return. */
static SV *sc_encode_flags(pTHX_ SV *value, U32 flags) {
    sc_enc e;
    char stack[SC_ENC_STACK];
    memset(&e, 0, sizeof e);
    e.buf = stack;
    e.cap = sizeof stack;
    e.flags = flags;
    sc_enc_run(aTHX_ &e, value);
    if (!e.bufsv) return newSVpvn(e.buf, e.len);
    SvCUR_set(e.bufsv, e.len);
    e.buf[e.len] = '\0';
    return SvREFCNT_inc_simple_NN(e.bufsv);
}

/* The ABI's encode: no options, so a pointer object is a croak. */
static SV *sc_encode(pTHX_ SV *value) {
    return sc_encode_flags(aTHX_ value, 0);
}

/* Into caller memory. See sc_abi.h for the contract. */
static STRLEN sc_encode_to(pTHX_ SV *value, char *buf, STRLEN cap, STRLEN *need) {
    sc_enc e;
    memset(&e, 0, sizeof e);
    e.buf = buf; e.cap = cap; e.fixed = 1;
    sc_enc_run(aTHX_ &e, value);
    if (need) *need = e.len;
    return e.len <= cap ? e.len : 0;
}

/* ============================================================================
 * the decoder
 * ==========================================================================*/

typedef struct {
    STRLEN off;
    SV    *sv;         /* borrowed: it is already attached to the structure */
    int    isref;      /* registered from a REF/OBJECT tag: sv is the RV     */
} sc_slot;

typedef struct {
    const unsigned char *base, *p, *end;
    sc_slot *tab;      /* TRACKed tags in offset order, which is decode order;
                        * the body of a mortal SV, so a croak frees it        */
    STRLEN   ntab, tabcap;
    int      depth;
} sc_dec;

#define SC_OFF(d) ((UV)((d)->p - (d)->base))

static void sc_dec_croak(pTHX_ sc_dec *d, const char *why) {
    croak("Struct::Codec: %s at byte %" UVuf, why, SC_OFF(d));
}

/* rule 1: every read is bounds-checked before it happens */
#define SC_NEED(d, n)                                                      \
    do {                                                                   \
        if ((UV)((d)->end - (d)->p) < (UV)(n))                             \
            sc_dec_croak(aTHX_ (d), "truncated input");                    \
    } while (0)

/* rule 2: an integer wider than a UV is corrupt, not big */
static UV sc_dec_varint(pTHX_ sc_dec *d) {
    UV v = 0;
    int shift = 0, i;
    for (i = 0; i < SC_VARINT_MAX; i++) {
        unsigned char c;
        SC_NEED(d, 1);
        c = *d->p++;
        if (shift >= SC_UV_BITS
            || (shift > SC_UV_BITS - 7 && ((UV)(c & 0x7F) >> (SC_UV_BITS - shift))))
            sc_dec_croak(aTHX_ d, "integer too wide");
        v |= (UV)(c & 0x7F) << shift;
        if (!(c & 0x80)) return v;
        shift += 7;
    }
    sc_dec_croak(aTHX_ d, "integer too long");
    return 0;
}

/* rule 7: only an offset that was registered, which means already decoded */
static sc_slot *sc_dec_lookup(pTHX_ sc_dec *d, UV off) {
    STRLEN lo = 0, hi = d->ntab;
    while (lo < hi) {
        STRLEN mid = lo + (hi - lo) / 2;
        if (d->tab[mid].off < off) lo = mid + 1;
        else hi = mid;
    }
    if (lo < d->ntab && d->tab[lo].off == off) return &d->tab[lo];
    sc_dec_croak(aTHX_ d, "reference to a value that was not tracked");
    return NULL;
}

static void sc_dec_register(pTHX_ sc_dec *d, STRLEN off, SV *sv, int isref) {
    if (d->ntab == d->tabcap) {
        sc_slot *old = d->tab;
        SV *holder;
        d->tabcap = d->tabcap ? d->tabcap * 2 : 16;
        holder = sv_2mortal(newSV(d->tabcap * sizeof(sc_slot)));
        d->tab = (sc_slot *)SvPVX(holder);
        if (old) memcpy(d->tab, old, d->ntab * sizeof(sc_slot));
    }
    d->tab[d->ntab].off   = off;
    d->tab[d->ntab].sv    = sv;
    d->tab[d->ntab].isref = isref;
    d->ntab++;
}

/* A key or class name: *p points INSIDE the input and the caller copies.
 *
 * rule 4: utf8 is validated, and only at a non-zero length. At zero the flag is
 * DROPPED and not merely left unchecked, because a zero length and a utf8 flag
 * together are a pair perl's string routines read as "no length given, find the
 * end yourself". is_utf8_string takes strlen there; hv_common is worse. It
 * sizes the buffer for the utf8-to-bytes downgrade from the length IT WAS GIVEN
 * - one byte for a zero-length key - and then copies the run utf8_to_bytes
 * measures for itself, which starts at the key and ends at the first byte that
 * cannot continue the string. Those bytes are the rest of the stream: a key of
 * length zero with the flag set wrote nine bytes into a one-byte allocation.
 * Nothing in a plain build says a word. The quadmath smoker aborted inside
 * free(), and under ASan it is a heap-buffer-overflow in memcpy under
 * Perl_hv_common. The empty string is the same key with the flag or without it,
 * so dropping it loses nothing. */
static void sc_dec_key(pTHX_ sc_dec *d, const char **p, STRLEN *n, int *utf8) {
    UV v = sc_dec_varint(aTHX_ d);
    *utf8 = (int)(v & 1);
    v >>= 1;
    SC_NEED(d, v);
    *p = (const char *)d->p;
    *n = (STRLEN)v;
    if (!v) *utf8 = 0;
    else if (*utf8 && !is_utf8_string(d->p, (STRLEN)v))
        sc_dec_croak(aTHX_ d, "malformed UTF-8");
    d->p += v;
}

static void sc_dec_str_into(pTHX_ sc_dec *d, SV *into, STRLEN n, int utf8) {
    SC_NEED(d, n);
    if (utf8 && n && !is_utf8_string(d->p, n))
        sc_dec_croak(aTHX_ d, "malformed UTF-8");
    sv_setpvn(into, (const char *)d->p, n);
    if (utf8) SvUTF8_on(into);
    d->p += n;
}

static SV *sc_dec_value(pTHX_ sc_dec *d, SV *into);

/* A key as a mortal SV, flag and all: the spelling a name lookup wants. */
static SV *sc_dec_key_sv(pTHX_ sc_dec *d) {
    const char *p; STRLEN n; int utf8;
    SV *sv;
    sc_dec_key(aTHX_ d, &p, &n, &utf8);
    sv = sv_2mortal(newSVpvn(p, n));
    if (utf8) SvUTF8_on(sv);
    return sv;
}

/* ---- the kinds that are not data ----------------------------------------------------
 *
 * Each builder reads its payload and returns an OWNED SV, complete, or croaks
 * having built nothing. The caller attaches it in one step, so a croak inside
 * a builder leaves the parent holding the undef it was given, and the rule that
 * nothing half-built is ever reachable holds without any of them being filled
 * in place. */

static SV *sc_dec_regexp(pTHX_ sc_dec *d) {
#if SC_HAVE_REGEXP
    SV *pat = sc_dec_key_sv(aTHX_ d);
    const char *f; STRLEN nf, i; int fu;
    U32 fl = 0;
    int xs = 0, as = 0, charset = 0;
    REGEXP *rx;

    /* rule 12: the flag letters are checked against the alphabet the encoder
     * writes BEFORE anything is compiled; a letter outside it is corrupt
     * input, not a request. */
    sc_dec_key(aTHX_ d, &f, &nf, &fu);
    for (i = 0; i < nf; i++) {
        switch (f[i]) {
        case 'm': fl |= RXf_PMf_MULTILINE;  break;
        case 's': fl |= RXf_PMf_SINGLELINE; break;
        case 'i': fl |= RXf_PMf_FOLD;       break;
        case 'p': fl |= RXf_PMf_KEEPCOPY;   break;
        case 'x':
            if (!xs++) { fl |= RXf_PMf_EXTENDED; break; }
#  ifdef RXf_PMf_EXTENDED_MORE
            fl |= RXf_PMf_EXTENDED_MORE; break;
#  else
            sc_dec_croak(aTHX_ d, "regexp flag /xx needs a newer perl");
#  endif
        case 'n':
#  ifdef RXf_PMf_NOCAPTURE
            fl |= RXf_PMf_NOCAPTURE; break;
#  else
            sc_dec_croak(aTHX_ d, "regexp flag /n needs a newer perl");
#  endif
#  if SC_HAVE_CHARSET
        case 'l': charset = REGEX_LOCALE_CHARSET;  break;
        case 'u': charset = REGEX_UNICODE_CHARSET; break;
        case 'a': charset = as++ ? REGEX_ASCII_MORE_RESTRICTED_CHARSET
                                 : REGEX_ASCII_RESTRICTED_CHARSET; break;
#  endif
        default:
            sc_dec_croak(aTHX_ d, "unknown regexp flag");
        }
    }
#  if SC_HAVE_CHARSET
    if (charset) set_regex_charset(&fl, (regex_charset)charset);
#  endif
    /* Compiled at runtime from a string, so a (?{ }) block is refused by the
     * regexp engine itself unless the DECODER's caller has `use re 'eval'` in
     * force - the same rule as a pattern interpolated from a variable.
     *
     * The compile runs inside Struct::Codec::_regcomp under G_EVAL, because
     * that is the one way to catch the engine's croak cleanly from C and
     * report it as this decoder reports everything else: with the byte. A
     * bare JMPENV outside an eval frame catches the jump but not before perl
     * has printed the message and begun exiting. */
    {
        dSP;
        int count;
        SV *msg = NULL;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(pat);
        XPUSHs(sv_2mortal(newSVuv((UV)fl)));
        PUTBACK;
        count = call_pv("Struct::Codec::_regcomp", G_SCALAR | G_EVAL);
        SPAGAIN;
        rx = NULL;
        if (count == 1) {
            SV *r = POPs;
            if (SvROK(r)) rx = (REGEXP *)SvREFCNT_inc_simple_NN(SvRV(r));
        }
        PUTBACK;
        if (!rx && SvTRUE(ERRSV)) {
            msg = newSVsv(ERRSV);          /* owned: it outlives the scope */
            if (SvCUR(msg) && SvPVX(msg)[SvCUR(msg) - 1] == '\n')
                SvCUR_set(msg, SvCUR(msg) - 1);
        }
        FREETMPS;
        LEAVE;
        if (msg) {
            sv_2mortal(msg);
            croak("Struct::Codec: %" SVf " at byte %" UVuf, SVfARG(msg), SC_OFF(d));
        }
    }
    if (!rx) sc_dec_croak(aTHX_ d, "regexp did not compile");
    return (SV *)rx;
#else
    (void)d;
    croak("Struct::Codec: a regexp needs perl 5.12 or later");
    return NULL;
#endif
}

/* rule 13: a name in the stream FINDS a sub or a format and never makes one.
 * A glob is the exception, because a glob that does not exist is what
 * naming it creates in perl too. */
static SV *sc_dec_code_name(pTHX_ sc_dec *d) {
    SV *name = sc_dec_key_sv(aTHX_ d);
    GV *gv;
    CV *cv;
    if (!SvCUR(name)) sc_dec_croak(aTHX_ d, "empty sub name");
    gv = gv_fetchsv(name, 0, SVt_PVCV);
    cv = gv ? GvCV(gv) : NULL;
    if (!cv)
        croak("Struct::Codec: sub %" SVf " is not defined at byte %" UVuf,
              SVfARG(name), SC_OFF(d));
    return SvREFCNT_inc_simple_NN((SV *)cv);
}

/* The one place the decoder runs code from the stream, and only when
 * $Struct::Codec::Eval allows it, which it does by default: true means eval
 * the source as `sub {...}`, false refuses,
 * a code reference means hand it the source and take the sub it returns. Its
 * scope is its own so the decoder's mortals, made before it, are not swept. */
static SV *sc_dec_code_src(pTHX_ sc_dec *d) {
    SV *src = sc_dec_key_sv(aTHX_ d);
    SV *ev  = get_sv("Struct::Codec::Eval", 0);
    SV *cv  = NULL, *msg = NULL;

    if (!ev || !SvTRUE(ev))
        sc_dec_croak(aTHX_ d, "a sub by source needs $Struct::Codec::Eval");
    {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        if (SvROK(ev) && SvTYPE(SvRV(ev)) == SVt_PVCV) {
            PUSHMARK(SP);
            XPUSHs(src);
            PUTBACK;
            count = call_sv(ev, G_SCALAR);
        }
        else {
            SV *text = sv_2mortal(newSVpvs("sub "));
            sv_catsv(text, src);
            count = eval_sv(text, G_SCALAR);
        }
        SPAGAIN;
        if (count == 1) {
            SV *r = POPs;
            if (SvROK(r) && SvTYPE(SvRV(r)) == SVt_PVCV)
                cv = SvREFCNT_inc_simple_NN(SvRV(r));
        }
        PUTBACK;
        if (!cv && SvTRUE(ERRSV)) msg = newSVsv(ERRSV);   /* owned: outlives the scope */
        FREETMPS;
        LEAVE;
    }
    if (msg) {
        sv_2mortal(msg);
        croak("Struct::Codec: %" SVf, SVfARG(msg));
    }
    if (!cv) sc_dec_croak(aTHX_ d, "the source did not produce a sub");
    return cv;
}

/* Borrowed: a glob in a stash is the stash's. */
static GV *sc_dec_glob_named(pTHX_ sc_dec *d) {
    SV *name = sc_dec_key_sv(aTHX_ d);
    GV *gv;
    if (!SvCUR(name)) sc_dec_croak(aTHX_ d, "empty glob name");
    gv = gv_fetchsv(name, GV_ADD, SVt_PVGV);
    if (!gv) sc_dec_croak(aTHX_ d, "glob name is unusable");
    return gv;
}

/* A fresh glob, in no stash, holding a DUP of the descriptor: closing this
 * one does not close the one it came from, and in a process where the number
 * means nothing the open fails and says so. Owned. */
static GV *sc_dec_fd_glob(pTHX_ sc_dec *d) {
    unsigned char type;
    UV fd;
    const char *how;
    char spec[32];
    GV *gv;

    SC_NEED(d, 1);
    type = *d->p++;
    fd = sc_dec_varint(aTHX_ d);
    if (fd > (UV)INT_MAX) sc_dec_croak(aTHX_ d, "descriptor too large");
    switch (type) {
    case '<': case '-': how = "<&";  break;    /* read; a pipe read from   */
    case '>': case '|': how = ">&";  break;    /* write; a pipe written to */
    case 'a':           how = ">>&"; break;
    case '+': case 's': case '#': how = "+<&"; break;
    default:  sc_dec_croak(aTHX_ d, "unknown filehandle mode"); how = "";
    }
    my_snprintf(spec, sizeof spec, "%s%d", how, (int)fd);

    gv = (GV *)newSV(0);
#if PERL_REVISION > 5 || (PERL_REVISION == 5 && PERL_VERSION >= 16)
    gv_init_pvn(gv, gv_stashpvs("Struct::Codec", GV_ADD), "FH", 2, 0);
#else
    gv_init(gv, gv_stashpvs("Struct::Codec", GV_ADD), "FH", 2, 0);
#endif
    if (!do_open(gv, spec, (I32)strlen(spec), FALSE, O_RDONLY, 0, NULL)) {
        int err = errno;
        SvREFCNT_dec((SV *)gv);
        croak("Struct::Codec: cannot reopen descriptor %d: %s at byte %" UVuf,
              (int)fd, Strerror(err), SC_OFF(d));
    }
    return gv;
}

/* The IO alone, which outlives the glob that opened it. Owned. */
static SV *sc_dec_fd_io(pTHX_ sc_dec *d) {
    GV *gv = sc_dec_fd_glob(aTHX_ d);
    SV *io = (SV *)GvIOp(gv);
    if (!io) { SvREFCNT_dec((SV *)gv); sc_dec_croak(aTHX_ d, "descriptor opened no IO"); }
    SvREFCNT_inc_simple_void_NN(io);
    SvREFCNT_dec((SV *)gv);
    return io;
}

static SV *sc_dec_format(pTHX_ sc_dec *d) {
    SV *name = sc_dec_key_sv(aTHX_ d);
    GV *gv;
    CV *fm;
    if (!SvCUR(name)) sc_dec_croak(aTHX_ d, "empty format name");
    gv = gv_fetchsv(name, 0, SVt_PVFM);
    fm = gv ? GvFORM(gv) : NULL;
    if (!fm)
        croak("Struct::Codec: format %" SVf " is not defined at byte %" UVuf,
              SVfARG(name), SC_OFF(d));
    return SvREFCNT_inc_simple_NN((SV *)fm);
}

/* The tie object, decoded through the ordinary path so that a stream which
 * shares it registers it as it would anything else; the mortal it lands in is
 * what the magic then holds its own reference to. */
static SV *sc_dec_tie_obj(pTHX_ sc_dec *d) {
    SV *obj = sv_newmortal();
    SV *shared = sc_dec_value(aTHX_ d, obj);
    if (shared) obj = shared;
    if (!SvROK(obj)) sc_dec_croak(aTHX_ d, "tie object is not a reference");
    return obj;
}

/* rule 8, widened: an ALIAS may put only a SCALAR in a slot. A container, a
 * glob, a sub, a format, an IO or a regexp placed where an SV belongs corrupts
 * the interpreter silently. */
static int sc_slot_safe(pTHX_ SV *sv) {
    if (SvTYPE(sv) >= SVt_PVAV || SvTYPE(sv) == SVt_PVGV) return 0;
    return !sc_is_regexp(aTHX_ sv);
}

/* The parent has attached `slot` and decoded into it; an ALIAS answered with
 * the SV that must be there instead. Each parent kind swaps it in its own way,
 * and the placeholder goes with the swap. */
static void sc_dec_swap_av(pTHX_ AV *av, SSize_t i, SV *shared) {
    SvREFCNT_inc_simple_void_NN(shared);
    (void)av_store(av, i, shared);
}

/* The thing behind a REF/OBJECT tag. `rv` is already attached to the parent;
 * the referent is made, the reference pointed at it, THEN it is filled (rule
 * 5), and blessed last (rule 10) so no DESTROY sees a half-built object. */
static void sc_dec_referent(pTHX_ sc_dec *d, SV *rv, STRLEN tag_off, int track,
                            HV *stash)
{
    unsigned char t, kind;
    SV *target;
    int plain = 0, tied = 0;

    SC_NEED(d, 1);
    t = *d->p;
    kind = SC_KIND(t);
    switch (kind) {
    case SC_T_ARRAY: case SC_T_HASH:
        /* the REF tag carried the TRACK bit; one here is corrupt */
        if (t & SC_TRACK) sc_dec_croak(aTHX_ d, "tracked container tag");
        d->p++;
        target = kind == SC_T_ARRAY ? (SV *)newAV() : (SV *)newHV();
        plain = 1;
        break;
    case SC_T_TIED_ARRAY: case SC_T_TIED_HASH:
        if (t & SC_TRACK) sc_dec_croak(aTHX_ d, "tracked container tag");
        d->p++;
        target = kind == SC_T_TIED_ARRAY ? (SV *)newAV() : (SV *)newHV();
        tied = 1;
        break;
    case SC_T_REGEXP:  case SC_T_CODE_NAME: case SC_T_CODE_SRC:
    case SC_T_GLOB:    case SC_T_FD_GLOB:   case SC_T_FD_IO:
    case SC_T_FORMAT:
        if (t & SC_TRACK) sc_dec_croak(aTHX_ d, "tracked referent tag");
        d->p++;
        /* built complete, or a croak that built nothing */
        switch (kind) {
        case SC_T_REGEXP:    target = sc_dec_regexp(aTHX_ d);    break;
        case SC_T_CODE_NAME: target = sc_dec_code_name(aTHX_ d); break;
        case SC_T_CODE_SRC:  target = sc_dec_code_src(aTHX_ d);  break;
        case SC_T_GLOB:
            target = (SV *)sc_dec_glob_named(aTHX_ d);
            SvREFCNT_inc_simple_void_NN(target);
            break;
        case SC_T_FD_GLOB:   target = (SV *)sc_dec_fd_glob(aTHX_ d); break;
        case SC_T_FD_IO:     target = sc_dec_fd_io(aTHX_ d);     break;
        default:             target = sc_dec_format(aTHX_ d);    break;
        }
        /* qr// is blessed into Regexp, and the tag implied it */
        if (kind == SC_T_REGEXP && !stash) stash = gv_stashpvs("Regexp", GV_ADD);
        break;
    default:
        target = newSV(0);
    }
    /* attach: the RV owns the referent from here, so a croak below frees it */
    SvUPGRADE(rv, SC_SVt_REF);
    SvRV_set(rv, target);
    SvROK_on(rv);
    if (track) sc_dec_register(aTHX_ d, tag_off, rv, 1);

    if (tied) {
        /* Registered above, so a tie object that refers back to its own
         * variable finds it. sv_magic takes its own reference to the object
         * and calls nothing: no TIEHASH, and nothing until the caller reads. */
        SV *obj = sc_dec_tie_obj(aTHX_ d);
        sv_magic(target, obj, PERL_MAGIC_tied, NULL, 0);
    }
    else if (!plain && SvTYPE(target) != SVt_NULL) {
        /* one of the kinds built complete above: nothing to fill */
    }
    else if (SvTYPE(target) == SVt_PVAV) {
        UV n = sc_dec_varint(aTHX_ d), i;
        SC_NEED(d, n);                          /* a value is at least one byte */
        if (n) av_extend((AV *)target, (SSize_t)n - 1);
        for (i = 0; i < n; i++) {
            SV *slot = newSV(0), *shared;
            av_push((AV *)target, slot);        /* attached before filled */
            shared = sc_dec_value(aTHX_ d, slot);
            if (shared) sc_dec_swap_av(aTHX_ (AV *)target, (SSize_t)i, shared);
        }
    }
    else if (SvTYPE(target) == SVt_PVHV) {
        UV n = sc_dec_varint(aTHX_ d), i;
        if (n > (UV)(d->end - d->p) / 2)        /* a key varint and a value tag */
            sc_dec_croak(aTHX_ d, "truncated input");
        for (i = 0; i < n; i++) {
            const char *k; STRLEN kl; int ku;
            SV **svp, *shared;
            UV before = HvTOTALKEYS((HV *)target);
            sc_dec_key(aTHX_ d, &k, &kl, &ku);
            /* ONE lookup: an lvalue fetch makes the entry with a fresh undef
             * SV already attached, which is exactly the placeholder wanted.
             * rule 6: a duplicate is refused BEFORE a store could free the
             * earlier value, which a later REFP may still name - and an
             * lvalue fetch of an existing key frees nothing, it hands back
             * the value that is there, so the key count not having moved is
             * the whole test. */
            svp = (SV **)hv_common((HV *)target, NULL, k, (I32)kl,
                                   ku ? HVhek_UTF8 : 0,
                                   HV_FETCH_LVALUE | HV_FETCH_JUST_SV, NULL, 0);
            if (!svp || HvTOTALKEYS((HV *)target) == before)
                sc_dec_croak(aTHX_ d, "duplicate hash key");
            shared = sc_dec_value(aTHX_ d, *svp);
            if (shared) {
                SvREFCNT_inc_simple_void_NN(shared);
                (void)hv_common((HV *)target, NULL, k, (I32)kl,
                                ku ? HVhek_UTF8 : 0, HV_FETCH_ISSTORE, shared, 0);
            }
        }
    }
    else {
        SV *shared = sc_dec_value(aTHX_ d, target);
        if (shared) {
            SvREFCNT_inc_simple_void_NN(shared);
            SvRV_set(rv, shared);
            SvREFCNT_dec(target);
        }
    }

    /* rule 10 has a second reason now: a referent that would become a pointer
     * object is refused BEFORE the bless, so it is freed as the plain integer
     * it is and the class's DESTROY never runs on it. Streams written before
     * the encoder refused the shape are how one arrives. */
    if (stash) {
        if (sc_is_pointer_obj(aTHX_ SvRV(rv), stash))
            croak("Struct::Codec: a %.*s object that holds a pointer at byte %" UVuf,
                  (int)HvNAMELEN_get(stash), HvNAME(stash), SC_OFF(d));
        sv_bless(rv, stash);
    }
}

/* Fill `into`, which the caller has already attached. Returns NULL, or the SV
 * the caller must put in `into`'s place because the stream said the slot IS
 * that SV. */
static SV *sc_dec_value(pTHX_ sc_dec *d, SV *into) {
    unsigned char t, kind;
    STRLEN tag_off;
    int track;
    SV *shared = NULL;

    if (++d->depth > SC_DEPTH_MAX)               /* rule 3 */
        sc_dec_croak(aTHX_ d, "structure too deep");

    SC_NEED(d, 1);
    tag_off = (STRLEN)SC_OFF(d);
    t = *d->p++;
    kind  = SC_KIND(t);
    track = (t & SC_TRACK) ? 1 : 0;

    if (kind >= SC_T_SHORT_BYTES) {
        sc_dec_str_into(aTHX_ d, into, SC_SHORT_LEN(kind),
                        kind >= SC_T_SHORT_UTF8 ? 1 : 0);
    }
    else if (kind < 0x20) {
        sv_setiv(into, (kind & 0x10) ? (IV)(kind & 0x0F) - 16 : (IV)kind);
    }
    else switch (kind) {
    case SC_T_UV: {
        UV u = sc_dec_varint(aTHX_ d);
        if (u <= (UV)IV_MAX) sv_setiv(into, (IV)u); else sv_setuv(into, u);
        break;
    }
    case SC_T_NEG: {
        UV u = sc_dec_varint(aTHX_ d);
        if (u > (UV)IV_MAX) sc_dec_croak(aTHX_ d, "negative integer too wide");
        sv_setiv(into, -(IV)u - 1);
        break;
    }
    case SC_T_NV:
        SC_NEED(d, SC_NV_BYTES);
        sv_setnv(into, sc_nv_from_wire(d->p));
        d->p += SC_NV_BYTES;
        break;
    case SC_T_NV_STR: {
        /* Decimal digits from a perl whose NV is wider than a double, read at
         * this perl's NV width: on a wide perl that returns the value the writer
         * had, and on a double perl the nearest double, which is the best it
         * could hold. The parser is named for the build rather than taken from
         * Atof, which below 5.30 is a ULP or two out at the top of a long double
         * - see the encoder's note.
         *
         * Copied out to get the NUL the parser needs - the stream has no room
         * for one and must not be written to. A length past the buffer is
         * corrupt input and is refused, not truncated, so the stack read stays
         * inside what the varint was checked against. */
        UV n = sc_dec_varint(aTHX_ d);
        char buf[SC_NV_STR_MAX + 1];
        if (n > (UV)SC_NV_STR_MAX) sc_dec_croak(aTHX_ d, "float too long");
        SC_NEED(d, n);
        Copy(d->p, buf, (STRLEN)n, char);
        buf[n] = '\0';
        d->p += n;
        sv_setnv(into, SC_NV_FROM_STR(buf));
        break;
    }
    case SC_T_UNDEF: break;   /* `into` is always a fresh SV, which is undef */
    case SC_T_TRUE:  sv_setsv(into, &PL_sv_yes);   break;
    case SC_T_FALSE: sv_setsv(into, &PL_sv_no);    break;
    case SC_T_BYTES:
    case SC_T_UTF8: {
        UV n = sc_dec_varint(aTHX_ d);
        sc_dec_str_into(aTHX_ d, into, (STRLEN)n, kind == SC_T_UTF8);
        break;
    }
    case SC_T_REF:
        sc_dec_referent(aTHX_ d, into, tag_off, track, NULL);
        track = 0;                                /* registered inside, as the RV */
        break;
    case SC_T_OBJECT: {
        const char *cn; STRLEN cl; int cu;
        HV *stash;
        sc_dec_key(aTHX_ d, &cn, &cl, &cu);
        if (!cl) sc_dec_croak(aTHX_ d, "empty class name");
        /* trusted contents: the stash is created if it does not exist */
#ifdef SVf_UTF8
        stash = gv_stashpvn(cn, cl, GV_ADD | (cu ? SVf_UTF8 : 0));
#else
        stash = gv_stashpvn(cn, cl, GV_ADD);
#endif
        sc_dec_referent(aTHX_ d, into, tag_off, track, stash);
        track = 0;
        break;
    }
    case SC_T_REFP: {
        sc_slot *s;
        if (track) sc_dec_croak(aTHX_ d, "tracked reference tag");
        s = sc_dec_lookup(aTHX_ d, sc_dec_varint(aTHX_ d));
        if (s->isref) {
            sv_setsv(into, s->sv);                /* a new RV to the same referent */
        }
        else {
            SV *r = newRV_inc(s->sv);             /* a reference TO that scalar */
            sv_setsv(into, r);
            SvREFCNT_dec(r);
        }
        break;
    }
    case SC_T_ALIAS: {
        sc_slot *s;
        if (track) sc_dec_croak(aTHX_ d, "tracked alias tag");
        s = sc_dec_lookup(aTHX_ d, sc_dec_varint(aTHX_ d));
        if (s->isref) {
            /* the slot IS the referent: legal for a scalar referent only.
             * rule 8: anything else placed where an SV belongs corrupts perl */
            shared = SvRV(s->sv);
            if (!sc_slot_safe(aTHX_ shared))
                sc_dec_croak(aTHX_ d, "alias of a container");
        }
        else {
            shared = s->sv;
        }
        break;
    }
    case SC_T_TIED_SCALAR: {
        /* `into` is attached and undef; the magic makes it the tie */
        SV *obj = sc_dec_tie_obj(aTHX_ d);
        sv_magic(into, obj, PERL_MAGIC_tiedscalar, NULL, 0);
        break;
    }
    case SC_T_GLOB:
        /* a glob in a slot: `$x = *STDOUT`, which sv_setsv reproduces */
        sv_setsv(into, (SV *)sc_dec_glob_named(aTHX_ d));
        break;
    case SC_T_FD_GLOB: {
        GV *gv = sc_dec_fd_glob(aTHX_ d);
        sv_setsv(into, (SV *)gv);
        SvREFCNT_dec((SV *)gv);
        break;
    }
    case SC_T_ARRAY:
    case SC_T_HASH:
    case SC_T_TIED_ARRAY:
    case SC_T_TIED_HASH:
        sc_dec_croak(aTHX_ d, "container without a reference");
        break;
    case SC_T_REGEXP:
    case SC_T_CODE_NAME:
    case SC_T_CODE_SRC:
    case SC_T_FD_IO:
    case SC_T_FORMAT:
        sc_dec_croak(aTHX_ d, "referent without a reference");
        break;
    default:
        sc_dec_croak(aTHX_ d, "unknown tag");
    }

    if (track) sc_dec_register(aTHX_ d, tag_off, into, 0);
    d->depth--;
    return shared;
}

/* An owned SV. */
static SV *sc_decode(pTHX_ const char *bytes, STRLEN len) {
    sc_dec d;
    SV *root, *shared;

    memset(&d, 0, sizeof d);
    d.base = d.p = (const unsigned char *)bytes;
    d.end  = d.base + len;

    SC_NEED(&d, SC_HDR_LEN);                                    /* rule 11 */
    if (d.p[0] != SC_MAGIC)   sc_dec_croak(aTHX_ &d, "not a Struct::Codec stream");
    if (d.p[1] != SC_VERSION) sc_dec_croak(aTHX_ &d, "unknown format version");
    if (d.p[2] != SC_FLOAT)   sc_dec_croak(aTHX_ &d, "unknown float encoding");
    d.p += SC_HDR_LEN;

    root = sv_newmortal();                 /* the mortal root: a croak frees it all */
    shared = sc_dec_value(aTHX_ &d, root);
    if (shared) sc_dec_croak(aTHX_ &d, "alias at the root");   /* nothing precedes it */
    if (d.p != d.end) sc_dec_croak(aTHX_ &d, "trailing bytes"); /* rule 9 */

    return SvREFCNT_inc_simple_NN(root);
}

#endif /* SC_CODEC_H */
