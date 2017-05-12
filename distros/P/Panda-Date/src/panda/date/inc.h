#pragma once
#include <panda/time.h>

namespace panda { namespace date {

using panda::time::ptime_t;
using panda::time::datetime;

enum err_t {E_OK, E_UNPARSABLE, E_RANGE};

inline static int epoch_cmp (ptime_t a, ptime_t b) {
    return a > b ? 1 : (a == b ? 0 : -1);
}

inline static ptime_t pseudo_epoch (const datetime& date) {
    return date.sec + date.min*61 + date.hour*60*61 + date.mday*24*60*61 + date.mon*31*24*60*61 + date.year*12*31*24*60*61;
}

inline static int date_cmp (const datetime& d1, const datetime& d2) {
    return epoch_cmp(pseudo_epoch(d1), pseudo_epoch(d2));
}

}}
