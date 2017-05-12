
#ifndef ICLOCK_H
#define ICLOCK_H

#include "ITicker.h"
#include "Types.h"

class IClock {

    public:
        virtual ~IClock() {}
        virtual void   register_ticker(ITicker *ticker) = 0;
        virtual void unregister_ticker(ITicker *ticker) = 0;

};

#endif
