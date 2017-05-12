#include <panda/time/timezone.h>
#include <map>
#include <assert.h>
#include <stdlib.h>
#include <panda/lib.h>
#include <panda/string.h>
#include <panda/time/util.h>
#include <panda/time/osdep.h>
#include <panda/time/tzparse.h>
#include <panda/unordered_string_map.h>

namespace panda { namespace time {

using panda::string;

static panda::unordered_string_map<string, const Timezone*> _tzcache;
static string          _tzdir;
static const Timezone* _localzone = NULL;

static const Timezone* _tzget            (string zonename);
static bool            _virtual_zone     (const string_view& zonename, Timezone* zone);
static void            _virtual_fallback (Timezone* zone);
static void            _tzcache_clear    ();

const Timezone* tzlocal () {
    if (_localzone == NULL) tzset(NULL);
    return _localzone;
}

const Timezone* tzget (const string_view& zonename) {
    if (!zonename.length()) {
        if (!_localzone) tzset(NULL);
        return _localzone;
    }
    auto it = _tzcache.find(zonename);
    if (it != _tzcache.cend()) return it->second;
    string strname = string(zonename);
    const Timezone* zone = _tzget(strname);
    _tzcache.emplace(strname, zone);
    return zone;
}

void tzset (const Timezone* zone) {
    if (!zone) {
        const char* s = getenv("TZ");
        if (!s) s = "";
        string_view etzname = s;
        if (etzname.length()) zone = tzget(etzname);
        else zone = _tzget("");
    }
    if (_localzone == zone) return;
    if (_localzone) {
        _localzone->is_local = false;
        _localzone->release();
    }
    _localzone = zone;
    _localzone->is_local = true;
    _localzone->retain();
}

void tzset (const string_view& zonename) {
    if (zonename.length()) tzset(tzget(zonename));
    else tzset(NULL);
}

const string& tzdir    () { return _tzdir ? _tzdir : tzsysdir(); }
const string& tzsysdir () { return ZONEDIR; }

bool tzdir (const string& dir) {
    _tzcache_clear();
    _tzdir = dir;
    return true;
}

static const Timezone* _tzget (string zonename) {
    //printf("ptime: tzget for zone %s\n", zonename);
    Timezone* zone = new Timezone();
    zone->is_local = false;
    
    if (!zonename.length()) {
        zonename = tz_lzname();
        zone->is_local = true;
        assert(zonename.length());
    }
    
    if (zonename.length() > TZNAME_MAX) {
        //fprintf(stderr, "ptime: tzrule too long\n");
        _virtual_fallback(zone);
        return zone;
    }

    string filename;
    if (zonename.front() == ':') {
        filename = zonename.substr(1);
        zone->name = zonename;
    }
    else {
        string dir = tzdir();
        if (!dir) {
            fprintf(stderr, "ptime: tzget: this OS has no olson timezone files, you must explicitly set tzdir(DIR)\n");
            _virtual_fallback(zone);
            return zone;
        }
        zone->name = zonename;
        filename = dir + '/' + zonename;
    }
    
    string content = readfile(filename);

    if (!content) { // tz rule
        //printf("ptime: tzget rule %s\n", zonename);
        if (!_virtual_zone(zonename, zone)) {
            //fprintf(stderr, "ptime: parsing rule '%s' failed\n", zonename);
            _virtual_fallback(zone);
            return zone;
        }
    }
    else { // tz file
        //printf("ptime: tzget file %s\n", filename.c_str());
        bool result = tzparse(content, zone);
        if (!result) {
            //fprintf(stderr, "ptime: parsing file '%s' failed\n", filename.c_str());
            _virtual_fallback(zone);
            return zone;
        }
    }
    
    return zone;
}

static void _virtual_fallback (Timezone* zone) {
    //fprintf(stderr, "ptime: fallback to '%s'\n", PTIME_GMT_FALLBACK);
    assert(_virtual_zone(GMT_FALLBACK, zone) == true);
    zone->name = GMT_FALLBACK;
    zone->is_local = false;
}

static bool _virtual_zone (const string_view& zonename, Timezone* zone) {
    //printf("ptime: virtual zone %s\n", zonename);
    if (!tzparse_rule(zonename, &zone->future)) return false;
    zone->future.outer.offset = zone->future.outer.gmt_offset;
    zone->future.inner.offset = zone->future.inner.gmt_offset;
    zone->future.delta        = zone->future.inner.offset - zone->future.outer.offset;
    zone->future.max_offset   = std::max(zone->future.outer.offset, zone->future.inner.offset);
    
    zone->leaps_cnt = 0;
    zone->leaps = NULL;
    zone->trans_cnt = 1;
    zone->trans = new Timezone::Transition[zone->trans_cnt];
    std::memset(zone->trans, 0, sizeof(Timezone::Transition));
    zone->trans[0].start       = EPOCH_NEGINF;
    zone->trans[0].local_start = EPOCH_NEGINF;
    zone->trans[0].local_lower = EPOCH_NEGINF;
    zone->trans[0].local_upper = EPOCH_NEGINF;
    zone->trans[0].leap_corr   = 0;
    zone->trans[0].leap_delta  = 0;
    zone->trans[0].leap_end    = EPOCH_NEGINF;
    zone->trans[0].leap_lend   = EPOCH_NEGINF;
    zone->ltrans = zone->trans[0];
    return true;
}

static void _tzcache_clear () {
    for (auto it = _tzcache.begin(); it != _tzcache.end(); it++) it->second->release();
    _tzcache.clear();
}

}}
