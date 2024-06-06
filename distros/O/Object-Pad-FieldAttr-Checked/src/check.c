#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"

#include "check.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "optree-additions.c.inc"

struct CheckData *Check_make_checkdata(pTHX_ SV *checker)
{
  HV *stash = NULL;
  CV *checkcv = NULL;

  if(SvROK(checker) && SvOBJECT(SvRV(checker)))
    stash = SvSTASH(SvRV(checker));
  else if(SvPOK(checker) && (stash = gv_stashsv(checker, GV_NOADD_NOINIT)))
    ; /* checker is package name */
  else if(SvROK(checker) && !SvOBJECT(SvRV(checker)) && SvTYPE(SvRV(checker)) == SVt_PVCV) {
    checkcv = (CV *)SvREFCNT_inc(SvRV(checker));
    SvREFCNT_dec(checker);
    checker = NULL;
  }
  else
    croak("Expected the checker expression to yield an object or code reference or package name; got %" SVf " instead",
      SVfARG(checker));

  if(!checkcv) {
    GV *methgv;
    if(!(methgv = gv_fetchmeth_pv(stash, "check", -1, 0)))
      croak("Expected that the checker expression can ->check");
    if(!GvCV(methgv))
      croak("Expected that methgv has a GvCV");
    checkcv = (CV *)SvREFCNT_inc(GvCV(methgv));
  }

  struct CheckData *data;
  Newx(data, 1, struct CheckData);

  data->checkobj = checker;
  data->checkcv  = checkcv;

  return data;
}

OP *Check_make_assertop(pTHX_ struct CheckData *data, OP *argop)
{
  OP *checkop = data->checkobj
    ? /* checkcv($checker, ARGOP) ... */
      newLISTOPn(OP_ENTERSUB, OPf_WANT_SCALAR|OPf_STACKED,
        newSVOP(OP_CONST, 0, SvREFCNT_inc(data->checkobj)),
        argop,
        newSVOP(OP_CONST, 0, SvREFCNT_inc(data->checkcv)),
        NULL)
    : /* checkcv(ARGOP) ... */
      newLISTOPn(OP_ENTERSUB, OPf_WANT_SCALAR|OPf_STACKED,
        argop,
        newSVOP(OP_CONST, 0, SvREFCNT_inc(data->checkcv)),
        NULL);

  return newLOGOP(OP_OR, 0,
    checkop,
    /* ... or die MESSAGE */
    newLISTOPn(OP_DIE, 0,
      newSVOP(OP_CONST, 0, SvREFCNT_inc(data->assertmess)),
      NULL));
}

bool Check_check_value(pTHX_ struct CheckData *data, SV *value)
{
  dSP;

  ENTER;
  SAVETMPS;

  EXTEND(SP, 2);
  PUSHMARK(SP);
  if(data->checkobj)
    PUSHs(sv_mortalcopy(data->checkobj));
  PUSHs(value); /* Yes we're pushing the SV itself */
  PUTBACK;

  call_sv((SV *)data->checkcv, G_SCALAR);

  SPAGAIN;

  bool ok = SvTRUEx(POPs);

  FREETMPS;
  LEAVE;

  return ok;
}

void Check_assert_value(pTHX_ struct CheckData *data, SV *value)
{
  if(check_value(data, value))
    return;

  croak_sv(data->assertmess);
}
