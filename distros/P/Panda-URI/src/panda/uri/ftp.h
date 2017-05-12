#pragma once
#include <panda/uri/Strict.h>

namespace panda { namespace uri {

class URI::ftp : public UserPass {
public:
    ftp () : Strict() {}
    ftp (const string& source, int flags = 0) : Strict(source, flags) { strict_scheme(); }
    ftp (const URI& source)                   : Strict(source)        { strict_scheme(); }
};

}}
