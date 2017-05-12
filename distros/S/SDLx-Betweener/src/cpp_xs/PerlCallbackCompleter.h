
#ifndef IPERLCALLBACKCOMPLETER_H
#define IPERLCALLBACKCOMPLETER_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "Types.h"
#include "ICompleter.h"

class PerlCallbackCompleter : public ICompleter  {

    public:
        PerlCallbackCompleter(SV *args) {
            callback = newSVsv(args);
        }
        ~PerlCallbackCompleter() {
            SvREFCNT_dec(callback);
        }
        void animation_complete(Uint32 now) {
            dSP; ENTER; SAVETMPS;PUSHMARK(SP); EXTEND(SP, 1);
            XPUSHs(sv_2mortal(newSViv(now)));
            PUTBACK;
            call_sv(callback, G_DISCARD);
            FREETMPS; LEAVE;
        }
    private:
        SV *callback;

};

#endif
