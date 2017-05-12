
#include "ROOTIncludes.h"

#include "PerlCallback.h"

#include "SOOTDebug.h"
#include <string>
#include <iostream>

using namespace std;

namespace SOOT {

  void
  StorePerlCallback(pTHX_ long unsigned int id, SV* callback)
  {
    HV* storage = get_hv("SOOT::TExec::_CallbackStorage", GV_ADD);
    SV* key = newSVuv(id);
    SvREFCNT_inc(callback);
    hv_store_ent(storage, key, callback, 0);
    sv_2mortal(key);
  }

  void
  ExecPerlCallback(pTHX_ SV* callback)
  {
    dSP;
    PUSHMARK(SP);
    call_sv(callback, G_DISCARD|G_NOARGS|G_VOID);
  }

  int
  ExecStoredPerlCallback(pTHX_ long unsigned int id)
  {
    dSP;
    PUSHMARK(SP);

    HV* storage = get_hv("SOOT::TExec::_CallbackStorage", GV_ADD);
    SV* key = newSVuv(id);
    HE* callback_he = hv_fetch_ent(storage, key, 0, 0);
    sv_2mortal(key);
    if (callback_he && HeVAL(callback_he)) {
      SV* callback = HeVAL(callback_he);
      call_sv(callback, G_DISCARD|G_NOARGS|G_VOID);
      return 1;
    }
    else
      return 0;
  }

  void
  ClearStoredPerlCallback(pTHX_ long unsigned int id)
  {
    HV* storage = get_hv("SOOT::TExec::_CallbackStorage", GV_ADD);
    SV* key = newSVuv(id);
    SV* oldval = hv_delete_ent(storage, key, 0, 0);
    if (oldval && oldval != &PL_sv_undef) {
      SvREFCNT_dec(oldval);
    }
    sv_2mortal(key);
  }

} // end namespace SOOT

