#pragma once
#include <panda/date/inc.h>
#include <panda/date/parse.h>

namespace panda { namespace date {

using panda::time::Timezone;
using panda::time::datetime;
using panda::time::days_in_month;
using panda::time::tzget;
using panda::time::tzlocal;
    
class DateRel;

class Date {

private:
    static const int MAX_FMT = 255;
    static char      _strfmt[MAX_FMT+1];
    static bool      _range_check;

    const Timezone* _zone;

    union {
                ptime_t _epoch;
        mutable ptime_t _epochMUT;
    };
    union {
                datetime _date;
        mutable datetime _dateMUT;
    };
    union {
                bool _has_epoch;
        mutable bool _has_epochMUT;
    };
    union {
                bool _has_date;
        mutable bool _has_dateMUT;
    };
    union {
                bool _normalized;
        mutable bool _normalizedMUT;
    };

    uint8_t _error;
    
    void esync () const;
    void dsync () const;
    err_t validate_range();
    
    void echeck () const { if (!_has_epoch) esync(); }
    void dcheck () const { if (!_has_date || !_normalized) dsync(); };

    void dchg () {
        _has_epoch = false;
        _normalized = false;
    }

    void dchg_auto () {
        dchg();
        _date.isdst = -1;
    }

    void echg () {
        _has_date = false;
        _normalized = false;
    }

    void _zone_set (const Timezone* zone) {
        if (_zone == NULL) {
            if (zone == NULL) _zone = tzlocal();
            else _zone = zone;
            _zone->retain();
        } else if (zone != NULL) {
            _zone->release();
            zone->retain();
            _zone = zone;
        }
    }

public: 

    ptime_t epoch () const      { echeck(); return _epoch; }
    void    epoch (ptime_t val) { _epoch = val; _has_epoch = true; echg(); }

    void set (ptime_t val, const Timezone* zone = NULL) {
        _zone_set(zone);
        epoch(val);
    }

    err_t set (const char* str, size_t len = 0, const Timezone* zone = NULL) {
        _zone_set(zone);
        _error    = parse_iso(str, len, &_date);
        _has_date = true;
        dchg_auto();
        if (_range_check && _error == E_OK) validate_range();
        return (err_t) _error;
    }

    err_t set (int32_t year, ptime_t month, ptime_t day, ptime_t hour, ptime_t min, ptime_t sec, int isdst= -1, const Timezone* zone = NULL) {
        _zone_set(zone);
        _error      = E_OK;
        _date.year  = year;
        _date.mon   = month - 1;
        _date.mday  = day;
        _date.hour  = hour;
        _date.min   = min;
        _date.sec   = sec;
        _date.isdst = isdst;
        _has_date   = true;
        dchg();
        if (_range_check) validate_range();
        return (err_t) _error;
    }

    void set (const Date* source, const Timezone* zone = NULL) {
        _error = source->_error;
        if (_zone != NULL) _zone->release();

        if (zone == NULL || _error) {
            _has_epoch  = source->_has_epoch;
            _has_date   = source->_has_date;
            _normalized = source->_normalized;
            _zone       = source->_zone;
            _epoch      = source->_epoch;
            if (_has_date) _date  = source->_date;
        } else {
            source->dcheck();
            _has_epoch  = false;
            _has_date   = true;
            _normalized = source->_normalized;
            _date       = source->_date;
            _zone       = zone;
        }

        _zone->retain();
    }

    Date (const Date& source) : _zone(NULL) {
        set(&source);
    }

    Date (ptime_t epoch = (ptime_t) ::time(NULL), const Timezone* zone = NULL) : _zone(NULL), _error(E_OK) {
        set(epoch, zone);
    }

    Date (const char* str, size_t len = 0, const Timezone* zone = NULL) : _zone(NULL) {
        set(str, len, zone);
    }

    Date (int32_t year, ptime_t mon, ptime_t day, ptime_t hour, ptime_t min, ptime_t sec, int isdst = -1, const Timezone* zone = NULL) : _zone(NULL) {
        set(year, mon, day, hour, min, sec, isdst, zone);
    }
    
    Date (const Date* source, const Timezone* zone = NULL) : _zone(NULL) {
        set(source, zone);
    }

    ~Date () {
        _zone->release();
    }

    Date& operator= (const Date& source) {
        if (this != &source) set(&source);
        return *this;
    }

    inline err_t change (int32_t year, ptime_t mon=-1, ptime_t day=-1, ptime_t hour=-1, ptime_t min=-1, ptime_t sec=-1, int isdst=-1, const Timezone* zone=NULL) {
        dcheck();
        _error = E_OK;
        if (year >= 0) _date.year = year;
        if (mon   > 0) _date.mon  = mon - 1;
        if (day   > 0) _date.mday = day;
        if (hour >= 0) _date.hour = hour;
        if (min  >= 0) _date.min  = min;
        if (sec  >= 0) _date.sec  = sec;
        _date.isdst = isdst;
        dchg();
        _zone_set(zone);
        if (_range_check) validate_range();
        return (err_t) _error;
    }

    const datetime* date       () const    { dcheck(); return &_date; }
    bool            has_epoch  () const    { return _has_epoch; }
    bool            has_date   () const    { return _has_date; }
    bool            normalized () const    { return _normalized; }
    err_t           error      () const    { return (err_t) _error; }
    void            error      (err_t val) { _error = val; epoch(0); }
    const Timezone* timezone   () const    { return _zone; }

    void timezone (const Timezone* zone) {
        dcheck();
        if (zone == NULL) zone = tzlocal();
        dchg_auto();
        _zone_set(zone);
    }

    void to_timezone (const Timezone* zone) {
        echeck();
        if (zone == NULL) zone = tzlocal();
        echg();
        _zone_set(zone);
    }
    
    int32_t year  () const      { dcheck(); return _date.year; }
    void    year  (int32_t val) { dcheck(); _date.year = val; dchg_auto(); }
    int32_t _year () const      { return year() - 1900; }
    void    _year (int32_t val) { year(val + 1900); }
    int8_t  yr    () const      { return year() % 100; }
    void    yr    (int val)     { year( year() - yr() + val ); }

    uint8_t month  () const      { dcheck(); return _date.mon + 1; }
    void    month  (ptime_t val) { dcheck(); _date.mon = val - 1; dchg_auto(); }
    uint8_t _month () const      { return month() - 1; }
    void    _month (ptime_t val) { month(val + 1); }

    uint8_t mday () const      { dcheck(); return _date.mday; }
    void    mday (ptime_t val) { dcheck(); _date.mday = val; dchg_auto(); }
    uint8_t day  () const      { return mday(); }
    void    day  (ptime_t val) { mday(val); }

    uint8_t hour () const      { dcheck(); return _date.hour; }
    void    hour (ptime_t val) { dcheck(); _date.hour = val; dchg_auto(); }

    uint8_t min () const      { dcheck(); return _date.min; }
    void    min (ptime_t val) { dcheck(); _date.min = val; dchg_auto(); }

    uint8_t sec () const      { dcheck(); return _date.sec; }
    void    sec (ptime_t val) { dcheck(); _date.sec = val; dchg_auto(); }

    uint8_t wday () const       { dcheck(); return _date.wday + 1; }
    void    wday (ptime_t val)  { dcheck(); _date.mday += val - (_date.wday + 1); dchg_auto(); }
    uint8_t _wday () const      { return wday() - 1; }
    void    _wday (ptime_t val) { wday(val + 1); }
    uint8_t ewday () const      { dcheck(); return _date.wday == 0 ? 7 : _date.wday; }
    void    ewday (ptime_t val) { _date.mday += val - ewday(); dchg_auto(); }

    uint16_t yday  () const      { dcheck(); return _date.yday + 1; }
    void     yday  (ptime_t val) { dcheck(); _date.mday += val - 1 - _date.yday; dchg_auto(); }
    uint16_t _yday () const      { return yday() - 1; }
    void     _yday (ptime_t val) { yday(val + 1); }

    bool        isdst  () const { dcheck(); return _date.isdst > 0 ? true : false; }
    int32_t     gmtoff () const { dcheck(); return _date.gmtoff; }
    const char* tzabbr () const { dcheck(); return _date.zone; }

    int days_in_month () const { dcheck(); return panda::time::days_in_month(_date.year, _date.mon); }

    Date* month_begin     () { mday(1); return this; }
    Date* month_end       () { mday(days_in_month()); return this; }
    Date* month_begin_new () { Date* ret = clone(); ret->mday(1); return ret; }
    Date* month_end_new   () { Date* ret = clone(); ret->mday(days_in_month()); return ret; }
    
    Date* truncate () {
        dcheck();
        _date.sec  = 0;
        _date.min  = 0;
        _date.hour = 0;
        dchg_auto();
        return this;
    }
    Date* truncate_new () { return clone()->truncate(); }

    Date* clone (const Timezone* zone = NULL) const {
        return new Date(this, zone);
    }

    Date* clone (int32_t year, ptime_t mon=-1, ptime_t day=-1, ptime_t hour=-1, ptime_t min=-1, ptime_t sec=-1, int isdst=-1, const Timezone* zone=NULL) const {
        Date* ret = clone();
        ret->change(year, mon, day, hour, min, sec, isdst, zone);
        return ret;
    }

    char*       strftime (const char*, char*, size_t) const;
    const char* errstr   () const;

    const char* toString () const {
        if (_error) return NULL;
        return _strfmt[0] == '\0' ? iso() : this->strftime(_strfmt, NULL, 0);
    }

    int compare (const Date&) const;
    int compare (const Date* arg) const { return compare(*arg); };

    bool operator== (const Date& operand) const { return compare(operand) == 0; }
    bool operator<  (const Date& operand) const { return compare(operand) == -1; }
    bool operator<= (const Date& operand) const { return compare(operand) != 1; }
    bool operator>  (const Date& operand) const { return compare(operand) == 1; }
    bool operator>= (const Date& operand) const { return compare(operand) != -1; }

    void operator+= (const DateRel&);
    void operator-= (const DateRel&);

    Date operator+ (const DateRel& operand) const {
        Date ret(*this);
        ret += operand;
        return ret;
    }

    Date operator- (const DateRel& operand) const {
        Date ret(*this);
        ret -= operand;
        return ret;
    }
    
    bool equals (const Date* operand) const { return operator==(*operand); }
    bool lt     (const Date* operand) const { return operator<(*operand); }
    bool lte    (const Date* operand) const { return operator<=(*operand); }
    bool gt     (const Date* operand) const { return operator>(*operand); }
    bool gte    (const Date* operand) const { return operator>=(*operand); }

    Date* add      (const DateRel* operand) { operator+=(*operand); return this; }
    Date* subtract (const DateRel* operand) { operator-=(*operand); return this; }

    Date* add_new      (const DateRel* operand) { return clone()->add(operand); }
    Date* subtract_new (const DateRel* operand) { return clone()->subtract(operand); }

    const char* iso      () const;
    const char* mysql    () const;
    const char* hms      () const;
    const char* ymd      () const;
    const char* mdy      () const;
    const char* dmy      () const;
    const char* meridiam () const;
    const char* ampm     () const;

    static Date* now   () { return new Date(); }
    static Date* today () {
        Date* ret = now();
        ret->truncate();
        return ret;
    }

    static bool range_check ()         { return _range_check; }
    static void range_check (bool val) { _range_check = val; }

    static void string_format (const char*);
    static const char* string_format ();
};

}}
