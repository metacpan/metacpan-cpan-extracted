
#ifndef POLYLINESEGMENT_H
#define POLYLINESEGMENT_H

#include "VectorTypes.h"

class PolylineSegment {

    public:
        float len, progress, ratio;
        Vector2i from, to, diff;
        PolylineSegment(Vector2i from, Vector2i to, float len);
        Vector2i solve(float t);
        bool operator< (float edge) const;

};

#endif
