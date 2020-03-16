#include "BodyGuard.h"

namespace panda { namespace protocol { namespace http {

BodyGuard::BodyGuard(Body *source):original{source} {
    new(body_copy)Body(*source);
}

BodyGuard::BodyGuard(BodyGuard&& other) {
    if (other.original) {
        original = other.original;
        Body* source = reinterpret_cast<Body*>(&other.body_copy);
        new(body_copy)Body(std::move(*source));
        other.original = nullptr;
        source->~Body();
    } else {
        original = nullptr;
    }
}


BodyGuard::~BodyGuard() {
    if (original) {
        Body* source = reinterpret_cast<Body*>(&body_copy);
        *original = std::move(*source);
        source->~Body();
    }
}

}}}
