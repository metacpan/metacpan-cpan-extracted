/*
 * Routines needed globally in PerlQt.
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pqt.h"

SV *obj_check(SV *sv, char *message = "Invalid object") {
    SV *rv = rv_check(sv, message);
    if(!SvOBJECT(rv) || SvTYPE(rv) != SVt_PVHV)
        croak(message);
    return rv;
}

SV *rv_check(SV *sv, char *message = "Not a reference") {
    if(!sv || !SvROK(sv)) croak(message);
    return SvRV(sv);
}

SV *safe_hv_store(HV *hash, char *key, SV *value) {
    register SV **svp = hv_store(hash, key, strlen(key), value, 0);
    if(!svp) croak("Hash store store of '%s' failed", key);
    return *svp;
}

SV *safe_hv_fetch(HV *hash, char *key, char *message) {
    register SV **svp = hv_fetch(hash, key, strlen(key), 0);
    if(!svp) croak(message);
    return *svp;
}

/*
static char *parse_clname(char *clname) {
    char *tmp = clname;
    int origlen = strlen(clname);

    if(!tmp) croak("NULL classname");
    while(isALNUM(*tmp)) tmp++;
    *tmp = 0;
    if(toLOWER(*clname) == 'p' && strlen(clname) != origlen) *clname = 'Q';

    return clname;
}
*/

static char *parse_clname(char *clname) {
    char *newclname, *tmp;

    if(!clname) croak("NULL classname");
    tmp = New(123, newclname, strlen(clname)+1, char);
    strcpy(newclname, clname);
    while(isALNUM(*tmp)) tmp++;
    *tmp = 0;
    if(toLOWER(*newclname) == 'p' && strlen(clname) != strlen(newclname))
	*newclname = 'Q';

    return newclname;   // this is New() memory, careful!
}

SV *objectify_ptr(void *ptr, char *clname, int delete_on_destroy = 0) {
    clname = parse_clname(clname);
    if(!ptr) return &sv_undef;

    HV *obj = newHV();

    safe_hv_store(obj, "THIS", newSViv((IV)ptr));
    if(delete_on_destroy)
	safe_hv_store(obj, "DELETE", &sv_yes);

    SV *ret = sv_bless(newRV_noinc((SV *)obj), gv_stashpv(parse_clname(clname),
		       true));
    Safefree(clname);   // parse_clname() returned New()ed memory.
    return ret;
}

void *extract_ptr(SV *rv, char *clname) {
    if(rv == &sv_undef) return NULL;
    HV *obj = (HV *)obj_check(rv);
    SV *THIS = safe_hv_fetch(obj, "THIS", "Could not access \"THIS\" element");

    return (void *)SvIV(THIS);
}

char *find_signal(SV *obj, char *signal) {
    dSP;
    int count;
    SV *ret;

    PUSHMARK(sp);
    XPUSHs(obj);
    XPUSHs(sv_2mortal(newSVpv(signal, 0)));
    PUTBACK;

    count = perl_call_pv("signals::find_signal", G_SCALAR);
    SPAGAIN;
    if(count != 1) croak("Bad perl_call_pv, bad");
    ret = POPs;
    PUTBACK;

    return SvTRUE(ret) ? SvPV(ret, na) : 0;
}

char *find_slot(SV *obj, char *slot) {
    dSP;
    int count;
    SV *ret;

    PUSHMARK(sp);
    XPUSHs(obj);
    XPUSHs(sv_2mortal(newSVpv(slot, 0)));
    PUTBACK;

    count = perl_call_pv("slots::find_slot", G_SCALAR);
    SPAGAIN;
    if(count != 1) croak("Bad perl_call_pv, bad");
    ret = POPs;
    PUTBACK;

    return SvTRUE(ret) ? SvPV(ret, na) : 0;
}

SV *parse_member(SV *member) {
    dSP;
    int count;
    SV *ret;

    PUSHMARK(sp);
    XPUSHs(member);
    PUTBACK;

    count = perl_call_pv("QObject::parse_member", G_SCALAR);
    SPAGAIN;
    if(count != 1) croak("Bad perl_call_pv, bad");
    ret = POPs;
    PUTBACK;

    return ret;
}