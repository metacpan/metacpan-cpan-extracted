/*
 * virtualize definition
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pqt.h"
#include "virtual.h"

virtualize::~virtualize() {
    warn("~virtualize()\n");
    if(qtClassName) free(qtClassName);
    if(qtObject && SvREFCNT(qtObject)) SvREFCNT_dec(qtObject);
}

void virtualize::callQtMethod(CV *method, SV *arg1, SV *arg2) {
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    XPUSHs(qtObject);
    if(arg1) XPUSHs(arg1);
    if(arg2) XPUSHs(arg2);
    PUTBACK;

    perl_call_sv((SV *)method, G_SCALAR);

    FREETMPS;
    LEAVE;
}

char *virtualize::setQtClassName(char *cname) {
    qtClassName = (char *)malloc(strlen(cname)+1);
    strcpy(qtClassName, cname);

    return cname;
}

