
#ifndef IPERLCALLBACKPROXY_H
#define IPERLCALLBACKPROXY_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "PerlBaseCodeProxy.h"

template<typename T,int DIM>
class PerlCallbackProxy : public PerlBaseCodeProxy<T,DIM>  {

    public:
        // cb is rv on callback
        PerlCallbackProxy(SV *cb) {
            // strong ref clone of callback
            callback = newSVsv(cb);
        }
        ~PerlCallbackProxy() {
            SvREFCNT_dec(callback);
        }
    protected:
        void update_perl(SV *out) {
            dSP; ENTER; SAVETMPS;PUSHMARK(SP); EXTEND(SP, 1);
            XPUSHs(sv_2mortal(out));
            PUTBACK;
            call_sv(callback, G_DISCARD);
            FREETMPS; LEAVE;
        }
    private:
        SV *callback;

};

#endif
