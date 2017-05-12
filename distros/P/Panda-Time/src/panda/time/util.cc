#include <panda/time/util.h>
#include <stdio.h>

namespace panda { namespace time {

using panda::string;

string readfile (const std::string_view& path) {
    char spath[path.length()+1]; // need to make path null-terminated
    std::memcpy(spath, path.data(), path.length());
    spath[path.length()] = 0;

    FILE* fh = fopen(spath, "rb");
    if (fh == NULL) return string();
    
    if (fseek(fh, 0, SEEK_END) != 0) {
        fclose(fh);
        return string();
    }
    
    auto size = ftell(fh);
    if (size < 0) {
        fclose(fh);
        return string();
    }
    
    rewind(fh);
    string ret(size);
    size_t readsize = fread(ret.buf(), sizeof(char), size, fh);
    if (readsize != (size_t)size) return string();
    
    fclose(fh);
    ret.length(readsize);
    return ret;
}

}}
