#include "Compression.h"

namespace panda { namespace protocol { namespace http { namespace compression {

bool is_valid_compression(std::uint8_t value) noexcept {
    bool r = false;
    if (value) {
        unsigned counter = 0;
        for(unsigned i = 0; i <= 3; ++i) {
            unsigned mask = 1 << i;
            if (mask & value) { ++counter; }
        }
        r = counter == 1;
    }
    return r;
}

}}}}
