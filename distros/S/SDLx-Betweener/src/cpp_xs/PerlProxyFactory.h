
#ifndef PERLPROXYFACTORY_H
#define PERLPROXYFACTORY_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "IProxy.h"
#include "PerlDirectProxy.h"
#include "PerlCallbackProxy.h"
#include "PerlMethodProxy.h"

template<typename T,int DIM>
IProxy<T,DIM> *Build_Proxy(int proxy_type, SV *proxy_args) {
    IProxy<T,DIM> *proxy;
         if (proxy_type == 1) { proxy = new PerlDirectProxy<T,DIM>(proxy_args); }
    else if (proxy_type == 2) { proxy = new PerlCallbackProxy<T,DIM>(proxy_args); }
    else                      { proxy = new PerlMethodProxy<T,DIM>(proxy_args); }
    return proxy;
}


#endif
