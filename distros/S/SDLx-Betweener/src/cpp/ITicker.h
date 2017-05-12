
#ifndef ITICKER_H
#define ITICKER_H

#include "Types.h"

class ITicker {

    public:
        virtual ~ITicker() {}
        virtual void tick(Uint32 now) = 0;
        virtual void stop() = 0;

};

#endif
