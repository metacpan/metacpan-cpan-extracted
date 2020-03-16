#include "Message.h"
#include <algorithm>

namespace panda { namespace protocol { namespace http {

bool Message::keep_alive () const {
    auto conn = headers.connection();
    if (http_version == 10) return iequals(conn, "keep-alive");
    else                    return !iequals(conn, "close");
}

BodyGuard Message::maybe_compress () {
    if (!compressor || body.parts.empty()) return {};
    BodyGuard body_holder(&body);

    /* if it is chunked, it will be compressed a bit later */
    if (!chunked)  {
        Body compressed;
        for(auto& part: body.parts) {
            auto data = compressor->compress(part);
            if (data) {
                compressed.parts.emplace_back(std::move(data));
            }
        }
        compressed.parts.emplace_back(compressor->flush());
        body = std::move(compressed);
    }
    return body_holder;
}

string Message::to_string (const std::vector<string>& pieces) {
    string r;
    for (auto piece: pieces) { r += piece; }
    return r;
}


}}}
