
#line 1 "src/panda/protocol/http/MessageParser.rl"
#include "MessageParser.h"


#line 191 "src/panda/protocol/http/MessageParser.rl"


namespace panda { namespace protocol { namespace http {


#line 13 "src/panda/protocol/http/MessageParser.cc"
static const int message_parser_start = 1;
static const int message_parser_first_final = 321;
static const int message_parser_error = 0;

static const int message_parser_en_first_chunk = 98;
static const int message_parser_en_chunk = 108;
static const int message_parser_en_chunk_trailer = 120;
static const int message_parser_en_request = 126;
static const int message_parser_en_response = 1;


#line 196 "src/panda/protocol/http/MessageParser.rl"

#ifdef PARSER_DEFINITIONS_ONLY
#undef PARSER_DEFINITIONS_ONLY
#else

#define ADD_DIGIT(dest) \
    dest *= 10;         \
    dest += *p - '0';
    
#define ADD_XDIGIT(dest) \
    char fc = *p | 0x20; \
    dest *= 16;          \
    dest += fc >= 'a' ? (fc - 'a' + 10) : (fc - '0');

#define SAVE(dest)                                              \
    if (mark != -1) dest = buffer.substr(mark, p - ps - mark);  \
    else {                                                      \
        dest = std::move(acc);                                  \
        dest.append(ps, p - ps);                                \
    }

size_t MessageParser::machine_exec (const string& buffer, size_t off) {
    const char* ps = buffer.data();
    const char* p  = ps + off;
    const char* pe = ps + buffer.size();
    
#line 52 "src/panda/protocol/http/MessageParser.cc"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
case 1:
	if ( (*p) == 72 )
		goto st2;
	goto st0;
st0:
cs = 0;
	goto _out;
st2:
	if ( ++p == pe )
		goto _test_eof2;
case 2:
	if ( (*p) == 84 )
		goto st3;
	goto st0;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
	if ( (*p) == 84 )
		goto st4;
	goto st0;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
	if ( (*p) == 80 )
		goto st5;
	goto st0;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
	if ( (*p) == 47 )
		goto st6;
	goto st0;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
	if ( (*p) == 49 )
		goto st7;
	goto st0;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
	if ( (*p) == 46 )
		goto st8;
	goto st0;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
	switch( (*p) ) {
		case 48: goto st9;
		case 49: goto st97;
	}
	goto st0;
st9:
	if ( ++p == pe )
		goto _test_eof9;
case 9:
	if ( (*p) == 32 )
		goto tr10;
	goto st0;
tr10:
#line 124 "src/panda/protocol/http/MessageParser.rl"
	{message->http_version = 10;}
	goto st10;
tr129:
#line 124 "src/panda/protocol/http/MessageParser.rl"
	{message->http_version = 11;}
	goto st10;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
#line 135 "src/panda/protocol/http/MessageParser.cc"
	if ( 49 <= (*p) && (*p) <= 57 )
		goto tr11;
	goto st0;
tr11:
#line 185 "src/panda/protocol/http/MessageParser.rl"
	{ADD_DIGIT(response->code)}
	goto st11;
st11:
	if ( ++p == pe )
		goto _test_eof11;
case 11:
#line 147 "src/panda/protocol/http/MessageParser.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr12;
	goto st0;
tr12:
#line 185 "src/panda/protocol/http/MessageParser.rl"
	{ADD_DIGIT(response->code)}
	goto st12;
st12:
	if ( ++p == pe )
		goto _test_eof12;
case 12:
#line 159 "src/panda/protocol/http/MessageParser.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr13;
	goto st0;
tr13:
#line 185 "src/panda/protocol/http/MessageParser.rl"
	{ADD_DIGIT(response->code)}
	goto st13;
st13:
	if ( ++p == pe )
		goto _test_eof13;
case 13:
#line 171 "src/panda/protocol/http/MessageParser.cc"
	if ( (*p) == 32 )
		goto st14;
	goto st0;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
	switch( (*p) ) {
		case 13: goto tr16;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto tr15;
tr15:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st15;
st15:
	if ( ++p == pe )
		goto _test_eof15;
case 15:
#line 200 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr18;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st15;
tr16:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
#line 186 "src/panda/protocol/http/MessageParser.rl"
	{SAVE(response->message)}
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st16;
tr18:
#line 186 "src/panda/protocol/http/MessageParser.rl"
	{SAVE(response->message)}
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st16;
tr29:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st16;
tr31:
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st16;
tr56:
#line 53 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            cs = message_parser_error;
            set_error(errc::unsupported_compression);
            {p++; cs = 16; goto _out;}
        }
    }
#line 94 "src/panda/protocol/http/MessageParser.rl"
	{
        if (message->compression.type != Compression::IDENTITY) {
            auto it = compression::instantiate(message->compression.type);
            if (it) {
                it->prepare_uncompress(max_body_size);
                compressor = std::move(it);
            } else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 16; goto _out;}
            }
        }
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st16;
tr59:
#line 83 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::BROTLI; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 16; goto _out;}
            }
        }
    }
#line 94 "src/panda/protocol/http/MessageParser.rl"
	{
        if (message->compression.type != Compression::IDENTITY) {
            auto it = compression::instantiate(message->compression.type);
            if (it) {
                it->prepare_uncompress(max_body_size);
                compressor = std::move(it);
            } else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 16; goto _out;}
            }
        }
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st16;
tr62:
#line 94 "src/panda/protocol/http/MessageParser.rl"
	{
        if (message->compression.type != Compression::IDENTITY) {
            auto it = compression::instantiate(message->compression.type);
            if (it) {
                it->prepare_uncompress(max_body_size);
                compressor = std::move(it);
            } else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 16; goto _out;}
            }
        }
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st16;
tr75:
#line 72 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::DEFLATE; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 16; goto _out;}
            }
        }
    }
#line 94 "src/panda/protocol/http/MessageParser.rl"
	{
        if (message->compression.type != Compression::IDENTITY) {
            auto it = compression::instantiate(message->compression.type);
            if (it) {
                it->prepare_uncompress(max_body_size);
                compressor = std::move(it);
            } else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 16; goto _out;}
            }
        }
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st16;
tr81:
#line 61 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::GZIP; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 16; goto _out;}
            }
        }
    }
#line 94 "src/panda/protocol/http/MessageParser.rl"
	{
        if (message->compression.type != Compression::IDENTITY) {
            auto it = compression::instantiate(message->compression.type);
            if (it) {
                it->prepare_uncompress(max_body_size);
                compressor = std::move(it);
            } else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 16; goto _out;}
            }
        }
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st16;
tr119:
#line 47 "src/panda/protocol/http/MessageParser.rl"
	{
        cs = message_parser_error;
        set_error(errc::unsupported_transfer_encoding);
        {p++; cs = 16; goto _out;}
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st16;
tr127:
#line 146 "src/panda/protocol/http/MessageParser.rl"
	{message->chunked = true;                     }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st16;
st16:
	if ( ++p == pe )
		goto _test_eof16;
case 16:
#line 495 "src/panda/protocol/http/MessageParser.cc"
	if ( (*p) == 10 )
		goto st17;
	goto st0;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
	switch( (*p) ) {
		case 13: goto st18;
		case 33: goto tr21;
		case 67: goto tr22;
		case 84: goto tr23;
		case 99: goto tr22;
		case 116: goto tr23;
		case 124: goto tr21;
		case 126: goto tr21;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto tr21;
		} else if ( (*p) >= 35 )
			goto tr21;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto tr21;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto tr21;
		} else
			goto tr21;
	} else
		goto tr21;
	goto st0;
st18:
	if ( ++p == pe )
		goto _test_eof18;
case 18:
	if ( (*p) == 10 )
		goto tr24;
	goto st0;
tr24:
#line 16 "src/panda/protocol/http/MessageParser.rl"
	{
        {p++; cs = 321; goto _out;}
    }
	goto st321;
st321:
	if ( ++p == pe )
		goto _test_eof321;
case 321:
#line 548 "src/panda/protocol/http/MessageParser.cc"
	goto st0;
tr21:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st19;
st19:
	if ( ++p == pe )
		goto _test_eof19;
case 19:
#line 561 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
tr26:
#line 20 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string value;
            SAVE(value);
            message->headers.add(value, {});
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st20;
st20:
	if ( ++p == pe )
		goto _test_eof20;
case 20:
#line 605 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st20;
		case 13: goto tr29;
		case 32: goto st20;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto tr27;
tr27:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st21;
st21:
	if ( ++p == pe )
		goto _test_eof21;
case 21:
#line 626 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr31;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st21;
tr22:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st22;
st22:
	if ( ++p == pe )
		goto _test_eof22;
case 22:
#line 648 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 79: goto st23;
		case 111: goto st23;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st23:
	if ( ++p == pe )
		goto _test_eof23;
case 23:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 78: goto st24;
		case 110: goto st24;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st24:
	if ( ++p == pe )
		goto _test_eof24;
case 24:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 84: goto st25;
		case 116: goto st25;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st25:
	if ( ++p == pe )
		goto _test_eof25;
case 25:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 69: goto st26;
		case 101: goto st26;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st26:
	if ( ++p == pe )
		goto _test_eof26;
case 26:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 78: goto st27;
		case 110: goto st27;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st27:
	if ( ++p == pe )
		goto _test_eof27;
case 27:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 84: goto st28;
		case 116: goto st28;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st28:
	if ( ++p == pe )
		goto _test_eof28;
case 28:
	switch( (*p) ) {
		case 33: goto st19;
		case 45: goto st29;
		case 46: goto st19;
		case 58: goto tr26;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 48 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else if ( (*p) >= 65 )
			goto st19;
	} else
		goto st19;
	goto st0;
st29:
	if ( ++p == pe )
		goto _test_eof29;
case 29:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 69: goto st30;
		case 76: goto st62;
		case 101: goto st30;
		case 108: goto st62;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st30:
	if ( ++p == pe )
		goto _test_eof30;
case 30:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 78: goto st31;
		case 110: goto st31;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 67: goto st32;
		case 99: goto st32;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st32:
	if ( ++p == pe )
		goto _test_eof32;
case 32:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 79: goto st33;
		case 111: goto st33;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st33:
	if ( ++p == pe )
		goto _test_eof33;
case 33:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 68: goto st34;
		case 100: goto st34;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st34:
	if ( ++p == pe )
		goto _test_eof34;
case 34:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 73: goto st35;
		case 105: goto st35;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st35:
	if ( ++p == pe )
		goto _test_eof35;
case 35:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 78: goto st36;
		case 110: goto st36;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st36:
	if ( ++p == pe )
		goto _test_eof36;
case 36:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 71: goto st37;
		case 103: goto st37;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st37:
	if ( ++p == pe )
		goto _test_eof37;
case 37:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr48;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
tr48:
#line 20 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string value;
            SAVE(value);
            message->headers.add(value, {});
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st38;
st38:
	if ( ++p == pe )
		goto _test_eof38;
case 38:
#line 1141 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st38;
		case 13: goto tr29;
		case 32: goto st38;
		case 98: goto tr51;
		case 100: goto tr52;
		case 103: goto tr53;
		case 105: goto tr54;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto tr49;
tr49:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st39;
st39:
	if ( ++p == pe )
		goto _test_eof39;
case 39:
#line 1166 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr56;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
tr51:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st40;
st40:
	if ( ++p == pe )
		goto _test_eof40;
case 40:
#line 1188 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr56;
		case 114: goto st41;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
st41:
	if ( ++p == pe )
		goto _test_eof41;
case 41:
	switch( (*p) ) {
		case 9: goto tr58;
		case 13: goto tr59;
		case 32: goto tr58;
		case 44: goto tr60;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st39;
tr58:
#line 83 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::BROTLI; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 42; goto _out;}
            }
        }
    }
	goto st42;
tr74:
#line 72 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::DEFLATE; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 42; goto _out;}
            }
        }
    }
	goto st42;
tr80:
#line 61 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::GZIP; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 42; goto _out;}
            }
        }
    }
	goto st42;
st42:
	if ( ++p == pe )
		goto _test_eof42;
case 42:
#line 1257 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st42;
		case 13: goto tr62;
		case 32: goto st42;
		case 44: goto st43;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st39;
tr60:
#line 83 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::BROTLI; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 43; goto _out;}
            }
        }
    }
	goto st43;
tr76:
#line 72 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::DEFLATE; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 43; goto _out;}
            }
        }
    }
	goto st43;
tr82:
#line 61 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::GZIP; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 43; goto _out;}
            }
        }
    }
	goto st43;
st43:
	if ( ++p == pe )
		goto _test_eof43;
case 43:
#line 1311 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st43;
		case 13: goto tr56;
		case 32: goto st43;
		case 98: goto st40;
		case 100: goto st44;
		case 103: goto st51;
		case 105: goto st55;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st39;
tr52:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st44;
st44:
	if ( ++p == pe )
		goto _test_eof44;
case 44:
#line 1336 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr56;
		case 101: goto st45;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
st45:
	if ( ++p == pe )
		goto _test_eof45;
case 45:
	switch( (*p) ) {
		case 13: goto tr56;
		case 102: goto st46;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
st46:
	if ( ++p == pe )
		goto _test_eof46;
case 46:
	switch( (*p) ) {
		case 13: goto tr56;
		case 108: goto st47;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
st47:
	if ( ++p == pe )
		goto _test_eof47;
case 47:
	switch( (*p) ) {
		case 13: goto tr56;
		case 97: goto st48;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
st48:
	if ( ++p == pe )
		goto _test_eof48;
case 48:
	switch( (*p) ) {
		case 13: goto tr56;
		case 116: goto st49;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
st49:
	if ( ++p == pe )
		goto _test_eof49;
case 49:
	switch( (*p) ) {
		case 13: goto tr56;
		case 101: goto st50;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
st50:
	if ( ++p == pe )
		goto _test_eof50;
case 50:
	switch( (*p) ) {
		case 9: goto tr74;
		case 13: goto tr75;
		case 32: goto tr74;
		case 44: goto tr76;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st39;
tr53:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st51;
st51:
	if ( ++p == pe )
		goto _test_eof51;
case 51:
#line 1448 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr56;
		case 122: goto st52;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
st52:
	if ( ++p == pe )
		goto _test_eof52;
case 52:
	switch( (*p) ) {
		case 13: goto tr56;
		case 105: goto st53;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
st53:
	if ( ++p == pe )
		goto _test_eof53;
case 53:
	switch( (*p) ) {
		case 13: goto tr56;
		case 112: goto st54;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
st54:
	if ( ++p == pe )
		goto _test_eof54;
case 54:
	switch( (*p) ) {
		case 9: goto tr80;
		case 13: goto tr81;
		case 32: goto tr80;
		case 44: goto tr82;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st39;
tr54:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st55;
st55:
	if ( ++p == pe )
		goto _test_eof55;
case 55:
#line 1515 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr56;
		case 100: goto st56;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
st56:
	if ( ++p == pe )
		goto _test_eof56;
case 56:
	switch( (*p) ) {
		case 13: goto tr56;
		case 101: goto st57;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
st57:
	if ( ++p == pe )
		goto _test_eof57;
case 57:
	switch( (*p) ) {
		case 13: goto tr56;
		case 110: goto st58;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
st58:
	if ( ++p == pe )
		goto _test_eof58;
case 58:
	switch( (*p) ) {
		case 13: goto tr56;
		case 116: goto st59;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
st59:
	if ( ++p == pe )
		goto _test_eof59;
case 59:
	switch( (*p) ) {
		case 13: goto tr56;
		case 105: goto st60;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
st60:
	if ( ++p == pe )
		goto _test_eof60;
case 60:
	switch( (*p) ) {
		case 13: goto tr56;
		case 116: goto st61;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
st61:
	if ( ++p == pe )
		goto _test_eof61;
case 61:
	switch( (*p) ) {
		case 13: goto tr56;
		case 121: goto st42;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st39;
st62:
	if ( ++p == pe )
		goto _test_eof62;
case 62:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 69: goto st63;
		case 101: goto st63;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st63:
	if ( ++p == pe )
		goto _test_eof63;
case 63:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 78: goto st64;
		case 110: goto st64;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st64:
	if ( ++p == pe )
		goto _test_eof64;
case 64:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 71: goto st65;
		case 103: goto st65;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st65:
	if ( ++p == pe )
		goto _test_eof65;
case 65:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 84: goto st66;
		case 116: goto st66;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st66:
	if ( ++p == pe )
		goto _test_eof66;
case 66:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 72: goto st67;
		case 104: goto st67;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st67:
	if ( ++p == pe )
		goto _test_eof67;
case 67:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr94;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
tr94:
#line 20 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string value;
            SAVE(value);
            message->headers.add(value, {});
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st68;
st68:
	if ( ++p == pe )
		goto _test_eof68;
case 68:
#line 1814 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st68;
		case 13: goto tr29;
		case 32: goto st68;
		case 127: goto st0;
	}
	if ( (*p) > 31 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr96;
	} else if ( (*p) >= 0 )
		goto st0;
	goto tr27;
tr96:
#line 38 "src/panda/protocol/http/MessageParser.rl"
	{
        if (has_content_length) {
            cs = message_parser_error;
            set_error(errc::multiple_content_length);
            {p++; cs = 69; goto _out;}
        }
        has_content_length = true;
    }
#line 145 "src/panda/protocol/http/MessageParser.rl"
	{ADD_DIGIT(content_length)}
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st69;
tr97:
#line 145 "src/panda/protocol/http/MessageParser.rl"
	{ADD_DIGIT(content_length)}
	goto st69;
st69:
	if ( ++p == pe )
		goto _test_eof69;
case 69:
#line 1853 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr31;
		case 127: goto st0;
	}
	if ( (*p) < 10 ) {
		if ( 0 <= (*p) && (*p) <= 8 )
			goto st0;
	} else if ( (*p) > 31 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr97;
	} else
		goto st0;
	goto st21;
tr23:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st70;
st70:
	if ( ++p == pe )
		goto _test_eof70;
case 70:
#line 1878 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 82: goto st71;
		case 114: goto st71;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st71:
	if ( ++p == pe )
		goto _test_eof71;
case 71:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 65: goto st72;
		case 97: goto st72;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 66 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st72:
	if ( ++p == pe )
		goto _test_eof72;
case 72:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 78: goto st73;
		case 110: goto st73;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st73:
	if ( ++p == pe )
		goto _test_eof73;
case 73:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 83: goto st74;
		case 115: goto st74;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st74:
	if ( ++p == pe )
		goto _test_eof74;
case 74:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 70: goto st75;
		case 102: goto st75;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st75:
	if ( ++p == pe )
		goto _test_eof75;
case 75:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 69: goto st76;
		case 101: goto st76;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st76:
	if ( ++p == pe )
		goto _test_eof76;
case 76:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 82: goto st77;
		case 114: goto st77;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st77:
	if ( ++p == pe )
		goto _test_eof77;
case 77:
	switch( (*p) ) {
		case 33: goto st19;
		case 45: goto st78;
		case 46: goto st19;
		case 58: goto tr26;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 48 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else if ( (*p) >= 65 )
			goto st19;
	} else
		goto st19;
	goto st0;
st78:
	if ( ++p == pe )
		goto _test_eof78;
case 78:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 69: goto st79;
		case 101: goto st79;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st79:
	if ( ++p == pe )
		goto _test_eof79;
case 79:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 78: goto st80;
		case 110: goto st80;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st80:
	if ( ++p == pe )
		goto _test_eof80;
case 80:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 67: goto st81;
		case 99: goto st81;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st81:
	if ( ++p == pe )
		goto _test_eof81;
case 81:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 79: goto st82;
		case 111: goto st82;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st82:
	if ( ++p == pe )
		goto _test_eof82;
case 82:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 68: goto st83;
		case 100: goto st83;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st83:
	if ( ++p == pe )
		goto _test_eof83;
case 83:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 73: goto st84;
		case 105: goto st84;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st84:
	if ( ++p == pe )
		goto _test_eof84;
case 84:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 78: goto st85;
		case 110: goto st85;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st85:
	if ( ++p == pe )
		goto _test_eof85;
case 85:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr26;
		case 71: goto st86;
		case 103: goto st86;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
st86:
	if ( ++p == pe )
		goto _test_eof86;
case 86:
	switch( (*p) ) {
		case 33: goto st19;
		case 58: goto tr114;
		case 124: goto st19;
		case 126: goto st19;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st19;
		} else if ( (*p) >= 35 )
			goto st19;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st19;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st19;
		} else
			goto st19;
	} else
		goto st19;
	goto st0;
tr114:
#line 20 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string value;
            SAVE(value);
            message->headers.add(value, {});
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st87;
st87:
	if ( ++p == pe )
		goto _test_eof87;
case 87:
#line 2399 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st87;
		case 13: goto tr29;
		case 32: goto st87;
		case 67: goto tr117;
		case 99: goto tr117;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto tr115;
tr115:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st88;
st88:
	if ( ++p == pe )
		goto _test_eof88;
case 88:
#line 2422 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr119;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st88;
tr117:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st89;
st89:
	if ( ++p == pe )
		goto _test_eof89;
case 89:
#line 2444 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr119;
		case 72: goto st90;
		case 104: goto st90;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st88;
st90:
	if ( ++p == pe )
		goto _test_eof90;
case 90:
	switch( (*p) ) {
		case 13: goto tr119;
		case 85: goto st91;
		case 117: goto st91;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st88;
st91:
	if ( ++p == pe )
		goto _test_eof91;
case 91:
	switch( (*p) ) {
		case 13: goto tr119;
		case 78: goto st92;
		case 110: goto st92;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st88;
st92:
	if ( ++p == pe )
		goto _test_eof92;
case 92:
	switch( (*p) ) {
		case 13: goto tr119;
		case 75: goto st93;
		case 107: goto st93;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st88;
st93:
	if ( ++p == pe )
		goto _test_eof93;
case 93:
	switch( (*p) ) {
		case 13: goto tr119;
		case 69: goto st94;
		case 101: goto st94;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st88;
st94:
	if ( ++p == pe )
		goto _test_eof94;
case 94:
	switch( (*p) ) {
		case 13: goto tr119;
		case 68: goto st95;
		case 100: goto st95;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st88;
st95:
	if ( ++p == pe )
		goto _test_eof95;
case 95:
	switch( (*p) ) {
		case 9: goto tr126;
		case 13: goto tr127;
		case 32: goto tr126;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st88;
tr126:
#line 146 "src/panda/protocol/http/MessageParser.rl"
	{message->chunked = true;                     }
	goto st96;
st96:
	if ( ++p == pe )
		goto _test_eof96;
case 96:
#line 2558 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st96;
		case 13: goto tr31;
		case 32: goto st96;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st88;
st97:
	if ( ++p == pe )
		goto _test_eof97;
case 97:
	if ( (*p) == 32 )
		goto tr129;
	goto st0;
case 98:
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr130;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr130;
	} else
		goto tr130;
	goto st0;
tr130:
#line 159 "src/panda/protocol/http/MessageParser.rl"
	{chunk_length = 0;}
#line 159 "src/panda/protocol/http/MessageParser.rl"
	{ADD_XDIGIT(chunk_length)}
	goto st99;
tr132:
#line 159 "src/panda/protocol/http/MessageParser.rl"
	{ADD_XDIGIT(chunk_length)}
	goto st99;
st99:
	if ( ++p == pe )
		goto _test_eof99;
case 99:
#line 2599 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto st100;
		case 59: goto st101;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr132;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr132;
	} else
		goto tr132;
	goto st0;
st100:
	if ( ++p == pe )
		goto _test_eof100;
case 100:
	if ( (*p) == 10 )
		goto tr134;
	goto st0;
tr134:
#line 16 "src/panda/protocol/http/MessageParser.rl"
	{
        {p++; cs = 322; goto _out;}
    }
	goto st322;
st322:
	if ( ++p == pe )
		goto _test_eof322;
case 322:
#line 2630 "src/panda/protocol/http/MessageParser.cc"
	goto st0;
st101:
	if ( ++p == pe )
		goto _test_eof101;
case 101:
	switch( (*p) ) {
		case 33: goto st102;
		case 124: goto st102;
		case 126: goto st102;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st102;
		} else if ( (*p) >= 35 )
			goto st102;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st102;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st102;
		} else
			goto st102;
	} else
		goto st102;
	goto st0;
st102:
	if ( ++p == pe )
		goto _test_eof102;
case 102:
	switch( (*p) ) {
		case 13: goto st100;
		case 33: goto st102;
		case 59: goto st101;
		case 61: goto st103;
		case 124: goto st102;
		case 126: goto st102;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st102;
		} else if ( (*p) >= 35 )
			goto st102;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st102;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st102;
		} else
			goto st102;
	} else
		goto st102;
	goto st0;
st103:
	if ( ++p == pe )
		goto _test_eof103;
case 103:
	switch( (*p) ) {
		case 34: goto st105;
		case 124: goto st104;
		case 126: goto st104;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st104;
		} else if ( (*p) >= 33 )
			goto st104;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st104;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st104;
		} else
			goto st104;
	} else
		goto st104;
	goto st0;
st104:
	if ( ++p == pe )
		goto _test_eof104;
case 104:
	switch( (*p) ) {
		case 13: goto st100;
		case 33: goto st104;
		case 59: goto st101;
		case 124: goto st104;
		case 126: goto st104;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st104;
		} else if ( (*p) >= 35 )
			goto st104;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st104;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st104;
		} else
			goto st104;
	} else
		goto st104;
	goto st0;
st105:
	if ( ++p == pe )
		goto _test_eof105;
case 105:
	switch( (*p) ) {
		case 34: goto st106;
		case 92: goto st107;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st105;
st106:
	if ( ++p == pe )
		goto _test_eof106;
case 106:
	switch( (*p) ) {
		case 13: goto st100;
		case 59: goto st101;
	}
	goto st0;
st107:
	if ( ++p == pe )
		goto _test_eof107;
case 107:
	if ( (*p) == 127 )
		goto st0;
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st105;
case 108:
	if ( (*p) == 13 )
		goto st109;
	goto st0;
st109:
	if ( ++p == pe )
		goto _test_eof109;
case 109:
	if ( (*p) == 10 )
		goto st110;
	goto st0;
st110:
	if ( ++p == pe )
		goto _test_eof110;
case 110:
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr143;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr143;
	} else
		goto tr143;
	goto st0;
tr143:
#line 159 "src/panda/protocol/http/MessageParser.rl"
	{chunk_length = 0;}
#line 159 "src/panda/protocol/http/MessageParser.rl"
	{ADD_XDIGIT(chunk_length)}
	goto st111;
tr145:
#line 159 "src/panda/protocol/http/MessageParser.rl"
	{ADD_XDIGIT(chunk_length)}
	goto st111;
st111:
	if ( ++p == pe )
		goto _test_eof111;
case 111:
#line 2819 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto st112;
		case 59: goto st113;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr145;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr145;
	} else
		goto tr145;
	goto st0;
st112:
	if ( ++p == pe )
		goto _test_eof112;
case 112:
	if ( (*p) == 10 )
		goto tr147;
	goto st0;
tr147:
#line 16 "src/panda/protocol/http/MessageParser.rl"
	{
        {p++; cs = 323; goto _out;}
    }
	goto st323;
st323:
	if ( ++p == pe )
		goto _test_eof323;
case 323:
#line 2850 "src/panda/protocol/http/MessageParser.cc"
	goto st0;
st113:
	if ( ++p == pe )
		goto _test_eof113;
case 113:
	switch( (*p) ) {
		case 33: goto st114;
		case 124: goto st114;
		case 126: goto st114;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st114;
		} else if ( (*p) >= 35 )
			goto st114;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st114;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st114;
		} else
			goto st114;
	} else
		goto st114;
	goto st0;
st114:
	if ( ++p == pe )
		goto _test_eof114;
case 114:
	switch( (*p) ) {
		case 13: goto st112;
		case 33: goto st114;
		case 59: goto st113;
		case 61: goto st115;
		case 124: goto st114;
		case 126: goto st114;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st114;
		} else if ( (*p) >= 35 )
			goto st114;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st114;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st114;
		} else
			goto st114;
	} else
		goto st114;
	goto st0;
st115:
	if ( ++p == pe )
		goto _test_eof115;
case 115:
	switch( (*p) ) {
		case 34: goto st117;
		case 124: goto st116;
		case 126: goto st116;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st116;
		} else if ( (*p) >= 33 )
			goto st116;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st116;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st116;
		} else
			goto st116;
	} else
		goto st116;
	goto st0;
st116:
	if ( ++p == pe )
		goto _test_eof116;
case 116:
	switch( (*p) ) {
		case 13: goto st112;
		case 33: goto st116;
		case 59: goto st113;
		case 124: goto st116;
		case 126: goto st116;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st116;
		} else if ( (*p) >= 35 )
			goto st116;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st116;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st116;
		} else
			goto st116;
	} else
		goto st116;
	goto st0;
st117:
	if ( ++p == pe )
		goto _test_eof117;
case 117:
	switch( (*p) ) {
		case 34: goto st118;
		case 92: goto st119;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st117;
st118:
	if ( ++p == pe )
		goto _test_eof118;
case 118:
	switch( (*p) ) {
		case 13: goto st112;
		case 59: goto st113;
	}
	goto st0;
st119:
	if ( ++p == pe )
		goto _test_eof119;
case 119:
	if ( (*p) == 127 )
		goto st0;
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st117;
st120:
	if ( ++p == pe )
		goto _test_eof120;
case 120:
	switch( (*p) ) {
		case 13: goto st121;
		case 33: goto tr155;
		case 124: goto tr155;
		case 126: goto tr155;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto tr155;
		} else if ( (*p) >= 35 )
			goto tr155;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto tr155;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto tr155;
		} else
			goto tr155;
	} else
		goto tr155;
	goto st0;
st121:
	if ( ++p == pe )
		goto _test_eof121;
case 121:
	if ( (*p) == 10 )
		goto tr156;
	goto st0;
tr156:
#line 16 "src/panda/protocol/http/MessageParser.rl"
	{
        {p++; cs = 324; goto _out;}
    }
	goto st324;
st324:
	if ( ++p == pe )
		goto _test_eof324;
case 324:
#line 3046 "src/panda/protocol/http/MessageParser.cc"
	goto st0;
tr155:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st122;
st122:
	if ( ++p == pe )
		goto _test_eof122;
case 122:
#line 3059 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 33: goto st122;
		case 58: goto tr158;
		case 124: goto st122;
		case 126: goto st122;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st122;
		} else if ( (*p) >= 35 )
			goto st122;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st122;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st122;
		} else
			goto st122;
	} else
		goto st122;
	goto st0;
tr158:
#line 20 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string value;
            SAVE(value);
            message->headers.add(value, {});
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st123;
st123:
	if ( ++p == pe )
		goto _test_eof123;
case 123:
#line 3103 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st123;
		case 13: goto tr161;
		case 32: goto st123;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto tr159;
tr159:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st124;
st124:
	if ( ++p == pe )
		goto _test_eof124;
case 124:
#line 3124 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr163;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st124;
tr161:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st125;
tr163:
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st125;
st125:
	if ( ++p == pe )
		goto _test_eof125;
case 125:
#line 3174 "src/panda/protocol/http/MessageParser.cc"
	if ( (*p) == 10 )
		goto st120;
	goto st0;
case 126:
	switch( (*p) ) {
		case 67: goto st127;
		case 68: goto st290;
		case 71: goto st296;
		case 72: goto st299;
		case 79: goto st303;
		case 80: goto st310;
		case 84: goto st316;
	}
	goto st0;
st127:
	if ( ++p == pe )
		goto _test_eof127;
case 127:
	if ( (*p) == 79 )
		goto st128;
	goto st0;
st128:
	if ( ++p == pe )
		goto _test_eof128;
case 128:
	if ( (*p) == 78 )
		goto st129;
	goto st0;
st129:
	if ( ++p == pe )
		goto _test_eof129;
case 129:
	if ( (*p) == 78 )
		goto st130;
	goto st0;
st130:
	if ( ++p == pe )
		goto _test_eof130;
case 130:
	if ( (*p) == 69 )
		goto st131;
	goto st0;
st131:
	if ( ++p == pe )
		goto _test_eof131;
case 131:
	if ( (*p) == 67 )
		goto st132;
	goto st0;
st132:
	if ( ++p == pe )
		goto _test_eof132;
case 132:
	if ( (*p) == 84 )
		goto st133;
	goto st0;
st133:
	if ( ++p == pe )
		goto _test_eof133;
case 133:
	if ( (*p) == 32 )
		goto tr178;
	goto st0;
tr178:
#line 176 "src/panda/protocol/http/MessageParser.rl"
	{request->method_raw(Request::Method::Connect); }
	goto st134;
tr401:
#line 174 "src/panda/protocol/http/MessageParser.rl"
	{request->method_raw(Request::Method::Delete);  }
	goto st134;
tr404:
#line 170 "src/panda/protocol/http/MessageParser.rl"
	{request->method_raw(Request::Method::Get);     }
	goto st134;
tr408:
#line 171 "src/panda/protocol/http/MessageParser.rl"
	{request->method_raw(Request::Method::Head);    }
	goto st134;
tr415:
#line 169 "src/panda/protocol/http/MessageParser.rl"
	{request->method_raw(Request::Method::Options); }
	goto st134;
tr420:
#line 172 "src/panda/protocol/http/MessageParser.rl"
	{request->method_raw(Request::Method::Post);    }
	goto st134;
tr422:
#line 173 "src/panda/protocol/http/MessageParser.rl"
	{request->method_raw(Request::Method::Put);     }
	goto st134;
tr427:
#line 175 "src/panda/protocol/http/MessageParser.rl"
	{request->method_raw(Request::Method::Trace);   }
	goto st134;
st134:
	if ( ++p == pe )
		goto _test_eof134;
case 134:
#line 3274 "src/panda/protocol/http/MessageParser.cc"
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr179;
	goto st0;
tr179:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st135;
st135:
	if ( ++p == pe )
		goto _test_eof135;
case 135:
#line 3289 "src/panda/protocol/http/MessageParser.cc"
	if ( (*p) == 32 )
		goto tr180;
	if ( 33 <= (*p) && (*p) <= 126 )
		goto st135;
	goto st0;
tr180:
#line 108 "src/panda/protocol/http/MessageParser.rl"
	{
        string target;
        SAVE(target);
        request->uri = new URI(target);
        if (target.length() >= 2 && target[0] == '/' && target[1] == '/') { // treat protocol-relative url as path
            proto_relative_uri = true;
        }
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st136;
st136:
	if ( ++p == pe )
		goto _test_eof136;
case 136:
#line 3314 "src/panda/protocol/http/MessageParser.cc"
	if ( (*p) == 72 )
		goto st137;
	goto st0;
st137:
	if ( ++p == pe )
		goto _test_eof137;
case 137:
	if ( (*p) == 84 )
		goto st138;
	goto st0;
st138:
	if ( ++p == pe )
		goto _test_eof138;
case 138:
	if ( (*p) == 84 )
		goto st139;
	goto st0;
st139:
	if ( ++p == pe )
		goto _test_eof139;
case 139:
	if ( (*p) == 80 )
		goto st140;
	goto st0;
st140:
	if ( ++p == pe )
		goto _test_eof140;
case 140:
	if ( (*p) == 47 )
		goto st141;
	goto st0;
st141:
	if ( ++p == pe )
		goto _test_eof141;
case 141:
	if ( (*p) == 49 )
		goto st142;
	goto st0;
st142:
	if ( ++p == pe )
		goto _test_eof142;
case 142:
	if ( (*p) == 46 )
		goto st143;
	goto st0;
st143:
	if ( ++p == pe )
		goto _test_eof143;
case 143:
	switch( (*p) ) {
		case 48: goto st144;
		case 49: goto st289;
	}
	goto st0;
st144:
	if ( ++p == pe )
		goto _test_eof144;
case 144:
	if ( (*p) == 13 )
		goto tr191;
	goto st0;
tr191:
#line 124 "src/panda/protocol/http/MessageParser.rl"
	{message->http_version = 10;}
	goto st145;
tr203:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st145;
tr205:
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st145;
tr322:
#line 53 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            cs = message_parser_error;
            set_error(errc::unsupported_compression);
            {p++; cs = 145; goto _out;}
        }
    }
#line 94 "src/panda/protocol/http/MessageParser.rl"
	{
        if (message->compression.type != Compression::IDENTITY) {
            auto it = compression::instantiate(message->compression.type);
            if (it) {
                it->prepare_uncompress(max_body_size);
                compressor = std::move(it);
            } else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 145; goto _out;}
            }
        }
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st145;
tr325:
#line 83 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::BROTLI; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 145; goto _out;}
            }
        }
    }
#line 94 "src/panda/protocol/http/MessageParser.rl"
	{
        if (message->compression.type != Compression::IDENTITY) {
            auto it = compression::instantiate(message->compression.type);
            if (it) {
                it->prepare_uncompress(max_body_size);
                compressor = std::move(it);
            } else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 145; goto _out;}
            }
        }
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st145;
tr328:
#line 94 "src/panda/protocol/http/MessageParser.rl"
	{
        if (message->compression.type != Compression::IDENTITY) {
            auto it = compression::instantiate(message->compression.type);
            if (it) {
                it->prepare_uncompress(max_body_size);
                compressor = std::move(it);
            } else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 145; goto _out;}
            }
        }
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st145;
tr341:
#line 72 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::DEFLATE; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 145; goto _out;}
            }
        }
    }
#line 94 "src/panda/protocol/http/MessageParser.rl"
	{
        if (message->compression.type != Compression::IDENTITY) {
            auto it = compression::instantiate(message->compression.type);
            if (it) {
                it->prepare_uncompress(max_body_size);
                compressor = std::move(it);
            } else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 145; goto _out;}
            }
        }
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st145;
tr347:
#line 61 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::GZIP; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 145; goto _out;}
            }
        }
    }
#line 94 "src/panda/protocol/http/MessageParser.rl"
	{
        if (message->compression.type != Compression::IDENTITY) {
            auto it = compression::instantiate(message->compression.type);
            if (it) {
                it->prepare_uncompress(max_body_size);
                compressor = std::move(it);
            } else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 145; goto _out;}
            }
        }
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st145;
tr385:
#line 47 "src/panda/protocol/http/MessageParser.rl"
	{
        cs = message_parser_error;
        set_error(errc::unsupported_transfer_encoding);
        {p++; cs = 145; goto _out;}
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st145;
tr393:
#line 146 "src/panda/protocol/http/MessageParser.rl"
	{message->chunked = true;                     }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st145;
tr395:
#line 124 "src/panda/protocol/http/MessageParser.rl"
	{message->http_version = 11;}
	goto st145;
tr229:
#line 132 "src/panda/protocol/http/MessageParser.rl"
	{compr = Compression::GZIP | Compression::DEFLATE; }
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st145;
tr243:
#line 129 "src/panda/protocol/http/MessageParser.rl"
	{ compr = Compression::BROTLI;  }
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st145;
tr251:
#line 134 "src/panda/protocol/http/MessageParser.rl"
	{ compr = 0; }
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st145;
tr262:
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st145;
tr282:
#line 128 "src/panda/protocol/http/MessageParser.rl"
	{ compr = Compression::DEFLATE;  }
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st145;
tr289:
#line 127 "src/panda/protocol/http/MessageParser.rl"
	{ compr = Compression::GZIP;     }
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
#line 29 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st145;
st145:
	if ( ++p == pe )
		goto _test_eof145;
case 145:
#line 3789 "src/panda/protocol/http/MessageParser.cc"
	if ( (*p) == 10 )
		goto st146;
	goto st0;
st146:
	if ( ++p == pe )
		goto _test_eof146;
case 146:
	switch( (*p) ) {
		case 13: goto st147;
		case 33: goto tr194;
		case 65: goto tr195;
		case 67: goto tr196;
		case 84: goto tr197;
		case 97: goto tr195;
		case 99: goto tr196;
		case 116: goto tr197;
		case 124: goto tr194;
		case 126: goto tr194;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto tr194;
		} else if ( (*p) >= 35 )
			goto tr194;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 66 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto tr194;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto tr194;
		} else
			goto tr194;
	} else
		goto tr194;
	goto st0;
st147:
	if ( ++p == pe )
		goto _test_eof147;
case 147:
	if ( (*p) == 10 )
		goto tr198;
	goto st0;
tr198:
#line 16 "src/panda/protocol/http/MessageParser.rl"
	{
        {p++; cs = 325; goto _out;}
    }
	goto st325;
st325:
	if ( ++p == pe )
		goto _test_eof325;
case 325:
#line 3844 "src/panda/protocol/http/MessageParser.cc"
	goto st0;
tr194:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st148;
st148:
	if ( ++p == pe )
		goto _test_eof148;
case 148:
#line 3857 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
tr200:
#line 20 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string value;
            SAVE(value);
            message->headers.add(value, {});
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st149;
st149:
	if ( ++p == pe )
		goto _test_eof149;
case 149:
#line 3901 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st149;
		case 13: goto tr203;
		case 32: goto st149;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto tr201;
tr201:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st150;
st150:
	if ( ++p == pe )
		goto _test_eof150;
case 150:
#line 3922 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr205;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
tr195:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st151;
st151:
	if ( ++p == pe )
		goto _test_eof151;
case 151:
#line 3944 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 67: goto st152;
		case 99: goto st152;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st152:
	if ( ++p == pe )
		goto _test_eof152;
case 152:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 67: goto st153;
		case 99: goto st153;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st153:
	if ( ++p == pe )
		goto _test_eof153;
case 153:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 69: goto st154;
		case 101: goto st154;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st154:
	if ( ++p == pe )
		goto _test_eof154;
case 154:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 80: goto st155;
		case 112: goto st155;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st155:
	if ( ++p == pe )
		goto _test_eof155;
case 155:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 84: goto st156;
		case 116: goto st156;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st156:
	if ( ++p == pe )
		goto _test_eof156;
case 156:
	switch( (*p) ) {
		case 33: goto st148;
		case 45: goto st157;
		case 46: goto st148;
		case 58: goto tr200;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 48 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else if ( (*p) >= 65 )
			goto st148;
	} else
		goto st148;
	goto st0;
st157:
	if ( ++p == pe )
		goto _test_eof157;
case 157:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 69: goto st158;
		case 101: goto st158;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st158:
	if ( ++p == pe )
		goto _test_eof158;
case 158:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 78: goto st159;
		case 110: goto st159;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st159:
	if ( ++p == pe )
		goto _test_eof159;
case 159:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 67: goto st160;
		case 99: goto st160;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st160:
	if ( ++p == pe )
		goto _test_eof160;
case 160:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 79: goto st161;
		case 111: goto st161;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st161:
	if ( ++p == pe )
		goto _test_eof161;
case 161:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 68: goto st162;
		case 100: goto st162;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st162:
	if ( ++p == pe )
		goto _test_eof162;
case 162:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 73: goto st163;
		case 105: goto st163;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st163:
	if ( ++p == pe )
		goto _test_eof163;
case 163:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 78: goto st164;
		case 110: goto st164;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st164:
	if ( ++p == pe )
		goto _test_eof164;
case 164:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 71: goto st165;
		case 103: goto st165;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st165:
	if ( ++p == pe )
		goto _test_eof165;
case 165:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr220;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
tr220:
#line 20 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string value;
            SAVE(value);
            message->headers.add(value, {});
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st166;
st166:
	if ( ++p == pe )
		goto _test_eof166;
case 166:
#line 4405 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st166;
		case 13: goto tr203;
		case 32: goto st166;
		case 42: goto tr222;
		case 98: goto tr223;
		case 99: goto tr224;
		case 100: goto tr225;
		case 103: goto tr226;
		case 105: goto tr227;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto tr201;
tr222:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st167;
st167:
	if ( ++p == pe )
		goto _test_eof167;
case 167:
#line 4432 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto tr228;
		case 13: goto tr229;
		case 32: goto tr228;
		case 44: goto tr230;
		case 59: goto tr231;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st150;
tr228:
#line 132 "src/panda/protocol/http/MessageParser.rl"
	{compr = Compression::GZIP | Compression::DEFLATE; }
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
	goto st168;
tr242:
#line 129 "src/panda/protocol/http/MessageParser.rl"
	{ compr = Compression::BROTLI;  }
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
	goto st168;
tr274:
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
	goto st168;
tr281:
#line 128 "src/panda/protocol/http/MessageParser.rl"
	{ compr = Compression::DEFLATE;  }
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
	goto st168;
tr288:
#line 127 "src/panda/protocol/http/MessageParser.rl"
	{ compr = Compression::GZIP;     }
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
	goto st168;
st168:
	if ( ++p == pe )
		goto _test_eof168;
case 168:
#line 4501 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st168;
		case 13: goto tr205;
		case 32: goto st168;
		case 44: goto st169;
		case 59: goto st172;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st150;
tr230:
#line 132 "src/panda/protocol/http/MessageParser.rl"
	{compr = Compression::GZIP | Compression::DEFLATE; }
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
	goto st169;
tr244:
#line 129 "src/panda/protocol/http/MessageParser.rl"
	{ compr = Compression::BROTLI;  }
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
	goto st169;
tr252:
#line 134 "src/panda/protocol/http/MessageParser.rl"
	{ compr = 0; }
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
	goto st169;
tr263:
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
	goto st169;
tr283:
#line 128 "src/panda/protocol/http/MessageParser.rl"
	{ compr = Compression::DEFLATE;  }
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
	goto st169;
tr290:
#line 127 "src/panda/protocol/http/MessageParser.rl"
	{ compr = Compression::GZIP;     }
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
	goto st169;
st169:
	if ( ++p == pe )
		goto _test_eof169;
case 169:
#line 4581 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st169;
		case 13: goto tr205;
		case 32: goto st169;
		case 42: goto st167;
		case 98: goto st170;
		case 99: goto st188;
		case 100: goto st196;
		case 103: goto st203;
		case 105: goto st207;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st150;
tr223:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st170;
st170:
	if ( ++p == pe )
		goto _test_eof170;
case 170:
#line 4608 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr205;
		case 114: goto st171;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st171:
	if ( ++p == pe )
		goto _test_eof171;
case 171:
	switch( (*p) ) {
		case 9: goto tr242;
		case 13: goto tr243;
		case 32: goto tr242;
		case 44: goto tr244;
		case 59: goto tr245;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st150;
tr231:
#line 132 "src/panda/protocol/http/MessageParser.rl"
	{compr = Compression::GZIP | Compression::DEFLATE; }
	goto st172;
tr245:
#line 129 "src/panda/protocol/http/MessageParser.rl"
	{ compr = Compression::BROTLI;  }
	goto st172;
tr284:
#line 128 "src/panda/protocol/http/MessageParser.rl"
	{ compr = Compression::DEFLATE;  }
	goto st172;
tr291:
#line 127 "src/panda/protocol/http/MessageParser.rl"
	{ compr = Compression::GZIP;     }
	goto st172;
st172:
	if ( ++p == pe )
		goto _test_eof172;
case 172:
#line 4655 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st172;
		case 13: goto tr205;
		case 32: goto st172;
		case 113: goto st173;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st150;
st173:
	if ( ++p == pe )
		goto _test_eof173;
case 173:
	switch( (*p) ) {
		case 13: goto tr205;
		case 61: goto st174;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st174:
	if ( ++p == pe )
		goto _test_eof174;
case 174:
	switch( (*p) ) {
		case 13: goto tr205;
		case 48: goto st175;
		case 49: goto st184;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st175:
	if ( ++p == pe )
		goto _test_eof175;
case 175:
	switch( (*p) ) {
		case 9: goto tr250;
		case 13: goto tr251;
		case 32: goto tr250;
		case 44: goto tr252;
		case 46: goto st177;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st150;
tr250:
#line 134 "src/panda/protocol/http/MessageParser.rl"
	{ compr = 0; }
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
	goto st176;
tr261:
#line 117 "src/panda/protocol/http/MessageParser.rl"
	{
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
	goto st176;
st176:
	if ( ++p == pe )
		goto _test_eof176;
case 176:
#line 4736 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st176;
		case 13: goto tr205;
		case 32: goto st176;
		case 44: goto st169;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st150;
st177:
	if ( ++p == pe )
		goto _test_eof177;
case 177:
	switch( (*p) ) {
		case 9: goto tr250;
		case 13: goto tr251;
		case 32: goto tr250;
		case 44: goto tr252;
		case 48: goto st178;
		case 127: goto st0;
	}
	if ( (*p) > 31 ) {
		if ( 49 <= (*p) && (*p) <= 57 )
			goto st183;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st178:
	if ( ++p == pe )
		goto _test_eof178;
case 178:
	switch( (*p) ) {
		case 9: goto tr250;
		case 13: goto tr251;
		case 32: goto tr250;
		case 44: goto tr252;
		case 48: goto st179;
		case 127: goto st0;
	}
	if ( (*p) > 31 ) {
		if ( 49 <= (*p) && (*p) <= 57 )
			goto st182;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st179:
	if ( ++p == pe )
		goto _test_eof179;
case 179:
	switch( (*p) ) {
		case 9: goto tr250;
		case 13: goto tr251;
		case 32: goto tr250;
		case 44: goto tr252;
		case 48: goto st180;
		case 127: goto st0;
	}
	if ( (*p) > 31 ) {
		if ( 49 <= (*p) && (*p) <= 57 )
			goto st181;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st180:
	if ( ++p == pe )
		goto _test_eof180;
case 180:
	switch( (*p) ) {
		case 9: goto tr250;
		case 13: goto tr251;
		case 32: goto tr250;
		case 44: goto tr252;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st150;
st181:
	if ( ++p == pe )
		goto _test_eof181;
case 181:
	switch( (*p) ) {
		case 9: goto tr261;
		case 13: goto tr262;
		case 32: goto tr261;
		case 44: goto tr263;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st150;
st182:
	if ( ++p == pe )
		goto _test_eof182;
case 182:
	switch( (*p) ) {
		case 9: goto tr261;
		case 13: goto tr262;
		case 32: goto tr261;
		case 44: goto tr263;
		case 127: goto st0;
	}
	if ( (*p) > 31 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st181;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st183:
	if ( ++p == pe )
		goto _test_eof183;
case 183:
	switch( (*p) ) {
		case 9: goto tr261;
		case 13: goto tr262;
		case 32: goto tr261;
		case 44: goto tr263;
		case 127: goto st0;
	}
	if ( (*p) > 31 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st182;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st184:
	if ( ++p == pe )
		goto _test_eof184;
case 184:
	switch( (*p) ) {
		case 9: goto tr261;
		case 13: goto tr262;
		case 32: goto tr261;
		case 44: goto tr263;
		case 46: goto st185;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st150;
st185:
	if ( ++p == pe )
		goto _test_eof185;
case 185:
	switch( (*p) ) {
		case 9: goto tr261;
		case 13: goto tr262;
		case 32: goto tr261;
		case 44: goto tr263;
		case 48: goto st186;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st150;
st186:
	if ( ++p == pe )
		goto _test_eof186;
case 186:
	switch( (*p) ) {
		case 9: goto tr261;
		case 13: goto tr262;
		case 32: goto tr261;
		case 44: goto tr263;
		case 48: goto st187;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st150;
st187:
	if ( ++p == pe )
		goto _test_eof187;
case 187:
	switch( (*p) ) {
		case 9: goto tr261;
		case 13: goto tr262;
		case 32: goto tr261;
		case 44: goto tr263;
		case 48: goto st181;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st150;
tr224:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st188;
st188:
	if ( ++p == pe )
		goto _test_eof188;
case 188:
#line 4934 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr205;
		case 111: goto st189;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st189:
	if ( ++p == pe )
		goto _test_eof189;
case 189:
	switch( (*p) ) {
		case 13: goto tr205;
		case 109: goto st190;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st190:
	if ( ++p == pe )
		goto _test_eof190;
case 190:
	switch( (*p) ) {
		case 13: goto tr205;
		case 112: goto st191;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st191:
	if ( ++p == pe )
		goto _test_eof191;
case 191:
	switch( (*p) ) {
		case 13: goto tr205;
		case 114: goto st192;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st192:
	if ( ++p == pe )
		goto _test_eof192;
case 192:
	switch( (*p) ) {
		case 13: goto tr205;
		case 101: goto st193;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st193:
	if ( ++p == pe )
		goto _test_eof193;
case 193:
	switch( (*p) ) {
		case 13: goto tr205;
		case 115: goto st194;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st194:
	if ( ++p == pe )
		goto _test_eof194;
case 194:
	switch( (*p) ) {
		case 13: goto tr205;
		case 115: goto st195;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st195:
	if ( ++p == pe )
		goto _test_eof195;
case 195:
	switch( (*p) ) {
		case 9: goto tr274;
		case 13: goto tr262;
		case 32: goto tr274;
		case 44: goto tr263;
		case 59: goto st172;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st150;
tr225:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st196;
st196:
	if ( ++p == pe )
		goto _test_eof196;
case 196:
#line 5062 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr205;
		case 101: goto st197;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st197:
	if ( ++p == pe )
		goto _test_eof197;
case 197:
	switch( (*p) ) {
		case 13: goto tr205;
		case 102: goto st198;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st198:
	if ( ++p == pe )
		goto _test_eof198;
case 198:
	switch( (*p) ) {
		case 13: goto tr205;
		case 108: goto st199;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st199:
	if ( ++p == pe )
		goto _test_eof199;
case 199:
	switch( (*p) ) {
		case 13: goto tr205;
		case 97: goto st200;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st200:
	if ( ++p == pe )
		goto _test_eof200;
case 200:
	switch( (*p) ) {
		case 13: goto tr205;
		case 116: goto st201;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st201:
	if ( ++p == pe )
		goto _test_eof201;
case 201:
	switch( (*p) ) {
		case 13: goto tr205;
		case 101: goto st202;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st202:
	if ( ++p == pe )
		goto _test_eof202;
case 202:
	switch( (*p) ) {
		case 9: goto tr281;
		case 13: goto tr282;
		case 32: goto tr281;
		case 44: goto tr283;
		case 59: goto tr284;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st150;
tr226:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st203;
st203:
	if ( ++p == pe )
		goto _test_eof203;
case 203:
#line 5175 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr205;
		case 122: goto st204;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st204:
	if ( ++p == pe )
		goto _test_eof204;
case 204:
	switch( (*p) ) {
		case 13: goto tr205;
		case 105: goto st205;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st205:
	if ( ++p == pe )
		goto _test_eof205;
case 205:
	switch( (*p) ) {
		case 13: goto tr205;
		case 112: goto st206;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st206:
	if ( ++p == pe )
		goto _test_eof206;
case 206:
	switch( (*p) ) {
		case 9: goto tr288;
		case 13: goto tr289;
		case 32: goto tr288;
		case 44: goto tr290;
		case 59: goto tr291;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st150;
tr227:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st207;
st207:
	if ( ++p == pe )
		goto _test_eof207;
case 207:
#line 5243 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr205;
		case 100: goto st208;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st208:
	if ( ++p == pe )
		goto _test_eof208;
case 208:
	switch( (*p) ) {
		case 13: goto tr205;
		case 101: goto st209;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st209:
	if ( ++p == pe )
		goto _test_eof209;
case 209:
	switch( (*p) ) {
		case 13: goto tr205;
		case 110: goto st210;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st210:
	if ( ++p == pe )
		goto _test_eof210;
case 210:
	switch( (*p) ) {
		case 13: goto tr205;
		case 116: goto st211;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st211:
	if ( ++p == pe )
		goto _test_eof211;
case 211:
	switch( (*p) ) {
		case 13: goto tr205;
		case 105: goto st212;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st212:
	if ( ++p == pe )
		goto _test_eof212;
case 212:
	switch( (*p) ) {
		case 13: goto tr205;
		case 116: goto st213;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
st213:
	if ( ++p == pe )
		goto _test_eof213;
case 213:
	switch( (*p) ) {
		case 13: goto tr205;
		case 121: goto st195;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st150;
tr196:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st214;
st214:
	if ( ++p == pe )
		goto _test_eof214;
case 214:
#line 5356 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 79: goto st215;
		case 111: goto st215;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st215:
	if ( ++p == pe )
		goto _test_eof215;
case 215:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 78: goto st216;
		case 110: goto st216;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st216:
	if ( ++p == pe )
		goto _test_eof216;
case 216:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 84: goto st217;
		case 116: goto st217;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st217:
	if ( ++p == pe )
		goto _test_eof217;
case 217:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 69: goto st218;
		case 101: goto st218;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st218:
	if ( ++p == pe )
		goto _test_eof218;
case 218:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 78: goto st219;
		case 110: goto st219;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st219:
	if ( ++p == pe )
		goto _test_eof219;
case 219:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 84: goto st220;
		case 116: goto st220;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st220:
	if ( ++p == pe )
		goto _test_eof220;
case 220:
	switch( (*p) ) {
		case 33: goto st148;
		case 45: goto st221;
		case 46: goto st148;
		case 58: goto tr200;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 48 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else if ( (*p) >= 65 )
			goto st148;
	} else
		goto st148;
	goto st0;
st221:
	if ( ++p == pe )
		goto _test_eof221;
case 221:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 69: goto st222;
		case 76: goto st254;
		case 101: goto st222;
		case 108: goto st254;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st222:
	if ( ++p == pe )
		goto _test_eof222;
case 222:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 78: goto st223;
		case 110: goto st223;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st223:
	if ( ++p == pe )
		goto _test_eof223;
case 223:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 67: goto st224;
		case 99: goto st224;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st224:
	if ( ++p == pe )
		goto _test_eof224;
case 224:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 79: goto st225;
		case 111: goto st225;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st225:
	if ( ++p == pe )
		goto _test_eof225;
case 225:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 68: goto st226;
		case 100: goto st226;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st226:
	if ( ++p == pe )
		goto _test_eof226;
case 226:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 73: goto st227;
		case 105: goto st227;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st227:
	if ( ++p == pe )
		goto _test_eof227;
case 227:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 78: goto st228;
		case 110: goto st228;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st228:
	if ( ++p == pe )
		goto _test_eof228;
case 228:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 71: goto st229;
		case 103: goto st229;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st229:
	if ( ++p == pe )
		goto _test_eof229;
case 229:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr314;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
tr314:
#line 20 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string value;
            SAVE(value);
            message->headers.add(value, {});
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st230;
st230:
	if ( ++p == pe )
		goto _test_eof230;
case 230:
#line 5849 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st230;
		case 13: goto tr203;
		case 32: goto st230;
		case 98: goto tr317;
		case 100: goto tr318;
		case 103: goto tr319;
		case 105: goto tr320;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto tr315;
tr315:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st231;
st231:
	if ( ++p == pe )
		goto _test_eof231;
case 231:
#line 5874 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr322;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
tr317:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st232;
st232:
	if ( ++p == pe )
		goto _test_eof232;
case 232:
#line 5896 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr322;
		case 114: goto st233;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
st233:
	if ( ++p == pe )
		goto _test_eof233;
case 233:
	switch( (*p) ) {
		case 9: goto tr324;
		case 13: goto tr325;
		case 32: goto tr324;
		case 44: goto tr326;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st231;
tr324:
#line 83 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::BROTLI; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 234; goto _out;}
            }
        }
    }
	goto st234;
tr340:
#line 72 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::DEFLATE; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 234; goto _out;}
            }
        }
    }
	goto st234;
tr346:
#line 61 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::GZIP; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 234; goto _out;}
            }
        }
    }
	goto st234;
st234:
	if ( ++p == pe )
		goto _test_eof234;
case 234:
#line 5965 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st234;
		case 13: goto tr328;
		case 32: goto st234;
		case 44: goto st235;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st231;
tr326:
#line 83 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::BROTLI; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 235; goto _out;}
            }
        }
    }
	goto st235;
tr342:
#line 72 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::DEFLATE; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 235; goto _out;}
            }
        }
    }
	goto st235;
tr348:
#line 61 "src/panda/protocol/http/MessageParser.rl"
	{
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::GZIP; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                {p++; cs = 235; goto _out;}
            }
        }
    }
	goto st235;
st235:
	if ( ++p == pe )
		goto _test_eof235;
case 235:
#line 6019 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st235;
		case 13: goto tr322;
		case 32: goto st235;
		case 98: goto st232;
		case 100: goto st236;
		case 103: goto st243;
		case 105: goto st247;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st231;
tr318:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st236;
st236:
	if ( ++p == pe )
		goto _test_eof236;
case 236:
#line 6044 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr322;
		case 101: goto st237;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
st237:
	if ( ++p == pe )
		goto _test_eof237;
case 237:
	switch( (*p) ) {
		case 13: goto tr322;
		case 102: goto st238;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
st238:
	if ( ++p == pe )
		goto _test_eof238;
case 238:
	switch( (*p) ) {
		case 13: goto tr322;
		case 108: goto st239;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
st239:
	if ( ++p == pe )
		goto _test_eof239;
case 239:
	switch( (*p) ) {
		case 13: goto tr322;
		case 97: goto st240;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
st240:
	if ( ++p == pe )
		goto _test_eof240;
case 240:
	switch( (*p) ) {
		case 13: goto tr322;
		case 116: goto st241;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
st241:
	if ( ++p == pe )
		goto _test_eof241;
case 241:
	switch( (*p) ) {
		case 13: goto tr322;
		case 101: goto st242;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
st242:
	if ( ++p == pe )
		goto _test_eof242;
case 242:
	switch( (*p) ) {
		case 9: goto tr340;
		case 13: goto tr341;
		case 32: goto tr340;
		case 44: goto tr342;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st231;
tr319:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st243;
st243:
	if ( ++p == pe )
		goto _test_eof243;
case 243:
#line 6156 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr322;
		case 122: goto st244;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
st244:
	if ( ++p == pe )
		goto _test_eof244;
case 244:
	switch( (*p) ) {
		case 13: goto tr322;
		case 105: goto st245;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
st245:
	if ( ++p == pe )
		goto _test_eof245;
case 245:
	switch( (*p) ) {
		case 13: goto tr322;
		case 112: goto st246;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
st246:
	if ( ++p == pe )
		goto _test_eof246;
case 246:
	switch( (*p) ) {
		case 9: goto tr346;
		case 13: goto tr347;
		case 32: goto tr346;
		case 44: goto tr348;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st231;
tr320:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st247;
st247:
	if ( ++p == pe )
		goto _test_eof247;
case 247:
#line 6223 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr322;
		case 100: goto st248;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
st248:
	if ( ++p == pe )
		goto _test_eof248;
case 248:
	switch( (*p) ) {
		case 13: goto tr322;
		case 101: goto st249;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
st249:
	if ( ++p == pe )
		goto _test_eof249;
case 249:
	switch( (*p) ) {
		case 13: goto tr322;
		case 110: goto st250;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
st250:
	if ( ++p == pe )
		goto _test_eof250;
case 250:
	switch( (*p) ) {
		case 13: goto tr322;
		case 116: goto st251;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
st251:
	if ( ++p == pe )
		goto _test_eof251;
case 251:
	switch( (*p) ) {
		case 13: goto tr322;
		case 105: goto st252;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
st252:
	if ( ++p == pe )
		goto _test_eof252;
case 252:
	switch( (*p) ) {
		case 13: goto tr322;
		case 116: goto st253;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
st253:
	if ( ++p == pe )
		goto _test_eof253;
case 253:
	switch( (*p) ) {
		case 13: goto tr322;
		case 121: goto st234;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st231;
st254:
	if ( ++p == pe )
		goto _test_eof254;
case 254:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 69: goto st255;
		case 101: goto st255;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st255:
	if ( ++p == pe )
		goto _test_eof255;
case 255:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 78: goto st256;
		case 110: goto st256;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st256:
	if ( ++p == pe )
		goto _test_eof256;
case 256:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 71: goto st257;
		case 103: goto st257;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st257:
	if ( ++p == pe )
		goto _test_eof257;
case 257:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 84: goto st258;
		case 116: goto st258;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st258:
	if ( ++p == pe )
		goto _test_eof258;
case 258:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 72: goto st259;
		case 104: goto st259;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st259:
	if ( ++p == pe )
		goto _test_eof259;
case 259:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr360;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
tr360:
#line 20 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string value;
            SAVE(value);
            message->headers.add(value, {});
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st260;
st260:
	if ( ++p == pe )
		goto _test_eof260;
case 260:
#line 6522 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st260;
		case 13: goto tr203;
		case 32: goto st260;
		case 127: goto st0;
	}
	if ( (*p) > 31 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr362;
	} else if ( (*p) >= 0 )
		goto st0;
	goto tr201;
tr362:
#line 38 "src/panda/protocol/http/MessageParser.rl"
	{
        if (has_content_length) {
            cs = message_parser_error;
            set_error(errc::multiple_content_length);
            {p++; cs = 261; goto _out;}
        }
        has_content_length = true;
    }
#line 145 "src/panda/protocol/http/MessageParser.rl"
	{ADD_DIGIT(content_length)}
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st261;
tr363:
#line 145 "src/panda/protocol/http/MessageParser.rl"
	{ADD_DIGIT(content_length)}
	goto st261;
st261:
	if ( ++p == pe )
		goto _test_eof261;
case 261:
#line 6561 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr205;
		case 127: goto st0;
	}
	if ( (*p) < 10 ) {
		if ( 0 <= (*p) && (*p) <= 8 )
			goto st0;
	} else if ( (*p) > 31 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr363;
	} else
		goto st0;
	goto st150;
tr197:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st262;
st262:
	if ( ++p == pe )
		goto _test_eof262;
case 262:
#line 6586 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 82: goto st263;
		case 114: goto st263;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st263:
	if ( ++p == pe )
		goto _test_eof263;
case 263:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 65: goto st264;
		case 97: goto st264;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 66 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st264:
	if ( ++p == pe )
		goto _test_eof264;
case 264:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 78: goto st265;
		case 110: goto st265;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st265:
	if ( ++p == pe )
		goto _test_eof265;
case 265:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 83: goto st266;
		case 115: goto st266;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st266:
	if ( ++p == pe )
		goto _test_eof266;
case 266:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 70: goto st267;
		case 102: goto st267;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st267:
	if ( ++p == pe )
		goto _test_eof267;
case 267:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 69: goto st268;
		case 101: goto st268;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st268:
	if ( ++p == pe )
		goto _test_eof268;
case 268:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 82: goto st269;
		case 114: goto st269;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st269:
	if ( ++p == pe )
		goto _test_eof269;
case 269:
	switch( (*p) ) {
		case 33: goto st148;
		case 45: goto st270;
		case 46: goto st148;
		case 58: goto tr200;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 48 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else if ( (*p) >= 65 )
			goto st148;
	} else
		goto st148;
	goto st0;
st270:
	if ( ++p == pe )
		goto _test_eof270;
case 270:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 69: goto st271;
		case 101: goto st271;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st271:
	if ( ++p == pe )
		goto _test_eof271;
case 271:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 78: goto st272;
		case 110: goto st272;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st272:
	if ( ++p == pe )
		goto _test_eof272;
case 272:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 67: goto st273;
		case 99: goto st273;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st273:
	if ( ++p == pe )
		goto _test_eof273;
case 273:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 79: goto st274;
		case 111: goto st274;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st274:
	if ( ++p == pe )
		goto _test_eof274;
case 274:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 68: goto st275;
		case 100: goto st275;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st275:
	if ( ++p == pe )
		goto _test_eof275;
case 275:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 73: goto st276;
		case 105: goto st276;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st276:
	if ( ++p == pe )
		goto _test_eof276;
case 276:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 78: goto st277;
		case 110: goto st277;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st277:
	if ( ++p == pe )
		goto _test_eof277;
case 277:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr200;
		case 71: goto st278;
		case 103: goto st278;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
st278:
	if ( ++p == pe )
		goto _test_eof278;
case 278:
	switch( (*p) ) {
		case 33: goto st148;
		case 58: goto tr380;
		case 124: goto st148;
		case 126: goto st148;
	}
	if ( (*p) < 45 ) {
		if ( (*p) > 39 ) {
			if ( 42 <= (*p) && (*p) <= 43 )
				goto st148;
		} else if ( (*p) >= 35 )
			goto st148;
	} else if ( (*p) > 46 ) {
		if ( (*p) < 65 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto st148;
		} else if ( (*p) > 90 ) {
			if ( 94 <= (*p) && (*p) <= 122 )
				goto st148;
		} else
			goto st148;
	} else
		goto st148;
	goto st0;
tr380:
#line 20 "src/panda/protocol/http/MessageParser.rl"
	{
        if (!headers_finished) {
            string value;
            SAVE(value);
            message->headers.add(value, {});
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
#line 12 "src/panda/protocol/http/MessageParser.rl"
	{
        marked = false;
    }
	goto st279;
st279:
	if ( ++p == pe )
		goto _test_eof279;
case 279:
#line 7107 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st279;
		case 13: goto tr203;
		case 32: goto st279;
		case 67: goto tr383;
		case 99: goto tr383;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto tr381;
tr381:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st280;
st280:
	if ( ++p == pe )
		goto _test_eof280;
case 280:
#line 7130 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr385;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st280;
tr383:
#line 7 "src/panda/protocol/http/MessageParser.rl"
	{
        mark   = p - ps;
        marked = true;
    }
	goto st281;
st281:
	if ( ++p == pe )
		goto _test_eof281;
case 281:
#line 7152 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 13: goto tr385;
		case 72: goto st282;
		case 104: goto st282;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st280;
st282:
	if ( ++p == pe )
		goto _test_eof282;
case 282:
	switch( (*p) ) {
		case 13: goto tr385;
		case 85: goto st283;
		case 117: goto st283;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st280;
st283:
	if ( ++p == pe )
		goto _test_eof283;
case 283:
	switch( (*p) ) {
		case 13: goto tr385;
		case 78: goto st284;
		case 110: goto st284;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st280;
st284:
	if ( ++p == pe )
		goto _test_eof284;
case 284:
	switch( (*p) ) {
		case 13: goto tr385;
		case 75: goto st285;
		case 107: goto st285;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st280;
st285:
	if ( ++p == pe )
		goto _test_eof285;
case 285:
	switch( (*p) ) {
		case 13: goto tr385;
		case 69: goto st286;
		case 101: goto st286;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st280;
st286:
	if ( ++p == pe )
		goto _test_eof286;
case 286:
	switch( (*p) ) {
		case 13: goto tr385;
		case 68: goto st287;
		case 100: goto st287;
		case 127: goto st0;
	}
	if ( (*p) > 8 ) {
		if ( 10 <= (*p) && (*p) <= 31 )
			goto st0;
	} else if ( (*p) >= 0 )
		goto st0;
	goto st280;
st287:
	if ( ++p == pe )
		goto _test_eof287;
case 287:
	switch( (*p) ) {
		case 9: goto tr392;
		case 13: goto tr393;
		case 32: goto tr392;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st280;
tr392:
#line 146 "src/panda/protocol/http/MessageParser.rl"
	{message->chunked = true;                     }
	goto st288;
st288:
	if ( ++p == pe )
		goto _test_eof288;
case 288:
#line 7266 "src/panda/protocol/http/MessageParser.cc"
	switch( (*p) ) {
		case 9: goto st288;
		case 13: goto tr205;
		case 32: goto st288;
		case 127: goto st0;
	}
	if ( 0 <= (*p) && (*p) <= 31 )
		goto st0;
	goto st280;
st289:
	if ( ++p == pe )
		goto _test_eof289;
case 289:
	if ( (*p) == 13 )
		goto tr395;
	goto st0;
st290:
	if ( ++p == pe )
		goto _test_eof290;
case 290:
	if ( (*p) == 69 )
		goto st291;
	goto st0;
st291:
	if ( ++p == pe )
		goto _test_eof291;
case 291:
	if ( (*p) == 76 )
		goto st292;
	goto st0;
st292:
	if ( ++p == pe )
		goto _test_eof292;
case 292:
	if ( (*p) == 69 )
		goto st293;
	goto st0;
st293:
	if ( ++p == pe )
		goto _test_eof293;
case 293:
	if ( (*p) == 84 )
		goto st294;
	goto st0;
st294:
	if ( ++p == pe )
		goto _test_eof294;
case 294:
	if ( (*p) == 69 )
		goto st295;
	goto st0;
st295:
	if ( ++p == pe )
		goto _test_eof295;
case 295:
	if ( (*p) == 32 )
		goto tr401;
	goto st0;
st296:
	if ( ++p == pe )
		goto _test_eof296;
case 296:
	if ( (*p) == 69 )
		goto st297;
	goto st0;
st297:
	if ( ++p == pe )
		goto _test_eof297;
case 297:
	if ( (*p) == 84 )
		goto st298;
	goto st0;
st298:
	if ( ++p == pe )
		goto _test_eof298;
case 298:
	if ( (*p) == 32 )
		goto tr404;
	goto st0;
st299:
	if ( ++p == pe )
		goto _test_eof299;
case 299:
	if ( (*p) == 69 )
		goto st300;
	goto st0;
st300:
	if ( ++p == pe )
		goto _test_eof300;
case 300:
	if ( (*p) == 65 )
		goto st301;
	goto st0;
st301:
	if ( ++p == pe )
		goto _test_eof301;
case 301:
	if ( (*p) == 68 )
		goto st302;
	goto st0;
st302:
	if ( ++p == pe )
		goto _test_eof302;
case 302:
	if ( (*p) == 32 )
		goto tr408;
	goto st0;
st303:
	if ( ++p == pe )
		goto _test_eof303;
case 303:
	if ( (*p) == 80 )
		goto st304;
	goto st0;
st304:
	if ( ++p == pe )
		goto _test_eof304;
case 304:
	if ( (*p) == 84 )
		goto st305;
	goto st0;
st305:
	if ( ++p == pe )
		goto _test_eof305;
case 305:
	if ( (*p) == 73 )
		goto st306;
	goto st0;
st306:
	if ( ++p == pe )
		goto _test_eof306;
case 306:
	if ( (*p) == 79 )
		goto st307;
	goto st0;
st307:
	if ( ++p == pe )
		goto _test_eof307;
case 307:
	if ( (*p) == 78 )
		goto st308;
	goto st0;
st308:
	if ( ++p == pe )
		goto _test_eof308;
case 308:
	if ( (*p) == 83 )
		goto st309;
	goto st0;
st309:
	if ( ++p == pe )
		goto _test_eof309;
case 309:
	if ( (*p) == 32 )
		goto tr415;
	goto st0;
st310:
	if ( ++p == pe )
		goto _test_eof310;
case 310:
	switch( (*p) ) {
		case 79: goto st311;
		case 85: goto st314;
	}
	goto st0;
st311:
	if ( ++p == pe )
		goto _test_eof311;
case 311:
	if ( (*p) == 83 )
		goto st312;
	goto st0;
st312:
	if ( ++p == pe )
		goto _test_eof312;
case 312:
	if ( (*p) == 84 )
		goto st313;
	goto st0;
st313:
	if ( ++p == pe )
		goto _test_eof313;
case 313:
	if ( (*p) == 32 )
		goto tr420;
	goto st0;
st314:
	if ( ++p == pe )
		goto _test_eof314;
case 314:
	if ( (*p) == 84 )
		goto st315;
	goto st0;
st315:
	if ( ++p == pe )
		goto _test_eof315;
case 315:
	if ( (*p) == 32 )
		goto tr422;
	goto st0;
st316:
	if ( ++p == pe )
		goto _test_eof316;
case 316:
	if ( (*p) == 82 )
		goto st317;
	goto st0;
st317:
	if ( ++p == pe )
		goto _test_eof317;
case 317:
	if ( (*p) == 65 )
		goto st318;
	goto st0;
st318:
	if ( ++p == pe )
		goto _test_eof318;
case 318:
	if ( (*p) == 67 )
		goto st319;
	goto st0;
st319:
	if ( ++p == pe )
		goto _test_eof319;
case 319:
	if ( (*p) == 69 )
		goto st320;
	goto st0;
st320:
	if ( ++p == pe )
		goto _test_eof320;
case 320:
	if ( (*p) == 32 )
		goto tr427;
	goto st0;
	}
	_test_eof2: cs = 2; goto _test_eof; 
	_test_eof3: cs = 3; goto _test_eof; 
	_test_eof4: cs = 4; goto _test_eof; 
	_test_eof5: cs = 5; goto _test_eof; 
	_test_eof6: cs = 6; goto _test_eof; 
	_test_eof7: cs = 7; goto _test_eof; 
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
	_test_eof321: cs = 321; goto _test_eof; 
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
	_test_eof76: cs = 76; goto _test_eof; 
	_test_eof77: cs = 77; goto _test_eof; 
	_test_eof78: cs = 78; goto _test_eof; 
	_test_eof79: cs = 79; goto _test_eof; 
	_test_eof80: cs = 80; goto _test_eof; 
	_test_eof81: cs = 81; goto _test_eof; 
	_test_eof82: cs = 82; goto _test_eof; 
	_test_eof83: cs = 83; goto _test_eof; 
	_test_eof84: cs = 84; goto _test_eof; 
	_test_eof85: cs = 85; goto _test_eof; 
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
	_test_eof97: cs = 97; goto _test_eof; 
	_test_eof99: cs = 99; goto _test_eof; 
	_test_eof100: cs = 100; goto _test_eof; 
	_test_eof322: cs = 322; goto _test_eof; 
	_test_eof101: cs = 101; goto _test_eof; 
	_test_eof102: cs = 102; goto _test_eof; 
	_test_eof103: cs = 103; goto _test_eof; 
	_test_eof104: cs = 104; goto _test_eof; 
	_test_eof105: cs = 105; goto _test_eof; 
	_test_eof106: cs = 106; goto _test_eof; 
	_test_eof107: cs = 107; goto _test_eof; 
	_test_eof109: cs = 109; goto _test_eof; 
	_test_eof110: cs = 110; goto _test_eof; 
	_test_eof111: cs = 111; goto _test_eof; 
	_test_eof112: cs = 112; goto _test_eof; 
	_test_eof323: cs = 323; goto _test_eof; 
	_test_eof113: cs = 113; goto _test_eof; 
	_test_eof114: cs = 114; goto _test_eof; 
	_test_eof115: cs = 115; goto _test_eof; 
	_test_eof116: cs = 116; goto _test_eof; 
	_test_eof117: cs = 117; goto _test_eof; 
	_test_eof118: cs = 118; goto _test_eof; 
	_test_eof119: cs = 119; goto _test_eof; 
	_test_eof120: cs = 120; goto _test_eof; 
	_test_eof121: cs = 121; goto _test_eof; 
	_test_eof324: cs = 324; goto _test_eof; 
	_test_eof122: cs = 122; goto _test_eof; 
	_test_eof123: cs = 123; goto _test_eof; 
	_test_eof124: cs = 124; goto _test_eof; 
	_test_eof125: cs = 125; goto _test_eof; 
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
	_test_eof325: cs = 325; goto _test_eof; 
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
	_test_eof201: cs = 201; goto _test_eof; 
	_test_eof202: cs = 202; goto _test_eof; 
	_test_eof203: cs = 203; goto _test_eof; 
	_test_eof204: cs = 204; goto _test_eof; 
	_test_eof205: cs = 205; goto _test_eof; 
	_test_eof206: cs = 206; goto _test_eof; 
	_test_eof207: cs = 207; goto _test_eof; 
	_test_eof208: cs = 208; goto _test_eof; 
	_test_eof209: cs = 209; goto _test_eof; 
	_test_eof210: cs = 210; goto _test_eof; 
	_test_eof211: cs = 211; goto _test_eof; 
	_test_eof212: cs = 212; goto _test_eof; 
	_test_eof213: cs = 213; goto _test_eof; 
	_test_eof214: cs = 214; goto _test_eof; 
	_test_eof215: cs = 215; goto _test_eof; 
	_test_eof216: cs = 216; goto _test_eof; 
	_test_eof217: cs = 217; goto _test_eof; 
	_test_eof218: cs = 218; goto _test_eof; 
	_test_eof219: cs = 219; goto _test_eof; 
	_test_eof220: cs = 220; goto _test_eof; 
	_test_eof221: cs = 221; goto _test_eof; 
	_test_eof222: cs = 222; goto _test_eof; 
	_test_eof223: cs = 223; goto _test_eof; 
	_test_eof224: cs = 224; goto _test_eof; 
	_test_eof225: cs = 225; goto _test_eof; 
	_test_eof226: cs = 226; goto _test_eof; 
	_test_eof227: cs = 227; goto _test_eof; 
	_test_eof228: cs = 228; goto _test_eof; 
	_test_eof229: cs = 229; goto _test_eof; 
	_test_eof230: cs = 230; goto _test_eof; 
	_test_eof231: cs = 231; goto _test_eof; 
	_test_eof232: cs = 232; goto _test_eof; 
	_test_eof233: cs = 233; goto _test_eof; 
	_test_eof234: cs = 234; goto _test_eof; 
	_test_eof235: cs = 235; goto _test_eof; 
	_test_eof236: cs = 236; goto _test_eof; 
	_test_eof237: cs = 237; goto _test_eof; 
	_test_eof238: cs = 238; goto _test_eof; 
	_test_eof239: cs = 239; goto _test_eof; 
	_test_eof240: cs = 240; goto _test_eof; 
	_test_eof241: cs = 241; goto _test_eof; 
	_test_eof242: cs = 242; goto _test_eof; 
	_test_eof243: cs = 243; goto _test_eof; 
	_test_eof244: cs = 244; goto _test_eof; 
	_test_eof245: cs = 245; goto _test_eof; 
	_test_eof246: cs = 246; goto _test_eof; 
	_test_eof247: cs = 247; goto _test_eof; 
	_test_eof248: cs = 248; goto _test_eof; 
	_test_eof249: cs = 249; goto _test_eof; 
	_test_eof250: cs = 250; goto _test_eof; 
	_test_eof251: cs = 251; goto _test_eof; 
	_test_eof252: cs = 252; goto _test_eof; 
	_test_eof253: cs = 253; goto _test_eof; 
	_test_eof254: cs = 254; goto _test_eof; 
	_test_eof255: cs = 255; goto _test_eof; 
	_test_eof256: cs = 256; goto _test_eof; 
	_test_eof257: cs = 257; goto _test_eof; 
	_test_eof258: cs = 258; goto _test_eof; 
	_test_eof259: cs = 259; goto _test_eof; 
	_test_eof260: cs = 260; goto _test_eof; 
	_test_eof261: cs = 261; goto _test_eof; 
	_test_eof262: cs = 262; goto _test_eof; 
	_test_eof263: cs = 263; goto _test_eof; 
	_test_eof264: cs = 264; goto _test_eof; 
	_test_eof265: cs = 265; goto _test_eof; 
	_test_eof266: cs = 266; goto _test_eof; 
	_test_eof267: cs = 267; goto _test_eof; 
	_test_eof268: cs = 268; goto _test_eof; 
	_test_eof269: cs = 269; goto _test_eof; 
	_test_eof270: cs = 270; goto _test_eof; 
	_test_eof271: cs = 271; goto _test_eof; 
	_test_eof272: cs = 272; goto _test_eof; 
	_test_eof273: cs = 273; goto _test_eof; 
	_test_eof274: cs = 274; goto _test_eof; 
	_test_eof275: cs = 275; goto _test_eof; 
	_test_eof276: cs = 276; goto _test_eof; 
	_test_eof277: cs = 277; goto _test_eof; 
	_test_eof278: cs = 278; goto _test_eof; 
	_test_eof279: cs = 279; goto _test_eof; 
	_test_eof280: cs = 280; goto _test_eof; 
	_test_eof281: cs = 281; goto _test_eof; 
	_test_eof282: cs = 282; goto _test_eof; 
	_test_eof283: cs = 283; goto _test_eof; 
	_test_eof284: cs = 284; goto _test_eof; 
	_test_eof285: cs = 285; goto _test_eof; 
	_test_eof286: cs = 286; goto _test_eof; 
	_test_eof287: cs = 287; goto _test_eof; 
	_test_eof288: cs = 288; goto _test_eof; 
	_test_eof289: cs = 289; goto _test_eof; 
	_test_eof290: cs = 290; goto _test_eof; 
	_test_eof291: cs = 291; goto _test_eof; 
	_test_eof292: cs = 292; goto _test_eof; 
	_test_eof293: cs = 293; goto _test_eof; 
	_test_eof294: cs = 294; goto _test_eof; 
	_test_eof295: cs = 295; goto _test_eof; 
	_test_eof296: cs = 296; goto _test_eof; 
	_test_eof297: cs = 297; goto _test_eof; 
	_test_eof298: cs = 298; goto _test_eof; 
	_test_eof299: cs = 299; goto _test_eof; 
	_test_eof300: cs = 300; goto _test_eof; 
	_test_eof301: cs = 301; goto _test_eof; 
	_test_eof302: cs = 302; goto _test_eof; 
	_test_eof303: cs = 303; goto _test_eof; 
	_test_eof304: cs = 304; goto _test_eof; 
	_test_eof305: cs = 305; goto _test_eof; 
	_test_eof306: cs = 306; goto _test_eof; 
	_test_eof307: cs = 307; goto _test_eof; 
	_test_eof308: cs = 308; goto _test_eof; 
	_test_eof309: cs = 309; goto _test_eof; 
	_test_eof310: cs = 310; goto _test_eof; 
	_test_eof311: cs = 311; goto _test_eof; 
	_test_eof312: cs = 312; goto _test_eof; 
	_test_eof313: cs = 313; goto _test_eof; 
	_test_eof314: cs = 314; goto _test_eof; 
	_test_eof315: cs = 315; goto _test_eof; 
	_test_eof316: cs = 316; goto _test_eof; 
	_test_eof317: cs = 317; goto _test_eof; 
	_test_eof318: cs = 318; goto _test_eof; 
	_test_eof319: cs = 319; goto _test_eof; 
	_test_eof320: cs = 320; goto _test_eof; 

	_test_eof: {}
	_out: {}
	}

#line 222 "src/panda/protocol/http/MessageParser.rl"
    return p - ps;
}

#endif

}}}
