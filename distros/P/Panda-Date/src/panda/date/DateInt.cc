#include <panda/date/inc.h>
#include <panda/date/DateInt.h>
#include <panda/date/DateRel.h>

namespace panda { namespace date {

err_t DateInt::set (const char* str, size_t len) {
    if (len < 1) len = strlen(str);
    const char* delim = strchr(str, '~');
    if (delim == NULL || delim >= str + len - 2) return E_UNPARSABLE;
    err_t error1 = _from.set(str, delim - str);
    const char* till_starts = delim + 2;
    err_t error2 = _till.set(till_starts, str + len - till_starts);
    if (error1 != E_OK) return error1;
    else if (error2 != E_OK) return error2;
    return E_OK;
}

const char* DateInt::to_string () const {
    if (error()) return NULL;
    static char str[100];
    char* ptr = str;
    const char* src = _from.toString();
    while (*src) *(ptr++) = *(src++);
    *(ptr++) = ' '; *(ptr++) = '~'; *(ptr++) = ' ';
    src = _till.toString();
    while (*src) *(ptr++) = *(src++);
    *(ptr++) = 0;
    return str;
}

DateRel* DateInt::relative () const { return new DateRel(_from.date(), _till.date()); }

}}
