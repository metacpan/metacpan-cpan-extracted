#pragma once
#include <xs/xs.h>
#include <panda/time.h>
#include <panda/date.h>

#if IVSIZE >= 8
#  define SvMIV(x) SvIV(x)
#  define SvMUV(x) SvUV(x)
#else
#  define SvMIV(x) ((int64_t)SvNV(x))
#  define SvMUV(x) ((uint64_t)SvNV(x))
#endif

namespace xs { namespace date {

using namespace panda::time;
using namespace panda::date;
using std::string_view;
using xs::sv2string_view;

const char*const DATE_CLASS    = "Panda::Date";
const char*const DATEREL_CLASS = "Panda::Date::Rel";
const char*const DATEINT_CLASS = "Panda::Date::Int";

inline const Timezone* tzget_required (pTHX_ SV* zone) {
    return tzget(zone != NULL && SvOK(zone) ? sv2string_view(aTHX_ zone) : string_view());
}

inline const Timezone* tzget_optional (pTHX_ SV* zone) {
    return zone ? tzget(SvOK(zone) ? sv2string_view(aTHX_ zone) : string_view()) : NULL;
}

inline void daterel_chkro (pTHX_ const DateRel* THIS) {
    if (THIS->is_const()) croak("Panda::Date::Rel: cannot change this object - it's read only");
}

}}
