#pragma once
#include <xs/xs.h>
#include <exception>
#include <panda/string.h>
#include <panda/string_view.h>

#define PXS_TRY(code) {                                                                       \
    try { code; }                                                                             \
    catch (const std::exception& err) { croak_sv(xs::lib::error_sv(err)); }                   \
    catch (const char* err)           { croak_sv(newSVpv(err, 0)); }                          \
    catch (const std::string& err)    { croak_sv(newSVpvn(err.data(), err.length())); }       \
    catch (const panda::string& err)  { croak_sv(newSVpvn(err.data(), err.length())); }       \
    catch (...)                       { croak_sv(newSVpvs("unknown c++ exception thrown")); } \
}

namespace xs { namespace lib {

inline panda::string sv2string (pTHX_ SV* svstr) {
    STRLEN len;
    char* ptr = SvPV(svstr, len);
    return panda::string(ptr, len);
}

inline std::string_view sv2string_view (pTHX_ SV* svstr) {
    STRLEN len;
    char* ptr = SvPV(svstr, len);
    return std::string_view(ptr, len);
}

SV* error_sv (const std::exception& err);

}}
