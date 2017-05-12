/*
 * pQtSigSlot definition
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "sigslot.h"
#include "pobject.h"

void pQtSigSlot::initMetaObject() {
    char *clname = (char *)qobj->className();
    SV **svp = hv_fetch(MetaObjects, clname, strlen(clname), 0);

    if(svp && SvTRUE(*svp)) return;
    if(!qobj->metaObject()) qobj->protected_initMetaObject();  // Paranoia?
    safe_hv_store(MetaObjects, clname, newSViv(0));
}

const char *pQtSigSlot::className() const {
    return qobj->className();
}

QMetaObject *pQtSigSlot::metaObject() const {
    return qobj->metaObject();
}

SV *getMemberArgs(char *member) {
    dSP;
    int count;
    SV *ret;

    ENTER;		// This can be called in the global Perl scope
    SAVETMPS;

    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newSVpv(member, 0)));
    PUTBACK;

    count = perl_call_pv("QObject::getMemberArgs", G_SCALAR);
    SPAGAIN;
    if(count != 1) croak("Bad perl_call_pv, bad");
    ret = newSVsv(POPs);
    PUTBACK;

    FREETMPS;
    LEAVE;

    return ret;
}

QMember stub_func(char *member) {
    SV *rv = getMemberArgs(member);
    AV *args = (AV *)rv_check(rv);
    int len = av_len(args)+1;

    if(len == 0) return (QMember)&pQtSigSlot::s;
    if(len == 1) return (QMember)&pQtSigSlot::sI;
    else if(len == 2) return (QMember)&pQtSigSlot::sII;
    SvREFCNT_dec(args);  // test
    SvREFCNT_dec(rv);
}

void pQtSigSlot::s() {
    dSP;
    GV *meth = gv_fetchmethod(SvSTASH(SvRV(object)), sname);

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    XPUSHs(object);
    PUTBACK;

    perl_call_sv((SV *)GvCV(meth), G_DISCARD);

    FREETMPS;
    LEAVE;
}

void pQtSigSlot::sI(IV i) {
    SV *sv = newSViv(i);

    slot1(sv);
    SvREFCNT_dec(sv);
}

void pQtSigSlot::sII(IV i1, IV i2) {
    SV *sv1 = newSViv(i1), *sv2 = newSViv(i2);

    slot2(sv1, sv2);

    SvREFCNT_dec(sv1);
    SvREFCNT_dec(sv2);
}

void pQtSigSlot::slot1(SV *sv1) {
    dSP;
    GV *meth = gv_fetchmethod(SvSTASH(SvRV(object)), sname);

    ENTER;
    SAVETMPS;

//    if(SvREFCNT(sv1)) sv1);	// scope it here

    PUSHMARK(sp);
    XPUSHs(object);
    XPUSHs(sv1);
    PUTBACK;

    perl_call_sv((SV *)GvCV(meth), G_DISCARD);

    FREETMPS;
    LEAVE;
}

void pQtSigSlot::slot2(SV *sv1, SV *sv2) {
    dSP;
    GV *meth = gv_fetchmethod(SvSTASH(SvRV(object)), sname);

    ENTER;
    SAVETMPS;

//    if(SvREFCNT(sv1)) sv_2mortal(sv1);	// scope it here
//    if(SvREFCNT(sv2)) sv_2mortal(sv2);

    PUSHMARK(sp);
    XPUSHs(object);
    XPUSHs(sv1);
    XPUSHs(sv2);
    PUTBACK;

    perl_call_sv((SV *)GvCV(meth), G_DISCARD);

    FREETMPS;
    LEAVE;
}
