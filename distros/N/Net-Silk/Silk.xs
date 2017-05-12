/*
**
** Copyright (C) 2011-2014 by Carnegie Mellon University
**
** Use of the Net-Silk library and related source code is subject to the
** terms of the following licenses:
** 
** GNU Public License (GPL) Rights pursuant to Version 2, June 1991
** Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013
** 
** NO WARRANTY
** 
** ANY INFORMATION, MATERIALS, SERVICES, INTELLECTUAL PROPERTY OR OTHER 
** PROPERTY OR RIGHTS GRANTED OR PROVIDED BY CARNEGIE MELLON UNIVERSITY 
** PURSUANT TO THIS LICENSE (HEREINAFTER THE "DELIVERABLES") ARE ON AN 
** "AS-IS" BASIS. CARNEGIE MELLON UNIVERSITY MAKES NO WARRANTIES OF ANY 
** KIND, EITHER EXPRESS OR IMPLIED AS TO ANY MATTER INCLUDING, BUT NOT 
** LIMITED TO, WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE, 
** MERCHANTABILITY, INFORMATIONAL CONTENT, NONINFRINGEMENT, OR ERROR-FREE 
** OPERATION. CARNEGIE MELLON UNIVERSITY SHALL NOT BE LIABLE FOR INDIRECT, 
** SPECIAL OR CONSEQUENTIAL DAMAGES, SUCH AS LOSS OF PROFITS OR INABILITY 
** TO USE SAID INTELLECTUAL PROPERTY, UNDER THIS LICENSE, REGARDLESS OF 
** WHETHER SUCH PARTY WAS AWARE OF THE POSSIBILITY OF SUCH DAMAGES. 
** LICENSEE AGREES THAT IT WILL NOT MAKE ANY WARRANTY ON BEHALF OF 
** CARNEGIE MELLON UNIVERSITY, EXPRESS OR IMPLIED, TO ANY PERSON 
** CONCERNING THE APPLICATION OF OR THE RESULTS TO BE OBTAINED WITH THE 
** DELIVERABLES UNDER THIS LICENSE.
** 
** Licensee hereby agrees to defend, indemnify, and hold harmless Carnegie 
** Mellon University, its trustees, officers, employees, and agents from 
** all claims or demands made against them (and any related losses, 
** expenses, or attorney's fees) arising out of, or relating to Licensee's 
** and/or its sub licensees' negligent use or willful misuse of or 
** negligent conduct or willful misconduct regarding the Software, 
** facilities, or other rights or assistance granted by Carnegie Mellon 
** University under this License, including, but not limited to, any 
** claims of product liability, personal injury, death, damage to 
** property, or violation of any laws or regulations.
** 
** Carnegie Mellon University Software Engineering Institute authored 
** documents are sponsored by the U.S. Department of Defense under 
** Contract FA8721-05-C-0003. Carnegie Mellon University retains 
** copyrights in all material produced under this contract. The U.S. 
** Government retains a non-exclusive, royalty-free license to publish or 
** reproduce these documents, or allow others to do so, for U.S. 
** Government purposes only pursuant to the copyright license under the 
** contract clause at 252.227.7013.
**
*/

#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_PL_signals 1
#include "ppport.h"

#include "pthread.h"

#define MATH_INT64_NATIVE_IF_AVAILABLE
#include "perl_math_int64.h"

/* begin cut/paste from Int128.xs */

#if __GNUC__ == 4 && __GNUC_MINOR__ >= 4 && __GNUC_MINOR__ < 6

/* workaroung for gcc 4.4/4.5 - see http://gcc.gnu.org/gcc-4.4/changes.html */
typedef int int128_t __attribute__ ((__mode__ (TI)));
typedef unsigned int uint128_t __attribute__ ((__mode__ (TI)));

#else

typedef __int128 int128_t;
typedef unsigned __int128 uint128_t;

#endif

/* perl memory allocator does not guarantee 16-byte alignment */
typedef int128_t int128_t_a8 __attribute__ ((aligned(8)));
typedef uint128_t uint128_t_a8 __attribute__ ((aligned(8)));

/* end cut/paste */

#include "perl_math_int128.h"

#include <silk/silk.h>

#include <silk/rwrec.h>
#include <silk/skbag.h>
#include <silk/skcountry.h>
#include <silk/skipaddr.h>
#include <silk/skipset.h>
#include <silk/skprefixmap.h>
#include <silk/sksite.h>
#include <silk/skstream.h>
#include <silk/skvector.h>
#include <silk/utils.h>

typedef skipset_t                *Net__Silk__IPSet;
typedef skBag_t                  *Net__Silk__Bag;
typedef skPrefixMap_t            *Net__Silk__Pmap;

typedef skIPWildcard_t            Net__Silk__IPWildcard;

typedef skipaddr_t                Net__Silk__IPAddr;
typedef Net__Silk__IPAddr         Net__Silk__IPv4Addr;
typedef Net__Silk__IPAddr         Net__Silk__IPv6Addr;

typedef skIPWildcardIterator_t   *Net__Silk__IPWildcard__iter_xs;
typedef skipset_iterator_t       *Net__Silk__IPSet__iter_xs;
typedef skBagIterator_t          *Net__Silk__Bag__iter_xs;
typedef skPrefixMapIterator_t    *Net__Silk__Pmap__iter_xs;
typedef sksite_repo_iter_t       *Net__Silk__Site__iter_xs;

typedef skPrefixMapProtoPort_t    Net__Silk__ProtoPort;

typedef uint16_t                  Net__Silk__TCPFlags;

typedef rwRec                    *Net__Silk__RWRec;

typedef skstream_t               *Net__Silk__File__io_xs;


#define SILK_IPADDR_CLASS     "Net::Silk::IPAddr"
#define SILK_IPV4ADDR_CLASS   "Net::Silk::IPv4Addr"
#define SILK_IPV6ADDR_CLASS   "Net::Silk::IPv6Addr"

#define SILK_IPWILDCARD_CLASS      "Net::Silk::IPWildcard"
#define SILK_IPWILDCARD_ITER_CLASS "Net::Silk::IPWildcard::iter_xs"

#define SILK_IPSET_CLASS      "Net::Silk::IPSet"
#define SILK_IPSET_ITER_CLASS "Net::Silk::IPSet::iter_xs"

#define SILK_BAG_CLASS      "Net::Silk::Bag"
#define SILK_BAG_ITER_CLASS "Net::Silk::Bag::iter_xs"

#define SILK_PMAP_CLASS      "Net::Silk::Pmap"
#define SILK_PMAP_IPV4_CLASS "Net::Silk::Pmap::IPv4"
#define SILK_PMAP_IPV6_CLASS "Net::Silk::Pmap::IPv6"
#define SILK_PMAP_PP_CLASS   "Net::Silk::Pmap::ProtoPort"
#define SILK_PMAP_ITER_CLASS "Net::Silk::Pmap::iter_xs"

#define SILK_PROTOPORT_CLASS "Net::Silk::ProtoPort"

#define SILK_TCPFLAGS_CLASS "Net::Silk::TCPFlags"

#define SILK_RWREC_CLASS "Net::Silk::RWRec"

#define SILK_SILKFILE_IO_CLASS "Net::Silk::File::io_xs"

#define MATH_INT64_CLASS   "Math::Int64"
#define MATH_UINT64_CLASS  "Math::UInt64"
#define MATH_INT128_CLASS  "Math::Int128"
#define MATH_UINT128_CLASS "Math::UInt128"

#define MAX_EPOCH (((INT64_C(1) << 31)-1)*1000) /* Tue Jan 19 03:14:07 2038 */

#define INT128_MAX ((int128_t)((~(uint128_t)0)>>1))
#define INT128_MIN (~INT128_MAX)
#define UINT128_MAX ((uint128_t)(~(uint128_t)0))

typedef enum groknum_err_en {
    GROKNUM_OK                =  0,  /* number ok         */
    GROKNUM_ERR_NVREF         = -1,  /* invalid reference */
    GROKNUM_ERR_NAS           = -2,  /* not a string      */
    GROKNUM_ERR_NAN           = -3,  /* not a number      */
    GROKNUM_ERR_NEG           = -4,  /* negative          */
    GROKNUM_ERR_U32_OVERFLOW  = -5,  /* exceeds U32_MAX   */
    GROKNUM_ERR_U64_OVERFLOW  = -6,  /* exceeds U64_MAX   */
    GROKNUM_ERR_U128_OVERFLOW = -7,  /* exceeds U128_MAX  */
    GROKNUM_ERR_I32_OVERFLOW  = -8,  /* exceeds I32_MAX   */
    GROKNUM_ERR_I64_OVERFLOW  = -9,  /* exceeds I64_MAX   */
    GROKNUM_ERR_I128_OVERFLOW = -10, /* exceeds I128_MAX  */
    GROKNUM_ERR_UNKNOWN       = -11, /* unknown           */
} groknum_err_t;

typedef union n128_un {
    uint128_t     u128;
    uint64_t       u64[2];
    uint32_t       u32[4];
    uint8_t         u8[16];
    unsigned char    c[16];
} n128_t;

#include <signal.h>
#include <assert.h>

#ifdef __cplusplus
}
#endif

#define MC(cc) \
    newCONSTSUB(stash, #cc, newSViv( cc ))

#define MCE(name, cc) \
    newCONSTSUB(stash, #name, newSViv( cc ))

#define MCPV(cc) \
    newCONSTSUB(stash, #cc, newSVpv( cc, sizeof(cc)-1 ))

#define MCEPV(name, cc) \
    newCONSTSUB(stash, #name, newSVpv( cc, sizeof(cc)-1 ))

#define IS_IPV4_KEY(k)                          \
    ((k) == SKBAG_FIELD_SIPv4                   \
     || (k) == SKBAG_FIELD_DIPv4                \
     || (k) == SKBAG_FIELD_NHIPv4               \
     || (k) == SKBAG_FIELD_ANY_IPv4)

#define IS_IPV6_KEY(k)                          \
    ((k) == SKBAG_FIELD_SIPv6                   \
     || (k) == SKBAG_FIELD_DIPv6                \
     || (k) == SKBAG_FIELD_NHIPv6               \
     || (k) == SKBAG_FIELD_ANY_IPv6)

#define IS_IP_KEY(k) (IS_IPV4_KEY(k) || IS_IPV6_KEY(k))

#define BYTE_SWAP32(a) (((((uint32_t)(a)) & 0x000000FF) << 24) |    \
                        ((((uint32_t)(a)) & 0x0000FF00) << 8)  |    \
                        ((((uint32_t)(a)) & 0x00FF0000) >> 8)  |    \
                        ((((uint32_t)(a)) >> 24) & 0x000000FF))

#define GROKNUM_CROAK(rv, msg)                             \
    switch (rv) {                                          \
        case GROKNUM_ERR_NVREF:                            \
            croak("%s: invalid reference", msg);           \
        case GROKNUM_ERR_NAS:                              \
            croak("%s: not a string", msg);                \
        case GROKNUM_ERR_NAN:                              \
            croak("%s: not an integer", msg);              \
        case GROKNUM_ERR_NEG:                              \
            croak("%s: negative number", msg);             \
        case GROKNUM_ERR_U32_OVERFLOW:                     \
            croak("%s: uint32 overflow", msg);             \
        case GROKNUM_ERR_U64_OVERFLOW:                     \
            croak("%s: uint64 overflow", msg);             \
        case GROKNUM_ERR_U128_OVERFLOW:                    \
            croak("%s: uint128 overflow", msg);            \
        case GROKNUM_ERR_I32_OVERFLOW:                     \
            croak("%s: int32 overflow", msg);              \
        case GROKNUM_ERR_I64_OVERFLOW:                     \
            croak("%s: int64 overflow", msg);              \
        case GROKNUM_ERR_I128_OVERFLOW:                    \
            croak("%s: int128 overflow", msg);             \
        case GROKNUM_ERR_UNKNOWN:                          \
            croak("%s: unknown error", msg);               \
        default:                                           \
            croak("%s: invalid error code (%d)", msg, rv); \
    }

static char error_buffer[1024];

static int error_printf(const char *fmt, ...)
{
    int rv;

    va_list args;
    va_start(args, fmt);
    rv = vsnprintf(error_buffer, sizeof(error_buffer), fmt, args);
    error_buffer[sizeof(error_buffer) - 1] = '\0';
    va_end(args);

    return rv;
}

/* callback hooks */

//static PerlInterpreter *orig_perl;
//static pthread_mutex_t callback_lock = PTHREAD_MUTEX_INITIALIZER;

/*
void
output_callback(nmsg_message_t m, void *callback) {

    //fprintf(stderr, "\n\nxs output_callback %p %p\n\n", m, callback);

    if (callback == NULL || m == NULL)
        return;

    PERL_SET_CONTEXT(orig_perl);
    pthread_mutex_lock(&callback_lock);

    { // C99 compliance

      dTHX;
      dSP;

      ENTER;
      SAVETMPS;
      // push args onto stack
      PUSHMARK(sp);
      mXPUSHs(_xs_wrap_msg(aTHX_ m));
      PUTBACK;
      // re-wrap our callback CV in a reference and invoke perl function
      call_sv(sv_2mortal(newRV(MUTABLE_SV(callback))), G_DISCARD);
      // clean up
      FREETMPS;
      LEAVE;
    }

    pthread_mutex_unlock(&callback_lock);

    //fprintf(stderr, "leaving callback fn\n");
}

*/

#include "strtoint64.h"
#include "strtoint128.h"

static groknum_err_t
_xs_pack_uint32_int(pTHX_ SV *sv, uint32_t *u32) {
    UV uv;
    IV iv;
    NV nv;
    int64_t   i64;
    uint64_t  u64;
    int128_t  i128;
    uint128_t u128;
    groknum_err_t rv = GROKNUM_OK;

    if (SvIOK_UV(sv)) {
        uv = SvUV(sv);
        if (uv > UINT32_MAX)
            rv = GROKNUM_ERR_U32_OVERFLOW;
        *u32 = (uint32_t)uv;
    }
    else if (SvIOK(sv)) {
        iv = SvIV(sv);
        if (iv < 0)
            rv = GROKNUM_ERR_NEG;
        else if (iv > UINT32_MAX)
            rv = GROKNUM_ERR_U32_OVERFLOW;
        *u32 = (uint32_t)iv;
    }
    else if (SvNOK(sv)) {
        nv = SvNV(sv);
        if (nv < 0)
            rv = GROKNUM_ERR_NEG;
        else if (nv > UINT32_MAX)
            rv = GROKNUM_ERR_U32_OVERFLOW;
        *u32 = (uint32_t)SvUV(sv);
    }
    else if (SvU64OK(sv)) {
        u64 = SvU64(sv);
        if (u64 > UINT32_MAX)
            return GROKNUM_ERR_U32_OVERFLOW;
        *u32 = (uint32_t)u64;
    }
    else if (SvI64OK(sv)) {
        i64 = SvI64(sv);
        if (i64 < 0)
            return GROKNUM_ERR_NEG;
        if (i64 > UINT32_MAX)
            return GROKNUM_ERR_U32_OVERFLOW;
        *u32 = (uint32_t)i64;
    }
    else if (SvU128OK(sv)) {
        u128 = SvU128(sv);
        if (u128 > UINT32_MAX)
            return GROKNUM_ERR_U32_OVERFLOW;
        *u32 = (uint32_t)u128;
    }
    else if (SvI128OK(sv)) {
        i128 = SvI128(sv);
        if (i128 < 0)
            return GROKNUM_ERR_NEG;
        if (i128 > UINT32_MAX)
            return GROKNUM_ERR_U32_OVERFLOW;
        *u32 = (uint32_t)i128;
    }
    else
        rv = GROKNUM_ERR_NAN;

    return rv;
}

static groknum_err_t
_xs_pack_uint32_strint(pTHX_ SV *sv, uint32_t *u32) {
    uint64_t       u64;
    groknum_err_t  rv;

    if (!SvPOK(sv))
        return GROKNUM_ERR_NAS;
    rv = strtoint64(aTHX_ SvPV_nolen(sv), 0, 0, &u64);
    switch (rv) {
        case GROKNUM_OK:
            if (u64 > UINT32_MAX)
                return GROKNUM_ERR_U32_OVERFLOW;
            *u32 = (uint32_t)u64;
            return GROKNUM_OK;
        case GROKNUM_ERR_I64_OVERFLOW:
        case GROKNUM_ERR_U64_OVERFLOW:
            return GROKNUM_ERR_U32_OVERFLOW;
        default:
            return rv;
    }
    return GROKNUM_ERR_UNKNOWN;
}

static groknum_err_t
_xs_pack_uint64_int(pTHX_ SV *sv, uint64_t *u64) {
    IV iv;
    NV nv;
    int64_t   i64;
    int128_t  i128;
    uint128_t u128;

    if (SvIOK_UV(sv)) {
        *u64 = (uint64_t)SvUV(sv);
    }
    else if (SvIOK(sv)) {
        iv = SvIV(sv);
        if (iv < 0)
            return GROKNUM_ERR_NEG;
        *u64 = (uint64_t)iv;
    }
    else if (SvNOK(sv)) {
        nv = SvNV(sv);
        if (nv < 0)
            return GROKNUM_ERR_NEG;
        if (nv > UINT64_MAX)
            return GROKNUM_ERR_U64_OVERFLOW;
        *u64 = (uint64_t)SvUV(sv);
    }
    else if (SvU64OK(sv)) {
        *u64 = SvU64(sv);
    }
    else if (SvI64OK(sv)) {
        i64 = SvI64(sv);
        if (i64 < 0)
            return GROKNUM_ERR_NEG;
        *u64 = (uint64_t)i64;
    }
    else if (SvU128OK(sv)) {
        u128 = SvU128(sv);
        if (u128 > UINT64_MAX)
            return GROKNUM_ERR_U64_OVERFLOW;
        *u64 = (uint64_t)u128;
    }
    else if (SvI128OK(sv)) {
        i128 = SvI128(sv);
        if (i128 < 0)
            return GROKNUM_ERR_NEG;
        if (i128 > UINT64_MAX)
            return GROKNUM_ERR_U64_OVERFLOW;
        *u64 = (uint64_t)i128;
    }
    else
        return GROKNUM_ERR_NAN;
    return GROKNUM_OK;
}

static groknum_err_t
_xs_pack_uint64_strint(pTHX_ SV *sv, uint64_t *u64) {
    if (!SvPOK(sv))
        return GROKNUM_ERR_NAS;
    return strtoint64(aTHX_ SvPV_nolen(sv), 0, 0, u64);
}

static groknum_err_t
_xs_pack_uint128_int(pTHX_ SV *sv, uint128_t *u128) {
    IV iv;
    NV nv;
    int64_t  i64;
    int128_t i128;
    groknum_err_t rv = GROKNUM_OK;

    if (SvIOK_UV(sv)) {
        *u128 = (uint128_t)SvUV(sv);
    }
    else if (SvIOK(sv)) {
        iv = SvIV(sv);
        if (iv < 0)
            return GROKNUM_ERR_NEG;
        *u128 = (uint128_t)iv;
    }
    else if (SvNOK(sv)) {
        nv = SvNV(sv);
        if (nv < 0)
            rv = GROKNUM_ERR_NEG;
        else if (nv > UINT128_MAX)
            rv = GROKNUM_ERR_U128_OVERFLOW;
        *u128 = (uint128_t)SvUV(sv);
    }
    else if (SvU128OK(sv))
        *u128 = SvU128(sv);
    else if (SvI128OK(sv)) {
        i128 = SvI128(sv);
        if (i128 < 0)
            rv = GROKNUM_ERR_NEG;
        *u128 = (uint128_t)i128;
    }
    else if (SvU64OK(sv))
        *u128 = (uint128_t)SvU64(sv);
    else if (SvI64OK(sv)) {
        i64 = SvI64(sv);
        if (i64 < 0)
            rv = GROKNUM_ERR_NEG;
        *u128 = (uint128_t)i64;
    }
    else
        rv = GROKNUM_ERR_NAN;

    return rv;
}

static groknum_err_t
_xs_pack_uint128_strint(pTHX_ SV *sv, uint128_t *u128) {
    STRLEN         len;
    char          *cp;

    if (!SvPOK(sv))
        return GROKNUM_ERR_NAS;
    cp = SvPV(sv, len);
    return strtoint128(aTHX_ cp, len, 0, 0, u128);
}

static groknum_err_t
_xs_pack_ipv4_int(pTHX_ SV *sv, skipaddr_t *addr) {
    uint32_t      u32 = 0;
    groknum_err_t rv;

    rv = _xs_pack_uint32_int(aTHX_ sv, &u32);
    skipaddrSetV4(addr, &u32);
    return rv;
}

static groknum_err_t
_xs_pack_ipv4_strint(pTHX_ SV *sv, skipaddr_t *addr) {
    uint32_t      u32 = 0;
    groknum_err_t rv;

    rv = _xs_pack_uint32_strint(aTHX_ sv, &u32);
    skipaddrSetV4(addr, &u32);
    return rv;
}

#if SK_ENABLE_IPV6

static groknum_err_t
_xs_pack_ipv6_int(pTHX_ SV *sv, skipaddr_t *addr) {
    n128_t n128;
    uint128_t val = 0;
    groknum_err_t rv = GROKNUM_OK;
    int i;

    memset(&n128.u128, 0, sizeof(n128.u128));

    rv = _xs_pack_uint128_int(aTHX_ sv, &val);

    // network byte order
    for (i = 3; i >= 0; i--, val >>= 32)
        n128.u32[i] = val;
#if SK_LITTLE_ENDIAN
    for (i=0; i < 4; i++)
        n128.u32[i] = BYTE_SWAP32(n128.u32[i]);
#endif
    skipaddrSetV6(addr, n128.u8);

    return rv;
}

static groknum_err_t
_xs_pack_ipv6_strint(pTHX_ SV *sv, skipaddr_t *addr) {
    n128_t n128;
    uint128_t u128 = 0;
    groknum_err_t rv = GROKNUM_OK;
    int i;

    memset(&n128.u128, 0, sizeof(n128.u128));

    rv = _xs_pack_uint128_strint(aTHX_ sv, &u128);

    // network byte order
    for (i = 3; i >= 0; i--, u128 >>= 32)
        n128.u32[i] = u128;
#if SK_LITTLE_ENDIAN
    for (i=0; i < 4; i++)
        n128.u32[i] = BYTE_SWAP32(n128.u32[i]);
#endif
    skipaddrSetV6(addr, n128.u8);

    return rv;
}

#endif

/* copy a Net::Silk::IPAddr value */

static groknum_err_t
_xs_copy_ipaddr(pTHX_ SV *sv, skipaddr_t *addr) {
    STRLEN len;
    char *s;

    if (! SvROK(sv) || ! sv_derived_from(sv, SILK_IPADDR_CLASS))
        return GROKNUM_ERR_NVREF;
    s = SvPV(SvRV(sv), len);
    if (len != sizeof(*addr))
        croak("invalid ip (size %lu of packed data != %lu of skipaddr_t)\n",
                len, sizeof(*addr));
    skipaddrCopy(addr, (skipaddr_t *)s);
    return GROKNUM_OK;
}

static skipaddr_t
SvNumIPV4ADDR(pTHX_ SV *sv) {
    skipaddr_t    addr;
    groknum_err_t rv;

    // this function handles regular numbers and uint128, uint64, etc
    rv = _xs_pack_ipv4_int(aTHX_ sv, &addr);
    switch (rv) {
        case GROKNUM_OK:
            return addr;
        case GROKNUM_ERR_NAN:
            break;
        default:
            GROKNUM_CROAK(rv, "invalid ipv4 numeric address");
    }
    // otherwise check for references
    if (SvROK(sv)) {
        // see if it's already a Net::Silk::IPAddr
        rv = _xs_copy_ipaddr(aTHX_ sv, &addr);
        if (rv == GROKNUM_OK) {
#if SK_ENABLE_IPV6
            if skipaddrIsV6(&addr) {
                rv = skipaddrV6toV4(&addr, &addr);
                if (rv < 0)
                    croak("invalid ipv4 address: ipv6 out of range");
            }
#endif
            return addr;
        }
        croak("invalid ipv4 numeric address ref (not a %s, %s, %s, %s,"
              " or %s derived reference)",
              SILK_IPADDR_CLASS, MATH_UINT64_CLASS, MATH_INT64_CLASS,
              MATH_UINT128_CLASS, MATH_INT128_CLASS);
    }
    // otherwise see if it's a number-like string
    if (SvPOK(sv)) {
        // string
        rv = _xs_pack_ipv4_strint(aTHX_ sv, &addr);
        if (rv == GROKNUM_OK)
            return addr;
        GROKNUM_CROAK(rv, "invalid ipv4 numeric address");
    }
    GROKNUM_CROAK(GROKNUM_ERR_NAN, "invalid ipv4 numeric address");
}

static skipaddr_t
SvIPV4ADDR(pTHX_ SV *sv) {
    skipaddr_t    addr;
    groknum_err_t rv;

    if (!SvOK(sv))
        croak("invalid ipv4 address: expected a string, int, or reference");
    if (SvROK(sv)) {
        // let num-specific handle refs
        return SvNumIPV4ADDR(aTHX_ sv);
    }
    if (SvPOK(sv)) {
        rv = _xs_pack_ipv4_strint(aTHX_ sv, &addr);
        switch (rv) {
            case GROKNUM_OK:
                break;
            case GROKNUM_ERR_NAN:
                rv = skStringParseIP(&addr, SvPV_nolen(sv));
                if (rv != 0)
                    croak("invalid ipv4 address: %s",
                          skStringParseStrerror(rv));
                break;
            default:
                GROKNUM_CROAK(rv, "invalid ipv4 string address");
        }
        return addr;
    }
    // punt to num-specific
    return SvNumIPV4ADDR(aTHX_ sv);
}

static skipaddr_t
SvNumIPV6ADDR(pTHX_ SV *sv) {
    skipaddr_t addr;
    groknum_err_t rv;

#if SK_ENABLE_IPV6
    // this function handles regular numbers and uint128, uint64, etc
    rv = _xs_pack_ipv6_int(aTHX_ sv, &addr);
    switch (rv) {
        case GROKNUM_OK:
            return addr;
        case GROKNUM_ERR_NAN:
            break;
        default:
            GROKNUM_CROAK(rv, "invalid ipv6 numeric address");
    }
    // otherwise check for references
    if (SvROK(sv)) {
        // first see if it's already a Net::Silk::IPAddr
        rv = _xs_copy_ipaddr(aTHX_ sv, &addr);
        if (rv == GROKNUM_OK) {
            if (!skipaddrIsV6(&addr))
                skipaddrV4toV6(&addr, &addr);
            return addr;
        }
        croak("invalid ipv6 reference: not a %s\n", SILK_IPADDR_CLASS);
    }
    // otherwise see if it's a numeric string
    if (SvPOK(sv)) {
        // string
        rv = _xs_pack_ipv6_strint(aTHX_ sv, &addr);
        if (rv != GROKNUM_OK)
            GROKNUM_CROAK(rv, "invalid ipv6 numeric address");
        return addr;
    }
    GROKNUM_CROAK(GROKNUM_ERR_NAN, "invalid ipv6 numeric address");
#else
    croak("SiLK was not built with IPv6 support.");
#endif
}

static skipaddr_t
SvIPV6ADDR(pTHX_ SV *sv) {
    skipaddr_t    addr;
    groknum_err_t rv;

#if SK_ENABLE_IPV6
    if (!SvOK(sv))
        croak("invalid ipv6: expected a string or reference");
    if (SvROK(sv)) {
        // let num-specific handle refs
        return SvNumIPV6ADDR(aTHX_ sv);
    }
    if (SvPOK(sv)) {
        rv = _xs_pack_ipv6_strint(aTHX_ sv, &addr);
        switch (rv) {
            case GROKNUM_OK:
                break;
            case GROKNUM_ERR_NAN:
                rv = skStringParseIP(&addr, SvPV_nolen(sv));
                if (rv != 0)
                    croak("invalid ipv6 address: %s",
                          skStringParseStrerror(rv));
                break;
            default:
                GROKNUM_CROAK(rv, "invalid ipv6 string address");
        }
        return addr;
    }
    // punt to numeric
    return SvNumIPV6ADDR(aTHX_ sv);
#else
    croak("SiLK was not built with IPv6 support.");
#endif
}

static skipaddr_t
SvIPADDR(pTHX_ SV *sv) {
    skipaddr_t    addr;
    uint128_t     u128;
    groknum_err_t rv;
    if (!SvOK(sv))
        croak("invalid ip address: expected a string or reference");
    if (SvROK(sv)) {
        rv = _xs_copy_ipaddr(aTHX_ sv, &addr);
        if (rv == GROKNUM_OK)
            return addr;
        if (SvU64OK(sv) || SvI64OK(sv) || SvU128OK(sv) || SvI128OK(sv))
            croak("invalid ipaddress : numeric address"
                  " (use ipv4/ipv6 specific class)");
        croak("invalid ip address ref: not a %s derived reference",
              SILK_IPADDR_CLASS);
    }
    if (SvPOK(sv)) {
        rv = _xs_pack_uint128_strint(aTHX_ sv, &u128);
        if (rv == GROKNUM_OK)
            croak("invalid ip address:"
                  " use ipv4/ipv6 specific class for numeric values");
        rv = skStringParseIP(&addr, SvPV_nolen(sv));
        if (rv != 0)
            croak("invalid ip address: %s)", skStringParseStrerror(rv));
        return addr;
    }
    rv = _xs_pack_uint128_int(aTHX_ sv, &u128);
    if (rv == GROKNUM_OK)
        croak("invalid ip address:"
              " use ipv4/ipv6 specific class for numeric values");
    croak("invalid ip address");
}

static SV *
newSvIPADDR(pTHX_ skipaddr_t *addr) {
#if SK_ENABLE_IPV6
    if (skipaddrIsV6(addr)) {
        return sv_setref_pvn(newSV(0), SILK_IPV6ADDR_CLASS,
                             (char *)addr, sizeof(*addr));
    } else
#else
    if (skipaddrIsV6(addr)) {
        int rv = skipaddrV6toV4(addr, addr);
        if (rv < 0)
            croak("invalid ipv4 address (ipv6 too large)");
    }
#endif
    {
        return sv_setref_pvn(newSV(0), SILK_IPV4ADDR_CLASS,
                             (char *)addr, sizeof(*addr));
    }
}

static SV *
newSvIPV4ADDR(pTHX_ skipaddr_t *addr) {
#if SK_ENABLE_IPV6
    if (skipaddrIsV6(addr)) {
        int rv = skipaddrV6toV4(addr, addr);
        if (rv < 0)
            croak("invalid ipv4 address (ipv6 too large)");
    }
#endif
    return sv_setref_pvn(newSV(0), SILK_IPV4ADDR_CLASS,
                         (char *)addr, sizeof(*addr));
}

static SV *
newSvIPV6ADDR(pTHX_ skipaddr_t *addr) {
    if (!skipaddrIsV6(addr))
        skipaddrV4toV6(addr, addr);
    return sv_setref_pvn(newSV(0), SILK_IPV6ADDR_CLASS,
                         (char *)addr, sizeof(*addr));
}

static skIPWildcard_t
SvIPWILDCARD(pTHX_ SV *sv) {
    skIPWildcard_t wc;
    STRLEN  len;
    int     rv;
    char   *s;
    char    buf[SK_NUM2DOT_STRLEN];

    if (!SvOK(sv))
        croak("invalid wildcard (expected a string or reference)");
    if (SvROK(sv)) {
        if (sv_derived_from(sv, SILK_IPWILDCARD_CLASS)) {
            s = SvPV(SvRV(sv), len);
            if (len != sizeof(skIPWildcard_t))
                croak("invalid wildcard (size %lu of packed data"
                      " != %lu of skIPWildcard_t)\n",
                      len, sizeof(skIPWildcard_t));
            return *(skIPWildcard_t *)s;
        }
        else if (sv_derived_from(sv, SILK_IPADDR_CLASS)) {
            skipaddrString(buf, (skipaddr_t *)SvPV_nolen(SvRV(sv)),
                           SKIPADDR_CANONICAL);
            rv = skStringParseIPWildcard(&wc, buf);
            if (rv != 0)
                croak("invalid wildcard (error %d parsing string: %s",
                      rv, skStringParseStrerror(rv));
            return wc;
        }
        else
            croak("invalid wildcard (not a %s or %s derived reference)",
                  SILK_IPWILDCARD_CLASS, SILK_IPADDR_CLASS);
    }
    rv = skStringParseIPWildcard(&wc, SvPV(sv, len));
    if (rv != 0) 
        croak("invalid wildcard (error %d parsing string: %s",
              rv, skStringParseStrerror(rv));
    return wc;
}

static SV *
newSvIPWILDCARD(pTHX_ skIPWildcard_t *wc) {
    return sv_setref_pvn(newSV(0), SILK_IPWILDCARD_CLASS,
                         (char *)wc, sizeof(*wc));
}

static void
_sv_pack_bagkey(pTHX_ skBag_t *bag, SV *sv, skBagTypedKey_t *key) {
    skBagFieldType_t ftype;
    int              ntype;
    UV               uv;
    STRLEN           len;
    char            *cp;
    uint32_t         u32;
    groknum_err_t    rv;

    if (!SvOK(sv))
        croak("invalid bag key (expected a string, int, or %s)",
              SILK_IPADDR_CLASS);

    ftype = skBagKeyFieldType(bag);

    if (IS_IP_KEY(ftype)) {
        key->val.addr = SvIPADDR(aTHX_ sv);
        key->type = SKBAG_KEY_IPADDR;
    }
    else {
        if (SvPOK(sv))
            rv = _xs_pack_uint32_strint(aTHX_ sv, &u32);
        else
            rv = _xs_pack_uint32_int(aTHX_ sv, &u32);
        if (rv != GROKNUM_OK)
            GROKNUM_CROAK(rv, "invalid bag key");
        key->val.u32 = u32;
        key->type = SKBAG_KEY_U32;
    }
}

static SV *
newSvBAGKEY(pTHX_ skBagTypedKey_t *key) {
    switch (key->type) {
        case SKBAG_KEY_IPADDR:
        case SKBAG_KEY_ANY:
            return newSvIPADDR(aTHX_ &key->val.addr);
        case SKBAG_KEY_U32:
            return newSVuv(key->val.u32);
        case SKBAG_KEY_U16:
            return newSVuv(key->val.u16);
        case SKBAG_KEY_U8:
            return newSVuv(key->val.u8);
        default:
            croak("unknown bag key type %d", key->type);
    }
}

static skBagTypedCounter_t
SvBAGCNT(pTHX_ SV *sv) {
    skBagTypedCounter_t counter;
    groknum_err_t rv;

    if (!SvOK(sv))
        croak("invalid bag value (expected an integer,"
              " numeric string, or ref");

    counter.val.u64 = 0;
    counter.type = SKBAG_COUNTER_U64;

    if (SvPOK(sv))
        rv = _xs_pack_uint64_strint(aTHX_ sv, &counter.val.u64);
    else
        rv = _xs_pack_uint64_int(aTHX_ sv, &counter.val.u64);
    if (rv != GROKNUM_OK)
        GROKNUM_CROAK(rv, "invalid bag count");
    // counter max is not the same as UINT64_MAX
    if (counter.val.u64 > SKBAG_COUNTER_MAX)
        croak("invalid bag count: counter max overflow\n");
    return counter;
}

static SV *
newSvBAGCNT(pTHX_ skBagTypedCounter_t *counter) {
    switch (counter->type) {
        case SKBAG_COUNTER_U64:
            return newSVu64(counter->val.u64);
        case SKBAG_COUNTER_ANY:
            croak("uninitialized bag counter");
        default:
            croak("unknown bag counter type %d", counter->type);
    }
}

static skPrefixMapProtoPort_t
_xs_pmap_pp_from_svs(pTHX_ SV *proto, SV *port) {
    skPrefixMapProtoPort_t pp;
    IV val;

    val = SvIV(proto);
    if (val < 0 || val > UINT8_MAX)
        croak("invalid protocol (%i out of range 0-%u", (int)val, UINT8_MAX); 
    pp.proto = (uint8_t)val;
    val = SvIV(port);
    if (val < 0 || val > UINT16_MAX)
        croak("invalid port (%i out of range 0-%u)", (int)val, UINT16_MAX);
    pp.port = (uint16_t)val;
    return pp;
}

static skPrefixMapProtoPort_t
SvPROTOPORT(pTHX_ SV *sv) {
    skPrefixMapProtoPort_t pp;
    SV      *av;
    STRLEN   len;
    if (!SvOK(sv) || !SvROK(sv))
        croak("invalid proto/port (expected an array ref, int, or %s)",
              SILK_PROTOPORT_CLASS);
    av = SvRV(sv);
    if (SvTYPE(av) == SVt_PVMG) {
        if (! sv_derived_from(sv, SILK_PROTOPORT_CLASS))
            croak("invalid proto/port (not derived from %s)",
                  SILK_PROTOPORT_CLASS);
        pp = *(skPrefixMapProtoPort_t *)SvPV(av, len);
        return pp;
    }
    else if (SvTYPE(av) == SVt_PVAV) {
        SV **pproto;
        SV **pport;
        if (av_len((AV *)av) != 1)
            croak("proto pair does not have two elements");
        pproto = av_fetch((AV *)av, 0, 0);
        if (pproto == NULL)
            croak("invalid proto value in ref to array (undef)");
        pport = av_fetch((AV *)av, 1, 0);
        if (pport == NULL)
            croak("invalid port value in ref to array (undef)");
        return _xs_pmap_pp_from_svs(aTHX_ *pproto, *pport);
    }
    croak("invalid proto/port (expected ref to array or %s",
          SILK_PROTOPORT_CLASS);
}

static SV *
newSvPROTOPORT(pTHX_ skPrefixMapProtoPort_t ppp) {
    return sv_setref_pvn(newSV(0), SILK_PROTOPORT_CLASS,
                         (char *)&ppp, sizeof(ppp));
}

static uint16_t
SvTCPFLAGS(pTHX_ SV *rv) {
    skPrefixMapProtoPort_t pp;
    UV uv = 0;
    if (!SvOK(rv))
        croak("invalid value (expected a string, int, or ref to %s",
              SILK_TCPFLAGS_CLASS);
    if (SvROK(rv)) {
        if (! sv_derived_from(rv, SILK_TCPFLAGS_CLASS))
            croak("invalid flags ref (not derived from %s)",
                  SILK_TCPFLAGS_CLASS);
        uv = SvUV(SvRV(rv));
    } else if (SvPOK(rv)) {
        STRLEN len;
        char   *p;
        p = SvPV(rv, len);
        if (skStringParseTCPFlags((uint8_t *)&uv, p))
            croak("Illegal TCP flag value: %s", p);
    } else {
        uv = SvUV(rv);
    }
    if (uv > UINT8_MAX)
        croak("flags value out of range 0-%u", UINT8_MAX);
    return (uint8_t)uv;
}

static SV *
newSvTCPFLAGS(pTHX_ uint16_t flags) {
    return sv_setref_uv(newSV(0), SILK_TCPFLAGS_CLASS, flags);
}

static SV *
newSvRWREC(pTHX_ rwRec *rec) {
    return sv_setref_pvn(newSV(0), SILK_RWREC_CLASS,
                         (char *)rec, sizeof(*rec));
}


static void
_stream_croak(pTHX_ skstream_t *stream, ssize_t err) {
    char err_buffer[2 * PATH_MAX];
    skStreamLastErrMessage(stream, err, err_buffer, sizeof(err_buffer));
    croak("silk stream IO error: %s", err_buffer);
}


MODULE = Net::Silk    PACKAGE = Net::Silk     PREFIX = sk

BOOT:
// BOOT ends after first blank line outside of a block
{
    HV *stash;

    stash = gv_stashpv("Net::Silk", TRUE);

    MCE(SILK_IPV6_ENABLED, SK_ENABLE_IPV6);
    MCE(SILK_ZLIB_ENABLED, SK_ENABLE_ZLIB);
    MCE(SILK_LZO_ENABLED,  SK_ENABLE_LZO);
    MCE(SILK_LOCALTIME_ENABLED, SK_ENABLE_LOCALTIME);

    MATH_INT64_BOOT;
    PERL_MATH_INT128_LOAD;
}

void
module_init(appname)
    char *appname
    CODE:
        skAppRegister(appname);

void
module_destroy()
    CODE:
        skAppUnregister();


MODULE = Net::Silk    PACKAGE = Net::Silk::IPAddr     PREFIX = sk

PROTOTYPES: DISABLE

Net::Silk::IPAddr
new(CLASS, spec)
    const char   *CLASS
    Net::Silk::IPAddr spec
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = spec;
    OUTPUT:
    RETVAL

Net::Silk::IPAddr
from_str(CLASS, spec)
    const char  *CLASS
    const char  *spec
    PREINIT:
    int rv;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    rv = skStringParseIP(&RETVAL, spec);
    if (rv != SKUTILS_OK)
        croak("invalid ip (error %d parsing string: %s",
              rv, skStringParseStrerror(rv));
    OUTPUT:
    RETVAL

Net::Silk::IPv4Addr
_as_ipv4(THIS)
    Net::Silk::IPAddr THIS
    CODE:
    RETVAL = THIS;
    OUTPUT:
    RETVAL

Net::Silk::IPv6Addr
_as_ipv6(THIS)
    Net::Silk::IPAddr THIS
    CODE:
#if SK_ENABLE_IPV6
    skipaddrCopy(&RETVAL, &THIS);
    if (!skipaddrIsV6(&RETVAL)) {
        skipaddrV4toV6(&RETVAL, &RETVAL);
    }
#else
    croak("SiLK was not built with IPv6 support.");
#endif
    OUTPUT:
    RETVAL

char *
str(THIS, ...)
    Net::Silk::IPAddr THIS
    PREINIT:
    // the ... is necessary to throw off signature of CORE::str
    char buf[SK_NUM2DOT_STRLEN];
    CODE:
    skipaddrString(buf, &THIS, SKIPADDR_CANONICAL);
    RETVAL = buf;
    OUTPUT:
    RETVAL

char *
padded(THIS)
    Net::Silk::IPAddr THIS
    PREINIT:
    char buf[SK_NUM2DOT_STRLEN];
    CODE:
    skipaddrString(buf, &THIS, SKIPADDR_ZEROPAD);
    RETVAL = buf;
    OUTPUT:
    RETVAL

void
num(THIS, ...)
    Net::Silk::IPAddr THIS
    PPCODE:
#if SK_ENABLE_IPV6
    if (skipaddrIsV6(&THIS)) {
        uint8_t *u8 = THIS.ip_ip.ipu_ipv6;
        mXPUSHs(
            newSVu128((((((((((((((((((((((((((((((((uint128_t)u8[0]) << 8)
                                                  + (uint128_t)u8[1]) << 8)
                                                + (uint128_t)u8[2]) << 8)
                                              + (uint128_t)u8[3]) << 8)
                                            + (uint128_t)u8[4]) << 8)
                                          + (uint128_t)u8[5]) << 8)
                                        + (uint128_t)u8[6]) << 8)
                                      + (uint128_t)u8[7]) << 8)
                                    + (uint128_t)u8[8]) << 8)
                                  + (uint128_t)u8[9]) << 8)
                                + (uint128_t)u8[10]) << 8)
                              + (uint128_t)u8[11]) << 8)
                            + (uint128_t)u8[12]) << 8)
                          + (uint128_t)u8[13]) << 8)
                        + (uint128_t)u8[14]) << 8)
                      + (uint128_t)u8[15]));
    } else
#endif
    {
        mXPUSHu(skipaddrGetV4(&THIS));
    }

void
octets(THIS)
    Net::Silk::IPAddr THIS
    PREINIT:
    int i;
    PPCODE:
#if SK_ENABLE_IPV6
    if (skipaddrIsV6(&THIS)) {
        uint8_t v6[16];
        EXTEND(SP, 16);
        skipaddrGetV6(&THIS, v6);
        for (i = 0; i < 16; i++) {
            mPUSHu(v6[i]);
        }
    } else
#endif
    {
        uint32_t v4 = skipaddrGetV4(&THIS);
        EXTEND(SP, 4);
        mPUSHu(0);
        mPUSHu(0);
        mPUSHu(0);
        mPUSHu(0);
        sv_setuv(ST(3), v4 & 0xff);
        v4 >>= 8;
        sv_setuv(ST(2), v4 & 0xff);
        v4 >>= 8;
        sv_setuv(ST(1), v4 & 0xff);
        v4 >>= 8;
        sv_setuv(ST(0), v4 & 0xff);
    }

bool
is_ipv6(THIS)
    Net::Silk::IPAddr THIS
    CODE:
    RETVAL = skipaddrIsV6(&THIS);
    OUTPUT:
    RETVAL

void
country_code(THIS)
    Net::Silk::IPAddr THIS
    PREINIT:
    char name[3];
    sk_countrycode_t code;
    int rv;
    PPCODE:
    rv = skCountrySetup(NULL, error_printf);
    if (rv != 0)
        croak("%s", error_buffer);
    code = skCountryLookupCode(&THIS);
    if (code != SK_COUNTRYCODE_INVALID)
        skCountryCodeToName(code, name, sizeof(name));
        mXPUSHs(newSVpvn(name, sizeof(name)));


MODULE = Net::Silk    PACKAGE = Net::Silk::IPv4Addr     PREFIX = sk

Net::Silk::IPv4Addr
new(CLASS, spec)
    const char *CLASS
    Net::Silk::IPv4Addr spec
    PREINIT:
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = spec;
    if (skipaddrIsV6(&RETVAL)) {
        int rv = skipaddrV6toV4(&RETVAL, &RETVAL);
        if (rv < 0)
            croak("invalid ipv6 address");
    }
    OUTPUT:
    RETVAL

Net::Silk::IPv4Addr
from_str(CLASS, spec)
    const char  *CLASS
    const char  *spec
    PREINIT:
    int rv;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    rv = skStringParseIP(&RETVAL, spec);
    if (rv != SKUTILS_OK)
        croak("invalid ipv4 (error %d parsing string: %s)",
              rv, skStringParseStrerror(rv));
    if (skipaddrIsV6(&RETVAL)) {
        int rv = skipaddrV6toV4(&RETVAL, &RETVAL);
        if (rv < 0)
            croak("invalid ipv4 address");
    }
    OUTPUT:
    RETVAL

Net::Silk::IPv4Addr
from_int(CLASS, val)
    const char *CLASS
    SV         *val
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = SvNumIPV4ADDR(aTHX_ val);
    if (skipaddrIsV6(&RETVAL)) {
        int rv = skipaddrV6toV4(&RETVAL, &RETVAL);
        if (rv < 0)
            croak("invalid ipv4 numeric address");
    }
    OUTPUT:
    RETVAL

Net::Silk::IPv4Addr
mask_prefix(THIS, prefix)
    Net::Silk::IPAddr THIS
    int          prefix
    CODE:
    if (prefix < 0 || prefix > 32)
        croak("invalid prefix (%d out of range 0-32)", prefix);
    skipaddrCopy(&RETVAL, &THIS);
    skipaddrApplyCIDR(&RETVAL, prefix);
    OUTPUT:
    RETVAL

int
_xs_cmp(THIS, other)
    Net::Silk::IPAddr   THIS
    Net::Silk::IPv4Addr other
    CODE:
    RETVAL = skipaddrCompare(&THIS, &other);
    OUTPUT:
    RETVAL

Net::Silk::IPv4Addr
_xs_mask(THIS, mask)
    Net::Silk::IPAddr   THIS
    Net::Silk::IPv4Addr mask
    CODE:
    skipaddrCopy(&RETVAL, &THIS);
    skipaddrMask(&RETVAL, &mask);
    OUTPUT:
    RETVAL


MODULE = Net::Silk    PACKAGE = Net::Silk::IPv6Addr     PREFIX = sk

Net::Silk::IPv6Addr
new(CLASS, spec)
    const char *CLASS
    Net::Silk::IPv6Addr spec
    CODE:
    PERL_UNUSED_VAR(CLASS);
#if SK_ENABLE_IPV6
    RETVAL = spec;
    if (! skipaddrIsV6(&RETVAL))
        skipaddrV4toV6(&RETVAL, &RETVAL);
#else
    croak("SiLK was not built with IPv6 support");
#endif
    OUTPUT:
    RETVAL

Net::Silk::IPv6Addr
from_int(CLASS, val)
    const char *CLASS
    SV         *val
    CODE:
    PERL_UNUSED_VAR(CLASS);
#if SK_ENABLE_IPV6
    RETVAL = SvNumIPV6ADDR(aTHX_ val);
    if (! skipaddrIsV6(&RETVAL))
        skipaddrV4toV6(&RETVAL, &RETVAL);
#else
    croak("SiLK was not built with IPv6 support");
#endif
    OUTPUT:
    RETVAL

Net::Silk::IPv6Addr
mask_prefix(THIS, prefix)
    Net::Silk::IPAddr THIS
    int          prefix
    PREINIT:
    //char buf[80];
    CODE:
#if SK_ENABLE_IPV6
    if (prefix < 0 || prefix > 128)
        croak("invalid prefix (%d out of range 0-128)", prefix);
    skipaddrCopy(&RETVAL, &THIS);
    skipaddrApplyCIDR(&RETVAL, prefix);
#else
    croak("SiLK was not built with IPv6 support");
#endif
    OUTPUT:
    RETVAL

int
_xs_cmp(THIS, other)
    Net::Silk::IPAddr   THIS
    Net::Silk::IPv6Addr other
    CODE:
    RETVAL = skipaddrCompare(&THIS, &other);
    OUTPUT:
    RETVAL

Net::Silk::IPv6Addr
_xs_mask(THIS, mask)
    Net::Silk::IPAddr   THIS
    Net::Silk::IPv6Addr mask
    CODE:
    skipaddrCopy(&RETVAL, &THIS);
    skipaddrMask(&RETVAL, &mask);
    OUTPUT:
    RETVAL

MODULE = Net::Silk    PACKAGE = Net::Silk::ProtoPort     PREFIX = sk

PROTOTYPES: DISABLE

Net::Silk::ProtoPort
init(CLASS, proto, port)
    const char *CLASS
    SV         *proto
    SV         *port
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = _xs_pmap_pp_from_svs(aTHX_ proto, port);
    OUTPUT:
    RETVAL

void
_set_proto(THIS, proto)
    Net::Silk::ProtoPort THIS
    uint16_t proto
    CODE:
    THIS.proto = proto;

void
_set_port(THIS, port)
    Net::Silk::ProtoPort THIS
    uint8_t port
    CODE:
    THIS.port = port;

uint8_t
_get_proto(THIS)
    Net::Silk::ProtoPort THIS
    CODE:
    RETVAL = THIS.proto;
    OUTPUT:
    RETVAL

uint16_t
_get_port(THIS)
    Net::Silk::ProtoPort THIS
    CODE:
    RETVAL = THIS.port;
    OUTPUT:
    RETVAL

Net::Silk::ProtoPort
_xs_add(THIS, num)
    Net::Silk::ProtoPort THIS
    uint32_t num
    PREINIT:
    uint32_t total;
    CODE:
    total   = THIS.proto;
    total <<= 16;
    total  += THIS.port;
    total  += num;
    if (total & 0xfff00000)
        croak("error: proto/port overflow");
    RETVAL.proto = (total & 0xff0000) >> 16;
    RETVAL.port  = total & 0x0ffff;
    OUTPUT:
    RETVAL

Net::Silk::ProtoPort
_xs_sub(THIS, num)
    Net::Silk::ProtoPort THIS
    uint32_t        num
    PREINIT:
    uint32_t total;
    CODE:
    total   = THIS.proto;
    total <<= 16;
    total  += THIS.port;
    total  -= num;
    if (total & 0xfff00000)
        croak("error: proto/port underflow");
    RETVAL.proto = (total & 0xff0000) >> 16;
    RETVAL.port  = total & 0x0ffff;
    OUTPUT:
    RETVAL

uint32_t
num(THIS)
    Net::Silk::ProtoPort THIS
    CODE:
    RETVAL   = THIS.proto;
    RETVAL <<= 16;
    RETVAL  += THIS.port;
    OUTPUT:
    RETVAL


MODULE = Net::Silk    PACKAGE = Net::Silk::IPWildcard::iter_xs     PREFIX = sk

PROTOTYPES: DISABLE

Net::Silk::IPWildcard::iter_xs
bind(CLASS, wc)
    const char *CLASS
    SV         *wc
    PREINIT:
    STRLEN  len;
    char   *s;
    int     rv;
    skIPWildcardIterator_t iter;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    if (!SvOK(wc))
    if (!SvOK(wc) && !SvROK(wc))
        croak("invalid ip (expected a reference to %s)",
              SILK_IPWILDCARD_CLASS);
    if (! SvROK(wc) || ! sv_derived_from(wc, SILK_IPWILDCARD_CLASS))
        croak("invalid ip (not a %s derived reference)",
              SILK_IPWILDCARD_CLASS);
    s = SvPV(SvRV(wc), len);
    if (len != sizeof(skIPWildcard_t))
        croak("invalid ip (size %lu of packed data != %lu of skIPWildcard_t)",
                len, sizeof(skIPWildcard_t));
    rv = skIPWildcardIteratorBind(&iter, (skIPWildcard_t *)s);
    if (rv != 0)
        croak("error %d binding wildcard iterator", rv);
    RETVAL = &iter;
    OUTPUT:
    RETVAL

void
next(THIS)
    Net::Silk::IPWildcard::iter_xs THIS
    PREINIT:
    skipaddr_t         raw_addr;
    skIteratorStatus_t rv;
    PPCODE:
    rv = skIPWildcardIteratorNext(THIS, &raw_addr);
    if (rv != SK_ITERATOR_NO_MORE_ENTRIES)
        mXPUSHs(newSvIPADDR(aTHX_ &raw_addr));

void
next_cidr(THIS)
    Net::Silk::IPWildcard::iter_xs THIS
    PREINIT:
    skipaddr_t         raw_addr;
    uint32_t           raw_prefix;
    skIteratorStatus_t rv;
    PPCODE:
    rv = skIPWildcardIteratorNextCidr(THIS, &raw_addr, &raw_prefix);
    if (rv != SK_ITERATOR_NO_MORE_ENTRIES) {
        mXPUSHs(newSvIPADDR(aTHX_ &raw_addr));
        mXPUSHu(raw_prefix);
    }


MODULE = Net::Silk    PACKAGE = Net::Silk::IPWildcard     PREFIX = sk

Net::Silk::IPWildcard
new(CLASS, spec)
    const char       *CLASS
    Net::Silk::IPWildcard  spec
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = spec;
    OUTPUT:
    RETVAL

bool
contains(THIS, addr)
    Net::Silk::IPWildcard THIS
    Net::Silk::IPAddr     addr
    CODE:
    RETVAL = skIPWildcardCheckIp(&THIS, &addr) ? 1 : 0;
    OUTPUT:
    RETVAL

bool
is_ipv6(THIS)
    Net::Silk::IPWildcard THIS
    CODE:
    RETVAL = skIPWildcardIsV6(&THIS);
    OUTPUT:
    RETVAL

void
_cardinality(THIS)
    Net::Silk::IPWildcard THIS
    PREINIT:
    int      i, j;
    uint8_t  bitcount;
    uint32_t bittotal;
    bool     gtzero = 0;
#if SK_ENABLE_IPV6
    uint128_t total;
#else
    uint64_t  total;
#endif
    PPCODE:
    total = 0;
    for (i = 0; i < THIS.num_blocks; ++i) {
        bittotal = 0;
        for (j = THIS.m_min[i] >> 5; j <= THIS.m_max[i] >> 5; ++j) {
            BITS_IN_WORD32(&bitcount, THIS.m_blocks[i][j]);
            bittotal += bitcount;
        }
        if (total == 0)
#if SK_ENABLE_IPV6
            total = (uint128_t)bittotal;
#else
            total = (uint64_t)bittotal;
#endif
        else
            total *= bittotal;
        if (total > 1)
            gtzero = 1;
    }
    if (total == 0 && gtzero)
        croak("cardinality overflow");
#if SK_ENABLE_IPV6
    mXPUSHs(newSVu128(total));
#else
    mXPUSHs(newSVu64(total));
#endif


MODULE = Net::Silk    PACKAGE = Net::Silk::IPSet::iter_xs     PREFIX = sk

PROTOTYPES: DISABLE

Net::Silk::IPSet::iter_xs
bind(CLASS, ipset, cidr_blocks=0)
    const char  *CLASS
    Net::Silk::IPSet  ipset
    unsigned     cidr_blocks
    PREINIT:
    skipset_iterator_t iter;
    int rv;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = &iter;
    skIPSetClean(ipset);
    if (cidr_blocks)
        rv = skIPSetIteratorBind(RETVAL, ipset, 1, SK_IPV6POLICY_MIX);
    else
        rv = skIPSetIteratorBind(RETVAL, ipset, 0, SK_IPV6POLICY_MIX);
    if (rv != SKIPSET_OK)
        croak("error binding iterator %d: %s", rv, skIPSetStrerror(rv));
    OUTPUT:
    RETVAL

void
next(THIS)
    Net::Silk::IPSet::iter_xs THIS
    PREINIT:
    skipaddr_t  raw_addr;
    uint32_t    raw_prefix;
    int         rv;
    PPCODE:
    rv = skIPSetIteratorNext(THIS, &raw_addr, &raw_prefix);
    if (rv != SK_ITERATOR_NO_MORE_ENTRIES) {
        mXPUSHs(newSvIPADDR(aTHX_ &raw_addr));
        if (THIS->cidr_blocks)
            mXPUSHu(raw_prefix);
    }


MODULE = Net::Silk    PACKAGE = Net::Silk::IPSet           PREFIX = sk

PROTOTYPES: DISABLE

Net::Silk::IPSet
_new(CLASS)
    const char *CLASS
    PREINIT:
    skipset_t  *ipset;
    int         rv;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    rv = skIPSetCreate(&ipset, 0);
    if (rv != SKIPSET_OK)
        croak("error creating ipset: %s", skIPSetStrerror(rv));
    RETVAL = ipset;
    OUTPUT:
    RETVAL

Net::Silk::IPSet
load(CLASS, fname)
    const char *CLASS
    const char *fname
    PREINIT:
    int         rv;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    rv = skIPSetLoad(&RETVAL, fname);
    if (rv != SKIPSET_OK)
        croak("error %d loading ipset from %s: %s",
               rv, fname, skIPSetStrerror(rv));
    OUTPUT:
    RETVAL

bool
supports_ipv6(CLASS)
    const char *CLASS
    CODE:
    PERL_UNUSED_VAR(CLASS);
#if SK_ENABLE_IPV6
    RETVAL = 1;
#else
    RETVAL = 0;
#endif
    OUTPUT:
    RETVAL

void
save(THIS, fname)
    Net::Silk::IPSet THIS
    const char *fname
    PREINIT:
    int rv;
    CODE:
    skIPSetClean(THIS);
    rv = skIPSetSave(THIS, fname);
    if (rv != SKIPSET_OK)
        croak("error %d saving ipset to %s: %s",
              rv, fname, skIPSetStrerror(rv));

void
clean(THIS)
    Net::Silk::IPSet THIS
    PREINIT:
    int rv;
    CODE:
    rv = skIPSetClean(THIS);
    if (rv != SKIPSET_OK)
        croak("error %d cleaning ipset: %s", rv, skIPSetStrerror(rv));

void
_destroy(THIS)
    Net::Silk::IPSet THIS
    CODE:
    skIPSetDestroy(&THIS);

bool
contains(THIS, addr)
    Net::Silk::IPSet  THIS
    Net::Silk::IPAddr addr
    PREINIT:
    int rv;
    CODE:
    rv = skIPSetCheckAddress(THIS, &addr);
    RETVAL = rv ? 1 : 0;
    OUTPUT:
    RETVAL

uint64_t
_cardinality(THIS)
    Net::Silk::IPSet THIS
    CODE:
    skIPSetClean(THIS);
    RETVAL = skIPSetCountIPs(THIS, NULL);
    if (RETVAL == UINT64_MAX)
        croak("cardinality overflow");
    OUTPUT:
    RETVAL

char *
_cardinality_as_str(THIS)
    Net::Silk::IPSet THIS
    PREINIT:
    char buf[40];
    CODE:
    skIPSetClean(THIS);
    skIPSetCountIPsString(THIS, buf, 40);
    RETVAL = buf;
    OUTPUT:
    RETVAL

bool
_is_disjoint_set(THIS, other)
    Net::Silk::IPSet THIS
    Net::Silk::IPSet other
    CODE:
    RETVAL = !skIPSetCheckIPSet(THIS, other);
    OUTPUT:
    RETVAL

bool
_is_disjoint_wildcard(THIS, other)
    Net::Silk::IPSet       THIS
    Net::Silk::IPWildcard  other
    CODE:
    RETVAL = !skIPSetCheckIPWildcard(THIS, &other);
    OUTPUT:
    RETVAL

void
add_addr(THIS, addr, ...)
    Net::Silk::IPSet  THIS
    Net::Silk::IPAddr addr
    PREINIT:
    uint32_t prefix;
    int      rv;
    CODE:
    if (items > 2) {
        prefix = SvUV(ST(2));
    }
    else {
        prefix = skipaddrIsV6(&addr) ? 128 : 32;
    }
    rv = skIPSetInsertAddress(THIS, &addr, prefix);
    if (rv != SKIPSET_OK)
        croak("error %d adding ip: %s", rv, skIPSetStrerror(rv));

void
add_wildcard(THIS, other)
    Net::Silk::IPSet       THIS
    Net::Silk::IPWildcard  other
    PREINIT:
    int rv;
    CODE:
    rv = skIPSetInsertIPWildcard(THIS, &other);
    if (rv == SKIPSET_ERR_IPV6)
        croak("error adding wildcard (must only include ipv4 addresses)");
    if (rv != SKIPSET_OK)
        croak("error %d adding wildcard: %s", rv, skIPSetStrerror(rv));

void
_add_range(THIS, lo, hi)
    Net::Silk::IPSet  THIS
    Net::Silk::IPAddr lo
    Net::Silk::IPAddr hi
    PREINIT:
    int rv;
    CODE:
    rv = skIPSetInsertRange(THIS, &lo, &hi);
    if (rv != SKIPSET_OK)
        croak("error %d adding ip range: %s", rv, skIPSetStrerror(rv));

void
_union_update(THIS, other)
    Net::Silk::IPSet THIS
    Net::Silk::IPSet other
    PREINIT:
    int rv;
    CODE:
    skIPSetClean(THIS);
    skIPSetClean(other);
    rv = skIPSetUnion(THIS, other);
    if (rv != SKIPSET_OK)
        croak("error %d updating: %s", rv, skIPSetStrerror(rv));

void
_intersection_update(THIS, other)
    Net::Silk::IPSet THIS
    Net::Silk::IPSet other
    CODE:
    skIPSetClean(THIS);
    skIPSetClean(other);
    skIPSetIntersect(THIS, other);

void
_difference_update(THIS, other)
    Net::Silk::IPSet THIS
    Net::Silk::IPSet other
    CODE:
    skIPSetClean(THIS);
    skIPSetClean(other);
    skIPSetSubtract(THIS, other);

void
remove_addr(THIS, addr)
    Net::Silk::IPSet  THIS
    Net::Silk::IPAddr addr
    PREINIT:
    int rv;
    CODE:
    rv = skIPSetRemoveAddress(THIS, &addr,
                              skipaddrIsV6(&addr) ? 128 : 32);
    if (rv != SKIPSET_OK)
        croak("error %d removing ip: %s", rv, skIPSetStrerror(rv));

void
remove_wildcard(THIS, other)
    Net::Silk::IPSet      THIS
    Net::Silk::IPWildcard other
    PREINIT:
    int rv;
    CODE:
    rv = skIPSetRemoveIPWildcard(THIS, &other);
    if (rv != SKIPSET_OK)
        croak("error %d removing wildcard: %s", rv, skIPSetStrerror(rv));

void
clear(THIS)
    Net::Silk::IPSet THIS
    CODE:
    skIPSetRemoveAll(THIS);


MODULE = Net::Silk    PACKAGE = Net::Silk::Bag::iter_xs     PREFIX = sk

Net::Silk::Bag::iter_xs
bind(CLASS, bag, sorted=0)
    const char *CLASS
    Net::Silk::Bag   bag
    bool        sorted
    PREINIT:
    skBagErr_t        rv;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    if (sorted)
        rv = skBagIteratorCreate(bag, &RETVAL);
    else
        rv = skBagIteratorCreateUnsorted(bag, &RETVAL);
    if (rv != SKBAG_OK)
        croak("error %d binding bag: %s", rv, skBagStrerror(rv));
    OUTPUT:
    RETVAL

void
DESTROY(THIS)
    Net::Silk::Bag::iter_xs THIS
    CODE:
    skBagIteratorDestroy(THIS);

void
next(THIS, key_type, counter_type)
    Net::Silk::Bag::iter_xs  THIS
    skBagKeyType_t      key_type
    skBagCounterType_t  counter_type
    PREINIT:
    skBagTypedKey_t     key;
    skBagTypedCounter_t counter;
    skBagErr_t          rv;
    PPCODE:
    key.type     = key_type;
    counter.type = counter_type;
    rv = skBagIteratorNextTyped(THIS, &key, &counter);
    if (rv != SKBAG_ERR_KEY_NOT_FOUND) {
        if (rv != SKBAG_OK)
            croak("error %d bag next: %s", rv, skBagStrerror(rv));
        mXPUSHs(newSvBAGKEY(aTHX_ &key));
        mXPUSHs(newSVu64(counter.val.u64));
    }


MODULE = Net::Silk    PACKAGE = Net::Silk::Bag             PREFIX = sk

BOOT:
// BOOT ends after first blank line outside of a block
{
    HV *stash;

    stash = gv_stashpv("Net::Silk::Bag", TRUE);

    MCE(SILK_BAG_KEY_ANY,    SKBAG_KEY_ANY);
    MCE(SILK_BAG_KEY_U8,     SKBAG_KEY_U8);
    MCE(SILK_BAG_KEY_U16,    SKBAG_KEY_U16);
    MCE(SILK_BAG_KEY_U32,    SKBAG_KEY_U32);
    MCE(SILK_BAG_KEY_IPADDR, SKBAG_KEY_IPADDR);

    MCE(SILK_BAG_COUNTER_ANY, SKBAG_COUNTER_ANY);
    MCE(SILK_BAG_COUNTER_U64, SKBAG_COUNTER_U64);

    MCE(SILK_BAG_FIELD_SIPv4,          SKBAG_FIELD_SIPv4);
    MCE(SILK_BAG_FIELD_DIPv4,          SKBAG_FIELD_DIPv4);
    MCE(SILK_BAG_FIELD_SPORT,          SKBAG_FIELD_SPORT);
    MCE(SILK_BAG_FIELD_DPORT,          SKBAG_FIELD_DPORT);
    MCE(SILK_BAG_FIELD_PROTO,          SKBAG_FIELD_PROTO);
    MCE(SILK_BAG_FIELD_PACKETS,        SKBAG_FIELD_PACKETS);
    MCE(SILK_BAG_FIELD_BYTES,          SKBAG_FIELD_BYTES);
    MCE(SILK_BAG_FIELD_FLAGS,          SKBAG_FIELD_FLAGS);
    MCE(SILK_BAG_FIELD_STARTTIME,      SKBAG_FIELD_STARTTIME);
    MCE(SILK_BAG_FIELD_ELAPSED,        SKBAG_FIELD_ELAPSED);
    MCE(SILK_BAG_FIELD_ENDTIME,        SKBAG_FIELD_ENDTIME);
    MCE(SILK_BAG_FIELD_SID,            SKBAG_FIELD_SID);
    MCE(SILK_BAG_FIELD_INPUT,          SKBAG_FIELD_INPUT);
    MCE(SILK_BAG_FIELD_OUTPUT,         SKBAG_FIELD_OUTPUT);
    MCE(SILK_BAG_FIELD_NHIPv4,         SKBAG_FIELD_NHIPv4);
    MCE(SILK_BAG_FIELD_INIT_FLAGS,     SKBAG_FIELD_INIT_FLAGS);
    MCE(SILK_BAG_FIELD_REST_FLAGS,     SKBAG_FIELD_REST_FLAGS);
    MCE(SILK_BAG_FIELD_TCP_STATE,      SKBAG_FIELD_TCP_STATE);
    MCE(SILK_BAG_FIELD_APPLICATION,    SKBAG_FIELD_APPLICATION);
    MCE(SILK_BAG_FIELD_FTYPE_CLASS,    SKBAG_FIELD_FTYPE_CLASS);
    MCE(SILK_BAG_FIELD_FTYPE_TYPE,     SKBAG_FIELD_FTYPE_TYPE);
    MCE(SILK_BAG_FIELD_ICMP_TYPE_CODE, SKBAG_FIELD_ICMP_TYPE_CODE);
    MCE(SILK_BAG_FIELD_SIPv6,          SKBAG_FIELD_SIPv6);
    MCE(SILK_BAG_FIELD_DIPv6,          SKBAG_FIELD_DIPv6);
    MCE(SILK_BAG_FIELD_NHIPv6,         SKBAG_FIELD_NHIPv6);
    MCE(SILK_BAG_FIELD_RECORDS,        SKBAG_FIELD_RECORDS);
    MCE(SILK_BAG_FIELD_SUM_PACKETS,    SKBAG_FIELD_SUM_PACKETS);
    MCE(SILK_BAG_FIELD_SUM_BYTES,      SKBAG_FIELD_SUM_BYTES);
    MCE(SILK_BAG_FIELD_SUM_ELAPSED,    SKBAG_FIELD_SUM_ELAPSED);
    MCE(SILK_BAG_FIELD_ANY_PORT,       SKBAG_FIELD_ANY_PORT);
    MCE(SILK_BAG_FIELD_ANY_SNMP,       SKBAG_FIELD_ANY_SNMP);
    MCE(SILK_BAG_FIELD_ANY_TIME,       SKBAG_FIELD_ANY_TIME);
    MCE(SILK_BAG_FIELD_CUSTOM,         SKBAG_FIELD_CUSTOM);
    MCE(SILK_BAG_FIELD_ANY_IPv4,       SKBAG_FIELD_ANY_IPv4);
    MCE(SILK_BAG_FIELD_ANY_IPv6,       SKBAG_FIELD_ANY_IPv6);
}

PROTOTYPES: DISABLE

char *
_field_type_label(CLASS, field)
    const char       *CLASS
    skBagFieldType_t  field
    PREINIT:
    char buf[80];
    CODE:
    PERL_UNUSED_VAR(CLASS);
    skBagFieldTypeAsString(field, buf, sizeof(buf));
    RETVAL = buf;
    OUTPUT:
    RETVAL

skBagFieldType_t
_field_type_lookup(CLASS, name)
    const char *CLASS
    const char *name
    PREINIT:
    size_t           field_size;
    skBagErr_t       rv;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    rv = skBagFieldTypeLookup(name, &RETVAL, &field_size);
    if (rv != SKBAG_OK)
        croak("error %d bag field type lookup: %s", rv, skBagStrerror(rv));
    OUTPUT:
    RETVAL

skBagFieldType_t
_type_merge(CLASS, a_type, b_type)
    const char       *CLASS
    skBagFieldType_t  a_type
    skBagFieldType_t  b_type
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = skBagFieldTypeMerge(a_type, b_type);
    OUTPUT:
    RETVAL
    
void
_destroy(THIS)
    Net::Silk::Bag THIS
    CODE:
    skBagDestroy(&THIS);

Net::Silk::Bag
init(CLASS, key_type, key_size, counter_type, counter_size)
    const char       *CLASS
    skBagFieldType_t  key_type
    unsigned          key_size
    skBagFieldType_t  counter_type
    unsigned          counter_size
    PREINIT:
    skBagErr_t       rv;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    if (key_type == SKBAG_FIELD_CUSTOM && key_size == 0)
        key_size = 4;
    if (counter_type == SKBAG_FIELD_CUSTOM && counter_size == 0)
        counter_size = 8;
    rv = skBagCreateTyped(&RETVAL, key_type, counter_type,
                                key_size, counter_size);
    if (rv != SKBAG_OK)
        croak("error %d bag init: %s", rv, skBagStrerror(rv));
    skBagAutoConvertDisable(RETVAL);
    OUTPUT:
    RETVAL

Net::Silk::Bag
load(CLASS, fname)
    const char *CLASS
    const char *fname
    PREINIT:
    skBagErr_t rv;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    rv = skBagLoad(&RETVAL, fname);
    if (rv != SKBAG_OK)
        croak("error %d reading bag from %s: %s",
               rv, fname, skBagStrerror(rv));
    OUTPUT:
    RETVAL

void
save(THIS, fname)
    Net::Silk::Bag   THIS
    const char *fname
    PREINIT:
    skBagErr_t rv;
    CODE:
    rv = skBagSave(THIS, fname);
    if (rv != SKBAG_OK)
        croak("error %d saving bag to %s: %s",
               rv, fname, skBagStrerror(rv));

Net::Silk::Bag
copy(THIS)
    Net::Silk::Bag THIS
    PREINIT:
    skBagErr_t rv;
    CODE:
    rv = skBagCopy(&RETVAL, THIS);
    if (rv != SKBAG_OK)
        croak("error %d bag copy: %s", rv, skBagStrerror(rv));
    OUTPUT:
    RETVAL

void
_copy_from(THIS, other)
    SV             *THIS
    Net::Silk::Bag  other
    PREINIT:
    skBag_t    *new;
    skBagErr_t  rv;
    CODE:
    if (! SvROK(THIS) || ! sv_derived_from(THIS, SILK_BAG_CLASS))
        croak("error bag copy_from (not a %s reference)", SILK_BAG_CLASS);
    rv = skBagCopy(&new, other);
    if (rv != SKBAG_OK)
        croak("error %d bag copy: %s", rv, skBagStrerror(rv));
    // note: this triggers _destroy() for old SV
    sv_setref_pv(THIS, SILK_BAG_CLASS, new);

void
clear(THIS)
    SV *THIS
    PREINIT:
    skBagErr_t rv;
    skBagFieldType_t key, value;
    size_t keylen, valuelen;
    skBag_t *bag;
    CODE:
    if (! SvROK(THIS) || ! sv_derived_from(THIS, SILK_BAG_CLASS))
        croak("error bag clear (not a %s reference)", SILK_BAG_CLASS);
    bag = INT2PTR(skBag_t*, SvIV(SvRV(THIS)));
    key      = skBagKeyFieldType(bag);
    keylen   = skBagKeyFieldLength(bag);
    value    = skBagCounterFieldType(bag);
    valuelen = skBagCounterFieldLength(bag);
    rv = skBagCreateTyped(&bag, key, value, keylen, valuelen);
    if (rv != SKBAG_OK)
        croak("error allocating bag");
    // note: this triggers _destroy() for old SV
    sv_setref_pv(THIS, SILK_BAG_CLASS, bag);

uint64_t
_cardinality(THIS)
    Net::Silk::Bag THIS
    CODE:
    RETVAL = skBagCountKeys(THIS);
    OUTPUT:
    RETVAL

bool
_autoconvert_enabled(THIS)
    Net::Silk::Bag THIS
    CODE:
    RETVAL = skBagAutoConvertIsEnabled(THIS);
    OUTPUT:
    RETVAL

void
_autoconvert_enable(THIS)
    Net::Silk::Bag THIS
    CODE:
    skBagAutoConvertEnable(THIS);

void
_autoconvert_disable(THIS)
    Net::Silk::Bag THIS
    CODE:
    skBagAutoConvertDisable(THIS);

void
_bag_info(THIS)
    Net::Silk::Bag THIS
    PREINIT:
    skBagFieldType_t type;
    size_t           len; 
    char             buf[80];
    PPCODE:
    type = skBagKeyFieldName(THIS, buf, sizeof(buf));
    len  = skBagKeyFieldLength(THIS);
    mXPUSHu(type);
    mXPUSHu(len);
    if (IS_IP_KEY(type)) {
        mXPUSHu(SKBAG_KEY_IPADDR);
    }
    else {
        switch(len) {
            case 4:
                mXPUSHu(SKBAG_KEY_U32);
                break;
            case 2:
                mXPUSHu(SKBAG_KEY_U16);
                break;
            case 1:
                mXPUSHu(SKBAG_KEY_U8);
                break;
            default:
                mXPUSHu(SKBAG_KEY_U32);
        }
    }
    mXPUSHs(newSVpv(buf, 0));
    type = skBagCounterFieldName(THIS, buf, sizeof(buf));
    len  = skBagCounterFieldLength(THIS);
    mXPUSHu(type);
    mXPUSHu(len);
    mXPUSHu(SKBAG_COUNTER_U64);
    mXPUSHs(newSVpv(buf, 0));

void
_modify(THIS, ktype, ctype, klen, clen)
    Net::Silk::Bag        THIS
    skBagFieldType_t ktype
    skBagFieldType_t ctype
    size_t           klen
    size_t           clen
    PREINIT:
    skBagErr_t rv;
    CODE:
    rv = skBagModify(THIS, ktype, ctype, klen, clen);
    if (rv != SKBAG_OK)
        croak("error bag setting info: %d", rv);

bool
_is_ipaddr(THIS)
    Net::Silk::Bag THIS
    CODE:
    RETVAL = IS_IP_KEY(skBagKeyFieldType(THIS)) || \
             skBagCounterFieldLength(THIS) == 16;
    OUTPUT:
    RETVAL

skBagTypedCounter_t
_set_val(THIS, sv_key, val)
    Net::Silk::Bag       THIS
    SV                  *sv_key
    skBagTypedCounter_t  val
    PREINIT:
    skBagTypedKey_t key;
    skBagErr_t      rv;
    CODE:
    _sv_pack_bagkey(aTHX_ THIS, sv_key, &key);
    rv = skBagCounterSet(THIS, &key, &val);
    if (rv != SKBAG_OK)
        croak("error bag %d: %s", rv, skBagStrerror(rv));
    RETVAL = val;
    OUTPUT:
    RETVAL

skBagTypedCounter_t
_incr_val(THIS, sv_key, val)
    Net::Silk::Bag       THIS
    SV                  *sv_key
    skBagTypedCounter_t  val
    PREINIT:
    skBagTypedKey_t     key;
    skBagTypedCounter_t new;
    skBagErr_t          rv;
    CODE:
    _sv_pack_bagkey(aTHX_ THIS, sv_key, &key);
    rv = skBagCounterAdd(THIS, &key, &val, &new);
    if (rv != SKBAG_OK)
        croak("error bag %d: %s", rv, skBagStrerror(rv));
    RETVAL = new;
    OUTPUT:
    RETVAL

skBagTypedCounter_t
_decr_val(THIS, sv_key, val)
    Net::Silk::Bag       THIS
    SV                  *sv_key
    skBagTypedCounter_t  val
    PREINIT:
    skBagTypedKey_t     key;
    skBagTypedCounter_t new;
    skBagErr_t          rv;
    CODE:
    _sv_pack_bagkey(aTHX_ THIS, sv_key, &key);
    rv = skBagCounterSubtract(THIS, &key, &val, &new);
    if (rv != SKBAG_OK)
        croak("error bag %d: %s", rv, skBagStrerror(rv));
    RETVAL = new;
    OUTPUT:
    RETVAL

skBagTypedCounter_t
_get_val(THIS, sv_key)
    Net::Silk::Bag  THIS
    SV             *sv_key
    PREINIT:
    skBagTypedKey_t     key;
    skBagTypedCounter_t val;
    skBagErr_t          rv;
    CODE:
    _sv_pack_bagkey(aTHX_ THIS, sv_key, &key);
    rv = skBagCounterGet(THIS, &key, &val);
    if (rv != SKBAG_OK)
        croak("error bag %d: %s", rv, skBagStrerror(rv));
    RETVAL = val;
    OUTPUT:
    RETVAL


void
_add_bag(THIS, other)
    Net::Silk::Bag THIS
    Net::Silk::Bag other
    PREINIT:
    skBagErr_t rv;
    CODE:
    rv = skBagAddBag(THIS, other, NULL, NULL);
    if (rv != SKBAG_OK)
        croak("error %d bag add bag: %s", rv, skBagStrerror(rv));


MODULE = Net::Silk    PACKAGE = Net::Silk::Pmap::iter_xs     PREFIX = sk

Net::Silk::Pmap::iter_xs
bind(CLASS, pmap)
    const char *CLASS
    Net::Silk::Pmap  pmap
    PREINIT:
    int rv;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    rv = skPrefixMapIteratorCreate(&RETVAL, pmap);
    if (rv != 0)
        croak("error binding prefix map iterator %d", rv);
    OUTPUT:
    RETVAL

void
DESTROY(THIS)
    Net::Silk::Pmap::iter_xs THIS
    CODE:
    skPrefixMapIteratorDestroy(&THIS);

void
next_ip(THIS)
    Net::Silk::Pmap::iter_xs     THIS
    PREINIT:
    uint32_t           val;
    skipaddr_t         lo;
    skipaddr_t         hi;
    skIteratorStatus_t rv;
    PPCODE:
    rv = skPrefixMapIteratorNext(THIS, &lo, &hi, &val);
    if (rv != SK_ITERATOR_NO_MORE_ENTRIES) {
        if (rv != SK_ITERATOR_OK)
            croak("error %d pmap iterator", rv);
        mXPUSHs(newSvIPADDR(aTHX_ &lo));
        mXPUSHs(newSvIPADDR(aTHX_ &hi));
        mXPUSHu(val);
    }

void
next_pp(THIS)
    Net::Silk::Pmap::iter_xs     THIS
    PREINIT:
    uint32_t               val;
    skPrefixMapProtoPort_t lo;
    skPrefixMapProtoPort_t hi;
    skIteratorStatus_t     rv;
    PPCODE:
    rv = skPrefixMapIteratorNext(THIS, &lo, &hi, &val);
    if (rv != SK_ITERATOR_NO_MORE_ENTRIES) {
        if (rv != SK_ITERATOR_OK)
            croak("error %d pmap iterator", rv);
        mXPUSHs(newSvPROTOPORT(aTHX_ lo));
        mXPUSHs(newSvPROTOPORT(aTHX_ hi));
        mXPUSHu(val);
    }


MODULE = Net::Silk    PACKAGE = Net::Silk::Pmap             PREFIX = sk

BOOT:
// BOOT ends after first blank line outside of a block
{
    HV *stash;

    stash = gv_stashpv("Net::Silk::Pmap", TRUE);

    MCE(SILK_PMAP_TYPE_IPV4,       SKPREFIXMAP_CONT_ADDR_V4);
    MCE(SILK_PMAP_TYPE_IPV6,       SKPREFIXMAP_CONT_ADDR_V6);
    MCE(SILK_PMAP_TYPE_PROTO_PORT, SKPREFIXMAP_CONT_PROTO_PORT);
}

PROTOTYPES: DISABLE

Net::Silk::Pmap
_init(CLASS)
    const char  *CLASS
    PREINIT:
    skPrefixMapErr_t rv;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    rv = skPrefixMapCreate(&RETVAL);
    if (rv != SKPREFIXMAP_OK)
        croak("error %d creating pmap: %s", rv, skPrefixMapStrerror(rv));
    OUTPUT:
    RETVAL

Net::Silk::Pmap
_load(CLASS, fname)
    const char *CLASS
    const char *fname
    PREINIT:
    skPrefixMapErr_t rv;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    rv = skPrefixMapLoad(&RETVAL, fname);
    if (rv != SKPREFIXMAP_OK)
        croak("error %d reading prefix map from %s: %s",
              rv, fname, skPrefixMapStrerror(rv));
    OUTPUT:
    RETVAL

void
_destroy(THIS)
    Net::Silk::Pmap THIS
    CODE:
    skPrefixMapDelete(THIS);

void
save(THIS, fname)
    Net::Silk::Pmap  THIS
    const char      *fname
    PREINIT:
    skPrefixMapErr_t rv;
    PPCODE:
    rv = skPrefixMapSave(THIS, fname);
    if (rv != SKPREFIXMAP_OK)
        croak("error %d saving prefix map to %s: %s",
              rv, fname, skPrefixMapStrerror(rv));

void
_set_content_type(THIS, type)
    Net::Silk::Pmap      THIS
    skPrefixMapContent_t type
    PREINIT:
    skPrefixMapErr_t rv;
    PPCODE:
    rv = skPrefixMapSetContentType(THIS, type);
    if (rv != SKPREFIXMAP_OK)
        croak("error %d setting pmap content type: %s",
              rv, skPrefixMapStrerror(rv));

skPrefixMapContent_t
_get_content_type(THIS)
    Net::Silk::Pmap THIS
    CODE:
    RETVAL = skPrefixMapGetContentType(THIS);
    OUTPUT:
    RETVAL

const char *
get_content_type(THIS)
    Net::Silk::Pmap THIS
    CODE:
    RETVAL = skPrefixMapGetContentName(skPrefixMapGetContentType(THIS));
    OUTPUT:
    RETVAL

void
_set_default_value(THIS, val)
    Net::Silk::Pmap THIS
    uint32_t        val
    PREINIT:
    skPrefixMapErr_t rv;
    PPCODE:
    rv = skPrefixMapSetDefaultVal(THIS, val);
    if (rv != SKPREFIXMAP_OK)
        croak("error %d setting default pmap value: %s",
               rv, skPrefixMapStrerror(rv));

void
_insert_label(THIS, val, label)
    Net::Silk::Pmap THIS
    uint32_t        val
    const char     *label
    PREINIT:
    skPrefixMapErr_t rv;
    PPCODE:
    rv = skPrefixMapDictionaryInsert(THIS, val, label);
    if (rv != SKPREFIXMAP_OK)
        croak("error %d inserting pmap label: %s",
               rv, skPrefixMapStrerror(rv));

uint32_t
_get_or_insert_label(THIS, label)
    Net::Silk::Pmap THIS
    const char     *label
    PREINIT:
    skPrefixMapErr_t rv;
    CODE:
    rv = skPrefixMapDictionarySearch(THIS, label, &RETVAL);
    if (rv != SKPREFIXMAP_OK)
        croak("error %d find/insert pmap label: %s",
               rv, skPrefixMapStrerror(rv));
    OUTPUT:
    RETVAL

void
_set_name(THIS, name)
    Net::Silk::Pmap  THIS
    const char      *name
    PREINIT:
    skPrefixMapErr_t rv;
    CODE:
    rv = skPrefixMapSetMapName(THIS, name);
    if (rv != SKPREFIXMAP_OK)
        croak("error %d setting pmap name: %s", rv, skPrefixMapStrerror(rv));

const char *
get_name(THIS)
    Net::Silk::Pmap THIS
    CODE:
    RETVAL = skPrefixMapGetMapName(THIS);
    OUTPUT:
    RETVAL

uint32_t
_get_max_label_size(THIS)
    Net::Silk::Pmap THIS
    CODE:
    RETVAL = skPrefixMapDictionaryGetMaxWordSize(THIS);
    OUTPUT:
    RETVAL

void
_label_to_val(THIS, label)
    Net::Silk::Pmap  THIS
    char *label
    PREINIT:
    uint32_t  idx;
    PPCODE:
    idx = skPrefixMapDictionaryLookup(THIS, label);
    if (idx != SKPREFIXMAP_NOT_FOUND)
        mXPUSHu(idx);

void
_val_to_label(THIS, val, max_size)
    Net::Silk::Pmap  THIS
    uint32_t    val
    uint32_t    max_size
    PREINIT:
    char     *buf;
    uint32_t  len;
    int       rv;
    PPCODE:
    if (val != SKPREFIXMAP_NOT_FOUND && val >= 0) {
        if (val >= skPrefixMapDictionaryGetWordCount(THIS))
            croak("invalid value index (%u out of range 0-%u)",
                  val, skPrefixMapDictionaryGetWordCount(THIS));
        // len = skPrefixMapDictionaryGetMaxWordSize(THIS) + 1;
        len = max_size + 1;
        buf = malloc(len);
        if (buf == NULL)
            croak("unable to allocate string (out of memory)");
        rv = skPrefixMapDictionaryGetEntry(THIS, val, buf, len);
        if (rv >= len)
            croak("error pmap string allocation overflow");
        mXPUSHs(newSVpvn(buf, rv));
        Safefree(buf);
    }

uint32_t
val_count(THIS)
    Net::Silk::Pmap  THIS
    CODE:
    RETVAL = skPrefixMapDictionaryGetWordCount(THIS);
    OUTPUT:
    RETVAL

void
_add_range(THIS, sv_lo, sv_hi, val)
    Net::Silk::Pmap THIS
    SV             *sv_lo
    SV             *sv_hi
    uint32_t        val
    PREINIT:
    void *ptr_lo = NULL;
    void *ptr_hi = NULL;
    skipaddr_t             addr_lo;
    skipaddr_t             addr_hi;
    skPrefixMapProtoPort_t pp_lo;
    skPrefixMapProtoPort_t pp_hi;
    skPrefixMapContent_t   content;
    skPrefixMapErr_t       rv;
    PPCODE:
    content = skPrefixMapGetContentType(THIS);
    switch (content) {
      case SKPREFIXMAP_CONT_ADDR_V4:
        addr_lo = SvIPV4ADDR(aTHX_ sv_lo);
        addr_hi = SvIPV4ADDR(aTHX_ sv_hi);
        ptr_lo = &addr_lo;
        ptr_hi = &addr_hi;
        break;
#if SK_ENABLE_IPV6
      case SKPREFIXMAP_CONT_ADDR_V6:
        addr_lo = SvIPV6ADDR(aTHX_ sv_lo);
        addr_hi = SvIPV6ADDR(aTHX_ sv_hi);
        ptr_lo = &addr_lo;
        ptr_hi = &addr_hi;
        break;
#endif
      case SKPREFIXMAP_CONT_PROTO_PORT:
        pp_lo = SvPROTOPORT(aTHX_ sv_lo);
        pp_hi = SvPROTOPORT(aTHX_ sv_hi);
        ptr_lo = &pp_lo;
        ptr_hi = &pp_hi;
        break;
      default:
        croak("unknown pmap key type");
    }
    rv = skPrefixMapAddRange(THIS, ptr_lo, ptr_hi, val);
    if (rv != SKPREFIXMAP_OK)
        croak("error %d adding pmap range: %s", rv, skPrefixMapStrerror(rv));

void
_get_range(THIS, sv_key)
    Net::Silk::Pmap THIS
    SV             *sv_key
    PREINIT:
    SV                    *sv_lo;
    SV                    *sv_hi;
    skipaddr_t             addr_key;
    skipaddr_t             addr_lo;
    skipaddr_t             addr_hi;
    skPrefixMapProtoPort_t pp_key;
    skPrefixMapProtoPort_t pp_lo;
    skPrefixMapProtoPort_t pp_hi;
    skPrefixMapContent_t   content;
    skPrefixMapErr_t       rv;
    PPCODE:
    content = skPrefixMapGetContentType(THIS);
    switch (content) {
      case SKPREFIXMAP_CONT_ADDR_V4:
        addr_key = SvIPV4ADDR(aTHX_ sv_key);
        rv = skPrefixMapFindRange(THIS, &addr_key, &addr_lo, &addr_hi);
        if (rv != SKPREFIXMAP_OK)
            croak("error %d finding pmap range: %s",
                  rv, skPrefixMapStrerror(rv));
        sv_lo = newSvIPV4ADDR(aTHX_ &addr_lo);
        sv_hi = newSvIPV4ADDR(aTHX_ &addr_hi);
        break;
#if SK_ENABLE_IPV6
      case SKPREFIXMAP_CONT_ADDR_V6:
        addr_key = SvIPV6ADDR(aTHX_ sv_key);
        rv = skPrefixMapFindRange(THIS, &addr_key, &addr_lo, &addr_hi);
        if (rv != SKPREFIXMAP_OK)
            croak("error %d finding pmap range: %s",
                  rv, skPrefixMapStrerror(rv));
        sv_lo = newSvIPV4ADDR(aTHX_ &addr_lo);
        sv_hi = newSvIPV4ADDR(aTHX_ &addr_hi);
        break;
#endif
      case SKPREFIXMAP_CONT_PROTO_PORT:
        pp_key = SvPROTOPORT(aTHX_ sv_key);
        rv = skPrefixMapFindRange(THIS, &pp_key, &pp_lo, &pp_hi);
        if (rv != SKPREFIXMAP_OK)
            croak("error %d finding pmap range: %s",
                  rv, skPrefixMapStrerror(rv));
        sv_lo = newSvPROTOPORT(aTHX_ pp_lo);
        sv_hi = newSvPROTOPORT(aTHX_ pp_hi);
        break;
      default:
        croak("unknown pmap key type");
    }
    mXPUSHs(sv_lo);
    mXPUSHs(sv_hi);

void
get_val(THIS, sv_key)
    Net::Silk::Pmap THIS
    SV *sv_key
    PREINIT:
    void *key = NULL;
    uint32_t               val;
    skipaddr_t             addr;
    skPrefixMapProtoPort_t pp;
    skPrefixMapContent_t   content;
    PPCODE:
    content = skPrefixMapGetContentType(THIS);
    switch (content) {
      case SKPREFIXMAP_CONT_ADDR_V4:
        addr = SvIPV4ADDR(aTHX_ sv_key);
        key = &addr;
        break;
#if SK_ENABLE_IPV6
      case SKPREFIXMAP_CONT_ADDR_V6:
        addr = SvIPV6ADDR(aTHX_ sv_key);
        key = &addr;
        break;
#endif
      case SKPREFIXMAP_CONT_PROTO_PORT:
        if (! SvROK(sv_key))
            croak("not a reference");
        pp = SvPROTOPORT(aTHX_ sv_key);
        key = &pp;
        break;
      default:
        croak("unknown pmap key type");
    }
    // should be skPrefixMapFindValue in SiLK-3.8.0 and above
    val = skPrefixMapGet(THIS, key);
    if (val != SKPREFIXMAP_NOT_FOUND) {
        mXPUSHu(val);
    }


MODULE = Net::Silk    PACKAGE = Net::Silk::TCPFlags         PREFIX = sk

PROTOTYPES: DISABLE

uint8_t
parse_flags(repr)
    const char *repr
    CODE:
    if (skStringParseTCPFlags(&RETVAL, repr)) {
        croak("Illegal TCP flag value: %s", repr);
    }
    OUTPUT:
    RETVAL

void
parse_high_mask(repr)
    const char *repr
    PREINIT:
    int     rv;
    uint8_t high, mask;
    PPCODE:
    rv = skStringParseTCPFlagsHighMask(&high, &mask, repr);
    if (rv == SKUTILS_ERR_SHORT) {
        mask = high;
    } else if (rv != SKUTILS_OK) {
        croak("Illegal flag/mask: %s", repr);
    }
    mXPUSHu(high);
    mXPUSHu(mask);

char *
str(THIS, ...)
    Net::Silk::TCPFlags THIS;
    PREINIT:
    // the ... is necessary to throw off signature of CORE::str
    char buf[SK_TCPFLAGS_STRLEN];
    CODE:
    skTCPFlagsString(THIS, buf, 0);
    RETVAL = buf;
    OUTPUT:
    RETVAL

char *
padded(THIS)
    Net::Silk::TCPFlags THIS;
    PREINIT:
    char buf[SK_TCPFLAGS_STRLEN];
    CODE:
    skTCPFlagsString(THIS, buf, SK_PADDED_FLAGS);
    RETVAL = buf;
    OUTPUT:
    RETVAL


MODULE = Net::Silk    PACKAGE = Net::Silk::Site::iter_xs

PROTOTYPES: DISABLE

void
DESTROY(THIS)
    Net::Silk::Site::iter_xs    THIS
    CODE:
    sksiteRepoIteratorDestroy(&THIS);

Net::Silk::Site::iter_xs
new(CLASS, flowtypes, sensors, start_time, end_time, missing)
    char                *CLASS
    HV                  *flowtypes
    AV                  *sensors
    int64_t              start_time
    int64_t              end_time
    bool                 missing
    PREINIT:
    int                 max;
    sk_vector_t        *ft_vec     = NULL;
    sk_vector_t        *sensor_vec = NULL;
    sk_flowtype_id_t    ft;
    sk_sensor_id_t      sensor;
    uint32_t            flags;
    int                 rv;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    // pull flowtypes
    ft_vec = skVectorNew(sizeof(sk_flowtype_id_t));
    if (ft_vec == NULL)
        croak("error allocating flowtype vector");
    max = hv_iterinit(flowtypes);
    if (max == 0) {
        sk_flowtype_iter_t ft_iter;
        sksiteFlowtypeIterator(&ft_iter);
        while (sksiteFlowtypeIteratorNext(&ft_iter, &ft)) {
            rv = skVectorAppendValue(ft_vec, &ft);
            if (rv != 0)
                croak("error appending to flowtype vector");
        }
    } else {
        SV   *val;
        I32   len;
        char *class_name, *type_name;
        while ((val = hv_iternextsv(flowtypes, &class_name, &len))) {
            type_name = SvPV_nolen(val);
            ft = sksiteFlowtypeLookupByClassType(class_name, type_name);
            if (ft == SK_INVALID_FLOWTYPE)
                croak("Invalid (class, type) pair ('%s', '%s')",
                       class_name, type_name);
            rv = skVectorAppendValue(ft_vec, &ft);
            if (rv != 0)
                croak("error appending to flowtype vector");
        }
    }

    // pull sensors
    max = av_top_index(sensors);
    if (max != -1) {
        SV **avp;
        sensor_vec = skVectorNew(sizeof(sk_sensor_id_t));
        if (sensor_vec == NULL)
            croak("error allocating sensor vector");
        max = av_top_index(sensors);
        int i;
        for (i = 0; i <= max; i++) {
            const char *sensor_name;
            avp = av_fetch(sensors, i, 0);
            sensor_name = SvPV_nolen(*avp);
            sensor = sksiteSensorLookup(sensor_name);
            if (sensor == SK_INVALID_SENSOR)
                croak("Invalid sensor name '%s'", sensor_name);
            rv = skVectorAppendValue(sensor_vec, &sensor);
            if (rv != 0)
                croak("error appending to sensor vector");
        }
    }

    flags = missing ? RETURN_MISSING : 0;

    rv = sksiteRepoIteratorCreate(&RETVAL, ft_vec, sensor_vec,
                                           start_time, end_time, flags);
    if (rv != 0)
        croak("error allocating iterator");
    if (ft_vec)
        skVectorDestroy(ft_vec);
    if (sensor_vec)
        skVectorDestroy(sensor_vec);
    OUTPUT:
    RETVAL

char *
next(THIS)
    Net::Silk::Site::iter_xs    THIS
    PREINIT:
    char path[PATH_MAX];
    int  missing;
    int  rv;
    PPCODE:
    rv = sksiteRepoIteratorNextPath(THIS, path, sizeof(path), &missing);
    if (rv != SK_ITERATOR_NO_MORE_ENTRIES) {
        mXPUSHs(newSVpvn(path, strlen(path)));
    }


MODULE = Net::Silk    PACKAGE = Net::Silk::Site             PREFIX = sk

BOOT:
// BOOT ends after first blank line outside of a block
{
    HV *stash;

    stash = gv_stashpv("Net::Silk::Site", TRUE);

    MCPV(SILK_DATA_ROOTDIR_ENVAR);
    MCPV(SILK_CONFIG_FILE_ENVAR);
}

PROTOTYPES: DISABLE

int
silk_init_set_envvar(val, envvar)
    const char *val
    const char *envvar
    PREINIT:
    static char env_buf[101 + PATH_MAX];
    int rv;
    CODE:
    rv = snprintf(env_buf, sizeof(env_buf), "%s=%s", envvar, val);
    if (rv >= (int)sizeof(env_buf) || putenv(env_buf) != 0) {
        warn("Could not set %s", envvar);
        RETVAL = -1;
    } else {
        RETVAL = 0;
    }
    OUTPUT:
    RETVAL

bool
set_site_config(filename)
    const char *filename
    CODE:
    RETVAL = sksiteSetConfigPath(filename) ? 0 : 1;
    OUTPUT:
    RETVAL

char *
get_site_config()
    PREINIT:
    char siteconf[PATH_MAX];
    CODE:
    sksiteGetConfigPath(siteconf, sizeof(siteconf));
    RETVAL = siteconf;
    OUTPUT:
    RETVAL

bool
set_data_rootdir(rootdir)
    const char *rootdir
    CODE:
    RETVAL = sksiteSetRootDir(rootdir) ? 0 : 1;
    OUTPUT:
    RETVAL

char *
get_data_rootdir()
    PREINIT:
    char rootdir[PATH_MAX];
    CODE:
    sksiteGetRootDir(rootdir, sizeof(rootdir));
    RETVAL = rootdir;
    OUTPUT:
    RETVAL

int
_site_configure(verbose)
    int verbose
    CODE:
    RETVAL = sksiteConfigure(verbose);
    OUTPUT:
    RETVAL

void
sensor_ids()
    PREINIT:
    sk_sensor_iter_t sensor_iter;
    sk_sensor_id_t   id;
    PPCODE:
    sksiteSensorIterator(&sensor_iter);
    while (sksiteSensorIteratorNext(&sensor_iter, &id)) {
        mXPUSHu(id);
    }

void
sensor_classes_by_id(id)
    sk_sensor_id_t id
    PREINIT:
    sk_class_iter_t class_iter;
    sk_class_id_t   class;
    PPCODE:
    sksiteSensorClassIterator(id, &class_iter);
    while (sksiteClassIteratorNext(&class_iter, &class)) {
        mXPUSHu(class);
    }

char *
sensor_name(id)
    sk_sensor_id_t id
    PREINIT:
    char name[SK_MAX_STRLEN_SENSOR+1];
    CODE:
    sksiteSensorGetName(name, sizeof(name), id);
    RETVAL = name;
    OUTPUT:
    RETVAL

const char *
sensor_description_by_id(id)
    sk_sensor_id_t id
    PREINIT:
    char name[SK_MAX_STRLEN_SENSOR+1];
    CODE:
    RETVAL = sksiteSensorGetDescription(id);
    OUTPUT:
    RETVAL

void
class_ids()
    PREINIT:
    sk_class_iter_t class_iter;
    sk_class_id_t   id;
    PPCODE:
    sksiteClassIterator(&class_iter);
    while (sksiteClassIteratorNext(&class_iter, &id)) {
        mXPUSHu(id);
    }

void
class_sensors_by_id(id)
    sk_class_id_t id
    PREINIT:
    sk_sensor_iter_t sensor_iter;
    sk_sensor_id_t   sensor;
    PPCODE:
    sksiteClassSensorIterator(id, &sensor_iter);
    while (sksiteSensorIteratorNext(&sensor_iter, &sensor)) {
        mXPUSHu(sensor);
    }

void
class_flowtypes_by_id(id)
    sk_class_id_t id
    PREINIT:
    sk_flowtype_iter_t flowtype_iter;
    sk_flowtype_id_t   flowtype;
    PPCODE:
    sksiteClassFlowtypeIterator(id, &flowtype_iter);
    while (sksiteFlowtypeIteratorNext(&flowtype_iter, &flowtype)) {
        mXPUSHu(flowtype);
    }

void
class_default_flowtypes_by_id(id)
    sk_class_id_t id
    PREINIT:
    sk_flowtype_iter_t flowtype_iter;
    sk_flowtype_id_t   flowtype;
    PPCODE:
    sksiteClassDefaultFlowtypeIterator(id, &flowtype_iter);
    while (sksiteFlowtypeIteratorNext(&flowtype_iter, &flowtype)) {
        mXPUSHu(flowtype);
    }

sk_class_id_t
default_class_id(id)
    CODE:
    RETVAL = sksiteClassGetDefault();
    OUTPUT:
    RETVAL

char *
class_name(id)
    sk_class_id_t id
    PREINIT:
    char name[SK_MAX_STRLEN_FLOWTYPE+1];
    CODE:
    sksiteClassGetName(name, sizeof(name), id);
    RETVAL = name;
    OUTPUT:
    RETVAL

void
flowtype_ids()
    PREINIT:
    sk_flowtype_iter_t flowtype_iter;
    sk_flowtype_id_t   id;
    PPCODE:
    sksiteFlowtypeIterator(&flowtype_iter);
    while (sksiteFlowtypeIteratorNext(&flowtype_iter, &id)) {
        mXPUSHu(id);
    }

char *
flowtype_name(id)
    sk_flowtype_id_t id
    PREINIT:
    char name[SK_MAX_STRLEN_SENSOR+1];
    CODE:
    sksiteFlowtypeGetName(name, sizeof(name), id);
    RETVAL = name;
    OUTPUT:
    RETVAL

char *
flowtype_type(id)
    sk_flowtype_id_t id
    PREINIT:
    char name[SK_MAX_STRLEN_SENSOR+1];
    CODE:
    sksiteFlowtypeGetType(name, sizeof(name), id);
    RETVAL = name;
    OUTPUT:
    RETVAL

sk_class_id_t
flowtype_class(id)
    sk_flowtype_id_t id
    CODE:
    RETVAL = sksiteFlowtypeGetClassID(id);
    OUTPUT:
    RETVAL


MODULE = Net::Silk    PACKAGE = Net::Silk::RWRec     PREFIX = rwRec

PROTOTYPES: DISABLE

Net::Silk::RWRec
new_cleared(CLASS)
    const char   *CLASS
    PREINIT:
    rwRec       rec;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RWREC_CLEAR(&rec);
    RETVAL = &rec;
    OUTPUT:
    RETVAL

Net::Silk::RWRec
to_ipv6(THIS)
    Net::Silk::RWRec    THIS
    PREINIT:
    rwRec       copy;
    CODE:
#if SK_ENABLE_IPV6
    copy = *THIS;
    rwRecConvertToIPv6(&copy);
    RETVAL = &copy;
#else
    croak("SiLK was not built with IPv6 support");
#endif
    OUTPUT:
    RETVAL

void
to_ipv4(THIS)
    Net::Silk::RWRec    THIS
    PREINIT:
    rwRec       copy;
    PPCODE:
    copy = *THIS;
#if SK_ENABLE_IPV6
    if (rwRecIsIPv6(&copy)) {
        if (!rwRecConvertToIPv4(&copy))
            goto proceed;
    }
    else
#endif
  proceed:
    {
        mXPUSHs(sv_setref_pvn(newSV(0), SILK_RWREC_CLASS,
                              (char *)&copy, sizeof(copy)));
    }

Net::Silk::RWRec
copy(THIS)
    Net::Silk::RWRec    THIS
    PREINIT:
    rwRec       copy;
    CODE:
    copy = *THIS;
    RETVAL = &copy;
    OUTPUT:
    RETVAL

uint16_t
get_application(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecGetApplication(THIS);
    OUTPUT:
    RETVAL

void
set_application(THIS, val)
    Net::Silk::RWRec    THIS
    int                 val
    CODE:
    if (val < 0 || val > UINT16_MAX)
        croak("The application value must be a 16-bit integer");
    rwRecSetApplication(THIS, val);

uint32_t
get_bytes(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecGetBytes(THIS);
    OUTPUT:
    RETVAL

void
set_bytes(THIS, val)
    Net::Silk::RWRec    THIS
    int                 val
    CODE:
    if (val < 0 || val > UINT32_MAX)
        croak("The bytes value must be a 32-bit integer");
    rwRecSetBytes(THIS, val);

uint8_t
get_icmpcode(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecGetIcmpCode(THIS);
    OUTPUT:
    RETVAL

void
set_icmpcode(THIS, val)
    Net::Silk::RWRec    THIS
    int                 val
    CODE:
    if (val < 0 || val > UINT8_MAX)
        croak("The icmpcode value must be a 8-bit integer");
    rwRecSetIcmpCode(THIS, (uint8_t)val);

uint8_t
get_icmptype(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecGetIcmpType(THIS);
    OUTPUT:
    RETVAL

void
set_icmptype(THIS, val)
    Net::Silk::RWRec    THIS
    int                 val
    CODE:
    if (val <= 0 || val > UINT8_MAX)
        croak("The icmptype value must be a 8-bit integer");
    rwRecSetIcmpType(THIS, (uint8_t)val);

uint16_t
get_input(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecGetInput(THIS);
    OUTPUT:
    RETVAL

void
set_input(THIS, val)
    Net::Silk::RWRec    THIS
    int                 val
    CODE:
    if (val < 0 || val > UINT16_MAX)
        croak("The input value must be a 16-bit integer");
    rwRecSetInput(THIS, val);

uint16_t
get_output(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecGetOutput(THIS);
    OUTPUT:
    RETVAL

void
set_output(THIS, val)
    Net::Silk::RWRec    THIS
    int                 val
    CODE:
    if (val < 0 || val > UINT16_MAX)
        croak("The output value must be a 16-bit integer");
    rwRecSetOutput(THIS, val);

bool
is_icmp(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecIsICMP(THIS);
    OUTPUT:
    RETVAL

bool
is_ipv6(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecIsIPv6(THIS);
    OUTPUT:
    RETVAL

bool
is_web(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecIsWeb(THIS);
    OUTPUT:
    RETVAL

uint32_t
get_packets(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecGetPkts(THIS);
    OUTPUT:
    RETVAL

void
set_packets(THIS, val)
    Net::Silk::RWRec    THIS
    int                 val
    CODE:
    if (val < 0 || val > UINT32_MAX)
        croak("The packets value must be a 32-bit integer");
    rwRecSetPkts(THIS, val);

uint8_t
get_protocol(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecGetProto(THIS);
    OUTPUT:
    RETVAL

void
set_protocol(THIS, val)
    Net::Silk::RWRec    THIS
    int                 val
    CODE:
    if (val < 0 || val > UINT8_MAX)
        croak("The protocol value must be a 8-bit integer");
    rwRecSetProto(THIS, val)
    if (val != IPPROTO_TCP) {
        /* Initial and session flags are not allowed for non-TCP. */
        uint8_t state = rwRecGetTcpState(THIS);
        rwRecSetTcpState(THIS, state & ~SK_TCPSTATE_EXPANDED);
        rwRecSetInitFlags(THIS, 0);
        rwRecSetRestFlags(THIS, 0);
    }

bool
_eq(THIS, other)
    Net::Silk::RWRec    THIS
    Net::Silk::RWRec    other
    CODE:
    RETVAL = memcmp(THIS, other, sizeof(*THIS));
    RETVAL = (RETVAL == 0) ? 1 : 0;
    OUTPUT:
    RETVAL

bool
_ne(THIS, other)
    Net::Silk::RWRec    THIS
    Net::Silk::RWRec    other
    CODE:
    RETVAL = memcmp(THIS, other, sizeof(*THIS));
    RETVAL = (RETVAL == 0) ? 0 : 1;
    OUTPUT:
    RETVAL

uint16_t
get_sensor_id(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecGetSensor(THIS);
    OUTPUT:
    RETVAL

void
set_sensor_id(THIS, val)
    Net::Silk::RWRec    THIS
    int                 val
    CODE:
    if (val < 0 || val > UINT16_MAX)
        croak("The sensor id value must be a 16-bit integer");
    rwRecSetSensor(THIS, (sk_sensor_id_t)val);

uint8_t
get_classtype_id(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecGetFlowType(THIS);
    OUTPUT:
    RETVAL

void
set_classtype_id(THIS, val)
    Net::Silk::RWRec    THIS
    int                 val
    CODE:
    if (val < 0 || val > UINT8_MAX)
        croak("The classtype id value must be a 8-bit integer");
    rwRecSetFlowType(THIS, (sk_flowtype_id_t)val);

char *
_classname(THIS)
    Net::Silk::RWRec    THIS
    PREINIT:
    char                class_name[SK_MAX_STRLEN_FLOWTYPE+1];
    sk_flowtype_id_t    flowtype;
    CODE:
    flowtype = rwRecGetFlowType(THIS);
    sksiteFlowtypeGetClass(class_name, sizeof(class_name), flowtype);
    RETVAL = class_name;
    OUTPUT:
    RETVAL

Net::Silk::TCPFlags
get_tcpflags(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecGetFlags(THIS);
    OUTPUT:
    RETVAL

void
set_tcpflags(THIS, flags)
    Net::Silk::RWRec    THIS
    Net::Silk::TCPFlags flags
    PREINIT:
    uint8_t     state;
    CODE:
    state = rwRecGetTcpState(THIS) & ~SK_TCPSTATE_EXPANDED;
    rwRecSetFlags(THIS, flags);
    rwRecSetInitFlags(THIS, 0);
    rwRecSetTcpState(THIS, state);

void
get_initial_tcpflags(THIS)
    Net::Silk::RWRec    THIS
    PPCODE:
    if (!(!(rwRecGetTcpState(THIS) & SK_TCPSTATE_EXPANDED)))
        mXPUSHs(newSvTCPFLAGS(aTHX_ rwRecGetInitFlags(THIS)));

void
set_initial_tcpflags(THIS, flags)
    Net::Silk::RWRec    THIS
    Net::Silk::TCPFlags flags
    PREINIT:
    uint8_t     state;
    CODE:
    if (rwRecGetProto(THIS) != IPPROTO_TCP)
        croak("Cannot set initial_tcpflags when protocol is not TCP");
    state = rwRecGetTcpState(THIS);
    rwRecSetInitFlags(THIS, flags);
    if (! (state & SK_TCPSTATE_EXPANDED)) {
        rwRecSetTcpState(THIS, state | SK_TCPSTATE_EXPANDED);
        rwRecSetRestFlags(THIS, 0);
    }
    rwRecSetFlags(THIS, rwRecGetRestFlags(THIS) | flags);

void
get_session_tcpflags(THIS)
    Net::Silk::RWRec    THIS
    PPCODE:
    if (!(!(rwRecGetTcpState(THIS) & SK_TCPSTATE_EXPANDED)))
        mXPUSHs(newSvTCPFLAGS(aTHX_ rwRecGetRestFlags(THIS)));

void
set_session_tcpflags(THIS, flags)
    Net::Silk::RWRec    THIS
    Net::Silk::TCPFlags flags
    PREINIT:
    uint8_t     state;
    CODE:
    if (rwRecGetProto(THIS) != IPPROTO_TCP)
        croak("Cannot set session_tcpflags when protocol is not TCP");
    state = rwRecGetTcpState(THIS);
    rwRecSetRestFlags(THIS, flags);
    if (! (state & SK_TCPSTATE_EXPANDED)) {
        rwRecSetTcpState(THIS, state | SK_TCPSTATE_EXPANDED);
        rwRecSetInitFlags(THIS, 0);
    }
    rwRecSetFlags(THIS, rwRecGetInitFlags(THIS) | flags);

Net::Silk::IPAddr
get_sip(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    rwRecMemGetSIP(THIS, &RETVAL);
    OUTPUT:
    RETVAL

void
set_sip(THIS, addr)
    Net::Silk::RWRec    THIS
    Net::Silk::IPAddr   addr
    CODE:
    rwRecMemSetSIP(THIS, &addr);

Net::Silk::IPAddr
get_dip(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    rwRecMemGetDIP(THIS, &RETVAL);
    OUTPUT:
    RETVAL

void
set_dip(THIS, addr)
    Net::Silk::RWRec    THIS
    Net::Silk::IPAddr   addr
    CODE:
    rwRecMemSetDIP(THIS, &addr);

Net::Silk::IPAddr
get_nhip(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    rwRecMemGetNhIP(THIS, &RETVAL);
    OUTPUT:
    RETVAL

void
set_nhip(THIS, addr)
    Net::Silk::RWRec    THIS
    Net::Silk::IPAddr   addr
    CODE:
    rwRecMemSetNhIP(THIS, &addr);

uint16_t
get_sport(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecGetSPort(THIS);
    OUTPUT:
    RETVAL

void
set_sport(THIS, val)
    Net::Silk::RWRec    THIS
    int                 val
    CODE:
    if (val < 0 || val > UINT16_MAX)
        croak("The sport value must be a 16-bit integer");
    rwRecSetSPort(THIS, val);

uint16_t
get_dport(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecGetDPort(THIS);
    OUTPUT:
    RETVAL

void
set_dport(THIS, val)
    Net::Silk::RWRec    THIS
    int                 val
    CODE:
    if (val < 0 || val > UINT16_MAX)
        croak("The dport value must be a 16-bit integer");
    rwRecSetDPort(THIS, val);

int64_t
get_stime_epoch_ms(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecGetStartTime(THIS);
    OUTPUT:
    RETVAL

void
set_stime_epoch_ms(THIS, stime)
    Net::Silk::RWRec    THIS
    int64_t             stime
    CODE:
    if (stime > MAX_EPOCH)
        croak("Maximum stime is 03:14:07, Jan 19, 2038");
    rwRecSetStartTime(THIS, stime);

int64_t
get_etime_epoch_ms(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecGetStartTime(THIS) + rwRecGetElapsed(THIS);
    OUTPUT:
    RETVAL

void
set_etime_epoch_ms(THIS, etime)
    Net::Silk::RWRec    THIS
    int64_t             etime
    PREINIT:
    int64_t     stime;
    CODE:
    if (etime > MAX_EPOCH)
        croak("Maximum etime is 03:14:07, Jan 19, 2038");
    stime = rwRecGetStartTime(THIS);
    if (etime < stime)
        croak("etime may not be less than stime");
    rwRecSetElapsed(THIS, (uint32_t)(etime - stime));

uint32_t
get_duration_ms(THIS)
    Net::Silk::RWRec    THIS
    CODE:
    RETVAL = rwRecGetElapsed(THIS);
    OUTPUT:
    RETVAL

void
set_duration_ms(THIS, val)
    Net::Silk::RWRec    THIS
    uint32_t            val
    CODE:
    if (val > UINT32_MAX)
        croak("The duration value must be a 32-bit integer");
    rwRecSetElapsed(THIS, val);

uint8_t
get_finnoack(THIS)
    Net::Silk::RWRec    THIS
    PREINIT:
    uint8_t state;
    CODE:
    state = rwRecGetTcpState(THIS);
    RETVAL = (state & SK_TCPSTATE_FIN_FOLLOWED_NOT_ACK) ? 1 : 0;
    OUTPUT:
    RETVAL

void
set_finnoack(THIS, val)
    Net::Silk::RWRec    THIS
    bool                val
    PREINIT:
    uint8_t state;
    CODE:
    state = rwRecGetTcpState(THIS);
    if (val) {
        state |= SK_TCPSTATE_FIN_FOLLOWED_NOT_ACK;
    } else {
        state &= ~SK_TCPSTATE_FIN_FOLLOWED_NOT_ACK;
    }
    rwRecSetTcpState(THIS, state);

bool
get_timeout_killed(THIS)
    Net::Silk::RWRec    THIS
    PREINIT:
    uint8_t     state;
    CODE:
    state = rwRecGetTcpState(THIS);
    RETVAL = (state & SK_TCPSTATE_TIMEOUT_KILLED) ? 1 : 0;
    OUTPUT:
    RETVAL

void
set_timeout_killed(THIS, val)
    Net::Silk::RWRec    THIS
    bool                val
    PREINIT:
    uint8_t     state;
    CODE:
    state = rwRecGetTcpState(THIS);
    if (val) {
        state |= SK_TCPSTATE_TIMEOUT_KILLED;
    } else {
        state &= ~SK_TCPSTATE_TIMEOUT_KILLED;
    }
    rwRecSetTcpState(THIS, state);

bool
get_timeout_started(THIS)
    Net::Silk::RWRec    THIS
    PREINIT:
    uint8_t     state;
    CODE:
    state = rwRecGetTcpState(THIS);
    RETVAL = (state & SK_TCPSTATE_TIMEOUT_STARTED) ? 1 : 0;
    OUTPUT:
    RETVAL

void
set_timeout_started(THIS, val)
    Net::Silk::RWRec    THIS
    bool                val
    PREINIT:
    uint8_t     state;
    CODE:
    state = rwRecGetTcpState(THIS);
    if (val) {
        state |= SK_TCPSTATE_TIMEOUT_STARTED;
    } else {
        state &= ~SK_TCPSTATE_TIMEOUT_STARTED;
    }
    rwRecSetTcpState(THIS, state);

char *
_typename(THIS)
    Net::Silk::RWRec    THIS
    PREINIT:
    char             type_name[SK_MAX_STRLEN_FLOWTYPE+1];
    sk_flowtype_id_t flowtype;
    CODE:
    flowtype = rwRecGetFlowType(THIS);
    sksiteFlowtypeGetType(type_name, sizeof(type_name), flowtype);
    RETVAL = type_name;
    OUTPUT:
    RETVAL

bool
get_uniform_packets(THIS)
    Net::Silk::RWRec    THIS
    PREINIT:
    uint8_t     state;
    CODE:
    state = rwRecGetTcpState(THIS);
    RETVAL = state & SK_TCPSTATE_UNIFORM_PACKET_SIZE;
    OUTPUT:
    RETVAL

void
set_uniform_packets(THIS, val)
    Net::Silk::RWRec    THIS
    bool                val
    PREINIT:
    uint8_t     state;
    CODE:
    state = rwRecGetTcpState(THIS);
    if (val) {
        state |= SK_TCPSTATE_UNIFORM_PACKET_SIZE;
    } else {
        state &= ~SK_TCPSTATE_UNIFORM_PACKET_SIZE;
    }
    rwRecSetTcpState(THIS, state);


MODULE = Net::Silk    PACKAGE = Net::Silk::File::io_xs   PREFIX = skStream

BOOT:
// BOOT ends after first blank line outside of a block
{
    HV *stash;

    stash = gv_stashpv("Net::Silk::File::io_xs", TRUE);

    MC(SK_IO_READ);
    MC(SK_IO_WRITE);
    MC(SK_IO_APPEND);

    MC(SK_IPV6POLICY_IGNORE);
    MC(SK_IPV6POLICY_ASV4);
    MC(SK_IPV6POLICY_MIX);
    MC(SK_IPV6POLICY_FORCE);
    MC(SK_IPV6POLICY_ONLY);

    MC(SK_COMPMETHOD_DEFAULT);
    MC(SK_COMPMETHOD_BEST);
    MC(SK_COMPMETHOD_NONE);
    MC(SK_COMPMETHOD_ZLIB);
    MC(SK_COMPMETHOD_LZO1X);
}

PROTOTYPES: DISABLE

void
DESTROY(THIS)
    Net::Silk::File::io_xs THIS
    CODE:
    skStreamClose(THIS);
    skStreamDestroy(&THIS);

void
close(THIS)
    Net::Silk::File::io_xs THIS
    PREINIT:
    int rv;
    CODE:
    rv = skStreamClose(THIS);
    if (rv != 0)
        _stream_croak(aTHX_ THIS, rv);

Net::Silk::File::io_xs
init_open(CLASS, filename, mode)
    char       *CLASS
    char       *filename
    int         mode
    PREINIT:
    int         rv;
    skstream_t  *stream;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    if (mode != SK_IO_READ && mode != SK_IO_WRITE && mode != SK_IO_APPEND)
        croak("Illegal mode");
    rv = skStreamCreate(&RETVAL, (skstream_mode_t)mode, SK_CONTENT_SILK_FLOW);
    if (rv != 0)
        _stream_croak(aTHX_ RETVAL, rv);
    rv = skStreamBind(RETVAL, filename);
    if (rv != 0)
        _stream_croak(aTHX_ RETVAL, rv);
    OUTPUT:
    RETVAL

void
init_policy(THIS, policy)
    Net::Silk::File::io_xs THIS
    int                 policy
    PREINIT:
    int         rv;
    CODE:
    rv = skStreamSetIPv6Policy(THIS, (sk_ipv6policy_t)policy);
    if (rv != 0)
        _stream_croak(aTHX_ THIS, rv);

void
init_compression(THIS, compr)
    Net::Silk::File::io_xs THIS
    int                 compr
    PREINIT:
    skstream_mode_t     mode;
    int                 rv;
    sk_file_header_t   *hdr;
    CODE:
    mode = skStreamGetMode(THIS);
    if (mode != SK_IO_WRITE)
        croak("Cannot set compression unless in WRITE mode");
    hdr = skStreamGetSilkHeader(THIS);
    if (hdr != NULL) {
        rv = skHeaderSetCompressionMethod(hdr, compr);
        if (rv != 0)
            _stream_croak(aTHX_ THIS, rv);
    }

void
init_format(THIS, format)
    Net::Silk::File::io_xs THIS
    int                 format
    PREINIT:
    skstream_mode_t     mode;
    int                 rv;
    sk_file_header_t   *hdr;
    CODE:
    mode = skStreamGetMode(THIS);
    if (mode != SK_IO_WRITE)
        croak("Cannot set file format unless in WRITE mode");
    hdr = skStreamGetSilkHeader(THIS);
    if (hdr != NULL) {
        rv = skHeaderSetFileFormat(hdr, format);
        if (rv != 0)
            _stream_croak(aTHX_ THIS, rv);
    }

void
init_add_annotation(THIS, annotation)
    Net::Silk::File::io_xs THIS
    char               *annotation
    PREINIT:
    skstream_mode_t     mode;
    int                 rv;
    sk_file_header_t   *hdr;
    CODE:
    mode = skStreamGetMode(THIS);
    if (mode != SK_IO_WRITE)
        croak("Cannot set annotations unless in WRITE mode");
    hdr = skStreamGetSilkHeader(THIS);
    if (hdr != NULL) {
        rv = skHeaderAddAnnotation(hdr, annotation);
        if (rv != 0)
            _stream_croak(aTHX_ THIS, rv);
    }

void
init_add_invocation(THIS, invocation)
    Net::Silk::File::io_xs THIS
    char               *invocation
    PREINIT:
    skstream_mode_t     mode;
    int                 rv;
    sk_file_header_t   *hdr;
    CODE:
    mode = skStreamGetMode(THIS);
    if (mode != SK_IO_WRITE)
        croak("Cannot set annotations unless in WRITE mode");
    hdr = skStreamGetSilkHeader(THIS);
    if (hdr != NULL) {
        rv = skHeaderAddInvocation(hdr, 0, 1, &invocation);
        if (rv != 0)
            _stream_croak(aTHX_ THIS, rv);
    }

void
init_finalize(THIS, ...)
    Net::Silk::File::io_xs THIS
    PREINIT:
    int                 fd;
    int                 rv;
    skstream_mode_t     mode;
    CODE:
        if (items > 1) {
            fd = (int)SvUV(ST(1));
            rv = skStreamFDOpen(THIS, fd);
        } else {
            rv = skStreamOpen(THIS);
        }
        if (rv != 0)
            _stream_croak(aTHX_ THIS, rv);
        mode = skStreamGetMode(THIS);
        if (mode == SK_IO_WRITE) {
            rv = skStreamWriteSilkHeader(THIS);
            if (rv != 0)
                _stream_croak(aTHX_ THIS, rv);
        } else {
            rv = skStreamReadSilkHeader(THIS, NULL);
            if (rv != 0)
                _stream_croak(aTHX_ THIS, rv);
        }

void
invocations(THIS)
    Net::Silk::File::io_xs THIS
    PREINIT:
    sk_file_header_t     *hdr;
    sk_header_entry_t    *entry;
    sk_hentry_iterator_t  iter;
    char                 *invoc;
    PPCODE:
    hdr = skStreamGetSilkHeader(THIS);
    if (hdr != NULL) {
        skHeaderIteratorBindType(&iter, hdr, SK_HENTRY_INVOCATION_ID);
        while ((entry = skHeaderIteratorNext(&iter)) != NULL) {
            invoc = ((sk_hentry_invocation_t*)entry)->command_line;
            mXPUSHs(newSVpvn(invoc, strlen(invoc)));
        }
    }

void
notes(THIS)
    Net::Silk::File::io_xs THIS
    PREINIT:
    sk_file_header_t     *hdr;
    sk_header_entry_t    *entry;
    sk_hentry_iterator_t  iter;
    char                 *annot;
    PPCODE:
    hdr = skStreamGetSilkHeader(THIS);
    if (hdr != NULL) {
        skHeaderIteratorBindType(&iter, hdr, SK_HENTRY_ANNOTATION_ID);
        while ((entry = skHeaderIteratorNext(&iter)) != NULL) {
            annot = ((sk_hentry_annotation_t*)entry)->annotation;
            mXPUSHs(newSVpvn(annot, strlen(annot)));
        }
    }

const char *
name(THIS)
    Net::Silk::File::io_xs THIS
    CODE:
    RETVAL = skStreamGetPathname(THIS);
    OUTPUT:
    RETVAL

int
mode(THIS)
    Net::Silk::File::io_xs THIS
    CODE:
    RETVAL = (int)skStreamGetMode(THIS);
    OUTPUT:
    RETVAL

int
fileno(THIS)
    Net::Silk::File::io_xs THIS
    CODE:
    RETVAL = skStreamGetDescriptor(THIS);
    OUTPUT:
    RETVAL

void
flush(THIS)
    Net::Silk::File::io_xs THIS
    PREINIT:
    int rv;
    CODE:
    rv = skStreamFlush(THIS);
    if (rv != 0)
        _stream_croak(aTHX_ THIS, rv);

Net::Silk::RWRec
read(THIS)
    Net::Silk::File::io_xs THIS
    PREINIT:
    int   rv;
    rwRec rec;
    PPCODE:
    rv = skStreamReadRecord(THIS, &rec);
    if (rv == 0) {
        mXPUSHs(newSvRWREC(aTHX_ &rec));
    } else if (rv != SKSTREAM_ERR_EOF) {
        _stream_croak(aTHX_ THIS, rv);
    }

void
write(THIS, rec)
    Net::Silk::File::io_xs THIS
    Net::Silk::RWRec    rec
    PREINIT:
    int rv;
    CODE:
    rv = skStreamWriteRecord(THIS, rec);
    if (rv != 0)
        _stream_croak(aTHX_ THIS, rv);
