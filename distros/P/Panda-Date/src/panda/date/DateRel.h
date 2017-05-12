#pragma once
#include <math.h>
#include <stdexcept>
#include <panda/date/Date.h>

namespace panda { namespace date {

using panda::time::datetime;
    
class Date;

class DateRel {
private:
    ptime_t _sec;
    ptime_t _min;
    ptime_t _hour;
    ptime_t _day;
    ptime_t _month;
    ptime_t _year;
    bool    _is_const;

    void _ensure_mutable () {
        if (_is_const) throw std::invalid_argument("cannot change DateRel object - it's read only");
    }

public:
    void set (const DateRel* source) {
        _ensure_mutable();
        _sec   = source->_sec;
        _min   = source->_min;
        _hour  = source->_hour;
        _day   = source->_day;
        _month = source->_month;
        _year  = source->_year;
    }

    void set (const datetime*, const datetime*);

    err_t set (const char* str, size_t len = 0) {
        _ensure_mutable();
        datetime date;
        err_t error = parse_relative(str, len, &date);
        if (error != E_OK) return error;
        _year  = date.year;
        _month = date.mon;
        _day   = date.mday;
        _hour  = date.hour;
        _min   = date.min;
        _sec   = date.sec;
        return E_OK;
    }

    void set (ptime_t year, ptime_t mon=0, ptime_t day=0, ptime_t hour=0, ptime_t min=0, ptime_t sec=0) {
        _ensure_mutable();
        _year  = year;
        _month = mon;
        _day   = day;
        _hour  = hour;
        _min   = min;
        _sec   = sec;
    }

    DateRel (ptime_t year=0, ptime_t mon=0, ptime_t day=0, ptime_t hour=0, ptime_t min=0, ptime_t sec=0) : _is_const(false) {
        set(year, mon, day, hour, min, sec);
    }

    DateRel (const DateRel* source)                       : _is_const(false) { set(source); }
    DateRel (const DateRel& source)                       : _is_const(false) { set(&source); }
    DateRel (const datetime* from, const datetime* till)  : _is_const(false) { set(from, till); }
    DateRel (const char* str, size_t len = 0)             : _is_const(false) { set(str, len); }
    
    DateRel& operator= (const DateRel& source) {
        if (this != &source) set(&source);
        return *this;
    }
    
    bool is_const () const   { return _is_const; }
    void is_const (bool val) { _ensure_mutable(); _is_const = val; }

    ptime_t sec   () const      { return _sec; }
    void    sec   (ptime_t val) { _ensure_mutable(); _sec = val; }
    ptime_t min   () const      { return _min; }
    void    min   (ptime_t val) { _ensure_mutable(); _min = val; }
    ptime_t hour  () const      { return _hour; }
    void    hour  (ptime_t val) { _ensure_mutable(); _hour = val; }
    ptime_t day   () const      { return _day; }
    void    day   (ptime_t val) { _ensure_mutable(); _day = val; }
    ptime_t month () const      { return _month; }
    void    month (ptime_t val) { _ensure_mutable(); _month = val; }
    ptime_t year  () const      { return _year; }
    void    year  (ptime_t val) { _ensure_mutable(); _year = val; }
    bool    empty () const      { return _sec == 0 && _min == 0 && _hour == 0 && _day == 0 && _month == 0 && _year == 0; }

    ptime_t to_sec   () const { return _sec + _min*60 + _hour*3600 + _day * 86400 + (_month + 12*_year) * 2629744; }
    double  to_min   () const { return (double) to_sec() / 60; }
    double  to_hour  () const { return (double) to_sec() / 3600; }
    double  to_day   () const { return (double) to_sec() / 86400; }
    double  to_month () const { return (double) to_sec() / 2629744; }
    double  to_year  () const { return to_month() / 12; }
    ptime_t duration () const { return to_sec(); }
    
    const char* to_string () const;
    
    DateRel* clone () const { return new DateRel(this); }

    DateRel* multiply     (double koef);
    DateRel* divide       (double koef);
    DateRel* add          (const DateRel*);
    DateRel* subtract     (const DateRel*);
    DateRel* negative     ();

    DateRel* multiply_new (double koef)            const { return clone()->multiply(koef); }
    DateRel* divide_new   (double koef)            const { return clone()->divide(koef); }
    DateRel* add_new      (const DateRel* operand) const { return clone()->add(operand); }
    DateRel* subtract_new (const DateRel* operand) const { return clone()->subtract(operand); }
    DateRel* negative_new ()                       const { return clone()->negative(); }

    int compare (const DateRel* operand) const {
        return epoch_cmp(to_sec(), operand->to_sec());
    }

    bool equals (const DateRel* operand) const {
        return _sec == operand->_sec && _min == operand->_min && _hour == operand->_hour &&
               _day == operand->_day && _month == operand->_month && _year == operand->_year;
    }

    ~DateRel () {}
};

}}
