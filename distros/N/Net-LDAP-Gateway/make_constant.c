
#include "common.h"

SV *
make_constant(char *name, STRLEN l, U32 value) {
    SV *sv = newSV(0);
    SvUPGRADE(sv, SVt_PVIV);
    sv_setpvn(sv, name, l);
    SvIOK_on(sv);
    SvIsUV_on(sv);
    SvUV_set(sv, value);
    SvREADONLY_on(sv);
    newCONSTSUB(gv_stashpv("Net::LDAP::Gateway::Constant", 1), name, sv);
    return sv;
}
