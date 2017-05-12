#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags
#include "ppport.h"

#define SN_INT8_MIN    "128"
#define SN_INT8_MAX    "127"
#define SN_INT8_DIG    3

#define SN_INT16_MIN   "32768"
#define SN_INT16_MAX   "32767"
#define SN_INT16_DIG   5

#define SN_INT32_MIN   "2147483648"
#define SN_INT32_MAX   "2147483647"
#define SN_INT32_DIG   10

#define SN_INT64_MIN   "9223372036854775808"
#define SN_INT64_MAX   "9223372036854775807"
#define SN_INT64_DIG   19

#define SN_INT128_MIN  "170141183460469231731687303715884105728"
#define SN_INT128_MAX  "170141183460469231731687303715884105727"
#define SN_INT128_DIG  39

#define SN_UINT8_MAX   "255"
#define SN_UINT8_DIG   3

#define SN_UINT16_MAX  "65535"
#define SN_UINT16_DIG  5

#define SN_UINT32_MAX  "4294967295"
#define SN_UINT32_DIG  10

#define SN_UINT64_MAX  "18446744073709551615"
#define SN_UINT64_DIG  20

#define SN_UINT128_MAX "340282366920938463463374607431768211455"
#define SN_UINT128_DIG 39

#ifdef HAS_MEMCMP
#  define memLE(s1,s2,l) (memcmp(s1,s2,l) <= 0)
#else
#  define memLE(s1,s2,l) (bcmp(s1,s2,l) <= 0)
#endif

%%{
    machine SN;

    action is_int8 {
        if (len == 3)
            return memLE(str, neg ? SN_INT8_MIN : SN_INT8_MAX, 3);
    }

    action is_int16 {
        if (len == 5)
            return memLE(str, neg ? SN_INT16_MIN : SN_INT16_MAX, 5);
    }

    action is_int32 {
        if (len == 10)
            return memLE(str, neg ? SN_INT32_MIN : SN_INT32_MAX, 10);
    }

    action is_int64 {
        if (len == 19)
            return memLE(str, neg ? SN_INT64_MIN : SN_INT64_MAX, 19);
    }

    action is_int128 {
        if (len == 39)
            return memLE(str, neg ? SN_INT128_MIN : SN_INT128_MAX, 39);
    }

    action is_uint8 {
        if (len == 3)
            return memLE(str, SN_UINT8_MAX, 3);
    }

    action is_uint16 {
        if (len == 5)
            return memLE(str, SN_UINT16_MAX, 5);
    }

    action is_uint32 {
        if (len == 10)
            return memLE(str, SN_UINT32_MAX, 10);
    }

    action is_uint64 {
        if (len == 20)
            return memLE(str, SN_UINT64_MAX, 20);
    }

    action is_uint128 {
        if (len == 39)
            return memLE(str, SN_UINT128_MAX, 39);
    }

    action sign {
        neg = (fc == '-');
    }

    action mark {
        str = p;
        len = pe - p;
    }

    is_decimal := '-'? ( '0' | ( [1-9] [0-9]* ) ) ( '.' [0-9]+ )?;
    is_float   := '-'? ( '0' | ( [1-9] [0-9]* ) ) ( '.' [0-9]+ )? ( [eE] [+\-]? [0-9]+ )?;

    is_int     := ( '-' @sign )? ( '0' | ( [1-9] [0-9]*                  ) );
    is_int8    := ( '-' @sign )? ( '0' | ( [1-9] [0-9]{0,2}  %is_int8    ) >mark );
    is_int16   := ( '-' @sign )? ( '0' | ( [1-9] [0-9]{0,4}  %is_int16   ) >mark );
    is_int32   := ( '-' @sign )? ( '0' | ( [1-9] [0-9]{0,9}  %is_int32   ) >mark );
    is_int64   := ( '-' @sign )? ( '0' | ( [1-9] [0-9]{0,18} %is_int64   ) >mark );
    is_int128  := ( '-' @sign )? ( '0' | ( [1-9] [0-9]{0,38} %is_int128  ) >mark );

    is_uint    :=                ( '0' | ( [1-9] [0-9]*                  ) );
    is_uint8   :=                ( '0' | ( [1-9] [0-9]{0,2}  %is_uint8   ) >mark );
    is_uint16  :=                ( '0' | ( [1-9] [0-9]{0,4}  %is_uint16  ) >mark );
    is_uint32  :=                ( '0' | ( [1-9] [0-9]{0,9}  %is_uint32  ) >mark );
    is_uint64  :=                ( '0' | ( [1-9] [0-9]{0,19} %is_uint64  ) >mark );
    is_uint128 :=                ( '0' | ( [1-9] [0-9]{0,38} %is_uint128 ) >mark );

    write data;
}%%

static bool 
sn_check(const char *str, STRLEN len, int cs) {
    const char *p = str;
    const char *pe = p + len;
    const char *eof = pe;
    bool neg = FALSE;

    %% write exec;

    return (cs >= SN_first_final);
}

MODULE = String::Numeric::XS   PACKAGE = String::Numeric::XS

PROTOTYPES: DISABLE

void
is_float(string)

  INPUT:
    SV *string

  INIT:
    STRLEN len;
    const char *str;

  ALIAS:
    is_float   = SN_en_is_float
    is_decimal = SN_en_is_decimal
    is_int     = SN_en_is_int
    is_int8    = SN_en_is_int8
    is_int16   = SN_en_is_int16
    is_int32   = SN_en_is_int32
    is_int64   = SN_en_is_int64
    is_int128  = SN_en_is_int128
    is_uint    = SN_en_is_uint
    is_uint8   = SN_en_is_uint8
    is_uint16  = SN_en_is_uint16
    is_uint32  = SN_en_is_uint32
    is_uint64  = SN_en_is_uint64
    is_uint128 = SN_en_is_uint128

  CODE:
    SvGETMAGIC(string);

    if (!SvOK(string))
        XSRETURN_NO;

    str = SvPV_nomg_const(string, len);

    ST(0) = boolSV(sn_check(str, len, ix));
    XSRETURN(1);

