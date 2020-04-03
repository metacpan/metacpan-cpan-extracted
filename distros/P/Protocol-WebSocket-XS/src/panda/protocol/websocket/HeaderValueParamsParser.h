#pragma once
#include <vector>
#include <panda/string.h>
#include <panda/unordered_string_map.h>

namespace panda { namespace protocol { namespace websocket {

using HeaderValueParams = panda::unordered_string_map<string, string>;

struct HeaderValue {
    string            name;
    HeaderValueParams params;
};
typedef std::vector<HeaderValue> HeaderValues;

void   parse_header_value(const string& strval, HeaderValues& values);
string compile_header_value(const HeaderValues& values);

}}}
