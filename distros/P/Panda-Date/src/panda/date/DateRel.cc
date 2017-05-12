#include <panda/lib.h>
#include <panda/date/DateRel.h>

#define RELSTR_START(maxlen)\
    static char ret[maxlen+1];\
    char* ptr = ret;\
    char* buf;
    
#define RELSTR_VAL(val,units)\
    if (ptr != ret) *(ptr++) = ' ';\
    buf = itoa(val);\
    while (*buf) *(ptr++) = *(buf++);\
    *(ptr++) = units;

#define RELSTR_END\
    *(ptr++) = 0;\
    return ret;
    
namespace panda { namespace date {

using panda::lib::itoa;
    
void DateRel::set (const datetime* from, const datetime* till) {
    _ensure_mutable();
    _sec = 0, _min = 0, _hour = 0, _day = 0, _month = 0, _year = 0;
    bool reverse = false;
    if (date_cmp(*from, *till) > 0) {
        reverse = true;
        std::swap(from, till);
    }
    
    _sec = till->sec - from->sec;
    if (_sec < 0) { _sec += 60; _min--; }
    
    _min += till->min - from->min;
    if (_min < 0) { _min += 60; _hour--; }
    
    _hour += till->hour - from->hour;
    if (_hour < 0) { _hour += 24; _day--; }
    
    _day += till->mday - from->mday;
    if (_day < 0) {
        int tmpy = till->year;
        int tmpm = till->mon-1;
        if (tmpm < 0) { tmpm += 12; tmpy--; }
        int days = days_in_month(tmpy, tmpm);
        _day += days;
        _month--;
    }
    
    _month += till->mon - from->mon;
    if (_month < 0) { _month += 12; _year--; }
    
    _year += till->year - from->year;
    
    if (reverse) negative();
}

const char* DateRel::to_string () const {
    RELSTR_START(65);
    if (_year  != 0) { RELSTR_VAL(_year, 'Y') }
    if (_month != 0) { RELSTR_VAL(_month, 'M') }
    if (_day   != 0) { RELSTR_VAL(_day, 'D') }
    if (_hour  != 0) { RELSTR_VAL(_hour, 'h') }
    if (_min   != 0) { RELSTR_VAL(_min, 'm') }
    if (_sec   != 0) { RELSTR_VAL(_sec, 's') }
    RELSTR_END;
}

DateRel* DateRel::multiply (double koef) {
    _ensure_mutable();
    if (fabs(koef) < 1 && koef != 0) return divide(1/koef);
    _sec   *= koef;
    _min   *= koef;
    _hour  *= koef;
    _day   *= koef;
    _month *= koef;
    _year  *= koef;
    return this;
}

DateRel* DateRel::divide (double koef) {
    _ensure_mutable();
    if (fabs(koef) <= 1) return multiply(1/koef);
    double td;
    int64_t tmp;
    
    tmp = _year;
    _year /= koef;
    td = (tmp - _year*koef)*12;
    tmp = td;
    _month += tmp;
    td = (td - tmp)*((double)2629744/86400);
    tmp = td;
    _day += tmp;
    td = (td - tmp)*24;
    tmp = td;
    _hour += tmp;
    td = (td - tmp)*60;
    tmp = td;
    _min += tmp;
    td = (td - tmp)*60;
    _sec += td;

    tmp = _month;
    _month /= koef;
    td = (tmp - _month*koef)*((double)2629744/86400);
    tmp = td;
    _day += tmp;
    td = (td - tmp)*24;
    tmp = td;
    _hour += tmp;
    td = (td - tmp)*60;
    tmp = td;
    _min += tmp;
    td = (td - tmp)*60;
    _sec += td;
    
    tmp = _day;
    _day /= koef;
    td = (tmp - _day*koef)*24;
    tmp = td;
    _hour += tmp;
    td = (td - tmp)*60;
    tmp = td;
    _min += tmp;
    td = (td - tmp)*60;
    _sec += td;
    
    tmp = _hour;
    _hour /= koef;
    td = (tmp - _hour*koef)*60;
    tmp = td;
    _min += tmp;
    td = (td - tmp)*60;
    _sec += td;
    
    tmp = _min;
    _min /= koef;
    _sec += (tmp - _min*koef)*60;
    
    _sec /= koef;
    
    return this;
}

DateRel* DateRel::add (const DateRel* operand) {
    _ensure_mutable();
    _sec   += operand->_sec;
    _min   += operand->_min;
    _hour  += operand->_hour;
    _day   += operand->_day;
    _month += operand->_month;
    _year  += operand->_year;
    return this;
}

DateRel* DateRel::subtract (const DateRel* operand) {
    _ensure_mutable();
    _sec   -= operand->_sec;
    _min   -= operand->_min;
    _hour  -= operand->_hour;
    _day   -= operand->_day;
    _month -= operand->_month;
    _year  -= operand->_year;
    return this;
}

DateRel* DateRel::negative () {
    _ensure_mutable();
    _sec   = -_sec;
    _min   = -_min;
    _hour  = -_hour;
    _day   = -_day;
    _month = -_month;
    _year  = -_year;
    return this;
}

}}
