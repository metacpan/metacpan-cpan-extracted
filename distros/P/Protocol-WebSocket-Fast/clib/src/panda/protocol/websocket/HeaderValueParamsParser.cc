#include "HeaderValueParamsParser.h"

namespace panda { namespace protocol { namespace websocket {

static const int MAX_HEADER_VALUE = 8*1024;
using uchar = unsigned char;
static bool header_value_special[256];

static int init () {
    header_value_special[(uchar)';'] = true;
    header_value_special[(uchar)','] = true;
    header_value_special[(uchar)'='] = true;
    header_value_special[(uchar)' '] = true;
    return 0;
}
static const auto __init = init();


void parse_header_value(const string& strval, HeaderValues& values) {
    auto cur = strval.begin();
    auto end = strval.end();

    enum { PARSE_MODE_NAME, PARSE_MODE_KEY, PARSE_MODE_VAL } mode = PARSE_MODE_NAME;
    char accstr[MAX_HEADER_VALUE];
    string key;
    char* acc = accstr;
    HeaderValue* elem = NULL;

    for (; cur != end; ++cur) {
        char c = *cur;
        if (!header_value_special[(uchar)c]) {
            *acc++ = c;
            continue;
        }
        if (c == ' ') continue;

        if (mode == PARSE_MODE_NAME) {
            if (c == ';' || c == ',') {
                auto sz = values.size();
                values.resize(sz+1);
                elem = &values[sz];
                elem->name.assign(accstr, acc-accstr);
                acc = accstr;
                if (c == ';') mode = PARSE_MODE_KEY;
            }
            else *acc++ = c;
        }
        else if (mode == PARSE_MODE_KEY) {
            if (c == ';' || c == ',') {
                elem->params.emplace(string(accstr, acc-accstr), string());
                acc = accstr;
                if (c == ',') mode = PARSE_MODE_NAME;
            }
            else if (c == '=') {
                key.assign(accstr, acc-accstr);
                acc = accstr;
                mode = PARSE_MODE_VAL;
            }
            else *acc++ = c;
        }
        else { // PARSE_MODE_VAL
            if (c == ';' || c == ',') {
                elem->params.emplace(key, string(accstr, acc-accstr));
                acc = accstr;
                if (c == ',') mode = PARSE_MODE_NAME;
                else mode = PARSE_MODE_KEY;
            }
            else *acc++ = c;
        }
    }

    // finish
    if      (mode == PARSE_MODE_NAME) values.push_back(HeaderValue{string(accstr, acc-accstr), HeaderValueParams()});
    else if (mode == PARSE_MODE_KEY)  elem->params.emplace(string(accstr, acc-accstr), string());
    else    /* PARSE_MODE_VAL */      elem->params.emplace(key, string(accstr, acc-accstr));
}

string compile_header_value(const HeaderValues& values) {
    string str;

    for (const auto& elem : values) {
        str += elem.name;
        for (const auto& param : elem.params) {
            str += "; ";
            str += param.first;
            if (param.second) {
                str += '=';
                str += param.second;
            }
        }
        str += ", ";
    }

    if (str) str.length(str.length() - 2);

    return str;
}

}}}
