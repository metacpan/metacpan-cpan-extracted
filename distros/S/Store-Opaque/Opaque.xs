#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

typedef SV MyOpaqueObject;

MODULE = Store::Opaque		PACKAGE = Store::Opaque		


MyOpaqueObject*
new(CLASS)
    char *CLASS
  CODE:
    RETVAL = (SV*)newHV();
  OUTPUT:
    RETVAL

SV*
_get(self, key)
    MyOpaqueObject* self
    SV* key
  PREINIT:
    HE* entry;
  CODE:
    entry = hv_fetch_ent((HV*)self, key, 0, 0);
    if (entry != NULL)
      RETVAL = newSVsv( HeVAL(entry) );
    else
      RETVAL = &PL_sv_undef;
  OUTPUT: RETVAL

void
_set(self, key, value)
    MyOpaqueObject* self
    SV* key
    SV* value
  CODE:
    hv_store_ent((HV*)self, key, newSVsv(value), 0);


void
DESTROY(self)
    MyOpaqueObject* self
  CODE:
    SvREFCNT_dec((HV*)self);

