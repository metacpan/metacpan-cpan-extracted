#pragma once
#include <cstring>
#include <panda/date/Date.h>

namespace panda { namespace date {

using panda::time::christ_days;

class Date;

class DateInt {
private:
    Date _from;
    Date _till;
    
    ptime_t hmsDiff () const;

public: 
    err_t set (string_view str);

    void set (ptime_t from, ptime_t till) {
        _from.set(from);
        _till.set(till);
    }

    void set (const Date* from, const Date* till) {
        _from.set(from);
        _till.set(till);
    }

    DateInt ()                                   : _from((ptime_t) 0), _till((ptime_t) 0)       {}
    DateInt (ptime_t from, ptime_t till)         : _from((ptime_t) from), _till((ptime_t) till) {}
    DateInt (const Date* from, const Date* till) : _from(from), _till(till)                     {}
    DateInt (string_view str)                    : _from((ptime_t) 0), _till((ptime_t) 0)       { set(str); }

    err_t error () const { return _from.error() == E_OK ? _till.error() : _from.error(); }
    
    Date* from () { return &_from; }
    Date* till () { return &_till; }

    const char* to_string() const;

    ptime_t hms_diff () const {
        return (_till.hour() - _from.hour())*3600 + (_till.min() - _from.min())*60 + _till.sec() - _from.sec();
    }

    ptime_t duration () const { return error() ? 0 : (_till.epoch() - _from.epoch()); }
    ptime_t sec      () const { return duration(); }
    ptime_t imin     () const { return duration()/60; }
    double  min      () const { return (double) duration()/60; }
    ptime_t ihour    () const { return duration()/3600; }
    double  hour     () const { return (double) duration()/3600; }

    ptime_t iday     () const { return (ptime_t) day(); }
    double  day      () const { return christ_days(_till.year()) + _till.yday() - christ_days(_from.year()) - _from.yday() + (double) hms_diff() / 86400; }

    ptime_t imonth   () const { return (ptime_t) month(); }
    double  month    () const {
        return (_till.year() - _from.year())*12 + _till.month() - _from.month() +
               (double) (_till.day() - _from.day() + (double) hms_diff() / 86400) / _from.days_in_month();
    }

    ptime_t iyear () const { return (ptime_t) year(); }
    double  year  () const { return month() / 12; }

    DateRel* relative () const;
    
    DateInt* clone () const { return new DateInt(&_from, &_till); }
    
    DateInt* add (const DateRel* operand) {
        _from.add(operand);
        _till.add(operand);
        return this;
    }

    DateInt* subtract (const DateRel* operand) {
        _from.subtract(operand);
        _till.subtract(operand);
        return this;
    }

    DateInt* negative () {
        char tmp[sizeof(_from)];
        std::memcpy(tmp, &_from, sizeof(_from));
        std::memcpy(&_from, &_till, sizeof(_from));
        std::memcpy(&_till, tmp, sizeof(_from));
        return this;
    }

    DateInt* add_new      (const DateRel* operand) const { return clone()->add(operand); }
    DateInt* subtract_new (const DateRel* operand) const { return clone()->subtract(operand); }
    DateInt* negative_new ()                       const { return new DateInt(&_till, &_from); }

    int compare (const DateInt* operand) const {
        return epoch_cmp(duration(), operand->duration());
    }

    bool equals  (const DateInt* operand) const {
        return _from.equals(&operand->_from) && _till.equals(&operand->_till);
    }

    int includes (const Date* date) const {
        if (_from.gt(date)) return 1;
        if (_till.lt(date)) return -1;
        return 0;
    }

    ~DateInt () {}
};

}}
