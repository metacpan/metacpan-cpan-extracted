#include "RequestParser.h"

#define PARSER_DEFINITIONS_ONLY
#include "MessageParser.cc"

namespace panda { namespace protocol { namespace http {

RequestParser::RequestParser (IFactory* fac) : factory(fac) {
    reset();
}

void RequestParser::reset () {
    MessageParser::reset();
    cs = message_parser_en_request;
}

RequestParser::Result RequestParser::parse (const string& buffer) {
    if (!request) {
        request = new_request();
        message = request;
    }

    auto pos = MessageParser::_parse(buffer);
    Result ret = {request, pos, state, error};
    if (state >= State::done) reset();
    return ret;
}

bool RequestParser::on_headers    () {
    for (const auto& s : request->headers.get_multi("Cookie")) parse_cookie(s);
    return true;
}

bool RequestParser::on_empty_body () {
    state = State::done;
    return false;
}


}}}
