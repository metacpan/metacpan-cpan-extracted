#include <xs/xs.h>
#include <xs/lib.h>
#include <panda/time.h>
using namespace panda::time;
using panda::string;
using xs::lib::sv2string;

#ifdef _WIN32
#  define SYSTIMEGM(x)    _mkgmtime(x)
#  define SYSTIMELOCAL(x) mktime(x)
#  define LT_FORMAT       "%a %b %d %H:%M:%S %Y"
#else
#  define SYSTIMEGM(x)    timegm(x)
#  define SYSTIMELOCAL(x) timelocal(x)
#  define LT_FORMAT       "%a %b %e %H:%M:%S %Y"
#endif

#if IVSIZE >= 8
#  define SvMIV(x) SvIV(x)
#  define SvMUV(x) SvUV(x)
#else
#  define SvMIV(x) ((int64_t)SvNV(x))
#  define SvMUV(x) ((uint64_t)SvNV(x))
#endif

SV* export_transition (pTHX_ Timezone::Transition& trans, bool is_past) {
    HV* hv = newHV();
    hv_store(hv, "offset", 6, newSViv(trans.offset),    0);
    hv_store(hv, "abbrev", 6, newSVpv(trans.abbrev, 0), 0);
    if (!is_past) {
        hv_store(hv, "start",       5, newSViv(trans.start),      0);
        hv_store(hv, "isdst",       5, newSVuv(trans.isdst),      0);
        hv_store(hv, "gmt_offset", 10, newSViv(trans.gmt_offset), 0);
        hv_store(hv, "leap_corr",   9, newSViv(trans.leap_corr), 0);
        hv_store(hv, "leap_delta", 10, newSViv(trans.leap_delta), 0);
    }
    return newRV_noinc((SV*)hv);
}

HV* export_timezone (pTHX_ const Timezone* zone) {
    HV* ret = newHV();
    
    hv_store(ret, "name", 4, newSVpvn(zone->name.data(), zone->name.length()), 0);
    hv_store(ret, "is_local", 8, newSViv(zone->is_local ? 1 : 0), 0);
    
    HV* future = newHV();
    hv_store(future, "hasdst", 6, newSVuv(zone->future.hasdst ? 1 : 0), 0);
    
    HV* outer = newHV();
    hv_store(outer, "abbrev", 6, newSVpv(zone->future.outer.abbrev, 0), 0);
    hv_store(outer, "offset", 6, newSViv(zone->future.outer.offset), 0);
    hv_store(outer, "gmt_offset", 10, newSViv(zone->future.outer.gmt_offset), 0);
    hv_store(outer, "isdst", 5, newSViv(zone->future.outer.isdst), 0);
    hv_store(future, "outer", 5, newRV_noinc((SV*) outer), 0);
    
    if (zone->future.hasdst) {
        HV* inner = newHV();
        hv_store(inner, "abbrev", 6, newSVpv(zone->future.inner.abbrev, 0), 0);
        hv_store(inner, "offset", 6, newSViv(zone->future.inner.offset), 0);
        hv_store(inner, "gmt_offset", 10, newSViv(zone->future.inner.gmt_offset), 0);
        hv_store(inner, "isdst", 5, newSViv(zone->future.inner.isdst), 0);
        
        HV* outer_end = newHV();
        hv_store(outer_end, "mon",  3, newSVuv(zone->future.outer.end.mon),  0);
        hv_store(outer_end, "week", 4, newSVuv(zone->future.outer.end.yday), 0);
        hv_store(outer_end, "day",  3, newSVuv(zone->future.outer.end.wday), 0);
        hv_store(outer_end, "hour", 4, newSViv(zone->future.outer.end.hour), 0);
        hv_store(outer_end, "min",  3, newSViv(zone->future.outer.end.min),  0);
        hv_store(outer_end, "sec",  3, newSViv(zone->future.outer.end.sec),  0);
        hv_store(outer, "end", 3, newRV_noinc((SV*) outer_end), 0);
        
        HV* inner_end = newHV();
        hv_store(inner_end, "mon",  3, newSVuv(zone->future.inner.end.mon),  0);
        hv_store(inner_end, "week", 4, newSVuv(zone->future.inner.end.yday), 0);
        hv_store(inner_end, "day",  3, newSVuv(zone->future.inner.end.wday), 0);
        hv_store(inner_end, "hour", 4, newSViv(zone->future.inner.end.hour), 0);
        hv_store(inner_end, "min",  3, newSViv(zone->future.inner.end.min),  0);
        hv_store(inner_end, "sec",  3, newSViv(zone->future.inner.end.sec),  0);
        hv_store(inner, "end", 3, newRV_noinc((SV*) inner_end), 0);
        
        hv_store(future, "inner", 5, newRV_noinc((SV*) inner), 0);
    }
    hv_store(ret, "future", 6, newRV_noinc((SV*) future), 0);
    
    AV* trans = newAV();
    for (uint32_t i = 0; i < zone->trans_cnt; i++) av_push(trans, export_transition(aTHX_ zone->trans[i], false));
    hv_store(ret, "transitions", 11, newRV_noinc((SV*) trans), 0);
    
    hv_store(ret, "past", 4, export_transition(aTHX_ zone->trans[0], true), 0);
    
    return ret;
}

MODULE = Panda::Time                PACKAGE = Panda::Time
PROTOTYPES: DISABLE

void tzset (string_view newzone = string_view()) {
    panda::time::tzset(newzone);
}

string tzdir (SV* newdirSV = NULL) {
    if (newdirSV) {
        string newdir = SvOK(newdirSV) ? sv2string(aTHX_ newdirSV) : string("");
        if (tzdir(newdir)) RETVAL = "1";
        else XSRETURN_UNDEF;
    } else
        RETVAL = tzdir();
}

string tzsysdir () {
    RETVAL = tzsysdir();
}
    
void gmtime (SV* epochSV = NULL) : ALIAS(localtime=1) {
    ptime_t epoch;
    if (epochSV) epoch = (ptime_t) SvMIV(epochSV);
    else epoch = (ptime_t) time(NULL);
    
    datetime date;
    if (ix == 0) gmtime(epoch, &date);
    else localtime(epoch, &date);
    
    if (GIMME_V == G_ARRAY) {
        EXTEND(SP, 9);
        EXTEND_MORTAL(9);
        mPUSHu(date.sec);
        mPUSHu(date.min);
        mPUSHu(date.hour);
        mPUSHu(date.mday);
        mPUSHu(date.mon);
        mPUSHi(date.year);
        mPUSHu(date.wday);
        mPUSHu(date.yday);
        mPUSHu(date.isdst);
        XSRETURN(9);
    } else {
        EXTEND(SP, 1);
        SV* ret = newSV(1000);
        SvPOK_on(ret);
        char* str = SvPVX(ret);
        size_t strlen = strftime(str, 1000, LT_FORMAT, &date);
        SvCUR_set(ret, strlen);
        mPUSHs(ret);
        XSRETURN(1);
    }
}

ptime_t timegm (SV* sec, SV* min, SV* hour, SV* mday, SV* mon, SV* year, SV* isdst = NULL) : ALIAS(timelocal=1, timegmn=2, timelocaln=3) {
    datetime date;
    date.sec  = SvMIV(sec);
    date.min  = SvMIV(min);
    date.hour = SvMIV(hour);
    date.mday = SvMIV(mday);
    date.mon  = SvMIV(mon);
    date.year = SvMIV(year);
    
    if (isdst) date.isdst = SvIV(isdst);
    else date.isdst = -1;
    
    switch (ix) {
        case 0:
            RETVAL = timegml(&date);
            break;
        case 1:
            RETVAL = timelocall(&date);
            break;
        case 2:
            RETVAL = timegm(&date);
            break;
        case 3:
            RETVAL = timelocal(&date);
            break;
        default: croak("not reached");
    }
    
    if (ix & 2) {
        sv_setiv(sec, date.sec);
        sv_setiv(min, date.min);
        sv_setiv(hour, date.hour);
        sv_setiv(mday, date.mday);
        sv_setiv(mon, date.mon);
        sv_setiv(year, date.year);
        if (isdst) sv_setiv(isdst, date.isdst);
    }
}

time_t systimegm (int64_t sec, int64_t min, int64_t hour, int64_t mday, int64_t mon, int64_t year, int64_t isdst = -1) : ALIAS(systimelocal=1) {
    struct tm date;
    date.tm_sec   = sec;
    date.tm_min   = min;
    date.tm_hour  = hour;
    date.tm_mday  = mday;
    date.tm_mon   = mon;
    date.tm_year  = year;
    date.tm_isdst = isdst;
    if (ix == 0) RETVAL = SYSTIMEGM(&date);
    else RETVAL = SYSTIMELOCAL(&date);
}

HV* tzget (string_view zonename = string_view()) {
    RETVAL = export_timezone(aTHX_ tzget(zonename));
}

string tzname () {
    RETVAL = tzlocal()->name;
}

#ifdef TEST_FULL

INCLUDE: test.xsi

#endif
