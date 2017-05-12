
#ifndef IPATH_H
#define IPATH_H

#include "VectorTypes.h"

class IPath {

    public:
        virtual ~IPath() {}
        virtual Vector2i solve(float t) = 0;

};

#endif
