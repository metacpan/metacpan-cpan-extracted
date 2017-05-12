
#ifndef LINEARPATH_H
#define LINEARPATH_H

#include "VectorTypes.h"
#include "IPath.h"

class LinearPath : public IPath {

    public:
        LinearPath(Vector2i from, Vector2i to);
        Vector2i solve(float t);
    private:
        Vector2i from, to, diff;

};

#endif
