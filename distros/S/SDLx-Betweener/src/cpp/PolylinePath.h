
#ifndef POLYLINEPATH_H
#define POLYLINEPATH_H

#include <stdlib.h>
#include <vector>
#include "VectorTypes.h"
#include "IPath.h"
#include "PolylineSegment.h"

class PolylinePath : public IPath {

    public:
        PolylinePath(std::vector<Vector2i> points);
        Vector2i solve(float t);
    private:
        std::vector<PolylineSegment> segments;

};

#endif
