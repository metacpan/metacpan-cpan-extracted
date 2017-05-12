
#line 1 "dev/XS.rl"
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


#line 53 "XS.xs"
static const int SN_start = 1;
static const int SN_first_final = 27;
static const int SN_error = 0;

static const int SN_en_is_decimal = 2;
static const int SN_en_is_float = 5;
static const int SN_en_is_int = 10;
static const int SN_en_is_int8 = 12;
static const int SN_en_is_int16 = 14;
static const int SN_en_is_int32 = 16;
static const int SN_en_is_int64 = 18;
static const int SN_en_is_int128 = 20;
static const int SN_en_is_uint = 22;
static const int SN_en_is_uint8 = 23;
static const int SN_en_is_uint16 = 24;
static const int SN_en_is_uint32 = 25;
static const int SN_en_is_uint64 = 26;
static const int SN_en_is_uint128 = 1;


#line 129 "dev/XS.rl"


static bool 
sn_check(const char *str, STRLEN len, int cs) {
    const char *p = str;
    const char *pe = p + len;
    const char *eof = pe;
    bool neg = FALSE;

    
#line 85 "XS.xs"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
case 1:
	if ( (*p) == 48 )
		goto st27;
	if ( 49 <= (*p) && (*p) <= 57 )
		goto tr2;
	goto st0;
st0:
cs = 0;
	goto _out;
st27:
	if ( ++p == pe )
		goto _test_eof27;
case 27:
	goto st0;
tr2:
#line 106 "dev/XS.rl"
	{
        str = p;
        len = pe - p;
    }
	goto st28;
st28:
	if ( ++p == pe )
		goto _test_eof28;
case 28:
#line 116 "XS.xs"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st29;
	goto st0;
st29:
	if ( ++p == pe )
		goto _test_eof29;
case 29:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st30;
	goto st0;
st30:
	if ( ++p == pe )
		goto _test_eof30;
case 30:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st31;
	goto st0;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st32;
	goto st0;
st32:
	if ( ++p == pe )
		goto _test_eof32;
case 32:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st33;
	goto st0;
st33:
	if ( ++p == pe )
		goto _test_eof33;
case 33:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st34;
	goto st0;
st34:
	if ( ++p == pe )
		goto _test_eof34;
case 34:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st35;
	goto st0;
st35:
	if ( ++p == pe )
		goto _test_eof35;
case 35:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st36;
	goto st0;
st36:
	if ( ++p == pe )
		goto _test_eof36;
case 36:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st37;
	goto st0;
st37:
	if ( ++p == pe )
		goto _test_eof37;
case 37:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st38;
	goto st0;
st38:
	if ( ++p == pe )
		goto _test_eof38;
case 38:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st39;
	goto st0;
st39:
	if ( ++p == pe )
		goto _test_eof39;
case 39:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st40;
	goto st0;
st40:
	if ( ++p == pe )
		goto _test_eof40;
case 40:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st41;
	goto st0;
st41:
	if ( ++p == pe )
		goto _test_eof41;
case 41:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st42;
	goto st0;
st42:
	if ( ++p == pe )
		goto _test_eof42;
case 42:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st43;
	goto st0;
st43:
	if ( ++p == pe )
		goto _test_eof43;
case 43:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st44;
	goto st0;
st44:
	if ( ++p == pe )
		goto _test_eof44;
case 44:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st45;
	goto st0;
st45:
	if ( ++p == pe )
		goto _test_eof45;
case 45:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st46;
	goto st0;
st46:
	if ( ++p == pe )
		goto _test_eof46;
case 46:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st47;
	goto st0;
st47:
	if ( ++p == pe )
		goto _test_eof47;
case 47:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st48;
	goto st0;
st48:
	if ( ++p == pe )
		goto _test_eof48;
case 48:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st49;
	goto st0;
st49:
	if ( ++p == pe )
		goto _test_eof49;
case 49:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st50;
	goto st0;
st50:
	if ( ++p == pe )
		goto _test_eof50;
case 50:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st51;
	goto st0;
st51:
	if ( ++p == pe )
		goto _test_eof51;
case 51:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st52;
	goto st0;
st52:
	if ( ++p == pe )
		goto _test_eof52;
case 52:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st53;
	goto st0;
st53:
	if ( ++p == pe )
		goto _test_eof53;
case 53:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st54;
	goto st0;
st54:
	if ( ++p == pe )
		goto _test_eof54;
case 54:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st55;
	goto st0;
st55:
	if ( ++p == pe )
		goto _test_eof55;
case 55:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st56;
	goto st0;
st56:
	if ( ++p == pe )
		goto _test_eof56;
case 56:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st57;
	goto st0;
st57:
	if ( ++p == pe )
		goto _test_eof57;
case 57:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st58;
	goto st0;
st58:
	if ( ++p == pe )
		goto _test_eof58;
case 58:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st59;
	goto st0;
st59:
	if ( ++p == pe )
		goto _test_eof59;
case 59:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st60;
	goto st0;
st60:
	if ( ++p == pe )
		goto _test_eof60;
case 60:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st61;
	goto st0;
st61:
	if ( ++p == pe )
		goto _test_eof61;
case 61:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st62;
	goto st0;
st62:
	if ( ++p == pe )
		goto _test_eof62;
case 62:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st63;
	goto st0;
st63:
	if ( ++p == pe )
		goto _test_eof63;
case 63:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st64;
	goto st0;
st64:
	if ( ++p == pe )
		goto _test_eof64;
case 64:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st65;
	goto st0;
st65:
	if ( ++p == pe )
		goto _test_eof65;
case 65:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st66;
	goto st0;
st66:
	if ( ++p == pe )
		goto _test_eof66;
case 66:
	goto st0;
case 2:
	switch( (*p) ) {
		case 45: goto st3;
		case 48: goto st67;
	}
	if ( 49 <= (*p) && (*p) <= 57 )
		goto st69;
	goto st0;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
	if ( (*p) == 48 )
		goto st67;
	if ( 49 <= (*p) && (*p) <= 57 )
		goto st69;
	goto st0;
st67:
	if ( ++p == pe )
		goto _test_eof67;
case 67:
	if ( (*p) == 46 )
		goto st4;
	goto st0;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st68;
	goto st0;
st68:
	if ( ++p == pe )
		goto _test_eof68;
case 68:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st68;
	goto st0;
st69:
	if ( ++p == pe )
		goto _test_eof69;
case 69:
	if ( (*p) == 46 )
		goto st4;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st69;
	goto st0;
case 5:
	switch( (*p) ) {
		case 45: goto st6;
		case 48: goto st70;
	}
	if ( 49 <= (*p) && (*p) <= 57 )
		goto st73;
	goto st0;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
	if ( (*p) == 48 )
		goto st70;
	if ( 49 <= (*p) && (*p) <= 57 )
		goto st73;
	goto st0;
st70:
	if ( ++p == pe )
		goto _test_eof70;
case 70:
	switch( (*p) ) {
		case 46: goto st7;
		case 69: goto st8;
		case 101: goto st8;
	}
	goto st0;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st71;
	goto st0;
st71:
	if ( ++p == pe )
		goto _test_eof71;
case 71:
	switch( (*p) ) {
		case 69: goto st8;
		case 101: goto st8;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st71;
	goto st0;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
	switch( (*p) ) {
		case 43: goto st9;
		case 45: goto st9;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st72;
	goto st0;
st9:
	if ( ++p == pe )
		goto _test_eof9;
case 9:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st72;
	goto st0;
st72:
	if ( ++p == pe )
		goto _test_eof72;
case 72:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st72;
	goto st0;
st73:
	if ( ++p == pe )
		goto _test_eof73;
case 73:
	switch( (*p) ) {
		case 46: goto st7;
		case 69: goto st8;
		case 101: goto st8;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st73;
	goto st0;
case 10:
	switch( (*p) ) {
		case 45: goto tr13;
		case 48: goto st74;
	}
	if ( 49 <= (*p) && (*p) <= 57 )
		goto st75;
	goto st0;
tr13:
#line 102 "dev/XS.rl"
	{
        neg = ((*p) == '-');
    }
	goto st11;
st11:
	if ( ++p == pe )
		goto _test_eof11;
case 11:
#line 531 "XS.xs"
	if ( (*p) == 48 )
		goto st74;
	if ( 49 <= (*p) && (*p) <= 57 )
		goto st75;
	goto st0;
st74:
	if ( ++p == pe )
		goto _test_eof74;
case 74:
	goto st0;
st75:
	if ( ++p == pe )
		goto _test_eof75;
case 75:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st75;
	goto st0;
case 12:
	switch( (*p) ) {
		case 45: goto tr16;
		case 48: goto st76;
	}
	if ( 49 <= (*p) && (*p) <= 57 )
		goto tr18;
	goto st0;
tr16:
#line 102 "dev/XS.rl"
	{
        neg = ((*p) == '-');
    }
	goto st13;
st13:
	if ( ++p == pe )
		goto _test_eof13;
case 13:
#line 567 "XS.xs"
	if ( (*p) == 48 )
		goto st76;
	if ( 49 <= (*p) && (*p) <= 57 )
		goto tr18;
	goto st0;
st76:
	if ( ++p == pe )
		goto _test_eof76;
case 76:
	goto st0;
tr18:
#line 106 "dev/XS.rl"
	{
        str = p;
        len = pe - p;
    }
	goto st77;
st77:
	if ( ++p == pe )
		goto _test_eof77;
case 77:
#line 589 "XS.xs"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st78;
	goto st0;
st78:
	if ( ++p == pe )
		goto _test_eof78;
case 78:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st79;
	goto st0;
st79:
	if ( ++p == pe )
		goto _test_eof79;
case 79:
	goto st0;
case 14:
	switch( (*p) ) {
		case 45: goto tr19;
		case 48: goto st80;
	}
	if ( 49 <= (*p) && (*p) <= 57 )
		goto tr21;
	goto st0;
tr19:
#line 102 "dev/XS.rl"
	{
        neg = ((*p) == '-');
    }
	goto st15;
st15:
	if ( ++p == pe )
		goto _test_eof15;
case 15:
#line 623 "XS.xs"
	if ( (*p) == 48 )
		goto st80;
	if ( 49 <= (*p) && (*p) <= 57 )
		goto tr21;
	goto st0;
st80:
	if ( ++p == pe )
		goto _test_eof80;
case 80:
	goto st0;
tr21:
#line 106 "dev/XS.rl"
	{
        str = p;
        len = pe - p;
    }
	goto st81;
st81:
	if ( ++p == pe )
		goto _test_eof81;
case 81:
#line 645 "XS.xs"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st82;
	goto st0;
st82:
	if ( ++p == pe )
		goto _test_eof82;
case 82:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st83;
	goto st0;
st83:
	if ( ++p == pe )
		goto _test_eof83;
case 83:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st84;
	goto st0;
st84:
	if ( ++p == pe )
		goto _test_eof84;
case 84:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st85;
	goto st0;
st85:
	if ( ++p == pe )
		goto _test_eof85;
case 85:
	goto st0;
case 16:
	switch( (*p) ) {
		case 45: goto tr22;
		case 48: goto st86;
	}
	if ( 49 <= (*p) && (*p) <= 57 )
		goto tr24;
	goto st0;
tr22:
#line 102 "dev/XS.rl"
	{
        neg = ((*p) == '-');
    }
	goto st17;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
#line 693 "XS.xs"
	if ( (*p) == 48 )
		goto st86;
	if ( 49 <= (*p) && (*p) <= 57 )
		goto tr24;
	goto st0;
st86:
	if ( ++p == pe )
		goto _test_eof86;
case 86:
	goto st0;
tr24:
#line 106 "dev/XS.rl"
	{
        str = p;
        len = pe - p;
    }
	goto st87;
st87:
	if ( ++p == pe )
		goto _test_eof87;
case 87:
#line 715 "XS.xs"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st88;
	goto st0;
st88:
	if ( ++p == pe )
		goto _test_eof88;
case 88:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st89;
	goto st0;
st89:
	if ( ++p == pe )
		goto _test_eof89;
case 89:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st90;
	goto st0;
st90:
	if ( ++p == pe )
		goto _test_eof90;
case 90:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st91;
	goto st0;
st91:
	if ( ++p == pe )
		goto _test_eof91;
case 91:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st92;
	goto st0;
st92:
	if ( ++p == pe )
		goto _test_eof92;
case 92:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st93;
	goto st0;
st93:
	if ( ++p == pe )
		goto _test_eof93;
case 93:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st94;
	goto st0;
st94:
	if ( ++p == pe )
		goto _test_eof94;
case 94:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st95;
	goto st0;
st95:
	if ( ++p == pe )
		goto _test_eof95;
case 95:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st96;
	goto st0;
st96:
	if ( ++p == pe )
		goto _test_eof96;
case 96:
	goto st0;
case 18:
	switch( (*p) ) {
		case 45: goto tr25;
		case 48: goto st97;
	}
	if ( 49 <= (*p) && (*p) <= 57 )
		goto tr27;
	goto st0;
tr25:
#line 102 "dev/XS.rl"
	{
        neg = ((*p) == '-');
    }
	goto st19;
st19:
	if ( ++p == pe )
		goto _test_eof19;
case 19:
#line 798 "XS.xs"
	if ( (*p) == 48 )
		goto st97;
	if ( 49 <= (*p) && (*p) <= 57 )
		goto tr27;
	goto st0;
st97:
	if ( ++p == pe )
		goto _test_eof97;
case 97:
	goto st0;
tr27:
#line 106 "dev/XS.rl"
	{
        str = p;
        len = pe - p;
    }
	goto st98;
st98:
	if ( ++p == pe )
		goto _test_eof98;
case 98:
#line 820 "XS.xs"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st99;
	goto st0;
st99:
	if ( ++p == pe )
		goto _test_eof99;
case 99:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st100;
	goto st0;
st100:
	if ( ++p == pe )
		goto _test_eof100;
case 100:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st101;
	goto st0;
st101:
	if ( ++p == pe )
		goto _test_eof101;
case 101:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st102;
	goto st0;
st102:
	if ( ++p == pe )
		goto _test_eof102;
case 102:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st103;
	goto st0;
st103:
	if ( ++p == pe )
		goto _test_eof103;
case 103:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st104;
	goto st0;
st104:
	if ( ++p == pe )
		goto _test_eof104;
case 104:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st105;
	goto st0;
st105:
	if ( ++p == pe )
		goto _test_eof105;
case 105:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st106;
	goto st0;
st106:
	if ( ++p == pe )
		goto _test_eof106;
case 106:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st107;
	goto st0;
st107:
	if ( ++p == pe )
		goto _test_eof107;
case 107:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st108;
	goto st0;
st108:
	if ( ++p == pe )
		goto _test_eof108;
case 108:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st109;
	goto st0;
st109:
	if ( ++p == pe )
		goto _test_eof109;
case 109:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st110;
	goto st0;
st110:
	if ( ++p == pe )
		goto _test_eof110;
case 110:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st111;
	goto st0;
st111:
	if ( ++p == pe )
		goto _test_eof111;
case 111:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st112;
	goto st0;
st112:
	if ( ++p == pe )
		goto _test_eof112;
case 112:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st113;
	goto st0;
st113:
	if ( ++p == pe )
		goto _test_eof113;
case 113:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st114;
	goto st0;
st114:
	if ( ++p == pe )
		goto _test_eof114;
case 114:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st115;
	goto st0;
st115:
	if ( ++p == pe )
		goto _test_eof115;
case 115:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st116;
	goto st0;
st116:
	if ( ++p == pe )
		goto _test_eof116;
case 116:
	goto st0;
case 20:
	switch( (*p) ) {
		case 45: goto tr28;
		case 48: goto st117;
	}
	if ( 49 <= (*p) && (*p) <= 57 )
		goto tr30;
	goto st0;
tr28:
#line 102 "dev/XS.rl"
	{
        neg = ((*p) == '-');
    }
	goto st21;
st21:
	if ( ++p == pe )
		goto _test_eof21;
case 21:
#line 966 "XS.xs"
	if ( (*p) == 48 )
		goto st117;
	if ( 49 <= (*p) && (*p) <= 57 )
		goto tr30;
	goto st0;
st117:
	if ( ++p == pe )
		goto _test_eof117;
case 117:
	goto st0;
tr30:
#line 106 "dev/XS.rl"
	{
        str = p;
        len = pe - p;
    }
	goto st118;
st118:
	if ( ++p == pe )
		goto _test_eof118;
case 118:
#line 988 "XS.xs"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st119;
	goto st0;
st119:
	if ( ++p == pe )
		goto _test_eof119;
case 119:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st120;
	goto st0;
st120:
	if ( ++p == pe )
		goto _test_eof120;
case 120:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st121;
	goto st0;
st121:
	if ( ++p == pe )
		goto _test_eof121;
case 121:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st122;
	goto st0;
st122:
	if ( ++p == pe )
		goto _test_eof122;
case 122:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st123;
	goto st0;
st123:
	if ( ++p == pe )
		goto _test_eof123;
case 123:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st124;
	goto st0;
st124:
	if ( ++p == pe )
		goto _test_eof124;
case 124:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st125;
	goto st0;
st125:
	if ( ++p == pe )
		goto _test_eof125;
case 125:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st126;
	goto st0;
st126:
	if ( ++p == pe )
		goto _test_eof126;
case 126:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st127;
	goto st0;
st127:
	if ( ++p == pe )
		goto _test_eof127;
case 127:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st128;
	goto st0;
st128:
	if ( ++p == pe )
		goto _test_eof128;
case 128:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st129;
	goto st0;
st129:
	if ( ++p == pe )
		goto _test_eof129;
case 129:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st130;
	goto st0;
st130:
	if ( ++p == pe )
		goto _test_eof130;
case 130:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st131;
	goto st0;
st131:
	if ( ++p == pe )
		goto _test_eof131;
case 131:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st132;
	goto st0;
st132:
	if ( ++p == pe )
		goto _test_eof132;
case 132:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st133;
	goto st0;
st133:
	if ( ++p == pe )
		goto _test_eof133;
case 133:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st134;
	goto st0;
st134:
	if ( ++p == pe )
		goto _test_eof134;
case 134:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st135;
	goto st0;
st135:
	if ( ++p == pe )
		goto _test_eof135;
case 135:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st136;
	goto st0;
st136:
	if ( ++p == pe )
		goto _test_eof136;
case 136:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st137;
	goto st0;
st137:
	if ( ++p == pe )
		goto _test_eof137;
case 137:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st138;
	goto st0;
st138:
	if ( ++p == pe )
		goto _test_eof138;
case 138:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st139;
	goto st0;
st139:
	if ( ++p == pe )
		goto _test_eof139;
case 139:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st140;
	goto st0;
st140:
	if ( ++p == pe )
		goto _test_eof140;
case 140:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st141;
	goto st0;
st141:
	if ( ++p == pe )
		goto _test_eof141;
case 141:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st142;
	goto st0;
st142:
	if ( ++p == pe )
		goto _test_eof142;
case 142:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st143;
	goto st0;
st143:
	if ( ++p == pe )
		goto _test_eof143;
case 143:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st144;
	goto st0;
st144:
	if ( ++p == pe )
		goto _test_eof144;
case 144:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st145;
	goto st0;
st145:
	if ( ++p == pe )
		goto _test_eof145;
case 145:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st146;
	goto st0;
st146:
	if ( ++p == pe )
		goto _test_eof146;
case 146:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st147;
	goto st0;
st147:
	if ( ++p == pe )
		goto _test_eof147;
case 147:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st148;
	goto st0;
st148:
	if ( ++p == pe )
		goto _test_eof148;
case 148:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st149;
	goto st0;
st149:
	if ( ++p == pe )
		goto _test_eof149;
case 149:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st150;
	goto st0;
st150:
	if ( ++p == pe )
		goto _test_eof150;
case 150:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st151;
	goto st0;
st151:
	if ( ++p == pe )
		goto _test_eof151;
case 151:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st152;
	goto st0;
st152:
	if ( ++p == pe )
		goto _test_eof152;
case 152:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st153;
	goto st0;
st153:
	if ( ++p == pe )
		goto _test_eof153;
case 153:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st154;
	goto st0;
st154:
	if ( ++p == pe )
		goto _test_eof154;
case 154:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st155;
	goto st0;
st155:
	if ( ++p == pe )
		goto _test_eof155;
case 155:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st156;
	goto st0;
st156:
	if ( ++p == pe )
		goto _test_eof156;
case 156:
	goto st0;
case 22:
	if ( (*p) == 48 )
		goto st157;
	if ( 49 <= (*p) && (*p) <= 57 )
		goto st158;
	goto st0;
st157:
	if ( ++p == pe )
		goto _test_eof157;
case 157:
	goto st0;
st158:
	if ( ++p == pe )
		goto _test_eof158;
case 158:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st158;
	goto st0;
case 23:
	if ( (*p) == 48 )
		goto st159;
	if ( 49 <= (*p) && (*p) <= 57 )
		goto tr34;
	goto st0;
st159:
	if ( ++p == pe )
		goto _test_eof159;
case 159:
	goto st0;
tr34:
#line 106 "dev/XS.rl"
	{
        str = p;
        len = pe - p;
    }
	goto st160;
st160:
	if ( ++p == pe )
		goto _test_eof160;
case 160:
#line 1296 "XS.xs"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st161;
	goto st0;
st161:
	if ( ++p == pe )
		goto _test_eof161;
case 161:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st162;
	goto st0;
st162:
	if ( ++p == pe )
		goto _test_eof162;
case 162:
	goto st0;
case 24:
	if ( (*p) == 48 )
		goto st163;
	if ( 49 <= (*p) && (*p) <= 57 )
		goto tr36;
	goto st0;
st163:
	if ( ++p == pe )
		goto _test_eof163;
case 163:
	goto st0;
tr36:
#line 106 "dev/XS.rl"
	{
        str = p;
        len = pe - p;
    }
	goto st164;
st164:
	if ( ++p == pe )
		goto _test_eof164;
case 164:
#line 1334 "XS.xs"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st165;
	goto st0;
st165:
	if ( ++p == pe )
		goto _test_eof165;
case 165:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st166;
	goto st0;
st166:
	if ( ++p == pe )
		goto _test_eof166;
case 166:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st167;
	goto st0;
st167:
	if ( ++p == pe )
		goto _test_eof167;
case 167:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st168;
	goto st0;
st168:
	if ( ++p == pe )
		goto _test_eof168;
case 168:
	goto st0;
case 25:
	if ( (*p) == 48 )
		goto st169;
	if ( 49 <= (*p) && (*p) <= 57 )
		goto tr38;
	goto st0;
st169:
	if ( ++p == pe )
		goto _test_eof169;
case 169:
	goto st0;
tr38:
#line 106 "dev/XS.rl"
	{
        str = p;
        len = pe - p;
    }
	goto st170;
st170:
	if ( ++p == pe )
		goto _test_eof170;
case 170:
#line 1386 "XS.xs"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st171;
	goto st0;
st171:
	if ( ++p == pe )
		goto _test_eof171;
case 171:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st172;
	goto st0;
st172:
	if ( ++p == pe )
		goto _test_eof172;
case 172:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st173;
	goto st0;
st173:
	if ( ++p == pe )
		goto _test_eof173;
case 173:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st174;
	goto st0;
st174:
	if ( ++p == pe )
		goto _test_eof174;
case 174:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st175;
	goto st0;
st175:
	if ( ++p == pe )
		goto _test_eof175;
case 175:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st176;
	goto st0;
st176:
	if ( ++p == pe )
		goto _test_eof176;
case 176:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st177;
	goto st0;
st177:
	if ( ++p == pe )
		goto _test_eof177;
case 177:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st178;
	goto st0;
st178:
	if ( ++p == pe )
		goto _test_eof178;
case 178:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st179;
	goto st0;
st179:
	if ( ++p == pe )
		goto _test_eof179;
case 179:
	goto st0;
case 26:
	if ( (*p) == 48 )
		goto st180;
	if ( 49 <= (*p) && (*p) <= 57 )
		goto tr40;
	goto st0;
st180:
	if ( ++p == pe )
		goto _test_eof180;
case 180:
	goto st0;
tr40:
#line 106 "dev/XS.rl"
	{
        str = p;
        len = pe - p;
    }
	goto st181;
st181:
	if ( ++p == pe )
		goto _test_eof181;
case 181:
#line 1473 "XS.xs"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st182;
	goto st0;
st182:
	if ( ++p == pe )
		goto _test_eof182;
case 182:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st183;
	goto st0;
st183:
	if ( ++p == pe )
		goto _test_eof183;
case 183:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st184;
	goto st0;
st184:
	if ( ++p == pe )
		goto _test_eof184;
case 184:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st185;
	goto st0;
st185:
	if ( ++p == pe )
		goto _test_eof185;
case 185:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st186;
	goto st0;
st186:
	if ( ++p == pe )
		goto _test_eof186;
case 186:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st187;
	goto st0;
st187:
	if ( ++p == pe )
		goto _test_eof187;
case 187:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st188;
	goto st0;
st188:
	if ( ++p == pe )
		goto _test_eof188;
case 188:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st189;
	goto st0;
st189:
	if ( ++p == pe )
		goto _test_eof189;
case 189:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st190;
	goto st0;
st190:
	if ( ++p == pe )
		goto _test_eof190;
case 190:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st191;
	goto st0;
st191:
	if ( ++p == pe )
		goto _test_eof191;
case 191:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st192;
	goto st0;
st192:
	if ( ++p == pe )
		goto _test_eof192;
case 192:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st193;
	goto st0;
st193:
	if ( ++p == pe )
		goto _test_eof193;
case 193:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st194;
	goto st0;
st194:
	if ( ++p == pe )
		goto _test_eof194;
case 194:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st195;
	goto st0;
st195:
	if ( ++p == pe )
		goto _test_eof195;
case 195:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st196;
	goto st0;
st196:
	if ( ++p == pe )
		goto _test_eof196;
case 196:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st197;
	goto st0;
st197:
	if ( ++p == pe )
		goto _test_eof197;
case 197:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st198;
	goto st0;
st198:
	if ( ++p == pe )
		goto _test_eof198;
case 198:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st199;
	goto st0;
st199:
	if ( ++p == pe )
		goto _test_eof199;
case 199:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st200;
	goto st0;
st200:
	if ( ++p == pe )
		goto _test_eof200;
case 200:
	goto st0;
	}
	_test_eof27: cs = 27; goto _test_eof; 
	_test_eof28: cs = 28; goto _test_eof; 
	_test_eof29: cs = 29; goto _test_eof; 
	_test_eof30: cs = 30; goto _test_eof; 
	_test_eof31: cs = 31; goto _test_eof; 
	_test_eof32: cs = 32; goto _test_eof; 
	_test_eof33: cs = 33; goto _test_eof; 
	_test_eof34: cs = 34; goto _test_eof; 
	_test_eof35: cs = 35; goto _test_eof; 
	_test_eof36: cs = 36; goto _test_eof; 
	_test_eof37: cs = 37; goto _test_eof; 
	_test_eof38: cs = 38; goto _test_eof; 
	_test_eof39: cs = 39; goto _test_eof; 
	_test_eof40: cs = 40; goto _test_eof; 
	_test_eof41: cs = 41; goto _test_eof; 
	_test_eof42: cs = 42; goto _test_eof; 
	_test_eof43: cs = 43; goto _test_eof; 
	_test_eof44: cs = 44; goto _test_eof; 
	_test_eof45: cs = 45; goto _test_eof; 
	_test_eof46: cs = 46; goto _test_eof; 
	_test_eof47: cs = 47; goto _test_eof; 
	_test_eof48: cs = 48; goto _test_eof; 
	_test_eof49: cs = 49; goto _test_eof; 
	_test_eof50: cs = 50; goto _test_eof; 
	_test_eof51: cs = 51; goto _test_eof; 
	_test_eof52: cs = 52; goto _test_eof; 
	_test_eof53: cs = 53; goto _test_eof; 
	_test_eof54: cs = 54; goto _test_eof; 
	_test_eof55: cs = 55; goto _test_eof; 
	_test_eof56: cs = 56; goto _test_eof; 
	_test_eof57: cs = 57; goto _test_eof; 
	_test_eof58: cs = 58; goto _test_eof; 
	_test_eof59: cs = 59; goto _test_eof; 
	_test_eof60: cs = 60; goto _test_eof; 
	_test_eof61: cs = 61; goto _test_eof; 
	_test_eof62: cs = 62; goto _test_eof; 
	_test_eof63: cs = 63; goto _test_eof; 
	_test_eof64: cs = 64; goto _test_eof; 
	_test_eof65: cs = 65; goto _test_eof; 
	_test_eof66: cs = 66; goto _test_eof; 
	_test_eof3: cs = 3; goto _test_eof; 
	_test_eof67: cs = 67; goto _test_eof; 
	_test_eof4: cs = 4; goto _test_eof; 
	_test_eof68: cs = 68; goto _test_eof; 
	_test_eof69: cs = 69; goto _test_eof; 
	_test_eof6: cs = 6; goto _test_eof; 
	_test_eof70: cs = 70; goto _test_eof; 
	_test_eof7: cs = 7; goto _test_eof; 
	_test_eof71: cs = 71; goto _test_eof; 
	_test_eof8: cs = 8; goto _test_eof; 
	_test_eof9: cs = 9; goto _test_eof; 
	_test_eof72: cs = 72; goto _test_eof; 
	_test_eof73: cs = 73; goto _test_eof; 
	_test_eof11: cs = 11; goto _test_eof; 
	_test_eof74: cs = 74; goto _test_eof; 
	_test_eof75: cs = 75; goto _test_eof; 
	_test_eof13: cs = 13; goto _test_eof; 
	_test_eof76: cs = 76; goto _test_eof; 
	_test_eof77: cs = 77; goto _test_eof; 
	_test_eof78: cs = 78; goto _test_eof; 
	_test_eof79: cs = 79; goto _test_eof; 
	_test_eof15: cs = 15; goto _test_eof; 
	_test_eof80: cs = 80; goto _test_eof; 
	_test_eof81: cs = 81; goto _test_eof; 
	_test_eof82: cs = 82; goto _test_eof; 
	_test_eof83: cs = 83; goto _test_eof; 
	_test_eof84: cs = 84; goto _test_eof; 
	_test_eof85: cs = 85; goto _test_eof; 
	_test_eof17: cs = 17; goto _test_eof; 
	_test_eof86: cs = 86; goto _test_eof; 
	_test_eof87: cs = 87; goto _test_eof; 
	_test_eof88: cs = 88; goto _test_eof; 
	_test_eof89: cs = 89; goto _test_eof; 
	_test_eof90: cs = 90; goto _test_eof; 
	_test_eof91: cs = 91; goto _test_eof; 
	_test_eof92: cs = 92; goto _test_eof; 
	_test_eof93: cs = 93; goto _test_eof; 
	_test_eof94: cs = 94; goto _test_eof; 
	_test_eof95: cs = 95; goto _test_eof; 
	_test_eof96: cs = 96; goto _test_eof; 
	_test_eof19: cs = 19; goto _test_eof; 
	_test_eof97: cs = 97; goto _test_eof; 
	_test_eof98: cs = 98; goto _test_eof; 
	_test_eof99: cs = 99; goto _test_eof; 
	_test_eof100: cs = 100; goto _test_eof; 
	_test_eof101: cs = 101; goto _test_eof; 
	_test_eof102: cs = 102; goto _test_eof; 
	_test_eof103: cs = 103; goto _test_eof; 
	_test_eof104: cs = 104; goto _test_eof; 
	_test_eof105: cs = 105; goto _test_eof; 
	_test_eof106: cs = 106; goto _test_eof; 
	_test_eof107: cs = 107; goto _test_eof; 
	_test_eof108: cs = 108; goto _test_eof; 
	_test_eof109: cs = 109; goto _test_eof; 
	_test_eof110: cs = 110; goto _test_eof; 
	_test_eof111: cs = 111; goto _test_eof; 
	_test_eof112: cs = 112; goto _test_eof; 
	_test_eof113: cs = 113; goto _test_eof; 
	_test_eof114: cs = 114; goto _test_eof; 
	_test_eof115: cs = 115; goto _test_eof; 
	_test_eof116: cs = 116; goto _test_eof; 
	_test_eof21: cs = 21; goto _test_eof; 
	_test_eof117: cs = 117; goto _test_eof; 
	_test_eof118: cs = 118; goto _test_eof; 
	_test_eof119: cs = 119; goto _test_eof; 
	_test_eof120: cs = 120; goto _test_eof; 
	_test_eof121: cs = 121; goto _test_eof; 
	_test_eof122: cs = 122; goto _test_eof; 
	_test_eof123: cs = 123; goto _test_eof; 
	_test_eof124: cs = 124; goto _test_eof; 
	_test_eof125: cs = 125; goto _test_eof; 
	_test_eof126: cs = 126; goto _test_eof; 
	_test_eof127: cs = 127; goto _test_eof; 
	_test_eof128: cs = 128; goto _test_eof; 
	_test_eof129: cs = 129; goto _test_eof; 
	_test_eof130: cs = 130; goto _test_eof; 
	_test_eof131: cs = 131; goto _test_eof; 
	_test_eof132: cs = 132; goto _test_eof; 
	_test_eof133: cs = 133; goto _test_eof; 
	_test_eof134: cs = 134; goto _test_eof; 
	_test_eof135: cs = 135; goto _test_eof; 
	_test_eof136: cs = 136; goto _test_eof; 
	_test_eof137: cs = 137; goto _test_eof; 
	_test_eof138: cs = 138; goto _test_eof; 
	_test_eof139: cs = 139; goto _test_eof; 
	_test_eof140: cs = 140; goto _test_eof; 
	_test_eof141: cs = 141; goto _test_eof; 
	_test_eof142: cs = 142; goto _test_eof; 
	_test_eof143: cs = 143; goto _test_eof; 
	_test_eof144: cs = 144; goto _test_eof; 
	_test_eof145: cs = 145; goto _test_eof; 
	_test_eof146: cs = 146; goto _test_eof; 
	_test_eof147: cs = 147; goto _test_eof; 
	_test_eof148: cs = 148; goto _test_eof; 
	_test_eof149: cs = 149; goto _test_eof; 
	_test_eof150: cs = 150; goto _test_eof; 
	_test_eof151: cs = 151; goto _test_eof; 
	_test_eof152: cs = 152; goto _test_eof; 
	_test_eof153: cs = 153; goto _test_eof; 
	_test_eof154: cs = 154; goto _test_eof; 
	_test_eof155: cs = 155; goto _test_eof; 
	_test_eof156: cs = 156; goto _test_eof; 
	_test_eof157: cs = 157; goto _test_eof; 
	_test_eof158: cs = 158; goto _test_eof; 
	_test_eof159: cs = 159; goto _test_eof; 
	_test_eof160: cs = 160; goto _test_eof; 
	_test_eof161: cs = 161; goto _test_eof; 
	_test_eof162: cs = 162; goto _test_eof; 
	_test_eof163: cs = 163; goto _test_eof; 
	_test_eof164: cs = 164; goto _test_eof; 
	_test_eof165: cs = 165; goto _test_eof; 
	_test_eof166: cs = 166; goto _test_eof; 
	_test_eof167: cs = 167; goto _test_eof; 
	_test_eof168: cs = 168; goto _test_eof; 
	_test_eof169: cs = 169; goto _test_eof; 
	_test_eof170: cs = 170; goto _test_eof; 
	_test_eof171: cs = 171; goto _test_eof; 
	_test_eof172: cs = 172; goto _test_eof; 
	_test_eof173: cs = 173; goto _test_eof; 
	_test_eof174: cs = 174; goto _test_eof; 
	_test_eof175: cs = 175; goto _test_eof; 
	_test_eof176: cs = 176; goto _test_eof; 
	_test_eof177: cs = 177; goto _test_eof; 
	_test_eof178: cs = 178; goto _test_eof; 
	_test_eof179: cs = 179; goto _test_eof; 
	_test_eof180: cs = 180; goto _test_eof; 
	_test_eof181: cs = 181; goto _test_eof; 
	_test_eof182: cs = 182; goto _test_eof; 
	_test_eof183: cs = 183; goto _test_eof; 
	_test_eof184: cs = 184; goto _test_eof; 
	_test_eof185: cs = 185; goto _test_eof; 
	_test_eof186: cs = 186; goto _test_eof; 
	_test_eof187: cs = 187; goto _test_eof; 
	_test_eof188: cs = 188; goto _test_eof; 
	_test_eof189: cs = 189; goto _test_eof; 
	_test_eof190: cs = 190; goto _test_eof; 
	_test_eof191: cs = 191; goto _test_eof; 
	_test_eof192: cs = 192; goto _test_eof; 
	_test_eof193: cs = 193; goto _test_eof; 
	_test_eof194: cs = 194; goto _test_eof; 
	_test_eof195: cs = 195; goto _test_eof; 
	_test_eof196: cs = 196; goto _test_eof; 
	_test_eof197: cs = 197; goto _test_eof; 
	_test_eof198: cs = 198; goto _test_eof; 
	_test_eof199: cs = 199; goto _test_eof; 
	_test_eof200: cs = 200; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 77: 
	case 78: 
	case 79: 
#line 52 "dev/XS.rl"
	{
        if (len == 3)
            return memLE(str, neg ? SN_INT8_MIN : SN_INT8_MAX, 3);
    }
	break;
	case 81: 
	case 82: 
	case 83: 
	case 84: 
	case 85: 
#line 57 "dev/XS.rl"
	{
        if (len == 5)
            return memLE(str, neg ? SN_INT16_MIN : SN_INT16_MAX, 5);
    }
	break;
	case 87: 
	case 88: 
	case 89: 
	case 90: 
	case 91: 
	case 92: 
	case 93: 
	case 94: 
	case 95: 
	case 96: 
#line 62 "dev/XS.rl"
	{
        if (len == 10)
            return memLE(str, neg ? SN_INT32_MIN : SN_INT32_MAX, 10);
    }
	break;
	case 98: 
	case 99: 
	case 100: 
	case 101: 
	case 102: 
	case 103: 
	case 104: 
	case 105: 
	case 106: 
	case 107: 
	case 108: 
	case 109: 
	case 110: 
	case 111: 
	case 112: 
	case 113: 
	case 114: 
	case 115: 
	case 116: 
#line 67 "dev/XS.rl"
	{
        if (len == 19)
            return memLE(str, neg ? SN_INT64_MIN : SN_INT64_MAX, 19);
    }
	break;
	case 118: 
	case 119: 
	case 120: 
	case 121: 
	case 122: 
	case 123: 
	case 124: 
	case 125: 
	case 126: 
	case 127: 
	case 128: 
	case 129: 
	case 130: 
	case 131: 
	case 132: 
	case 133: 
	case 134: 
	case 135: 
	case 136: 
	case 137: 
	case 138: 
	case 139: 
	case 140: 
	case 141: 
	case 142: 
	case 143: 
	case 144: 
	case 145: 
	case 146: 
	case 147: 
	case 148: 
	case 149: 
	case 150: 
	case 151: 
	case 152: 
	case 153: 
	case 154: 
	case 155: 
	case 156: 
#line 72 "dev/XS.rl"
	{
        if (len == 39)
            return memLE(str, neg ? SN_INT128_MIN : SN_INT128_MAX, 39);
    }
	break;
	case 160: 
	case 161: 
	case 162: 
#line 77 "dev/XS.rl"
	{
        if (len == 3)
            return memLE(str, SN_UINT8_MAX, 3);
    }
	break;
	case 164: 
	case 165: 
	case 166: 
	case 167: 
	case 168: 
#line 82 "dev/XS.rl"
	{
        if (len == 5)
            return memLE(str, SN_UINT16_MAX, 5);
    }
	break;
	case 170: 
	case 171: 
	case 172: 
	case 173: 
	case 174: 
	case 175: 
	case 176: 
	case 177: 
	case 178: 
	case 179: 
#line 87 "dev/XS.rl"
	{
        if (len == 10)
            return memLE(str, SN_UINT32_MAX, 10);
    }
	break;
	case 181: 
	case 182: 
	case 183: 
	case 184: 
	case 185: 
	case 186: 
	case 187: 
	case 188: 
	case 189: 
	case 190: 
	case 191: 
	case 192: 
	case 193: 
	case 194: 
	case 195: 
	case 196: 
	case 197: 
	case 198: 
	case 199: 
	case 200: 
#line 92 "dev/XS.rl"
	{
        if (len == 20)
            return memLE(str, SN_UINT64_MAX, 20);
    }
	break;
	case 28: 
	case 29: 
	case 30: 
	case 31: 
	case 32: 
	case 33: 
	case 34: 
	case 35: 
	case 36: 
	case 37: 
	case 38: 
	case 39: 
	case 40: 
	case 41: 
	case 42: 
	case 43: 
	case 44: 
	case 45: 
	case 46: 
	case 47: 
	case 48: 
	case 49: 
	case 50: 
	case 51: 
	case 52: 
	case 53: 
	case 54: 
	case 55: 
	case 56: 
	case 57: 
	case 58: 
	case 59: 
	case 60: 
	case 61: 
	case 62: 
	case 63: 
	case 64: 
	case 65: 
	case 66: 
#line 97 "dev/XS.rl"
	{
        if (len == 39)
            return memLE(str, SN_UINT128_MAX, 39);
    }
	break;
#line 2013 "XS.xs"
	}
	}

	_out: {}
	}

#line 139 "dev/XS.rl"

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

