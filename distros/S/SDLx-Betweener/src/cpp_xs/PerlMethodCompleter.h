
#ifndef IPERLMETHODCOMPLETER_H
#define IPERLMETHODCOMPLETER_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "Types.h"
#include "ICompleter.h"

class PerlMethodCompleter : public ICompleter  {

    public:
        PerlMethodCompleter(SV* args) {
           AV* on_av      = (AV*) SvRV(args);
           SV** method_sv = av_fetch(on_av, 0, 0);
           SV** target_sv = av_fetch(on_av, 1, 0);
           method         = strdup((char*) SvPV_nolen(*method_sv));
           // weak ref on target object
           target         = newRV_inc(SvRV(*target_sv));
           sv_rvweaken(target);
        }
        ~PerlMethodCompleter() {
            delete method;
            SvREFCNT_dec(target);
        }
        void animation_complete(Uint32 now) {
            dSP; ENTER; SAVETMPS;PUSHMARK(SP); EXTEND(SP, 2);
            XPUSHs(target);
            XPUSHs(sv_2mortal(newSViv(now)));
            PUTBACK;
            call_method(method, G_DISCARD);
            FREETMPS; LEAVE;

        }
    private:
        SV   *target;
        char *method;

};

#endif
