#include <cstring>
#include <stdlib.h>
#include <panda/date/parse.h>

namespace panda { namespace date {

// guess date&time format guess helper ( points for ASCII character )
static uint32_t FORMAT_POINTS[256];

static bool _init () {
    FORMAT_POINTS[(unsigned char)'-'] = 1;
    FORMAT_POINTS[(unsigned char)'/'] = 1;
    FORMAT_POINTS[(unsigned char)'T'] = 100;
    FORMAT_POINTS[(unsigned char)'W'] = 100;
    return true;
}
static bool _init_ = _init();

err_t parse (string_view str, datetime* date, const Timezone** zone) {
    auto ptr = str.cbegin();
    auto end = str.cend();
    uint32_t format_guess = 0;
    while (ptr != end) format_guess += FORMAT_POINTS[(unsigned char)*ptr++];

    if (format_guess == 0 || format_guess >= 100)
        return parse_iso8601(str, date, zone);
    else
        return parse_iso(str, date, zone);
}

err_t parse_relative (string_view str, datetime* date) {
    memset(date, 0, sizeof(datetime)); // reset all values
    ptime_t curval = 0;
    bool negative = false;
    auto ptr = str.cbegin();
    auto end = str.cend();
    while (ptr != end) {
        char c = *ptr++;
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

bool looks_like_relative (string_view str) {
    auto ptr = str.cbegin();
    auto end = str.cend();
    while (ptr != end && *ptr != 0) if (relchars[(unsigned char)*ptr++]) return true;
    return ptr == str.cbegin();
}

}}
