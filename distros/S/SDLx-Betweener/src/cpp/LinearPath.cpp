
#include "LinearPath.h"

LinearPath::LinearPath(Vector2i from, Vector2i to) :
    from(from), to(to), diff(to - from) {}

Vector2i LinearPath::solve(float t) {
    return from + diff * t;
}


