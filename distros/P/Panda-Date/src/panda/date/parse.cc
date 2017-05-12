#include <cstring>
#include <stdlib.h>
#include <panda/date/parse.h>
using namespace panda::time;

namespace panda { namespace date {

const int _P_STATE_YEAR  = 0;
const int _P_STATE_MONTH = 1;
const int _P_STATE_DAY   = 2;
const int _P_STATE_HOUR  = 3;
const int _P_STATE_MIN   = 4;
const int _P_STATE_SEC   = 5;

err_t parse_iso (const char* str, size_t len, datetime* date) {
    if (len < 1) len = std::strlen(str);
    int state = _P_STATE_YEAR;
    int32_t curval = 0;
    const char* strend = str + len;
    for (; str <= strend; str++) {
        char c = (str == strend) ? '-' : *str;
        if (c >= '0' and c <= '9') {
            curval *= 10;
            curval += (c-'0');
        }
        else if (c == '-' || c == ' ' || c == ':' || c == '/' || c == '.' || c == '\n' || c == 0) {
            switch (state) {
                case _P_STATE_YEAR:
                    date->year = curval;
                    break;
                case _P_STATE_MONTH:
                    date->mon = (curval == 0 ? 1 : curval) - 1;
                    break;
                case _P_STATE_DAY:
                    date->mday = curval == 0 ? 1 : curval;
                    break;
                case _P_STATE_HOUR:
                    date->hour = curval;
                    break;
                case _P_STATE_MIN:
                    date->min = curval;
                    break;
                case _P_STATE_SEC:
                    date->sec = curval;
                    break;
            }
            state++;
            curval = 0;
        }
        else return E_UNPARSABLE;
    }

    switch (state) { // fill absent fields with defaults
        case _P_STATE_MONTH:
            date->mon = 0;
        case _P_STATE_DAY:
            date->mday = 1;
        case _P_STATE_HOUR:
            date->hour = 0;
        case _P_STATE_MIN:
            date->min = 0;
        case _P_STATE_SEC:
            date->sec = 0;
    }
    
    return E_OK;
}

err_t parse_relative (const char* str, size_t len, datetime* date) {
    if (len < 1) len = strlen(str);
    memset(date, 0, sizeof(datetime)); // reset all values
    ptime_t curval = 0;
    bool negative = false;
    const char* strend = str + len;
    for (; str < strend; str++) {
        char c = *str;
        if (c == '-') negative = true;
        else if (c >= '0' and c <= '9') {
            curval *= 10;
            curval += (c-48);
        }
        else {
            if (negative) {
                curval = -curval;
                negative = false;
            }
            
            switch (c) {
                case 'Y':
                case 'y':
                    date->year = curval; break;
                case 'M':
                    date->mon = curval; break;
                case 'D':
                case 'd':
                    date->mday = curval; break;
                case 'h':
                    date->hour = curval; break;
                case 'm':
                    date->min = curval; break;
                case 's':
                    date->sec = curval; break;
            }
            
            curval = 0;
        }
    }

    return E_OK;
}

const unsigned char relchars[256] = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0,
    0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

bool looks_like_relative (const char* str) {
    unsigned char c;
    const char* p = str;
    for (; (c = *p) != '\0'; p++) if (relchars[c]) return true;
    return p == str;
}

}}
