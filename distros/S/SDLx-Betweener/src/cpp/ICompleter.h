
#ifndef ICOMPLETER_H
#define ICOMPLETER_H

#include "Types.h"

class ICompleter {

    public:
        virtual ~ICompleter() {}
        virtual void animation_complete(Uint32 complete_time) = 0;

};

#endif
