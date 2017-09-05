#include <panda/date/parse.h>

namespace panda { namespace date {

const int _P_STATE_YEAR  = 0;
const int _P_STATE_MONTH = 1;
const int _P_STATE_DAY   = 2;
const int _P_STATE_HOUR  = 3;
const int _P_STATE_MIN   = 4;
const int _P_STATE_SEC   = 5;

err_t parse_iso (string_view str, datetime* date, const Timezone**) {
    int state = _P_STATE_YEAR;
    int32_t curval = 0;
    auto end = str.cend();
    for (auto ptr = str.cbegin(); ptr <= end; ++ptr) {
        char c = (ptr == end) ? '-' : *ptr;
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
        else {
            return E_UNPARSABLE;
        }
    }

    switch (state) { // fill absent fields with defaults
        case _P_STATE_MONTH:
            date->mon = 0; // fallthrough
        case _P_STATE_DAY:
            date->mday = 1; // fallthrough
        case _P_STATE_HOUR:
            date->hour = 0; // fallthrough
        case _P_STATE_MIN:
            date->min = 0; // fallthrough
        case _P_STATE_SEC:
            date->sec = 0;
    }

    return E_OK;
}

}}
