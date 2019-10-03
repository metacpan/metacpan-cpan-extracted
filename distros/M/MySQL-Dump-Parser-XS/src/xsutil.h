#pragma once

#include "use_perl.h"
#include <stdlib.h>
#include <string.h>

#define XSUTIL_HV_STORE_NOINC(hv, name, value) \
  hv_store(hv, name, strlen(name), value, 0)

#define XSUTIL_HV_STORE(hv, name, value) \
  XSUTIL_HV_STORE_NOINC(hv, name, SvREFCNT_inc(value))

#define XSUTIL_HV_STORE_REF(hv, name, value) \
  XSUTIL_HV_STORE(hv, name, newRV_inc_mortal(value))

#define XSUTIL_HV_FETCH(hv, name) \
  hv_fetch(hv, name, strlen(name), 0)

#define XSUTIL_HV_FETCH_ENT(hv, key) \
  hv_fetch_ent(hv, key, 0, 0)

#define XSUTIL_HV_STORE_ENT_NOINC(hv, key, value) \
  hv_store_ent(hv, key, value, 0)

#define XSUTIL_HV_STORE_ENT(hv, key, value) \
  XSUTIL_HV_STORE_ENT_NOINC(hv, key, SvREFCNT_inc(value))

#define XSUTIL_HV_STORE_ENT_REF(hv, key, value) \
  XSUTIL_HV_STORE_ENT(hv, key, newRV_inc_mortal(value))

#define XSUTIL_HV_FOREACH(hv, entry, block) { \
  HV* hash = hv;                              \
  hv_iterinit(hash);                          \
  HE* entry;                                  \
  while ((entry = hv_iternext(hash))) {       \
    block;                                    \
  }                                           \
}

#define XSUTIL_AV_PUSH_NOINC(av, value) \
  av_push(av, value)

#define XSUTIL_AV_PUSH(av, value) \
  XSUTIL_AV_PUSH_NOINC(av, SvREFCNT_inc(value))

#define XSUTIL_AV_PUSH_REF(av, value) \
  XSUTIL_AV_PUSH(av, newRV_inc_mortal(value))

#define XSUTIL_AV_FETCH(av, index) \
  av_fetch(av, index, 0)

#define XSUTIL_AV_FOREACH(av, entry, block) { \
  AV* array = av;                             \
  I32 id;                                     \
  I32 len = av_len(array) + 1;                \
  for (id = 0; id < len; id++) {              \
    SV** ssv = XSUTIL_AV_FETCH(array, id);    \
    if (ssv) {                                \
      SV* entry = *ssv;                       \
      block;                                  \
    }                                         \
    else {                                    \
      croak("Cannot fetch " #av "[%d]", id);  \
    }                                         \
  }                                           \
}

#define XSUTIL_NEW_SVIV_MORTAL(i) sv_2mortal(newSViv(i))
