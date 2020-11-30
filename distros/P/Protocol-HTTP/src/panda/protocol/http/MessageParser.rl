#include "MessageParser.h"

%%{
    machine message_parser;
    include rules "Rules.rl";
    
    action mark {
        mark   = fpc - ps;
        marked = true;
    }

    action unmark {
        marked = false;
    }

    action done {
        fbreak;
    }
    
    action header_name {
        if (!headers_finished) {
            string value;
            SAVE(value);
            message->headers.add(value, {});
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
    
    action header_value {
        if (!headers_finished) {
            string& value = message->headers.fields.back().value;
            SAVE(value);
            if (value && value.back() <= 0x20) value.offset(0, value.find_last_not_of(" \t") + 1);
        }
        else {} // trailing header after chunks, currently we just ignore them
    }
    
    action content_length_start {
        if (has_content_length) {
            cs = message_parser_error;
            set_error(errc::multiple_content_length);
            fbreak;
        }
        has_content_length = true;
    }

    action transfer_encoding_err {
        cs = message_parser_error;
        set_error(errc::unsupported_transfer_encoding);
        fbreak;
    }

    action unknown_content_encoding {
        if (uncompress_content) {
            cs = message_parser_error;
            set_error(errc::unsupported_compression);
            fbreak;
        }
    }

    action content_gziped {
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::GZIP; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                fbreak;
            }
        }
    }

    action content_deflated {
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::DEFLATE; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                fbreak;
            }
        }
    }

    action content_brotlied {
        if (uncompress_content) {
            if (message->compression.type == Compression::IDENTITY) { message->compression.type = Compression::BROTLI; }
            else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                fbreak;
            }
        }
    }

    action attach_compressor {
        if (message->compression.type != Compression::IDENTITY) {
            auto it = compression::instantiate(message->compression.type);
            if (it) {
                it->prepare_uncompress(max_body_size);
                compressor = std::move(it);
            } else {
                cs = message_parser_error;
                set_error(errc::unsupported_compression);
                fbreak;
            }
        }
    }

    action request_target {
        string target;
        SAVE(target);
        request->uri = new URI(target);
    }

    action push_compression {
        if (compr) {
            request->allow_compression(static_cast<Compression::Type>(compr));
            compr = 0;
        }
    }
    
    http_version  = "HTTP/1." (("0" %{message->http_version = 10;}) | ("1" %{message->http_version = 11;}));
    
    ################################## ACCEPT-ENCODING ################################
    encoding_gzip     = /gzip/     %{ compr = Compression::GZIP;     };
    encoding_deflate  = /deflate/  %{ compr = Compression::DEFLATE;  };
    encoding_br       = /br/       %{ compr = Compression::BROTLI;  };
    encoding_identity = /identity/;
    encoding_compress = /compress/;
    encoding_any      = "*" %{compr = Compression::GZIP | Compression::DEFLATE; };
    some_enconding    = encoding_identity | encoding_deflate | encoding_gzip | encoding_compress | encoding_br | encoding_any;
    q_not             = "0" ("." ("0"){,3})? %{ compr = 0; };
    q_any             = ("1" ("." ("0"){,3})?) | ("0" ("." digit{1,3})? );
    q_value           = q_any | q_not;
    encoding_value    = some_enconding (OWS ";" OWS "q=" q_value )? %push_compression;
    accept_encoding   = /Accept-Encoding/i ":" OWS encoding_value ( OWS "," OWS encoding_value )*;

    ################################## HEADERS ########################################
    field_name        = token >mark %header_name %unmark;
    field_vchar       = VCHAR | WSP | obs_text;
    field_value       = field_vchar* >mark %header_value %unmark;
    header_field      = field_name ":" OWS <: field_value;
    content_length    = /Content-Length/i ":" OWS digit+ >content_length_start ${ADD_DIGIT(content_length)} OWS;
    te_chunked        = /chunked/i %{message->chunked = true;                     };
    te_value          = te_chunked OWS;
    transfer_encoding = /Transfer-Encoding/i ":" OWS <: (te_value| (field_vchar+ - te_value) %transfer_encoding_err);
    ce_identity       = /identity/;
    ce_gzip           = /gzip/     %content_gziped;
    ce_deflate        = /deflate/  %content_deflated;
    ce_br             = /br/       %content_brotlied;
    ce_compression    = ce_identity | ce_gzip | ce_deflate | ce_br;
    ce_value          = (ce_compression (OWS "," OWS ce_compression)*) OWS;
    content_encoding  = /Content-Encoding/i ":" OWS <: (ce_value | (field_vchar+ - ce_value) %unknown_content_encoding) %attach_compressor;
    header            = content_length | transfer_encoding | content_encoding | header_field;

    ################################## CHUNKS ########################################
    chunk_size      = xdigit+ >{chunk_length = 0;} ${ADD_XDIGIT(chunk_length)};
    chunk_ext_name  = token;
    chunk_ext_val   = token | quoted_string;
    chunk_extension = ( ";" chunk_ext_name ("=" chunk_ext_val)? )+;
    _first_chunk    = chunk_size chunk_extension? CRLF;
    first_chunk    := _first_chunk @done;
    chunk          := CRLF _first_chunk @done;
    chunk_trailer  := (header_field CRLF)* CRLF @done;
    
    ################################## REQUEST ########################################
    method = "OPTIONS" %{request->method_raw(Request::Method::Options); }
           | "GET"     %{request->method_raw(Request::Method::Get);     }
           | "HEAD"    %{request->method_raw(Request::Method::Head);    }
           | "POST"    %{request->method_raw(Request::Method::Post);    }
           | "PUT"     %{request->method_raw(Request::Method::Put);     }
           | "DELETE"  %{request->method_raw(Request::Method::Delete);  }
           | "TRACE"   %{request->method_raw(Request::Method::Trace);   }
           | "CONNECT" %{request->method_raw(Request::Method::Connect); }
           ;
    request_target  = VCHAR+ >mark %request_target %unmark;
    request_line    = method SP request_target SP http_version :> CRLF;
    request_header  = accept_encoding | header;
    request_headers = (request_header CRLF)* CRLF;
    request        := request_line request_headers @done;
    
    ################################## RESPONSE ########################################
    status_code      = ([1-9] digit{2}) ${ADD_DIGIT(response->code)};
    reason_phrase    = (VCHAR | WSP | obs_text)* >mark %{SAVE(response->message)} %unmark;
    status_line      = http_version SP status_code SP reason_phrase :> CRLF;
    response_header  = header;
    response_headers = (response_header CRLF)* CRLF;
    response        := status_line response_headers @done;
}%%

namespace panda { namespace protocol { namespace http {

%% write data;

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
    %% write exec;
    return p - ps;
}

#endif

}}}
