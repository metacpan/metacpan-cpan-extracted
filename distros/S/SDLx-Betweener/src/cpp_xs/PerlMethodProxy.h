
#ifndef PERLMETHODPROXY_H
#define PERLMETHODPROXY_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "PerlBaseCodeProxy.h"

template<typename T,int DIM>
class PerlMethodProxy : public PerlBaseCodeProxy<T,DIM>  {

    public:
        // on_sv is array ref of method, target
        PerlMethodProxy(SV *on_sv) {
           AV* on_av      = (AV*) SvRV(on_sv);
           SV** method_sv = av_fetch(on_av, 0, 0);
           SV** target_sv = av_fetch(on_av, 1, 0);
           method         = strdup((char*) SvPV_nolen(*method_sv));
           // weak ref on target object
           target         = newRV_inc(SvRV(*target_sv));
           sv_rvweaken(target);
        }
        ~PerlMethodProxy() {
            delete method;
            SvREFCNT_dec(target);
        }
    protected:
        void update_perl(SV *out) {
            dSP; ENTER; SAVETMPS;PUSHMARK(SP); EXTEND(SP, 2);
            XPUSHs(target);
            XPUSHs(sv_2mortal(out));
            PUTBACK;
            call_method(method, G_DISCARD);
            FREETMPS; LEAVE;
        }
    private:
        SV   *target;
        char *method;

};

#endif
