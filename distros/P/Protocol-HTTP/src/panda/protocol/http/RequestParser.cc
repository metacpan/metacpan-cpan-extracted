#include "RequestParser.h"
#include "MessageParser.tcc"

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

    auto pos = MessageParser::parse(buffer,
        [this] {
            for (const auto& s : request->headers.get_multi("Cookie")) parse_cookie(s);
            return true;
        },
        [this] {
            state = State::done;
            return false;
        }
   );
    Result ret = {request, pos, state, error};
    if (state >= State::done) reset();
    return ret;
}

}}}
