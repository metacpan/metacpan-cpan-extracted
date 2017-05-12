#ifndef _gnu_config_h_
#define _gnu_config_h_

#include "config.h"
#include "xs_config.h"

#ifdef HAS_TM_TM_GMTOFF
#define HAVE_TM_GMTOFF 1
#endif

#ifdef HAS_TM_TM_ZONE
#define HAVE_TM_ZONE 1
#endif

#ifdef HAS_GMTIME_R
#define HAVE_GMTIME_R 1
#endif

#ifdef HAS_LOCALTIME_R
#define HAVE_LOCALTIME_R 1
#endif

#ifdef HAS_TZNAME
#define HAVE_TZNAME 1
#endif

#ifdef HAS_TZSET
#define HAVE_TZSET 1
#endif

#define my_strftime gnu_strftime

#endif
