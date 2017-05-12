/*
 * PLabel definitions.
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pobject.h"
#include "plabel.h"
#include "pqt.h"
#include "virtual.h"

void PLabel::initMetaObject() {
    char *clname = (char *)getQtClassName();
    SV **svp = hv_fetch(MetaObjects, clname, strlen(clname), 1);

    if(!QLabel::metaObject()) QLabel::initMetaObject();
    if(svp && SvTRUE(*svp)) return;
    safe_hv_store(MetaObjects, clname, newSViv(0));
}

QMetaObject *PLabel::metaObject() {
    initMetaObject();
    char *clname = (char *)getQtClassName();
    return metaObjectSetup(clname);
}

const char *PLabel::className() const {
    return getQtClassName();
}
