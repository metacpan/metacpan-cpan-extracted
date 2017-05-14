#include <panda/time/osdep.h>
#include <cstring>  // strlen
#include <stdlib.h> // getenv
#include <assert.h>
#include <panda/time/util.h>

namespace panda { namespace time {

static inline bool _from_env (char* lzname, const char* envar) {
    const char* val = getenv(envar);
    if (val == NULL) return false;
    size_t len = std::strlen(val);
    if (len < 1 || len > TZNAME_MAX) return false;
    std::strcpy(lzname, val);
    return true;
}

static bool _tz_lzname (char* lzname);

}}

#if defined(__FreeBSD__) || defined(__FreeBSD_kernel__) || defined(__NetBSD__) || defined(__bsdi__) || defined(__DragonFly__)
#  include "unix.icc"
#  define __PTIME_TZDIR "/usr/share/zoneinfo"
#elif defined __linux__
#  include "unix.icc"
#  define __PTIME_TZDIR "/usr/share/zoneinfo"
#elif defined __APPLE__
#  include "unix.icc"
#  define __PTIME_TZDIR "/usr/share/zoneinfo"
#elif defined __VMS
#  include "vms.icc"
#  define __PTIME_TZDIR "/usr/share/zoneinfo"
#elif defined _WIN32
#  include "win.icc"
#  define __PTIME_TZDIR ""
#elif defined __OpenBSD__
#  include "unix.icc"
#  define __PTIME_TZDIR "/usr/share/zoneinfo"
#else
#error "Current operating system is not supported"
#endif

#ifdef TZDIR
#  undef  __PTIME_TZDIR
#  define __TMP_SHIT(name) #name
#  define __PTIME_TZDIR __TMP_SHIT(TZDIR)
#endif

const panda::string panda::time::ZONEDIR = __PTIME_TZDIR;

namespace panda { namespace time {

string tz_lzname () {
    char tmp[TZNAME_MAX+1];
    if (_from_env(tmp, "TZ") || _tz_lzname(tmp)) return string(tmp, strlen(tmp));
    return string(GMT_FALLBACK);
}

}}
