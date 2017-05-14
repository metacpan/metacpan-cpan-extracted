#include <xs/xs.h>
#include <xs/uri.h>
#include <iostream>
#include <panda/uri/all.h>
#include <panda/string_view.h>

using namespace panda::uri;
using namespace xs::uri;
using xs::sv2string;
using xs::sv2string_view;
using std::string_view;

static char unsafe_query_component_plus[256];

MODULE = Panda::URI                PACKAGE = Panda::URI
PROTOTYPES: DISABLE

TYPEMAP: << END
XSURI* XT_PANDA_XSURI
END

BOOT {
    unsafe_generate(unsafe_query_component_plus, UNSAFE_UNRESERVED);
    unsafe_query_component_plus[(unsigned char)' '] = '+';
    XSURIWrapper::register_perl_scheme(aTHX_ "http",  "Panda::URI::http");
    XSURIWrapper::register_perl_scheme(aTHX_ "https", "Panda::URI::https");
    XSURIWrapper::register_perl_scheme(aTHX_ "ftp",   "Panda::URI::ftp");
}

URIx* uri (string url = string(), int flags = 0) {
    RETVAL = URI::create(url, flags);
}

void register_scheme (string scheme, string_view perl_class) {
    XSURIWrapper::register_perl_scheme(aTHX_ scheme, perl_class);
}

INCLUDE: encode.xsi
INCLUDE: URI.xsi
INCLUDE: schemas.xsi
INCLUDE: cloning.xsi
