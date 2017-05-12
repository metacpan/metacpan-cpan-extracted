
#ifndef ISEEKERTARGET_H
#define ISEEKERTARGET_H

#include "VectorTypes.h"

class ISeekerTarget {

    public:
        virtual ~ISeekerTarget() {}
        virtual Vector2i get_target_xy() = 0;

};

#endif
