#pragma once
#include <panda/time/basic.h>
#include <panda/time/timezone.h>

namespace panda { namespace time {

void    gmtime   (ptime_t epoch, datetime* result);
ptime_t timegm   (datetime* date);
ptime_t timegml  (datetime* date);
void    anytime  (ptime_t epoch, datetime* result, const Timezone* zone);
ptime_t timeany  (datetime* date, const Timezone* zone);
ptime_t timeanyl (datetime* date, const Timezone* zone);

inline void    localtime  (ptime_t epoch, datetime* result) { anytime(epoch, result, tzlocal()); }
inline ptime_t timelocal  (datetime* date)                  { return timeany(date, tzlocal()); }
inline ptime_t timelocall (datetime* date)                  { return timeanyl(date, tzlocal()); }

size_t strftime   (char* buf, size_t maxsize, const char* format, const datetime* timeptr);
void   printftime (const char* format, const datetime* timeptr);

}}

