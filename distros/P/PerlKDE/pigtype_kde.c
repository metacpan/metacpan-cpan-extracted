/*
 * Definition and export of types declared in pigtype_kde.h
 *
 * Copyright (C) 2000, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

#include "pigperl.h"
#include "pigtype_object.h"
#include "pigtype_kde.h"
#include "pigclassinfo.h"
#include <ktreelist.h>

PIG_DEFINE_SCOPE_ARGUMENT(pig_type_kde_const_KPath_ptr) {
    KPath *pigpath = (KPath *)pig0;
    delete pigpath;
}

PIG_DEFINE_TYPE_ARGUMENT(pig_type_kde_const_KPath_ptr, const KPath *) {
    PIGARGS;
    KPath *pigpath = 0;
    if(!SvOK(PIG_ARG) || !SvROK(PIG_ARG) || SvTYPE(SvRV(PIG_ARG)) != SVt_PVAV)
        PIGARGUMENT(pigpath);
    pigpath = new KPath;
    pigpath->setAutoDelete(TRUE);
    AV *pigav = (AV *)SvRV(PIG_ARG);
    I32 pigcnt = av_len(pigav) + 1;
    char **pigr;
    I32 pigi;
    STRLEN n_a;

    for(pigi = 0; pigi < pigcnt; pigi++) {
        SV **pigsvp = av_fetch(pigav, pigi, 0);
        if(!pigsvp) {
	    pigpath->push(new QString());
	    continue;
        }
	pigpath->push(new QString(SvPV(*pigsvp, n_a)));
    }

    PIGSCOPE_ARGUMENT(pig_type_kde_const_KPath_ptr, pigpath);
    PIGARGUMENT(pigpath);
}

PIG_DEFINE_STUB_DEFARGUMENT(pig_type_kde_const_KPath_ptr, const KPath *)
PIG_DEFINE_STUB_RETURN(pig_type_kde_const_KPath_ptr, const KPath *)
PIG_DEFINE_STUB_PUSH(pig_type_kde_const_KPath_ptr, const KPath *)
PIG_DEFINE_STUB_POP(pig_type_kde_const_KPath_ptr, const KPath *)

PIG_DEFINE_TYPE(pig_type_kde_const_KPath_ptr)

PIG_EXPORT_TABLE(pigtype_kde)
    PIG_EXPORT_TYPE(pig_type_kde_const_KPath_ptr, "KDE const KPath*")
PIG_EXPORT_ENDTABLE
