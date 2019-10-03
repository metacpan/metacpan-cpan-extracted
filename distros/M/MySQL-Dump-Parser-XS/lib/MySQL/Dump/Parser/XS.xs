#include "use_perl.h"
#include "debug.h"
#include "macro.h"
#include "context.h"
#include "state.h"
#include "parser.h"
#include "xsutil.h"

MODULE = MySQL::Dump::Parser::XS    PACKAGE = MySQL::Dump::Parser::XS

PROTOTYPES: DISABLE

void
new(...)
PPCODE:
{
  if (items != 1) {
    croak("Invalid argument count: %d", items);
  }
  const char *klass = SvPV_nolen(ST(0));

  HV* state = newState(aTHX);
  SV* self  = newRV_inc_mortal((SV*)state);
  sv_bless(self, gv_stashpv(klass, 1));
  SvREADONLY_on(self);
  XPUSHs(self);
  XSRETURN(1);
}

void
reset(...)
PPCODE:
{
  if (items != 1) {
    croak("Invalid argument count: %d", items);
  }
  HV* state = (HV*)SvRV(ST(0));
  hv_clear(state);
  initState(aTHX_ state);
  XSRETURN(0);
}

void
parse(...)
PPCODE:
{
  if (items != 2) {
    croak("Invalid argument count: %d", items);
  }
  HV* state = (HV*)SvRV(ST(0));
  SV* src   = ST(1);

  AV* ret = parse(aTHX_ state, SvPV_nolen(src));
  if (ret == NULL) {
    XSRETURN(0);
    return;
  }

  I32 size = 0;
  XSUTIL_AV_FOREACH(ret, entry, {
    XPUSHs(entry);
    size++;
  });
  XSRETURN(size);
}

void
current_target_table(...)
PPCODE:
{
  if (items != 1) {
    croak("Invalid argument count: %d", items);
  }
  HV* state = (HV*)SvRV(ST(0));
  SV* table = get_table(aTHX_ state);
  XPUSHs(table);
  XSRETURN(1);
}

void
columns(...)
PPCODE:
{
  if (items != 2) {
    croak("Invalid argument count: %d", items);
  }
  HV* state = (HV*)SvRV(ST(0));
  SV* table = ST(1);

  HV* schema  = get_or_create_schema(aTHX_ state, table);
  AV* columns = get_or_create_columns(aTHX_ schema);

  I32 size = 0;
  XSUTIL_AV_FOREACH(columns, entry, {
    XPUSHs(entry);
    size++;
  });
  XSRETURN(size);
}

void
tables(...)
PPCODE:
{
  if (items != 1) {
    croak("Invalid argument count: %d", items);
  }

  HV* state = (HV*)SvRV(ST(0));
  SV** ssv = XSUTIL_HV_FETCH(state, "schema");
  if (! ssv) {
    XSRETURN(0);
    return;
  }

  I32 size = 0;
  XSUTIL_HV_FOREACH((HV*)SvRV(*ssv), entry, {
    SV* key = hv_iterkeysv(entry);
    XPUSHs(key);
    size++;
  });
  XSRETURN(size);
}
