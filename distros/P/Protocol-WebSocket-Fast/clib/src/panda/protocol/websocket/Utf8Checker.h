#pragma once
#include <vector>
#include <panda/string.h>

namespace panda { namespace protocol { namespace websocket {

// Incremental UTF8 validator. Based on boost::beast

struct Utf8Checker {
    void reset () {
        need_ = 0;
        p_    = cp_;
    }

    bool finish () {
        auto const success = need_ == 0;
        reset();
        return success;
    }

    bool write (const string&);

    bool write (const std::vector<string>& v) {
        for (const auto& s : v) if (!write(s)) return false;
        return true;
    }

private:
    std::uint8_t  cp_[4];      // a temp buffer for the code point
    size_t        need_ = 0;   // chars we need to finish the code point
    std::uint8_t* p_    = cp_; // current position in temp buffer
};

}}}
