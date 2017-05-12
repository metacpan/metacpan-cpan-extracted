
#ifndef IPROXY_H
#define IPROXY_H

#include "Vector.h"

template<class T,int DIM>
class IProxy {

    public:
        virtual ~IProxy() {}
        virtual void update(Vector<T,DIM>& value) = 0;

};

#endif
