#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

MODULE = Object::Accessor::XS	PACKAGE = Object::Accessor::XS	

PROTOTYPES: DISABLE

SV *
new (class)
	char *	class
PPCODE:
{
    ST(0) = sv_bless(newRV_noinc((SV*)newHV()), gv_stashpv(class, TRUE));
    XSRETURN(1);
}

void
_debug (message)
	SV *	message
PPCODE:
{
       if (!SvTRUE(get_sv("DEBUG", TRUE)))
         return;

       ENTER;
       SAVETMPS;

       SV* carplevel = get_sv("Carp::CarpLevel", TRUE);
       save_item(carplevel);
       sv_inc(carplevel);

       PUSHMARK(SP);
       XPUSHs(sv_mortalcopy(message));
       PUTBACK;

       call_pv("carp", G_VOID|G_DISCARD);

       FREETMPS;
       LEAVE;
}

void
mk_accessors (self, ...)
	SV *	self
PPCODE:
{
      if(items > 1 && SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV) {
        HV* object = (HV*)SvRV(self);

        IV i;
        for (i = 1; i < items; i++) {
          if (!hv_exists_ent(object, ST(i), 0))
            hv_store_ent(object, ST(i), newSV(0), 0);
        }
        XSRETURN_YES;
      } else {
        XSRETURN_UNDEF;
      }
}

void
mk_flush (self)
	SV *	self
PPCODE:
{
  if(SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV) {
    HV* object = (HV*)SvRV(self);

    (void)hv_iterinit(object);
    IV i; HE* element;
    while (element = hv_iternext(object)) {
      sv_setsv(hv_iterval(object, element), &PL_sv_undef);
    }
    XSRETURN_YES;
  } else {
    XSRETURN_UNDEF;
  }
}

void
ls_accessors (self)
	SV *	self
PPCODE:
{
      if(SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV) {
        HV* object = (HV*)SvRV(self);
	AV* keys = newAV();

	(void)hv_iterinit(object);
	HE* iter; SV* key;
	while (iter = hv_iternext(object)) {
          key = hv_iterkeysv(iter);
	  SvREFCNT_inc(key);
	  av_push(keys, key);
        }
        sortsv(AvARRAY(keys), av_len(keys) + 1, Perl_sv_cmp);
	
	IV i; IV len = av_len(keys) + 1;
	for (i=0; i<len; i++) {
	    ST(i) = *av_fetch(keys, i, 0);
	}
        XSRETURN(i);
      } else {
        XSRETURN_UNDEF;
      }
}

void
DESTROY (self)
	SV *	self
PPCODE:
{
    /* return; */
}
