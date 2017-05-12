
#ifndef IPERLDIRECTPROXY_H
#define IPERLDIRECTPROXY_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "Types.h"
#include "VectorTypes.h"
#include "Vector.h"
#include "IProxy.h"


template<typename T,int DIM>
class PerlDirectProxy : public IProxy<T,DIM>  {

    public:
        // val is rv on sv or av
        PerlDirectProxy(SV* val) {
            // weak ref on target
            target = SvRV(val);
        }
        ~PerlDirectProxy() {
        }
        void update(Vector1i& value) {
            SvIV_set(target, value[0]);
        }
        void update(Vector1f& value) {
            SvNV_set(target, value[0]);
        }
        void update(Vector2i& value) {
            AV* arr = (AV*) target;
            SV** v1 = av_fetch(arr, 0, 0);
            SV** v2 = av_fetch(arr, 1, 0);
            SvIV_set(*v1, value[0]);
            SvIV_set(*v2, value[1]);
        }
        void update(Vector4c& value) {
            Uint32 color = (value[0] << 24) |
                           (value[1] << 16) |
                           (value[2] <<  8) |
                            value[3];
            SvIV_set(target, color);
        }


     private:
        SV *target;

};

#endif
