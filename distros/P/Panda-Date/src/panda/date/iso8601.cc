#include <panda/date/parse.h>

namespace panda { namespace date {

using namespace panda::time;

enum class ISO_8601_STATE { YEAR, MONTH, WEEK, MDAY, WDAY, HOUR, MIN, SEC, TZ_OFFSET, END };

// helper: convert exactly len characters to int32_t or return error
static inline bool str2uint_helper (const char* str, size_t len, size_t len_left, int32_t& res) {
    if (len_left < len)
        return false;

    res = 0;
    for(size_t i = 0; i < len; ++i)
    {
        char c = str[i];
        if (c < '0' || c > '9')
            return false;
        res = res * 10 + (c - '0');
    }
    return true;
}

// helper: parse current fragment, move current parsing iterator and state
// str - beginning of the fragment to be parsed
// fragment_length - length of the expected value as defined by ISO 8601
// len_left - characters left till the end of the string
// fragment_value - output parameter for the parsed value
// delimiter - delimiter, expected AFTER this value
// state - current parsing state
// idx - index of current character for parsing
// next_state - next parsing state
// extended - extended or basic format (as defined by ISO 8601)
static inline err_t parse_fragment (const char* str, size_t fragment_length, size_t len_left, int32_t& fragment_value, char delimiter, ISO_8601_STATE& state, size_t& idx, ISO_8601_STATE next_state, bool extended) {
    if (!str2uint_helper(str, fragment_length, len_left, fragment_value))
        return E_UNPARSABLE;

    bool skip_delimiter = true;
    if (fragment_length  < len_left)
    {
        if (!extended && (delimiter != 'T'))
            delimiter = '\0';
        if ((delimiter == '\0') || (str[fragment_length] == delimiter))
            state = next_state;
        else
            return E_UNPARSABLE;

        if (delimiter == '\0')
            skip_delimiter = false;
    }
    idx = skip_delimiter ? idx + fragment_length + 1 : idx + fragment_length;
    return E_OK;
}

static inline const Timezone* parse_offset (const char* str, size_t len) {
    if (*str == 'Z' || len < 3) return tzget("GMT");

    bool is_western;
    if (*str == '+') is_western = true;
    else if (*str == '-') is_western = false;
    else return tzget("GMT");

    char offset[14];
    char* ptr = offset;
    *ptr++ = '<';
    *ptr++ = *str++;
    *ptr++ = *str++;
    *ptr++ = *str++;

    if (len > 3) {
        if (len == 5) *ptr++ = ':';
        else if (len == 6) *ptr++ = *str++;
        else return tzget("GMT");
        *ptr++ = *str++;
        *ptr++ = *str++;
    }
    *ptr++ = '>';
    *ptr++ = is_western ? '-' : '+';
    auto val_len = ptr-offset-4;
    memcpy(ptr, offset+2, val_len);
    ptr += val_len;

    return tzget(string_view(offset, ptr - offset));
}

err_t parse_iso8601 (string_view sv, datetime* date, const Timezone** zone) {
    static const int32_t WEEK_1_OFFSETS[] = {0, -1, -2, -3, 4, 3, 2};
    static const int32_t WEEK_2_OFFSETS[] = {8, 7, 6, 5, 9, 10, 9};
    auto len = sv.length();
    auto str = sv.data();

    if (!len) return E_UNPARSABLE;

    int32_t year = 0;
    int32_t month = 0;
    int32_t week = 0;
    int32_t mday = 1;
    int32_t wday = 1;
    int32_t hours = 0;
    int32_t minutes = 0;
    int32_t seconds = 0;

    // 2 formats are supported
    // extended (with hyphens)
    // basic (without hyphens)
    bool extended = false;
    // week format (with 'W')
    bool has_week = false;

    if (memchr(str, '-', len)) extended = true;
    if (memchr(str, 'W', len)) has_week = true;

    ISO_8601_STATE state = ISO_8601_STATE::YEAR;
    size_t i = 0;
    if (!has_week) {
        while (i < len) {
            if (state == ISO_8601_STATE::END) {
                if (i != len) return E_UNPARSABLE;
                break;
            }

            switch (state) {
                case ISO_8601_STATE::YEAR:
                    if (parse_fragment(str + i, 4, len-i, year, '-', state, i, ISO_8601_STATE::MONTH, extended) == E_UNPARSABLE) return E_UNPARSABLE;
                    break;

                case ISO_8601_STATE::MONTH:
                    if (parse_fragment(str + i, 2, len-i, month, '-', state, i, ISO_8601_STATE::MDAY, extended) == E_UNPARSABLE) return E_UNPARSABLE;
                    break;

                case ISO_8601_STATE::MDAY:
                    if (parse_fragment(str + i, 2, len-i, mday, 'T', state, i, ISO_8601_STATE::HOUR, extended) == E_UNPARSABLE) return E_UNPARSABLE;
                    break;

                case ISO_8601_STATE::HOUR:
                    if (parse_fragment(str + i, 2, len-i, hours, ':', state, i, ISO_8601_STATE::MIN, extended) == E_UNPARSABLE) return E_UNPARSABLE;
                    break;

                case ISO_8601_STATE::MIN:
                    if (parse_fragment(str + i, 2, len-i, minutes, ':', state, i, ISO_8601_STATE::SEC, extended) == E_UNPARSABLE) return E_UNPARSABLE;
                    break;

                case ISO_8601_STATE::SEC:
                    if (parse_fragment(str + i, 2, len-i, seconds, '\0', state, i, ISO_8601_STATE::TZ_OFFSET, extended) == E_UNPARSABLE) return E_UNPARSABLE;
                    break;

                case ISO_8601_STATE::TZ_OFFSET:
                    if (len-i) {
                        size_t offset_len = std::min(len-i, (size_t)6);
                        *zone = parse_offset(str + i, offset_len);
                        i += offset_len;
                    }
                    state = ISO_8601_STATE::END;
                    break;

                default: break;
            }
        }
    }
    else {
        while (i < len) {
            if (state == ISO_8601_STATE::END) {
                if (i != len) return E_UNPARSABLE;
                break;
            }

            switch (state) {
                case ISO_8601_STATE::YEAR:
                    if (parse_fragment(str + i, 4, len-i, year, '-', state, i, ISO_8601_STATE::WEEK, extended) == E_UNPARSABLE)
                        return E_UNPARSABLE;
                    break;

                case ISO_8601_STATE::WEEK:
                    if (str[i] == 'W')
                        ++i;
                    else
                        return E_UNPARSABLE;
                    if ( (parse_fragment(str + i, 2, len-i, week, '-', state, i, ISO_8601_STATE::WDAY,extended) == E_UNPARSABLE)
                        && (parse_fragment(str + i, 2, len-i, week, 'T', state, i, ISO_8601_STATE::HOUR,extended) == E_UNPARSABLE))
                            return E_UNPARSABLE;
                    break;

                case ISO_8601_STATE::WDAY:
                    if (parse_fragment(str + i, 1, len-i, wday, 'T', state, i, ISO_8601_STATE::HOUR,extended) == E_UNPARSABLE)
                        return E_UNPARSABLE;
                    break;

                case ISO_8601_STATE::HOUR:
                    if (parse_fragment(str + i, 2, len-i, hours, ':', state, i, ISO_8601_STATE::MIN,extended) == E_UNPARSABLE)
                        return E_UNPARSABLE;
                    break;

                case ISO_8601_STATE::MIN:
                    if (parse_fragment(str + i, 2, len-i, minutes, ':', state, i, ISO_8601_STATE::SEC,extended) == E_UNPARSABLE)
                        return E_UNPARSABLE;
                    break;

                case ISO_8601_STATE::SEC:
                    if (parse_fragment(str + i, 2, len-i, seconds, '\0', state, i, ISO_8601_STATE::TZ_OFFSET,extended) == E_UNPARSABLE)
                        return E_UNPARSABLE;
                    break;

                case ISO_8601_STATE::TZ_OFFSET:
                    if (len-i) {
                        size_t offset_len = std::min(len-i, (size_t)6);
                        *zone = parse_offset(str + i, offset_len);
                        i += offset_len;
                    }
                    state = ISO_8601_STATE::END;
                    break;

                default: break;
            }
        }
    }

    // special case: disallow trailing '-' or 'T'
    char last_char = str[std::min(i, len) - 1];
    if((last_char  < '0' || last_char > '9')
        && (last_char != 'Z')
        && (last_char != '+')
        && (last_char != '-'))
            return E_UNPARSABLE;

    if (has_week) {
        ptime_t days_since_christ = christ_days(year);
        int32_t beginning_weekday = days_since_christ % 7;
        if (week == 1) {
            wday = wday ? wday : 1;
            mday = WEEK_1_OFFSETS[beginning_weekday] + (wday - 1);
            if (mday <= 0) return E_UNPARSABLE; // was no such weekday that year
            date->mday = mday;
        }
        else {
            wday = wday ? wday : 1;
            date->mday = WEEK_2_OFFSETS[beginning_weekday] + (wday - 1) + 7 * (week -2);
        }
    }
    else {
        date->mday = (mday == 0) ? 1 : mday;
    }

    date->year = year;
    date->mon = (month == 0 ? 1 : month) - 1;
    date->hour = hours;
    date->min = minutes;
    date->sec = seconds;

    return E_OK;
}

}}
