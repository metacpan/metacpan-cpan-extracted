#include <xs/lib.h>
#include <typeinfo>
#include <cxxabi.h>

namespace xs { namespace lib {

SV* error_sv (const std::exception& err) {
    dTHX;

    int status;
    char* class_name = abi::__cxa_demangle(typeid(err).name(), NULL, NULL, &status);
    if (status != 0) croak("[error_sv] !critical! abi::__cxa_demangle error");
    SV* errsv = newSVpvs("[");
    sv_catpv(errsv, class_name);
    sv_catpv(errsv, "] ");
    sv_catpv(errsv, err.what());
    free(class_name);

    return errsv;
}

}}
