#pragma once
#include "Body.h"

namespace panda { namespace protocol { namespace http {

struct BodyGuard {
    const static constexpr std::size_t body_size = sizeof (Body);
    char body_copy[body_size];
    Body *original;

    BodyGuard(): original{nullptr} {}
    BodyGuard(Body *source);
    BodyGuard(const BodyGuard&) = delete;
    BodyGuard(BodyGuard&& other);

    ~BodyGuard();
};


}}}
