#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

static XOP eqi_xop;
static XOP nei_xop;

static OP *
pp_eqi(pTHX)
{
    dSP;
    SV *b = POPs;
    SV *a = TOPs;
    const char *sa, *sb;
    STRLEN la, lb;
    I32 result;

    sv_utf8_upgrade(a);
    sv_utf8_upgrade(b);
    sa = SvPVutf8(a, la);
    sb = SvPVutf8(b, lb);
    char *ea = (char *)(sa + la);
    char *eb = (char *)(sb + lb);
    result = foldEQ_utf8(sa, &ea, (UV)la, TRUE,
                         sb, &eb, (UV)lb, TRUE);
    SETs(sv_2mortal(newSViv(result ? 1 : 0)));
    RETURN;
}

static OP *
pp_nei(pTHX)
{
    dSP;
    SV *b = POPs;
    SV *a = TOPs;
    const char *sa, *sb;
    STRLEN la, lb;
    I32 result;

    sv_utf8_upgrade(a);
    sv_utf8_upgrade(b);
    sa = SvPVutf8(a, la);
    sb = SvPVutf8(b, lb);
    char *ea = (char *)(sa + la);
    char *eb = (char *)(sb + lb);
    result = foldEQ_utf8(sa, &ea, (UV)la, TRUE,
                             sb, &eb, (UV)lb, TRUE);
    SETs(sv_2mortal(newSViv(result ? 0 : 1)));
    RETURN;
}

static OP *
eqi_build_op(pTHX_ SV **opdata, OP *lhs, OP *rhs,
             struct Perl_custom_infix *def)
{
    OP *o;
    PERL_UNUSED_ARG(opdata);
    PERL_UNUSED_ARG(def);
    o = newBINOP(OP_CUSTOM, 0, lhs, rhs);
    o->op_ppaddr = pp_eqi;
    return o;
}

static OP *
nei_build_op(pTHX_ SV **opdata, OP *lhs, OP *rhs,
             struct Perl_custom_infix *def)
{
    OP *o;
    PERL_UNUSED_ARG(opdata);
    PERL_UNUSED_ARG(def);
    o = newBINOP(OP_CUSTOM, 0, lhs, rhs);
    o->op_ppaddr = pp_nei;
    return o;
}

MODULE = Syntax::Infix::EqualityInsensitive    PACKAGE = Syntax::Infix::EqualityInsensitive

BOOT:
    XopENTRY_set(&eqi_xop, xop_name,  "eqi");
    XopENTRY_set(&eqi_xop, xop_desc,  "case-insensitive string equality");
    XopENTRY_set(&eqi_xop, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_eqi, &eqi_xop);

    XopENTRY_set(&nei_xop, xop_name,  "nei");
    XopENTRY_set(&nei_xop, xop_desc,  "case-insensitive string inequality");
    XopENTRY_set(&nei_xop, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_nei, &nei_xop);

IV
_eqi_build_op_addr()
    CODE:
        RETVAL = PTR2IV(eqi_build_op);
    OUTPUT:
        RETVAL

IV
_nei_build_op_addr()
    CODE:
        RETVAL = PTR2IV(nei_build_op);
    OUTPUT:
        RETVAL
