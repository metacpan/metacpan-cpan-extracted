#ifndef EASYXS_STRUCTREF_H
#define EASYXS_STRUCTREF_H 1

#include "init.h"

#define exs_new_structref(type, classname) _exs_new_structref_f(aTHX_ sizeof(type), classname)

#define exs_structref_ptr(svrv) ( (void *) SvPVX( SvRV(svrv) ) )

static inline SV* _exs_new_structref_f (pTHX_ unsigned size, const char* classname) {

    SV* referent = newSV(size);
    SvPOK_on(referent);

    SV* reference = newRV_noinc(referent);
    sv_bless(reference, gv_stashpv(classname, FALSE));

    return reference;
}

#endif
