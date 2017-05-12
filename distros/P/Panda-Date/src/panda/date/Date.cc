#include <panda/lib.h>
#include <panda/date/Date.h>
#include <panda/date/DateRel.h>

using panda::lib::itoa;

#define TOSTR_START(maxlen)\
    dcheck();\
    size_t i;\
    static char ret[maxlen+1];\
    char* ptr = ret;\
    char* buf;\
    size_t len;
    
#define TOSTR_DEL(char) *(ptr++) = char;

#define TOSTR_VAL2(val)\
    buf = itoa(val);\
    len = strlen(buf);\
    if ((val) < 10) *(ptr++) = '0';\
    for (i = 0; i < len; i++) *(ptr++) = *(buf++);

#define TOSTR_YEAR\
    buf = itoa(_date.year);\
    len = strlen(buf);\
    if (_date.year >= 0 && _date.year <= 999) for (i = 0; i < 4 - len; i++) *(ptr++) = '0';\
    for (i = 0; i < len; i++) *(ptr++) = *(buf++);
    
#define TOSTR_MONTH TOSTR_VAL2(_date.mon+1)
#define TOSTR_DAY   TOSTR_VAL2(_date.mday)
#define TOSTR_HOUR  TOSTR_VAL2(_date.hour)
#define TOSTR_MIN   TOSTR_VAL2(_date.min)
#define TOSTR_SEC   TOSTR_VAL2(_date.sec)

#define TOSTR_AMPM\
    *(ptr++) = _date.hour < 12 ? 'A' : 'P';\
    *(ptr++) = 'M';

#define TOSTR_END\
    *(ptr++) = 0;\
    return ret;

namespace panda { namespace date {

void Date::esync () const { // w/o date normalization
    _has_epochMUT = true;
    _epochMUT = timeanyl(&_dateMUT, _zone);
}

void Date::dsync () const {
    _normalizedMUT = true;
    if (_has_epoch) { // no date -> calculate from epoch
        _has_dateMUT = true;
        anytime(_epoch, &_dateMUT, _zone);
    } else { // no epoch -> normalize from date (set epoch as a side effect as well)
        _has_epochMUT = true;
        _epochMUT = timeany(&_dateMUT, _zone);
    }
}

err_t Date::validate_range () {
    datetime old = _date;
    dsync();
    
    if (old.sec != _date.sec || old.min != _date.min || old.hour != _date.hour || old.mday != _date.mday ||
        old.mon != _date.mon || old.year != _date.year) {
        _error = E_RANGE;
        return E_RANGE;
    }
    
    return E_OK;
}

int Date::compare (const Date& operand) const {
    if (_has_epoch && operand._has_epoch) return epoch_cmp(_epoch, operand._epoch);
    else if (_zone != operand._zone) return epoch_cmp(epoch(), operand.epoch());
    else return date_cmp(*date(), *operand.date());
}

void Date::operator+= (const DateRel& operand) {
    if (operand.year() | operand.month() | operand.day()) {
        dcheck();
        _date.mday += operand.day();
        _date.mon  += operand.month();
        _date.year += operand.year();
        dchg_auto();
    }
    echeck();
    _epoch += operand.sec() + operand.min()*60 + operand.hour()*3600;
    echg();
}

void Date::operator-= (const DateRel& operand) {
    if (operand.year() | operand.month() | operand.day()) {
        dcheck();
        _date.mday -= operand.day();
        _date.mon  -= operand.month();
        _date.year -= operand.year();
        dchg_auto();
    }
    echeck();
    _epoch -= operand.sec() + operand.min()*60 + operand.hour()*3600;
    echg();
}

char* Date::strftime (const char* format, char* buf, size_t maxsize) const {
    dcheck();
    static char defbuf[1000];
    if (buf == NULL) {
        buf = defbuf;
        maxsize = 1000;
    }
    size_t reslen = panda::time::strftime(buf, maxsize, format, &_date);
    return reslen > 0 ? buf : NULL;
}

const char* Date::iso () const {
    TOSTR_START(50);
    TOSTR_YEAR; TOSTR_DEL('-'); TOSTR_MONTH; TOSTR_DEL('-'); TOSTR_DAY; TOSTR_DEL(' ');
    TOSTR_HOUR; TOSTR_DEL(':'); TOSTR_MIN; TOSTR_DEL(':'); TOSTR_SEC;
    TOSTR_END;
}

const char* Date::mysql () const {
    TOSTR_START(45);
    TOSTR_YEAR; TOSTR_MONTH; TOSTR_DAY; TOSTR_HOUR; TOSTR_MIN; TOSTR_SEC;
    TOSTR_END;
}

const char* Date::hms () const {
    TOSTR_START(8); TOSTR_HOUR; TOSTR_DEL(':'); TOSTR_MIN; TOSTR_DEL(':'); TOSTR_SEC; TOSTR_END;
}

const char* Date::ymd () const {
    TOSTR_START(41); TOSTR_YEAR; TOSTR_DEL('/'); TOSTR_MONTH; TOSTR_DEL('/'); TOSTR_DAY; TOSTR_END;
}

const char* Date::mdy () const {
    TOSTR_START(41); TOSTR_MONTH; TOSTR_DEL('/'); TOSTR_DAY; TOSTR_DEL('/'); TOSTR_YEAR; TOSTR_END;
}

const char* Date::dmy () const {
    TOSTR_START(41); TOSTR_DAY; TOSTR_DEL('/'); TOSTR_MONTH; TOSTR_DEL('/'); TOSTR_YEAR; TOSTR_END;
}

const char* Date::meridiam () const {
    TOSTR_START(8);
    int hour = _date.hour % 12;
    if (hour == 0) hour = 12;
    TOSTR_VAL2(hour); TOSTR_DEL(':'); TOSTR_MIN; TOSTR_DEL(' '); TOSTR_AMPM;
    TOSTR_END;
}

const char* Date::ampm () const {
    dcheck();
    return _date.hour < 12 ? "AM" : "PM";
}

const char* Date::errstr () const {
    switch (_error) {
        case E_OK:
            return NULL;
        case E_UNPARSABLE:
            return "can't parse date string";
        case E_RANGE:
            return "input date is out of range";
        default:
            return "unknown error";
    }
}

/////////   STATIC   ///////////////////////////////
char Date::_strfmt[] = "";
bool Date::_range_check = false;

const char* Date::string_format () {
    if (_strfmt[0] == '\0') return NULL;
    return _strfmt;
}

void Date::string_format (const char* fmt) {
    if (fmt == NULL) _strfmt[0] = '\0';
    else strncpy(_strfmt, fmt, MAX_FMT);
}

}}
