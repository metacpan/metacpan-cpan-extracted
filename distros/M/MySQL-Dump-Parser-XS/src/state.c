#include "state.h"
#include "context.h"
#include "debug.h"
#include "xsutil.h"

HV* newState (pTHX) {
  return initState(aTHX_ newHV_mortal());
}

HV* initState (pTHX_ HV* state) {
  XSUTIL_HV_STORE_REF(state,   "schema",   (SV*)newHV_mortal());
  XSUTIL_HV_STORE_NOINC(state, "table",    &PL_sv_undef);
  XSUTIL_HV_STORE(state,       "context",  XSUTIL_NEW_SVIV_MORTAL(CONTEXT_GLOBAL));
  XSUTIL_HV_STORE(state,       "_context", XSUTIL_NEW_SVIV_MORTAL(CONTEXT_GLOBAL));
  XSUTIL_HV_STORE(state,       "_nest",    XSUTIL_NEW_SVIV_MORTAL(0));
  XSUTIL_HV_STORE(state,       "nest",     XSUTIL_NEW_SVIV_MORTAL(0));
  return state;
}

SV* _get_parser_context (pTHX_ HV* state) {
  SV** ssv = XSUTIL_HV_FETCH(state, "context");
  if (ssv) {
    return *ssv;
  }
  else {
    sv_dump((SV*)state);
    croak("Cannot get context.");
  }
}

SV* _get_parser_recent_context (pTHX_ HV* state) {
  SV** ssv = XSUTIL_HV_FETCH(state, "_context");
  if (ssv) {
    return *ssv;
  }
  else {
    sv_dump((SV*)state);
    croak("Cannot get recent context.");
  }
}

SV* _get_nest (pTHX_ HV* state) {
  SV** ssv = XSUTIL_HV_FETCH(state, "nest");
  if (ssv) {
    return *ssv;
  }
  else {
    sv_dump((SV*)state);
    croak("Cannot get nest.");
  }
}

SV* _get_recent_nest (pTHX_ HV* state) {
  SV** ssv = XSUTIL_HV_FETCH(state, "nest");
  if (ssv) {
    return *ssv;
  }
  else {
    sv_dump((SV*)state);
    croak("Cannot get nest.");
  }
}

void set_parser_context (pTHX_ HV* state, const IV context) {
  {
    SV* context_sv  = _get_parser_context(aTHX_ state);
    SV* _context_sv = _get_parser_recent_context(aTHX_ state);
    sv_setiv(_context_sv, SvIV(context_sv));
    sv_setiv(context_sv,  context);
    DEBUG_OUT("context: %d\n", (int)SvIV(context_sv));
  }
  {
    SV* nest_sv  = _get_nest(aTHX_ state);
    SV* _nest_sv = _get_recent_nest(aTHX_ state);
    sv_setiv(_nest_sv, SvIV(nest_sv));
    sv_setiv(nest_sv,  0);
    DEBUG_OUT("nest: %d\n", (int)SvIV(nest_sv));
  }
}

void restore_context (pTHX_ HV* state) {
  {
    SV* context_sv  = _get_parser_context(aTHX_ state);
    SV* _context_sv = _get_parser_recent_context(aTHX_ state);
    sv_setiv(context_sv,  SvIV(_context_sv));
    sv_setiv(_context_sv, 0);
    DEBUG_OUT("context: %d\n", (int)SvIV(context_sv));
  }
  {
    SV* nest_sv  = _get_nest(aTHX_ state);
    SV* _nest_sv = _get_recent_nest(aTHX_ state);
    sv_setiv(nest_sv,  SvIV(_nest_sv));
    sv_setiv(_nest_sv, 0);
    DEBUG_OUT("nest: %d\n", (int)SvIV(nest_sv));
  }
}

IV get_parser_context (pTHX_ HV* state) {
  return SvIV(_get_parser_context(aTHX_ state));
}

IV get_nest (pTHX_ HV* state) {
  return SvIV(_get_nest(aTHX_ state));
}

void incr_nest (pTHX_ HV* state) {
  SV* nest = _get_nest(aTHX_ state);
  sv_setiv(nest, SvIV(nest) + 1);
}

void decr_nest (pTHX_ HV* state) {
  SV* nest = _get_nest(aTHX_ state);
  sv_setiv(nest, SvIV(nest) - 1);
}

void set_table (pTHX_ HV* state, const char* name, const size_t length) {
  SV* table = get_table(aTHX_ state);
  DEBUG_OUT("table name: %.*s\n", (int)length, name);
  if (SvOK(table)) {
    sv_setpvn(table, name, length);
  }
  else {
    table = sv_2mortal(newSVpvn(name, length));
    XSUTIL_HV_STORE(state, "table", table);
  }
  get_or_create_schema(aTHX_ state, table);
}

SV* get_table (pTHX_ HV* state) {
  SV** ssv = XSUTIL_HV_FETCH(state, "table");
  if (ssv) {
    DEBUG_OUT("table name: %s\n", SvPV_nolen(*ssv));
    return *ssv;
  }
  else {
    return &PL_sv_undef;
  }
}

HV* get_current_schema (pTHX_ HV* state) {
  SV* table = get_table(aTHX_ state);
  return get_or_create_schema(aTHX_ state, table);
}

HV* get_or_create_schema (pTHX_ HV* state, SV* key) {
  SV** ssv = XSUTIL_HV_FETCH(state, "schema");
  if (!ssv) {
    sv_dump((SV*)state);
    croak("Cannot get schema.");
  }

  HV* schema  = (HV*)SvRV(*ssv);
  HE* entry   = XSUTIL_HV_FETCH_ENT(schema, key);
  if (entry) {
    DEBUG_OUT("get table: %s\n", SvPV_nolen(key));
    return (HV*) SvRV(HeVAL(entry));
  }
  else {
    DEBUG_OUT("create table: %s\n", SvPV_nolen(key));
    HV* table = newHV_mortal();
    XSUTIL_HV_STORE_ENT_REF(schema, key, (SV*)table);
    return table;
  }
}

AV* get_or_create_columns (pTHX_ HV* table) {
  SV** ssv = XSUTIL_HV_FETCH(table, "columns");
  if (ssv) {
    DEBUG_OUT("get columns\n");
    return (AV*)SvRV(*ssv);
  }
  else {
    DEBUG_OUT("create columns\n");
    AV* columns = newAV_mortal();
    XSUTIL_HV_STORE_REF(table, "columns", (SV*)columns);
    return columns;
  }
}
