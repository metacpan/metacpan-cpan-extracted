
#ifndef ITWEENFORM_H
#define ITWEENFORM_H

#include "ITicker.h"

class ITweenForm {

    public:
        virtual ~ITweenForm() {}
        virtual void start(float t) = 0;
        virtual void tick(float t) = 0;

};

#endif
