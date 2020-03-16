#include "ResponseParser.h"
#include "MessageParser.tcc"

namespace panda { namespace protocol { namespace http {

ResponseParser::ResponseParser () {
    reset();
}

void ResponseParser::_reset (bool keep_context) {
    MessageParser::reset();
    if (!keep_context) _context_request.reset();
    cs = message_parser_en_response;
}

ResponseParser::Result ResponseParser::parse (const string& buffer) {
    ensure_response_created();

    auto pos = MessageParser::parse(buffer,
        [this] {
            for (const auto& s : response->headers.get_multi("Set-Cookie")) parse_cookie(s);

            if (_context_request->method == Request::Method::HEAD || response->code  < 200 || response->code == 204 || response->code == 304) {
                if (response->chunked || (content_length > 0 && _context_request->method != Request::Method::HEAD)) {
                    set_error(errc::unexpected_body);
                } else {
                    state = State::done;
                }
                return false;
            }
            return true;
        },
        [this] {
            response->headers.set("Connection", "close");
            state = State::body;
            return true;
        }
    );

    Result ret = {response, pos, state, error};

    if (state >= State::done) {
        bool keep_context = false;
        if (response->code == 100 && !error) {
            if (_context_request->expects_continue()) keep_context = true;
            else {
                ret.error = errc::unexpected_continue;
                ret.state = State::error;
            }
        }
        _reset(keep_context);
    }

    return ret;
}

ResponseParser::Result ResponseParser::eof () {
    if (!_context_request) return {{}, 0, State::headers, {}};

    bool done = response && !response->keep_alive() && !content_length && !response->chunked && state == State::body
            && (!compressor || compressor->eof());

    if (done) {
        state = State::done;
    } else {
        ensure_response_created();
        set_error(errc::unexpected_eof);
    }

    Result ret = {response, 0, state, error};
    reset();
    return ret;
}

}}}
