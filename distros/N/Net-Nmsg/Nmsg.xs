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

#ifdef _CYGWIN
#include <windows.h>
#endif

#ifdef _WIN32
#include <windows.h>
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

#include <nmsg.h>
#include <pcap.h>

#ifdef _CYGWIN
#include <Win32-Extensions.h>
#endif

typedef nmsg_message_t      Net__Nmsg__XS__msg;
typedef nmsg_io_t           Net__Nmsg__XS__io;
typedef nmsg_input_t        Net__Nmsg__XS__input;
typedef nmsg_input_t        Net__Nmsg__XS__input_file;
typedef nmsg_input_t        Net__Nmsg__XS__input_json;
typedef nmsg_input_t        Net__Nmsg__XS__input_sock;
typedef nmsg_input_t        Net__Nmsg__XS__input_pres;
typedef nmsg_input_t        Net__Nmsg__XS__input_pcap;
typedef nmsg_output_t       Net__Nmsg__XS__output;
typedef nmsg_output_t       Net__Nmsg__XS__output_file;
typedef nmsg_output_t       Net__Nmsg__XS__output_json;
typedef nmsg_output_t       Net__Nmsg__XS__output_sock;
typedef nmsg_output_t       Net__Nmsg__XS__output_pres;
typedef nmsg_output_t       Net__Nmsg__XS__output_cb;
typedef nmsg_rate_t         Net__Nmsg__XS__rate;

typedef nmsg_pcap_t         Net__Nmsg__XS__nmsg_pcap;
typedef pcap_t             *Net__Nmsg__XS__pcap;

typedef enum groknum_err_en {
    GROKNUM_OK                =  0,  /* number ok                */
    GROKNUM_ERR_NVREF         = -1,  /* invalid reference        */
    GROKNUM_ERR_NAS           = -2,  /* not a string             */
    GROKNUM_ERR_NAN           = -3,  /* not a number             */
    GROKNUM_ERR_U16_OVERFLOW  = -4,  /* exceeds U16_MAX          */
    GROKNUM_ERR_U32_OVERFLOW  = -5,  /* exceeds U32_MAX          */
    GROKNUM_ERR_U64_OVERFLOW  = -6,  /* exceeds U64_MAX          */
    GROKNUM_ERR_I16_OVERFLOW  = -7,  /* lt I16_MIN or gt I16_MAX */
    GROKNUM_ERR_I32_OVERFLOW  = -8,  /* lt I32_MIN or gt I32_MAX */
    GROKNUM_ERR_I64_OVERFLOW  = -9,  /* lt I64_MIN or gt I64_MAX */
    GROKNUM_ERR_UNKNOWN       = -10, /* unknown                  */
} groknum_err_t;

typedef union {
    uint64_t    u64;
    uint32_t    u32;
    uint16_t    u16;
    int64_t     i64;
    int32_t     i32;
    int16_t     i16;
    int         en;
    double      dbl;
    bool        boo;
} nmsg_field_val_u;

#include "strtoint64.h"

#include <signal.h>
#include <assert.h>

#ifdef __cplusplus
}
#endif

#define NMSG_CLASS   "Net::Nmsg"
#define MSG_CLASS    "Net::Nmsg::Msg"
#define MSG_XS_CLASS "Net::Nmsg::XS::msg"
#define IPV4_CLASS   "Net::Nmsg::Field::IPv4"
#define IPV6_CLASS   "Net::Nmsg::Field::IPv6"

#define MSG_SUBCLASS(class, vid, mid) \
    sprintf(class, MSG_CLASS "::%s::%s", \
                   nmsg_msgmod_vid_to_vname(vid), \
                   nmsg_msgmod_msgtype_to_mname(vid, mid))

#define NMSG_FF_REPEATED    0x01
#define NMSG_FF_REQUIRED    0x02
#define NMSG_FF_HIDDEN      0x04
#define NMSG_FF_NOPRINT     0x08

#define GROKNUM_CROAK(rv, msg)                        \
    switch (rv) {                                     \
        case GROKNUM_ERR_NVREF:                       \
            croak("%s: invalid reference", msg);      \
        case GROKNUM_ERR_NAS:                         \
            croak("%s: not a string", msg);           \
        case GROKNUM_ERR_NAN:                         \
            croak("%s: not an integer", msg);         \
        case GROKNUM_ERR_U16_OVERFLOW:                \
            croak("%s: uint16 overflow", msg);        \
        case GROKNUM_ERR_U32_OVERFLOW:                \
            croak("%s: uint32 overflow", msg);        \
        case GROKNUM_ERR_U64_OVERFLOW:                \
            croak("%s: uint64 overflow", msg);        \
        case GROKNUM_ERR_I16_OVERFLOW:                \
            croak("%s: int16 overflow", msg);         \
        case GROKNUM_ERR_I32_OVERFLOW:                \
            croak("%s: int32 overflow", msg);         \
        case GROKNUM_ERR_I64_OVERFLOW:                \
            croak("%s: int64 overflow", msg);         \
        case GROKNUM_ERR_UNKNOWN:                     \
            croak("%s: unknown error", msg);          \
        default:                                      \
            croak("%s: invalid error code (%d)", rv); \
    }

#define WRAP_MSG(m, msg) \
    char class[100]; \
    HV  *msg_stash; \
    AV  *arr; \
    MSG_SUBCLASS(class, nmsg_message_get_vid(m), nmsg_message_get_msgtype(m)); \
    msg_stash = gv_stashpv(class, TRUE); \
    arr = newAV(); \
    av_push(arr, sv_setref_pv(newSV(0), MSG_XS_CLASS, (char *)m)); \
    msg = sv_bless(newRV_noinc(MUTABLE_SV(arr)), msg_stash);

/* callback hooks */

static PerlInterpreter *orig_perl;
static pthread_mutex_t callback_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t presentation_lock = PTHREAD_MUTEX_INITIALIZER;

SV *
_xs_wrap_msg(pTHX_ nmsg_message_t m) {
    char class[100];
    int32_t vid, mtype;
    const char *vname, *mname;
    HV  *msg_stash;
    AV  *arr;

    vid = nmsg_message_get_vid(m);
    vname = nmsg_msgmod_vid_to_vname(vid);
    if (vname == NULL)
        croak("unknown vendor id %d", vid);
    mtype = nmsg_message_get_msgtype(m);
    mname = nmsg_msgmod_msgtype_to_mname(vid, mtype);
    if (mname == NULL)
        croak("unknown vendor/message type %d/%d", vid, mtype);
    sprintf(class, MSG_CLASS "::%s::%s", vname, mname);
    msg_stash = gv_stashpv(class, TRUE);
    arr = newAV();
    av_push(arr, sv_setref_pv(newSV(0), MSG_XS_CLASS, (char *)m));
    return(sv_bless(newRV_noinc(MUTABLE_SV(arr)), msg_stash));
}

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

void
io_closed_callback(struct nmsg_io_close_event *ce) {

    if (ce->user == NULL ||
        ce->io_type != nmsg_io_io_type_output ||
        ce->close_type == nmsg_io_close_type_eof)
        return;

    //fprintf(stderr, "io_closed_callback: 0x%x\n", (int)ce->user);

    PERL_SET_CONTEXT(orig_perl);
    pthread_mutex_lock(&callback_lock);

    { // C99 compliance

      int   count;
      IV    tmp;
      SV   *ref;
      void *ptr;

      dTHX;
      dSP;

      ENTER;
      SAVETMPS;
      // push args onto stack
      PUSHMARK(sp);
      mXPUSHs(newSViv(ce->close_type));
      //mXPUSHs(newSViv(ce->io_type));
      PUTBACK;
      // re-wrap callback CV in a reference and invoke perl function
      count = call_sv(sv_2mortal(newRV(MUTABLE_SV(ce->user))), G_SCALAR);
      SPAGAIN;
      if (count != 1)
          croak("single return value required from callback");
      ref = POPs;
      if (! SvROK(ref))
          croak("not a reference");
      tmp = SvIV(SvRV(ref));
      ptr = INT2PTR(void *, tmp);
      if (ptr != NULL) {
          //fprintf(stderr, "xs reopen output %p\n", *(ce->output));
          *(ce->output) = ptr;
          //*(ce->output) = INT2PTR(nmsg_output_t, tmp);
          //*(ce->output) = (nmsg_output_t)tmp;
          //fprintf(stderr, "xs reopen output %p\n", *(ce->output));
      }
      PUTBACK;

      // clean up
      FREETMPS;
      LEAVE;
    }

    pthread_mutex_unlock(&callback_lock);

    //fprintf(stderr, "io_closed_callback complete\n");
}

groknum_err_t
_xs_pack_uint16_int(pTHX_ SV *sv, uint16_t *val) {
    UV uv;
    IV iv;
    NV nv;
    int64_t  i64;
    uint64_t u64;
    groknum_err_t rv = GROKNUM_OK;

    if (SvIOK_UV(sv)) {
        uv = SvUV(sv);
        if (uv > UINT16_MAX)
            rv = GROKNUM_ERR_U16_OVERFLOW;
        *val = (uint16_t)uv;
    }
    else if (SvIOK(sv)) {
        iv = SvIV(sv);
        if (iv < 0 || iv > UINT16_MAX)
            rv = GROKNUM_ERR_U16_OVERFLOW;
        *val = (uint16_t)iv;
    }
    else if (SvNOK(sv)) {
        nv = SvNV(sv);
        if (nv < 0 || nv > UINT16_MAX)
            rv = GROKNUM_ERR_U16_OVERFLOW;
        *val = (uint16_t)SvUV(sv);
    }
    else if (SvU64OK(sv)) {
        u64 = SvU64(sv);
        if (u64 > UINT16_MAX)
            rv = GROKNUM_ERR_U16_OVERFLOW;
        *val = (uint16_t)u64;
    }
    else if (SvI64OK(sv)) {
        i64 = SvI64(sv);
        if (i64 < 0 || i64 > UINT16_MAX)
            rv = GROKNUM_ERR_U16_OVERFLOW;
        *val = (uint16_t)i64;
    }
    else
        rv = GROKNUM_ERR_NAN;

    return rv;
}

groknum_err_t
_xs_pack_uint16_strint(pTHX_ SV *sv, uint16_t *val) {
    uint64_t       u64;
    groknum_err_t  rv;

    if (!SvPOK(sv))
        return GROKNUM_ERR_NAS;
    rv = strtoint64(aTHX_ SvPV_nolen(sv), 0, 0, &u64);
    switch (rv) {
        case GROKNUM_OK:
            if (u64 > UINT16_MAX)
                return GROKNUM_ERR_U16_OVERFLOW;
            *val = (uint16_t)u64;
            return GROKNUM_OK;
        case GROKNUM_ERR_I64_OVERFLOW:
        case GROKNUM_ERR_U64_OVERFLOW:
            return GROKNUM_ERR_U16_OVERFLOW;
        default:
            return rv;
    }
    return GROKNUM_ERR_UNKNOWN;
}

uint16_t
_xs_make_uint16(pTHX_ SV *sv) {
    uint16_t      val;
    groknum_err_t rv;

    rv = _xs_pack_uint16_int(aTHX_ sv, &val);
    switch (rv) {
        case GROKNUM_OK:
            return val;
        case GROKNUM_ERR_NAN:
            break;
        default:
            GROKNUM_CROAK(rv, "invalid uint16");
    }
    // check for number-like strings
    if (SvPOK(sv)) {
        rv = _xs_pack_uint16_strint(aTHX_ sv, &val);
        if (rv == GROKNUM_OK)
            return val;
        GROKNUM_CROAK(rv, "invalid uint16");
    }
    GROKNUM_CROAK(GROKNUM_ERR_NAN, "invalid uint16");
}

groknum_err_t
_xs_pack_int16_int(pTHX_ SV *sv, int16_t *val) {
    UV uv;
    IV iv;
    NV nv;
    int64_t  i64;
    uint64_t u64;
    groknum_err_t rv = GROKNUM_OK;

    if (SvIOK_UV(sv)) {
        uv = SvUV(sv);
        if (uv > UINT16_MAX)
            rv = GROKNUM_ERR_I16_OVERFLOW;
        *val = (int16_t)uv;
    }
    else if (SvIOK(sv)) {
        iv = SvIV(sv);
        if (iv < INT16_MIN || iv > INT16_MAX)
            rv = GROKNUM_ERR_I16_OVERFLOW;
        *val = (int16_t)iv;
    }
    else if (SvNOK(sv)) {
        nv = SvNV(sv);
        if (nv < INT16_MIN || nv > INT16_MAX)
            rv = GROKNUM_ERR_I16_OVERFLOW;
        *val = (int16_t)SvIV(sv);
    }
    else if (SvU64OK(sv)) {
        u64 = SvU64(sv);
        if (u64 > INT16_MAX)
            rv = GROKNUM_ERR_I16_OVERFLOW;
        *val = (int16_t)u64;
    }
    else if (SvI64OK(sv)) {
        i64 = SvI64(sv);
        if (i64 < INT16_MIN || i64 > INT16_MAX)
            rv = GROKNUM_ERR_I16_OVERFLOW;
        *val = (int16_t)i64;
    }
    else
        rv = GROKNUM_ERR_NAN;

    return rv;
}

groknum_err_t
_xs_pack_int16_strint(pTHX_ SV *sv, uint16_t *val) {
    uint64_t       i64;
    groknum_err_t  rv;

    if (!SvPOK(sv))
        return GROKNUM_ERR_NAS;
    rv = strtoint64(aTHX_ SvPV_nolen(sv), 0, 1, &i64);
    switch (rv) {
        case GROKNUM_OK:
            if (i64 < INT16_MIN || i64 > INT16_MAX)
                return GROKNUM_ERR_I16_OVERFLOW;
            *val = (int16_t)i64;
            return GROKNUM_OK;
        case GROKNUM_ERR_I64_OVERFLOW:
        case GROKNUM_ERR_U64_OVERFLOW:
            return GROKNUM_ERR_I16_OVERFLOW;
        default:
            return rv;
    }
    return GROKNUM_ERR_UNKNOWN;
}

int16_t
_xs_make_int16(pTHX_ SV *sv) {
    int16_t       val;
    groknum_err_t rv;

    rv = _xs_pack_int16_int(aTHX_ sv, &val);
    switch (rv) {
        case GROKNUM_OK:
            return val;
        case GROKNUM_ERR_NAN:
            break;
        default:
            GROKNUM_CROAK(rv, "invalid int16");
    }
    // check for number-like strings
    if (SvPOK(sv)) {
        rv = _xs_pack_int16_strint(aTHX_ sv, &val);
        if (rv == GROKNUM_OK)
            return val;
        GROKNUM_CROAK(rv, "invalid int16");
    }
    GROKNUM_CROAK(GROKNUM_ERR_NAN, "invalid int16");
}

groknum_err_t
_xs_pack_uint32_int(pTHX_ SV *sv, uint32_t *val) {
    UV uv;
    IV iv;
    NV nv;
    int64_t  i64;
    uint64_t u64;
    groknum_err_t rv = GROKNUM_OK;

    if (SvIOK_UV(sv)) {
        uv = SvUV(sv);
        if (uv > UINT32_MAX)
            rv = GROKNUM_ERR_U32_OVERFLOW;
        *val = (uint32_t)uv;
    }
    else if (SvIOK(sv)) {
        iv = SvIV(sv);
        if (iv < 0 || iv > UINT32_MAX)
            rv = GROKNUM_ERR_U32_OVERFLOW;
        *val = (uint32_t)iv;
    }
    else if (SvNOK(sv)) {
        nv = SvNV(sv);
        if (nv < 0 || nv > UINT32_MAX)
            rv = GROKNUM_ERR_U32_OVERFLOW;
        *val = (uint32_t)SvUV(sv);
    }
    else if (SvU64OK(sv)) {
        u64 = SvU64(sv);
        if (u64 > UINT32_MAX)
            rv = GROKNUM_ERR_U32_OVERFLOW;
        *val = (uint32_t)u64;
    }
    else if (SvI64OK(sv)) {
        i64 = SvI64(sv);
        if (i64 < 0 || i64 > UINT32_MAX)
            rv = GROKNUM_ERR_U32_OVERFLOW;
        *val = (uint32_t)i64;
    }
    else
        rv = GROKNUM_ERR_NAN;

    return rv;
}

groknum_err_t
_xs_pack_uint32_strint(pTHX_ SV *sv, uint32_t *val) {
    uint64_t       u64;
    groknum_err_t  rv;

    if (!SvPOK(sv))
        return GROKNUM_ERR_NAS;
    rv = strtoint64(aTHX_ SvPV_nolen(sv), 0, 0, &u64);
    switch (rv) {
        case GROKNUM_OK:
            if (u64 > UINT32_MAX)
                return GROKNUM_ERR_U32_OVERFLOW;
            *val = (uint32_t)u64;
            return GROKNUM_OK;
        case GROKNUM_ERR_I64_OVERFLOW:
        case GROKNUM_ERR_U64_OVERFLOW:
            return GROKNUM_ERR_U32_OVERFLOW;
        default:
            return rv;
    }
    return GROKNUM_ERR_UNKNOWN;
}

uint32_t
_xs_make_uint32(pTHX_ SV *sv) {
    uint32_t      val;
    groknum_err_t rv;

    rv = _xs_pack_uint32_int(aTHX_ sv, &val);
    switch (rv) {
        case GROKNUM_OK:
            return val;
        case GROKNUM_ERR_NAN:
            break;
        default:
            GROKNUM_CROAK(rv, "invalid uint32");
    }
    // check for number-like strings
    if (SvPOK(sv)) {
        rv = _xs_pack_uint32_strint(aTHX_ sv, &val);
        if (rv == GROKNUM_OK)
            return val;
        GROKNUM_CROAK(rv, "invalid uint32");
    }
    GROKNUM_CROAK(GROKNUM_ERR_NAN, "invalid uint32");
}

groknum_err_t
_xs_pack_int32_int(pTHX_ SV *sv, int32_t *val) {
    UV uv;
    IV iv;
    NV nv;
    int64_t  i64;
    uint64_t u64;
    groknum_err_t rv = GROKNUM_OK;

    if (SvIOK_UV(sv)) {
        uv = SvUV(sv);
        if (uv > INT32_MAX)
            rv = GROKNUM_ERR_I32_OVERFLOW;
        *val = (int32_t)uv;
    }
    else if (SvIOK(sv)) {
        iv = SvIV(sv);
        if (iv < INT32_MIN || iv > INT32_MAX)
            rv = GROKNUM_ERR_I32_OVERFLOW;
        *val = (int32_t)iv;
    }
    else if (SvNOK(sv)) {
        nv = SvNV(sv);
        if (nv < INT32_MIN || nv > INT32_MAX)
            rv = GROKNUM_ERR_I32_OVERFLOW;
        *val = (int32_t)SvIV(sv);
    }
    else if (SvU64OK(sv)) {
        u64 = SvU64(sv);
        if (u64 > INT32_MAX)
            rv = GROKNUM_ERR_I32_OVERFLOW;
        *val = (uint32_t)u64;
    }
    else if (SvI64OK(sv)) {
        i64 = SvI64(sv);
        if (i64 < INT32_MIN || i64 > INT32_MAX)
            rv = GROKNUM_ERR_I32_OVERFLOW;
        *val = (int32_t)i64;
    }
    else
        rv = GROKNUM_ERR_NAN;

    return rv;
}

groknum_err_t
_xs_pack_int32_strint(pTHX_ SV *sv, int32_t *val) {
    int64_t        i64;
    groknum_err_t  rv;

    if (!SvPOK(sv))
        return GROKNUM_ERR_NAS;
    rv = strtoint64(aTHX_ SvPV_nolen(sv), 0, 1, &i64);
    switch (rv) {
        case GROKNUM_OK:
            if (i64 < INT32_MIN || i64 > INT32_MAX)
                return GROKNUM_ERR_I32_OVERFLOW;
            *val = (int32_t)i64;
            return GROKNUM_OK;
        case GROKNUM_ERR_I64_OVERFLOW:
        case GROKNUM_ERR_U64_OVERFLOW:
            return GROKNUM_ERR_I32_OVERFLOW;
        default:
            return rv;
    }
    return GROKNUM_ERR_UNKNOWN;
}

int32_t
_xs_make_int32(pTHX_ SV *sv) {
    int32_t       val;
    groknum_err_t rv;

    rv = _xs_pack_int32_int(aTHX_ sv, &val);
    switch (rv) {
        case GROKNUM_OK:
            return val;
        case GROKNUM_ERR_NAN:
            break;
        default:
            GROKNUM_CROAK(rv, "invalid int32");
    }
    // check for number-like strings
    if (SvPOK(sv)) {
        rv = _xs_pack_int32_strint(aTHX_ sv, &val);
        if (rv == GROKNUM_OK)
            return val;
        GROKNUM_CROAK(rv, "invalid int32");
    }
    GROKNUM_CROAK(GROKNUM_ERR_NAN, "invalid int32");
}

groknum_err_t
_xs_pack_uint64_int(pTHX_ SV *sv, uint64_t *val) {
    IV iv;
    NV nv;
    int64_t i64;

    if (SvIOK_UV(sv)) {
        *val = (uint64_t)SvUV(sv);
    }
    else if (SvIOK(sv)) {
        iv = SvIV(sv);
        if (iv < 0)
            return GROKNUM_ERR_U64_OVERFLOW;
        *val = (uint64_t)iv;
    }
    else if (SvNOK(sv)) {
        nv = SvNV(sv);
        if (nv < 0 || nv > UINT64_MAX)
            return GROKNUM_ERR_U64_OVERFLOW;
        *val = (uint64_t)SvUV(sv);
    }
    else if (SvU64OK(sv)) {
        *val = SvU64(sv);
    }
    else if (SvI64OK(sv)) {
        i64 = SvI64(sv);
        if (i64 < 0)
            return GROKNUM_ERR_U64_OVERFLOW;
        *val = (uint64_t)i64;
    }
    else
        return GROKNUM_ERR_NAN;
    return GROKNUM_OK;
}

groknum_err_t
_xs_pack_uint64_strint(pTHX_ SV *sv, uint64_t *val) {
    if (!SvPOK(sv))
        return GROKNUM_ERR_NAS;
    return strtoint64(aTHX_ SvPV_nolen(sv), 0, 0, val);
}

uint64_t
_xs_make_uint64(pTHX_ SV *sv) {
    uint64_t      val;
    groknum_err_t rv;

    rv = _xs_pack_uint64_int(aTHX_ sv, &val);
    switch (rv) {
        case GROKNUM_OK:
            return val;
        case GROKNUM_ERR_NAN:
            break;
        default:
            GROKNUM_CROAK(rv, "invalid uint64");
    }
    // check for number-like strings
    if (SvPOK(sv)) {
        rv = _xs_pack_uint64_strint(aTHX_ sv, &val);
        if (rv == GROKNUM_OK)
            return val;
        GROKNUM_CROAK(rv, "invalid uint64");
    }
    GROKNUM_CROAK(GROKNUM_ERR_NAN, "invalid uint64");
}

groknum_err_t
_xs_pack_int64_int(pTHX_ SV *sv, int64_t *i64) {
    IV iv;
    NV nv;
    uint64_t u64;

    if (SvIOK_UV(sv)) {
        *i64 = (int64_t)SvUV(sv);
    }
    else if (SvIOK(sv)) {
        iv = SvIV(sv);
        *i64 = (int64_t)iv;
    }
    else if (SvNOK(sv)) {
        nv = SvNV(sv);
        if (nv < INT64_MIN || nv > INT64_MAX)
            return GROKNUM_ERR_I64_OVERFLOW;
        *i64 = (int64_t)SvUV(sv);
    }
    else if (SvU64OK(sv)) {
        u64 = SvU64(sv);
        if (u64 > INT64_MAX)
            return GROKNUM_ERR_I64_OVERFLOW;
        *i64 = (int64_t)u64;
    }
    else if (SvI64OK(sv)) {
        *i64 = SvI64(sv);
    }
    else
        return GROKNUM_ERR_NAN;
    return GROKNUM_OK;
}

groknum_err_t
_xs_pack_int64_strint(pTHX_ SV *sv, int64_t *i64) {
    if (!SvPOK(sv))
        return GROKNUM_ERR_NAS;
    return strtoint64(aTHX_ SvPV_nolen(sv), 0, 1, i64);
}

int64_t
_xs_make_int64(pTHX_ SV *sv) {
    int64_t       val;
    groknum_err_t rv;

    rv = _xs_pack_int64_int(aTHX_ sv, &val);
    switch (rv) {
        case GROKNUM_OK:
            return val;
        case GROKNUM_ERR_NAN:
            break;
        default:
            GROKNUM_CROAK(rv, "invalid int64");
    }
    // check for number-like strings
    if (SvPOK(sv)) {
        rv = _xs_pack_int64_strint(aTHX_ sv, &val);
        if (rv == GROKNUM_OK)
            return val;
        GROKNUM_CROAK(rv, "invalid int64");
    }
    GROKNUM_CROAK(GROKNUM_ERR_NAN, "invalid int64");
}

SV *
_xs_field_to_sv(pTHX_ void *data, size_t len, nmsg_msgmod_field_type type) {

    if (data == NULL)
        croak("oops null data pointer");

    switch (type) {

    case nmsg_msgmod_ft_enum:
    case nmsg_msgmod_ft_int16:
    case nmsg_msgmod_ft_int32:
        return newSViv(*(int *)data);
    case nmsg_msgmod_ft_uint16:
    case nmsg_msgmod_ft_uint32:
        return newSVuv(*(unsigned *)data);
    case nmsg_msgmod_ft_double:
        return newSVnv(*(double *)data);
    case nmsg_msgmod_ft_bool:
        return boolSV(newSViv(*(int *)data));
    case nmsg_msgmod_ft_int64:
        return newSVi64(*(int64_t *)data);
    case nmsg_msgmod_ft_uint64:
        return newSVu64(*(uint64_t *)data);
    case nmsg_msgmod_ft_string:
    case nmsg_msgmod_ft_mlstring:
        // len includes trailing null
        return newSVpv((char *)data, len - 1);
    // case nmsg_msgmod_ft_ip:
    // case nmsg_msgmod_ft_bytes:
    default:
        return newSVpvn((char *)data, len);
    }
}

uint8_t *
_xs_sv_to_field(pTHX_ SV *sv, nmsg_msgmod_field_type type,
                nmsg_field_val_u *data, size_t *len) {
    switch (type) {
        case nmsg_msgmod_ft_int16:
            data->i16 = _xs_make_int16(aTHX_ sv);
            *len = sizeof(int16_t);
            break;
        case nmsg_msgmod_ft_uint16:
            data->u16 = _xs_make_uint16(aTHX_ sv);
            *len = sizeof(uint16_t);
            break;
        case nmsg_msgmod_ft_int32:
            data->i32 = _xs_make_int32(aTHX_ sv);
            *len = sizeof(int32_t);
            break;
        case nmsg_msgmod_ft_uint32:
            data->u32 = _xs_make_uint32(aTHX_ sv);
            *len = sizeof(uint32_t);
            break;
        case nmsg_msgmod_ft_int64:
            data->i64 = _xs_make_int64(aTHX_ sv);
            *len = sizeof(int64_t);
            break;
        case nmsg_msgmod_ft_uint64:
            data->u64 = _xs_make_uint64(aTHX_ sv);
            *len = sizeof(uint64_t);
            break;
        case nmsg_msgmod_ft_enum:
            data->en = (int)SvIV(sv);
            *len = sizeof(int);
            break;
        case nmsg_msgmod_ft_double:
            data->dbl = (double)SvNV(sv);
            break;
        case nmsg_msgmod_ft_bool:
            data->boo = (bool)SvTRUE(sv);
            break;
        case nmsg_msgmod_ft_string:
        case nmsg_msgmod_ft_mlstring:
            data = (void *)SvPV(sv, *len);
            *len += 1;
            break;
        //case nmsg_msgmod_ft_ip:
        //case nmsg_msgmod_ft_bytes:
        default:
            data = (void *)SvPV(sv, *len);
            break;
    }
    return((uint8_t *)data);
}


MODULE = Net::Nmsg		PACKAGE = Net::Nmsg::Util

BOOT:
#define MC(cc) \
    newCONSTSUB(stash, #cc, newSViv( cc ))
//
#define MCE(name, ce) \
    newCONSTSUB(stash, #name, newSViv( ce ))
//
#define MCPV(name, cc) \
    newCONSTSUB(stash, #name, newSVpv( cc, sizeof(cc) ))
// BOOT ends after first blank line outside of a block
{
    HV *stash;

    stash = gv_stashpv("Net::Nmsg::Util", TRUE);

    MC(NMSG_DEFAULT_SNAPLEN);
    MC(NMSG_FLAG_FRAGMENT);
    MC(NMSG_FLAG_ZLIB);
    MC(NMSG_HDRLSZ_V2);
    MC(NMSG_HDRSZ);
    MC(NMSG_IPSZ_MAX);
    MC(NMSG_LENHDRSZ_V1);
    MC(NMSG_LENHDRSZ_V2);
    MC(NMSG_PAYHDRSZ);
    MC(NMSG_RBUFSZ);
    MC(NMSG_RBUF_TIMEOUT);
    MC(NMSG_VERSION);
    MC(NMSG_WBUFSZ_ETHER);
    MC(NMSG_WBUFSZ_JUMBO);
    MC(NMSG_WBUFSZ_MAX);
    MC(NMSG_WBUFSZ_MIN);

    MCE(NMSG_INPUT_TYPE,  nmsg_io_io_type_input );
    MCE(NMSG_OUTPUT_TYPE, nmsg_io_io_type_output);

    MCE(NMSG_INPUT_TYPE_STREAM, nmsg_input_type_stream);
    MCE(NMSG_INPUT_TYPE_PRES,   nmsg_input_type_pres  );
    MCE(NMSG_INPUT_TYPE_PCAP,   nmsg_input_type_pcap  );

    MCE(NMSG_OUTPUT_TYPE_STREAM,   nmsg_output_type_stream  );
    MCE(NMSG_OUTPUT_TYPE_PRES,     nmsg_output_type_pres    );
    MCE(NMSG_OUTPUT_TYPE_CALLBACK, nmsg_output_type_callback);

    MCE(NMSG_OUTPUT_MODE_STRIPE, nmsg_io_output_mode_stripe);
    MCE(NMSG_OUTPUT_MODE_MIRROR, nmsg_io_output_mode_mirror);

    MCE(NMSG_CLOSE_TYPE_EOF,      nmsg_io_close_type_eof     );
    MCE(NMSG_CLOSE_TYPE_COUNT,    nmsg_io_close_type_count   );
    MCE(NMSG_CLOSE_TYPE_INTERVAL, nmsg_io_close_type_interval);

    MCE(NMSG_PCAP_TYPE_FILE, nmsg_pcap_type_file);
    MCE(NMSG_PCAP_TYPE_LIVE, nmsg_pcap_type_live);

    MCE(NMSG_RES_SUCCESS,          nmsg_res_success         );
    MCE(NMSG_RES_FAILURE,          nmsg_res_failure         );
    MCE(NMSG_RES_EOF,              nmsg_res_eof             );
    MCE(NMSG_RES_MEMFAIL,          nmsg_res_memfail         );
    MCE(NMSG_RES_PBUF_READY,       nmsg_res_pbuf_ready      );
    MCE(NMSG_RES_NOTIMPL,          nmsg_res_notimpl         );
    MCE(NMSG_RES_STOP,             nmsg_res_stop            );
    MCE(NMSG_RES_AGAIN,            nmsg_res_again           );
    MCE(NMSG_RES_PARSE_ERROR,      nmsg_res_parse_error     );
    MCE(NMSG_RES_PCAP_ERROR,       nmsg_res_pcap_error      );
    MCE(NMSG_RES_MAGIC_MISMATCH,   nmsg_res_magic_mismatch  );
    MCE(NMSG_RES_VERSION_MISMATCH, nmsg_res_version_mismatch);

    MC(NMSG_FF_REPEATED);
    MC(NMSG_FF_REQUIRED);
    MC(NMSG_FF_HIDDEN);
    MC(NMSG_FF_NOPRINT);

    MCE(NMSG_FT_ENUM,       nmsg_msgmod_ft_enum    );
    MCE(NMSG_FT_BYTES,      nmsg_msgmod_ft_bytes   );
    MCE(NMSG_FT_STRING,     nmsg_msgmod_ft_string  );
    MCE(NMSG_FT_MLSTRING,   nmsg_msgmod_ft_mlstring);
    MCE(NMSG_FT_IP,         nmsg_msgmod_ft_ip      );
    MCE(NMSG_FT_UINT16,     nmsg_msgmod_ft_uint16  );
    MCE(NMSG_FT_UINT32,     nmsg_msgmod_ft_uint32  );
    MCE(NMSG_FT_UINT64,     nmsg_msgmod_ft_uint64  );
    MCE(NMSG_FT_INT16,      nmsg_msgmod_ft_int16   );
    MCE(NMSG_FT_INT32,      nmsg_msgmod_ft_int32   );
    MCE(NMSG_FT_INT64,      nmsg_msgmod_ft_int64   );
    MCE(NMSG_FT_DOUBLE,     nmsg_msgmod_ft_double  );
    MCE(NMSG_FT_BOOL,       nmsg_msgmod_ft_bool    );

    MCE(NMSG_ALIAS_OPERATOR,    nmsg_alias_operator);
    MCE(NMSG_ALIAS_GROUP,       nmsg_alias_group   );

    MATH_INT64_BOOT;
}


MODULE = Net::Nmsg		PACKAGE = Net::Nmsg     PREFIX = nmsg_

void
_nmsg_init_lib()
    PREINIT:
    nmsg_res    res;
    CODE:
    if (NULL == orig_perl)
        orig_perl = Perl_get_context();
    res = nmsg_init();
    if (res != nmsg_res_success)
        croak("nmsg_init failed: %s", nmsg_res_lookup(res));

void
nmsg_set_autoclose(autoclose)
    _Bool   autoclose

void
nmsg_set_debug(debug)
    int debug


MODULE = Net::Nmsg		PACKAGE = Net::Nmsg::Util   PREFIX = nmsg_

void
nmsg_chalias_lookup(ch)
    const char *ch
    PREINIT:
    char **alias = NULL;
    int num_aliases;
    int i;
    PPCODE:
    num_aliases = nmsg_chalias_lookup(ch, &alias);
    if (num_aliases > 0) {
        for (i = 0; i < num_aliases; i++)
            mXPUSHs(newSVpv(alias[i], 0));
    }
    if (alias != NULL)
        nmsg_chalias_free(&alias);

const char *
nmsg_alias_by_key(ae, key)
	nmsg_alias_e    ae
	unsigned        key

unsigned
nmsg_alias_by_value(ae, value)
	nmsg_alias_e    ae
	const char     *value

void
find_all_devs()
    PREINIT:
    char    err[PCAP_ERRBUF_SIZE];
    PPCODE:
    pcap_if_t *devs, *d;

    if (pcap_findalldevs(&devs, err) == -1)
        croak("%s", err);

    for (d=devs; d; d=d->next) {
        mXPUSHs(newSVpv(d->name, 0));
        if (d->description)
            mXPUSHs(newSVpv(d->description, 0));
        else {
            if ((strcmp(d->name,"lo")  == 0) || (strcmp(d->name,"lo0") == 0))
                mXPUSHs(newSVpv("loopback device", 0));
            else
                mXPUSHs(newSVpv("unknown device", 0));
        }
    }
    pcap_freealldevs(devs);

const char *
lookup_result(val)
    enum nmsg_res val
    CODE:
    RETVAL = nmsg_res_lookup(val);
    OUTPUT:
    RETVAL

void
get_timestring()
    PREINIT:
    char    now[32];
    struct  timespec ts;
    struct  tm *tm;
    time_t  t;
    char   *tstr;
    PPCODE:
    nmsg_timespec_get(&ts);
    t = (time_t) ts.tv_sec;
    tm = gmtime(&t);
    strftime(now, sizeof(now), "%Y%m%d.%H%M.%s", tm);
    nmsg_asprintf(&tstr, "%s.%09ld", now, ts.tv_nsec);
    if (tstr == NULL)
        croak("problem allocating time string");
    mXPUSHs(newSVpv(tstr, 0));
    Safefree(tstr);


MODULE = Net::Nmsg  PACKAGE = Net::Nmsg::Util   PREFIX = nmsg_msgmod_

PROTOTYPES: ENABLE

nmsg_msgmod_t
_msgmod_lookup(vid, msgtype)
    unsigned    vid
    unsigned    msgtype
    CODE:
    RETVAL = nmsg_msgmod_lookup(vid, msgtype);
    OUTPUT:
    RETVAL

size_t
nmsg_msgmod_get_max_vid()

size_t
nmsg_msgmod_get_max_msgtype(vid)
	unsigned    vid

unsigned
nmsg_msgmod_mname_to_msgtype(vid, mname)
	unsigned    vid
	const char *mname

const char *
nmsg_msgmod_msgtype_to_mname(vid, msgtype)
	unsigned    vid
	unsigned    msgtype

const char *
nmsg_msgmod_vid_to_vname(vid)
	unsigned    vid

unsigned
nmsg_msgmod_vname_to_vid(vname)
	char *vname


MODULE = Net::Nmsg  PACKAGE = Net::Nmsg::XS::io PREFIX = nmsg_io_

PROTOTYPES: ENABLE

Net::Nmsg::XS::io
init(CLASS)
  const char *CLASS
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = nmsg_io_init();
    OUTPUT:
    RETVAL

void
DESTROY(THIS)
	Net::Nmsg::XS::io   THIS
    CODE:
    nmsg_io_destroy(&THIS);

void
nmsg_io_breakloop(THIS)
	Net::Nmsg::XS::io   THIS

void
loop(THIS)
	Net::Nmsg::XS::io   THIS
    PREINIT:
    nmsg_res    res;
    U32         SAVE_signals;
    CODE:
    SAVE_signals = PL_signals;
    PL_signals |= PERL_SIGNALS_UNSAFE_FLAG;
    res = nmsg_io_loop(THIS);
    PL_signals = SAVE_signals;
    if (res != nmsg_res_success)
        croak("loop failure(%d): %s", res, nmsg_res_lookup(res));

void
_add_input(THIS, input, ...)
	Net::Nmsg::XS::io       THIS
    Net::Nmsg::XS::input    input
    PREINIT:
	void *user = NULL;
    nmsg_res    res;
    CODE:
    if (items > 2) {
        if SvROK(ST(2))
            user = SvRV(ST(2));
        else if SvOK(ST(2))
            croak("not a reference");
    }
    res = nmsg_io_add_input(THIS, input, user);
    if (res != nmsg_res_success)
        croak("nmsg_io_add_input failed: %s", nmsg_res_lookup(res));
    if (user != NULL)
        nmsg_io_set_close_fp(THIS, io_closed_callback);

void
_add_output(THIS, output, ...)
	Net::Nmsg::XS::io       THIS
	Net::Nmsg::XS::output   output
    PREINIT:
	void *user = NULL;
    nmsg_res    res;
    CODE:
    if (items > 2) {
        if SvROK(ST(2))
            user = SvRV(ST(2));
        else if SvOK(ST(2))
            croak("not a reference");
    }
    res = nmsg_io_add_output(THIS, output, user);
    if (res != nmsg_res_success)
        croak("nmsg_io_add_output failed: %s", nmsg_res_lookup(res));
    if (user != NULL)
        nmsg_io_set_close_fp(THIS, io_closed_callback);

void
nmsg_io_set_count(THIS, value)
	Net::Nmsg::XS::io   THIS
	unsigned            value

void
nmsg_io_set_debug(THIS, value)
	Net::Nmsg::XS::io   THIS
	unsigned            value

void
nmsg_io_set_interval(THIS, value)
	Net::Nmsg::XS::io   THIS
	unsigned            value

void
nmsg_io_set_interval_randomized(THIS, value)
	Net::Nmsg::XS::io   THIS
	bool                value

void
nmsg_io_set_output_mode(THIS, value)
	Net::Nmsg::XS::io   THIS
	nmsg_io_output_mode value

void
set_mirror(THIS, value)
	Net::Nmsg::XS::io   THIS
	unsigned            value
    CODE:
    if (value > 0)
        nmsg_io_set_output_mode(THIS, nmsg_io_output_mode_mirror);
    else
        nmsg_io_set_output_mode(THIS, nmsg_io_output_mode_stripe);


MODULE = Net::Nmsg  PACKAGE = Net::Nmsg::XS::nmsg_pcap  PREFIX=nmsg_pcap_

PROTOTYPES: ENABLE

Net::Nmsg::XS::nmsg_pcap
_input_open(CLASS, pcap)
    const char          *CLASS
    Net::Nmsg::XS::pcap  pcap
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = nmsg_pcap_input_open(pcap);
    if (RETVAL == NULL)
        croak("nmsg_pcap_input_open() failed");
    OUTPUT:
    RETVAL

void
destroy(THIS)
    Net::Nmsg::XS::nmsg_pcap    THIS
    PREINIT:
    nmsg_res    res;
    CODE:
    res = nmsg_pcap_input_close(&THIS);
    if (res != nmsg_res_success)
        fprintf(stderr, "nmsg_pcap_input_close failed: %s", nmsg_res_lookup(res));

void
set_bpf(THIS, bpf)
    Net::Nmsg::XS::nmsg_pcap    THIS
    char *bpf
    PREINIT:
    nmsg_res    res;
    CODE:
    res = nmsg_pcap_input_setfilter(THIS, bpf);
    if (res != nmsg_res_success)
        croak("nmsg_pcap_input_setfilter failed: %s", nmsg_res_lookup(res));

nmsg_pcap_type
nmsg_pcap_get_type(THIS)
	Net::Nmsg::XS::nmsg_pcap    THIS


MODULE = Net::Nmsg  PACKAGE = Net::Nmsg::XS::pcap   PREFIX = pcap_

PROTOTYPES: ENABLE

Net::Nmsg::XS::pcap
open_offline(CLASS, fname)
    const char  *CLASS
    const char  *fname
    PREINIT:
    char    err[PCAP_ERRBUF_SIZE];
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = pcap_open_offline(fname, err);
    if (RETVAL == NULL)
        croak("pcap_open_offline() failed: %s", err);
    OUTPUT:
    RETVAL

Net::Nmsg::XS::pcap
open_live(CLASS, iface, snaplen, promisc)
    const char *CLASS
    const char *iface
    int         snaplen
    int         promisc
    PREINIT:
    char    err[PCAP_ERRBUF_SIZE];
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = pcap_open_live(iface, snaplen, promisc, 0, err);
    if (RETVAL == NULL)
        croak("pcap_open_offline() failed: %s", err);
    OUTPUT:
    RETVAL

void
destroy(THIS)
    Net::Nmsg::XS::pcap THIS
    CODE:
    pcap_close(THIS);

int
set_snaplen(THIS, snaplen)
    Net::Nmsg::XS::pcap THIS
    int                 snaplen
    CODE:
#ifdef LIMITED_PCAP
    PERL_UNUSED_VAR(snaplen);
    croak("pcap_set_snaplen unavailable in this version of libpcap");
#else
    RETVAL = pcap_set_snaplen(THIS, snaplen);
#endif /* LIMITED_PCAP */
    OUTPUT:
    RETVAL

int
set_promisc(THIS, promisc)
    Net::Nmsg::XS::pcap THIS
    int                 promisc
    CODE:
#ifdef LIMITED_PCAP
    PERL_UNUSED_VAR(promisc);
    croak("pcap_set_promisc unavailable in this version of libpcap");
#else
    RETVAL = pcap_set_promisc(THIS, promisc);
#endif /* LIMITED_PCAP */
    OUTPUT:
    RETVAL

void
get_selectable_fd(THIS)
    Net::Nmsg::XS::pcap THIS
    PREINIT:
    int res;
    PPCODE:
    res = pcap_get_selectable_fd(THIS);
    if (res != -1)
        mXPUSHi(res);

int
pcap_fileno(THIS)
    Net::Nmsg::XS::pcap THIS

char *
pcap_geterr(THIS)
    Net::Nmsg::XS::pcap THIS


MODULE = Net::Nmsg  PACKAGE = Net::Nmsg::XS::input  PREFIX = nmsg_input_

PROTOTYPES: ENABLE

void
destroy(THIS)
    Net::Nmsg::XS::input    THIS
    CODE:
    nmsg_input_close(&THIS);

Net::Nmsg::XS::input_file
nmsg_input_open_file(CLASS, fh)
    const char   *CLASS
    PerlIO *fh
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = nmsg_input_open_file(PerlIO_fileno(fh));
    if (RETVAL == NULL)
        croak("nmsg_input_open_file() failed");
    OUTPUT:
    RETVAL

Net::Nmsg::XS::input_json
nmsg_input_open_json(CLASS, fh)
    const char   *CLASS
    PerlIO *fh
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = nmsg_input_open_json(PerlIO_fileno(fh));
    if (RETVAL == NULL)
        croak("nmsg_input_open_json() failed");
    OUTPUT:
    RETVAL

Net::Nmsg::XS::input_sock
nmsg_input_open_sock(CLASS, fh)
    const char   *CLASS
    PerlIO *fh
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = nmsg_input_open_sock(PerlIO_fileno(fh));
    if (RETVAL == NULL)
        croak("nmsg_input_open_sock() failed");
    OUTPUT:
    RETVAL

Net::Nmsg::XS::input_pres
_open_pres(CLASS, fh, vid, mid)
    const char  *CLASS
    PerlIO      *fh
    unsigned     vid
    unsigned     mid
    PREINIT:
    nmsg_msgmod_t   mod;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    mod = nmsg_msgmod_lookup(vid, mid);
    if (mod == NULL)
        croak("unknown vendor id '%d' or message type '%d'", vid, mid);
    RETVAL = nmsg_input_open_pres(PerlIO_fileno(fh), mod);
    if (RETVAL == NULL)
        croak("nmsg_input_open_pres() failed");
    OUTPUT:
    RETVAL

Net::Nmsg::XS::input_pcap
_open_pcap(CLASS, pcap, vid, mid)
    const char                 *CLASS
    Net::Nmsg::XS::nmsg_pcap    pcap
    unsigned                    vid
    unsigned                    mid
    PREINIT:
    nmsg_msgmod_t   mod;
    CODE:
    PERL_UNUSED_VAR(CLASS);
    mod = nmsg_msgmod_lookup(vid, mid);
    if (mod == NULL)
        croak("unknown vendor id '%d' or message type '%d'", vid, mid);
    RETVAL = nmsg_input_open_pcap(pcap, mod);
    if (RETVAL == NULL)
        croak("nmsg_input_open_pcap() failed");
    OUTPUT:
    RETVAL

void
nmsg_input_set_filter_source(THIS, value)
	Net::Nmsg::XS::input    THIS
	unsigned    value

void
_set_filter_group(THIS, value)
	Net::Nmsg::XS::input    THIS
	unsigned    value
        CODE:
        nmsg_input_set_filter_group(THIS, value);

void
_set_filter_operator(THIS, value)
	Net::Nmsg::XS::input    THIS
	unsigned    value
        CODE:
        nmsg_input_set_filter_operator(THIS, value);

void
_set_filter_msgtype(THIS, vid, mid)
	Net::Nmsg::XS::input    THIS
	unsigned    vid
	unsigned    mid
    CODE:
    nmsg_input_set_filter_msgtype(THIS, vid, mid);

void
nmsg_input_set_blocking_io(THIS, flag)
    Net::Nmsg::XS::input    THIS
    bool    flag
    PREINIT:
    nmsg_res    res;
    PPCODE:
    res = nmsg_input_set_blocking_io(THIS, flag);
    if (res == nmsg_res_success)
        mXPUSHi(flag);

void
read(THIS, blocking_io=true)
    Net::Nmsg::XS::input    THIS
    bool                    blocking_io
    PREINIT:
    nmsg_message_t  m;
    nmsg_res        res;
    U32             SAVE_signals;      
    PPCODE:
    res = nmsg_res_failure;
    while (res != nmsg_res_success) {
        SAVE_signals = PL_signals;
        PL_signals |= PERL_SIGNALS_UNSAFE_FLAG;
        res = nmsg_input_read(THIS, &m);
        PL_signals = SAVE_signals;
        switch (res) {
        case (nmsg_res_success):
            mXPUSHs(_xs_wrap_msg(aTHX_ m));
            goto last_read;
        case (nmsg_res_again):
            if (blocking_io != true)
                goto last_read;
            break;
        case (nmsg_res_eof):
            goto last_read;
        default:
            croak("nmsg_input_read() failed: %s", nmsg_res_lookup(res));
        }
    }
    last_read:
        // return

nmsg_res
loop(THIS, cb, count)
    Net::Nmsg::XS::input    THIS
    int     count
    CV     *cb
    PREINIT:
    nmsg_res    res;
    U32         SAVE_signals;
    CODE:
    SAVE_signals = PL_signals;
    PL_signals |= PERL_SIGNALS_UNSAFE_FLAG;
    res = nmsg_input_loop(THIS, count, output_callback, (void *)cb);
    PL_signals = SAVE_signals;
    if (res != nmsg_res_success && res != nmsg_res_eof)
        croak("nmsg_input_loop() failed(%d): %s", res, nmsg_res_lookup(res));
    RETVAL = res;
    OUTPUT:
    RETVAL


MODULE = Net::Nmsg  PACKAGE = Net::Nmsg::XS::output PREFIX = nmsg_output_

PROTOTYPES: ENABLE

void
destroy(THIS)
    Net::Nmsg::XS::output   THIS
    CODE:
    nmsg_output_close(&THIS);

Net::Nmsg::XS::output_file
open_file(CLASS, fh, bufsz)
    const char   *CLASS
    PerlIO *fh
    size_t  bufsz
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = nmsg_output_open_file(PerlIO_fileno(fh), bufsz);
    OUTPUT:
    RETVAL

Net::Nmsg::XS::output_json
open_json(CLASS, fh)
    const char   *CLASS
    PerlIO *fh
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = nmsg_output_open_json(PerlIO_fileno(fh));
    OUTPUT:
    RETVAL

Net::Nmsg::XS::output_sock
open_sock(CLASS, fh, bufsz)
    const char   *CLASS
    PerlIO *fh
    size_t  bufsz
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = nmsg_output_open_sock(PerlIO_fileno(fh), bufsz);
    OUTPUT:
    RETVAL

Net::Nmsg::XS::output_pres
open_pres(CLASS, fh)
    const char   *CLASS
    PerlIO *fh
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = nmsg_output_open_pres(PerlIO_fileno(fh));
    OUTPUT:
    RETVAL

Net::Nmsg::XS::output_cb
open_callback(CLASS, cb)
    const char    *CLASS
    CV      *cb
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = nmsg_output_open_callback(output_callback, (void *)cb);
    OUTPUT:
    RETVAL

void
nmsg_output_set_buffered(THIS, value)
	Net::Nmsg::XS::output   THIS
	bool    value

void
nmsg_output_set_endline(THIS, value)
	Net::Nmsg::XS::output   THIS
	const char *value

void
nmsg_output_set_rate(THIS, rate, freq, rate_obj)
    Net::Nmsg::XS::output THIS
    unsigned              rate
    unsigned              freq
    Net::Nmsg::XS::rate   rate_obj
    CODE:
    PERL_UNUSED_VAR(rate);
    PERL_UNUSED_VAR(freq);
    nmsg_output_set_rate(THIS, rate_obj);

void
nmsg_output_set_zlibout(THIS, value)
	Net::Nmsg::XS::output   THIS
	bool    value

void
nmsg_output_set_group(THIS, value)
	Net::Nmsg::XS::output   THIS
	unsigned    value

void
nmsg_output_set_operator(THIS, value)
	Net::Nmsg::XS::output   THIS
	unsigned    value

void
nmsg_output_set_source(THIS, value)
	Net::Nmsg::XS::output   THIS
	unsigned    value

void
nmsg_output_set_filter_msgtype(THIS, vid, mid)
	Net::Nmsg::XS::output   THIS
	unsigned    vid
	unsigned    mid

void
_write(THIS, msg)
    Net::Nmsg::XS::output   THIS
    Net::Nmsg::XS::msg      msg
    PREINIT:
    nmsg_res    res;
    U32         SAVE_signals;
    CODE:
    SAVE_signals = PL_signals;
    PL_signals |= PERL_SIGNALS_UNSAFE_FLAG;
    res = nmsg_output_write(THIS, msg);
    PL_signals = SAVE_signals;
    if (res != nmsg_res_success)
        croak("nmsg_output_write() failed: %s", nmsg_res_lookup(res));


MODULE = Net::Nmsg  PACKAGE = Net::Nmsg::XS::rate PREFIX = nmsg_rate_

PROTOTYPES: ENABLE

Net::Nmsg::XS::rate
nmsg_rate_init(CLASS, rate, freq)
    char           *CLASS
    unsigned        rate
    unsigned        freq
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = nmsg_rate_init(rate, freq);
    if (RETVAL == NULL)
        croak("rate error %d/%d", rate, freq);
    OUTPUT:
    RETVAL

void
DESTROY(THIS)
    Net::Nmsg::XS::rate THIS
    CODE:
    nmsg_rate_destroy(&THIS);


MODULE = Net::Nmsg  PACKAGE = Net::Nmsg::XS::msg PREFIX = nmsg_message_

PROTOTYPES: ENABLE

Net::Nmsg::XS::msg
nmsg_message_init(CLASS, mod)
    char           *CLASS
    nmsg_msgmod_t   mod
    CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = nmsg_message_init(mod);
    OUTPUT:
    RETVAL

void
DESTROY(THIS)
    Net::Nmsg::XS::msg  THIS
    CODE:
    nmsg_message_destroy(&THIS);

uint32_t
nmsg_message_get_source(THIS)
    Net::Nmsg::XS::msg  THIS

uint32_t
nmsg_message_get_operator(THIS)
    Net::Nmsg::XS::msg  THIS

uint32_t
nmsg_message_get_group(THIS)
    Net::Nmsg::XS::msg  THIS

void
get_time(THIS)
    Net::Nmsg::XS::msg  THIS
    PREINIT:
    struct timespec ts;
    PPCODE:
    nmsg_message_get_time(THIS, &ts);
    mXPUSHi(ts.tv_sec);
    mXPUSHi(ts.tv_nsec);

void
get_num_fields(THIS)
    Net::Nmsg::XS::msg  THIS
    PREINIT:
    nmsg_res  res;
    size_t    len;
    PPCODE:
    res = nmsg_message_get_num_fields(THIS, &len);
    if (res == nmsg_res_success)
        mXPUSHu(len);

void
get_num_field_values(THIS, field)
    Net::Nmsg::XS::msg  THIS
    const char         *field
    PREINIT:
    nmsg_res  res;
    size_t    len;
    PPCODE:
    res = nmsg_message_get_num_field_values(THIS, field, &len);
    if (res == nmsg_res_success)
        mXPUSHu(len);

void
get_num_field_values_by_idx(THIS, idx)
    Net::Nmsg::XS::msg  THIS
    unsigned            idx
    PREINIT:
    nmsg_res  res;
    size_t    len;
    PPCODE:
    res = nmsg_message_get_num_field_values_by_idx(THIS, idx, &len);
    if (res == nmsg_res_success)
        mXPUSHu(len);

void
get_field(THIS, field, v_idx = 0)
    Net::Nmsg::XS::msg  THIS
    const char         *field
    unsigned            v_idx
    PREINIT:
    nmsg_res                res;
    size_t                  len;
    void                   *data;
    nmsg_msgmod_field_type  type;
    PPCODE:
    res = nmsg_message_get_field(THIS, field, v_idx, &data, &len);
    if (res == nmsg_res_success && data != NULL) {
        res = nmsg_message_get_field_type(THIS, field, &type);
        if (res == nmsg_res_success) {
            mXPUSHs(_xs_field_to_sv(aTHX_ data, len, type));
        }
        else
            croak("nmsg_message_get_field_type failed: %s",
                  nmsg_res_lookup(res));
    }

void
get_field_vals(THIS, field)
    Net::Nmsg::XS::msg  THIS
    const char         *field
    PREINIT:
    nmsg_res                res;
    size_t                  len;
    void                   *data;
    nmsg_msgmod_field_type  type;
    int                     i;
    PPCODE:
    res = nmsg_message_get_field_type(THIS, field, &type);
    if (res != nmsg_res_success)
        croak("nmsg_message_get_field_type failed: %s", nmsg_res_lookup(res));
    for (i = 0; ; i++) {
        res = nmsg_message_get_field(THIS, field, i, &data, &len);
        if (res != nmsg_res_success || data == NULL)
            break;
        mXPUSHs(_xs_field_to_sv(aTHX_ data, len, type));
    }

void
get_field_by_idx(THIS, f_idx, v_idx = 0)
    Net::Nmsg::XS::msg  THIS
    unsigned            f_idx
    unsigned            v_idx
    PREINIT:
    nmsg_res               res;
    nmsg_msgmod_field_type type;
    size_t                 len;
    void                  *data;
    PPCODE:
    res = nmsg_message_get_field_by_idx(THIS, f_idx, v_idx, &data, &len);
    if (res == nmsg_res_success) {
        res = nmsg_message_get_field_type_by_idx(THIS, f_idx, &type);
        if (res == nmsg_res_success && data != NULL) {
            mXPUSHs(_xs_field_to_sv(aTHX_ data, len, type));
        }
        else if (res != nmsg_res_success)
            croak("nmsg_message_get_field_type_by_idx failed: %s",
                  nmsg_res_lookup(res));
    }

void
get_field_vals_by_idx(THIS, f_idx)
    Net::Nmsg::XS::msg  THIS
    unsigned            f_idx
    PREINIT:
    nmsg_res                res;
    nmsg_msgmod_field_type  type;
    size_t                  len;
    void                   *data;
    int                     i;
    PPCODE:
    res = nmsg_message_get_field_type_by_idx(THIS, f_idx, &type);
    if (res == nmsg_res_success) {
        for (i = 0; ; i++) {
            res = nmsg_message_get_field_by_idx(THIS, f_idx, i, &data, &len);
            if (res != nmsg_res_success || data == NULL)
                break;
            mXPUSHs(_xs_field_to_sv(aTHX_ data, len, type));
        }
    }

void
get_field_flags(THIS, field)
    Net::Nmsg::XS::msg  THIS
    const char         *field
    PREINIT:
    nmsg_res    res;
    unsigned    flags;
    PPCODE:
    res = nmsg_message_get_field_flags(THIS, field, &flags);
    if (res == nmsg_res_success)
        mXPUSHu(flags);

void
get_field_flags_by_idx(THIS, f_idx)
    Net::Nmsg::XS::msg  THIS
    unsigned            f_idx
    PREINIT:
    nmsg_res    res;
    unsigned    flags;
    PPCODE:
    res = nmsg_message_get_field_flags_by_idx(THIS, f_idx, &flags);
    if (res == nmsg_res_success)
        mXPUSHu(flags);

void
get_field_idx(THIS, name)
    Net::Nmsg::XS::msg  THIS
    const char         *name
    PREINIT:
    nmsg_res    res;
    unsigned    idx;
    PPCODE:
    res = nmsg_message_get_field_idx(THIS, name, &idx);
    if (res == nmsg_res_success)
        mXPUSHu(idx);

void
get_field_name(THIS, idx)
    Net::Nmsg::XS::msg  THIS
    unsigned            idx
    PREINIT:
    nmsg_res    res;
    const char *name;
    PPCODE:
    res = nmsg_message_get_field_name(THIS, idx, &name);
    if (res == nmsg_res_success)
        mXPUSHs(newSVpv(name, 0));

void
get_field_type(THIS, name)
    Net::Nmsg::XS::msg  THIS
    const char         *name;
    PREINIT:
    nmsg_res                res;
    nmsg_msgmod_field_type  type;
    PPCODE:
    res = nmsg_message_get_field_type(THIS, name, &type);
    if (res == nmsg_res_success)
        mXPUSHi(type);

void
get_field_type_by_idx(THIS, idx)
    Net::Nmsg::XS::msg  THIS
    unsigned            idx
    PREINIT:
    nmsg_res                res;
    nmsg_msgmod_field_type  type;
    PPCODE:
    res = nmsg_message_get_field_type_by_idx(THIS, idx, &type);
    if (res == nmsg_res_success)
        mXPUSHi(type);

void
enum_name_to_value(THIS, field, name)
    Net::Nmsg::XS::msg  THIS
    const char         *field
    const char         *name
    PREINIT:
    nmsg_res    res;
    unsigned    value;
    PPCODE:
    res = nmsg_message_enum_name_to_value(THIS, field, name, &value);
    if (res == nmsg_res_success)
        mXPUSHu(value);

void
enum_name_to_value_by_idx(THIS, f_idx, name)
    Net::Nmsg::XS::msg  THIS
    unsigned            f_idx
    const char         *name
    PREINIT:
    nmsg_res    res;
    unsigned    value;
    PPCODE:
    res = nmsg_message_enum_name_to_value_by_idx(THIS, f_idx, name, &value);
    if (res == nmsg_res_success)
        mXPUSHu(value);

void
enum_value_to_name(THIS, field, value)
    Net::Nmsg::XS::msg  THIS
    const char         *field
    unsigned            value
    PREINIT:
    nmsg_res    res;
    const char *name;
    PPCODE:
    res = nmsg_message_enum_value_to_name(THIS, field, value, &name);
    if (res == nmsg_res_success)
        mXPUSHs(newSVpv(name, 0));

void
enum_value_to_name_by_idx(THIS, f_idx, value)
    Net::Nmsg::XS::msg  THIS
    unsigned            f_idx
    unsigned            value
    PREINIT:
    nmsg_res    res;
    const char *name;
    PPCODE:
    res = nmsg_message_enum_value_to_name_by_idx(THIS, f_idx, value, &name);
    if (res == nmsg_res_success)
        mXPUSHs(newSVpv(name, 0));

void
set_field(THIS, field, v_idx, sv)
    Net::Nmsg::XS::msg  THIS
    const char         *field
    unsigned            v_idx
    SV                 *sv
    PREINIT:
    nmsg_res                res;
    nmsg_msgmod_field_type  type;
    nmsg_field_val_u        data;
    uint8_t                *bp;
    size_t                  len;
    CODE:
    res = nmsg_message_get_field_type(THIS, field, &type);
    if (res == nmsg_res_success) {
        bp = _xs_sv_to_field(aTHX_ sv, type, &data, &len);
        res = nmsg_message_set_field(THIS, field, v_idx, bp, len);
        if (res != nmsg_res_success)
            croak("nmsg_message_set_field failed: %s", nmsg_res_lookup(res));
    }
    else
        croak("nmsg_message_get_field_type failed: %s", nmsg_res_lookup(res));

void
set_field_by_idx(THIS, f_idx, v_idx, sv)
    Net::Nmsg::XS::msg  THIS
    unsigned            f_idx
    unsigned            v_idx
    SV                 *sv;
    PREINIT:
    nmsg_res                res;
    nmsg_msgmod_field_type  type;
    nmsg_field_val_u        data;
    uint8_t                *bp;
    size_t                  len;
    CODE:
    res = nmsg_message_get_field_type_by_idx(THIS, f_idx, &type);
    if (res == nmsg_res_success) {
        bp = _xs_sv_to_field(aTHX_ sv, type, &data, &len);
        res = nmsg_message_set_field_by_idx(THIS, f_idx, v_idx, bp, len);
        if (res != nmsg_res_success)
            croak("nmsg_message_set_field_by_idx failed: %s",
                  nmsg_res_lookup(res));
    }
    else
        croak("nmsg_message_get_field_type_by_idx failed: %s",
              nmsg_res_lookup(res));

void
nmsg_message_set_source(THIS, source)
    Net::Nmsg::XS::msg  THIS
    uint32_t            source

void
nmsg_message_set_operator(THIS, operator)
    Net::Nmsg::XS::msg  THIS
    uint32_t            operator

void
nmsg_message_set_group(THIS, group)
    Net::Nmsg::XS::msg  THIS
    uint32_t            group

void
set_time(THIS, time_sec, time_nsec)
    Net::Nmsg::XS::msg  THIS
    long                time_sec
    int                 time_nsec
    PREINIT:
    struct timespec ts;
    PPCODE:
    ts.tv_sec = time_sec;
    ts.tv_nsec = time_nsec;
    nmsg_message_set_time(THIS, &ts);

void
message_to_pres(THIS, endline)
    Net::Nmsg::XS::msg    THIS
    const char           *endline
    PREINIT:
    nmsg_res  res;
    char     *pres;
    PPCODE:
    pthread_mutex_lock(&presentation_lock);
    res = nmsg_message_to_pres(THIS, &pres, endline);
    if (res != nmsg_res_success)
        goto out;
    mXPUSHs(newSVpv(pres, 0));
    Safefree(pres);
    out:
    pthread_mutex_unlock(&presentation_lock);
    if (res != nmsg_res_success)
        croak("nmsg_message_to_pres failed: %s", nmsg_res_lookup(res));

void
get_field_type_descr_by_idx(THIS, f_idx)
    Net::Nmsg::XS::msg  THIS
    unsigned            f_idx
    PREINIT:
    nmsg_res                res;
    nmsg_msgmod_field_type  type;
    PPCODE:
    res = nmsg_message_get_field_type_by_idx(THIS, f_idx, &type);
    if (res == nmsg_res_success) {
        mXPUSHs(newSViv(type));

        switch (type) {

        case nmsg_msgmod_ft_enum:
            mXPUSHs(newSVpvs("enum"));
            break;
        case nmsg_msgmod_ft_int16:
            mXPUSHs(newSVpvs("int16"));
            break;
        case nmsg_msgmod_ft_int32:
            mXPUSHs(newSVpvs("int32"));
            break;
        case nmsg_msgmod_ft_uint16:
            mXPUSHs(newSVpvs("uint16"));
            break;
        case nmsg_msgmod_ft_uint32:
            mXPUSHs(newSVpvs("uint32"));
            break;
        case nmsg_msgmod_ft_uint64:
            mXPUSHs(newSVpvs("uint64"));
            break;
        case nmsg_msgmod_ft_int64:
            mXPUSHs(newSVpvs("int64"));
            break;
        case nmsg_msgmod_ft_string:
            mXPUSHs(newSVpvs("string"));
            break;
        case nmsg_msgmod_ft_mlstring:
            mXPUSHs(newSVpvs("mlstring"));
            break;
        case nmsg_msgmod_ft_bytes:
            mXPUSHs(newSVpvs("bytes"));
            break;
        case nmsg_msgmod_ft_ip:
            mXPUSHs(newSVpvs("ip"));
            break;
        default:
            mXPUSHs(newSVpvs("unknown"));
        }
    }

void
get_field_flag_descr_by_idx(THIS, f_idx)
    Net::Nmsg::XS::msg  THIS
    unsigned            f_idx
    PREINIT:
    nmsg_res    res;
    unsigned    flags;
    PPCODE:
    res = nmsg_message_get_field_flags_by_idx(THIS, f_idx, &flags);
    if (res == nmsg_res_success) {
        if (flags & NMSG_FF_REPEATED)
            mXPUSHs(newSViv(NMSG_FF_REPEATED));
            mXPUSHs(newSVpvs("repeated"));
        if (flags & NMSG_FF_REQUIRED)
            mXPUSHs(newSViv(NMSG_FF_REQUIRED));
            mXPUSHs(newSVpvs("required"));
        if (flags & NMSG_FF_HIDDEN)
            mXPUSHs(newSViv(NMSG_FF_HIDDEN));
            mXPUSHs(newSVpvs("hidden"));
        if (flags & NMSG_FF_NOPRINT)
            mXPUSHs(newSViv(NMSG_FF_NOPRINT));
            mXPUSHs(newSVpvs("noprint"));
    }

void
get_field_enum_descr_by_idx(THIS, f_idx)
    Net::Nmsg::XS::msg  THIS
    unsigned            f_idx
    PREINIT:
    nmsg_res                res;
    nmsg_msgmod_field_type  type;
    unsigned                v;
    const char             *name;
    PPCODE:
    res = nmsg_message_get_field_type_by_idx(THIS, f_idx, &type);
    if (res == nmsg_res_success && type == nmsg_msgmod_ft_enum) {
        for (v = 0;  ; v++) {
            res = nmsg_message_enum_value_to_name_by_idx(
                    THIS, f_idx, v, &name);
            if (res != nmsg_res_success)
                break;
            mXPUSHu(v);
            mXPUSHs(newSVpv(name, 0));
        }
    }
