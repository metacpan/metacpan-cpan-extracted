#ifndef UTIL_H_INCLUDED
#define UTIL_H_INCLUDED

#include "common.h"

void init_constants(void);
SV * make_constant(char *name, STRLEN l, U32 value);
SV * hv_fetch_def(HV *, const char *, I32, SV *);
#define hv_fetchs_def(hv, key, def) hv_fetch_def((hv), (key), strlen(key), (def))
#define hv_fetchs_def_no(hv, key) hv_fetch_def((hv), (key), strlen(key), &PL_sv_no)
#define hv_fetchs_def_undef(hv, key) hv_fetch_def((hv), (key), strlen(key), &PL_sv_undef)
#define hv_fetchs_def_null(hv, key) hv_fetch_def((hv), (key), strlen(key), 0)

SV * av_fetch_def(AV *, I32, SV *);
#define av_fetch_def_no(av, ix) av_fetch_def((av), (ix), &PL_sv_no)
#define av_fetch_def_undef(av, ix) av_fetch_def((av), (ix), &PL_sv_undef)

#endif
