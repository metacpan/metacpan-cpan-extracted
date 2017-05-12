#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <time.h>

#define POSIX_STRPTIME_SENTINEL (-1901)

#define POSIX_STRPTIME_SET(field) \
  { \
    if (field == POSIX_STRPTIME_SENTINEL) { \
        XPUSHs(&PL_sv_undef); \
    } \
    else { \
        mXPUSHi(field); \
    } \
  } \


MODULE = POSIX::strptime		PACKAGE = POSIX::strptime

void
strptime(input, format)
    SV *input
    SV *format
   PREINIT:
     struct tm tm_t;
     init_tm(&tm_t);
     // We need these to tell what values were *not* modified by strptime()
     tm_t.tm_sec = POSIX_STRPTIME_SENTINEL;
     tm_t.tm_min = POSIX_STRPTIME_SENTINEL;
     tm_t.tm_hour = POSIX_STRPTIME_SENTINEL;
     tm_t.tm_mday = POSIX_STRPTIME_SENTINEL;
     tm_t.tm_mon = POSIX_STRPTIME_SENTINEL;
     tm_t.tm_year = POSIX_STRPTIME_SENTINEL;
     tm_t.tm_isdst = POSIX_STRPTIME_SENTINEL;
   PPCODE:
     strptime(SvPV_nolen(input), SvPV_nolen(format), &tm_t);
     POSIX_STRPTIME_SET(tm_t.tm_sec);
     POSIX_STRPTIME_SET(tm_t.tm_min);
     POSIX_STRPTIME_SET(tm_t.tm_hour);
     POSIX_STRPTIME_SET(tm_t.tm_mday);
     POSIX_STRPTIME_SET(tm_t.tm_mon);
     POSIX_STRPTIME_SET(tm_t.tm_year);
     POSIX_STRPTIME_SET(tm_t.tm_wday);
     POSIX_STRPTIME_SET(tm_t.tm_yday);
     POSIX_STRPTIME_SET(tm_t.tm_isdst);
