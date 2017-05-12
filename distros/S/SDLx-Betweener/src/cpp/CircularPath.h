
#ifndef CIRCULARPATH_H
#define CIRCULARPATH_H

#include "VectorTypes.h"
#include "IPath.h"

class CircularPath : public IPath {

    public:
        CircularPath(Vector2i center, int radius, float from_angle, float to_angle);
        Vector2i solve(float t);
    private:
        Vector2i center;
        int radius;
        float from_angle, to_angle;
        float angle_delta;

};

#endif
