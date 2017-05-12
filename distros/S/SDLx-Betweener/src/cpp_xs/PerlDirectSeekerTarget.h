
#ifndef IPERLDIRECTSEEKERTARGET_H
#define IPERLDIRECTSEEKERTARGET_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "Types.h"
#include "VectorTypes.h"
#include "Vector.h"
#include "ISeekerTarget.h"


class PerlDirectSeekerTarget : public ISeekerTarget  {

    public:
        PerlDirectSeekerTarget(SV* target_sv) {
            target = (AV*) SvRV(target_sv);
        }
        ~PerlDirectSeekerTarget() {
        }
        Vector2i get_target_xy() {
            SV**     e1  = av_fetch(target, 0, 0);
            SV**     e2  = av_fetch(target, 1, 0);
            Vector2i xy  = { {(int) SvIV(*e1), (int) SvIV(*e2)} };
            return xy;
        }

     private:
        AV *target;

};

#endif
