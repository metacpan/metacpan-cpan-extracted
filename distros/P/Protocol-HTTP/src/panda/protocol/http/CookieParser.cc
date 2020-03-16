
#line 1 "src/panda/protocol/http/CookieParser.rl"
#include "RequestParser.h"
#include "ResponseParser.h"

namespace panda { namespace protocol { namespace http {

#define ADD_DIGIT(dest) \
    dest *= 10;         \
    dest += *p - '0';
    
#define CURSTR     buffer.substr(mark, p - ps - mark)
#define SAVE(dest) dest = CURSTR


#line 26 "src/panda/protocol/http/CookieParser.rl"



#line 21 "src/panda/protocol/http/CookieParser.cc"
static const int cookie_parser_start = 1;
static const int cookie_parser_first_final = 5;
static const int cookie_parser_error = 0;

static const int cookie_parser_en_main = 1;


#line 36 "src/panda/protocol/http/CookieParser.rl"


void RequestParser::parse_cookie (const string& buffer) {
    const char* ps  = buffer.data();
    const char* p   = ps;
    const char* pe  = ps + buffer.size();
    const char* eof = pe;
    int         cs  = cookie_parser_start;
    auto&     cont  = request->cookies.fields;
    size_t mark;
    
#line 41 "src/panda/protocol/http/CookieParser.cc"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
st1:
	if ( ++p == pe )
		goto _test_eof1;
case 1:
	switch( (*p) ) {
		case 33: goto tr0;
		case 124: goto tr0;
		case 126: goto tr0;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto tr0;
		} else if ( (*p) >= 35 )
			goto tr0;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto tr0;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto tr0;
		} else
			goto tr0;
	} else
		goto tr0;
	goto st0;
st0:
cs = 0;
	goto _out;
tr0:
#line 17 "src/panda/protocol/http/CookieParser.rl"
	{
        mark = p - ps;
    }
	goto st2;
st2:
	if ( ++p == pe )
		goto _test_eof2;
case 2:
#line 87 "src/panda/protocol/http/CookieParser.cc"
	switch( (*p) ) {
		case 33: goto st2;
		case 61: goto tr3;
		case 124: goto st2;
		case 126: goto st2;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st2;
		} else if ( (*p) >= 35 )
			goto st2;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st2;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st2;
		} else
			goto st2;
	} else
		goto st2;
	goto st0;
tr3:
#line 32 "src/panda/protocol/http/CookieParser.rl"
	{ cont.emplace_back(CURSTR, string()); }
	goto st5;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
#line 120 "src/panda/protocol/http/CookieParser.cc"
	switch( (*p) ) {
		case 9: goto tr8;
		case 32: goto tr8;
		case 34: goto tr9;
		case 44: goto st0;
		case 59: goto tr10;
		case 92: goto st0;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto tr7;
tr7:
#line 17 "src/panda/protocol/http/CookieParser.rl"
	{
        mark = p - ps;
    }
	goto st6;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
#line 143 "src/panda/protocol/http/CookieParser.cc"
	switch( (*p) ) {
		case 9: goto tr12;
		case 32: goto tr12;
		case 34: goto st0;
		case 44: goto st0;
		case 59: goto tr13;
		case 92: goto st0;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st6;
tr8:
#line 17 "src/panda/protocol/http/CookieParser.rl"
	{
        mark = p - ps;
    }
#line 32 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(cont.back().value); }
	goto st7;
tr12:
#line 32 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(cont.back().value); }
	goto st7;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
#line 172 "src/panda/protocol/http/CookieParser.cc"
	switch( (*p) ) {
		case 9: goto st7;
		case 32: goto st7;
	}
	goto st0;
tr10:
#line 17 "src/panda/protocol/http/CookieParser.rl"
	{
        mark = p - ps;
    }
#line 32 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(cont.back().value); }
	goto st3;
tr13:
#line 32 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(cont.back().value); }
	goto st3;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
#line 194 "src/panda/protocol/http/CookieParser.cc"
	if ( (*p) == 32 )
		goto st1;
	goto st0;
tr9:
#line 17 "src/panda/protocol/http/CookieParser.rl"
	{
        mark = p - ps;
    }
	goto st4;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
#line 208 "src/panda/protocol/http/CookieParser.cc"
	switch( (*p) ) {
		case 34: goto st8;
		case 44: goto st0;
		case 59: goto st0;
		case 92: goto st0;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 32 )
		goto st0;
	goto st4;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
	switch( (*p) ) {
		case 9: goto tr12;
		case 32: goto tr12;
		case 59: goto tr13;
	}
	goto st0;
	}
	_test_eof1: cs = 1; goto _test_eof; 
	_test_eof2: cs = 2; goto _test_eof; 
	_test_eof5: cs = 5; goto _test_eof; 
	_test_eof6: cs = 6; goto _test_eof; 
	_test_eof7: cs = 7; goto _test_eof; 
	_test_eof3: cs = 3; goto _test_eof; 
	_test_eof4: cs = 4; goto _test_eof; 
	_test_eof8: cs = 8; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 6: 
	case 8: 
#line 32 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(cont.back().value); }
	break;
	case 5: 
#line 17 "src/panda/protocol/http/CookieParser.rl"
	{
        mark = p - ps;
    }
#line 32 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(cont.back().value); }
	break;
#line 256 "src/panda/protocol/http/CookieParser.cc"
	}
	}

	_out: {}
	}

#line 47 "src/panda/protocol/http/CookieParser.rl"
}


#line 267 "src/panda/protocol/http/CookieParser.cc"
static const int set_cookie_parser_start = 1;
static const int set_cookie_parser_first_final = 6;
static const int set_cookie_parser_error = 0;

static const int set_cookie_parser_en_main = 1;


#line 71 "src/panda/protocol/http/CookieParser.rl"


void ResponseParser::parse_cookie (const string& buffer) {
    const char* ps  = buffer.data();
    const char* p   = ps;
    const char* pe  = ps + buffer.size();
    const char* eof = pe;
    int         cs  = set_cookie_parser_start;
    auto&     cont  = response->cookies.fields;
    size_t mark;
    Response::Cookie* v;
    
#line 288 "src/panda/protocol/http/CookieParser.cc"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
case 1:
	switch( (*p) ) {
		case 33: goto tr0;
		case 124: goto tr0;
		case 126: goto tr0;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto tr0;
		} else if ( (*p) >= 35 )
			goto tr0;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto tr0;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto tr0;
		} else
			goto tr0;
	} else
		goto tr0;
	goto st0;
st0:
cs = 0;
	goto _out;
tr0:
#line 17 "src/panda/protocol/http/CookieParser.rl"
	{
        mark = p - ps;
    }
	goto st2;
st2:
	if ( ++p == pe )
		goto _test_eof2;
case 2:
#line 331 "src/panda/protocol/http/CookieParser.cc"
	switch( (*p) ) {
		case 33: goto st2;
		case 61: goto tr3;
		case 124: goto st2;
		case 126: goto st2;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st2;
		} else if ( (*p) >= 35 )
			goto st2;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st2;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st2;
		} else
			goto st2;
	} else
		goto st2;
	goto st0;
tr3:
#line 53 "src/panda/protocol/http/CookieParser.rl"
	{ cont.emplace_back(CURSTR, Response::Cookie()); v = &cont.back().value; }
	goto st6;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
#line 364 "src/panda/protocol/http/CookieParser.cc"
	switch( (*p) ) {
		case 34: goto tr15;
		case 44: goto st0;
		case 59: goto tr16;
		case 92: goto st0;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 32 )
		goto st0;
	goto tr14;
tr14:
#line 17 "src/panda/protocol/http/CookieParser.rl"
	{
        mark = p - ps;
    }
	goto st7;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
#line 385 "src/panda/protocol/http/CookieParser.cc"
	switch( (*p) ) {
		case 34: goto st0;
		case 44: goto st0;
		case 59: goto tr18;
		case 92: goto st0;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 32 )
		goto st0;
	goto st7;
tr16:
#line 17 "src/panda/protocol/http/CookieParser.rl"
	{
        mark = p - ps;
    }
#line 53 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(v->_value); }
	goto st3;
tr18:
#line 53 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(v->_value); }
	goto st3;
tr28:
#line 56 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(v->_domain); }
	goto st3;
tr37:
#line 17 "src/panda/protocol/http/CookieParser.rl"
	{
        mark = p - ps;
    }
#line 54 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(v->_expires); }
	goto st3;
tr39:
#line 54 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(v->_expires); }
	goto st3;
tr47:
#line 59 "src/panda/protocol/http/CookieParser.rl"
	{ v->_http_only = true; }
	goto st3;
tr63:
#line 57 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(v->_path); }
	goto st3;
tr72:
#line 61 "src/panda/protocol/http/CookieParser.rl"
	{ v->_same_site = Response::Cookie::SameSite::Strict; }
	goto st3;
tr79:
#line 63 "src/panda/protocol/http/CookieParser.rl"
	{ v->_same_site = Response::Cookie::SameSite::Lax; }
	goto st3;
tr83:
#line 64 "src/panda/protocol/http/CookieParser.rl"
	{ v->_same_site = Response::Cookie::SameSite::None; }
	goto st3;
tr89:
#line 62 "src/panda/protocol/http/CookieParser.rl"
	{ v->_same_site = Response::Cookie::SameSite::Strict; }
	goto st3;
tr94:
#line 58 "src/panda/protocol/http/CookieParser.rl"
	{ v->_secure = true; }
	goto st3;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
#line 456 "src/panda/protocol/http/CookieParser.cc"
	if ( (*p) == 32 )
		goto st4;
	goto st0;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
	switch( (*p) ) {
		case 59: goto st0;
		case 68: goto st9;
		case 69: goto st17;
		case 72: goto st26;
		case 77: goto st34;
		case 80: goto st43;
		case 83: goto st49;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
	switch( (*p) ) {
		case 59: goto st3;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st9:
	if ( ++p == pe )
		goto _test_eof9;
case 9:
	switch( (*p) ) {
		case 59: goto st3;
		case 111: goto st10;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
	switch( (*p) ) {
		case 59: goto st3;
		case 109: goto st11;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st11:
	if ( ++p == pe )
		goto _test_eof11;
case 11:
	switch( (*p) ) {
		case 59: goto st3;
		case 97: goto st12;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st12:
	if ( ++p == pe )
		goto _test_eof12;
case 12:
	switch( (*p) ) {
		case 59: goto st3;
		case 105: goto st13;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st13:
	if ( ++p == pe )
		goto _test_eof13;
case 13:
	switch( (*p) ) {
		case 59: goto st3;
		case 110: goto st14;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
	switch( (*p) ) {
		case 59: goto st3;
		case 61: goto st15;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st15:
	if ( ++p == pe )
		goto _test_eof15;
case 15:
	switch( (*p) ) {
		case 59: goto st3;
		case 127: goto st0;
	}
	if ( (*p) < 48 ) {
		if ( (*p) > 31 ) {
			if ( 45 <= (*p) && (*p) <= 46 )
				goto tr26;
		} else if ( (*p) >= 0 )
			goto st0;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 90 ) {
			if ( 97 <= (*p) && (*p) <= 122 )
				goto tr26;
		} else if ( (*p) >= 65 )
			goto tr26;
	} else
		goto tr26;
	goto st8;
tr26:
#line 17 "src/panda/protocol/http/CookieParser.rl"
	{
        mark = p - ps;
    }
	goto st16;
st16:
	if ( ++p == pe )
		goto _test_eof16;
case 16:
#line 593 "src/panda/protocol/http/CookieParser.cc"
	switch( (*p) ) {
		case 59: goto tr28;
		case 127: goto st0;
	}
	if ( (*p) < 48 ) {
		if ( (*p) > 31 ) {
			if ( 45 <= (*p) && (*p) <= 46 )
				goto st16;
		} else if ( (*p) >= 0 )
			goto st0;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 90 ) {
			if ( 97 <= (*p) && (*p) <= 122 )
				goto st16;
		} else if ( (*p) >= 65 )
			goto st16;
	} else
		goto st16;
	goto st8;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
	switch( (*p) ) {
		case 59: goto st3;
		case 120: goto st18;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st18:
	if ( ++p == pe )
		goto _test_eof18;
case 18:
	switch( (*p) ) {
		case 59: goto st3;
		case 112: goto st19;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st19:
	if ( ++p == pe )
		goto _test_eof19;
case 19:
	switch( (*p) ) {
		case 59: goto st3;
		case 105: goto st20;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st20:
	if ( ++p == pe )
		goto _test_eof20;
case 20:
	switch( (*p) ) {
		case 59: goto st3;
		case 114: goto st21;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st21:
	if ( ++p == pe )
		goto _test_eof21;
case 21:
	switch( (*p) ) {
		case 59: goto st3;
		case 101: goto st22;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st22:
	if ( ++p == pe )
		goto _test_eof22;
case 22:
	switch( (*p) ) {
		case 59: goto st3;
		case 115: goto st23;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st23:
	if ( ++p == pe )
		goto _test_eof23;
case 23:
	switch( (*p) ) {
		case 59: goto st3;
		case 61: goto st24;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st24:
	if ( ++p == pe )
		goto _test_eof24;
case 24:
	switch( (*p) ) {
		case 32: goto tr36;
		case 44: goto tr36;
		case 59: goto tr37;
		case 127: goto st0;
	}
	if ( (*p) < 48 ) {
		if ( 0 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) > 58 ) {
		if ( (*p) > 90 ) {
			if ( 97 <= (*p) && (*p) <= 122 )
				goto tr36;
		} else if ( (*p) >= 65 )
			goto tr36;
	} else
		goto tr36;
	goto st8;
tr36:
#line 17 "src/panda/protocol/http/CookieParser.rl"
	{
        mark = p - ps;
    }
	goto st25;
st25:
	if ( ++p == pe )
		goto _test_eof25;
case 25:
#line 729 "src/panda/protocol/http/CookieParser.cc"
	switch( (*p) ) {
		case 32: goto st25;
		case 44: goto st25;
		case 59: goto tr39;
		case 127: goto st0;
	}
	if ( (*p) < 48 ) {
		if ( 0 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) > 58 ) {
		if ( (*p) > 90 ) {
			if ( 97 <= (*p) && (*p) <= 122 )
				goto st25;
		} else if ( (*p) >= 65 )
			goto st25;
	} else
		goto st25;
	goto st8;
st26:
	if ( ++p == pe )
		goto _test_eof26;
case 26:
	switch( (*p) ) {
		case 59: goto st3;
		case 116: goto st27;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st27:
	if ( ++p == pe )
		goto _test_eof27;
case 27:
	switch( (*p) ) {
		case 59: goto st3;
		case 116: goto st28;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st28:
	if ( ++p == pe )
		goto _test_eof28;
case 28:
	switch( (*p) ) {
		case 59: goto st3;
		case 112: goto st29;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st29:
	if ( ++p == pe )
		goto _test_eof29;
case 29:
	switch( (*p) ) {
		case 59: goto st3;
		case 79: goto st30;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st30:
	if ( ++p == pe )
		goto _test_eof30;
case 30:
	switch( (*p) ) {
		case 59: goto st3;
		case 110: goto st31;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
	switch( (*p) ) {
		case 59: goto st3;
		case 108: goto st32;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st32:
	if ( ++p == pe )
		goto _test_eof32;
case 32:
	switch( (*p) ) {
		case 59: goto st3;
		case 121: goto st33;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st33:
	if ( ++p == pe )
		goto _test_eof33;
case 33:
	switch( (*p) ) {
		case 59: goto tr47;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st34:
	if ( ++p == pe )
		goto _test_eof34;
case 34:
	switch( (*p) ) {
		case 59: goto st3;
		case 97: goto st35;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st35:
	if ( ++p == pe )
		goto _test_eof35;
case 35:
	switch( (*p) ) {
		case 59: goto st3;
		case 120: goto st36;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st36:
	if ( ++p == pe )
		goto _test_eof36;
case 36:
	switch( (*p) ) {
		case 45: goto st37;
		case 59: goto st3;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st37:
	if ( ++p == pe )
		goto _test_eof37;
case 37:
	switch( (*p) ) {
		case 59: goto st3;
		case 65: goto st38;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st38:
	if ( ++p == pe )
		goto _test_eof38;
case 38:
	switch( (*p) ) {
		case 59: goto st3;
		case 103: goto st39;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st39:
	if ( ++p == pe )
		goto _test_eof39;
case 39:
	switch( (*p) ) {
		case 59: goto st3;
		case 101: goto st40;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st40:
	if ( ++p == pe )
		goto _test_eof40;
case 40:
	switch( (*p) ) {
		case 59: goto st3;
		case 61: goto st41;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st41:
	if ( ++p == pe )
		goto _test_eof41;
case 41:
	switch( (*p) ) {
		case 59: goto st3;
		case 127: goto st0;
	}
	if ( (*p) > 31 ) {
		if ( 49 <= (*p) && (*p) <= 57 )
			goto tr55;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st8;
tr55:
#line 55 "src/panda/protocol/http/CookieParser.rl"
	{ v->_max_age = 0; }
#line 55 "src/panda/protocol/http/CookieParser.rl"
	{ ADD_DIGIT(v->_max_age); }
	goto st42;
tr56:
#line 55 "src/panda/protocol/http/CookieParser.rl"
	{ ADD_DIGIT(v->_max_age); }
	goto st42;
st42:
	if ( ++p == pe )
		goto _test_eof42;
case 42:
#line 955 "src/panda/protocol/http/CookieParser.cc"
	switch( (*p) ) {
		case 59: goto st3;
		case 127: goto st0;
	}
	if ( (*p) > 31 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr56;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st8;
st43:
	if ( ++p == pe )
		goto _test_eof43;
case 43:
	switch( (*p) ) {
		case 59: goto st3;
		case 97: goto st44;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st44:
	if ( ++p == pe )
		goto _test_eof44;
case 44:
	switch( (*p) ) {
		case 59: goto st3;
		case 116: goto st45;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st45:
	if ( ++p == pe )
		goto _test_eof45;
case 45:
	switch( (*p) ) {
		case 59: goto st3;
		case 104: goto st46;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st46:
	if ( ++p == pe )
		goto _test_eof46;
case 46:
	switch( (*p) ) {
		case 59: goto st3;
		case 61: goto st47;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st47:
	if ( ++p == pe )
		goto _test_eof47;
case 47:
	switch( (*p) ) {
		case 59: goto st3;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto tr61;
tr61:
#line 17 "src/panda/protocol/http/CookieParser.rl"
	{
        mark = p - ps;
    }
	goto st48;
st48:
	if ( ++p == pe )
		goto _test_eof48;
case 48:
#line 1035 "src/panda/protocol/http/CookieParser.cc"
	switch( (*p) ) {
		case 59: goto tr63;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st48;
st49:
	if ( ++p == pe )
		goto _test_eof49;
case 49:
	switch( (*p) ) {
		case 59: goto st3;
		case 97: goto st50;
		case 101: goto st71;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st50:
	if ( ++p == pe )
		goto _test_eof50;
case 50:
	switch( (*p) ) {
		case 59: goto st3;
		case 109: goto st51;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st51:
	if ( ++p == pe )
		goto _test_eof51;
case 51:
	switch( (*p) ) {
		case 59: goto st3;
		case 101: goto st52;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st52:
	if ( ++p == pe )
		goto _test_eof52;
case 52:
	switch( (*p) ) {
		case 59: goto st3;
		case 83: goto st53;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st53:
	if ( ++p == pe )
		goto _test_eof53;
case 53:
	switch( (*p) ) {
		case 59: goto st3;
		case 105: goto st54;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st54:
	if ( ++p == pe )
		goto _test_eof54;
case 54:
	switch( (*p) ) {
		case 59: goto st3;
		case 116: goto st55;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st55:
	if ( ++p == pe )
		goto _test_eof55;
case 55:
	switch( (*p) ) {
		case 59: goto st3;
		case 101: goto st56;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st56:
	if ( ++p == pe )
		goto _test_eof56;
case 56:
	switch( (*p) ) {
		case 59: goto tr72;
		case 61: goto st57;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st57:
	if ( ++p == pe )
		goto _test_eof57;
case 57:
	switch( (*p) ) {
		case 59: goto st3;
		case 76: goto st58;
		case 78: goto st61;
		case 83: goto st65;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st58:
	if ( ++p == pe )
		goto _test_eof58;
case 58:
	switch( (*p) ) {
		case 59: goto st3;
		case 97: goto st59;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st59:
	if ( ++p == pe )
		goto _test_eof59;
case 59:
	switch( (*p) ) {
		case 59: goto st3;
		case 120: goto st60;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st60:
	if ( ++p == pe )
		goto _test_eof60;
case 60:
	switch( (*p) ) {
		case 59: goto tr79;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st61:
	if ( ++p == pe )
		goto _test_eof61;
case 61:
	switch( (*p) ) {
		case 59: goto st3;
		case 111: goto st62;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st62:
	if ( ++p == pe )
		goto _test_eof62;
case 62:
	switch( (*p) ) {
		case 59: goto st3;
		case 110: goto st63;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st63:
	if ( ++p == pe )
		goto _test_eof63;
case 63:
	switch( (*p) ) {
		case 59: goto st3;
		case 101: goto st64;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st64:
	if ( ++p == pe )
		goto _test_eof64;
case 64:
	switch( (*p) ) {
		case 59: goto tr83;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st65:
	if ( ++p == pe )
		goto _test_eof65;
case 65:
	switch( (*p) ) {
		case 59: goto st3;
		case 116: goto st66;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st66:
	if ( ++p == pe )
		goto _test_eof66;
case 66:
	switch( (*p) ) {
		case 59: goto st3;
		case 114: goto st67;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st67:
	if ( ++p == pe )
		goto _test_eof67;
case 67:
	switch( (*p) ) {
		case 59: goto st3;
		case 105: goto st68;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st68:
	if ( ++p == pe )
		goto _test_eof68;
case 68:
	switch( (*p) ) {
		case 59: goto st3;
		case 99: goto st69;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st69:
	if ( ++p == pe )
		goto _test_eof69;
case 69:
	switch( (*p) ) {
		case 59: goto st3;
		case 116: goto st70;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st70:
	if ( ++p == pe )
		goto _test_eof70;
case 70:
	switch( (*p) ) {
		case 59: goto tr89;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st71:
	if ( ++p == pe )
		goto _test_eof71;
case 71:
	switch( (*p) ) {
		case 59: goto st3;
		case 99: goto st72;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st72:
	if ( ++p == pe )
		goto _test_eof72;
case 72:
	switch( (*p) ) {
		case 59: goto st3;
		case 117: goto st73;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st73:
	if ( ++p == pe )
		goto _test_eof73;
case 73:
	switch( (*p) ) {
		case 59: goto st3;
		case 114: goto st74;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st74:
	if ( ++p == pe )
		goto _test_eof74;
case 74:
	switch( (*p) ) {
		case 59: goto st3;
		case 101: goto st75;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
st75:
	if ( ++p == pe )
		goto _test_eof75;
case 75:
	switch( (*p) ) {
		case 59: goto tr94;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st8;
tr15:
#line 17 "src/panda/protocol/http/CookieParser.rl"
	{
        mark = p - ps;
    }
	goto st5;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
#line 1376 "src/panda/protocol/http/CookieParser.cc"
	switch( (*p) ) {
		case 34: goto st76;
		case 44: goto st0;
		case 59: goto st0;
		case 92: goto st0;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 32 )
		goto st0;
	goto st5;
st76:
	if ( ++p == pe )
		goto _test_eof76;
case 76:
	if ( (*p) == 59 )
		goto tr18;
	goto st0;
	}
	_test_eof2: cs = 2; goto _test_eof; 
	_test_eof6: cs = 6; goto _test_eof; 
	_test_eof7: cs = 7; goto _test_eof; 
	_test_eof3: cs = 3; goto _test_eof; 
	_test_eof4: cs = 4; goto _test_eof; 
	_test_eof8: cs = 8; goto _test_eof; 
	_test_eof9: cs = 9; goto _test_eof; 
	_test_eof10: cs = 10; goto _test_eof; 
	_test_eof11: cs = 11; goto _test_eof; 
	_test_eof12: cs = 12; goto _test_eof; 
	_test_eof13: cs = 13; goto _test_eof; 
	_test_eof14: cs = 14; goto _test_eof; 
	_test_eof15: cs = 15; goto _test_eof; 
	_test_eof16: cs = 16; goto _test_eof; 
	_test_eof17: cs = 17; goto _test_eof; 
	_test_eof18: cs = 18; goto _test_eof; 
	_test_eof19: cs = 19; goto _test_eof; 
	_test_eof20: cs = 20; goto _test_eof; 
	_test_eof21: cs = 21; goto _test_eof; 
	_test_eof22: cs = 22; goto _test_eof; 
	_test_eof23: cs = 23; goto _test_eof; 
	_test_eof24: cs = 24; goto _test_eof; 
	_test_eof25: cs = 25; goto _test_eof; 
	_test_eof26: cs = 26; goto _test_eof; 
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
	_test_eof67: cs = 67; goto _test_eof; 
	_test_eof68: cs = 68; goto _test_eof; 
	_test_eof69: cs = 69; goto _test_eof; 
	_test_eof70: cs = 70; goto _test_eof; 
	_test_eof71: cs = 71; goto _test_eof; 
	_test_eof72: cs = 72; goto _test_eof; 
	_test_eof73: cs = 73; goto _test_eof; 
	_test_eof74: cs = 74; goto _test_eof; 
	_test_eof75: cs = 75; goto _test_eof; 
	_test_eof5: cs = 5; goto _test_eof; 
	_test_eof76: cs = 76; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 7: 
	case 76: 
#line 53 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(v->_value); }
	break;
	case 25: 
#line 54 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(v->_expires); }
	break;
	case 16: 
#line 56 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(v->_domain); }
	break;
	case 48: 
#line 57 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(v->_path); }
	break;
	case 75: 
#line 58 "src/panda/protocol/http/CookieParser.rl"
	{ v->_secure = true; }
	break;
	case 33: 
#line 59 "src/panda/protocol/http/CookieParser.rl"
	{ v->_http_only = true; }
	break;
	case 56: 
#line 61 "src/panda/protocol/http/CookieParser.rl"
	{ v->_same_site = Response::Cookie::SameSite::Strict; }
	break;
	case 70: 
#line 62 "src/panda/protocol/http/CookieParser.rl"
	{ v->_same_site = Response::Cookie::SameSite::Strict; }
	break;
	case 60: 
#line 63 "src/panda/protocol/http/CookieParser.rl"
	{ v->_same_site = Response::Cookie::SameSite::Lax; }
	break;
	case 64: 
#line 64 "src/panda/protocol/http/CookieParser.rl"
	{ v->_same_site = Response::Cookie::SameSite::None; }
	break;
	case 6: 
#line 17 "src/panda/protocol/http/CookieParser.rl"
	{
        mark = p - ps;
    }
#line 53 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(v->_value); }
	break;
	case 24: 
#line 17 "src/panda/protocol/http/CookieParser.rl"
	{
        mark = p - ps;
    }
#line 54 "src/panda/protocol/http/CookieParser.rl"
	{ SAVE(v->_expires); }
	break;
#line 1532 "src/panda/protocol/http/CookieParser.cc"
	}
	}

	_out: {}
	}

#line 83 "src/panda/protocol/http/CookieParser.rl"
}

}}}
