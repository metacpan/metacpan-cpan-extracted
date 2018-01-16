#include <xs/xs.h>
#include <xs/XSCallbackDispatcher.h>
#ifdef TEST_FULL
#  include "t/src/test.h"
#endif

STATIC xs::payload_marker_t marker;

MODULE = Panda::XS                PACKAGE = Panda::XS
PROTOTYPES: DISABLE

void sv_payload_attach (SV* sv, SV* payload) {
    xs::sv_payload_detach(aTHX_ sv, &marker);
    xs::sv_payload_attach(aTHX_ sv, payload, &marker);
}    
    
bool sv_payload_exists (SV* sv) {
    RETVAL = xs::sv_payload_exists(aTHX_ sv, &marker);
}   
    
SV* sv_payload (SV* sv) {
    RETVAL = xs::sv_payload_sv(aTHX_ sv, &marker);
    if (!RETVAL) XSRETURN_UNDEF;
    else SvREFCNT_inc_simple_void_NN(RETVAL);
}    

int sv_payload_detach (SV* sv) {
    RETVAL = xs::sv_payload_detach(aTHX_ sv, &marker);
}

void rv_payload_attach (SV* rv, SV* payload) {
    if (!SvROK(rv)) croak("Panda::XS::rv_payload_attach: argument is not a reference"); 
    xs::rv_payload_detach(aTHX_ rv, &marker);
    xs::rv_payload_attach(aTHX_ rv, payload, &marker);
}    
    
bool rv_payload_exists (SV* rv) {
    if (!SvROK(rv)) croak("Panda::XS::rv_payload_exists: argument is not a reference"); 
    RETVAL = xs::rv_payload_exists(aTHX_ rv, &marker);
}   
    
SV* rv_payload (SV* rv) {
    if (!SvROK(rv)) croak("Panda::XS::rv_payload: argument is not a reference"); 
    RETVAL = xs::rv_payload_sv(aTHX_ rv, &marker);
    if (!RETVAL) XSRETURN_UNDEF;
    else SvREFCNT_inc_simple_void_NN(RETVAL);
}    

int rv_payload_detach (SV* rv) {
    if (!SvROK(rv)) croak("Panda::XS::rv_payload_detach: argument is not a reference"); 
    RETVAL = xs::rv_payload_detach(aTHX_ rv, &marker);
}

void any_payload_attach (SV* sv, SV* payload) {
    if (SvROK(sv)) {
        xs::sv_payload_detach(aTHX_ SvRV(sv), &marker);
        xs::sv_payload_attach(aTHX_ SvRV(sv), payload, &marker);
    }
    else {
        xs::sv_payload_detach(aTHX_ sv, &marker);
        xs::sv_payload_attach(aTHX_ sv, payload, &marker);
    }
}
    
bool any_payload_exists (SV* sv) {
    if (SvROK(sv)) RETVAL = xs::sv_payload_exists(aTHX_ SvRV(sv), &marker);
    else RETVAL = xs::sv_payload_exists(aTHX_ sv, &marker);
}   
    
SV* any_payload (SV* sv) {
    if (SvROK(sv)) RETVAL = xs::sv_payload_sv(aTHX_ SvRV(sv), &marker);
    else RETVAL = xs::sv_payload_sv(aTHX_ sv, &marker);

    if (!RETVAL) XSRETURN_UNDEF;
    else SvREFCNT_inc_simple_void_NN(RETVAL);
}    

int any_payload_detach (SV* sv) {
    if (SvROK(sv)) RETVAL = xs::sv_payload_detach(aTHX_ SvRV(sv), &marker); 
    else RETVAL = xs::sv_payload_detach(aTHX_ sv, &marker);
}


void obj2hv (SV* rv) {
    if (!SvROK(rv)) croak("Panda::XS::obj2hv: argument is not a reference");
    SV* obj = SvRV(rv);
    if (SvOK(obj)) croak("Panda::XS::obj2hv: only references to undefs can be upgraded");
    SvUPGRADE(obj, SVt_PVHV);
}

void obj2av (SV* rv) {
    if (!SvROK(rv)) croak("Panda::XS::obj2av: argument is not a reference");
    SV* obj = SvRV(rv);
    if (SvOK(obj)) croak("Panda::XS::obj2av: only references to undefs can be upgraded");
    SvUPGRADE(obj, SVt_PVAV);
}

INCLUDE: XSCallbackDispatcher.xsi

#ifdef TEST_FULL

INCLUDE: t/src/test.xsi

#endif
