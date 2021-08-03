/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "object_pad.h"

static int magic_get(pTHX_ SV *sv, MAGIC *mg);
static int magic_set(pTHX_ SV *sv, MAGIC *mg);

static MGVTBL vtbl = {
  .svt_get = &magic_get,
  .svt_set = &magic_set,
};

static int magic_get(pTHX_ SV *sv, MAGIC *mg)
{
  SV *self       = mg->mg_obj;
  SV *methodname = (SV *)mg->mg_ptr;

  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  PUSHs(self);
  PUTBACK;

  call_method(SvPV_nolen(methodname), G_SCALAR);

  SPAGAIN;

  SV *value = POPs;

  sv_setsv_nomg(sv, value);

  FREETMPS;
  LEAVE;

  /* Now disarm the magic so it won't run again */
  mg_freeext(sv, PERL_MAGIC_ext, &vtbl);

  return 1;
}

static int magic_set(pTHX_ SV *sv, MAGIC *mg)
{
  /* Now disarm the magic so it won't run again */
  mg_freeext(sv, PERL_MAGIC_ext, &vtbl);

  return 1;
}

static void lazyinit_post_initslot(pTHX_ SlotMeta *slotmeta, SV *hookdata, SV *slot)
{
  SV *weakself = newSVsv(PAD_SVl(PADIX_SELF));
  sv_rvweaken(weakself);

  sv_magicext(slot, weakself, PERL_MAGIC_ext, &vtbl, (char *)hookdata, HEf_SVKEY);
}

static const struct SlotHookFuncs lazyinit_hooks = {
  .flags = OBJECTPAD_FLAG_ATTR_MUST_VALUE,
  .permit_hintkey = "Object::Pad::SlotAttr::LazyInit/LazyInit",
  .post_initslot = &lazyinit_post_initslot,
};

MODULE = Object::Pad::SlotAttr::LazyInit    PACKAGE = Object::Pad::SlotAttr::LazyInit

BOOT:
  register_slot_attribute("LazyInit", &lazyinit_hooks);
