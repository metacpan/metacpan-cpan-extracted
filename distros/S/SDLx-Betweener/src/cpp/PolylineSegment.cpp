
#include "PolylineSegment.h"

PolylineSegment::PolylineSegment(Vector2i from, Vector2i to, float len) :
    len(len),
    progress(0), ratio(0),
    from(from), to(to), diff(to - from)
    {}

Vector2i PolylineSegment::solve(float t) {
    return from + diff * t;
}

bool PolylineSegment::operator< (float edge) const {
    return progress < edge;
}


