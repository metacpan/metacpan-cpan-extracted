#include "Body.h"
#include <ostream>

namespace panda { namespace protocol { namespace http {

string Body::to_string () const {
    if (!parts.size()) return "";
    if (parts.size() == 1) return parts[0];
    string ret(length() + 1); // speedup possible c_str()
    for (auto& s : parts) ret += s;
    return ret;
}

std::ostream& operator<< (std::ostream& os, const Body& b) {
    for (auto part : b.parts) os << part;
    return os;
}

}}}
