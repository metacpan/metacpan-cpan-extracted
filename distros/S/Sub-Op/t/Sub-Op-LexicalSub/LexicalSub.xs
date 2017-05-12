/* This file is part of the Sub::Op Perl module.
 * See http://search.cpan.org/dist/Sub-Op/ */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define __PACKAGE__     "Sub::Op::LexicalSub"
#define __PACKAGE_LEN__ (sizeof(__PACKAGE__)-1)

#include "sub_op.h"

STATIC HV *sols_map = NULL;

STATIC OP *sols_check(pTHX_ OP *o, void *ud_) {
 char buf[sizeof(void*)*2+1];
 SV *cb = ud_;

 (void) hv_store(sols_map, buf, sprintf(buf, "%"UVxf, PTR2UV(o)), cb, 0);

 return o;
}

STATIC OP *sols_pp(pTHX) {
 dSP;
 dMARK;
 SV *cb;
 int i, items;

 {
  char buf[sizeof(void*)*2+1];
  SV **svp;
  svp = hv_fetch(sols_map, buf, sprintf(buf, "%"UVxf, PTR2UV(PL_op)), 0);
  if (!svp)
   RETURN;
  cb = *svp;
 }

 ENTER;
 SAVETMPS;

 PUSHMARK(MARK);

 items = call_sv(cb, G_ARRAY);

 SPAGAIN;
 for (i = 0; i < items; ++i)
  SvREFCNT_inc(SP[-i]);
 PUTBACK;

 FREETMPS;
 LEAVE;

 return NORMAL;
}

/* --- XS ------------------------------------------------------------------ */

MODULE = Sub::Op::LexicalSub      PACKAGE = Sub::Op::LexicalSub

PROTOTYPES: ENABLE

BOOT:
{
 sols_map = newHV();
}

void
_init(SV *name, SV *cb)
PROTOTYPE: $$
PREINIT:
 sub_op_config_t c;
PPCODE:
 if (SvROK(cb)) {
  cb = SvRV(cb);
  if (SvTYPE(cb) >= SVt_PVCV) {
   c.name  = SvPV_const(name, c.namelen);
   c.check = sols_check;
   c.ud    = SvREFCNT_inc(cb);
   c.pp    = sols_pp;
   sub_op_register(aTHX_ &c);
  }
 }
 XSRETURN(0);
