#include <xs/export.h>
using namespace xs::exp;

#define EX_CROAK_NOPACKAGE(pack) croak("Panda::Export: context package '%" SVf "' doesn't exist", SVfARG(pack))

MODULE = Panda::Export                PACKAGE = Panda::Export
PROTOTYPES: DISABLE

void import (SV* ctx_class, ...) {
    HV* caller_stash = CopSTASH(PL_curcop);
    if (strEQ(SvPV_nolen(ctx_class), "Panda::Export")) {
        if (items < 2) XSRETURN(0);
        SV* arg = ST(1);
        if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVHV) create_constants(aTHX_ caller_stash, (HV*)SvRV(arg));
        else create_constants(aTHX_ caller_stash, &ST(1), items-1);
    }
    else {
        HV* ctx_stash = gv_stashsv(ctx_class, 0);
        if (ctx_stash == NULL) EX_CROAK_NOPACKAGE(ctx_class);
        if (items > 1) export_subs(aTHX_ ctx_stash, caller_stash, &ST(1), items-1);
        else           export_constants(aTHX_ ctx_stash, caller_stash);
    }
}    

SV* constants_list (SV* ctx_class) {
    HV* ctx_stash = gv_stashsv(ctx_class, 0);
    if (ctx_stash == NULL) EX_CROAK_NOPACKAGE(ctx_class);
    RETVAL = newRV((SV*)constants_list(aTHX_ ctx_stash));
}
