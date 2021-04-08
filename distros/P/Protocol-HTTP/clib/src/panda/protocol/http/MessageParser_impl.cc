#include "MessageParser.h"

#define PARSER_DEFINITIONS_ONLY
#include "MessageParser.cc"

namespace panda { namespace protocol { namespace http {

MessageParser::~MessageParser() {}

#define RETURN_IF_PARSE_ERROR do if (cs == message_parser_error) {  \
    if (!error) set_error(errc::lexical_error);                     \
    return pos;                                                     \
} while (0)

#define RETURN_IF_INCOMPLETE do if (cs < message_parser_first_final) {  \
    if (marked) {                                                       \
        if (mark != -1) {                                               \
            acc = buffer.substr(mark, len - mark);                      \
            mark = -1;                                                  \
        }                                                               \
        else acc += buffer;                                             \
    }                                                                   \
    return pos;                                                         \
} while (0)

#define RETURN_IF_MAX_BODY_SIZE(current_size) do if (current_size > max_body_size) {    \
    set_error(max_body_size ? errc::body_too_large : errc::unexpected_body);            \
    return pos;                                                                         \
} while (0)

size_t MessageParser::_parse (const string& buffer) {
    auto   len = buffer.length();
    size_t pos = 0;
    //printf("parse: %s\n", buffer.c_str());

    while (pos != len) switch (state) {
        case State::headers: {
            //printf("headers\n");
            pos = machine_exec(buffer, pos);
            RETURN_IF_PARSE_ERROR;

            headers_so_far += pos;
            if (headers_so_far > max_headers_size) {
                set_error(errc::headers_too_large);
                return pos;
            }
            
            RETURN_IF_INCOMPLETE;
            
            headers_finished = true;
            if (!on_headers()) return pos;

            if (message->chunked) {
                state = State::chunk;
                cs = message_parser_en_first_chunk;
            }
            else if (has_content_length) {
                if (content_length > 0) {
                    state = State::body;
                    RETURN_IF_MAX_BODY_SIZE(content_length);
                } else {
                    state = State::done;
                    return pos;
                }
            }
            else if (!on_empty_body()) return pos;
            
            continue;
        }
        case State::body: {
            //printf("body\n");
            auto have = len - pos;
            size_t consumed;

            /* 1. determine how much it can be consumed */
            if (content_length) {
                auto left = content_length - body_so_far;
                if (have >= left) { consumed = left; state = State::done; }
                else              { consumed = have;                      }
            } else {
                consumed = have;
            }

            /* 2. try to consume the available bytes */
            string piece = buffer.substr(pos, consumed);
            body_so_far += have;
            if (compressor) {
                auto append_err = compressor->uncompress(piece, message->body);
                if (append_err) { set_error(append_err); return pos; }
            }
            else {
                if (!content_length) { RETURN_IF_MAX_BODY_SIZE(body_so_far); }
                message->body.parts.push_back(piece);
            }

            return pos + consumed;
        }
        case State::chunk: {
            //printf("chunk. rest: %s\n", buffer.substr(pos).c_str());
            pos = machine_exec(buffer, pos);
            RETURN_IF_PARSE_ERROR;
            RETURN_IF_INCOMPLETE;

            if (!chunk_length) { // final chunk
                state = State::chunk_trailer;
                cs = message_parser_en_chunk_trailer;
                continue;
            }
            //printf("chunk len = %llu\n", chunk_length);

            body_so_far += chunk_length;
            RETURN_IF_MAX_BODY_SIZE(body_so_far);

            chunk_so_far = 0;
            state = State::chunk_body;
            continue;
        }
        case State::chunk_body: {
            //printf("chunk body\n");
            auto left = chunk_length - chunk_so_far;
            auto have = len - pos;

            bool final = false;
            size_t consumed;
            if (have >= left) {
                consumed = left;
                final = true;
            } else {
                consumed = have;
            }
            chunk_so_far += consumed;

            auto piece = buffer.substr(pos, consumed);
            if (compressor) {
                auto append_err = compressor->uncompress(piece, message->body);
                if (append_err) { set_error(append_err); return pos; }
            }
            else {
                message->body.parts.push_back(piece);
            }

            if (final) {
                pos += left;
                state = State::chunk;
                cs = message_parser_en_chunk;
                continue;
            } else {
                return len;
            }

        }
        case State::chunk_trailer: {
            //printf("chjunk trailer\n");
            pos = machine_exec(buffer, pos);
            RETURN_IF_PARSE_ERROR;
            RETURN_IF_INCOMPLETE;
            state = State::done;
            return pos;
        }
        default: abort();
    }
    
    return len;
}

}}}
