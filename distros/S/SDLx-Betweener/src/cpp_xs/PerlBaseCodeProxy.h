
#ifndef IPERLBASECODEPROXY_H
#define IPERLBASECODEPROXY_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "Types.h"
#include "VectorTypes.h"
#include "Vector.h"
#include "IProxy.h"

template<typename T,int DIM>
class PerlBaseCodeProxy : public IProxy<T,DIM>  {

    public:
        virtual ~PerlBaseCodeProxy() {}

        void update(Vector1i& value) {
            SV* out = newSViv(value[0]);
            update_perl(out);
        }

        void update(Vector1f& value) {
            SV* out = newSVnv(value[0]);
            update_perl(out);
        }

        void update(Vector2i& value) {
            AV* arr = newAV();
            av_extend(arr, 1);
            av_store(arr, 0, newSViv(value[0]));
            av_store(arr, 1, newSViv(value[1]));
            update_perl((SV*) newRV_noinc((SV*) arr));
        }

        void update(Vector4c& value) {
            Uint32 color = (value[0] << 24) |
                           (value[1] << 16) |
                           (value[2] <<  8) |
                            value[3];
            SV* out = newSViv(color);
            update_perl(out);
        }
    protected:
        virtual void update_perl(SV *out) = 0;

};

#endif
