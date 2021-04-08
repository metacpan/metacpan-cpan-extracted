#include "Message.h"
#include <algorithm>
#include <ostream>

namespace panda { namespace protocol { namespace http {

bool Message::keep_alive () const {
    auto conn = headers.connection();
    if (http_version == 10) return iequals(conn, "keep-alive");
    else                    return !iequals(conn, "close");
}

string Message::to_string (const std::vector<string>& pieces) {
    string r;
    for (auto piece: pieces) { r += piece; }
    return r;
}

void Message::compress_body(compression::Compressor& compressor, const Body &src, Body &dst) const {
    for(auto& part: src.parts) {
        auto data = compressor.compress(part);
        if (data) dst.parts.emplace_back(std::move(data));
    }
    dst.parts.emplace_back(compressor.flush());
}

// not effective at all, but used only in tests
bool operator== (const Headers& lhs, const Headers& _rhs) {
    if (lhs.size() != _rhs.size()) return false;
    auto rhs = _rhs; // copy
    for (auto& field : lhs) {
        bool found = false;
        for (auto it = rhs.begin(); it != rhs.end(); ++it) {
            if (!field.matches(it->name) || it->value != field.value) continue;
            found = true;
            rhs.fields.erase(it);
            break;
        }
        if (!found) return false;
    }
    return true;
}

std::ostream& operator<< (std::ostream& os, const Headers::Field& f) {
    os << "\"" << f.name << ": " << f.value << "\"";
    return os;
}

}}}
