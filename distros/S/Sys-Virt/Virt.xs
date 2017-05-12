/* -*- c -*-
 *
 * Copyright (C) 2006-2016 Red Hat
 * Copyright (C) 2006-2014 Daniel P. Berrange
 *
 * This program is free software; You can redistribute it and/or modify
 * it under either:
 *
 * a) the GNU General Public License as published by the Free
 *   Software Foundation; either version 2, or (at your option) any
 *   later version,
 *
 * or
 *
 * b) the "Artistic License"
 *
 * The file "LICENSE" distributed along with this file provides full
 * details of the terms and conditions of the two licenses.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <libvirt/virterror.h>
#include <libvirt/libvirt.h>

/*
 * On 32-bit OS (and some 64-bit) Perl does not have an
 * integer type capable of storing 64 bit numbers. So
 * we serialize to/from strings on these platforms
 */

static long long
virt_SvIVll(SV *sv) {
#ifdef USE_64_BIT_ALL
    return SvIV(sv);
#else
    return strtoll(SvPV_nolen(sv), NULL, 10);
#endif
}


static unsigned long long
virt_SvIVull(SV *sv) {
#ifdef USE_64_BIT_ALL
    return SvIV(sv);
#else
    return strtoull(SvPV_nolen(sv), NULL, 10);
#endif
}


#ifndef PRId64
#define PRId64 "lld"
#endif


static SV *
virt_newSVll(long long val) {
#ifdef USE_64_BIT_ALL
    return newSViv(val);
#else
    char buf[100];
    int len;
    len = snprintf(buf, 100, "%" PRId64, val);
    return newSVpv(buf, len);
#endif
}


#ifndef PRIu64
#define PRIu64 "llu"
#endif

static SV *
virt_newSVull(unsigned long long val) {
#ifdef USE_64_BIT_ALL
    return newSVuv(val);
#else
    char buf[100];
    int len;
    len = snprintf(buf, 100, "%" PRIu64, val);
    return newSVpv(buf, len);
#endif
}



static void
ignoreVirErrorFunc(void * userData, virErrorPtr error) {
  /* Do nothing */
}


static SV *
_sv_from_error(virErrorPtr error)
{
    HV *hv;

    hv = newHV ();

    /* Map virErrorPtr attributes to hash keys */
    (void)hv_store (hv, "level", 5, newSViv (error ? error->level : 0), 0);
    (void)hv_store (hv, "code", 4, newSViv (error ? error->code : 0), 0);
    (void)hv_store (hv, "domain", 6, newSViv (error ? error->domain : VIR_FROM_NONE), 0);
    (void)hv_store (hv, "message", 7, newSVpv (error && error->message ? error->message : "Unknown problem", 0), 0);

    return sv_bless (newRV_noinc ((SV*) hv), gv_stashpv ("Sys::Virt::Error", TRUE));
}


static void
_croak_error(void)
{
    virErrorPtr error = virGetLastError();
    sv_setsv(ERRSV, _sv_from_error (error));

    /* croak does not return, so we free this now to avoid leaking */
    virResetError(error);

    croak (Nullch);
}


static void
_populate_constant(HV *stash, const char *name, int val)
{
    SV *valsv;

    valsv = newSViv(0);
    sv_setuv(valsv,val);
    newCONSTSUB(stash, name, valsv);
}


static void
_populate_constant_str(HV *stash, const char *name, const char *value)
{
    SV *valsv;

    valsv = newSVpv(value, strlen(value));
    newCONSTSUB(stash, name, valsv);
}


static void
_populate_constant_ull(HV *stash, const char *name, unsigned long long val)
{
    SV *valsv;

    valsv = virt_newSVull(val);
    newCONSTSUB(stash, name, valsv);
}


#define REGISTER_CONSTANT(name, key) _populate_constant(stash, #key, name)
#define REGISTER_CONSTANT_STR(name, key) _populate_constant_str(stash, #key, name)
#define REGISTER_CONSTANT_ULL(name, key) _populate_constant_ull(stash, #key, name)

static HV *
vir_typed_param_to_hv(virTypedParameterPtr params, int nparams)
{
    HV *ret = (HV *)sv_2mortal((SV*)newHV());
    unsigned int i;
    const char *field;
    STRLEN val_length;

    for (i = 0 ; i < nparams ; i++) {
        SV *val = NULL;

        switch (params[i].type) {
        case VIR_TYPED_PARAM_INT:
            val = newSViv(params[i].value.i);
            break;

        case VIR_TYPED_PARAM_UINT:
            val = newSViv((int)params[i].value.ui);
            break;

        case VIR_TYPED_PARAM_LLONG:
            val = virt_newSVll(params[i].value.l);
            break;

        case VIR_TYPED_PARAM_ULLONG:
            val = virt_newSVull(params[i].value.ul);
            break;

        case VIR_TYPED_PARAM_DOUBLE:
            val = newSVnv(params[i].value.d);
            break;

        case VIR_TYPED_PARAM_BOOLEAN:
            val = newSViv(params[i].value.b);
            break;

        case VIR_TYPED_PARAM_STRING:
            val_length = strlen(params[i].value.s);
            val = newSVpv(params[i].value.s, val_length);
            break;

        }

        field = params[i].field;
        (void)hv_store(ret, field, strlen(params[i].field), val, 0);
    }

    return ret;
}


static int
vir_typed_param_from_hv(HV *newparams, virTypedParameterPtr params, int nparams)
{
    unsigned int i;
    char * ptr;
    STRLEN len;

    /* We only want to set parameters which we're actually changing
     * so here we figure out which elements of 'params' we need to
     * update, and overwrite the others
     */
    for (i = 0 ; i < nparams ;) {
        if (!hv_exists(newparams, params[i].field, strlen(params[i].field))) {
            if ((nparams-i) > 1)
                memmove(params+i, params+i+1, sizeof(*params)*(nparams-(i+1)));
            nparams--;
            continue;
        }

        i++;
    }

    for (i = 0 ; i < nparams ; i++) {
        SV **val;

        val = hv_fetch (newparams, params[i].field, strlen(params[i].field), 0);

        switch (params[i].type) {
        case VIR_TYPED_PARAM_INT:
            params[i].value.i = SvIV(*val);
            break;

        case VIR_TYPED_PARAM_UINT:
            params[i].value.ui = SvIV(*val);
            break;

        case VIR_TYPED_PARAM_LLONG:
            params[i].value.l = virt_SvIVll(*val);
            break;

        case VIR_TYPED_PARAM_ULLONG:
            params[i].value.ul = virt_SvIVull(*val);
            break;

        case VIR_TYPED_PARAM_DOUBLE:
            params[i].value.d = SvNV(*val);
            break;

        case VIR_TYPED_PARAM_BOOLEAN:
            params[i].value.b = SvIV(*val);
            break;

        case VIR_TYPED_PARAM_STRING:
            ptr = SvPV(*val, len);
            params[i].value.s = (char *)ptr;
            break;
        }
    }

    return nparams;
}


static void
vir_typed_param_add_string_list_from_hv(HV *newparams,
					virTypedParameterPtr *params,
					int *nparams,
					const char *key)
{
    if (!hv_exists(newparams, key, strlen(key))) {
        return;
    }
    SSize_t nstr, i;
    virTypedParameterPtr localparams = *params;

    SV **val = hv_fetch(newparams, key, strlen(key), 0);
    AV *av = (AV*)(SvRV(*val));
    nstr = av_len(av) + 1;

    Renew(localparams, *nparams + nstr, virTypedParameter);

    for (i = 0 ; i < nstr ; i++) {
      STRLEN len;
      SV **subval = av_fetch(av, i, 0);
      char *ptr = SvPV(*subval, len);

      strncpy(localparams[*nparams + i].field, key,
	      VIR_TYPED_PARAM_FIELD_LENGTH);
      localparams[*nparams + i].field[VIR_TYPED_PARAM_FIELD_LENGTH - 1] = '\0';

      localparams[*nparams + i].type = VIR_TYPED_PARAM_STRING;
      localparams[*nparams + i].value.s = ptr;
    }

    *params = localparams;
    *nparams += nstr;
}


static int
_domain_event_lifecycle_callback(virConnectPtr con,
                                 virDomainPtr dom,
                                 int event,
                                 int detail,
                                 void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(newSViv(event)));
    XPUSHs(sv_2mortal(newSViv(detail)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_generic_callback(virConnectPtr con,
                               virDomainPtr dom,
                               void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_rtcchange_callback(virConnectPtr con,
                                 virDomainPtr dom,
                                 long long utcoffset,
                                 void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(virt_newSVll(utcoffset)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_watchdog_callback(virConnectPtr con,
                                virDomainPtr dom,
                                int action,
                                void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(newSViv(action)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_io_error_callback(virConnectPtr con,
                                virDomainPtr dom,
                                const char *srcPath,
                                const char *devAlias,
                                int action,
                                void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(newSVpv(srcPath, 0)));
    XPUSHs(sv_2mortal(newSVpv(devAlias, 0)));
    XPUSHs(sv_2mortal(newSViv(action)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_disk_change_callback(virConnectPtr con,
                                   virDomainPtr dom,
                                   const char *oldSrcPath,
                                   const char *newSrcPath,
                                   const char *devAlias,
                                   int reason,
                                   void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(newSVpv(oldSrcPath, 0)));
    XPUSHs(sv_2mortal(newSVpv(newSrcPath, 0)));
    XPUSHs(sv_2mortal(newSVpv(devAlias, 0)));
    XPUSHs(sv_2mortal(newSViv(reason)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_tray_change_callback(virConnectPtr con,
                                   virDomainPtr dom,
                                   const char *devAlias,
                                   int reason,
                                   void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(newSVpv(devAlias, 0)));
    XPUSHs(sv_2mortal(newSViv(reason)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_pmwakeup_callback(virConnectPtr con,
                                virDomainPtr dom,
                                int reason,
                                void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(newSViv(reason)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_pmsuspend_callback(virConnectPtr con,
                                 virDomainPtr dom,
                                 int reason,
                                 void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(newSViv(reason)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_pmsuspend_disk_callback(virConnectPtr con,
                                      virDomainPtr dom,
                                      int reason,
                                      void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(newSViv(reason)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_io_error_reason_callback(virConnectPtr con,
                                       virDomainPtr dom,
                                       const char *srcPath,
                                       const char *devAlias,
                                       int action,
                                       const char *reason,
                                       void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(newSVpv(srcPath, 0)));
    XPUSHs(sv_2mortal(newSVpv(devAlias, 0)));
    XPUSHs(sv_2mortal(newSViv(action)));
    XPUSHs(sv_2mortal(newSVpv(reason, 0)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_graphics_callback(virConnectPtr con,
                                virDomainPtr dom,
                                int phase,
                                virDomainEventGraphicsAddressPtr local,
                                virDomainEventGraphicsAddressPtr remote,
                                const char *authScheme,
                                virDomainEventGraphicsSubjectPtr subject,
                                void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    HV *local_hv;
    HV *remote_hv;
    AV *subject_av;
    int i;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    local_hv = newHV();
    (void)hv_store(local_hv, "family", 6, newSViv(local->family), 0);
    (void)hv_store(local_hv, "node", 4, newSVpv(local->node, 0), 0);
    (void)hv_store(local_hv, "service", 7, newSVpv(local->service, 0), 0);

    remote_hv = newHV();
    (void)hv_store(remote_hv, "family", 6, newSViv(remote->family), 0);
    (void)hv_store(remote_hv, "node", 4, newSVpv(remote->node, 0), 0);
    (void)hv_store(remote_hv, "service", 7, newSVpv(remote->service, 0), 0);

    subject_av = newAV();
    for (i = 0 ; i < subject->nidentity ; i++) {
        HV *identity = newHV();
        (void)hv_store(identity, "type", 4, newSVpv(subject->identities[i].type, 0), 0);
        (void)hv_store(identity, "name", 4, newSVpv(subject->identities[i].name, 0), 0);

        av_push(subject_av, newRV_noinc((SV *)identity));
    }

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(newSViv(phase)));
    XPUSHs(newRV_noinc((SV*)local_hv));
    XPUSHs(newRV_noinc((SV*)remote_hv));
    XPUSHs(sv_2mortal(newSVpv(authScheme, 0)));
    XPUSHs(newRV_noinc((SV*)subject_av));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_block_job_callback(virConnectPtr con,
                                 virDomainPtr dom,
                                 const char *path,
                                 int type,
                                 int status,
                                 void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(newSVpv(path, 0)));
    XPUSHs(sv_2mortal(newSViv(type)));
    XPUSHs(sv_2mortal(newSViv(status)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_balloonchange_callback(virConnectPtr con,
                                     virDomainPtr dom,
                                     unsigned long long actual,
                                     void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(virt_newSVull(actual)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_device_generic_callback(virConnectPtr con,
                                      virDomainPtr dom,
                                      const char *devAlias,
                                      void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(newSVpv(devAlias, 0)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_tunable_callback(virConnectPtr con,
			       virDomainPtr dom,
			       virTypedParameterPtr params,
			       size_t nparams,
			       void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    HV *params_hv;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);

    params_hv = vir_typed_param_to_hv(params, nparams);

    XPUSHs(domref);
    XPUSHs(newRV(( SV*)params_hv));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_agent_lifecycle_callback(virConnectPtr con,
				       virDomainPtr dom,
				       int state,
				       int reason,
				       void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(newSViv(state)));
    XPUSHs(sv_2mortal(newSViv(reason)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_migration_iteration_callback(virConnectPtr con,
					   virDomainPtr dom,
					   int iteration,
					   void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(newSViv(iteration)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_job_completed_callback(virConnectPtr con,
				     virDomainPtr dom,
				     virTypedParameterPtr params,
				     int nparams,
				     void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    HV *params_hv;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);

    params_hv = vir_typed_param_to_hv(params, nparams);

    XPUSHs(domref);
    XPUSHs(newRV(( SV*)params_hv));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_metadata_change_callback(virConnectPtr con,
				       virDomainPtr dom,
				       int type,
				       const char *nsuri,
				       void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void*)dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(newSViv(type)));
    XPUSHs(sv_2mortal(newSVpv(nsuri, 0)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_domain_event_block_threshold_callback(virConnectPtr con,
                                       virDomainPtr dom,
                                       const char *dev,
                                       const char *path,
                                       unsigned long long threshold,
                                       unsigned long long excess,
                                       void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *domref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    domref = sv_newmortal();
    sv_setref_pv(domref, "Sys::Virt::Domain", (void *) dom);
    virDomainRef(dom);
    XPUSHs(domref);
    XPUSHs(sv_2mortal(newSVpv(dev, 0)));
    XPUSHs(sv_2mortal(newSVpv(path, 0)));
    XPUSHs(sv_2mortal(newSViv(threshold)));
    XPUSHs(sv_2mortal(newSViv(excess)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_network_event_lifecycle_callback(virConnectPtr con,
				  virNetworkPtr net,
				  int event,
				  int detail,
				  void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *netref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    netref = sv_newmortal();
    sv_setref_pv(netref, "Sys::Virt::Network", (void*)net);
    virNetworkRef(net);
    XPUSHs(netref);
    XPUSHs(sv_2mortal(newSViv(event)));
    XPUSHs(sv_2mortal(newSViv(detail)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_network_event_generic_callback(virConnectPtr con,
				virNetworkPtr net,
				void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *netref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    netref = sv_newmortal();
    sv_setref_pv(netref, "Sys::Virt::Network", (void*)net);
    virNetworkRef(net);
    XPUSHs(netref);
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_storage_pool_event_generic_callback(virConnectPtr con,
				     virStoragePoolPtr pool,
				     void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *poolref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    poolref = sv_newmortal();
    sv_setref_pv(poolref, "Sys::Virt::StoragePool", (void*)pool);
    virStoragePoolRef(pool);
    XPUSHs(poolref);
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_storage_pool_event_lifecycle_callback(virConnectPtr con,
				       virStoragePoolPtr pool,
				       int event,
				       int detail,
				       void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *poolref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    poolref = sv_newmortal();
    sv_setref_pv(poolref, "Sys::Virt::StoragePool", (void*)pool);
    virStoragePoolRef(pool);
    XPUSHs(poolref);
    XPUSHs(sv_2mortal(newSViv(event)));
    XPUSHs(sv_2mortal(newSViv(detail)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_node_device_event_generic_callback(virConnectPtr con,
				    virNodeDevicePtr dev,
				    void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *devref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    devref = sv_newmortal();
    sv_setref_pv(devref, "Sys::Virt::NodeDevice", (void*)dev);
    virNodeDeviceRef(dev);
    XPUSHs(devref);
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_node_device_event_lifecycle_callback(virConnectPtr con,
				       virNodeDevicePtr dev,
				       int event,
				       int detail,
				       void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *devref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    devref = sv_newmortal();
    sv_setref_pv(devref, "Sys::Virt::NodeDevice", (void*)dev);
    virNodeDeviceRef(dev);
    XPUSHs(devref);
    XPUSHs(sv_2mortal(newSViv(event)));
    XPUSHs(sv_2mortal(newSViv(detail)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_secret_event_lifecycle_callback(virConnectPtr con,
				 virSecretPtr secret,
				 int event,
				 int detail,
				 void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *secretref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    secretref = sv_newmortal();
    sv_setref_pv(secretref, "Sys::Virt::Secret", (void*)secret);
    virSecretRef(secret);
    XPUSHs(secretref);
    XPUSHs(sv_2mortal(newSViv(event)));
    XPUSHs(sv_2mortal(newSViv(detail)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_secret_event_generic_callback(virConnectPtr con,
				virSecretPtr secret,
				void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    SV *secretref;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    secretref = sv_newmortal();
    sv_setref_pv(secretref, "Sys::Virt::Secret", (void*)secret);
    virSecretRef(secret);
    XPUSHs(secretref);
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static void
_domain_event_free(void *opaque)
{
  SV *sv = opaque;
  SvREFCNT_dec(sv);
}


static void
_network_event_free(void *opaque)
{
  SV *sv = opaque;
  SvREFCNT_dec(sv);
}


static void
_storage_pool_event_free(void *opaque)
{
  SV *sv = opaque;
  SvREFCNT_dec(sv);
}


static void
_node_device_event_free(void *opaque)
{
  SV *sv = opaque;
  SvREFCNT_dec(sv);
}


static void
_secret_event_free(void *opaque)
{
  SV *sv = opaque;
  SvREFCNT_dec(sv);
}


static void
_close_callback(virConnectPtr con,
                int reason,
                void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    XPUSHs(sv_2mortal(newSViv(reason)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;
}


static void
_close_callback_free(void *opaque)
{
  SV *sv = opaque;
  SvREFCNT_dec(sv);
}


static int
_event_add_handle(int fd,
		  int events,
		  virEventHandleCallback cb,
		  void *opaque,
		  virFreeCallback ff)
{
    SV *cbref;
    SV *opaqueref;
    SV *ffref;
    int ret;
    int watch = 0;
    dSP;

    ENTER;
    SAVETMPS;

    cbref= sv_newmortal();
    opaqueref= sv_newmortal();
    ffref= sv_newmortal();

    sv_setref_pv(cbref, NULL, cb);
    sv_setref_pv(opaqueref, NULL, opaque);
    sv_setref_pv(ffref, NULL, ff);

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(fd)));
    XPUSHs(sv_2mortal(newSViv(events)));
    XPUSHs(cbref);
    XPUSHs(opaqueref);
    XPUSHs(ffref);
    PUTBACK;

    ret = call_pv("Sys::Virt::Event::_add_handle", G_SCALAR);

    SPAGAIN;

    if (ret == 1)
      watch = POPi;

    FREETMPS;
    LEAVE;

    if (ret != 1)
      return -1;

    return watch;
}


static void
_event_update_handle(int watch,
		     int events)
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(watch)));
    XPUSHs(sv_2mortal(newSViv(events)));
    PUTBACK;

    call_pv("Sys::Virt::Event::_update_handle", G_DISCARD);

    FREETMPS;
    LEAVE;
}


static int
_event_remove_handle(int watch)
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(watch)));
    PUTBACK;

    call_pv("Sys::Virt::Event::_remove_handle", G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
    return 0;
}


static int
_event_add_timeout(int interval,
		   virEventTimeoutCallback cb,
		   void *opaque,
		   virFreeCallback ff)
{
    SV *cbref;
    SV *opaqueref;
    SV *ffref;
    int ret;
    int timer = 0;
    dSP;

    ENTER;
    SAVETMPS;

    cbref = sv_newmortal();
    opaqueref = sv_newmortal();
    ffref = sv_newmortal();

    sv_setref_pv(cbref, NULL, cb);
    sv_setref_pv(opaqueref, NULL, opaque);
    sv_setref_pv(ffref, NULL, ff);

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(interval)));
    XPUSHs(cbref);
    XPUSHs(opaqueref);
    XPUSHs(ffref);
    PUTBACK;

    ret = call_pv("Sys::Virt::Event::_add_timeout", G_SCALAR);

    SPAGAIN;

    if (ret == 1)
      timer = POPi;

    FREETMPS;
    LEAVE;

    if (ret != 1)
      return -1;

    return timer;
}


static void
_event_update_timeout(int timer,
		      int interval)
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(timer)));
    XPUSHs(sv_2mortal(newSViv(interval)));
    PUTBACK;

    call_pv("Sys::Virt::Event::_update_timeout", G_DISCARD);

    FREETMPS;
    LEAVE;
}


static int
_event_remove_timeout(int timer)
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(timer)));
    PUTBACK;

    call_pv("Sys::Virt::Event::_remove_timeout", G_DISCARD);

    FREETMPS;
    LEAVE;

    return 0;
}


static int
_open_auth_callback(virConnectCredentialPtr cred,
		    unsigned int ncred,
		    void *cbdata)
{
  dSP;
  int i, ret, success = -1;
  AV *credlist;

  credlist = newAV();

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);

  for (i = 0 ; i < ncred ; i++) {
      HV *credrec = newHV();

      (void)hv_store(credrec, "type", 4, newSViv(cred[i].type), 0);
      (void)hv_store(credrec, "prompt", 6, newSVpv(cred[i].prompt, 0), 0);
      (void)hv_store(credrec, "challenge", 9, newSVpv(cred[i].challenge, 0), 0);
      if (cred[i].defresult != NULL)
          (void)hv_store(credrec, "result", 6, newSVpv(cred[i].defresult, 0), 0);
      else
          (void)hv_fetch(credrec, "result", 6, 1);

      av_push(credlist, newRV_noinc((SV *)credrec));
  }
  SvREFCNT_inc((SV*)credlist);

  XPUSHs(newRV_noinc((SV*)credlist));
  PUTBACK;

  ret = call_sv((SV*)cbdata, G_SCALAR);

  SPAGAIN;

  if (ret == 1)
     success = POPi;

  for (i = 0 ; i < ncred ; i++) {
      SV **credsv = av_fetch(credlist, i, 0);
      HV *credrec = (HV*)SvRV(*credsv);
      SV **val = hv_fetch(credrec, "result", 6, 0);

      if (val && SvOK(*val)) {
	  STRLEN len;
	  char *result = SvPV(*val, len);
	  if (!(cred[i].result = malloc(len+1)))
	      abort();
	  memcpy(cred[i].result, result, len+1);
	  cred[i].resultlen = (unsigned int)len;
      } else {
	  cred[i].resultlen = 0;
	  cred[i].result = NULL;
      }
  }

  FREETMPS;
  LEAVE;

  return success;
}


static void
_event_handle_helper(int watch,
                     int fd,
                     int events,
                     void *opaque)
{
    SV *cb = opaque;
    dSP;

    SvREFCNT_inc(cb);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(watch)));
    XPUSHs(sv_2mortal(newSViv(fd)));
    XPUSHs(sv_2mortal(newSViv(events)));
    PUTBACK;

    call_sv(cb, G_DISCARD);

    FREETMPS;
    LEAVE;
}


static void
_event_timeout_helper(int timer,
                      void *opaque)
{
    SV *cb = opaque;
    dSP;

    SvREFCNT_inc(cb);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(timer)));
    PUTBACK;

    call_sv(cb, G_DISCARD);

    FREETMPS;
    LEAVE;
}


static void
_event_cb_free(void *opaque)
{
    SV *data = opaque;
    SvREFCNT_dec(data);
}


static void
_stream_event_callback(virStreamPtr st,
                       int events,
                       void *opaque)
{
    AV *data = opaque;
    SV **self;
    SV **cb;
    dSP;

    self = av_fetch(data, 0, 0);
    cb = av_fetch(data, 1, 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    XPUSHs(sv_2mortal(newSViv(events)));
    PUTBACK;

    call_sv(*cb, G_DISCARD);

    FREETMPS;
    LEAVE;
}


static void
_stream_event_free(void *opaque)
{
    AV *data = opaque;
    SvREFCNT_dec(data);
}


static int
_stream_send_all_source(virStreamPtr st,
                        char *data,
                        size_t nbytes,
                        void *opaque)
{
    AV *av = opaque;
    SV **self;
    SV **handler;
    SV *datasv;
    int rv;
    int ret;
    dSP;

    self = av_fetch(av, 0, 0);
    handler = av_fetch(av, 1, 0);
    datasv = newSVpv("", 0);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    XPUSHs(datasv);
    XPUSHs(sv_2mortal(newSViv(nbytes)));
    PUTBACK;

    rv = call_sv((SV*)*handler, G_SCALAR);

    SPAGAIN;

    if (rv == 1) {
        ret = POPi;
    } else {
        ret = -1;
    }

    if (ret > 0) {
        const char *newdata = SvPV_nolen(datasv);
        if (ret > nbytes)
            ret = nbytes;
        strncpy(data, newdata, nbytes);
    }

    FREETMPS;
    LEAVE;

    SvREFCNT_dec(datasv);

    return ret;
}


static int
_stream_recv_all_sink(virStreamPtr st,
                      const char *data,
                      size_t nbytes,
                      void *opaque)
{
    AV *av = opaque;
    SV **self;
    SV **handler;
    SV *datasv;
    int rv;
    int ret;
    dSP;

    self = av_fetch(av, 0, 0);
    handler = av_fetch(av, 1, 0);
    datasv = newSVpv(data, nbytes);

    SvREFCNT_inc(*self);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(*self);
    XPUSHs(datasv);
    XPUSHs(sv_2mortal(newSViv(nbytes)));
    PUTBACK;

    rv = call_sv((SV*)*handler, G_SCALAR);

    SPAGAIN;

    if (rv == 1) {
        ret = POPi;
    } else {
        ret = -1;
    }

    FREETMPS;
    LEAVE;

    SvREFCNT_dec(datasv);

    return ret;
}


MODULE = Sys::Virt  PACKAGE = Sys::Virt

PROTOTYPES: ENABLE

virConnectPtr
_open(name, flags)
      SV *name;
      unsigned int flags;
PREINIT:
      const char *uri = NULL;
    CODE:
      if (SvOK(name))
	  uri = SvPV_nolen(name);

      if (!(RETVAL = virConnectOpenAuth(uri, NULL, flags)))
          _croak_error();
  OUTPUT:
      RETVAL


virConnectPtr
_open_auth(name, creds, cb, flags)
      SV *name;
      SV *creds;
      SV *cb;
      unsigned int flags;
PREINIT:
      AV *credlist;
      virConnectAuth auth;
      int i;
      const char *uri = NULL;
   CODE:
      if (SvOK(name))
	  uri = SvPV_nolen(name);

      if (SvOK(cb) && SvOK(creds)) {
	  memset(&auth, 0, sizeof auth);
	  credlist = (AV*)SvRV(creds);
	  auth.ncredtype = av_len(credlist) + 1;
	  Newx(auth.credtype, auth.ncredtype, int);
	  for (i = 0 ; i < auth.ncredtype ; i++) {
	    SV **type = av_fetch(credlist, i, 0);
	    auth.credtype[i] = SvIV(*type);
	  }

	  auth.cb = _open_auth_callback;
	  auth.cbdata = cb;
	  RETVAL = virConnectOpenAuth(uri,
				      &auth,
                                      flags);
	  Safefree(auth.credtype);
      } else {
	  RETVAL = virConnectOpenAuth(uri,
				      virConnectAuthPtrDefault,
                                      flags);
      }
      if (!RETVAL)
	_croak_error();
 OUTPUT:
      RETVAL


void
restore_domain(con, from, dxmlsv=&PL_sv_undef, flags=0)
      virConnectPtr con;
      const char *from;
      SV *dxmlsv;
      unsigned int flags;
 PREINIT:
      const char *dxml = NULL;
  PPCODE:
      if (SvOK(dxmlsv))
	  dxml = SvPV_nolen(dxmlsv);

      if (dxml || flags) {
          if (virDomainRestoreFlags(con, from, dxml, flags) < 0)
              _croak_error();
      } else {
          if (virDomainRestore(con, from) < 0)
              _croak_error();
      }


SV *
get_save_image_xml_description(con, file, flags=0)
      virConnectPtr con;
      const char *file;
      unsigned int flags;
  PREINIT:
      char *xml;
    CODE:
      if (!(xml = virDomainSaveImageGetXMLDesc(con, file, flags)))
	 _croak_error();
      RETVAL = newSVpv(xml, 0);
      free(xml);
  OUTPUT:
      RETVAL


void
define_save_image_xml(con, file, xml, flags=0)
      virConnectPtr con;
      const char *file;
      const char *xml;
      unsigned int flags;
    PPCODE:
      if (virDomainSaveImageDefineXML(con, file, xml, flags) < 0)
          _croak_error();



unsigned long
_get_library_version(void)
 PREINIT:
      unsigned long version;
   CODE:
      if (virGetVersion(&version, NULL, NULL) < 0)
          _croak_error();
      RETVAL = version;
  OUTPUT:
      RETVAL


unsigned long
_get_conn_version(con)
      virConnectPtr con;
 PREINIT:
      unsigned long version;
   CODE:
      if (virConnectGetVersion(con, &version) < 0)
          _croak_error();
      RETVAL = version;
  OUTPUT:
      RETVAL


unsigned long
_get_conn_library_version(con)
      virConnectPtr con;
 PREINIT:
      unsigned long version;
   CODE:
      if (virConnectGetLibVersion(con, &version) < 0)
          _croak_error();
      RETVAL = version;
  OUTPUT:
      RETVAL


int
is_encrypted(conn)
      virConnectPtr conn;
    CODE:
      if ((RETVAL = virConnectIsEncrypted(conn)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


int
is_secure(conn)
      virConnectPtr conn;
    CODE:
      if ((RETVAL = virConnectIsSecure(conn)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


int
is_alive(conn)
      virConnectPtr conn;
    CODE:
      if ((RETVAL = virConnectIsAlive(conn)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


void
set_keep_alive(conn, interval, count)
      virConnectPtr conn;
      int interval;
      unsigned int count;
  PPCODE:
      if (virConnectSetKeepAlive(conn, interval, count) < 0)
          _croak_error();


const char *
get_type(con)
      virConnectPtr con;
   CODE:
      RETVAL = virConnectGetType(con);
 OUTPUT:
      RETVAL


char *
get_uri(con)
      virConnectPtr con;
   CODE:
      RETVAL = virConnectGetURI(con);
 OUTPUT:
      RETVAL


char *
get_sysinfo(con, flags=0)
      virConnectPtr con;
      unsigned int flags;
   CODE:
      RETVAL = virConnectGetSysinfo(con, flags);
 OUTPUT:
      RETVAL


HV *
get_node_info(con)
      virConnectPtr con;
  PREINIT:
      virNodeInfo info;
    CODE:
      if (virNodeGetInfo(con, &info) < 0)
          _croak_error();

      RETVAL = (HV *)sv_2mortal((SV*)newHV());
      (void)hv_store (RETVAL, "model", 5, newSVpv(info.model, 0), 0);
      (void)hv_store (RETVAL, "memory", 6, newSViv(info.memory), 0);
      (void)hv_store (RETVAL, "cpus", 4, newSViv(info.cpus), 0);
      (void)hv_store (RETVAL, "mhz", 3, newSViv(info.mhz), 0);
      (void)hv_store (RETVAL, "nodes", 5, newSViv(info.nodes), 0);
      (void)hv_store (RETVAL, "sockets", 7, newSViv(info.sockets), 0);
      (void)hv_store (RETVAL, "cores", 5, newSViv(info.cores), 0);
      (void)hv_store (RETVAL, "threads", 7, newSViv(info.threads), 0);
  OUTPUT:
      RETVAL


HV *
get_node_security_model(con)
      virConnectPtr con;
 PREINIT:
      virSecurityModel secmodel;
    CODE:
      if (virNodeGetSecurityModel(con, &secmodel) < 0)
          _croak_error();

      RETVAL = (HV *)sv_2mortal((SV*)newHV());
      (void)hv_store (RETVAL, "model", 5, newSVpv(secmodel.model, 0), 0);
      (void)hv_store (RETVAL, "doi", 3, newSVpv(secmodel.doi, 0), 0);
   OUTPUT:
      RETVAL

void
get_node_cpu_map(con, flags=0)
      virConnectPtr con;
      unsigned int flags;
 PREINIT:
      unsigned char *cpumaps;
      unsigned int online;
      int ncpus;
  PPCODE:
      if ((ncpus = virNodeGetCPUMap(con, &cpumaps, &online, flags)) < 0)
          _croak_error();

      EXTEND(SP, 3);
      PUSHs(sv_2mortal(newSViv(ncpus)));
      PUSHs(sv_2mortal(newSVpvn((char*)cpumaps, VIR_CPU_MAPLEN(ncpus))));
      PUSHs(sv_2mortal(newSViv(online)));
      free(cpumaps);

SV *
get_node_free_memory(con)
      virConnectPtr con;
PREINIT:
      unsigned long long mem;
   CODE:
      if ((mem = virNodeGetFreeMemory(con)) == 0)
          _croak_error();

      RETVAL = virt_newSVull(mem);
  OUTPUT:
      RETVAL


void
get_node_cells_free_memory(con, start, end)
      virConnectPtr con;
      int start;
      int end;
PREINIT:
      unsigned long long *mem;
      int i, num, ncells;
 PPCODE:
      ncells = (end - start) + 1;
      Newx(mem, ncells, unsigned long long);
      if ((num = virNodeGetCellsFreeMemory(con, mem, start, ncells)) < 0) {
          Safefree(mem);
          _croak_error();
      }
      EXTEND(SP, num);
      for (i = 0 ; i < num ; i++) {
	SV *val = newSViv(mem[i]);
	PUSHs(sv_2mortal(val));
      }
      Safefree(mem);


void
get_node_free_pages(con, pagesizes, start, end, flags=0)
     virConnectPtr con;
     SV *pagesizes;
     int start;
     int end;
     unsigned int flags;
PREINIT:
     AV *pagesizeslist;
     unsigned int *pages;
     unsigned int npages;
     unsigned long long *counts;
     int ncells;
     int i, j;
 PPCODE:
     ncells = (end - start) + 1;
     pagesizeslist = (AV *)SvRV(pagesizes);
     npages = av_len(pagesizeslist) + 1;
     Newx(pages, npages, unsigned int);
     for (i = 0; i < npages; i++) {
         SV **pagesize = av_fetch(pagesizeslist, i, 0);
	 pages[i] = SvIV(*pagesize);
     }

     Newx(counts, npages * ncells, unsigned long long);

     if (virNodeGetFreePages(con, npages, pages, start,
			     ncells, counts, flags) < 0) {
         Safefree(counts);
         Safefree(pages);
         _croak_error();
     }
     EXTEND(SP, ncells);
     for (i = 0; i < ncells; i++) {
         HV *rec = newHV();
	 HV *prec = newHV();
	 (void)hv_store(rec, "cell", 4, newSViv(start + i), 0);
	 (void)hv_store(rec, "pages", 5, newRV_noinc((SV *)prec), 0);

	 for (j = 0; j < npages; j++) {
	     (void)hv_store_ent(prec,
				newSViv(pages[j]),
				virt_newSVull(counts[(i * npages) + j]),
				0);
	 }
	 PUSHs(newRV_noinc((SV *)rec));
     }
     Safefree(counts);
     Safefree(pages);

void
node_alloc_pages(con, pages, start, end, flags=0)
      virConnectPtr con;
      SV *pages;
      int start;
      int end;
      unsigned int flags;
PREINIT:
      AV *pageslist;
      unsigned int npages;
      unsigned int *pagesizes;
      unsigned long long *pagecounts;
      unsigned int ncells;
      unsigned int i;
  PPCODE:
      ncells = (end - start) + 1;
      pageslist = (AV *)SvRV(pages);
      npages = av_len(pageslist) + 1;

      Newx(pagesizes, npages, unsigned int);
      Newx(pagecounts, npages, unsigned long long);
      for (i = 0; i < npages; i++) {
          SV **pageinforv = av_fetch(pageslist, i, 0);
	  AV *pageinfo = (AV*)SvRV(*pageinforv);
          SV **pagesize = av_fetch(pageinfo, 0, 0);
          SV **pagecount = av_fetch(pageinfo, 1, 0);

          pagesizes[i] = SvIV(*pagesize);
	  pagecounts[i] = virt_SvIVull(*pagecount);
      }

      if (virNodeAllocPages(con, npages, pagesizes, pagecounts,
			    start, ncells, flags) < 0) {
          Safefree(pagesizes);
          Safefree(pagecounts);
	  _croak_error();
      }

      Safefree(pagesizes);
      Safefree(pagecounts);


HV *
get_node_cpu_stats(con, cpuNum=VIR_NODE_CPU_STATS_ALL_CPUS, flags=0)
      virConnectPtr con;
      int cpuNum;
      unsigned int flags;
PREINIT:
      virNodeCPUStatsPtr params;
      int nparams = 0;
      int i;
  CODE:
      if (virNodeGetCPUStats(con, cpuNum, NULL, &nparams, flags) < 0)
          _croak_error();

      Newx(params, nparams, virNodeCPUStats);
      if (virNodeGetCPUStats(con, cpuNum, params, &nparams, flags) < 0) {
          Safefree(params);
          _croak_error();
      }
      RETVAL = (HV *)sv_2mortal((SV*)newHV());
      for (i = 0 ; i < nparams ; i++) {
          if (strcmp(params[i].field, VIR_NODE_CPU_STATS_KERNEL) == 0) {
              (void)hv_store (RETVAL, "kernel", 6, virt_newSVull(params[i].value), 0);
          } else if (strcmp(params[i].field, VIR_NODE_CPU_STATS_USER) == 0) {
              (void)hv_store (RETVAL, "user", 4, virt_newSVull(params[i].value), 0);
          } else if (strcmp(params[i].field, VIR_NODE_CPU_STATS_IDLE) == 0) {
              (void)hv_store (RETVAL, "idle", 4, virt_newSVull(params[i].value), 0);
          } else if (strcmp(params[i].field, VIR_NODE_CPU_STATS_IOWAIT) == 0) {
              (void)hv_store (RETVAL, "iowait", 6, virt_newSVull(params[i].value), 0);
          } else if (strcmp(params[i].field, VIR_NODE_CPU_STATS_INTR) == 0) {
              (void)hv_store (RETVAL, "intr", 4, virt_newSVull(params[i].value), 0);
          } else if (strcmp(params[i].field, VIR_NODE_CPU_STATS_UTILIZATION) == 0) {
              (void)hv_store (RETVAL, "utilization", 11, virt_newSVull(params[i].value), 0);
          }
      }
      Safefree(params);
  OUTPUT:
      RETVAL


HV *
get_node_memory_stats(con, cellNum=VIR_NODE_MEMORY_STATS_ALL_CELLS, flags=0)
      virConnectPtr con;
      int cellNum;
      unsigned int flags;
PREINIT:
      virNodeMemoryStatsPtr params;
      int nparams = 0;
      int i;
  CODE:
      if (virNodeGetMemoryStats(con, cellNum, NULL, &nparams, flags) < 0)
          _croak_error();

      Newx(params, nparams, virNodeMemoryStats);
      if (virNodeGetMemoryStats(con, cellNum, params, &nparams, flags) < 0) {
          Safefree(params);
          _croak_error();
      }
      RETVAL = (HV *)sv_2mortal((SV*)newHV());
      for (i = 0 ; i < nparams ; i++) {
          if (strcmp(params[i].field, VIR_NODE_MEMORY_STATS_TOTAL) == 0) {
              (void)hv_store (RETVAL, "total", 5, virt_newSVull(params[i].value), 0);
          } else if (strcmp(params[i].field, VIR_NODE_MEMORY_STATS_FREE) == 0) {
              (void)hv_store (RETVAL, "free", 4, virt_newSVull(params[i].value), 0);
          } else if (strcmp(params[i].field, VIR_NODE_MEMORY_STATS_BUFFERS) == 0) {
              (void)hv_store (RETVAL, "buffers", 7, virt_newSVull(params[i].value), 0);
          } else if (strcmp(params[i].field, VIR_NODE_MEMORY_STATS_CACHED) == 0) {
              (void)hv_store (RETVAL, "cached", 6, virt_newSVull(params[i].value), 0);
          }
      }
      Safefree(params);
  OUTPUT:
      RETVAL


HV *
get_node_memory_parameters(conn, flags=0)
      virConnectPtr conn;
      unsigned int flags;
  PREINIT:
      virTypedParameterPtr params;
      int nparams;
    CODE:
      nparams = 0;
      if (virNodeGetMemoryParameters(conn, NULL, &nparams, 0) < 0)
          _croak_error();

      Newx(params, nparams, virTypedParameter);

      if (virNodeGetMemoryParameters(conn, params, &nparams, flags) < 0) {
          Safefree(params);
          _croak_error();
      }

      RETVAL = vir_typed_param_to_hv(params, nparams);
      Safefree(params);
  OUTPUT:
      RETVAL


void
set_node_memory_parameters(conn, newparams, flags=0)
      virConnectPtr conn;
      HV *newparams;
      unsigned int flags;
  PREINIT:
      virTypedParameterPtr params;
      int nparams;
    PPCODE:
      nparams = 0;
      if (virNodeGetMemoryParameters(conn, NULL, &nparams, 0) < 0)
          _croak_error();

      Newx(params, nparams, virTypedParameter);

      if (virNodeGetMemoryParameters(conn, params, &nparams, 0) < 0) {
          Safefree(params);
          _croak_error();
      }

      nparams = vir_typed_param_from_hv(newparams, params, nparams);

      if (virNodeSetMemoryParameters(conn, params, nparams, flags) < 0)
          _croak_error();
      Safefree(params);



void
node_suspend_for_duration(conn, target, duration, flags=0)
      virConnectPtr conn;
      unsigned int target;
      SV *duration;
      unsigned int flags;
  PPCODE:
      if (virNodeSuspendForDuration(conn, target, virt_SvIVull(duration), flags) < 0)
          _croak_error();


char *
find_storage_pool_sources(con, type, srcspec, flags=0)
      virConnectPtr con;
      const char *type;
      const char *srcspec;
      unsigned int flags;
    CODE:
      if ((RETVAL = virConnectFindStoragePoolSources(con, type, srcspec, flags)) == NULL)
          _croak_error();
  OUTPUT:
      RETVAL


SV *
get_capabilities(con)
      virConnectPtr con;
PREINIT:
      char *xml;
   CODE:
      if (!(xml = virConnectGetCapabilities(con)))
          _croak_error();

      RETVAL = newSVpv(xml, 0);
      free(xml);
  OUTPUT:
      RETVAL

SV *
get_domain_capabilities(con, emulatorsv, archsv, machinesv, virttypesv, flags=0)
      virConnectPtr con;
      SV *emulatorsv;
      SV *archsv;
      SV *machinesv;
      SV *virttypesv;
      unsigned int flags;
PREINIT:
      char *emulator = NULL;
      char *arch = NULL;
      char *machine = NULL;
      char *virttype = NULL;
      char *xml;
   CODE:
      if (SvOK(emulatorsv))
	  emulator = SvPV_nolen(emulatorsv);
      if (SvOK(archsv))
	  arch = SvPV_nolen(archsv);
      if (SvOK(machinesv))
	  machine = SvPV_nolen(machinesv);
      if (SvOK(virttypesv))
	  virttype = SvPV_nolen(virttypesv);

      if (!(xml = virConnectGetDomainCapabilities(con,
						  emulator, arch,
						  machine, virttype,
						  flags)))
          _croak_error();

      RETVAL = newSVpv(xml, 0);
      free(xml);
  OUTPUT:
      RETVAL


SV *
compare_cpu(con, xml, flags=0)
      virConnectPtr con;
      char *xml;
      unsigned int flags;
PREINIT:
      int rc;
   CODE:
      if ((rc = virConnectCompareCPU(con, xml, flags)) < 0)
          _croak_error();

      RETVAL = newSViv(rc);
  OUTPUT:
      RETVAL


SV *
baseline_cpu(con, xml, flags=0)
      virConnectPtr con;
      SV *xml;
      unsigned int flags;
PREINIT:
      AV *xmllist;
      const char **xmlstr;
      int xmllen;
      int i;
      char *retxml;
   CODE:
      xmllist = (AV*)SvRV(xml);
      xmllen = av_len(xmllist) + 1;
      Newx(xmlstr, xmllen, const char *);
      for (i = 0 ; i < xmllen ; i++) {
          SV **doc = av_fetch(xmllist, i, 0);
          xmlstr[i] = SvPV_nolen(*doc);
      }

      if (!(retxml = virConnectBaselineCPU(con, xmlstr, xmllen, flags))) {
          Safefree(xmlstr);
          _croak_error();
      }

      Safefree(xmlstr);
      RETVAL = newSVpv(retxml, 0);
      free(retxml);
  OUTPUT:
      RETVAL

void
get_cpu_model_names(con, arch, flags=0)
      virConnectPtr con;
      char *arch;
      unsigned int flags;
PREINIT:
      int nnames;
      int i;
      char **names = NULL;
  PPCODE:
      if ((nnames = virConnectGetCPUModelNames(con, arch, &names, flags)) < 0)
          _croak_error();

      EXTEND(SP, nnames);
      for (i = 0 ; i < nnames ; i++) {
          PUSHs(sv_2mortal(newSVpv(names[i], 0)));
          free(names[i]);
      }
      free(names);



int
get_max_vcpus(con, type)
      virConnectPtr con;
      char *type;
    CODE:
      if ((RETVAL = virConnectGetMaxVcpus(con, type)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


SV *
get_hostname(con)
      virConnectPtr con;
 PREINIT:
      char *host;
    CODE:
      if (!(host = virConnectGetHostname(con)))
          _croak_error();

      RETVAL = newSVpv(host, 0);
      free(host);
  OUTPUT:
      RETVAL


int
num_of_domains(con)
      virConnectPtr con;
    CODE:
      if ((RETVAL = virConnectNumOfDomains(con)) < 0)
	_croak_error();
  OUTPUT:
      RETVAL


void
list_domain_ids(con, maxids)
      virConnectPtr con;
      int maxids
 PREINIT:
      int *ids;
      int i, nid;
  PPCODE:
      Newx(ids, maxids, int);
      if ((nid = virConnectListDomains(con, ids, maxids)) < 0) {
          Safefree(ids);
          _croak_error();
      }
      EXTEND(SP, nid);
      for (i = 0 ; i < nid ; i++) {
          PUSHs(sv_2mortal(newSViv(ids[i])));
      }
      Safefree(ids);


int
num_of_defined_domains(con)
      virConnectPtr con;
    CODE:
      if ((RETVAL = virConnectNumOfDefinedDomains(con)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


void
list_defined_domain_names(con, maxnames)
      virConnectPtr con;
      int maxnames;
 PREINIT:
      char **names;
      int ndom;
      int i;
  PPCODE:
      Newx(names, maxnames, char *);
      if ((ndom = virConnectListDefinedDomains(con, names, maxnames)) < 0) {
          Safefree(names);
          _croak_error();
      }
      EXTEND(SP, ndom);
      for (i = 0 ; i < ndom ; i++) {
          PUSHs(sv_2mortal(newSVpv(names[i], 0)));
          free(names[i]);
      }
      Safefree(names);


void
list_all_domains(con, flags=0)
      virConnectPtr con;
      unsigned int flags;
 PREINIT:
      virDomainPtr *doms;
      int i, ndom;
      SV *domrv;
  PPCODE:
      if ((ndom = virConnectListAllDomains(con, &doms, flags)) < 0)
          _croak_error();

      EXTEND(SP, ndom);
      for (i = 0 ; i < ndom ; i++) {
          domrv = sv_newmortal();
          sv_setref_pv(domrv, "Sys::Virt::Domain", doms[i]);
          PUSHs(domrv);
      }
      free(doms);


void
list_all_interfaces(con, flags=0)
      virConnectPtr con;
      unsigned int flags;
 PREINIT:
      virInterfacePtr *ifaces;
      int i, niface;
      SV *ifacerv;
  PPCODE:
      if ((niface = virConnectListAllInterfaces(con, &ifaces, flags)) < 0)
          _croak_error();

      EXTEND(SP, niface);
      for (i = 0 ; i < niface ; i++) {
          ifacerv = sv_newmortal();
          sv_setref_pv(ifacerv, "Sys::Virt::Interface", ifaces[i]);
          PUSHs(ifacerv);
      }
      free(ifaces);


void
list_all_nwfilters(con, flags=0)
      virConnectPtr con;
      unsigned int flags;
 PREINIT:
      virNWFilterPtr *nwfilters;
      int i, nnwfilter;
      SV *nwfilterrv;
  PPCODE:
      if ((nnwfilter = virConnectListAllNWFilters(con, &nwfilters, flags)) < 0)
          _croak_error();

      EXTEND(SP, nnwfilter);
      for (i = 0 ; i < nnwfilter ; i++) {
          nwfilterrv = sv_newmortal();
          sv_setref_pv(nwfilterrv, "Sys::Virt::NWFilter", nwfilters[i]);
          PUSHs(nwfilterrv);
      }
      free(nwfilters);


void
list_all_networks(con, flags=0)
      virConnectPtr con;
      unsigned int flags;
 PREINIT:
      virNetworkPtr *nets;
      int i, nnet;
      SV *netrv;
  PPCODE:
      if ((nnet = virConnectListAllNetworks(con, &nets, flags)) < 0)
          _croak_error();

      EXTEND(SP, nnet);
      for (i = 0 ; i < nnet ; i++) {
          netrv = sv_newmortal();
          sv_setref_pv(netrv, "Sys::Virt::Network", nets[i]);
          PUSHs(netrv);
      }
      free(nets);


void
list_all_node_devices(con, flags=0)
      virConnectPtr con;
      unsigned int flags;
 PREINIT:
      virNodeDevicePtr *devs;
      int i, ndev;
      SV *devrv;
  PPCODE:
      if ((ndev = virConnectListAllNodeDevices(con, &devs, flags)) < 0)
          _croak_error();

      EXTEND(SP, ndev);
      for (i = 0 ; i < ndev ; i++) {
          devrv = sv_newmortal();
          sv_setref_pv(devrv, "Sys::Virt::NodeDevice", devs[i]);
          PUSHs(devrv);
      }
      free(devs);


void
list_all_secrets(con, flags=0)
      virConnectPtr con;
      unsigned int flags;
 PREINIT:
      virSecretPtr *secrets;
      int i, nsecret;
      SV *secretrv;
  PPCODE:
      if ((nsecret = virConnectListAllSecrets(con, &secrets, flags)) < 0)
          _croak_error();

      EXTEND(SP, nsecret);
      for (i = 0 ; i < nsecret ; i++) {
          secretrv = sv_newmortal();
          sv_setref_pv(secretrv, "Sys::Virt::Secret", secrets[i]);
          PUSHs(secretrv);
      }
      free(secrets);


void
list_all_storage_pools(con, flags=0)
      virConnectPtr con;
      unsigned int flags;
 PREINIT:
      virStoragePoolPtr *pools;
      int i, npool;
      SV *poolrv;
  PPCODE:
      if ((npool = virConnectListAllStoragePools(con, &pools, flags)) < 0)
          _croak_error();

      EXTEND(SP, npool);
      for (i = 0 ; i < npool ; i++) {
          poolrv = sv_newmortal();
          sv_setref_pv(poolrv, "Sys::Virt::StoragePool", pools[i]);
          PUSHs(poolrv);
      }
      free(pools);


int
num_of_networks(con)
      virConnectPtr con;
    CODE:
      if ((RETVAL = virConnectNumOfNetworks(con)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


void
list_network_names(con, maxnames)
      virConnectPtr con;
      int maxnames;
 PREINIT:
      char **names;
      int i, nnet;
  PPCODE:
      Newx(names, maxnames, char *);
      if ((nnet = virConnectListNetworks(con, names, maxnames)) < 0) {
          Safefree(names);
          _croak_error();
      }
      EXTEND(SP, nnet);
      for (i = 0 ; i < nnet ; i++) {
          PUSHs(sv_2mortal(newSVpv(names[i], 0)));
          free(names[i]);
      }
      Safefree(names);


int
num_of_defined_networks(con)
      virConnectPtr con;
    CODE:
      if ((RETVAL = virConnectNumOfDefinedNetworks(con)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


void
list_defined_network_names(con, maxnames)
      virConnectPtr con;
      int maxnames;
 PREINIT:
      char **names;
      int ndom;
      int i;
  PPCODE:
      Newx(names, maxnames, char *);
      if ((ndom = virConnectListDefinedNetworks(con, names, maxnames)) < 0) {
          Safefree(names);
          _croak_error();
      }
      EXTEND(SP, ndom);
      for (i = 0 ; i < ndom ; i++) {
          PUSHs(sv_2mortal(newSVpv(names[i], 0)));
          free(names[i]);
      }
      Safefree(names);


int
num_of_storage_pools(con)
      virConnectPtr con;
    CODE:
      if ((RETVAL = virConnectNumOfStoragePools(con)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


void
list_storage_pool_names(con, maxnames)
      virConnectPtr con;
      int maxnames;
 PREINIT:
      char **names;
      int i, nnet;
  PPCODE:
      Newx(names, maxnames, char *);
      if ((nnet = virConnectListStoragePools(con, names, maxnames)) < 0) {
          Safefree(names);
          _croak_error();
      }
      EXTEND(SP, nnet);
      for (i = 0 ; i < nnet ; i++) {
          PUSHs(sv_2mortal(newSVpv(names[i], 0)));
          free(names[i]);
      }
      Safefree(names);


int
num_of_defined_storage_pools(con)
      virConnectPtr con;
    CODE:
      if ((RETVAL = virConnectNumOfDefinedStoragePools(con)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL

void
list_defined_storage_pool_names(con, maxnames)
      virConnectPtr con;
      int maxnames;
 PREINIT:
      char **names;
      int ndom;
      int i;
  PPCODE:
      Newx(names, maxnames, char *);
      if ((ndom = virConnectListDefinedStoragePools(con, names, maxnames)) < 0) {
          Safefree(names);
          _croak_error();
      }
      EXTEND(SP, ndom);
      for (i = 0 ; i < ndom ; i++) {
          PUSHs(sv_2mortal(newSVpv(names[i], 0)));
          free(names[i]);
      }
      Safefree(names);


int
num_of_node_devices(con, cap, flags=0)
      virConnectPtr con;
      SV *cap;
      int flags
 PREINIT:
      const char *capname = NULL;
    CODE:
      if (SvOK(cap))
	  capname = SvPV_nolen(cap);
      if ((RETVAL = virNodeNumOfDevices(con, capname, flags)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


void
list_node_device_names(con, cap, maxnames, flags=0)
      virConnectPtr con;
      SV *cap;
      int maxnames;
      int flags;
 PREINIT:
      char **names;
      int i, nnet;
      const char *capname = NULL;
  PPCODE:
      if (SvOK(cap))
	  capname = SvPV_nolen(cap);
      Newx(names, maxnames, char *);
      if ((nnet = virNodeListDevices(con, capname, names, maxnames, flags)) < 0) {
          Safefree(names);
          _croak_error();
      }
      EXTEND(SP, nnet);
      for (i = 0 ; i < nnet ; i++) {
          PUSHs(sv_2mortal(newSVpv(names[i], 0)));
          free(names[i]);
      }
      Safefree(names);


int
num_of_interfaces(con)
      virConnectPtr con;
    CODE:
      if ((RETVAL = virConnectNumOfInterfaces(con)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


void
list_interface_names(con, maxnames)
      virConnectPtr con;
      int maxnames;
 PREINIT:
      char **names;
      int i, nnet;
  PPCODE:
      Newx(names, maxnames, char *);
      if ((nnet = virConnectListInterfaces(con, names, maxnames)) < 0) {
          Safefree(names);
          _croak_error();
      }
      EXTEND(SP, nnet);
      for (i = 0 ; i < nnet ; i++) {
          PUSHs(sv_2mortal(newSVpv(names[i], 0)));
          free(names[i]);
      }
      Safefree(names);


int
num_of_defined_interfaces(con)
      virConnectPtr con;
    CODE:
      if ((RETVAL = virConnectNumOfDefinedInterfaces(con)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


void
list_defined_interface_names(con, maxnames)
      virConnectPtr con;
      int maxnames;
 PREINIT:
      char **names;
      int i, nnet;
  PPCODE:
      Newx(names, maxnames, char *);
      if ((nnet = virConnectListDefinedInterfaces(con, names, maxnames)) < 0) {
          Safefree(names);
          _croak_error();
      }
      EXTEND(SP, nnet);
      for (i = 0 ; i < nnet ; i++) {
          PUSHs(sv_2mortal(newSVpv(names[i], 0)));
          free(names[i]);
      }
      Safefree(names);


int
num_of_secrets(con)
      virConnectPtr con;
    CODE:
      if ((RETVAL = virConnectNumOfSecrets(con)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


void
list_secret_uuids(con, maxuuids)
      virConnectPtr con;
      int maxuuids;
 PREINIT:
      char **uuids;
      int i, nsecret;
  PPCODE:
      Newx(uuids, maxuuids, char *);
      if ((nsecret = virConnectListSecrets(con, uuids, maxuuids)) < 0) {
          Safefree(uuids);
          _croak_error();
      }
      EXTEND(SP, nsecret);
      for (i = 0 ; i < nsecret ; i++) {
          PUSHs(sv_2mortal(newSVpv(uuids[i], 0)));
          free(uuids[i]);
      }
      Safefree(uuids);


int
num_of_nwfilters(con)
      virConnectPtr con;
    CODE:
      if ((RETVAL = virConnectNumOfNWFilters(con)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


void
list_nwfilter_names(con, maxnames)
      virConnectPtr con;
      int maxnames;
 PREINIT:
      char **names;
      int i, nnet;
  PPCODE:
      Newx(names, maxnames, char *);
      if ((nnet = virConnectListNWFilters(con, names, maxnames)) < 0) {
          Safefree(names);
          _croak_error();
      }
      EXTEND(SP, nnet);
      for (i = 0 ; i < nnet ; i++) {
          PUSHs(sv_2mortal(newSVpv(names[i], 0)));
          free(names[i]);
      }
      Safefree(names);


void get_all_domain_stats(con, stats, doms_sv=&PL_sv_undef, flags=0)
      virConnectPtr con;
      unsigned int stats;
      SV *doms_sv;
      unsigned int flags;
 PREINIT:
      AV *doms_av;
      int ndoms;
      int nstats;
      int i;
      virDomainPtr *doms = NULL;
      virDomainStatsRecordPtr *statsrec = NULL;
   PPCODE:

      if (SvOK(doms_sv)) {
	  doms_av = (AV*)SvRV(doms_sv);
	  ndoms = av_len(doms_av) + 1;
	  fprintf(stderr, "Len %d\n", ndoms);
      } else {
          ndoms = 0;
      }

      if (ndoms) {
	  Newx(doms, ndoms + 1, virDomainPtr);

	  for (i = 0 ; i < ndoms ; i++) {
	      SV **dom = av_fetch(doms_av, i, 0);
	      doms[i] = (virDomainPtr)SvIV((SV*)SvRV(*dom));
	  }
	  doms[ndoms] = NULL;

	  if ((nstats = virDomainListGetStats(doms, stats, &statsrec, flags)) < 0) {
	    Safefree(doms);
	    _croak_error();
	  }
      } else {
          doms = NULL;

	  if ((nstats = virConnectGetAllDomainStats(con, stats, &statsrec, flags)) < 0) {
	    Safefree(doms);
	    _croak_error();
	  }
      }

      EXTEND(SP, nstats);
      for (i = 0 ; i < nstats ; i++) {
	HV *rec = newHV();
	SV *dom = sv_newmortal();
	HV *data = vir_typed_param_to_hv(statsrec[i]->params,
					 statsrec[i]->nparams);
	sv_setref_pv(dom, "Sys::Virt::Domain", statsrec[i]->dom);
	virDomainRef(statsrec[i]->dom);
	hv_store(rec, "dom", 3, SvREFCNT_inc(dom), 0);
	hv_store(rec, "data", 4, newRV((SV*)data), 0);
	PUSHs(newRV_noinc((SV*)rec));
      }
      virDomainStatsRecordListFree(statsrec);
      Safefree(doms);


SV *
domain_xml_from_native(con, configtype, configdata, flags=0)
      virConnectPtr con;
      const char *configtype;
      const char *configdata;
      unsigned int flags;
 PREINIT:
      char *xmldata;
    CODE:
      if (!(xmldata = virConnectDomainXMLFromNative(con, configtype, configdata, flags)))
          _croak_error();

      RETVAL = newSVpv(xmldata, 0);
      free(xmldata);
 OUTPUT:
      RETVAL


SV *
domain_xml_to_native(con, configtype, xmldata, flags=0)
      virConnectPtr con;
      const char *configtype;
      const char *xmldata;
      unsigned int flags;
 PREINIT:
      char *configdata;
    CODE:
      if (!(configdata = virConnectDomainXMLToNative(con, configtype, xmldata, flags)))
          _croak_error();

      RETVAL = newSVpv(configdata, 0);
      free(configdata);
 OUTPUT:
      RETVAL


void
domain_event_register(conref, cb)
      SV* conref;
      SV* cb;
PREINIT:
      AV *opaque;
      virConnectPtr con;
 PPCODE:
      con = (virConnectPtr)SvIV((SV*)SvRV(conref));
      opaque = newAV();
      SvREFCNT_inc(cb);
      SvREFCNT_inc(conref);
      av_push(opaque, conref);
      av_push(opaque, cb);
      if (virConnectDomainEventRegister(con, _domain_event_lifecycle_callback,
                                        opaque, _domain_event_free) < 0)
          _croak_error();


void
domain_event_deregister(con)
      virConnectPtr con;
 PPCODE:
      virConnectDomainEventDeregister(con, _domain_event_lifecycle_callback);


int
domain_event_register_any(conref, domref, eventID, cb)
      SV* conref;
      SV* domref;
      int eventID;
      SV* cb;
PREINIT:
      AV *opaque;
      virConnectPtr con;
      virDomainPtr dom;
      virConnectDomainEventGenericCallback callback;
    CODE:
      con = (virConnectPtr)SvIV((SV*)SvRV(conref));
      if (SvROK(domref)) {
          dom = (virDomainPtr)SvIV((SV*)SvRV(domref));
      } else {
          dom = NULL;
      }

      switch (eventID) {
      case VIR_DOMAIN_EVENT_ID_LIFECYCLE:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_lifecycle_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_REBOOT:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_generic_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_RTC_CHANGE:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_rtcchange_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_WATCHDOG:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_watchdog_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_IO_ERROR:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_io_error_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_IO_ERROR_REASON:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_io_error_reason_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_GRAPHICS:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_graphics_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_CONTROL_ERROR:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_generic_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_BLOCK_JOB:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_block_job_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_BLOCK_JOB_2:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_block_job_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_DISK_CHANGE:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_disk_change_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_TRAY_CHANGE:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_tray_change_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_PMSUSPEND:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_pmsuspend_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_PMSUSPEND_DISK:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_pmsuspend_disk_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_PMWAKEUP:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_pmwakeup_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_BALLOON_CHANGE:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_balloonchange_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_DEVICE_ADDED:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_device_generic_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_DEVICE_REMOVED:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_device_generic_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_TUNABLE:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_tunable_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_AGENT_LIFECYCLE:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_agent_lifecycle_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_MIGRATION_ITERATION:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_migration_iteration_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_JOB_COMPLETED:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_job_completed_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_DEVICE_REMOVAL_FAILED:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_device_generic_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_METADATA_CHANGE:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_metadata_change_callback);
          break;
      case VIR_DOMAIN_EVENT_ID_BLOCK_THRESHOLD:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_block_threshold_callback);
          break;
      default:
          callback = VIR_DOMAIN_EVENT_CALLBACK(_domain_event_generic_callback);
          break;
      }

      opaque = newAV();
      SvREFCNT_inc(cb);
      SvREFCNT_inc(conref);
      av_push(opaque, conref);
      av_push(opaque, cb);
      if ((RETVAL = virConnectDomainEventRegisterAny(con, dom, eventID, callback, opaque, _domain_event_free)) < 0)
          _croak_error();
OUTPUT:
      RETVAL


void
domain_event_deregister_any(con, callbackID)
      virConnectPtr con;
      int callbackID;
 PPCODE:
      virConnectDomainEventDeregisterAny(con, callbackID);


int
network_event_register_any(conref, netref, eventID, cb)
      SV* conref;
      SV* netref;
      int eventID;
      SV* cb;
PREINIT:
      AV *opaque;
      virConnectPtr con;
      virNetworkPtr net;
      virConnectNetworkEventGenericCallback callback;
    CODE:
      con = (virConnectPtr)SvIV((SV*)SvRV(conref));
      if (SvROK(netref)) {
          net = (virNetworkPtr)SvIV((SV*)SvRV(netref));
      } else {
          net = NULL;
      }

      switch (eventID) {
      case VIR_NETWORK_EVENT_ID_LIFECYCLE:
          callback = VIR_NETWORK_EVENT_CALLBACK(_network_event_lifecycle_callback);
          break;
      default:
          callback = VIR_NETWORK_EVENT_CALLBACK(_network_event_generic_callback);
          break;
      }

      opaque = newAV();
      SvREFCNT_inc(cb);
      SvREFCNT_inc(conref);
      av_push(opaque, conref);
      av_push(opaque, cb);
      if ((RETVAL = virConnectNetworkEventRegisterAny(con, net, eventID, callback, opaque, _network_event_free)) < 0)
          _croak_error();
OUTPUT:
      RETVAL


void
network_event_deregister_any(con, callbackID)
      virConnectPtr con;
      int callbackID;
 PPCODE:
      virConnectNetworkEventDeregisterAny(con, callbackID);


int
storage_pool_event_register_any(conref, poolref, eventID, cb)
      SV* conref;
      SV* poolref;
      int eventID;
      SV* cb;
PREINIT:
      AV *opaque;
      virConnectPtr con;
      virStoragePoolPtr pool;
      virConnectStoragePoolEventGenericCallback callback;
    CODE:
      con = (virConnectPtr)SvIV((SV*)SvRV(conref));
      if (SvROK(poolref)) {
          pool = (virStoragePoolPtr)SvIV((SV*)SvRV(poolref));
      } else {
          pool = NULL;
      }

      switch (eventID) {
      case VIR_STORAGE_POOL_EVENT_ID_LIFECYCLE:
          callback = VIR_STORAGE_POOL_EVENT_CALLBACK(_storage_pool_event_lifecycle_callback);
          break;
      case VIR_STORAGE_POOL_EVENT_ID_REFRESH:
          callback = VIR_STORAGE_POOL_EVENT_CALLBACK(_storage_pool_event_generic_callback);
          break;
      default:
          callback = VIR_STORAGE_POOL_EVENT_CALLBACK(_storage_pool_event_generic_callback);
          break;
      }

      opaque = newAV();
      SvREFCNT_inc(cb);
      SvREFCNT_inc(conref);
      av_push(opaque, conref);
      av_push(opaque, cb);
      if ((RETVAL = virConnectStoragePoolEventRegisterAny(con, pool, eventID, callback, opaque, _storage_pool_event_free)) < 0)
          _croak_error();
OUTPUT:
      RETVAL


void
storage_pool_event_deregister_any(con, callbackID)
      virConnectPtr con;
      int callbackID;
 PPCODE:
      virConnectStoragePoolEventDeregisterAny(con, callbackID);


int
node_device_event_register_any(conref, devref, eventID, cb)
      SV* conref;
      SV* devref;
      int eventID;
      SV* cb;
PREINIT:
      AV *opaque;
      virConnectPtr con;
      virNodeDevicePtr dev;
      virConnectNodeDeviceEventGenericCallback callback;
    CODE:
      con = (virConnectPtr)SvIV((SV*)SvRV(conref));
      if (SvROK(devref)) {
          dev = (virNodeDevicePtr)SvIV((SV*)SvRV(devref));
      } else {
          dev = NULL;
      }

      switch (eventID) {
      case VIR_NODE_DEVICE_EVENT_ID_LIFECYCLE:
          callback = VIR_NODE_DEVICE_EVENT_CALLBACK(_node_device_event_lifecycle_callback);
          break;
      case VIR_NODE_DEVICE_EVENT_ID_UPDATE:
          callback = VIR_NODE_DEVICE_EVENT_CALLBACK(_node_device_event_generic_callback);
          break;
      default:
          callback = VIR_NODE_DEVICE_EVENT_CALLBACK(_node_device_event_generic_callback);
          break;
      }

      opaque = newAV();
      SvREFCNT_inc(cb);
      SvREFCNT_inc(conref);
      av_push(opaque, conref);
      av_push(opaque, cb);
      if ((RETVAL = virConnectNodeDeviceEventRegisterAny(con, dev, eventID, callback, opaque, _node_device_event_free)) < 0)
          _croak_error();
OUTPUT:
      RETVAL


void
node_device_event_deregister_any(con, callbackID)
      virConnectPtr con;
      int callbackID;
 PPCODE:
      virConnectNodeDeviceEventDeregisterAny(con, callbackID);


int
secret_event_register_any(conref, secretref, eventID, cb)
      SV* conref;
      SV* secretref;
      int eventID;
      SV* cb;
PREINIT:
      AV *opaque;
      virConnectPtr con;
      virSecretPtr secret;
      virConnectSecretEventGenericCallback callback;
    CODE:
      con = (virConnectPtr)SvIV((SV*)SvRV(conref));
      if (SvROK(secretref)) {
          secret = (virSecretPtr)SvIV((SV*)SvRV(secretref));
      } else {
          secret = NULL;
      }

      switch (eventID) {
      case VIR_SECRET_EVENT_ID_LIFECYCLE:
          callback = VIR_SECRET_EVENT_CALLBACK(_secret_event_lifecycle_callback);
          break;
      case VIR_SECRET_EVENT_ID_VALUE_CHANGED:
          callback = VIR_SECRET_EVENT_CALLBACK(_secret_event_generic_callback);
          break;
      default:
          callback = VIR_SECRET_EVENT_CALLBACK(_secret_event_generic_callback);
          break;
      }

      opaque = newAV();
      SvREFCNT_inc(cb);
      SvREFCNT_inc(conref);
      av_push(opaque, conref);
      av_push(opaque, cb);
      if ((RETVAL = virConnectSecretEventRegisterAny(con, secret, eventID, callback, opaque, _secret_event_free)) < 0)
          _croak_error();
OUTPUT:
      RETVAL


void
secret_event_deregister_any(con, callbackID)
      virConnectPtr con;
      int callbackID;
 PPCODE:
      virConnectSecretEventDeregisterAny(con, callbackID);


void
register_close_callback(conref, cb)
      SV* conref;
      SV* cb;
PREINIT:
      AV *opaque;
      virConnectPtr con;
 PPCODE:
      con = (virConnectPtr)SvIV((SV*)SvRV(conref));
      opaque = newAV();
      SvREFCNT_inc(cb);
      SvREFCNT_inc(conref);
      av_push(opaque, conref);
      av_push(opaque, cb);
      if (virConnectRegisterCloseCallback(con, _close_callback,
                                          opaque, _close_callback_free) < 0)
          _croak_error();


void
unregister_close_callback(con)
      virConnectPtr con;
 PPCODE:
      virConnectUnregisterCloseCallback(con, _close_callback);


void
interface_change_begin(conn, flags=0)
      virConnectPtr conn;
      unsigned int flags;
    PPCODE:
      if (virInterfaceChangeBegin(conn, flags) < 0)
          _croak_error();


void
interface_change_commit(conn, flags=0)
      virConnectPtr conn;
      unsigned int flags;
    PPCODE:
      if (virInterfaceChangeCommit(conn, flags) < 0)
          _croak_error();


void
interface_change_rollback(conn, flags=0)
      virConnectPtr conn;
      unsigned int flags;
    PPCODE:
      if (virInterfaceChangeRollback(conn, flags) < 0)
          _croak_error();


void
DESTROY(con_rv)
      SV *con_rv;
 PREINIT:
      virConnectPtr con;
  PPCODE:
      con = (virConnectPtr)SvIV((SV*)SvRV(con_rv));
      if (con) {
	virConnectClose(con);
	sv_setiv((SV*)SvRV(con_rv), 0);
      }


MODULE = Sys::Virt::Domain  PACKAGE = Sys::Virt::Domain


virDomainPtr
_create(con, xml, flags=0)
      virConnectPtr con;
      const char *xml;
      unsigned int flags;
    CODE:
      if (flags) {
          if (!(RETVAL = virDomainCreateXML(con, xml, flags)))
              _croak_error();
      } else {
          if (!(RETVAL = virDomainCreateLinux(con, xml, 0)))
              _croak_error();
      }
  OUTPUT:
      RETVAL


virDomainPtr
_create_with_files(con, xml, fdssv, flags=0)
      virConnectPtr con;
      const char *xml;
      SV *fdssv;
      unsigned int flags;
 PREINIT:
      AV *fdsav;
      unsigned int nfds;
      int *fds;
      int i;
    CODE:
      if (!SvROK(fdssv))
          return;
      fdsav = (AV*)SvRV(fdssv);
      nfds = av_len(fdsav) + 1;
      Newx(fds, nfds, int);

      for (i = 0 ; i < nfds ; i++) {
          SV **fd = av_fetch(fdsav, i, 0);
          fds[i] = SvIV(*fd);
      }

      if (!(RETVAL = virDomainCreateXMLWithFiles(con, xml, nfds, fds, flags))) {
          Safefree(fds);
          _croak_error();
      }

      Safefree(fds);
  OUTPUT:
      RETVAL


virDomainPtr
_define_xml(con, xml, flags=0)
      virConnectPtr con;
      const char *xml;
      unsigned int flags;
    CODE:
      if (flags) {
	  if (!(RETVAL = virDomainDefineXMLFlags(con, xml, flags)))
	      _croak_error();
      } else {
	  if (!(RETVAL = virDomainDefineXML(con, xml)))
	      _croak_error();
      }
  OUTPUT:
      RETVAL


virDomainPtr
_lookup_by_id(con, id)
      virConnectPtr con;
      int id;
    CODE:
      if (!(RETVAL = virDomainLookupByID(con, id)))
          _croak_error();
  OUTPUT:
      RETVAL


virDomainPtr
_lookup_by_name(con, name)
      virConnectPtr con;
      const char *name;
    CODE:
      if (!(RETVAL = virDomainLookupByName(con, name)))
          _croak_error();
  OUTPUT:
      RETVAL


virDomainPtr
_lookup_by_uuid(con, uuid)
      virConnectPtr con;
      const unsigned char *uuid;
    CODE:
      if (!(RETVAL = virDomainLookupByUUID(con, uuid)))
          _croak_error();
  OUTPUT:
      RETVAL


virDomainPtr
_lookup_by_uuid_string(con, uuid)
      virConnectPtr con;
      const char *uuid;
    CODE:
      if (!(RETVAL = virDomainLookupByUUIDString(con, uuid)))
          _croak_error();
  OUTPUT:
      RETVAL


int
get_id(dom)
      virDomainPtr dom;
    CODE:
      RETVAL = virDomainGetID(dom);
  OUTPUT:
      RETVAL


SV *
get_uuid(dom)
      virDomainPtr dom;
  PREINIT:
      unsigned char rawuuid[VIR_UUID_BUFLEN];
    CODE:
      if ((virDomainGetUUID(dom, rawuuid)) < 0)
          _croak_error();

      RETVAL = newSVpv((char*)rawuuid, sizeof(rawuuid));
  OUTPUT:
      RETVAL


SV *
get_uuid_string(dom)
      virDomainPtr dom;
  PREINIT:
      char uuid[VIR_UUID_STRING_BUFLEN];
    CODE:
      if ((virDomainGetUUIDString(dom, uuid)) < 0)
          _croak_error();

      RETVAL = newSVpv(uuid, 0);
  OUTPUT:
      RETVAL


const char *
get_name(dom)
      virDomainPtr dom;
    CODE:
      if (!(RETVAL = virDomainGetName(dom)))
          _croak_error();
  OUTPUT:
      RETVAL


const char *
get_hostname(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
    CODE:
      if (!(RETVAL = virDomainGetHostname(dom, flags)))
          _croak_error();
  OUTPUT:
      RETVAL


char *
get_metadata(dom, type, uri=&PL_sv_undef, flags=0)
      virDomainPtr dom;
      int type;
      SV *uri;
      unsigned int flags;
 PREINIT:
      const char *uristr = NULL;
    CODE:
      if (SvOK(uri))
	  uristr = SvPV_nolen(uri);

      if (!(RETVAL = virDomainGetMetadata(dom, type, uristr, flags)))
          _croak_error();
  OUTPUT:
      RETVAL


void
set_metadata(dom, type, metadata=&PL_sv_undef, key=&PL_sv_undef, uri=&PL_sv_undef, flags=0)
      virDomainPtr dom;
      int type;
      SV *metadata;
      SV *key;
      SV *uri;
      unsigned int flags;
 PREINIT:
      const char *metadatastr = NULL;
      const char *keystr = NULL;
      const char *uristr = NULL;
  PPCODE:
      if (SvOK(metadata))
	  metadatastr = SvPV_nolen(metadata);
      if (SvOK(key))
	  keystr = SvPV_nolen(key);
      if (SvOK(uri))
	  uristr = SvPV_nolen(uri);

      if (virDomainSetMetadata(dom, type, metadatastr, keystr, uristr, flags) < 0)
          _croak_error();



int
is_active(dom)
      virDomainPtr dom;
    CODE:
      if ((RETVAL = virDomainIsActive(dom)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


int
is_persistent(dom)
      virDomainPtr dom;
    CODE:
      if ((RETVAL = virDomainIsPersistent(dom)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


int
is_updated(dom)
      virDomainPtr dom;
    CODE:
      if ((RETVAL = virDomainIsUpdated(dom)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


void
suspend(dom)
      virDomainPtr dom;
  PPCODE:
      if ((virDomainSuspend(dom)) < 0)
          _croak_error();


void
resume(dom)
      virDomainPtr dom;
  PPCODE:
      if ((virDomainResume(dom)) < 0)
          _croak_error();


void
pm_wakeup(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PPCODE:
      if ((virDomainPMWakeup(dom, flags)) < 0)
          _croak_error();


void
save(dom, to, dxmlsv=&PL_sv_undef, flags=0)
      virDomainPtr dom;
      const char *to;
      SV *dxmlsv;
      unsigned int flags;
PREINIT:
      const char *dxml = NULL;
  PPCODE:
      if (SvOK(dxmlsv))
	  dxml = SvPV_nolen(dxmlsv);

      if (dxml || flags) {
          if ((virDomainSaveFlags(dom, to, dxml, flags)) < 0)
              _croak_error();
      } else {
          if ((virDomainSave(dom, to)) < 0)
              _croak_error();
      }


void
managed_save(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PPCODE:
      if ((virDomainManagedSave(dom, flags)) < 0)
          _croak_error();


int
has_managed_save_image(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
    CODE:
      if ((RETVAL = virDomainHasManagedSaveImage(dom, flags)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


void
managed_save_remove(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PPCODE:
      if ((virDomainManagedSaveRemove(dom, flags)) < 0)
          _croak_error();


void
core_dump(dom, to, flags=0)
      virDomainPtr dom;
      const char *to;
      unsigned int flags;
    PPCODE:
      if (virDomainCoreDump(dom, to, flags) < 0)
          _croak_error();


void
core_dump_format(dom, to, format, flags=0)
      virDomainPtr dom;
      const char *to;
      unsigned int format;
      unsigned int flags;
    PPCODE:
      if (virDomainCoreDumpWithFormat(dom, to, format, flags) < 0)
          _croak_error();


HV *
get_info(dom)
      virDomainPtr dom;
  PREINIT:
      virDomainInfo info;
    CODE:
      if (virDomainGetInfo(dom, &info) < 0)
          _croak_error();

      RETVAL = (HV *)sv_2mortal((SV*)newHV());
      (void)hv_store (RETVAL, "state", 5, newSViv(info.state), 0);
      (void)hv_store (RETVAL, "maxMem", 6, newSViv(info.maxMem), 0);
      (void)hv_store (RETVAL, "memory", 6, newSViv(info.memory), 0);
      (void)hv_store (RETVAL, "nrVirtCpu", 9, newSViv(info.nrVirtCpu), 0);
      (void)hv_store (RETVAL, "cpuTime", 7, virt_newSVull(info.cpuTime), 0);
  OUTPUT:
      RETVAL

AV *
get_time(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PREINIT:
      long long secs;
      unsigned int nsecs;
    CODE:
      if (virDomainGetTime(dom, &secs, &nsecs, flags) < 0)
          _croak_error();

      RETVAL = (AV *)sv_2mortal((SV*)newAV());
      (void)av_push(RETVAL, virt_newSVull(secs));
      (void)av_push(RETVAL, newSViv(nsecs));
  OUTPUT:
      RETVAL


void
set_time(dom, secssv, nsecs, flags=0)
      virDomainPtr dom;
      SV *secssv;
      unsigned int nsecs;
      unsigned int flags;
  PREINIT:
      long long secs;
  PPCODE:
      secs = virt_SvIVll(secssv);

      if (virDomainSetTime(dom, secs, nsecs, flags) < 0)
	_croak_error();


void
set_user_password(dom, username, password, flags=0)
      virDomainPtr dom;
      const char *username;
      const char *password;
      unsigned int flags;
  PPCODE:
      if (virDomainSetUserPassword(dom, username, password, flags) < 0)
	_croak_error();

void
rename(dom, newname, flags=0)
      virDomainPtr dom;
      const char *newname;
      unsigned int flags;
  PPCODE:
      if (virDomainRename(dom, newname, flags) < 0)
	_croak_error();

HV *
get_control_info(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PREINIT:
      virDomainControlInfo info;
    CODE:
      if (virDomainGetControlInfo(dom, &info, flags) < 0)
          _croak_error();

      RETVAL = (HV *)sv_2mortal((SV*)newHV());
      (void)hv_store (RETVAL, "state", 5, newSViv(info.state), 0);
      (void)hv_store (RETVAL, "details", 7, newSViv(info.details), 0);
      (void)hv_store (RETVAL, "stateTime", 9, virt_newSVull(info.stateTime), 0);
  OUTPUT:
      RETVAL


void
get_state(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
PREINIT:
      int state;
      int reason;
 PPCODE:
      if (virDomainGetState(dom, &state, &reason, flags) < 0)
          _croak_error();

      XPUSHs(sv_2mortal(newSViv(state)));
      XPUSHs(sv_2mortal(newSViv(reason)));


void
open_console(dom, st, devname, flags=0)
      virDomainPtr dom;
      virStreamPtr st;
      SV *devname;
      unsigned int flags;
 PREINIT:
      const char *devnamestr = NULL;
  PPCODE:
      if (SvOK(devname))
          devnamestr = SvPV_nolen(devname);

      if (virDomainOpenConsole(dom, devnamestr, st, flags) < 0)
          _croak_error();


void
open_channel(dom, st, devname, flags=0)
      virDomainPtr dom;
      virStreamPtr st;
      SV *devname;
      unsigned int flags;
 PREINIT:
      const char *devnamestr = NULL;
  PPCODE:
      if (SvOK(devname))
          devnamestr = SvPV_nolen(devname);

      if (virDomainOpenChannel(dom, devnamestr, st, flags) < 0)
          _croak_error();


void
open_graphics(dom, idx, fd, flags=0)
      virDomainPtr dom;
      unsigned int idx;
      int fd;
      unsigned int flags;
  PPCODE:
      if (virDomainOpenGraphics(dom, idx, fd, flags) < 0)
          _croak_error();


int
open_graphics_fd(dom, idx, flags=0)
      virDomainPtr dom;
      unsigned int idx;
      unsigned int flags;
  CODE:
      if ((RETVAL = virDomainOpenGraphicsFD(dom, idx, flags)) < 0)
          _croak_error();
OUTPUT:
      RETVAL


SV *
screenshot(dom, st, screen, flags=0)
      virDomainPtr dom;
      virStreamPtr st;
      unsigned int screen;
      unsigned int flags;
 PREINIT:
      char *mimetype;
    CODE:
      if (!(mimetype = virDomainScreenshot(dom, st, screen, flags)))
          _croak_error();
      RETVAL = newSVpv(mimetype, 0);
      free(mimetype);
  OUTPUT:
      RETVAL


HV *
get_block_info(dom, dev, flags=0)
      virDomainPtr dom;
      const char *dev;
      unsigned int flags;
  PREINIT:
      virDomainBlockInfo info;
    CODE:
      if (virDomainGetBlockInfo(dom, dev, &info, flags) < 0)
          _croak_error();

      RETVAL = (HV *)sv_2mortal((SV*)newHV());
      (void)hv_store (RETVAL, "capacity", 8, virt_newSVull(info.capacity), 0);
      (void)hv_store (RETVAL, "allocation", 10, virt_newSVull(info.allocation), 0);
      (void)hv_store (RETVAL, "physical", 8, virt_newSVull(info.physical), 0);
  OUTPUT:
      RETVAL


HV *
get_job_info(dom)
      virDomainPtr dom;
  PREINIT:
      virDomainJobInfo info;
    CODE:
      if (virDomainGetJobInfo(dom, &info) < 0)
          _croak_error();

      RETVAL = (HV *)sv_2mortal((SV*)newHV());
      (void)hv_store (RETVAL, "type", 4, newSViv(info.type), 0);
      (void)hv_store (RETVAL, "timeElapsed", 11, virt_newSVull(info.timeElapsed), 0);
      (void)hv_store (RETVAL, "timeRemaining", 13, virt_newSVull(info.timeRemaining), 0);
      (void)hv_store (RETVAL, "dataTotal", 9, virt_newSVull(info.dataTotal), 0);
      (void)hv_store (RETVAL, "dataProcessed", 13, virt_newSVull(info.dataProcessed), 0);
      (void)hv_store (RETVAL, "dataRemaining", 13, virt_newSVull(info.dataRemaining), 0);
      (void)hv_store (RETVAL, "memTotal", 8, virt_newSVull(info.memTotal), 0);
      (void)hv_store (RETVAL, "memProcessed", 12, virt_newSVull(info.memProcessed), 0);
      (void)hv_store (RETVAL, "memRemaining", 12, virt_newSVull(info.memRemaining), 0);
      (void)hv_store (RETVAL, "fileTotal", 9, virt_newSVull(info.fileTotal), 0);
      (void)hv_store (RETVAL, "fileProcessed", 13, virt_newSVull(info.fileProcessed), 0);
      (void)hv_store (RETVAL, "fileRemaining", 13, virt_newSVull(info.fileRemaining), 0);
  OUTPUT:
      RETVAL


void
get_job_stats(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PREINIT:
      int type;
      virTypedParameterPtr params;
      int nparams;
      HV *paramsHv;
      SV *typeSv;
    PPCODE:
      if (virDomainGetJobStats(dom, &type, &params, &nparams, flags) < 0) {
          Safefree(params);
          _croak_error();
      }

      typeSv = newSViv(type);
      paramsHv = vir_typed_param_to_hv(params, nparams);
      Safefree(params);

      EXTEND(SP, 2);
      PUSHs(newRV_noinc((SV*)typeSv));
      PUSHs(newRV_noinc((SV*)paramsHv));


void
abort_job(dom)
      virDomainPtr dom;
    PPCODE:
      if (virDomainAbortJob(dom) < 0)
          _croak_error();


void
abort_block_job(dom, path, flags=0)
      virDomainPtr dom;
      const char *path;
      unsigned int flags;
    PPCODE:
      if (virDomainBlockJobAbort(dom, path, flags) < 0)
          _croak_error();


HV *
get_block_job_info(dom, path, flags=0)
      virDomainPtr dom;
      const char *path;
      unsigned int flags;
  PREINIT:
      virDomainBlockJobInfo info;
    CODE:
      if (virDomainGetBlockJobInfo(dom, path, &info, flags) < 0)
          _croak_error();

      RETVAL = (HV *)sv_2mortal((SV*)newHV());
      (void)hv_store (RETVAL, "type", 4, newSViv(info.type), 0);
      (void)hv_store (RETVAL, "bandwidth", 9, virt_newSVull(info.bandwidth), 0);
      (void)hv_store (RETVAL, "cur", 3, virt_newSVull(info.cur), 0);
      (void)hv_store (RETVAL, "end", 3, virt_newSVull(info.end), 0);
  OUTPUT:
      RETVAL


void
set_block_job_speed(dom, path, bandwidth, flags=0)
      virDomainPtr dom;
      const char *path;
      unsigned long bandwidth;
      unsigned int flags;
    PPCODE:
      if (virDomainBlockJobSetSpeed(dom, path, bandwidth, flags) < 0)
          _croak_error();


void
block_pull(dom, path, bandwidth, flags=0)
      virDomainPtr dom;
      const char *path;
      unsigned long bandwidth;
      unsigned int flags;
    PPCODE:
      if (virDomainBlockPull(dom, path, bandwidth, flags) < 0)
          _croak_error();


void
block_rebase(dom, path, base, bandwidth, flags=0)
      virDomainPtr dom;
      const char *path;
      const char *base;
      unsigned long bandwidth;
      unsigned int flags;
    PPCODE:
      if (virDomainBlockRebase(dom, path, base, bandwidth, flags) < 0)
          _croak_error();


void
block_copy(dom, path, destxml, newparams, flags=0)
      virDomainPtr dom;
      const char *path;
      const char *destxml;
      HV *newparams;
      unsigned long flags;
  PREINIT:
      virTypedParameterPtr params;
      int nparams;
  PPCODE:
      nparams = 3;
      Newx(params, nparams, virTypedParameter);

      strncpy(params[0].field, VIR_DOMAIN_BLOCK_COPY_BANDWIDTH,
              VIR_TYPED_PARAM_FIELD_LENGTH);
      params[0].type = VIR_TYPED_PARAM_ULLONG;

      strncpy(params[1].field, VIR_DOMAIN_BLOCK_COPY_GRANULARITY,
              VIR_TYPED_PARAM_FIELD_LENGTH);
      params[1].type = VIR_TYPED_PARAM_UINT;

      strncpy(params[2].field, VIR_DOMAIN_BLOCK_COPY_BUF_SIZE,
              VIR_TYPED_PARAM_FIELD_LENGTH);
      params[2].type = VIR_TYPED_PARAM_UINT;

      nparams = vir_typed_param_from_hv(newparams, params, nparams);

      if (virDomainBlockCopy(dom, path, destxml, params, nparams, flags) < 0) {
          Safefree(params);
          _croak_error();
      }

      Safefree(params);


void
block_commit(dom, path, base, top, bandwidth, flags=0)
      virDomainPtr dom;
      const char *path;
      const char *base;
      const char *top;
      unsigned long bandwidth;
      unsigned int flags;
    PPCODE:
      if (virDomainBlockCommit(dom, path, base, top, bandwidth, flags) < 0)
          _croak_error();


void
get_disk_errors(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
 PREINIT:
      virDomainDiskErrorPtr errors;
      unsigned int maxerrors;
      int ret;
      int i;
  PPCODE:
      if ((ret = virDomainGetDiskErrors(dom, NULL, 0, 0)) < 0)
          _croak_error();
      maxerrors = ret;
      Newx(errors, maxerrors, virDomainDiskError);
      if ((ret = virDomainGetDiskErrors(dom, errors, maxerrors, flags)) < 0) {
          Safefree(errors);
          _croak_error();
      }
      EXTEND(SP, ret);
      for (i = 0 ; i < ret ; i++) {
          HV *rec = newHV();
          (void)hv_store(rec, "path", 4, newSVpv(errors[i].disk, 0), 0);
          (void)hv_store(rec, "error", 5, newSViv(errors[i].error), 0);
          PUSHs(newRV_noinc((SV *)rec));
      }

      Safefree(errors);


HV *
get_scheduler_parameters(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PREINIT:
      virTypedParameterPtr params;
      int nparams;
      char *type;
    CODE:
      if (!(type = virDomainGetSchedulerType(dom, &nparams)))
          _croak_error();

      free(type);
      Newx(params, nparams, virTypedParameter);
      if (flags) {
          if (virDomainGetSchedulerParametersFlags(dom, params, &nparams, flags) < 0) {
              Safefree(params);
              _croak_error();
          }
      } else {
          if (virDomainGetSchedulerParameters(dom, params, &nparams) < 0) {
              Safefree(params);
              _croak_error();
          }
      }
      RETVAL = vir_typed_param_to_hv(params, nparams);
      Safefree(params);
  OUTPUT:
      RETVAL


void
set_scheduler_parameters(dom, newparams, flags=0)
      virDomainPtr dom;
      HV *newparams;
      unsigned int flags;
  PREINIT:
      virTypedParameterPtr params;
      int nparams;
      char *type;
    PPCODE:
      if (!(type = virDomainGetSchedulerType(dom, &nparams)))
          _croak_error();

      free(type);
      Newx(params, nparams, virTypedParameter);
      if (virDomainGetSchedulerParameters(dom, params, &nparams) < 0) {
          Safefree(params);
          _croak_error();
      }
      nparams = vir_typed_param_from_hv(newparams, params, nparams);
      if (flags) {
          if (virDomainSetSchedulerParametersFlags(dom, params, nparams, flags) < 0)
              _croak_error();
      } else {
          if (virDomainSetSchedulerParameters(dom, params, nparams) < 0)
              _croak_error();
      }
      Safefree(params);


HV *
get_memory_parameters(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PREINIT:
      virTypedParameterPtr params;
      int nparams;
    CODE:
      nparams = 0;
      if (virDomainGetMemoryParameters(dom, NULL, &nparams, 0) < 0)
          _croak_error();

      Newx(params, nparams, virTypedParameter);

      if (virDomainGetMemoryParameters(dom, params, &nparams, flags) < 0) {
          Safefree(params);
          _croak_error();
      }

      RETVAL = vir_typed_param_to_hv(params, nparams);
      Safefree(params);
  OUTPUT:
      RETVAL


void
set_memory_parameters(dom, newparams, flags=0)
      virDomainPtr dom;
      HV *newparams;
      unsigned int flags;
  PREINIT:
      virTypedParameterPtr params;
      int nparams;
    PPCODE:
      nparams = 0;
      if (virDomainGetMemoryParameters(dom, NULL, &nparams, 0) < 0)
          _croak_error();

      Newx(params, nparams, virTypedParameter);

      if (virDomainGetMemoryParameters(dom, params, &nparams, 0) < 0) {
          Safefree(params);
          _croak_error();
      }

      nparams = vir_typed_param_from_hv(newparams, params, nparams);

      if (virDomainSetMemoryParameters(dom, params, nparams, flags) < 0)
          _croak_error();
      Safefree(params);


HV *
get_numa_parameters(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PREINIT:
      virTypedParameterPtr params;
      int nparams;
    CODE:
      nparams = 0;
      if (virDomainGetNumaParameters(dom, NULL, &nparams, 0) < 0)
          _croak_error();

      Newx(params, nparams, virTypedParameter);

      if (virDomainGetNumaParameters(dom, params, &nparams, flags) < 0) {
          Safefree(params);
          _croak_error();
      }

      RETVAL = vir_typed_param_to_hv(params, nparams);
      Safefree(params);
  OUTPUT:
      RETVAL


void
set_numa_parameters(dom, newparams, flags=0)
      virDomainPtr dom;
      HV *newparams;
      unsigned int flags;
  PREINIT:
      virTypedParameterPtr params;
      int nparams;
    PPCODE:
      nparams = 0;
      if (virDomainGetNumaParameters(dom, NULL, &nparams, 0) < 0)
          _croak_error();

      Newx(params, nparams, virTypedParameter);

      if (virDomainGetNumaParameters(dom, params, &nparams, 0) < 0) {
          Safefree(params);
          _croak_error();
      }

      nparams = vir_typed_param_from_hv(newparams, params, nparams);

      if (virDomainSetNumaParameters(dom, params, nparams, flags) < 0)
          _croak_error();
      Safefree(params);


HV *
get_blkio_parameters(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PREINIT:
      virTypedParameterPtr params;
      int nparams;
    CODE:
      nparams = 0;
      if (virDomainGetBlkioParameters(dom, NULL, &nparams, 0) < 0)
          _croak_error();

      Newx(params, nparams, virBlkioParameter);

      if (virDomainGetBlkioParameters(dom, params, &nparams, flags) < 0) {
          Safefree(params);
          _croak_error();
      }

      RETVAL = vir_typed_param_to_hv(params, nparams);
      Safefree(params);
  OUTPUT:
      RETVAL


void
set_blkio_parameters(dom, newparams, flags=0)
      virDomainPtr dom;
      HV *newparams;
      unsigned int flags;
  PREINIT:
      virTypedParameterPtr params;
      int nparams;
    PPCODE:
      nparams = 0;
      if (virDomainGetBlkioParameters(dom, NULL, &nparams, 0) < 0)
          _croak_error();

      Newx(params, nparams, virBlkioParameter);

      if (virDomainGetBlkioParameters(dom, params, &nparams, 0) < 0) {
          Safefree(params);
          _croak_error();
      }

      nparams = vir_typed_param_from_hv(newparams, params, nparams);

      if (virDomainSetBlkioParameters(dom, params, nparams,
                                      flags) < 0)
          _croak_error();
      Safefree(params);


HV *
get_perf_events(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PREINIT:
      virTypedParameterPtr params = NULL;
      int nparams = 0;
    CODE:
      if (virDomainGetPerfEvents(dom, &params, &nparams, flags) < 0) {
          Safefree(params);
          _croak_error();
      }

      RETVAL = vir_typed_param_to_hv(params, nparams);
      Safefree(params);
  OUTPUT:
      RETVAL


void
set_perf_events(dom, newparams, flags=0)
      virDomainPtr dom;
      HV *newparams;
      unsigned int flags;
  PREINIT:
      virTypedParameterPtr params = NULL;
      int nparams = 0;
    PPCODE:
      if (virDomainGetPerfEvents(dom, &params, &nparams, 0) < 0) {
          Safefree(params);
          _croak_error();
      }

      nparams = vir_typed_param_from_hv(newparams, params, nparams);

      if (virDomainSetPerfEvents(dom, params, nparams, flags) < 0)
          _croak_error();
      Safefree(params);


unsigned long
get_max_memory(dom)
      virDomainPtr dom;
    CODE:
      if (!(RETVAL = virDomainGetMaxMemory(dom)))
          _croak_error();
  OUTPUT:
      RETVAL


void
set_max_memory(dom, val)
      virDomainPtr dom;
      unsigned long val;
  PPCODE:
      if (virDomainSetMaxMemory(dom, val) < 0)
	_croak_error();


void
set_memory(dom, val, flags=0)
      virDomainPtr dom;
      unsigned long val;
      unsigned int flags;
  PPCODE:
      if (flags) {
          if (virDomainSetMemoryFlags(dom, val, flags) < 0)
              _croak_error();
      } else {
          if (virDomainSetMemory(dom, val) < 0)
              _croak_error();
      }


void
set_memory_stats_period(dom, val, flags=0)
      virDomainPtr dom;
      int val;
      unsigned int flags;
  PPCODE:
      if (virDomainSetMemoryStatsPeriod(dom, val, flags) < 0)
          _croak_error();


int
get_max_vcpus(dom)
      virDomainPtr dom;
    CODE:
      if (!(RETVAL = virDomainGetMaxVcpus(dom)))
          _croak_error();
  OUTPUT:
      RETVAL


void
set_vcpus(dom, num, flags=0)
      virDomainPtr dom;
      int num;
      int flags;
  PPCODE:
      if (flags) {
          if (virDomainSetVcpusFlags(dom, num, flags) < 0)
              _croak_error();
      } else {
          if (virDomainSetVcpus(dom, num) < 0)
              _croak_error();
      }

void
set_vcpu(dom, cpumap, state, flags=0)
    virDomainPtr dom;
    const char *cpumap;
    int state;
    unsigned int flags;
PPCODE:
    if (virDomainSetVcpu(dom, cpumap, state, flags) < 0)
        _croak_error();

int
get_vcpus(dom, flags=0)
    virDomainPtr dom;
    int flags;
  CODE:
    if ((RETVAL = virDomainGetVcpusFlags(dom, flags)) < 0)
        _croak_error();
OUTPUT:
    RETVAL


void
set_guest_vcpus(dom, cpumap, state, flags=0)
      virDomainPtr dom;
      const char *cpumap;
      int state;
      unsigned int flags;
  PPCODE:
      if (virDomainSetGuestVcpus(dom, cpumap, state, flags) < 0)
          _croak_error();


HV *
get_guest_vcpus(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PREINIT:
      virTypedParameterPtr params;
      unsigned int nparams;
    CODE:
      if (virDomainGetGuestVcpus(dom, &params, &nparams, flags) < 0) {
          _croak_error();
      }
      RETVAL = vir_typed_param_to_hv(params, nparams);
      virTypedParamsFree(params, nparams);
  OUTPUT:
      RETVAL


void
set_autostart(dom, autostart)
      virDomainPtr dom;
      int autostart;
  PPCODE:
      if (virDomainSetAutostart(dom, autostart) < 0)
          _croak_error();


int
get_autostart(dom)
      virDomainPtr dom;
 PREINIT:
      int autostart;
    CODE:
      if (virDomainGetAutostart(dom, &autostart) < 0)
          _croak_error();
      RETVAL = autostart;
  OUTPUT:
      RETVAL


char *
get_scheduler_type(dom)
      virDomainPtr dom;
PREINIT:
      int nparams;
    CODE:
      if ((RETVAL = virDomainGetSchedulerType(dom, &nparams)) == NULL)
          _croak_error();
   OUTPUT:
      RETVAL


SV *
get_os_type(dom)
      virDomainPtr dom;
  PREINIT:
      char *type;
    CODE:
      if (!(type = virDomainGetOSType(dom)))
          _croak_error();

      RETVAL = newSVpv(type, 0);
      free(type);
  OUTPUT:
      RETVAL


SV *
get_xml_description(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PREINIT:
      char *xml;
    CODE:
      if (!(xml = virDomainGetXMLDesc(dom, flags)))
          _croak_error();

      RETVAL = newSVpv(xml, 0);
      free(xml);
  OUTPUT:
      RETVAL


void
shutdown(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
    PPCODE:
      if (flags) {
          if (virDomainShutdownFlags(dom, flags) < 0)
              _croak_error();
      } else {
          if (virDomainShutdown(dom) < 0)
              _croak_error();
      }


void
reboot(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
    PPCODE:
      if (virDomainReboot(dom, flags) < 0)
          _croak_error();


void
pm_suspend_for_duration(dom, target, duration, flags=0)
      virDomainPtr dom;
      unsigned int target;
      SV *duration;
      unsigned int flags;
  PPCODE:
      if (virDomainPMSuspendForDuration(dom, target, virt_SvIVull(duration), flags) < 0)
          _croak_error();


void
reset(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
    PPCODE:
      if (virDomainReset(dom, flags) < 0)
          _croak_error();


void
inject_nmi(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
    PPCODE:
      if (virDomainInjectNMI(dom, flags) < 0)
          _croak_error();


void
undefine(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
    PPCODE:
      if (flags) {
          if (virDomainUndefineFlags(dom, flags) < 0)
              _croak_error();
      } else {
          if (virDomainUndefine(dom) < 0)
              _croak_error();
      }


void
create(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
    PPCODE:
      if (flags) {
          if (virDomainCreateWithFlags(dom, flags) < 0)
              _croak_error();
      } else {
          if (virDomainCreate(dom) < 0)
              _croak_error();
      }



void
create_with_files(dom, fdssv, flags=0)
      virDomainPtr dom;
      SV *fdssv;
      unsigned int flags;
 PREINIT:
      AV *fdsav;
      unsigned int nfds;
      int *fds;
      int i;
  PPCODE:
      if (!SvROK(fdssv))
          return;
      fdsav = (AV*)SvRV(fdssv);
      nfds = av_len(fdsav) + 1;
      Newx(fds, nfds, int);

      for (i = 0 ; i < nfds ; i++) {
          SV **fd = av_fetch(fdsav, i, 0);
          fds[i] = SvIV(*fd);
      }

      if (virDomainCreateWithFiles(dom, nfds, fds, flags) < 0) {
          Safefree(fds);
          _croak_error();
      }

      Safefree(fds);


virDomainPtr
_migrate(dom, destcon, newparams, flags=0)
     virDomainPtr dom;
     virConnectPtr destcon;
     HV *newparams;
     unsigned long flags;
  PREINIT:
     virTypedParameterPtr params;
     int nparams;
    CODE:
     nparams = 15;
     Newx(params, nparams, virTypedParameter);

     strncpy(params[0].field, VIR_MIGRATE_PARAM_URI,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[0].type = VIR_TYPED_PARAM_STRING;

     strncpy(params[1].field, VIR_MIGRATE_PARAM_DEST_NAME,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[1].type = VIR_TYPED_PARAM_STRING;

     strncpy(params[2].field, VIR_MIGRATE_PARAM_DEST_XML,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[2].type = VIR_TYPED_PARAM_STRING;

     strncpy(params[3].field, VIR_MIGRATE_PARAM_GRAPHICS_URI,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[3].type = VIR_TYPED_PARAM_STRING;

     strncpy(params[4].field, VIR_MIGRATE_PARAM_BANDWIDTH,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[4].type = VIR_TYPED_PARAM_ULLONG;

     strncpy(params[5].field, VIR_MIGRATE_PARAM_LISTEN_ADDRESS,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[5].type = VIR_TYPED_PARAM_STRING;

     strncpy(params[6].field, VIR_MIGRATE_PARAM_DISKS_PORT,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[6].type = VIR_TYPED_PARAM_INT;

     strncpy(params[7].field, VIR_MIGRATE_PARAM_COMPRESSION,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[7].type = VIR_TYPED_PARAM_STRING;

     strncpy(params[8].field, VIR_MIGRATE_PARAM_COMPRESSION_MT_DTHREADS,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[8].type = VIR_TYPED_PARAM_INT;

     strncpy(params[9].field, VIR_MIGRATE_PARAM_COMPRESSION_MT_LEVEL,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[9].type = VIR_TYPED_PARAM_INT;

     strncpy(params[10].field, VIR_MIGRATE_PARAM_COMPRESSION_MT_THREADS,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[10].type = VIR_TYPED_PARAM_INT;

     strncpy(params[11].field, VIR_MIGRATE_PARAM_COMPRESSION_XBZRLE_CACHE,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[11].type = VIR_TYPED_PARAM_ULLONG;

     strncpy(params[12].field, VIR_MIGRATE_PARAM_PERSIST_XML,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[12].type = VIR_TYPED_PARAM_STRING;

     strncpy(params[13].field, VIR_MIGRATE_PARAM_AUTO_CONVERGE_INITIAL,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[13].type = VIR_TYPED_PARAM_INT;

     strncpy(params[14].field, VIR_MIGRATE_PARAM_AUTO_CONVERGE_INCREMENT,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[14].type = VIR_TYPED_PARAM_INT;

     nparams = vir_typed_param_from_hv(newparams, params, nparams);

     vir_typed_param_add_string_list_from_hv(newparams, &params, &nparams,
					     VIR_MIGRATE_PARAM_MIGRATE_DISKS);

     /* No need to support virDomainMigrate/virDomainMigrate2, since
      * virDomainMigrate3 takes care to call the older APIs internally
      * if it is possible todo so
      */
     if ((RETVAL = virDomainMigrate3(dom, destcon, params, nparams, flags)) == NULL) {
         Safefree(params);
         _croak_error();
     }
     Safefree(params);
 OUTPUT:
     RETVAL


void
_migrate_to_uri(dom, desturi, newparams, flags=0)
     virDomainPtr dom;
     const char *desturi;
     HV *newparams;
     unsigned long flags;
  PREINIT:
     virTypedParameterPtr params;
     int nparams;
  PPCODE:
     nparams = 15;
     Newx(params, nparams, virTypedParameter);

     strncpy(params[0].field, VIR_MIGRATE_PARAM_URI,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[0].type = VIR_TYPED_PARAM_STRING;

     strncpy(params[1].field, VIR_MIGRATE_PARAM_DEST_NAME,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[1].type = VIR_TYPED_PARAM_STRING;

     strncpy(params[2].field, VIR_MIGRATE_PARAM_DEST_XML,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[2].type = VIR_TYPED_PARAM_STRING;

     strncpy(params[3].field, VIR_MIGRATE_PARAM_GRAPHICS_URI,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[3].type = VIR_TYPED_PARAM_STRING;

     strncpy(params[4].field, VIR_MIGRATE_PARAM_BANDWIDTH,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[4].type = VIR_TYPED_PARAM_ULLONG;

     strncpy(params[5].field, VIR_MIGRATE_PARAM_LISTEN_ADDRESS,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[5].type = VIR_TYPED_PARAM_STRING;

     strncpy(params[6].field, VIR_MIGRATE_PARAM_DISKS_PORT,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[6].type = VIR_TYPED_PARAM_INT;

     strncpy(params[7].field, VIR_MIGRATE_PARAM_COMPRESSION,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[7].type = VIR_TYPED_PARAM_STRING;

     strncpy(params[8].field, VIR_MIGRATE_PARAM_COMPRESSION_MT_DTHREADS,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[8].type = VIR_TYPED_PARAM_INT;

     strncpy(params[9].field, VIR_MIGRATE_PARAM_COMPRESSION_MT_LEVEL,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[9].type = VIR_TYPED_PARAM_INT;

     strncpy(params[10].field, VIR_MIGRATE_PARAM_COMPRESSION_MT_THREADS,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[10].type = VIR_TYPED_PARAM_INT;

     strncpy(params[11].field, VIR_MIGRATE_PARAM_COMPRESSION_XBZRLE_CACHE,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[11].type = VIR_TYPED_PARAM_ULLONG;

     strncpy(params[12].field, VIR_MIGRATE_PARAM_PERSIST_XML,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[12].type = VIR_TYPED_PARAM_STRING;

     strncpy(params[13].field, VIR_MIGRATE_PARAM_AUTO_CONVERGE_INITIAL,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[13].type = VIR_TYPED_PARAM_INT;

     strncpy(params[14].field, VIR_MIGRATE_PARAM_AUTO_CONVERGE_INCREMENT,
             VIR_TYPED_PARAM_FIELD_LENGTH);
     params[14].type = VIR_TYPED_PARAM_INT;

     nparams = vir_typed_param_from_hv(newparams, params, nparams);

     vir_typed_param_add_string_list_from_hv(newparams, &params, &nparams,
					     VIR_MIGRATE_PARAM_MIGRATE_DISKS);

     /* No need to support virDomainMigrateToURI/virDomainMigrateToURI2, since
      * virDomainMigrate3 takes care to call the older APIs internally
      * if it is possible todo so
      */
     if (virDomainMigrateToURI3(dom, desturi, params, nparams, flags) < 0) {
         Safefree(params);
         _croak_error();
     }
     Safefree(params);


void
migrate_set_max_downtime(dom, downtime, flags=0)
     virDomainPtr dom;
     SV *downtime;
     unsigned int flags;
 PREINIT:
     unsigned long long downtimeVal;
  PPCODE:
     downtimeVal = virt_SvIVull(downtime);
     if (virDomainMigrateSetMaxDowntime(dom, downtimeVal, flags) < 0)
         _croak_error();


void
migrate_set_max_speed(dom, bandwidth, flags=0)
     virDomainPtr dom;
     unsigned long bandwidth;
     unsigned int flags;
  PPCODE:
     if (virDomainMigrateSetMaxSpeed(dom, bandwidth, flags) < 0)
         _croak_error();


unsigned long
migrate_get_max_speed(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PREINIT:
      unsigned long speed;
    CODE:
      if (virDomainMigrateGetMaxSpeed(dom, &speed, flags) < 0)
          _croak_error();

      RETVAL = speed;
  OUTPUT:
      RETVAL


void
migrate_set_compression_cache(dom, cacheSizeSv, flags=0)
      virDomainPtr dom;
      SV *cacheSizeSv;
      unsigned int flags;
 PREINIT:
      unsigned long long cacheSize;
  PPCODE:
      cacheSize = virt_SvIVull(cacheSizeSv);
      if (virDomainMigrateSetCompressionCache(dom, cacheSize, flags) < 0)
          _croak_error();


SV *
migrate_get_compression_cache(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PREINIT:
      unsigned long long cacheSize;
    CODE:
      if (virDomainMigrateGetCompressionCache(dom, &cacheSize, flags) < 0)
          _croak_error();

      RETVAL = virt_newSVull(cacheSize);
  OUTPUT:
      RETVAL


void
migrate_start_post_copy(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PPCODE:
      if (virDomainMigrateStartPostCopy(dom, flags) < 0)
          _croak_error();


void
attach_device(dom, xml, flags=0)
      virDomainPtr dom;
      const char *xml;
      unsigned int flags;
    PPCODE:
      if (flags) {
          if (virDomainAttachDeviceFlags(dom, xml, flags) < 0)
              _croak_error();
      } else {
          if (virDomainAttachDevice(dom, xml) < 0)
              _croak_error();
      }


void
detach_device(dom, xml, flags=0)
      virDomainPtr dom;
      const char *xml;
      unsigned int flags;
    PPCODE:
      if (flags) {
          if (virDomainDetachDeviceFlags(dom, xml, flags) < 0)
              _croak_error();
      } else {
          if (virDomainDetachDevice(dom, xml) < 0)
              _croak_error();
      }


void
update_device(dom, xml, flags=0)
      virDomainPtr dom;
      const char *xml;
      unsigned int flags;
    PPCODE:
      if (virDomainUpdateDeviceFlags(dom, xml, flags) < 0)
          _croak_error();


HV *
get_block_iotune(dom, disk, flags=0)
      virDomainPtr dom;
      const char *disk;
      unsigned int flags;
  PREINIT:
      virTypedParameterPtr params;
      int nparams;
    CODE:
      nparams = 0;
      RETVAL = NULL;
      if (virDomainGetBlockIoTune(dom, disk, NULL, &nparams, 0) < 0)
          _croak_error();

      Newx(params, nparams, virTypedParameter);
      if (virDomainGetBlockIoTune(dom, disk, params, &nparams, flags) < 0) {
          Safefree(params);
          _croak_error();
      }

      RETVAL = vir_typed_param_to_hv(params, nparams);
      Safefree(params);
  OUTPUT:
      RETVAL


void
set_block_iotune(dom, disk, newparams, flags=0)
      virDomainPtr dom;
      const char *disk;
      HV *newparams;
      unsigned int flags;
  PREINIT:
      virTypedParameterPtr params;
      int nparams;
  PPCODE:
      nparams = 0;
      if (virDomainGetBlockIoTune(dom, disk, NULL, &nparams, 0) < 0)
          _croak_error();
      Newx(params, nparams, virTypedParameter);

      if (virDomainGetBlockIoTune(dom, disk, params, &nparams, 0) < 0) {
          Safefree(params);
          _croak_error();
      }

      nparams = vir_typed_param_from_hv(newparams, params, nparams);
      if (virDomainSetBlockIoTune(dom, disk, params, nparams, flags) < 0)
          _croak_error();


HV *
get_interface_parameters(dom, intf, flags=0)
      virDomainPtr dom;
      const char *intf;
      unsigned int flags;
  PREINIT:
      virTypedParameterPtr params;
      int nparams;
    CODE:
      nparams = 0;
      RETVAL = NULL;
      if (virDomainGetInterfaceParameters(dom, intf, NULL, &nparams, 0) < 0)
          _croak_error();

      Newx(params, nparams, virTypedParameter);
      if (virDomainGetInterfaceParameters(dom, intf, params, &nparams, flags) < 0) {
          Safefree(params);
          _croak_error();
      }

      RETVAL = vir_typed_param_to_hv(params, nparams);
      Safefree(params);
  OUTPUT:
      RETVAL


void
set_interface_parameters(dom, intf, newparams, flags=0)
      virDomainPtr dom;
      const char *intf;
      HV *newparams;
      unsigned int flags;
  PREINIT:
      virTypedParameterPtr params;
      int nparams;
  PPCODE:
      nparams = 0;
      if (virDomainGetInterfaceParameters(dom, intf, NULL, &nparams, 0) < 0)
          _croak_error();
      Newx(params, nparams, virTypedParameter);

      if (virDomainGetInterfaceParameters(dom, intf, params, &nparams, 0) < 0) {
          Safefree(params);
          _croak_error();
      }

      nparams = vir_typed_param_from_hv(newparams, params, nparams);
      if (virDomainSetInterfaceParameters(dom, intf, params, nparams, flags) < 0)
          _croak_error();


HV *
block_stats(dom, path, flags=0)
      virDomainPtr dom;
      const char *path;
      unsigned int flags;
  PREINIT:
      virDomainBlockStatsStruct stats;
      virTypedParameterPtr params;
      int nparams;
      unsigned int i;
      const char *field;
    CODE:
      nparams = 0;
      RETVAL = NULL;
      if (virDomainBlockStatsFlags(dom, path, NULL, &nparams, 0) < 0) {
          virErrorPtr err = virGetLastError();
          if (err && err->code == VIR_ERR_NO_SUPPORT && !flags) {
              if (virDomainBlockStats(dom, path, &stats, sizeof(stats)) < 0)
                  _croak_error();

              RETVAL = (HV *)sv_2mortal((SV*)newHV());
              (void)hv_store (RETVAL, "rd_req", 6, virt_newSVll(stats.rd_req), 0);
              (void)hv_store (RETVAL, "rd_bytes", 8, virt_newSVll(stats.rd_bytes), 0);
              (void)hv_store (RETVAL, "wr_req", 6, virt_newSVll(stats.wr_req), 0);
              (void)hv_store (RETVAL, "wr_bytes", 8, virt_newSVll(stats.wr_bytes), 0);
              (void)hv_store (RETVAL, "errs", 4, virt_newSVll(stats.errs), 0);
          } else {
              _croak_error();
          }
      } else {
          Newx(params, nparams, virTypedParameter);

          if (virDomainBlockStatsFlags(dom, path, params, &nparams, flags) < 0) {
              Safefree(params);
              _croak_error();
          }

          RETVAL = vir_typed_param_to_hv(params, nparams);
          for (i = 0 ; i < nparams ; i++) {
              field = NULL;
              /* For back compat with previous hash above */
              if (strcmp(params[i].field, "rd_operations") == 0)
                  field = "rd_reqs";
              else if (strcmp(params[i].field, "wr_operations") == 0)
                  field = "wr_reqs";
              else if (strcmp(params[i].field, "flush_operations") == 0)
                  field = "flush_reqs";
              if (field) {
                  SV *val = hv_delete(RETVAL, params[i].field, strlen(params[i].field), 0);
                  SvREFCNT_inc(val);
                  (void)hv_store(RETVAL, field, strlen(field), val, 0);
              }
          }
          Safefree(params);
      }
  OUTPUT:
      RETVAL


HV *
interface_stats(dom, path)
      virDomainPtr dom;
      const char *path;
  PREINIT:
      virDomainInterfaceStatsStruct stats;
    CODE:
      if (virDomainInterfaceStats(dom, path, &stats, sizeof(stats)) < 0)
          _croak_error();

      RETVAL = (HV *)sv_2mortal((SV*)newHV());
      (void)hv_store (RETVAL, "rx_bytes", 8, virt_newSVll(stats.rx_bytes), 0);
      (void)hv_store (RETVAL, "rx_packets", 10, virt_newSVll(stats.rx_packets), 0);
      (void)hv_store (RETVAL, "rx_errs", 7, virt_newSVll(stats.rx_errs), 0);
      (void)hv_store (RETVAL, "rx_drop", 7, virt_newSVll(stats.rx_drop), 0);
      (void)hv_store (RETVAL, "tx_bytes", 8, virt_newSVll(stats.tx_bytes), 0);
      (void)hv_store (RETVAL, "tx_packets", 10, virt_newSVll(stats.tx_packets), 0);
      (void)hv_store (RETVAL, "tx_errs", 7, virt_newSVll(stats.tx_errs), 0);
      (void)hv_store (RETVAL, "tx_drop", 7, virt_newSVll(stats.tx_drop), 0);
  OUTPUT:
      RETVAL


HV *
memory_stats(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PREINIT:
      virDomainMemoryStatPtr stats;
      int i, got;
    CODE:
      Newx(stats, VIR_DOMAIN_MEMORY_STAT_NR, virDomainMemoryStatStruct);
      if ((got = virDomainMemoryStats(dom, stats, VIR_DOMAIN_MEMORY_STAT_NR, flags)) < 0) {
          Safefree(stats);
          _croak_error();
      }
      RETVAL = (HV *)sv_2mortal((SV*)newHV());
      for (i = 0 ; i < got ; i++) {
          switch (stats[i].tag) {
          case VIR_DOMAIN_MEMORY_STAT_SWAP_IN:
              (void)hv_store (RETVAL, "swap_in", 7, virt_newSVll(stats[i].val), 0);
              break;

          case VIR_DOMAIN_MEMORY_STAT_SWAP_OUT:
              (void)hv_store (RETVAL, "swap_out", 8, virt_newSVll(stats[i].val), 0);
              break;

          case VIR_DOMAIN_MEMORY_STAT_MAJOR_FAULT:
              (void)hv_store (RETVAL, "major_fault", 11, virt_newSVll(stats[i].val), 0);
              break;

          case VIR_DOMAIN_MEMORY_STAT_MINOR_FAULT:
              (void)hv_store (RETVAL, "minor_fault", 11, virt_newSVll(stats[i].val), 0);
              break;

          case VIR_DOMAIN_MEMORY_STAT_UNUSED:
              (void)hv_store (RETVAL, "unused", 6, virt_newSVll(stats[i].val), 0);
              break;

          case VIR_DOMAIN_MEMORY_STAT_AVAILABLE:
              (void)hv_store (RETVAL, "available", 9, virt_newSVll(stats[i].val), 0);
              break;

          case VIR_DOMAIN_MEMORY_STAT_ACTUAL_BALLOON:
              (void)hv_store (RETVAL, "actual_balloon", 14, virt_newSVll(stats[i].val), 0);
              break;

          case VIR_DOMAIN_MEMORY_STAT_RSS:
              (void)hv_store (RETVAL, "rss", 3, virt_newSVll(stats[i].val), 0);
              break;

          case VIR_DOMAIN_MEMORY_STAT_LAST_UPDATE:
              (void)hv_store (RETVAL, "last_update", 11, virt_newSVll(stats[i].val), 0);
              break;

          case VIR_DOMAIN_MEMORY_STAT_USABLE:
              (void)hv_store (RETVAL, "usable", 6, virt_newSVll(stats[i].val), 0);
              break;
          }
      }
      Safefree(stats);
  OUTPUT:
      RETVAL


void
send_key(dom, codeset, holdtime, keycodesSV, flags=0)
      virDomainPtr dom;
      unsigned int codeset;
      unsigned int holdtime;
      SV *keycodesSV;
      unsigned int flags;
PREINIT:
      AV *keycodesAV;
      unsigned int *keycodes;
      int nkeycodes;
      int i;
   PPCODE:
      if (!SvROK(keycodesSV))
          return;
      keycodesAV = (AV*)SvRV(keycodesSV);
      nkeycodes = av_len(keycodesAV) + 1;
      Newx(keycodes, nkeycodes, unsigned int);

      for (i = 0 ; i < nkeycodes ; i++) {
          SV **code = av_fetch(keycodesAV, i, 0);
          keycodes[i] = SvIV(*code);
      }

      if (virDomainSendKey(dom, codeset, holdtime, keycodes, nkeycodes, flags) < 0) {
          Safefree(keycodes);
          _croak_error();
      }

      Safefree(keycodes);


void
block_resize(dom, disk, size, flags=0)
      virDomainPtr dom;
      const char *disk;
      SV *size;
      unsigned int flags;
  PPCODE:
      if (virDomainBlockResize(dom, disk, virt_SvIVull(size), flags) < 0)
          _croak_error();


SV *
block_peek(dom, path, offset, size, flags=0)
      virDomainPtr dom;
      const char *path;
      unsigned int offset;
      size_t size;
      unsigned int flags;
  PREINIT:
      char *buf;
    CODE:
      Newx(buf, size, char);
      if (virDomainBlockPeek(dom, path, offset, size, buf, flags) < 0) {
          Safefree(buf);
          _croak_error();
      }
      RETVAL = newSVpvn(buf, size);
  OUTPUT:
      RETVAL


SV *
memory_peek(dom, offset, size, flags=0)
      virDomainPtr dom;
      unsigned int offset;
      size_t size;
      unsigned int flags;
  PREINIT:
      char *buf;
    CODE:
      Newx(buf, size, char);
      if (virDomainMemoryPeek(dom, offset, size, buf, flags) < 0) {
          Safefree(buf);
          _croak_error();
      }
      RETVAL = newSVpvn(buf, size);
  OUTPUT:
      RETVAL


HV *
get_security_label(dom)
      virDomainPtr dom;
 PREINIT:
      virSecurityLabel seclabel;
    CODE:
      if (virDomainGetSecurityLabel(dom, &seclabel) < 0)
          _croak_error();

      RETVAL = (HV *)sv_2mortal((SV*)newHV());
      (void)hv_store (RETVAL, "label", 5, newSVpv(seclabel.label, 0), 0);
      (void)hv_store (RETVAL, "enforcing", 9, newSViv(seclabel.enforcing), 0);
   OUTPUT:
      RETVAL


void
get_security_label_list(dom)
      virDomainPtr dom;
 PREINIT:
      virSecurityLabelPtr seclabels;
      int nlabels;
      int i;
    PPCODE:
      if ((nlabels = virDomainGetSecurityLabelList(dom, &seclabels)) < 0)
          _croak_error();

      EXTEND(SP, nlabels);
      for (i = 0 ; i < nlabels ; i++) {
          HV *rec = (HV *)sv_2mortal((SV*)newHV());
          (void)hv_store (rec, "label", 5, newSVpv(seclabels[i].label, 0), 0);
          (void)hv_store (rec, "enforcing", 9, newSViv(seclabels[i].enforcing), 0);
          PUSHs(newRV_noinc((SV*)rec));
      }
      free(seclabels);


void
get_cpu_stats(dom, start_cpu, ncpus, flags=0)
      virDomainPtr dom;
      int start_cpu;
      unsigned int ncpus;
      unsigned int flags;
 PREINIT:
      virTypedParameterPtr params;
      unsigned int nparams;
      int ret;
      int i;
   PPCODE:
      if ((ret = virDomainGetCPUStats(dom, NULL, 0, 0, 1, 0)) < 0)
          _croak_error();
      nparams = ret;

      if (ncpus == 0) {
          if ((ret = virDomainGetCPUStats(dom, NULL, 0, 0, 0, 0)) < 0)
              _croak_error();
          ncpus = ret;
      }

      Newx(params, ncpus * nparams, virTypedParameter);
      if ((ret = virDomainGetCPUStats(dom, params, nparams, start_cpu, ncpus, flags)) < 0) {
          Safefree(params);
          _croak_error();
      }

      EXTEND(SP, ret);
      for (i = 0 ; i < ret ; i++) {
          HV *rec = vir_typed_param_to_hv(params + (i * nparams), nparams);
          PUSHs(newRV_noinc((SV *)rec));
      }

      Safefree(params);


void
get_vcpu_info(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
 PREINIT:
      virVcpuInfoPtr info;
      unsigned char *cpumaps;
      size_t maplen;
      virNodeInfo nodeinfo;
      virDomainInfo dominfo;
      int nvCpus;
      int i;
   PPCODE:
      if (virNodeGetInfo(virDomainGetConnect(dom), &nodeinfo) < 0)
          _croak_error();
      if (virDomainGetInfo(dom, &dominfo) < 0)
          _croak_error();

      maplen = VIR_CPU_MAPLEN(VIR_NODEINFO_MAXCPUS(nodeinfo));
      Newx(cpumaps, dominfo.nrVirtCpu * maplen, unsigned char);
      if (!flags) {
	  Newx(info, dominfo.nrVirtCpu, virVcpuInfo);
          if ((nvCpus = virDomainGetVcpus(dom, info, dominfo.nrVirtCpu, cpumaps, maplen)) < 0) {
              virErrorPtr err = virGetLastError();
              Safefree(info);
              info = NULL;
              if (err && err->code == VIR_ERR_OPERATION_INVALID) {
                  if ((nvCpus = virDomainGetVcpuPinInfo(dom, dominfo.nrVirtCpu, cpumaps, maplen, flags)) < 0) {
                      Safefree(cpumaps);
                      _croak_error();
                  }
              } else {
                  Safefree(cpumaps);
                  _croak_error();
              }
          }
      } else {
          info = NULL;
          if ((nvCpus = virDomainGetVcpuPinInfo(dom, dominfo.nrVirtCpu, cpumaps, maplen, flags)) < 0) {
              Safefree(cpumaps);
              _croak_error();
          }
      }

      EXTEND(SP, nvCpus);
      for (i = 0 ; i < nvCpus ; i++) {
          HV *rec = newHV();
          (void)hv_store(rec, "number", 6, newSViv(i), 0);
          if (info) {
              (void)hv_store(rec, "state", 5, newSViv(info[i].state), 0);
              (void)hv_store(rec, "cpuTime", 7, virt_newSVull(info[i].cpuTime), 0);
              (void)hv_store(rec, "cpu", 3, newSViv(info[i].cpu), 0);
          } else {
              (void)hv_store(rec, "state", 5, newSViv(0), 0);
              (void)hv_store(rec, "cpuTime", 7, virt_newSVull(0), 0);
              (void)hv_store(rec, "cpu", 3, newSViv(0), 0);
          }
          (void)hv_store(rec, "affinity", 8, newSVpvn((char*)cpumaps + (i *maplen), maplen), 0);
          PUSHs(newRV_noinc((SV *)rec));
      }

      if (info)
          Safefree(info);
      Safefree(cpumaps);


void
pin_vcpu(dom, vcpu, mask, flags=0)
     virDomainPtr dom;
     unsigned int vcpu;
     SV *mask;
     unsigned int flags;
PREINIT:
     STRLEN masklen;
     unsigned char *maps;
 PPCODE:
     maps = (unsigned char *)SvPV(mask, masklen);
     if (flags) {
         if (virDomainPinVcpuFlags(dom, vcpu, maps, masklen, flags) < 0)
             _croak_error();
     } else {
         if (virDomainPinVcpu(dom, vcpu, maps, masklen) < 0)
             _croak_error();
     }


void
pin_emulator(dom, mask, flags=0)
     virDomainPtr dom;
     SV *mask;
     unsigned int flags;
PREINIT:
     STRLEN masklen;
     unsigned char *maps;
 PPCODE:
     maps = (unsigned char *)SvPV(mask, masklen);
     if (virDomainPinEmulator(dom, maps, masklen, flags) < 0)
         _croak_error();


SV *
get_emulator_pin_info(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
 PREINIT:
      unsigned char *cpumaps;
      int maplen;
      virNodeInfo nodeinfo;
      int nCpus;
   CODE:
      if (virNodeGetInfo(virDomainGetConnect(dom), &nodeinfo) < 0)
          _croak_error();

      nCpus = VIR_NODEINFO_MAXCPUS(nodeinfo);
      maplen = VIR_CPU_MAPLEN(nCpus);
      Newx(cpumaps, maplen, unsigned char);
      if ((virDomainGetEmulatorPinInfo(dom, cpumaps, maplen, flags)) < 0) {
          Safefree(cpumaps);
          _croak_error();
      }
      RETVAL = newSVpvn((char*)cpumaps, maplen);
      Safefree(cpumaps);
 OUTPUT:
      RETVAL


void
get_iothread_info(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
 PREINIT:
      virDomainIOThreadInfoPtr *iothrinfo;
      int niothreads;
      int i;
   PPCODE:
      if ((niothreads = virDomainGetIOThreadInfo(dom, &iothrinfo,
                                                 flags)) < 0)
          _croak_error();

      EXTEND(SP, niothreads);
      for (i = 0 ; i < niothreads ; i++) {
          HV *rec = newHV();
          (void)hv_store(rec, "number", 6,
                         newSViv(iothrinfo[i]->iothread_id), 0);
          (void)hv_store(rec, "affinity", 8,
                         newSVpvn((char*)iothrinfo[i]->cpumap,
                                  iothrinfo[i]->cpumaplen), 0);
          PUSHs(newRV_noinc((SV *)rec));
      }

      for (i = 0 ; i < niothreads ; i++) {
          virDomainIOThreadInfoFree(iothrinfo[i]);
      }
      free(iothrinfo);


void
pin_iothread(dom, iothread_id, mask, flags=0)
     virDomainPtr dom;
     unsigned int iothread_id;
     SV *mask;
     unsigned int flags;
PREINIT:
     STRLEN masklen;
     unsigned char *maps;
 PPCODE:
     maps = (unsigned char *)SvPV(mask, masklen);
     if (virDomainPinIOThread(dom, iothread_id, maps, masklen, flags) < 0)
         _croak_error();


void
add_iothread(dom, iothread_id, flags=0)
     virDomainPtr dom;
     unsigned int iothread_id;
     unsigned int flags;
 PPCODE:
     if (virDomainAddIOThread(dom, iothread_id, flags) < 0)
         _croak_error();


void
del_iothread(dom, iothread_id, flags=0)
     virDomainPtr dom;
     unsigned int iothread_id;
     unsigned int flags;
 PPCODE:
     if (virDomainDelIOThread(dom, iothread_id, flags) < 0)
         _croak_error();


int
num_of_snapshots(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
    CODE:
      if ((RETVAL = virDomainSnapshotNum(dom, flags)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


void
list_snapshot_names(dom, maxnames, flags=0)
      virDomainPtr dom;
      int maxnames;
      unsigned int flags;
 PREINIT:
      char **names;
      int nsnap;
      int i;
  PPCODE:
      Newx(names, maxnames, char *);
      if ((nsnap = virDomainSnapshotListNames(dom, names, maxnames, flags)) < 0) {
          Safefree(names);
          _croak_error();
      }
      EXTEND(SP, nsnap);
      for (i = 0 ; i < nsnap ; i++) {
          PUSHs(sv_2mortal(newSVpv(names[i], 0)));
          free(names[i]);
      }
      Safefree(names);


void
list_all_snapshots(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
 PREINIT:
      virDomainSnapshotPtr *domsss;
      int i, ndomss;
      SV *domssrv;
  PPCODE:
      if ((ndomss = virDomainListAllSnapshots(dom, &domsss, flags)) < 0)
          _croak_error();

      EXTEND(SP, ndomss);
      for (i = 0 ; i < ndomss ; i++) {
          domssrv = sv_newmortal();
          sv_setref_pv(domssrv, "Sys::Virt::DomainSnapshot", domsss[i]);
          PUSHs(domssrv);
      }
      free(domsss);


int
has_current_snapshot(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
    CODE:
      if ((RETVAL = virDomainHasCurrentSnapshot(dom, flags)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


virDomainSnapshotPtr
current_snapshot(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
    CODE:
      if (!(RETVAL = virDomainSnapshotCurrent(dom, flags)))
          _croak_error();
  OUTPUT:
      RETVAL


void
fs_trim(dom, mountPoint, minimumsv, flags=0)
      virDomainPtr dom;
      const char *mountPoint;
      SV *minimumsv;
      unsigned int flags;
 PREINIT:
      unsigned long long minimum;
  PPCODE:
      minimum = virt_SvIVull(minimumsv);
      if (virDomainFSTrim(dom, mountPoint, minimum, flags) < 0)
          _croak_error();


void
fs_freeze(dom, mountPointsSV, flags=0)
      virDomainPtr dom;
      SV *mountPointsSV;
      unsigned int flags;
PREINIT:
      AV *mountPointsAV;
      const char **mountPoints;
      unsigned int nMountPoints;
      unsigned int i;
PPCODE:
      mountPointsAV = (AV*)SvRV(mountPointsSV);
      nMountPoints = av_len(mountPointsAV) + 1;
      if (nMountPoints) {
          Newx(mountPoints, nMountPoints, const char *);
          for (i = 0 ; i < nMountPoints ; i++) {
              SV **mountPoint = av_fetch(mountPointsAV, i, 0);
              mountPoints[i] = SvPV_nolen(*mountPoint);
          }
      } else {
	  mountPoints = NULL;
      }

      if (virDomainFSFreeze(dom, mountPoints, nMountPoints, flags) < 0) {
          Safefree(mountPoints);
          _croak_error();
      }

      Safefree(mountPoints);


void
fs_thaw(dom, mountPointsSV, flags=0)
      virDomainPtr dom;
      SV *mountPointsSV;
      unsigned int flags;
PREINIT:
      AV *mountPointsAV;
      const char **mountPoints;
      unsigned int nMountPoints;
      unsigned int i;
PPCODE:
      mountPointsAV = (AV*)SvRV(mountPointsSV);
      nMountPoints = av_len(mountPointsAV) + 1;
      if (nMountPoints) {
          Newx(mountPoints, nMountPoints, const char *);
          for (i = 0 ; i < nMountPoints ; i++) {
              SV **mountPoint = av_fetch(mountPointsAV, i, 0);
              mountPoints[i] = SvPV_nolen(*mountPoint);
          }
      } else {
	  mountPoints = NULL;
      }
      if (virDomainFSThaw(dom, mountPoints, nMountPoints, flags) < 0) {
          Safefree(mountPoints);
          _croak_error();
      }

      Safefree(mountPoints);

void
get_fs_info(dom, flags=0)
      virDomainPtr dom;
      unsigned int flags;
  PREINIT:
      virDomainFSInfoPtr *info;
      int ninfo;
      size_t i, j;
   PPCODE:

      if ((ninfo = virDomainGetFSInfo(dom, &info, flags)) < 0)
	_croak_error();

      EXTEND(SP, ninfo);
      for (i = 0 ; i < ninfo ; i++) {
	  HV *hv = newHV();
	  AV *av = newAV();

	  (void)hv_store(hv, "mountpoint", 10, newSVpv(info[i]->mountpoint, 0), 0);
	  (void)hv_store(hv, "name", 4, newSVpv(info[i]->name, 0), 0);
	  (void)hv_store(hv, "fstype", 6, newSVpv(info[i]->fstype, 0), 0);

	  for (j = 0; j < info[i]->ndevAlias; j++)
	      av_push(av, newSVpv(info[i]->devAlias[j], 0));

	  (void)hv_store(hv, "devalias", 8, newRV_noinc((SV*)av), 0);

	  virDomainFSInfoFree(info[i]);

	  PUSHs(newRV_noinc((SV*)hv));
      }
      free(info);

void
get_interface_addresses(dom, src, flags=0)
        virDomainPtr dom;
        unsigned int src;
        unsigned int flags;
    PREINIT:
        virDomainInterfacePtr *info;
        int ninfo;
        size_t i, j;
     PPCODE:
        if ((ninfo = virDomainInterfaceAddresses(dom, &info, src, flags)) < 0)
	    _croak_error();

        EXTEND(SP, ninfo);
        for (i = 0; i < ninfo; i++) {
	    HV *hv = newHV();
	    AV *av = newAV();

	    (void)hv_store(hv, "name", 4, newSVpv(info[i]->name, 0), 0);
	    if (info[i]->hwaddr) {
	      (void)hv_store(hv, "hwaddr", 6, newSVpv(info[i]->hwaddr, 0), 0);
	    }

	    for (j = 0; j < info[i]->naddrs; j++) {
	      HV *subhv = newHV();

	      (void)hv_store(subhv, "type", 4, newSViv(info[i]->addrs[j].type), 0);
	      (void)hv_store(subhv, "addr", 4, newSVpv(info[i]->addrs[j].addr, 0), 0);
	      (void)hv_store(subhv, "prefix", 6, newSViv(info[i]->addrs[j].prefix), 0);
	      av_push(av, newRV_noinc((SV*)subhv));
	    }
	    (void)hv_store(hv, "addrs", 5, newRV_noinc((SV*)av), 0);

	    virDomainInterfaceFree(info[i]);

	    PUSHs(newRV_noinc((SV*)hv));
	}
        free(info);

void
send_process_signal(dom, pidsv, signum, flags=0)
      virDomainPtr dom;
      SV *pidsv;
      unsigned int signum;
      unsigned int flags;
 PREINIT:
      long long pid;
  PPCODE:
      pid = virt_SvIVull(pidsv);
      if (virDomainSendProcessSignal(dom, pid, signum, flags) < 0)
          _croak_error();

void
set_block_threshold(dom, dev, thresholdsv, flags=0)
    virDomainPtr dom;
    const char *dev;
    SV *thresholdsv;
    unsigned int flags;
 PREINIT:
    unsigned long long threshold;
  PPCODE:
    threshold = virt_SvIVull(thresholdsv);
    if (virDomainSetBlockThreshold(dom, dev, threshold, flags) < 0)
        _croak_error();

void
destroy(dom_rv, flags=0)
      SV *dom_rv;
      unsigned int flags;
 PREINIT:
      virDomainPtr dom;
  PPCODE:
      dom = (virDomainPtr)SvIV((SV*)SvRV(dom_rv));
      if (flags) {
          if (virDomainDestroyFlags(dom, flags) < 0)
              _croak_error();
      } else {
          if (virDomainDestroy(dom) < 0)
              _croak_error();
      }


void
DESTROY(dom_rv)
      SV *dom_rv;
 PREINIT:
      virDomainPtr dom;
  PPCODE:
      dom = (virDomainPtr)SvIV((SV*)SvRV(dom_rv));
      if (dom) {
	virDomainFree(dom);
	sv_setiv((SV*)SvRV(dom_rv), 0);
      }


MODULE = Sys::Virt::Network  PACKAGE = Sys::Virt::Network


virNetworkPtr
_create_xml(con, xml)
      virConnectPtr con;
      const char *xml;
    CODE:
      if (!(RETVAL = virNetworkCreateXML(con, xml)))
          _croak_error();
  OUTPUT:
      RETVAL


virNetworkPtr
_define_xml(con, xml)
      virConnectPtr con;
      const char *xml;
    CODE:
      if (!(RETVAL = virNetworkDefineXML(con, xml)))
          _croak_error();
  OUTPUT:
      RETVAL


virNetworkPtr
_lookup_by_name(con, name)
      virConnectPtr con;
      const char *name;
    CODE:
      if (!(RETVAL = virNetworkLookupByName(con, name)))
          _croak_error();
  OUTPUT:
      RETVAL


virNetworkPtr
_lookup_by_uuid(con, uuid)
      virConnectPtr con;
      const unsigned char *uuid;
    CODE:
      if (!(RETVAL = virNetworkLookupByUUID(con, uuid)))
          _croak_error();
  OUTPUT:
      RETVAL


virNetworkPtr
_lookup_by_uuid_string(con, uuid)
      virConnectPtr con;
      const char *uuid;
    CODE:
      if (!(RETVAL = virNetworkLookupByUUIDString(con, uuid)))
          _croak_error();

  OUTPUT:
      RETVAL


SV *
get_uuid(net)
      virNetworkPtr net;
  PREINIT:
      unsigned char rawuuid[VIR_UUID_BUFLEN];
    CODE:
      if ((virNetworkGetUUID(net, rawuuid)) < 0)
          _croak_error();

      RETVAL = newSVpv((char*)rawuuid, sizeof(rawuuid));
  OUTPUT:
      RETVAL


SV *
get_uuid_string(net)
      virNetworkPtr net;
  PREINIT:
      char uuid[VIR_UUID_STRING_BUFLEN];
    CODE:
      if ((virNetworkGetUUIDString(net, uuid)) < 0)
          _croak_error();

      RETVAL = newSVpv(uuid, 0);
  OUTPUT:
      RETVAL


const char *
get_name(net)
      virNetworkPtr net;
    CODE:
      if (!(RETVAL = virNetworkGetName(net)))
          _croak_error();
  OUTPUT:
      RETVAL


int
is_active(net)
      virNetworkPtr net;
    CODE:
      if ((RETVAL = virNetworkIsActive(net)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


int
is_persistent(net)
      virNetworkPtr net;
    CODE:
      if ((RETVAL = virNetworkIsPersistent(net)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


SV *
get_bridge_name(net)
      virNetworkPtr net;
  PREINIT:
      char *name;
    CODE:
      if (!(name = virNetworkGetBridgeName(net)))
          _croak_error();

      RETVAL = newSVpv(name, 0);
      free(name);
  OUTPUT:
      RETVAL


SV *
get_xml_description(net, flags=0)
      virNetworkPtr net;
      unsigned int flags;
  PREINIT:
      char *xml;
    CODE:
      if (!(xml = virNetworkGetXMLDesc(net, flags)))
	 _croak_error();

      RETVAL = newSVpv(xml, 0);
      free(xml);
  OUTPUT:
      RETVAL


void
undefine(net)
      virNetworkPtr net;
    PPCODE:
      if (virNetworkUndefine(net) < 0)
          _croak_error();


void
create(net)
      virNetworkPtr net;
    PPCODE:
      if (virNetworkCreate(net) < 0)
          _croak_error();


void
update(net, command, section, parentIndex, xml, flags=0)
      virNetworkPtr net;
      unsigned int command;
      unsigned int section;
      int parentIndex;
      const char *xml;
      unsigned int flags;
    PPCODE:
      if (virNetworkUpdate(net, command, section, parentIndex, xml, flags) < 0)
          _croak_error();

void
set_autostart(net, autostart)
      virNetworkPtr net;
      int autostart;
  PPCODE:
      if (virNetworkSetAutostart(net, autostart) < 0)
          _croak_error();


int
get_autostart(net)
      virNetworkPtr net;
 PREINIT:
      int autostart;
    CODE:
      if (virNetworkGetAutostart(net, &autostart) < 0)
          _croak_error();

      RETVAL = autostart;
  OUTPUT:
      RETVAL


void
get_dhcp_leases(net, macsv=&PL_sv_undef, flags=0)
      virNetworkPtr net;
      SV *macsv;
      unsigned int flags;
PREINIT:
      virNetworkDHCPLeasePtr *leases = NULL;
      int nleases;
      const char *mac = NULL;
      int i;
  PPCODE:
      if (SvOK(macsv))
	  mac = SvPV_nolen(macsv);

      if ((nleases = virNetworkGetDHCPLeases(net, mac, &leases, flags)) < 0)
	  _croak_error();

      EXTEND(SP, nleases);
      for (i = 0 ; i < nleases ; i++) {
	  HV *hv = newHV();

	  (void)hv_store(hv, "iface", 5, newSVpv(leases[i]->iface, 0), 0);
	  (void)hv_store(hv, "expirytime", 10, virt_newSVll(leases[i]->expirytime), 0);
	  (void)hv_store(hv, "type", 4, newSViv(leases[i]->type), 0);
	  (void)hv_store(hv, "mac", 3, newSVpv(leases[i]->mac, 0), 0);
	  (void)hv_store(hv, "iaid", 4, newSVpv(leases[i]->iaid, 0), 0);
	  (void)hv_store(hv, "ipaddr", 6, newSVpv(leases[i]->ipaddr, 0), 0);
	  (void)hv_store(hv, "prefix", 6, newSViv(leases[i]->prefix), 0);
	  (void)hv_store(hv, "hostname", 8, newSVpv(leases[i]->hostname, 0), 0);
	  (void)hv_store(hv, "clientid", 8, newSVpv(leases[i]->clientid, 0), 0);

	  virNetworkDHCPLeaseFree(leases[i]);

	  PUSHs(newRV_noinc((SV*)hv));
      }
      free(leases);


void
destroy(net_rv)
      SV *net_rv;
 PREINIT:
      virNetworkPtr net;
  PPCODE:
      net = (virNetworkPtr)SvIV((SV*)SvRV(net_rv));
      if (virNetworkDestroy(net) < 0)
          _croak_error();


void
DESTROY(net_rv)
      SV *net_rv;
 PREINIT:
      virNetworkPtr net;
  PPCODE:
      net = (virNetworkPtr)SvIV((SV*)SvRV(net_rv));
      if (net) {
	virNetworkFree(net);
	sv_setiv((SV*)SvRV(net_rv), 0);
      }


MODULE = Sys::Virt::StoragePool  PACKAGE = Sys::Virt::StoragePool


virStoragePoolPtr
_create_xml(con, xml)
      virConnectPtr con;
      const char *xml;
    CODE:
      if (!(RETVAL = virStoragePoolCreateXML(con, xml, 0)))
          _croak_error();

  OUTPUT:
      RETVAL


virStoragePoolPtr
_define_xml(con, xml)
      virConnectPtr con;
      const char *xml;
    CODE:
      if (!(RETVAL = virStoragePoolDefineXML(con, xml, 0)))
          _croak_error();
  OUTPUT:
      RETVAL


virStoragePoolPtr
_lookup_by_name(con, name)
      virConnectPtr con;
      const char *name;
    CODE:
      if (!(RETVAL = virStoragePoolLookupByName(con, name)))
          _croak_error();
  OUTPUT:
      RETVAL


virStoragePoolPtr
_lookup_by_uuid(con, uuid)
      virConnectPtr con;
      const unsigned char *uuid;
    CODE:
      if (!(RETVAL = virStoragePoolLookupByUUID(con, uuid)))
          _croak_error();
  OUTPUT:
      RETVAL


virStoragePoolPtr
_lookup_by_uuid_string(con, uuid)
      virConnectPtr con;
      const char *uuid;
    CODE:
      if (!(RETVAL = virStoragePoolLookupByUUIDString(con, uuid)))
	_croak_error();
  OUTPUT:
      RETVAL


virStoragePoolPtr
_lookup_by_volume(vol)
      virStorageVolPtr vol;
    CODE:
      if (!(RETVAL = virStoragePoolLookupByVolume(vol)))
          _croak_error();
  OUTPUT:
      RETVAL


SV *
get_uuid(pool)
      virStoragePoolPtr pool;
  PREINIT:
      unsigned char rawuuid[VIR_UUID_BUFLEN];
    CODE:
      if ((virStoragePoolGetUUID(pool, rawuuid)) < 0)
          _croak_error();

      RETVAL = newSVpv((char*)rawuuid, sizeof(rawuuid));
  OUTPUT:
      RETVAL


SV *
get_uuid_string(pool)
      virStoragePoolPtr pool;
  PREINIT:
      char uuid[VIR_UUID_STRING_BUFLEN];
    CODE:
      if ((virStoragePoolGetUUIDString(pool, uuid)) < 0)
          _croak_error();

      RETVAL = newSVpv(uuid, 0);
  OUTPUT:
      RETVAL


const char *
get_name(pool)
      virStoragePoolPtr pool;
    CODE:
      if (!(RETVAL = virStoragePoolGetName(pool)))
          _croak_error();
  OUTPUT:
      RETVAL


int
is_active(pool)
      virStoragePoolPtr pool;
    CODE:
      if ((RETVAL = virStoragePoolIsActive(pool)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


int
is_persistent(pool)
      virStoragePoolPtr pool;
    CODE:
      if ((RETVAL = virStoragePoolIsPersistent(pool)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


SV *
get_xml_description(pool, flags=0)
      virStoragePoolPtr pool;
      unsigned int flags;
  PREINIT:
      char *xml;
    CODE:
      if (!(xml = virStoragePoolGetXMLDesc(pool, flags)))
          _croak_error();

      RETVAL = newSVpv(xml, 0);
      free(xml);
  OUTPUT:
      RETVAL


void
undefine(pool)
      virStoragePoolPtr pool;
    PPCODE:
      if (virStoragePoolUndefine(pool) < 0)
          _croak_error();


void
create(pool)
      virStoragePoolPtr pool;
    PPCODE:
      if (virStoragePoolCreate(pool, 0) < 0)
          _croak_error();


void
refresh(pool, flags=0)
      virStoragePoolPtr pool;
      int flags;
    PPCODE:
      if (virStoragePoolRefresh(pool, flags) < 0)
          _croak_error();


void
build(pool, flags=0)
      virStoragePoolPtr pool;
      int flags;
    PPCODE:
      if (virStoragePoolBuild(pool, flags) < 0)
          _croak_error();


void
delete(pool, flags=0)
      virStoragePoolPtr pool;
      int flags;
    PPCODE:
      if (virStoragePoolDelete(pool, flags) < 0)
          _croak_error();


void
set_autostart(pool, autostart)
      virStoragePoolPtr pool;
      int autostart;
  PPCODE:
      if (virStoragePoolSetAutostart(pool, autostart) < 0)
          _croak_error();


int
get_autostart(pool)
      virStoragePoolPtr pool;
 PREINIT:
      int autostart;
    CODE:
      if (virStoragePoolGetAutostart(pool, &autostart) < 0)
          _croak_error();

      RETVAL = autostart;
  OUTPUT:
      RETVAL


HV *
get_info(pool)
      virStoragePoolPtr pool;
  PREINIT:
      virStoragePoolInfo info;
    CODE:
      if (virStoragePoolGetInfo(pool, &info) < 0)
          _croak_error();

      RETVAL = (HV *)sv_2mortal((SV*)newHV());
      (void)hv_store (RETVAL, "state", 5, newSViv(info.state), 0);
      (void)hv_store (RETVAL, "capacity", 8, virt_newSVull(info.capacity), 0);
      (void)hv_store (RETVAL, "allocation", 10, virt_newSVull(info.allocation), 0);
      (void)hv_store (RETVAL, "available", 9, virt_newSVull(info.available), 0);
  OUTPUT:
      RETVAL


void
destroy(pool_rv)
      SV *pool_rv;
 PREINIT:
      virStoragePoolPtr pool;
  PPCODE:
      pool = (virStoragePoolPtr)SvIV((SV*)SvRV(pool_rv));
      if (virStoragePoolDestroy(pool) < 0)
          _croak_error();


int
num_of_storage_volumes(pool)
      virStoragePoolPtr pool;
    CODE:
      if ((RETVAL = virStoragePoolNumOfVolumes(pool)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


void
list_storage_vol_names(pool, maxnames)
      virStoragePoolPtr pool;
      int maxnames;
 PREINIT:
      char **names;
      int i, nnet;
  PPCODE:
      Newx(names, maxnames, char *);
      if ((nnet = virStoragePoolListVolumes(pool, names, maxnames)) < 0) {
          Safefree(names);
          _croak_error();
      }
      EXTEND(SP, nnet);
      for (i = 0 ; i < nnet ; i++) {
          PUSHs(sv_2mortal(newSVpv(names[i], 0)));
          free(names[i]);
      }
      Safefree(names);


void
list_all_volumes(pool, flags=0)
      virStoragePoolPtr pool;
      unsigned int flags;
 PREINIT:
      virStorageVolPtr *vols;
      int i, nvolss;
      SV *volssrv;
  PPCODE:
      if ((nvolss = virStoragePoolListAllVolumes(pool, &vols, flags)) < 0)
          _croak_error();

      EXTEND(SP, nvolss);
      for (i = 0 ; i < nvolss ; i++) {
          volssrv = sv_newmortal();
          sv_setref_pv(volssrv, "Sys::Virt::StorageVol", vols[i]);
          PUSHs(volssrv);
      }
      free(vols);




void
DESTROY(pool_rv)
      SV *pool_rv;
 PREINIT:
      virStoragePoolPtr pool;
  PPCODE:
      pool = (virStoragePoolPtr)SvIV((SV*)SvRV(pool_rv));
      if (pool) {
          virStoragePoolFree(pool);
          sv_setiv((SV*)SvRV(pool_rv), 0);
      }


MODULE = Sys::Virt::StorageVol  PACKAGE = Sys::Virt::StorageVol


virStorageVolPtr
_create_xml(pool, xml, flags=0)
      virStoragePoolPtr pool;
      const char *xml;
      int flags;
    CODE:
      if (!(RETVAL = virStorageVolCreateXML(pool, xml, flags)))
          _croak_error();
  OUTPUT:
      RETVAL


virStorageVolPtr
_create_xml_from(pool, xml, clone, flags=0)
      virStoragePoolPtr pool;
      const char *xml;
      virStorageVolPtr clone;
      int flags;
    CODE:
      if (!(RETVAL = virStorageVolCreateXMLFrom(pool, xml, clone, flags)))
	_croak_error();
  OUTPUT:
      RETVAL


virStorageVolPtr
_lookup_by_name(pool, name)
      virStoragePoolPtr pool;
      const char *name;
    CODE:
      if (!(RETVAL = virStorageVolLookupByName(pool, name)))
          _croak_error();
  OUTPUT:
      RETVAL


virStorageVolPtr
_lookup_by_key(con, key)
      virConnectPtr con;
      const char *key;
    CODE:
      if (!(RETVAL = virStorageVolLookupByKey(con, key)))
          _croak_error();
  OUTPUT:
      RETVAL


virStorageVolPtr
_lookup_by_path(con, path)
      virConnectPtr con;
      const char *path;
    CODE:
      if (!(RETVAL = virStorageVolLookupByPath(con, path)))
          _croak_error();
  OUTPUT:
      RETVAL


const char *
get_name(vol)
      virStorageVolPtr vol;
    CODE:
      if (!(RETVAL = virStorageVolGetName(vol)))
          _croak_error();
  OUTPUT:
      RETVAL


const char *
get_key(vol)
      virStorageVolPtr vol;
    CODE:
      if (!(RETVAL = virStorageVolGetKey(vol)))
          _croak_error();
  OUTPUT:
      RETVAL


const char *
get_path(vol)
      virStorageVolPtr vol;
    CODE:
      if (!(RETVAL = virStorageVolGetPath(vol)))
          _croak_error();
  OUTPUT:
      RETVAL


void
resize(vol, capacity, flags=0)
      virStorageVolPtr vol;
      SV *capacity;
      unsigned int flags;
  PPCODE:
      if (virStorageVolResize(vol, virt_SvIVull(capacity), flags) < 0)
          _croak_error();


SV *
get_xml_description(vol, flags=0)
      virStorageVolPtr vol;
      unsigned int flags;
  PREINIT:
      char *xml;
    CODE:
      if (!(xml = virStorageVolGetXMLDesc(vol, flags)))
	 _croak_error();

      RETVAL = newSVpv(xml, 0);
      free(xml);
  OUTPUT:
      RETVAL


void
delete(vol, flags=0)
      virStorageVolPtr vol;
      unsigned int flags;
    PPCODE:
      if (virStorageVolDelete(vol, flags) < 0)
          _croak_error();


void
wipe(vol, flags=0)
      virStorageVolPtr vol;
      unsigned int flags;
    PPCODE:
      if (virStorageVolWipe(vol, flags) < 0)
          _croak_error();


void
wipe_pattern(vol, algorithm, flags=0)
      virStorageVolPtr vol;
      unsigned int algorithm
      unsigned int flags;
    PPCODE:
      if (virStorageVolWipePattern(vol, algorithm, flags) < 0)
          _croak_error();


HV *
get_info(vol, flags=0)
      virStorageVolPtr vol;
      unsigned int flags;
  PREINIT:
      virStorageVolInfo info;
    CODE:
      if (flags != 0) {
	  if (virStorageVolGetInfoFlags(vol, &info, flags) < 0)
              _croak_error();
      } else {
          if (virStorageVolGetInfo(vol, &info) < 0)
              _croak_error();
      }

      RETVAL = (HV *)sv_2mortal((SV*)newHV());
      (void)hv_store (RETVAL, "type", 4, newSViv(info.type), 0);
      (void)hv_store (RETVAL, "capacity", 8, virt_newSVull(info.capacity), 0);
      (void)hv_store (RETVAL, "allocation", 10, virt_newSVull(info.allocation), 0);
  OUTPUT:
      RETVAL


void
download(vol, st, offsetsv, lengthsv, flags=0)
      virStorageVolPtr vol;
      virStreamPtr st;
      SV *offsetsv;
      SV *lengthsv;
      unsigned int flags;
 PREINIT:
      unsigned long long offset;
      unsigned long long length;
  PPCODE:
      offset = virt_SvIVull(offsetsv);
      length = virt_SvIVull(lengthsv);

      if (virStorageVolDownload(vol, st, offset, length, flags) < 0)
          _croak_error();


void
upload(vol, st, offsetsv, lengthsv, flags=0)
      virStorageVolPtr vol;
      virStreamPtr st;
      SV *offsetsv;
      SV *lengthsv;
      unsigned int flags;
 PREINIT:
      unsigned long long offset;
      unsigned long long length;
  PPCODE:
      offset = virt_SvIVull(offsetsv);
      length = virt_SvIVull(lengthsv);

      if (virStorageVolUpload(vol, st, offset, length, flags) < 0)
          _croak_error();


void
DESTROY(vol_rv)
      SV *vol_rv;
 PREINIT:
      virStorageVolPtr vol;
  PPCODE:
      vol = (virStorageVolPtr)SvIV((SV*)SvRV(vol_rv));
      if (vol) {
          virStorageVolFree(vol);
          sv_setiv((SV*)SvRV(vol_rv), 0);
      }


MODULE = Sys::Virt::NodeDevice  PACKAGE = Sys::Virt::NodeDevice


virNodeDevicePtr
_create_xml(con, xml, flags=0)
      virConnectPtr con;
      const char *xml;
      unsigned int flags;
    CODE:
      if (!(RETVAL = virNodeDeviceCreateXML(con, xml, flags)))
          _croak_error();
  OUTPUT:
      RETVAL


virNodeDevicePtr
_lookup_by_name(con, name)
      virConnectPtr con;
      const char *name;
    CODE:
      if (!(RETVAL = virNodeDeviceLookupByName(con, name)))
          _croak_error();
  OUTPUT:
      RETVAL


virNodeDevicePtr
_lookup_scsihost_by_wwn(con, wwnn, wwpn, flags=0)
      virConnectPtr con;
      const char *wwnn;
      const char *wwpn;
      unsigned int flags;
    CODE:
      if (!(RETVAL = virNodeDeviceLookupSCSIHostByWWN(con, wwnn, wwpn, flags)))
          _croak_error();
  OUTPUT:
      RETVAL


const char *
get_name(dev)
      virNodeDevicePtr dev;
    CODE:
      if (!(RETVAL = virNodeDeviceGetName(dev)))
          _croak_error();
  OUTPUT:
      RETVAL


const char *
get_parent(dev)
      virNodeDevicePtr dev;
    CODE:
      if (!(RETVAL = virNodeDeviceGetParent(dev))) {
          if (virGetLastError() != NULL)
              _croak_error();
      }
  OUTPUT:
      RETVAL


SV *
get_xml_description(dev, flags=0)
      virNodeDevicePtr dev;
      unsigned int flags;
  PREINIT:
      char *xml;
    CODE:
      if (!(xml = virNodeDeviceGetXMLDesc(dev, flags)))
          _croak_error();

      RETVAL = newSVpv(xml, 0);
      free(xml);
  OUTPUT:
      RETVAL


void
dettach(dev, driversv, flags=0)
      virNodeDevicePtr dev;
      SV *driversv;
      unsigned int flags;
  PREINIT:
      const char *driver = NULL;
      STRLEN len;
   PPCODE:
      if (SvOK(driversv)) {
	  driver = SvPV(driversv, len);
      }

      if (flags || driver) {
          if (virNodeDeviceDetachFlags(dev, driver, flags) < 0)
              _croak_error();
      } else {
          if (virNodeDeviceDettach(dev) < 0)
              _croak_error();
      }


void
reattach(dev)
      virNodeDevicePtr dev;
    PPCODE:
      if (virNodeDeviceReAttach(dev) < 0)
	_croak_error();


void
reset(dev)
      virNodeDevicePtr dev;
    PPCODE:
      if (virNodeDeviceReset(dev) < 0)
          _croak_error();


void
list_capabilities(dev)
      virNodeDevicePtr dev;
 PREINIT:
      int maxnames;
      char **names;
      int i, nnet;
  PPCODE:
      if ((maxnames = virNodeDeviceNumOfCaps(dev)) < 0)
          _croak_error();

      Newx(names, maxnames, char *);
      if ((nnet = virNodeDeviceListCaps(dev, names, maxnames)) < 0) {
          Safefree(names);
          _croak_error();
      }
      EXTEND(SP, nnet);
      for (i = 0 ; i < nnet ; i++) {
          PUSHs(sv_2mortal(newSVpv(names[i], 0)));
          free(names[i]);
      }
      Safefree(names);


void
destroy(dev_rv)
      SV *dev_rv;
 PREINIT:
      virNodeDevicePtr dev;
  PPCODE:
      dev = (virNodeDevicePtr)SvIV((SV*)SvRV(dev_rv));
      if (virNodeDeviceDestroy(dev) < 0)
          _croak_error();


void
DESTROY(dev_rv)
      SV *dev_rv;
 PREINIT:
      virNodeDevicePtr dev;
  PPCODE:
      dev = (virNodeDevicePtr)SvIV((SV*)SvRV(dev_rv));
      if (dev) {
          virNodeDeviceFree(dev);
          sv_setiv((SV*)SvRV(dev_rv), 0);
      }


MODULE = Sys::Virt::Interface  PACKAGE = Sys::Virt::Interface

virInterfacePtr
_define_xml(con, xml, flags = 0)
      virConnectPtr con;
      const char *xml;
      unsigned int flags;
    CODE:
      if (!(RETVAL = virInterfaceDefineXML(con, xml, flags)))
          _croak_error();
  OUTPUT:
      RETVAL


virInterfacePtr
_lookup_by_name(con, name)
      virConnectPtr con;
      const char *name;
    CODE:
      if (!(RETVAL = virInterfaceLookupByName(con, name)))
          _croak_error();
  OUTPUT:
      RETVAL


virInterfacePtr
_lookup_by_mac(con, mac)
      virConnectPtr con;
      const char *mac;
    CODE:
      if (!(RETVAL = virInterfaceLookupByMACString(con, mac)))
          _croak_error();
  OUTPUT:
      RETVAL


const char *
get_mac(iface)
      virInterfacePtr iface;
    CODE:
      if (!(RETVAL = virInterfaceGetMACString(iface)))
          _croak_error();
  OUTPUT:
      RETVAL


const char *
get_name(iface)
      virInterfacePtr iface;
    CODE:
      if (!(RETVAL = virInterfaceGetName(iface)))
          _croak_error();
  OUTPUT:
      RETVAL


int
is_active(iface)
      virInterfacePtr iface;
    CODE:
      if ((RETVAL = virInterfaceIsActive(iface)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


SV *
get_xml_description(iface, flags=0)
      virInterfacePtr iface;
      unsigned int flags;
  PREINIT:
      char *xml;
    CODE:
      if (!(xml = virInterfaceGetXMLDesc(iface, flags)))
          _croak_error();
      RETVAL = newSVpv(xml, 0);
      free(xml);
  OUTPUT:
      RETVAL


void
undefine(iface)
      virInterfacePtr iface;
    PPCODE:
      if (virInterfaceUndefine(iface) < 0)
          _croak_error();


void
create(iface, flags=0)
      virInterfacePtr iface;
      unsigned int flags;
    PPCODE:
      if (virInterfaceCreate(iface, flags) < 0)
          _croak_error();


void
destroy(iface_rv, flags=0)
      SV *iface_rv;
      unsigned int flags;
 PREINIT:
      virInterfacePtr iface;
  PPCODE:
      iface = (virInterfacePtr)SvIV((SV*)SvRV(iface_rv));
      if (virInterfaceDestroy(iface, flags) < 0)
          _croak_error();


void
DESTROY(iface_rv)
      SV *iface_rv;
 PREINIT:
      virInterfacePtr iface;
  PPCODE:
      iface = (virInterfacePtr)SvIV((SV*)SvRV(iface_rv));
      if (iface) {
          virInterfaceFree(iface);
          sv_setiv((SV*)SvRV(iface_rv), 0);
      }


MODULE = Sys::Virt::Secret  PACKAGE = Sys::Virt::Secret


virSecretPtr
_define_xml(con, xml, flags=0)
      virConnectPtr con;
      const char *xml;
      unsigned int flags;
    CODE:
      if (!(RETVAL = virSecretDefineXML(con, xml, flags)))
          _croak_error();
  OUTPUT:
      RETVAL


virSecretPtr
_lookup_by_usage(con, usageType, usageID)
      virConnectPtr con;
      int usageType;
      const char *usageID;
    CODE:
      if (!(RETVAL = virSecretLookupByUsage(con, usageType, usageID))) {
	_croak_error();
      }
  OUTPUT:
      RETVAL


virSecretPtr
_lookup_by_uuid(con, uuid)
      virConnectPtr con;
      const unsigned char *uuid;
    CODE:
      if (!(RETVAL = virSecretLookupByUUID(con, uuid)))
          _croak_error();
  OUTPUT:
      RETVAL


virSecretPtr
_lookup_by_uuid_string(con, uuid)
      virConnectPtr con;
      const char *uuid;
    CODE:
      if (!(RETVAL = virSecretLookupByUUIDString(con, uuid)))
          _croak_error();
  OUTPUT:
      RETVAL


SV *
get_uuid(sec)
      virSecretPtr sec;
  PREINIT:
      unsigned char rawuuid[VIR_UUID_BUFLEN];
    CODE:
      if ((virSecretGetUUID(sec, rawuuid)) < 0)
          _croak_error();

      RETVAL = newSVpv((char*)rawuuid, sizeof(rawuuid));
  OUTPUT:
      RETVAL


SV *
get_uuid_string(sec)
      virSecretPtr sec;
  PREINIT:
      char uuid[VIR_UUID_STRING_BUFLEN];
    CODE:
      if ((virSecretGetUUIDString(sec, uuid)) < 0)
          _croak_error();

      RETVAL = newSVpv(uuid, 0);
  OUTPUT:
      RETVAL


const char *
get_usage_id(sec)
      virSecretPtr sec;
    CODE:
      if (!(RETVAL = virSecretGetUsageID(sec)))
          _croak_error();
  OUTPUT:
      RETVAL


int
get_usage_type(sec)
      virSecretPtr sec;
    CODE:
      if (!(RETVAL = virSecretGetUsageType(sec)))
          _croak_error();
  OUTPUT:
      RETVAL


SV *
get_xml_description(sec, flags=0)
      virSecretPtr sec;
      unsigned int flags;
  PREINIT:
      char *xml;
    CODE:
      if (!(xml = virSecretGetXMLDesc(sec, flags)))
          _croak_error();
      RETVAL = newSVpv(xml, 0);
      free(xml);
  OUTPUT:
      RETVAL


void
undefine(sec)
      virSecretPtr sec;
    PPCODE:
      if (virSecretUndefine(sec) < 0)
          _croak_error();


void
set_value(sec, value, flags=0)
      virSecretPtr sec;
      SV *value;
      unsigned int flags;
PREINIT:
      unsigned char *bytes;
      STRLEN len;
 PPCODE:
      bytes = (unsigned char *)SvPV(value, len);
      if (virSecretSetValue(sec, bytes, len, flags) < 0)
          _croak_error();


SV *
get_value(sec, flags=0)
      virSecretPtr sec;
      unsigned int flags;
PREINIT:
      unsigned char *bytes;
      size_t len;
    CODE:
      if ((bytes = virSecretGetValue(sec, &len, flags)) == NULL)
          _croak_error();

      RETVAL = newSVpv((char*)bytes, len);
  OUTPUT:
      RETVAL



void
DESTROY(sec_rv)
      SV *sec_rv;
 PREINIT:
      virSecretPtr sec;
  PPCODE:
      sec = (virSecretPtr)SvIV((SV*)SvRV(sec_rv));
      if (sec) {
          virSecretFree(sec);
          sv_setiv((SV*)SvRV(sec_rv), 0);
      }


MODULE = Sys::Virt::NWFilter  PACKAGE = Sys::Virt::NWFilter


virNWFilterPtr
_define_xml(con, xml)
      virConnectPtr con;
      const char *xml;
    CODE:
      if (!(RETVAL = virNWFilterDefineXML(con, xml)))
          _croak_error();
  OUTPUT:
      RETVAL


virNWFilterPtr
_lookup_by_name(con, name)
      virConnectPtr con;
      const char *name;
    CODE:
      if (!(RETVAL = virNWFilterLookupByName(con, name)))
          _croak_error();
  OUTPUT:
      RETVAL


virNWFilterPtr
_lookup_by_uuid(con, uuid)
      virConnectPtr con;
      const unsigned char *uuid;
    CODE:
      if (!(RETVAL = virNWFilterLookupByUUID(con, uuid)))
          _croak_error();
  OUTPUT:
      RETVAL


virNWFilterPtr
_lookup_by_uuid_string(con, uuid)
      virConnectPtr con;
      const char *uuid;
    CODE:
      if (!(RETVAL = virNWFilterLookupByUUIDString(con, uuid)))
          _croak_error();
  OUTPUT:
      RETVAL


SV *
get_uuid(filter)
      virNWFilterPtr filter;
  PREINIT:
      unsigned char rawuuid[VIR_UUID_BUFLEN];
    CODE:
      if ((virNWFilterGetUUID(filter, rawuuid)) < 0)
          _croak_error();

      RETVAL = newSVpv((char*)rawuuid, sizeof(rawuuid));
  OUTPUT:
      RETVAL


SV *
get_uuid_string(filter)
      virNWFilterPtr filter;
  PREINIT:
      char uuid[VIR_UUID_STRING_BUFLEN];
    CODE:
      if ((virNWFilterGetUUIDString(filter, uuid)) < 0)
          _croak_error();

      RETVAL = newSVpv(uuid, 0);
  OUTPUT:
      RETVAL


const char *
get_name(filter)
      virNWFilterPtr filter;
    CODE:
      if (!(RETVAL = virNWFilterGetName(filter)))
          _croak_error();
  OUTPUT:
      RETVAL


SV *
get_xml_description(filter, flags=0)
      virNWFilterPtr filter;
      unsigned int flags;
  PREINIT:
      char *xml;
    CODE:
      if (!(xml = virNWFilterGetXMLDesc(filter, flags)))
          _croak_error();

      RETVAL = newSVpv(xml, 0);
      free(xml);
  OUTPUT:
      RETVAL


void
undefine(filter)
      virNWFilterPtr filter;
    PPCODE:
      if (virNWFilterUndefine(filter) < 0)
          _croak_error();

void
DESTROY(filter_rv)
      SV *filter_rv;
 PREINIT:
      virNWFilterPtr filter;
  PPCODE:
      filter = (virNWFilterPtr)SvIV((SV*)SvRV(filter_rv));
      if (filter) {
          virNWFilterFree(filter);
          sv_setiv((SV*)SvRV(filter_rv), 0);
      }


MODULE = Sys::Virt::DomainSnapshot  PACKAGE = Sys::Virt::DomainSnapshot


virDomainSnapshotPtr
_create_xml(dom, xml, flags=0)
      virDomainPtr dom;
      const char *xml;
      unsigned int flags;
    CODE:
      if (!(RETVAL = virDomainSnapshotCreateXML(dom, xml, flags)))
          _croak_error();
  OUTPUT:
      RETVAL


virDomainSnapshotPtr
_lookup_by_name(dom, name, flags=0)
      virDomainPtr dom;
      const char *name;
      unsigned int flags;
    CODE:
      if (!(RETVAL = virDomainSnapshotLookupByName(dom, name, flags)))
          _croak_error();
  OUTPUT:
      RETVAL


const char *
get_name(domss)
      virDomainSnapshotPtr domss;
    CODE:
      if (!(RETVAL = virDomainSnapshotGetName(domss)))
          _croak_error();
  OUTPUT:
      RETVAL


SV *
get_xml_description(domss, flags=0)
      virDomainSnapshotPtr domss;
      unsigned int flags;
  PREINIT:
      char *xml;
    CODE:
      if (!(xml = virDomainSnapshotGetXMLDesc(domss, flags)))
          _croak_error();
      RETVAL = newSVpv(xml, 0);
      free(xml);
  OUTPUT:
      RETVAL


void
revert_to(domss, flags=0)
      virDomainSnapshotPtr domss;
      unsigned int flags;
  PPCODE:
      if (virDomainRevertToSnapshot(domss, flags) < 0)
          _croak_error();


void
delete(domss, flags=0)
      virDomainSnapshotPtr domss;
      unsigned int flags;
  PPCODE:
      if (virDomainSnapshotDelete(domss, flags) < 0)
          _croak_error();


virDomainSnapshotPtr
get_parent(domss, flags=0)
      virDomainSnapshotPtr domss;
      unsigned int flags;
    CODE:
      if (!(RETVAL = virDomainSnapshotGetParent(domss, flags)))
          _croak_error();
  OUTPUT:
      RETVAL


int
num_of_child_snapshots(domss, flags=0)
      virDomainSnapshotPtr domss;
      unsigned int flags;
    CODE:
      if ((RETVAL = virDomainSnapshotNumChildren(domss, flags)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


int
is_current(domss, flags=0)
      virDomainSnapshotPtr domss;
      unsigned int flags;
    CODE:
      if ((RETVAL = virDomainSnapshotIsCurrent(domss, flags)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


int
has_metadata(domss, flags=0)
      virDomainSnapshotPtr domss;
      unsigned int flags;
    CODE:
      if ((RETVAL = virDomainSnapshotHasMetadata(domss, flags)) < 0)
          _croak_error();
  OUTPUT:
      RETVAL


void
list_child_snapshot_names(domss, maxnames, flags=0)
      virDomainSnapshotPtr domss;
      int maxnames;
      unsigned int flags;
 PREINIT:
      char **names;
      int nsnap;
      int i;
  PPCODE:
      Newx(names, maxnames, char *);
      if ((nsnap = virDomainSnapshotListChildrenNames(domss, names, maxnames, flags)) < 0) {
          Safefree(names);
          _croak_error();
      }
      EXTEND(SP, nsnap);
      for (i = 0 ; i < nsnap ; i++) {
          PUSHs(sv_2mortal(newSVpv(names[i], 0)));
          free(names[i]);
      }
      Safefree(names);


void
list_all_children(domss, flags=0)
      virDomainSnapshotPtr domss;
      unsigned int flags;
 PREINIT:
      virDomainSnapshotPtr *domsss;
      int i, ndomss;
      SV *domssrv;
  PPCODE:
      if ((ndomss = virDomainSnapshotListAllChildren(domss, &domsss, flags)) < 0)
          _croak_error();

      EXTEND(SP, ndomss);
      for (i = 0 ; i < ndomss ; i++) {
          domssrv = sv_newmortal();
          sv_setref_pv(domssrv, "Sys::Virt::DomainSnapshot", domsss[i]);
          PUSHs(domssrv);
      }
      free(domsss);


void
DESTROY(domss_rv)
      SV *domss_rv;
 PREINIT:
      virDomainSnapshotPtr domss;
  PPCODE:
      domss = (virDomainSnapshotPtr)SvIV((SV*)SvRV(domss_rv));
      if (domss) {
          virDomainSnapshotFree(domss);
          sv_setiv((SV*)SvRV(domss_rv), 0);
      }


MODULE = Sys::Virt::Event  PACKAGE = Sys::Virt::Event


PROTOTYPES: ENABLE


void
_register_impl()
 PPCODE:
      virEventRegisterImpl(_event_add_handle,
			   _event_update_handle,
			   _event_remove_handle,
			   _event_add_timeout,
			   _event_update_timeout,
			   _event_remove_timeout);


void
register_default()
  PPCODE:
      virEventRegisterDefaultImpl();


void
run_default()
  PPCODE:
      virEventRunDefaultImpl();


int
add_handle(fd, events, coderef)
      int fd;
      int events;
      SV *coderef;
PREINIT:
      int watch;
  CODE:
      SvREFCNT_inc(coderef);

      if ((watch = virEventAddHandle(fd, events, _event_handle_helper, coderef, _event_cb_free)) < 0) {
          SvREFCNT_dec(coderef);
          _croak_error();
      }
      RETVAL = watch;
 OUTPUT:
      RETVAL


void
update_handle(watch, events)
      int watch;
      int events;
  PPCODE:
      virEventUpdateHandle(watch, events);


void
remove_handle(watch)
      int watch;
  PPCODE:
      if (virEventRemoveHandle(watch) < 0)
          _croak_error();


int
add_timeout(frequency, coderef)
      int frequency;
      SV *coderef;
PREINIT:
      int timer;
  CODE:
      SvREFCNT_inc(coderef);

      if ((timer = virEventAddTimeout(frequency, _event_timeout_helper, coderef, _event_cb_free)) < 0) {
          SvREFCNT_dec(coderef);
          _croak_error();
      }
      RETVAL = timer;
 OUTPUT:
      RETVAL


void
update_timeout(timer, frequency)
      int timer;
      int frequency;
  PPCODE:
      virEventUpdateTimeout(timer, frequency);


void
remove_timeout(timer)
      int timer;
  PPCODE:
      if (virEventRemoveTimeout(timer) < 0)
          _croak_error();


void
_run_handle_callback_helper(watch, fd, event, cbref, opaqueref)
      int watch;
      int fd;
      int event;
      SV *cbref;
      SV *opaqueref;
 PREINIT:
      virEventHandleCallback cb;
      void *opaque;
  PPCODE:
      cb = (virEventHandleCallback)SvIV((SV*)SvRV(cbref));
      opaque = (void*)SvIV((SV*)SvRV(opaqueref));

      cb(watch, fd, event, opaque);


void
_run_timeout_callback_helper(timer, cbref, opaqueref)
      int timer;
      SV *cbref;
      SV *opaqueref;
 PREINIT:
      virEventTimeoutCallback cb;
      void *opaque;
  PPCODE:
      cb = (virEventTimeoutCallback)SvIV((SV*)SvRV(cbref));
      opaque = (void*)SvIV((SV*)SvRV(opaqueref));

      cb(timer, opaque);


void
_free_callback_opaque_helper(ffref, opaqueref)
      SV *ffref;
      SV *opaqueref;
PREINIT:
      virFreeCallback ff;
      void *opaque;
  PPCODE:
      opaque = SvOK(opaqueref) ? (void*)SvIV((SV*)SvRV(opaqueref)) : NULL;
      ff = SvOK(ffref) ? (virFreeCallback)SvIV((SV*)SvRV(ffref)) : NULL;

      if (opaque != NULL && ff != NULL)
        ff(opaque);



MODULE = Sys::Virt::Stream  PACKAGE = Sys::Virt::Stream

virStreamPtr
_new_obj(con, flags=0)
      virConnectPtr con;
      unsigned int flags;
    CODE:
      if (!(RETVAL = virStreamNew(con, flags)))
          _croak_error();
  OUTPUT:
      RETVAL


int
send(st, data, nbytes)
      virStreamPtr st;
      SV *data;
      size_t nbytes;
 PREINIT:
      const char *rawdata;
      STRLEN len;
    CODE:
      if (SvOK(data)) {
	  rawdata = SvPV(data, len);
          if (nbytes > len)
              nbytes = len;
      } else {
          rawdata = "";
          nbytes = 0;
      }

      if ((RETVAL = virStreamSend(st, rawdata, nbytes)) < 0 &&
          RETVAL != -2)
          _croak_error();
  OUTPUT:
      RETVAL


int
recv(st, data, nbytes)
      virStreamPtr st;
      SV *data;
      size_t nbytes;
 PREINIT:
      char *rawdata;
    CODE:
      Newx(rawdata, nbytes, char);
      if ((RETVAL = virStreamRecv(st, rawdata, nbytes)) < 0 &&
          RETVAL != -2) {
          Safefree(rawdata);
          _croak_error();
      }
      if (RETVAL > 0) {
          sv_setpvn(data, rawdata, RETVAL);
      }
      Safefree(rawdata);
  OUTPUT:
      RETVAL


void
send_all(stref, handler)
      SV *stref;
      SV *handler;
 PREINIT:
      AV *opaque;
      virStreamPtr st;
    CODE:
      st = (virStreamPtr)SvIV((SV*)SvRV(stref));

      opaque = newAV();
      SvREFCNT_inc(handler);
      SvREFCNT_inc(stref);
      av_push(opaque, stref);
      av_push(opaque, handler);

      if (virStreamSendAll(st, _stream_send_all_source, opaque) < 0)
          _croak_error();

      SvREFCNT_dec(opaque);


void
recv_all(stref, handler)
      SV *stref;
      SV *handler;
 PREINIT:
      AV *opaque;
      virStreamPtr st;
    CODE:
      st = (virStreamPtr)SvIV((SV*)SvRV(stref));

      opaque = newAV();
      SvREFCNT_inc(handler);
      SvREFCNT_inc(stref);
      av_push(opaque, stref);
      av_push(opaque, handler);

      if (virStreamRecvAll(st, _stream_recv_all_sink, opaque) < 0)
          _croak_error();

      SvREFCNT_dec(opaque);


void
add_callback(stref, events, cb)
      SV* stref;
      int events;
      SV* cb;
 PREINIT:
      AV *opaque;
      virStreamPtr st;
  PPCODE:
      st = (virStreamPtr)SvIV((SV*)SvRV(stref));

      opaque = newAV();
      SvREFCNT_inc(cb);
      SvREFCNT_inc(stref);
      av_push(opaque, stref);
      av_push(opaque, cb);
      if (virStreamEventAddCallback(st, events, _stream_event_callback, opaque, _stream_event_free) < 0)
          _croak_error();


void
update_callback(st, events)
      virStreamPtr st;
      int events;
   PPCODE:
      if (virStreamEventUpdateCallback(st, events) < 0)
          _croak_error();


void
remove_callback(st)
      virStreamPtr st;
   PPCODE:
      if (virStreamEventRemoveCallback(st) < 0)
          _croak_error();


void
finish(st)
      virStreamPtr st;
  PPCODE:
      if (virStreamFinish(st) < 0)
          _croak_error();


void
abort(st)
      virStreamPtr st;
  PPCODE:
      if (virStreamAbort(st) < 0)
          _croak_error();


void
DESTROY(st_rv)
      SV *st_rv;
 PREINIT:
      virStreamPtr st;
  PPCODE:
      st = (virStreamPtr)SvIV((SV*)SvRV(st_rv));
      if (st) {
	virStreamFree(st);
	sv_setiv((SV*)SvRV(st_rv), 0);
      }


MODULE = Sys::Virt  PACKAGE = Sys::Virt


PROTOTYPES: ENABLE


BOOT:
    {
      HV *stash;

      virSetErrorFunc(NULL, ignoreVirErrorFunc);
      virInitialize();

      stash = gv_stashpv( "Sys::Virt", TRUE );

      REGISTER_CONSTANT(VIR_CONNECT_RO, CONNECT_RO);
      REGISTER_CONSTANT(VIR_CONNECT_NO_ALIASES, CONNECT_NO_ALIASES);

      REGISTER_CONSTANT(VIR_CRED_USERNAME, CRED_USERNAME);
      REGISTER_CONSTANT(VIR_CRED_AUTHNAME, CRED_AUTHNAME);
      REGISTER_CONSTANT(VIR_CRED_LANGUAGE, CRED_LANGUAGE);
      REGISTER_CONSTANT(VIR_CRED_CNONCE, CRED_CNONCE);
      REGISTER_CONSTANT(VIR_CRED_PASSPHRASE, CRED_PASSPHRASE);
      REGISTER_CONSTANT(VIR_CRED_ECHOPROMPT, CRED_ECHOPROMPT);
      REGISTER_CONSTANT(VIR_CRED_NOECHOPROMPT, CRED_NOECHOPROMPT);
      REGISTER_CONSTANT(VIR_CRED_REALM, CRED_REALM);
      REGISTER_CONSTANT(VIR_CRED_EXTERNAL, CRED_EXTERNAL);


      /* Don't bother with VIR_CPU_COMPARE_ERROR since we die in that case */
      REGISTER_CONSTANT(VIR_CPU_COMPARE_INCOMPATIBLE, CPU_COMPARE_INCOMPATIBLE);
      REGISTER_CONSTANT(VIR_CPU_COMPARE_IDENTICAL, CPU_COMPARE_IDENTICAL);
      REGISTER_CONSTANT(VIR_CPU_COMPARE_SUPERSET, CPU_COMPARE_SUPERSET);


      REGISTER_CONSTANT(VIR_NODE_SUSPEND_TARGET_MEM, NODE_SUSPEND_TARGET_MEM);
      REGISTER_CONSTANT(VIR_NODE_SUSPEND_TARGET_DISK, NODE_SUSPEND_TARGET_DISK);
      REGISTER_CONSTANT(VIR_NODE_SUSPEND_TARGET_HYBRID, NODE_SUSPEND_TARGET_HYBRID);


      REGISTER_CONSTANT(VIR_NODE_CPU_STATS_ALL_CPUS, NODE_CPU_STATS_ALL_CPUS);
      REGISTER_CONSTANT_STR(VIR_NODE_CPU_STATS_IDLE, NODE_CPU_STATS_IDLE);
      REGISTER_CONSTANT_STR(VIR_NODE_CPU_STATS_IOWAIT, NODE_CPU_STATS_IOWAIT);
      REGISTER_CONSTANT_STR(VIR_NODE_CPU_STATS_KERNEL, NODE_CPU_STATS_KERNEL);
      REGISTER_CONSTANT_STR(VIR_NODE_CPU_STATS_USER, NODE_CPU_STATS_USER);
      REGISTER_CONSTANT_STR(VIR_NODE_CPU_STATS_INTR, NODE_CPU_STATS_INTR);
      REGISTER_CONSTANT_STR(VIR_NODE_CPU_STATS_UTILIZATION, NODE_CPU_STATS_UTILIZATION);

      REGISTER_CONSTANT(VIR_NODE_MEMORY_STATS_ALL_CELLS, NODE_MEMORY_STATS_ALL_CELLS);
      REGISTER_CONSTANT_STR(VIR_NODE_MEMORY_STATS_BUFFERS, NODE_MEMORY_STATS_BUFFERS);
      REGISTER_CONSTANT_STR(VIR_NODE_MEMORY_STATS_CACHED, NODE_MEMORY_STATS_CACHED);
      REGISTER_CONSTANT_STR(VIR_NODE_MEMORY_STATS_FREE, NODE_MEMORY_STATS_FREE);
      REGISTER_CONSTANT_STR(VIR_NODE_MEMORY_STATS_TOTAL, NODE_MEMORY_STATS_TOTAL);

      REGISTER_CONSTANT(VIR_CONNECT_CLOSE_REASON_CLIENT, CLOSE_REASON_CLIENT);
      REGISTER_CONSTANT(VIR_CONNECT_CLOSE_REASON_EOF, CLOSE_REASON_EOF);
      REGISTER_CONSTANT(VIR_CONNECT_CLOSE_REASON_ERROR, CLOSE_REASON_ERROR);
      REGISTER_CONSTANT(VIR_CONNECT_CLOSE_REASON_KEEPALIVE, CLOSE_REASON_KEEPALIVE);

      REGISTER_CONSTANT_STR(VIR_NODE_MEMORY_SHARED_PAGES_TO_SCAN, NODE_MEMORY_SHARED_PAGES_TO_SCAN);
      REGISTER_CONSTANT_STR(VIR_NODE_MEMORY_SHARED_SLEEP_MILLISECS, NODE_MEMORY_SHARED_SLEEP_MILLISECS);
      REGISTER_CONSTANT_STR(VIR_NODE_MEMORY_SHARED_PAGES_SHARED, NODE_MEMORY_SHARED_PAGES_SHARED);
      REGISTER_CONSTANT_STR(VIR_NODE_MEMORY_SHARED_PAGES_SHARING, NODE_MEMORY_SHARED_PAGES_SHARING);
      REGISTER_CONSTANT_STR(VIR_NODE_MEMORY_SHARED_PAGES_UNSHARED, NODE_MEMORY_SHARED_PAGES_UNSHARED);
      REGISTER_CONSTANT_STR(VIR_NODE_MEMORY_SHARED_PAGES_VOLATILE, NODE_MEMORY_SHARED_PAGES_VOLATILE);
      REGISTER_CONSTANT_STR(VIR_NODE_MEMORY_SHARED_FULL_SCANS, NODE_MEMORY_SHARED_FULL_SCANS);
      REGISTER_CONSTANT_STR(VIR_NODE_MEMORY_SHARED_MERGE_ACROSS_NODES, NODE_MEMORY_SHARED_MERGE_ACROSS_NODES);

      REGISTER_CONSTANT(VIR_CONNECT_BASELINE_CPU_EXPAND_FEATURES, BASELINE_CPU_EXPAND_FEATURES);
      REGISTER_CONSTANT(VIR_CONNECT_BASELINE_CPU_MIGRATABLE, BASELINE_CPU_MIGRATABLE);

      REGISTER_CONSTANT(VIR_CONNECT_COMPARE_CPU_FAIL_INCOMPATIBLE, COMPARE_CPU_FAIL_INCOMPATIBLE);

      REGISTER_CONSTANT(VIR_IP_ADDR_TYPE_IPV4, IP_ADDR_TYPE_IPV4);
      REGISTER_CONSTANT(VIR_IP_ADDR_TYPE_IPV6, IP_ADDR_TYPE_IPV6);

      REGISTER_CONSTANT(VIR_NODE_ALLOC_PAGES_ADD, NODE_ALLOC_PAGES_ADD);
      REGISTER_CONSTANT(VIR_NODE_ALLOC_PAGES_SET, NODE_ALLOC_PAGES_SET);

      stash = gv_stashpv( "Sys::Virt::Event", TRUE );

      REGISTER_CONSTANT(VIR_EVENT_HANDLE_READABLE, HANDLE_READABLE);
      REGISTER_CONSTANT(VIR_EVENT_HANDLE_WRITABLE, HANDLE_WRITABLE);
      REGISTER_CONSTANT(VIR_EVENT_HANDLE_ERROR, HANDLE_ERROR);
      REGISTER_CONSTANT(VIR_EVENT_HANDLE_HANGUP, HANDLE_HANGUP);


      stash = gv_stashpv( "Sys::Virt::Domain", TRUE );
      REGISTER_CONSTANT(VIR_DOMAIN_NOSTATE, STATE_NOSTATE);
      REGISTER_CONSTANT(VIR_DOMAIN_RUNNING, STATE_RUNNING);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCKED, STATE_BLOCKED);
      REGISTER_CONSTANT(VIR_DOMAIN_PAUSED, STATE_PAUSED);
      REGISTER_CONSTANT(VIR_DOMAIN_SHUTDOWN, STATE_SHUTDOWN);
      REGISTER_CONSTANT(VIR_DOMAIN_SHUTOFF, STATE_SHUTOFF);
      REGISTER_CONSTANT(VIR_DOMAIN_CRASHED, STATE_CRASHED);
      REGISTER_CONSTANT(VIR_DOMAIN_PMSUSPENDED, STATE_PMSUSPENDED);

      REGISTER_CONSTANT(VIR_DUMP_CRASH, DUMP_CRASH);
      REGISTER_CONSTANT(VIR_DUMP_LIVE, DUMP_LIVE);
      REGISTER_CONSTANT(VIR_DUMP_BYPASS_CACHE, DUMP_BYPASS_CACHE);
      REGISTER_CONSTANT(VIR_DUMP_RESET, DUMP_RESET);
      REGISTER_CONSTANT(VIR_DUMP_MEMORY_ONLY, DUMP_MEMORY_ONLY);

      REGISTER_CONSTANT(VIR_DOMAIN_SAVE_BYPASS_CACHE, SAVE_BYPASS_CACHE);
      REGISTER_CONSTANT(VIR_DOMAIN_SAVE_RUNNING, SAVE_RUNNING);
      REGISTER_CONSTANT(VIR_DOMAIN_SAVE_PAUSED, SAVE_PAUSED);

      REGISTER_CONSTANT(VIR_DOMAIN_UNDEFINE_MANAGED_SAVE, UNDEFINE_MANAGED_SAVE);
      REGISTER_CONSTANT(VIR_DOMAIN_UNDEFINE_SNAPSHOTS_METADATA, UNDEFINE_SNAPSHOTS_METADATA);
      REGISTER_CONSTANT(VIR_DOMAIN_UNDEFINE_NVRAM, UNDEFINE_NVRAM);
      REGISTER_CONSTANT(VIR_DOMAIN_UNDEFINE_KEEP_NVRAM, UNDEFINE_KEEP_NVRAM);

      REGISTER_CONSTANT(VIR_DOMAIN_START_PAUSED, START_PAUSED);
      REGISTER_CONSTANT(VIR_DOMAIN_START_AUTODESTROY, START_AUTODESTROY);
      REGISTER_CONSTANT(VIR_DOMAIN_START_BYPASS_CACHE, START_BYPASS_CACHE);
      REGISTER_CONSTANT(VIR_DOMAIN_START_FORCE_BOOT, START_FORCE_BOOT);
      REGISTER_CONSTANT(VIR_DOMAIN_START_VALIDATE, START_VALIDATE);

      REGISTER_CONSTANT(VIR_DOMAIN_DEFINE_VALIDATE, DEFINE_VALIDATE);

      REGISTER_CONSTANT(VIR_DOMAIN_NOSTATE_UNKNOWN, STATE_NOSTATE_UNKNOWN);

      REGISTER_CONSTANT(VIR_DOMAIN_RUNNING_UNKNOWN, STATE_RUNNING_UNKNOWN);
      REGISTER_CONSTANT(VIR_DOMAIN_RUNNING_BOOTED, STATE_RUNNING_BOOTED);
      REGISTER_CONSTANT(VIR_DOMAIN_RUNNING_MIGRATED, STATE_RUNNING_MIGRATED);
      REGISTER_CONSTANT(VIR_DOMAIN_RUNNING_RESTORED, STATE_RUNNING_RESTORED);
      REGISTER_CONSTANT(VIR_DOMAIN_RUNNING_FROM_SNAPSHOT, STATE_RUNNING_FROM_SNAPSHOT);
      REGISTER_CONSTANT(VIR_DOMAIN_RUNNING_UNPAUSED, STATE_RUNNING_UNPAUSED);
      REGISTER_CONSTANT(VIR_DOMAIN_RUNNING_MIGRATION_CANCELED, STATE_RUNNING_MIGRATION_CANCELED);
      REGISTER_CONSTANT(VIR_DOMAIN_RUNNING_SAVE_CANCELED, STATE_RUNNING_SAVE_CANCELED);
      REGISTER_CONSTANT(VIR_DOMAIN_RUNNING_WAKEUP, STATE_RUNNING_WAKEUP);
      REGISTER_CONSTANT(VIR_DOMAIN_RUNNING_CRASHED, STATE_RUNNING_CRASHED);
      REGISTER_CONSTANT(VIR_DOMAIN_RUNNING_POSTCOPY, STATE_RUNNING_POSTCOPY);

      REGISTER_CONSTANT(VIR_DOMAIN_BLOCKED_UNKNOWN, STATE_BLOCKED_UNKNOWN);

      REGISTER_CONSTANT(VIR_DOMAIN_PAUSED_UNKNOWN, STATE_PAUSED_UNKNOWN);
      REGISTER_CONSTANT(VIR_DOMAIN_PAUSED_USER, STATE_PAUSED_USER);
      REGISTER_CONSTANT(VIR_DOMAIN_PAUSED_MIGRATION, STATE_PAUSED_MIGRATION);
      REGISTER_CONSTANT(VIR_DOMAIN_PAUSED_SAVE, STATE_PAUSED_SAVE);
      REGISTER_CONSTANT(VIR_DOMAIN_PAUSED_DUMP, STATE_PAUSED_DUMP);
      REGISTER_CONSTANT(VIR_DOMAIN_PAUSED_IOERROR, STATE_PAUSED_IOERROR);
      REGISTER_CONSTANT(VIR_DOMAIN_PAUSED_WATCHDOG, STATE_PAUSED_WATCHDOG);
      REGISTER_CONSTANT(VIR_DOMAIN_PAUSED_FROM_SNAPSHOT, STATE_PAUSED_FROM_SNAPSHOT);
      REGISTER_CONSTANT(VIR_DOMAIN_PAUSED_SHUTTING_DOWN, STATE_PAUSED_SHUTTING_DOWN);
      REGISTER_CONSTANT(VIR_DOMAIN_PAUSED_SNAPSHOT, STATE_PAUSED_SNAPSHOT);
      REGISTER_CONSTANT(VIR_DOMAIN_PAUSED_CRASHED, STATE_PAUSED_CRASHED);
      REGISTER_CONSTANT(VIR_DOMAIN_PAUSED_STARTING_UP, STATE_PAUSED_STARTING_UP);
      REGISTER_CONSTANT(VIR_DOMAIN_PAUSED_POSTCOPY, STATE_PAUSED_POSTCOPY);
      REGISTER_CONSTANT(VIR_DOMAIN_PAUSED_POSTCOPY_FAILED, STATE_PAUSED_POSTCOPY_FAILED);

      REGISTER_CONSTANT(VIR_DOMAIN_SHUTDOWN_UNKNOWN, STATE_SHUTDOWN_UNKNOWN);
      REGISTER_CONSTANT(VIR_DOMAIN_SHUTDOWN_USER, STATE_SHUTDOWN_USER);

      REGISTER_CONSTANT(VIR_DOMAIN_SHUTOFF_UNKNOWN, STATE_SHUTOFF_UNKNOWN);
      REGISTER_CONSTANT(VIR_DOMAIN_SHUTOFF_SHUTDOWN, STATE_SHUTOFF_SHUTDOWN);
      REGISTER_CONSTANT(VIR_DOMAIN_SHUTOFF_DESTROYED, STATE_SHUTOFF_DESTROYED);
      REGISTER_CONSTANT(VIR_DOMAIN_SHUTOFF_CRASHED, STATE_SHUTOFF_CRASHED);
      REGISTER_CONSTANT(VIR_DOMAIN_SHUTOFF_MIGRATED, STATE_SHUTOFF_MIGRATED);
      REGISTER_CONSTANT(VIR_DOMAIN_SHUTOFF_SAVED, STATE_SHUTOFF_SAVED);
      REGISTER_CONSTANT(VIR_DOMAIN_SHUTOFF_FAILED, STATE_SHUTOFF_FAILED);
      REGISTER_CONSTANT(VIR_DOMAIN_SHUTOFF_FROM_SNAPSHOT, STATE_SHUTOFF_FROM_SNAPSHOT);

      REGISTER_CONSTANT(VIR_DOMAIN_CRASHED_UNKNOWN, STATE_CRASHED_UNKNOWN);
      REGISTER_CONSTANT(VIR_DOMAIN_CRASHED_PANICKED, STATE_CRASHED_PANICKED);

      REGISTER_CONSTANT(VIR_DOMAIN_PMSUSPENDED_UNKNOWN, STATE_PMSUSPENDED_UNKNOWN);

      REGISTER_CONSTANT(VIR_DOMAIN_PMSUSPENDED_DISK_UNKNOWN, STATE_PMSUSPENDED_DISK_UNKNOWN);

      REGISTER_CONSTANT(VIR_DOMAIN_OPEN_GRAPHICS_SKIPAUTH, OPEN_GRAPHICS_SKIPAUTH);

      REGISTER_CONSTANT(VIR_DOMAIN_CONSOLE_FORCE, OPEN_CONSOLE_FORCE);
      REGISTER_CONSTANT(VIR_DOMAIN_CONSOLE_SAFE, OPEN_CONSOLE_SAFE);

      REGISTER_CONSTANT(VIR_DOMAIN_CHANNEL_FORCE, OPEN_CHANNEL_FORCE);

      REGISTER_CONSTANT_STR(VIR_DOMAIN_SCHEDULER_EMULATOR_PERIOD, SCHEDULER_EMULATOR_PERIOD);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_SCHEDULER_EMULATOR_QUOTA, SCHEDULER_EMULATOR_QUOTA);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_SCHEDULER_IOTHREAD_PERIOD, SCHEDULER_IOTHREAD_PERIOD);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_SCHEDULER_IOTHREAD_QUOTA, SCHEDULER_IOTHREAD_QUOTA);

      REGISTER_CONSTANT_STR(VIR_DOMAIN_CPU_STATS_CPUTIME, CPU_STATS_CPUTIME);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_CPU_STATS_SYSTEMTIME, CPU_STATS_SYSTEMTIME);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_CPU_STATS_USERTIME, CPU_STATS_USERTIME);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_CPU_STATS_VCPUTIME, CPU_STATS_VCPUTIME);


      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_STATS_ERRS, BLOCK_STATS_ERRS);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_STATS_FLUSH_REQ, BLOCK_STATS_FLUSH_REQ);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_STATS_FLUSH_TOTAL_TIMES, BLOCK_STATS_FLUSH_TOTAL_TIMES);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_STATS_READ_BYTES, BLOCK_STATS_READ_BYTES);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_STATS_READ_REQ, BLOCK_STATS_READ_REQ);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_STATS_READ_TOTAL_TIMES, BLOCK_STATS_READ_TOTAL_TIMES);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_STATS_WRITE_BYTES, BLOCK_STATS_WRITE_BYTES);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_STATS_WRITE_REQ, BLOCK_STATS_WRITE_REQ);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_STATS_WRITE_TOTAL_TIMES, BLOCK_STATS_WRITE_TOTAL_TIMES);

      REGISTER_CONSTANT(VIR_MIGRATE_LIVE, MIGRATE_LIVE);
      REGISTER_CONSTANT(VIR_MIGRATE_PEER2PEER, MIGRATE_PEER2PEER);
      REGISTER_CONSTANT(VIR_MIGRATE_TUNNELLED, MIGRATE_TUNNELLED);
      REGISTER_CONSTANT(VIR_MIGRATE_PERSIST_DEST, MIGRATE_PERSIST_DEST);
      REGISTER_CONSTANT(VIR_MIGRATE_UNDEFINE_SOURCE, MIGRATE_UNDEFINE_SOURCE);
      REGISTER_CONSTANT(VIR_MIGRATE_PAUSED, MIGRATE_PAUSED);
      REGISTER_CONSTANT(VIR_MIGRATE_NON_SHARED_DISK, MIGRATE_NON_SHARED_DISK);
      REGISTER_CONSTANT(VIR_MIGRATE_NON_SHARED_INC, MIGRATE_NON_SHARED_INC);
      REGISTER_CONSTANT(VIR_MIGRATE_CHANGE_PROTECTION, MIGRATE_CHANGE_PROTECTION);
      REGISTER_CONSTANT(VIR_MIGRATE_UNSAFE, MIGRATE_UNSAFE);
      REGISTER_CONSTANT(VIR_MIGRATE_OFFLINE, MIGRATE_OFFLINE);
      REGISTER_CONSTANT(VIR_MIGRATE_COMPRESSED, MIGRATE_COMPRESSED);
      REGISTER_CONSTANT(VIR_MIGRATE_ABORT_ON_ERROR, MIGRATE_ABORT_ON_ERROR);
      REGISTER_CONSTANT(VIR_MIGRATE_AUTO_CONVERGE, MIGRATE_AUTO_CONVERGE);
      REGISTER_CONSTANT(VIR_MIGRATE_RDMA_PIN_ALL, MIGRATE_RDMA_PIN_ALL);
      REGISTER_CONSTANT(VIR_MIGRATE_POSTCOPY, MIGRATE_POSTCOPY);
      REGISTER_CONSTANT(VIR_MIGRATE_TLS, MIGRATE_TLS);

      REGISTER_CONSTANT_STR(VIR_MIGRATE_PARAM_BANDWIDTH, MIGRATE_PARAM_BANDWIDTH);
      REGISTER_CONSTANT_STR(VIR_MIGRATE_PARAM_DEST_NAME, MIGRATE_PARAM_DEST_NAME);
      REGISTER_CONSTANT_STR(VIR_MIGRATE_PARAM_DEST_XML, MIGRATE_PARAM_DEST_XML);
      REGISTER_CONSTANT_STR(VIR_MIGRATE_PARAM_GRAPHICS_URI, MIGRATE_PARAM_GRAPHICS_URI);
      REGISTER_CONSTANT_STR(VIR_MIGRATE_PARAM_URI, MIGRATE_PARAM_URI);
      REGISTER_CONSTANT_STR(VIR_MIGRATE_PARAM_LISTEN_ADDRESS, MIGRATE_PARAM_LISTEN_ADDRESS);
      REGISTER_CONSTANT_STR(VIR_MIGRATE_PARAM_MIGRATE_DISKS, MIGRATE_PARAM_MIGRATE_DISKS);
      REGISTER_CONSTANT_STR(VIR_MIGRATE_PARAM_DISKS_PORT, MIGRATE_PARAM_DISK_PORT);
      REGISTER_CONSTANT_STR(VIR_MIGRATE_PARAM_COMPRESSION, MIGRATE_PARAM_COMPRESSION);
      REGISTER_CONSTANT_STR(VIR_MIGRATE_PARAM_COMPRESSION_MT_THREADS, MIGRATE_PARAM_COMPRESSION_MT_THREADS);
      REGISTER_CONSTANT_STR(VIR_MIGRATE_PARAM_COMPRESSION_MT_DTHREADS, MIGRATE_PARAM_COMPRESSION_MT_DTHREADS);
      REGISTER_CONSTANT_STR(VIR_MIGRATE_PARAM_COMPRESSION_MT_LEVEL, MIGRATE_PARAM_COMPRESSION_MT_LEVEL);
      REGISTER_CONSTANT_STR(VIR_MIGRATE_PARAM_COMPRESSION_XBZRLE_CACHE, MIGRATE_PARAM_COMPRESSION_XBZRLE_CACHE);
      REGISTER_CONSTANT_STR(VIR_MIGRATE_PARAM_PERSIST_XML, MIGRATE_PARAM_PERSIST_XML);
      REGISTER_CONSTANT_STR(VIR_MIGRATE_PARAM_AUTO_CONVERGE_INITIAL, MIGRATE_PARAM_AUTO_CONVERGE_INITIAL);
      REGISTER_CONSTANT_STR(VIR_MIGRATE_PARAM_AUTO_CONVERGE_INCREMENT, MIGRATE_PARAM_AUTO_CONVERGE_INCREMENT);

      REGISTER_CONSTANT(VIR_DOMAIN_XML_SECURE, XML_SECURE);
      REGISTER_CONSTANT(VIR_DOMAIN_XML_INACTIVE, XML_INACTIVE);
      REGISTER_CONSTANT(VIR_DOMAIN_XML_UPDATE_CPU, XML_UPDATE_CPU);
      REGISTER_CONSTANT(VIR_DOMAIN_XML_MIGRATABLE, XML_MIGRATABLE);


      REGISTER_CONSTANT(VIR_MEMORY_VIRTUAL, MEMORY_VIRTUAL);
      REGISTER_CONSTANT(VIR_MEMORY_PHYSICAL, MEMORY_PHYSICAL);


      REGISTER_CONSTANT(VIR_VCPU_OFFLINE, VCPU_OFFLINE);
      REGISTER_CONSTANT(VIR_VCPU_RUNNING, VCPU_RUNNING);
      REGISTER_CONSTANT(VIR_VCPU_BLOCKED, VCPU_BLOCKED);


      REGISTER_CONSTANT(VIR_KEYCODE_SET_LINUX, KEYCODE_SET_LINUX);
      REGISTER_CONSTANT(VIR_KEYCODE_SET_XT, KEYCODE_SET_XT);
      REGISTER_CONSTANT(VIR_KEYCODE_SET_ATSET1, KEYCODE_SET_ATSET1);
      REGISTER_CONSTANT(VIR_KEYCODE_SET_ATSET2, KEYCODE_SET_ATSET2);
      REGISTER_CONSTANT(VIR_KEYCODE_SET_ATSET3, KEYCODE_SET_ATSET3);
      REGISTER_CONSTANT(VIR_KEYCODE_SET_OSX, KEYCODE_SET_OSX);
      REGISTER_CONSTANT(VIR_KEYCODE_SET_XT_KBD, KEYCODE_SET_XT_KBD);
      REGISTER_CONSTANT(VIR_KEYCODE_SET_USB, KEYCODE_SET_USB);
      REGISTER_CONSTANT(VIR_KEYCODE_SET_WIN32, KEYCODE_SET_WIN32);
      REGISTER_CONSTANT(VIR_KEYCODE_SET_RFB, KEYCODE_SET_RFB);

      REGISTER_CONSTANT(VIR_DOMAIN_STATS_BALLOON, STATS_BALLOON);
      REGISTER_CONSTANT(VIR_DOMAIN_STATS_BLOCK, STATS_BLOCK);
      REGISTER_CONSTANT(VIR_DOMAIN_STATS_CPU_TOTAL, STATS_CPU_TOTAL);
      REGISTER_CONSTANT(VIR_DOMAIN_STATS_INTERFACE, STATS_INTERFACE);
      REGISTER_CONSTANT(VIR_DOMAIN_STATS_STATE, STATS_STATE);
      REGISTER_CONSTANT(VIR_DOMAIN_STATS_VCPU, STATS_VCPU);
      REGISTER_CONSTANT(VIR_DOMAIN_STATS_PERF, STATS_PERF);

      REGISTER_CONSTANT(VIR_CONNECT_GET_ALL_DOMAINS_STATS_ACTIVE, GET_ALL_STATS_ACTIVE);
      REGISTER_CONSTANT(VIR_CONNECT_GET_ALL_DOMAINS_STATS_INACTIVE, GET_ALL_STATS_INACTIVE);
      REGISTER_CONSTANT(VIR_CONNECT_GET_ALL_DOMAINS_STATS_OTHER, GET_ALL_STATS_OTHER);
      REGISTER_CONSTANT(VIR_CONNECT_GET_ALL_DOMAINS_STATS_PAUSED, GET_ALL_STATS_PAUSED);
      REGISTER_CONSTANT(VIR_CONNECT_GET_ALL_DOMAINS_STATS_PERSISTENT, GET_ALL_STATS_PERSISTENT);
      REGISTER_CONSTANT(VIR_CONNECT_GET_ALL_DOMAINS_STATS_RUNNING, GET_ALL_STATS_RUNNING);
      REGISTER_CONSTANT(VIR_CONNECT_GET_ALL_DOMAINS_STATS_SHUTOFF, GET_ALL_STATS_SHUTOFF);
      REGISTER_CONSTANT(VIR_CONNECT_GET_ALL_DOMAINS_STATS_TRANSIENT, GET_ALL_STATS_TRANSIENT);
      REGISTER_CONSTANT(VIR_CONNECT_GET_ALL_DOMAINS_STATS_ENFORCE_STATS, GET_ALL_STATS_ENFORCE_STATS);
      REGISTER_CONSTANT(VIR_CONNECT_GET_ALL_DOMAINS_STATS_BACKING, GET_ALL_STATS_BACKING);

      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_DEFINED, EVENT_DEFINED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_UNDEFINED, EVENT_UNDEFINED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_STARTED, EVENT_STARTED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_SUSPENDED, EVENT_SUSPENDED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_RESUMED, EVENT_RESUMED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_STOPPED, EVENT_STOPPED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_SHUTDOWN, EVENT_SHUTDOWN);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_PMSUSPENDED, EVENT_PMSUSPENDED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_PMSUSPENDED_DISK, EVENT_PMSUSPENDED_DISK);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_CRASHED, EVENT_CRASHED);

      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_DEFINED_ADDED, EVENT_DEFINED_ADDED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_DEFINED_UPDATED, EVENT_DEFINED_UPDATED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_DEFINED_RENAMED, EVENT_DEFINED_RENAMED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_DEFINED_FROM_SNAPSHOT, EVENT_DEFINED_FROM_SNAPSHOT);

      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_UNDEFINED_REMOVED, EVENT_UNDEFINED_REMOVED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_UNDEFINED_RENAMED, EVENT_UNDEFINED_RENAMED);

      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_STARTED_BOOTED, EVENT_STARTED_BOOTED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_STARTED_MIGRATED, EVENT_STARTED_MIGRATED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_STARTED_RESTORED, EVENT_STARTED_RESTORED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_STARTED_FROM_SNAPSHOT, EVENT_STARTED_FROM_SNAPSHOT);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_STARTED_WAKEUP, EVENT_STARTED_WAKEUP);

      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_CRASHED_PANICKED, EVENT_CRASHED_PANICKED);

      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_SUSPENDED_PAUSED, EVENT_SUSPENDED_PAUSED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_SUSPENDED_MIGRATED, EVENT_SUSPENDED_MIGRATED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_SUSPENDED_IOERROR, EVENT_SUSPENDED_IOERROR);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_SUSPENDED_WATCHDOG, EVENT_SUSPENDED_WATCHDOG);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_SUSPENDED_RESTORED, EVENT_SUSPENDED_RESTORED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_SUSPENDED_FROM_SNAPSHOT, EVENT_SUSPENDED_FROM_SNAPSHOT);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_SUSPENDED_API_ERROR, EVENT_SUSPENDED_API_ERROR);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_SUSPENDED_POSTCOPY, EVENT_SUSPENDED_POSTCOPY);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_SUSPENDED_POSTCOPY_FAILED, EVENT_SUSPENDED_POSTCOPY_FAILED);

      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_RESUMED_UNPAUSED, EVENT_RESUMED_UNPAUSED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_RESUMED_MIGRATED, EVENT_RESUMED_MIGRATED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_RESUMED_FROM_SNAPSHOT, EVENT_RESUMED_FROM_SNAPSHOT);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_RESUMED_POSTCOPY, EVENT_RESUMED_POSTCOPY);

      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_STOPPED_SHUTDOWN, EVENT_STOPPED_SHUTDOWN);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_STOPPED_DESTROYED, EVENT_STOPPED_DESTROYED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_STOPPED_CRASHED, EVENT_STOPPED_CRASHED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_STOPPED_MIGRATED, EVENT_STOPPED_MIGRATED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_STOPPED_SAVED, EVENT_STOPPED_SAVED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_STOPPED_FAILED, EVENT_STOPPED_FAILED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_STOPPED_FROM_SNAPSHOT, EVENT_STOPPED_FROM_SNAPSHOT);

      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_SHUTDOWN_FINISHED, EVENT_SHUTDOWN_FINISHED);

      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_PMSUSPENDED_MEMORY, EVENT_PMSUSPENDED_MEMORY);


      REGISTER_CONSTANT(VIR_DOMAIN_CONTROL_OK, CONTROL_OK);
      REGISTER_CONSTANT(VIR_DOMAIN_CONTROL_JOB, CONTROL_JOB);
      REGISTER_CONSTANT(VIR_DOMAIN_CONTROL_OCCUPIED, CONTROL_OCCUPIED);
      REGISTER_CONSTANT(VIR_DOMAIN_CONTROL_ERROR, CONTROL_ERROR);

      REGISTER_CONSTANT(VIR_DOMAIN_CONTROL_ERROR_REASON_NONE, CONTROL_ERROR_REASON_NONE);
      REGISTER_CONSTANT(VIR_DOMAIN_CONTROL_ERROR_REASON_UNKNOWN, CONTROL_ERROR_REASON_UNKNOWN);
      REGISTER_CONSTANT(VIR_DOMAIN_CONTROL_ERROR_REASON_INTERNAL, CONTROL_ERROR_REASON_INTERNAL);
      REGISTER_CONSTANT(VIR_DOMAIN_CONTROL_ERROR_REASON_MONITOR, CONTROL_ERROR_REASON_MONITOR);

      REGISTER_CONSTANT(VIR_DOMAIN_DEVICE_MODIFY_CURRENT, DEVICE_MODIFY_CURRENT);
      REGISTER_CONSTANT(VIR_DOMAIN_DEVICE_MODIFY_LIVE, DEVICE_MODIFY_LIVE);
      REGISTER_CONSTANT(VIR_DOMAIN_DEVICE_MODIFY_CONFIG, DEVICE_MODIFY_CONFIG);
      REGISTER_CONSTANT(VIR_DOMAIN_DEVICE_MODIFY_FORCE, DEVICE_MODIFY_FORCE);


      REGISTER_CONSTANT(VIR_DOMAIN_MEM_CURRENT, MEM_CURRENT);
      REGISTER_CONSTANT(VIR_DOMAIN_MEM_LIVE, MEM_LIVE);
      REGISTER_CONSTANT(VIR_DOMAIN_MEM_CONFIG, MEM_CONFIG);
      REGISTER_CONSTANT(VIR_DOMAIN_MEM_MAXIMUM, MEM_MAXIMUM);


      REGISTER_CONSTANT(VIR_DOMAIN_AFFECT_CURRENT, AFFECT_CURRENT);
      REGISTER_CONSTANT(VIR_DOMAIN_AFFECT_LIVE, AFFECT_LIVE);
      REGISTER_CONSTANT(VIR_DOMAIN_AFFECT_CONFIG, AFFECT_CONFIG);


      REGISTER_CONSTANT(VIR_DOMAIN_JOB_NONE, JOB_NONE);
      REGISTER_CONSTANT(VIR_DOMAIN_JOB_BOUNDED, JOB_BOUNDED);
      REGISTER_CONSTANT(VIR_DOMAIN_JOB_UNBOUNDED, JOB_UNBOUNDED);
      REGISTER_CONSTANT(VIR_DOMAIN_JOB_COMPLETED, JOB_COMPLETED);
      REGISTER_CONSTANT(VIR_DOMAIN_JOB_FAILED, JOB_FAILED);
      REGISTER_CONSTANT(VIR_DOMAIN_JOB_CANCELLED, JOB_CANCELLED);

      REGISTER_CONSTANT(VIR_DOMAIN_JOB_STATS_COMPLETED, JOB_STATS_COMPLETED);

      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_AUTO_CONVERGE_THROTTLE, JOB_AUTO_CONVERGE_THROTTLE);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_COMPRESSION_BYTES, JOB_COMPRESSION_BYTES);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_COMPRESSION_CACHE, JOB_COMPRESSION_CACHE);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_COMPRESSION_CACHE_MISSES, JOB_COMPRESSION_CACHE_MISSES);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_COMPRESSION_OVERFLOW, JOB_COMPRESSION_OVERFLOW);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_COMPRESSION_PAGES, JOB_COMPRESSION_PAGES);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_DATA_PROCESSED, JOB_DATA_PROCESSED);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_DATA_REMAINING, JOB_DATA_REMAINING);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_DATA_TOTAL, JOB_DATA_TOTAL);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_DISK_PROCESSED, JOB_DISK_PROCESSED);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_DISK_REMAINING, JOB_DISK_REMAINING);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_DISK_TOTAL, JOB_DISK_TOTAL);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_DISK_BPS, JOB_DISK_BPS);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_DOWNTIME, JOB_DOWNTIME);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_DOWNTIME_NET, JOB_DOWNTIME_NET);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_MEMORY_CONSTANT, JOB_MEMORY_CONSTANT);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_MEMORY_NORMAL, JOB_MEMORY_NORMAL);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_MEMORY_NORMAL_BYTES, JOB_MEMORY_NORMAL_BYTES);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_MEMORY_PROCESSED, JOB_MEMORY_PROCESSED);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_MEMORY_REMAINING, JOB_MEMORY_REMAINING);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_MEMORY_TOTAL, JOB_MEMORY_TOTAL);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_MEMORY_BPS, JOB_MEMORY_BPS);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_MEMORY_DIRTY_RATE, JOB_MEMORY_DIRTY_RATE);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_MEMORY_ITERATION, JOB_MEMORY_ITERATION);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_SETUP_TIME, JOB_SETUP_TIME);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_TIME_ELAPSED, JOB_TIME_ELAPSED);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_TIME_ELAPSED_NET, JOB_TIME_ELAPSED_NET);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_TIME_REMAINING, JOB_TIME_REMAINING);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_JOB_OPERATION, JOB_OPERATION);

      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_JOB_TYPE_UNKNOWN, BLOCK_JOB_TYPE_UNKNOWN);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_JOB_TYPE_PULL, BLOCK_JOB_TYPE_PULL);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_JOB_TYPE_COPY, BLOCK_JOB_TYPE_COPY);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_JOB_TYPE_COMMIT, BLOCK_JOB_TYPE_COMMIT);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_JOB_TYPE_ACTIVE_COMMIT, BLOCK_JOB_TYPE_ACTIVE_COMMIT);

      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_JOB_COMPLETED, BLOCK_JOB_COMPLETED);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_JOB_FAILED, BLOCK_JOB_FAILED);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_JOB_CANCELED, BLOCK_JOB_CANCELED);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_JOB_READY, BLOCK_JOB_READY);

      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_COMMIT_DELETE, BLOCK_COMMIT_DELETE);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_COMMIT_SHALLOW, BLOCK_COMMIT_SHALLOW);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_COMMIT_ACTIVE, BLOCK_COMMIT_ACTIVE);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_COMMIT_RELATIVE, BLOCK_COMMIT_RELATIVE);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_COMMIT_BANDWIDTH_BYTES, BLOCK_COMMIT_BANDWIDTH_BYTES);

      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_LIFECYCLE, EVENT_ID_LIFECYCLE);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_REBOOT, EVENT_ID_REBOOT);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_RTC_CHANGE, EVENT_ID_RTC_CHANGE);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_WATCHDOG, EVENT_ID_WATCHDOG);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_IO_ERROR, EVENT_ID_IO_ERROR);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_GRAPHICS, EVENT_ID_GRAPHICS);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_IO_ERROR_REASON, EVENT_ID_IO_ERROR_REASON);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_CONTROL_ERROR, EVENT_ID_CONTROL_ERROR);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_BLOCK_JOB, EVENT_ID_BLOCK_JOB);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_BLOCK_JOB_2, EVENT_ID_BLOCK_JOB_2);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_DISK_CHANGE, EVENT_ID_DISK_CHANGE);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_PMSUSPEND, EVENT_ID_PMSUSPEND);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_PMSUSPEND_DISK, EVENT_ID_PMSUSPEND_DISK);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_PMWAKEUP, EVENT_ID_PMWAKEUP);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_TRAY_CHANGE, EVENT_ID_TRAY_CHANGE);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_BALLOON_CHANGE, EVENT_ID_BALLOON_CHANGE);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_DEVICE_ADDED, EVENT_ID_DEVICE_ADDED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_DEVICE_REMOVED, EVENT_ID_DEVICE_REMOVED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_TUNABLE, EVENT_ID_TUNABLE);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_AGENT_LIFECYCLE, EVENT_ID_AGENT_LIFECYCLE);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_MIGRATION_ITERATION, EVENT_ID_MIGRATION_ITERATION);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_JOB_COMPLETED, EVENT_ID_JOB_COMPLETED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_DEVICE_REMOVAL_FAILED, EVENT_ID_DEVICE_REMOVAL_FAILED);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_METADATA_CHANGE, EVENT_ID_METADATA_CHANGE);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_ID_BLOCK_THRESHOLD, EVENT_ID_BLOCK_THRESHOLD);

      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_WATCHDOG_NONE, EVENT_WATCHDOG_NONE);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_WATCHDOG_PAUSE, EVENT_WATCHDOG_PAUSE);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_WATCHDOG_RESET, EVENT_WATCHDOG_RESET);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_WATCHDOG_POWEROFF, EVENT_WATCHDOG_POWEROFF);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_WATCHDOG_SHUTDOWN, EVENT_WATCHDOG_SHUTDOWN);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_WATCHDOG_DEBUG, EVENT_WATCHDOG_DEBUG);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_WATCHDOG_INJECTNMI, EVENT_WATCHDOG_INJECTNMI);

      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_IO_ERROR_NONE, EVENT_IO_ERROR_NONE);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_IO_ERROR_PAUSE, EVENT_IO_ERROR_PAUSE);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_IO_ERROR_REPORT, EVENT_IO_ERROR_REPORT);

      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_GRAPHICS_CONNECT, EVENT_GRAPHICS_CONNECT);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_GRAPHICS_INITIALIZE, EVENT_GRAPHICS_INITIALIZE);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_GRAPHICS_DISCONNECT, EVENT_GRAPHICS_DISCONNECT);

      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_GRAPHICS_ADDRESS_IPV4, EVENT_GRAPHICS_ADDRESS_IPV4);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_GRAPHICS_ADDRESS_IPV6, EVENT_GRAPHICS_ADDRESS_IPV6);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_GRAPHICS_ADDRESS_UNIX, EVENT_GRAPHICS_ADDRESS_UNIX);

      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_DISK_CHANGE_MISSING_ON_START, EVENT_DISK_CHANGE_MISSING_ON_START);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_DISK_DROP_MISSING_ON_START, EVENT_DISK_DROP_MISSING_ON_START);

      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_TRAY_CHANGE_OPEN, EVENT_TRAY_CHANGE_OPEN);
      REGISTER_CONSTANT(VIR_DOMAIN_EVENT_TRAY_CHANGE_CLOSE, EVENT_TRAY_CHANGE_CLOSE);

      REGISTER_CONSTANT(VIR_CONNECT_DOMAIN_EVENT_AGENT_LIFECYCLE_STATE_CONNECTED, EVENT_AGENT_LIFECYCLE_STATE_CONNECTED);
      REGISTER_CONSTANT(VIR_CONNECT_DOMAIN_EVENT_AGENT_LIFECYCLE_STATE_DISCONNECTED, EVENT_AGENT_LIFECYCLE_STATE_DISCONNECTED);

      REGISTER_CONSTANT(VIR_CONNECT_DOMAIN_EVENT_AGENT_LIFECYCLE_REASON_CHANNEL, EVENT_AGENT_LIFECYCLE_REASON_CHANNEL);
      REGISTER_CONSTANT(VIR_CONNECT_DOMAIN_EVENT_AGENT_LIFECYCLE_REASON_DOMAIN_STARTED, EVENT_AGENT_LIFECYCLE_REASON_DOMAIN_STARTED);
      REGISTER_CONSTANT(VIR_CONNECT_DOMAIN_EVENT_AGENT_LIFECYCLE_REASON_UNKNOWN, EVENT_AGENT_LIFECYCLE_REASON_UNKNOWN);

      REGISTER_CONSTANT_STR(VIR_DOMAIN_MEMORY_HARD_LIMIT, MEMORY_HARD_LIMIT);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_MEMORY_SOFT_LIMIT, MEMORY_SOFT_LIMIT);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_MEMORY_MIN_GUARANTEE, MEMORY_MIN_GUARANTEE);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_MEMORY_SWAP_HARD_LIMIT, MEMORY_SWAP_HARD_LIMIT);
      REGISTER_CONSTANT_ULL(VIR_DOMAIN_MEMORY_PARAM_UNLIMITED, MEMORY_PARAM_UNLIMITED);

      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLKIO_WEIGHT, BLKIO_WEIGHT);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLKIO_DEVICE_WEIGHT, BLKIO_DEVICE_WEIGHT);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLKIO_DEVICE_READ_BPS, BLKIO_DEVICE_READ_BPS);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLKIO_DEVICE_READ_IOPS, BLKIO_DEVICE_READ_IOPS);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLKIO_DEVICE_WRITE_BPS, BLKIO_DEVICE_WRITE_BPS);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLKIO_DEVICE_WRITE_IOPS, BLKIO_DEVICE_WRITE_IOPS);

      REGISTER_CONSTANT_STR(VIR_DOMAIN_SCHEDULER_CPU_SHARES, SCHEDULER_CPU_SHARES);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_SCHEDULER_VCPU_PERIOD, SCHEDULER_VCPU_PERIOD);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_SCHEDULER_VCPU_QUOTA, SCHEDULER_VCPU_QUOTA);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_SCHEDULER_GLOBAL_PERIOD, SCHEDULER_GLOBAL_PERIOD);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_SCHEDULER_GLOBAL_QUOTA, SCHEDULER_GLOBAL_QUOTA);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_SCHEDULER_WEIGHT, SCHEDULER_WEIGHT);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_SCHEDULER_CAP, SCHEDULER_CAP);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_SCHEDULER_LIMIT, SCHEDULER_LIMIT);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_SCHEDULER_RESERVATION, SCHEDULER_RESERVATION);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_SCHEDULER_SHARES, SCHEDULER_SHARES);


      REGISTER_CONSTANT(VIR_DOMAIN_MEMORY_STAT_SWAP_IN, MEMORY_STAT_SWAP_IN);
      REGISTER_CONSTANT(VIR_DOMAIN_MEMORY_STAT_SWAP_OUT, MEMORY_STAT_SWAP_OUT);
      REGISTER_CONSTANT(VIR_DOMAIN_MEMORY_STAT_MAJOR_FAULT, MEMORY_STAT_MAJOR_FAULT);
      REGISTER_CONSTANT(VIR_DOMAIN_MEMORY_STAT_MINOR_FAULT, MEMORY_STAT_MINOR_FAULT);
      REGISTER_CONSTANT(VIR_DOMAIN_MEMORY_STAT_UNUSED, MEMORY_STAT_UNUSED);
      REGISTER_CONSTANT(VIR_DOMAIN_MEMORY_STAT_AVAILABLE, MEMORY_STAT_AVAILABLE);
      REGISTER_CONSTANT(VIR_DOMAIN_MEMORY_STAT_ACTUAL_BALLOON, MEMORY_STAT_ACTUAL_BALLOON);
      REGISTER_CONSTANT(VIR_DOMAIN_MEMORY_STAT_RSS, MEMORY_STAT_RSS);
      REGISTER_CONSTANT(VIR_DOMAIN_MEMORY_STAT_LAST_UPDATE, MEMORY_STAT_LAST_UPDATE);
      REGISTER_CONSTANT(VIR_DOMAIN_MEMORY_STAT_USABLE, MEMORY_STAT_USABLE);


      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_TOTAL_BYTES_SEC, BLOCK_IOTUNE_TOTAL_BYTES_SEC);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_READ_BYTES_SEC, BLOCK_IOTUNE_READ_BYTES_SEC);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_WRITE_BYTES_SEC, BLOCK_IOTUNE_WRITE_BYTES_SEC);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_TOTAL_IOPS_SEC, BLOCK_IOTUNE_TOTAL_IOPS_SEC);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_READ_IOPS_SEC, BLOCK_IOTUNE_READ_IOPS_SEC);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_WRITE_IOPS_SEC, BLOCK_IOTUNE_WRITE_IOPS_SEC);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_TOTAL_BYTES_SEC_MAX, BLOCK_IOTUNE_TOTAL_BYTES_SEC_MAX);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_READ_BYTES_SEC_MAX, BLOCK_IOTUNE_READ_BYTES_SEC_MAX);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_WRITE_BYTES_SEC_MAX, BLOCK_IOTUNE_WRITE_BYTES_SEC_MAX);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_TOTAL_IOPS_SEC_MAX, BLOCK_IOTUNE_TOTAL_IOPS_SEC_MAX);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_READ_IOPS_SEC_MAX, BLOCK_IOTUNE_READ_IOPS_SEC_MAX);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_WRITE_IOPS_SEC_MAX, BLOCK_IOTUNE_WRITE_IOPS_SEC_MAX);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_SIZE_IOPS_SEC, BLOCK_IOTUNE_SIZE_IOPS_SEC);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_GROUP_NAME, BLOCK_IOTUNE_GROUP_NAME);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_TOTAL_BYTES_SEC_MAX_LENGTH, BLOCK_IOTUNE_TOTAL_BYTES_SEC_MAX_LENGTH);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_READ_BYTES_SEC_MAX_LENGTH, BLOCK_IOTUNE_READ_BYTES_SEC_MAX_LENGTH);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_WRITE_BYTES_SEC_MAX_LENGTH, BLOCK_IOTUNE_WRITE_BYTES_SEC_MAX_LENGTH);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_TOTAL_IOPS_SEC_MAX_LENGTH, BLOCK_IOTUNE_TOTAL_IOPS_SEC_MAX_LENGTH);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_READ_IOPS_SEC_MAX_LENGTH, BLOCK_IOTUNE_READ_IOPS_SEC_MAX_LENGTH);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_IOTUNE_WRITE_IOPS_SEC_MAX_LENGTH, BLOCK_IOTUNE_WRITE_IOPS_SEC_MAX_LENGTH);


      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_RESIZE_BYTES, BLOCK_RESIZE_BYTES);


      REGISTER_CONSTANT_STR(VIR_DOMAIN_NUMA_NODESET, NUMA_NODESET);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_NUMA_MODE, NUMA_MODE);

      REGISTER_CONSTANT(VIR_DOMAIN_NUMATUNE_MEM_STRICT, NUMATUNE_MEM_STRICT);
      REGISTER_CONSTANT(VIR_DOMAIN_NUMATUNE_MEM_PREFERRED, NUMATUNE_MEM_PREFERRED);
      REGISTER_CONSTANT(VIR_DOMAIN_NUMATUNE_MEM_INTERLEAVE, NUMATUNE_MEM_INTERLEAVE);

      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_CMT, PERF_PARAM_CMT);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_MBML, PERF_PARAM_MBML);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_MBMT, PERF_PARAM_MBMT);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_CACHE_MISSES, PERF_PARAM_CACHE_MISSES);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_CACHE_REFERENCES, PERF_PARAM_CACHE_REFERENCES);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_CPU_CYCLES, PERF_PARAM_CPU_CYCLES);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_INSTRUCTIONS, PERF_PARAM_INSTRUCTIONS);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_BRANCH_INSTRUCTIONS, PERF_PARAM_BRANCH_INSTRUCTIONS);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_BRANCH_MISSES, PERF_PARAM_BRANCH_MISSES);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_BUS_CYCLES, PERF_PARAM_BUS_CYCLES);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_STALLED_CYCLES_FRONTEND, PERF_PARAM_STALLED_CYCLES_FRONTEND);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_STALLED_CYCLES_BACKEND, PERF_PARAM_STALLED_CYCLES_BACKEND);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_REF_CPU_CYCLES, PERF_PARAM_REF_CPU_CYCLES);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_CPU_CLOCK, PERF_PARAM_CPU_CLOCK);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_TASK_CLOCK, PERF_PARAM_TASK_CLOCK);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_PAGE_FAULTS, PERF_PARAM_PAGE_FAULTS);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_CONTEXT_SWITCHES, PERF_PARAM_CONTEXT_SWITCHES);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_CPU_MIGRATIONS, PERF_PARAM_CPU_MIGRATIONS);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_PAGE_FAULTS_MIN, PERF_PARAM_PAGE_FAULTS_MIN);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_PAGE_FAULTS_MAJ, PERF_PARAM_PAGE_FAULTS_MAJ);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_ALIGNMENT_FAULTS, PERF_PARAM_ALIGNMENT_FAULTS);
      REGISTER_CONSTANT_STR(VIR_PERF_PARAM_EMULATION_FAULTS, PERF_PARAM_EMULATION_FAULTS);

      REGISTER_CONSTANT_STR(VIR_DOMAIN_BANDWIDTH_IN_AVERAGE, BANDWIDTH_IN_AVERAGE);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BANDWIDTH_IN_PEAK, BANDWIDTH_IN_PEAK);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BANDWIDTH_IN_BURST, BANDWIDTH_IN_BURST);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BANDWIDTH_IN_FLOOR, BANDWIDTH_IN_FLOOR);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BANDWIDTH_OUT_AVERAGE, BANDWIDTH_OUT_AVERAGE);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BANDWIDTH_OUT_PEAK, BANDWIDTH_OUT_PEAK);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BANDWIDTH_OUT_BURST, BANDWIDTH_OUT_BURST);


      REGISTER_CONSTANT(VIR_DOMAIN_VCPU_CURRENT, VCPU_CURRENT);
      REGISTER_CONSTANT(VIR_DOMAIN_VCPU_LIVE, VCPU_LIVE);
      REGISTER_CONSTANT(VIR_DOMAIN_VCPU_CONFIG, VCPU_CONFIG);
      REGISTER_CONSTANT(VIR_DOMAIN_VCPU_MAXIMUM, VCPU_MAXIMUM);
      REGISTER_CONSTANT(VIR_DOMAIN_VCPU_GUEST, VCPU_GUEST);
      REGISTER_CONSTANT(VIR_DOMAIN_VCPU_HOTPLUGGABLE, VCPU_HOTPLUGGABLE);


      REGISTER_CONSTANT(VIR_DOMAIN_SHUTDOWN_DEFAULT, SHUTDOWN_DEFAULT);
      REGISTER_CONSTANT(VIR_DOMAIN_SHUTDOWN_ACPI_POWER_BTN, SHUTDOWN_ACPI_POWER_BTN);
      REGISTER_CONSTANT(VIR_DOMAIN_SHUTDOWN_GUEST_AGENT, SHUTDOWN_GUEST_AGENT);
      REGISTER_CONSTANT(VIR_DOMAIN_SHUTDOWN_INITCTL, SHUTDOWN_INITCTL);
      REGISTER_CONSTANT(VIR_DOMAIN_SHUTDOWN_SIGNAL, SHUTDOWN_SIGNAL);
      REGISTER_CONSTANT(VIR_DOMAIN_SHUTDOWN_PARAVIRT, SHUTDOWN_PARAVIRT);


      REGISTER_CONSTANT(VIR_DOMAIN_REBOOT_DEFAULT, REBOOT_DEFAULT);
      REGISTER_CONSTANT(VIR_DOMAIN_REBOOT_ACPI_POWER_BTN, REBOOT_ACPI_POWER_BTN);
      REGISTER_CONSTANT(VIR_DOMAIN_REBOOT_GUEST_AGENT, REBOOT_GUEST_AGENT);
      REGISTER_CONSTANT(VIR_DOMAIN_REBOOT_INITCTL, REBOOT_INITCTL);
      REGISTER_CONSTANT(VIR_DOMAIN_REBOOT_SIGNAL, REBOOT_SIGNAL);
      REGISTER_CONSTANT(VIR_DOMAIN_REBOOT_PARAVIRT, REBOOT_PARAVIRT);

      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_NOP, PROCESS_SIGNAL_NOP);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_HUP, PROCESS_SIGNAL_HUP);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_INT, PROCESS_SIGNAL_INT);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_QUIT, PROCESS_SIGNAL_QUIT);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_ILL, PROCESS_SIGNAL_ILL);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_TRAP, PROCESS_SIGNAL_TRAP);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_ABRT, PROCESS_SIGNAL_ABRT);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_BUS, PROCESS_SIGNAL_BUS);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_FPE, PROCESS_SIGNAL_FPE);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_KILL, PROCESS_SIGNAL_KILL);

      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_USR1, PROCESS_SIGNAL_USR1);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_SEGV, PROCESS_SIGNAL_SEGV);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_USR2, PROCESS_SIGNAL_USR2);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_PIPE, PROCESS_SIGNAL_PIPE);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_ALRM, PROCESS_SIGNAL_ALRM);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_TERM, PROCESS_SIGNAL_TERM);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_STKFLT, PROCESS_SIGNAL_STKFLT);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_CHLD, PROCESS_SIGNAL_CHLD);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_CONT, PROCESS_SIGNAL_CONT);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_STOP, PROCESS_SIGNAL_STOP);

      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_TSTP, PROCESS_SIGNAL_TSTP);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_TTIN, PROCESS_SIGNAL_TTIN);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_TTOU, PROCESS_SIGNAL_TTOU);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_URG, PROCESS_SIGNAL_URG);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_XCPU, PROCESS_SIGNAL_XCPU);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_XFSZ, PROCESS_SIGNAL_XFSZ);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_VTALRM, PROCESS_SIGNAL_VTALRM);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_PROF, PROCESS_SIGNAL_PROF);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_WINCH, PROCESS_SIGNAL_WINCH);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_POLL, PROCESS_SIGNAL_POLL);

      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_PWR, PROCESS_SIGNAL_PWR);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_SYS, PROCESS_SIGNAL_SYS);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT0, PROCESS_SIGNAL_RT0);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT1, PROCESS_SIGNAL_RT1);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT2, PROCESS_SIGNAL_RT2);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT3, PROCESS_SIGNAL_RT3);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT4, PROCESS_SIGNAL_RT4);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT5, PROCESS_SIGNAL_RT5);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT6, PROCESS_SIGNAL_RT6);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT7, PROCESS_SIGNAL_RT7);

      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT8, PROCESS_SIGNAL_RT8);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT9, PROCESS_SIGNAL_RT9);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT10, PROCESS_SIGNAL_RT10);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT11, PROCESS_SIGNAL_RT11);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT12, PROCESS_SIGNAL_RT12);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT13, PROCESS_SIGNAL_RT13);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT14, PROCESS_SIGNAL_RT14);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT15, PROCESS_SIGNAL_RT15);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT16, PROCESS_SIGNAL_RT16);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT17, PROCESS_SIGNAL_RT17);

      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT18, PROCESS_SIGNAL_RT18);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT19, PROCESS_SIGNAL_RT19);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT20, PROCESS_SIGNAL_RT20);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT21, PROCESS_SIGNAL_RT21);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT22, PROCESS_SIGNAL_RT22);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT23, PROCESS_SIGNAL_RT23);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT24, PROCESS_SIGNAL_RT24);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT25, PROCESS_SIGNAL_RT25);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT26, PROCESS_SIGNAL_RT26);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT27, PROCESS_SIGNAL_RT27);

      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT28, PROCESS_SIGNAL_RT28);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT29, PROCESS_SIGNAL_RT29);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT30, PROCESS_SIGNAL_RT30);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT31, PROCESS_SIGNAL_RT31);
      REGISTER_CONSTANT(VIR_DOMAIN_PROCESS_SIGNAL_RT32, PROCESS_SIGNAL_RT32);

      REGISTER_CONSTANT(VIR_DOMAIN_DESTROY_DEFAULT, DESTROY_DEFAULT);
      REGISTER_CONSTANT(VIR_DOMAIN_DESTROY_GRACEFUL, DESTROY_GRACEFUL);


      REGISTER_CONSTANT(VIR_DOMAIN_METADATA_DESCRIPTION, METADATA_DESCRIPTION);
      REGISTER_CONSTANT(VIR_DOMAIN_METADATA_TITLE, METADATA_TITLE);
      REGISTER_CONSTANT(VIR_DOMAIN_METADATA_ELEMENT, METADATA_ELEMENT);

      REGISTER_CONSTANT(VIR_DOMAIN_DISK_ERROR_NONE, DISK_ERROR_NONE);
      REGISTER_CONSTANT(VIR_DOMAIN_DISK_ERROR_NO_SPACE, DISK_ERROR_NO_SPACE);
      REGISTER_CONSTANT(VIR_DOMAIN_DISK_ERROR_UNSPEC, DISK_ERROR_UNSPEC);


      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_JOB_ABORT_ASYNC, BLOCK_JOB_ABORT_ASYNC);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_JOB_ABORT_PIVOT, BLOCK_JOB_ABORT_PIVOT);

      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_REBASE_SHALLOW, BLOCK_REBASE_SHALLOW);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_REBASE_REUSE_EXT, BLOCK_REBASE_REUSE_EXT);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_REBASE_COPY_RAW, BLOCK_REBASE_COPY_RAW);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_REBASE_COPY, BLOCK_REBASE_COPY);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_REBASE_COPY_DEV, BLOCK_REBASE_COPY_DEV);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_REBASE_RELATIVE, BLOCK_REBASE_RELATIVE);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_REBASE_BANDWIDTH_BYTES, BLOCK_REBASE_BANDWIDTH_BYTES);

      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_COPY_BANDWIDTH, BLOCK_COPY_BANDWIDTH);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_COPY_GRANULARITY, BLOCK_COPY_GRANULARITY);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_BLOCK_COPY_BUF_SIZE, BLOCK_COPY_BUF_SIZE);

      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_COPY_REUSE_EXT, BLOCK_COPY_REUSE_EXT);
      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_COPY_SHALLOW, BLOCK_COPY_SHALLOW);

      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_JOB_SPEED_BANDWIDTH_BYTES, BLOCK_JOB_SPEED_BANDWIDTH_BYTES);

      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_PULL_BANDWIDTH_BYTES, BLOCK_PULL_BANDWIDTH_BYTES);

      REGISTER_CONSTANT(VIR_DOMAIN_BLOCK_JOB_INFO_BANDWIDTH_BYTES, BLOCK_JOB_INFO_BANDWIDTH_BYTES);

      REGISTER_CONSTANT(VIR_CONNECT_LIST_DOMAINS_ACTIVE, LIST_ACTIVE);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_DOMAINS_AUTOSTART, LIST_AUTOSTART);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_DOMAINS_HAS_SNAPSHOT, LIST_HAS_SNAPSHOT);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_DOMAINS_INACTIVE, LIST_INACTIVE);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_DOMAINS_MANAGEDSAVE, LIST_MANAGEDSAVE);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_DOMAINS_NO_AUTOSTART, LIST_NO_AUTOSTART);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_DOMAINS_NO_MANAGEDSAVE, LIST_NO_MANAGEDSAVE);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_DOMAINS_NO_SNAPSHOT, LIST_NO_SNAPSHOT);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_DOMAINS_OTHER, LIST_OTHER);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_DOMAINS_PAUSED, LIST_PAUSED);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_DOMAINS_PERSISTENT, LIST_PERSISTENT);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_DOMAINS_RUNNING, LIST_RUNNING);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_DOMAINS_SHUTOFF, LIST_SHUTOFF);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_DOMAINS_TRANSIENT, LIST_TRANSIENT);

      REGISTER_CONSTANT(VIR_DOMAIN_SEND_KEY_MAX_KEYS, SEND_KEY_MAX_KEYS);

      REGISTER_CONSTANT(VIR_DOMAIN_CORE_DUMP_FORMAT_RAW, CORE_DUMP_FORMAT_RAW);
      REGISTER_CONSTANT(VIR_DOMAIN_CORE_DUMP_FORMAT_KDUMP_LZO, CORE_DUMP_FORMAT_KDUMP_LZO);
      REGISTER_CONSTANT(VIR_DOMAIN_CORE_DUMP_FORMAT_KDUMP_SNAPPY, CORE_DUMP_FORMAT_KDUMP_SNAPPY);
      REGISTER_CONSTANT(VIR_DOMAIN_CORE_DUMP_FORMAT_KDUMP_ZLIB, CORE_DUMP_FORMAT_KDUMP_ZLIB);

      REGISTER_CONSTANT(VIR_DOMAIN_TIME_SYNC, TIME_SYNC);

      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_CPU_CPU_SHARES, TUNABLE_CPU_CPU_SHARES);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_CPU_EMULATORPIN, TUNABLE_CPU_EMULATORPIN);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_CPU_EMULATOR_PERIOD, TUNABLE_CPU_EMULATOR_PERIOD);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_CPU_EMULATOR_QUOTA, TUNABLE_CPU_EMULATOR_QUOTA);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_CPU_IOTHREAD_PERIOD, TUNABLE_CPU_IOTHREAD_PERIOD);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_CPU_IOTHREAD_QUOTA, TUNABLE_CPU_IOTHREAD_QUOTA);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_CPU_VCPUPIN, TUNABLE_CPU_VCPUPIN);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_CPU_VCPU_PERIOD, TUNABLE_CPU_VCPU_PERIOD);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_CPU_VCPU_QUOTA, TUNABLE_CPU_VCPU_QUOTA);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_CPU_GLOBAL_PERIOD, TUNABLE_CPU_GLOBAL_PERIOD);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_CPU_GLOBAL_QUOTA, TUNABLE_CPU_GLOBAL_QUOTA);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_DISK, TUNABLE_BLKDEV_DISK);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_READ_BYTES_SEC, TUNABLE_BLKDEV_READ_BYTES_SEC);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_READ_IOPS_SEC, TUNABLE_BLKDEV_READ_IOPS_SEC);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_TOTAL_BYTES_SEC, TUNABLE_BLKDEV_TOTAL_BYTES_SEC);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_TOTAL_IOPS_SEC, TUNABLE_BLKDEV_TOTAL_IOPS_SEC);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_WRITE_BYTES_SEC, TUNABLE_BLKDEV_WRITE_BYTES_SEC);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_WRITE_IOPS_SEC, TUNABLE_BLKDEV_WRITE_IOPS_SEC);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_READ_BYTES_SEC_MAX, TUNABLE_BLKDEV_READ_BYTES_SEC_MAX);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_READ_IOPS_SEC_MAX, TUNABLE_BLKDEV_READ_IOPS_SEC_MAX);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_WRITE_BYTES_SEC_MAX, TUNABLE_BLKDEV_WRITE_BYTES_SEC_MAX);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_WRITE_IOPS_SEC_MAX, TUNABLE_BLKDEV_WRITE_IOPS_SEC_MAX);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_TOTAL_BYTES_SEC_MAX, TUNABLE_BLKDEV_TOTAL_BYTES_SEC_MAX);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_TOTAL_IOPS_SEC_MAX, TUNABLE_BLKDEV_TOTAL_IOPS_SEC_MAX);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_SIZE_IOPS_SEC, TUNABLE_BLKDEV_SIZE_IOPS_SEC);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_GROUP_NAME, TUNABLE_BLKDEV_GROUP_NAME);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_READ_BYTES_SEC_MAX_LENGTH, TUNABLE_BLKDEV_READ_BYTES_SEC_MAX_LENGTH);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_READ_IOPS_SEC_MAX_LENGTH, TUNABLE_BLKDEV_READ_IOPS_SEC_MAX_LENGTH);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_WRITE_BYTES_SEC_MAX_LENGTH, TUNABLE_BLKDEV_WRITE_BYTES_SEC_MAX_LENGTH);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_WRITE_IOPS_SEC_MAX_LENGTH, TUNABLE_BLKDEV_WRITE_IOPS_SEC_MAX_LENGTH);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_TOTAL_BYTES_SEC_MAX_LENGTH, TUNABLE_BLKDEV_TOTAL_BYTES_SEC_MAX_LENGTH);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_BLKDEV_TOTAL_IOPS_SEC_MAX_LENGTH, TUNABLE_BLKDEV_TOTAL_IOPS_SEC_MAX_LENGTH);
      REGISTER_CONSTANT_STR(VIR_DOMAIN_TUNABLE_CPU_IOTHREADSPIN, TUNABLE_IOTHREADSPIN);


      REGISTER_CONSTANT(VIR_DOMAIN_INTERFACE_ADDRESSES_SRC_AGENT, INTERFACE_ADDRESSES_SRC_AGENT);
      REGISTER_CONSTANT(VIR_DOMAIN_INTERFACE_ADDRESSES_SRC_LEASE, INTERFACE_ADDRESSES_SRC_LEASE);


      REGISTER_CONSTANT(VIR_DOMAIN_PASSWORD_ENCRYPTED, PASSWORD_ENCRYPTED);

      REGISTER_CONSTANT(VIR_DOMAIN_JOB_OPERATION_UNKNOWN, JOB_OPERATION_UNKNOWN);
      REGISTER_CONSTANT(VIR_DOMAIN_JOB_OPERATION_START, JOB_OPERATION_START);
      REGISTER_CONSTANT(VIR_DOMAIN_JOB_OPERATION_SAVE, JOB_OPERATION_SAVE);
      REGISTER_CONSTANT(VIR_DOMAIN_JOB_OPERATION_RESTORE, JOB_OPERATION_RESTORE);
      REGISTER_CONSTANT(VIR_DOMAIN_JOB_OPERATION_MIGRATION_IN, JOB_OPERATION_MIGRATION_IN);
      REGISTER_CONSTANT(VIR_DOMAIN_JOB_OPERATION_MIGRATION_OUT, JOB_OPERATION_MIGRATION_OUT);
      REGISTER_CONSTANT(VIR_DOMAIN_JOB_OPERATION_SNAPSHOT, JOB_OPERATION_SNAPSHOT);
      REGISTER_CONSTANT(VIR_DOMAIN_JOB_OPERATION_SNAPSHOT_REVERT, JOB_OPERATION_SNAPSHOT_REVERT);
      REGISTER_CONSTANT(VIR_DOMAIN_JOB_OPERATION_DUMP, JOB_OPERATION_DUMP);

      stash = gv_stashpv( "Sys::Virt::DomainSnapshot", TRUE );
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_DELETE_CHILDREN, DELETE_CHILDREN);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_DELETE_METADATA_ONLY, DELETE_METADATA_ONLY);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_DELETE_CHILDREN_ONLY, DELETE_CHILDREN_ONLY);

      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_CREATE_REDEFINE, CREATE_REDEFINE);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_CREATE_CURRENT, CREATE_CURRENT);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_CREATE_NO_METADATA, CREATE_NO_METADATA);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_CREATE_HALT, CREATE_HALT);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_CREATE_DISK_ONLY, CREATE_DISK_ONLY);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_CREATE_REUSE_EXT, CREATE_REUSE_EXT);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_CREATE_QUIESCE, CREATE_QUIESCE);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_CREATE_ATOMIC, CREATE_ATOMIC);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_CREATE_LIVE, CREATE_LIVE);

      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_LIST_ROOTS, LIST_ROOTS);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_LIST_DESCENDANTS, LIST_DESCENDANTS);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_LIST_METADATA, LIST_METADATA);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_LIST_LEAVES, LIST_LEAVES);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_LIST_NO_LEAVES, LIST_NO_LEAVES);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_LIST_NO_METADATA, LIST_NO_METADATA);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_LIST_ACTIVE, LIST_ACTIVE);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_LIST_INACTIVE, LIST_INACTIVE);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_LIST_EXTERNAL, LIST_EXTERNAL);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_LIST_INTERNAL, LIST_INTERNAL);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_LIST_DISK_ONLY, LIST_DISK_ONLY);


      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_REVERT_RUNNING, REVERT_RUNNING);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_REVERT_PAUSED, REVERT_PAUSED);
      REGISTER_CONSTANT(VIR_DOMAIN_SNAPSHOT_REVERT_FORCE, REVERT_FORCE);

      stash = gv_stashpv( "Sys::Virt::StoragePool", TRUE );
      REGISTER_CONSTANT(VIR_STORAGE_POOL_INACTIVE, STATE_INACTIVE);
      REGISTER_CONSTANT(VIR_STORAGE_POOL_BUILDING, STATE_BUILDING);
      REGISTER_CONSTANT(VIR_STORAGE_POOL_RUNNING, STATE_RUNNING);
      REGISTER_CONSTANT(VIR_STORAGE_POOL_DEGRADED, STATE_DEGRADED);
      REGISTER_CONSTANT(VIR_STORAGE_POOL_INACCESSIBLE, STATE_INACCESSIBLE);

      REGISTER_CONSTANT(VIR_STORAGE_POOL_BUILD_NEW, BUILD_NEW);
      REGISTER_CONSTANT(VIR_STORAGE_POOL_BUILD_REPAIR, BUILD_REPAIR);
      REGISTER_CONSTANT(VIR_STORAGE_POOL_BUILD_RESIZE, BUILD_RESIZE);
      REGISTER_CONSTANT(VIR_STORAGE_POOL_BUILD_NO_OVERWRITE, BUILD_NO_OVERWRITE);
      REGISTER_CONSTANT(VIR_STORAGE_POOL_BUILD_OVERWRITE, BUILD_OVERWRITE);

      REGISTER_CONSTANT(VIR_STORAGE_POOL_CREATE_NORMAL, CREATE_NORMAL);
      REGISTER_CONSTANT(VIR_STORAGE_POOL_CREATE_WITH_BUILD, CREATE_WITH_BUILD);
      REGISTER_CONSTANT(VIR_STORAGE_POOL_CREATE_WITH_BUILD_OVERWRITE, CREATE_WITH_BUILD_OVERWRITE);
      REGISTER_CONSTANT(VIR_STORAGE_POOL_CREATE_WITH_BUILD_NO_OVERWRITE, CREATE_WITH_BUILD_NO_OVERWRITE);

      REGISTER_CONSTANT(VIR_STORAGE_POOL_DELETE_NORMAL, DELETE_NORMAL);
      REGISTER_CONSTANT(VIR_STORAGE_POOL_DELETE_ZEROED, DELETE_ZEROED);

      REGISTER_CONSTANT(VIR_STORAGE_XML_INACTIVE, XML_INACTIVE);


      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_INACTIVE, LIST_INACTIVE);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_ACTIVE, LIST_ACTIVE);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_PERSISTENT, LIST_PERSISTENT);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_TRANSIENT, LIST_TRANSIENT);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_AUTOSTART, LIST_AUTOSTART);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_NO_AUTOSTART, LIST_NO_AUTOSTART);

      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_DIR, LIST_DIR);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_FS, LIST_FS);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_NETFS, LIST_NETFS);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_LOGICAL, LIST_LOGICAL);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_DISK, LIST_DISK);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_ISCSI, LIST_ISCSI);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_SCSI, LIST_SCSI);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_MPATH, LIST_MPATH);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_RBD, LIST_RBD);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_SHEEPDOG, LIST_SHEEPDOG);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_GLUSTER, LIST_GLUSTER);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_ZFS, LIST_ZFS);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_STORAGE_POOLS_VSTORAGE, LIST_VSTORAGE);

      REGISTER_CONSTANT(VIR_STORAGE_POOL_EVENT_ID_LIFECYCLE, EVENT_ID_LIFECYCLE);
      REGISTER_CONSTANT(VIR_STORAGE_POOL_EVENT_ID_REFRESH, EVENT_ID_REFRESH);

      REGISTER_CONSTANT(VIR_STORAGE_POOL_EVENT_DEFINED, EVENT_DEFINED);
      REGISTER_CONSTANT(VIR_STORAGE_POOL_EVENT_UNDEFINED, EVENT_UNDEFINED);
      REGISTER_CONSTANT(VIR_STORAGE_POOL_EVENT_STARTED, EVENT_STARTED);
      REGISTER_CONSTANT(VIR_STORAGE_POOL_EVENT_STOPPED, EVENT_STOPPED);


      stash = gv_stashpv( "Sys::Virt::Network", TRUE );
      REGISTER_CONSTANT(VIR_NETWORK_XML_INACTIVE, XML_INACTIVE);

      REGISTER_CONSTANT(VIR_NETWORK_UPDATE_COMMAND_NONE, UPDATE_COMMAND_NONE);
      REGISTER_CONSTANT(VIR_NETWORK_UPDATE_COMMAND_MODIFY, UPDATE_COMMAND_MODIFY);
      REGISTER_CONSTANT(VIR_NETWORK_UPDATE_COMMAND_DELETE, UPDATE_COMMAND_DELETE);
      REGISTER_CONSTANT(VIR_NETWORK_UPDATE_COMMAND_ADD_LAST, UPDATE_COMMAND_ADD_LAST);
      REGISTER_CONSTANT(VIR_NETWORK_UPDATE_COMMAND_ADD_FIRST, UPDATE_COMMAND_ADD_FIRST);

      REGISTER_CONSTANT(VIR_NETWORK_SECTION_NONE, SECTION_NONE);
      REGISTER_CONSTANT(VIR_NETWORK_SECTION_BRIDGE, SECTION_BRIDGE);
      REGISTER_CONSTANT(VIR_NETWORK_SECTION_DOMAIN, SECTION_DOMAIN);
      REGISTER_CONSTANT(VIR_NETWORK_SECTION_IP, SECTION_IP);
      REGISTER_CONSTANT(VIR_NETWORK_SECTION_IP_DHCP_HOST, SECTION_IP_DHCP_HOST);
      REGISTER_CONSTANT(VIR_NETWORK_SECTION_IP_DHCP_RANGE, SECTION_IP_DHCP_RANGE);
      REGISTER_CONSTANT(VIR_NETWORK_SECTION_FORWARD, SECTION_FORWARD);
      REGISTER_CONSTANT(VIR_NETWORK_SECTION_FORWARD_INTERFACE, SECTION_FORWARD_INTERFACE);
      REGISTER_CONSTANT(VIR_NETWORK_SECTION_FORWARD_PF, SECTION_FORWARD_PF);
      REGISTER_CONSTANT(VIR_NETWORK_SECTION_PORTGROUP, SECTION_PORTGROUP);
      REGISTER_CONSTANT(VIR_NETWORK_SECTION_DNS_HOST, SECTION_DNS_HOST);
      REGISTER_CONSTANT(VIR_NETWORK_SECTION_DNS_TXT, SECTION_DNS_TXT);
      REGISTER_CONSTANT(VIR_NETWORK_SECTION_DNS_SRV, SECTION_DNS_SRV);

      REGISTER_CONSTANT(VIR_NETWORK_UPDATE_AFFECT_CURRENT, UPDATE_AFFECT_CURRENT);
      REGISTER_CONSTANT(VIR_NETWORK_UPDATE_AFFECT_LIVE, UPDATE_AFFECT_LIVE);
      REGISTER_CONSTANT(VIR_NETWORK_UPDATE_AFFECT_CONFIG, UPDATE_AFFECT_CONFIG);

      REGISTER_CONSTANT(VIR_CONNECT_LIST_NETWORKS_ACTIVE, LIST_ACTIVE);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_NETWORKS_INACTIVE, LIST_INACTIVE);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_NETWORKS_AUTOSTART, LIST_AUTOSTART);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_NETWORKS_NO_AUTOSTART, LIST_NO_AUTOSTART);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_NETWORKS_PERSISTENT, LIST_PERSISTENT);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_NETWORKS_TRANSIENT, LIST_TRANSIENT);

      REGISTER_CONSTANT(VIR_NETWORK_EVENT_ID_LIFECYCLE, EVENT_ID_LIFECYCLE);

      REGISTER_CONSTANT(VIR_NETWORK_EVENT_DEFINED, EVENT_DEFINED);
      REGISTER_CONSTANT(VIR_NETWORK_EVENT_UNDEFINED, EVENT_UNDEFINED);
      REGISTER_CONSTANT(VIR_NETWORK_EVENT_STARTED, EVENT_STARTED);
      REGISTER_CONSTANT(VIR_NETWORK_EVENT_STOPPED, EVENT_STOPPED);


      stash = gv_stashpv( "Sys::Virt::Interface", TRUE );
      REGISTER_CONSTANT(VIR_INTERFACE_XML_INACTIVE, XML_INACTIVE);

      REGISTER_CONSTANT(VIR_CONNECT_LIST_INTERFACES_ACTIVE, LIST_ACTIVE);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_INTERFACES_INACTIVE, LIST_INACTIVE);


      stash = gv_stashpv( "Sys::Virt::NodeDevice", TRUE );

      REGISTER_CONSTANT(VIR_CONNECT_LIST_NODE_DEVICES_CAP_SYSTEM, LIST_CAP_SYSTEM);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_NODE_DEVICES_CAP_PCI_DEV, LIST_CAP_PCI_DEV);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_NODE_DEVICES_CAP_USB_DEV, LIST_CAP_USB_DEV);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_NODE_DEVICES_CAP_USB_INTERFACE, LIST_CAP_USB_INTERFACE);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_NODE_DEVICES_CAP_NET, LIST_CAP_NET);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_NODE_DEVICES_CAP_SCSI_HOST, LIST_CAP_SCSI_HOST);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_NODE_DEVICES_CAP_SCSI_TARGET, LIST_CAP_SCSI_TARGET);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_NODE_DEVICES_CAP_SCSI, LIST_CAP_SCSI);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_NODE_DEVICES_CAP_STORAGE, LIST_CAP_STORAGE);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_NODE_DEVICES_CAP_FC_HOST, LIST_CAP_FC_HOST);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_NODE_DEVICES_CAP_VPORTS, LIST_CAP_VPORTS);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_NODE_DEVICES_CAP_SCSI_GENERIC, LIST_CAP_SCSI_GENERIC);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_NODE_DEVICES_CAP_DRM, LIST_CAP_DRM);

      REGISTER_CONSTANT(VIR_NODE_DEVICE_EVENT_ID_LIFECYCLE, EVENT_ID_LIFECYCLE);
      REGISTER_CONSTANT(VIR_NODE_DEVICE_EVENT_ID_UPDATE, EVENT_ID_UPDATE);

      REGISTER_CONSTANT(VIR_NODE_DEVICE_EVENT_CREATED, EVENT_CREATED);
      REGISTER_CONSTANT(VIR_NODE_DEVICE_EVENT_DELETED, EVENT_DELETED);


      stash = gv_stashpv( "Sys::Virt::StorageVol", TRUE );
      REGISTER_CONSTANT(VIR_STORAGE_VOL_FILE, TYPE_FILE);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_BLOCK, TYPE_BLOCK);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_DIR, TYPE_DIR);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_NETWORK, TYPE_NETWORK);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_NETDIR, TYPE_NETDIR);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_PLOOP, TYPE_PLOOP);

      REGISTER_CONSTANT(VIR_STORAGE_VOL_DELETE_NORMAL, DELETE_NORMAL);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_DELETE_ZEROED, DELETE_ZEROED);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_DELETE_WITH_SNAPSHOTS, DELETE_WITH_SNAPSHOTS);


      REGISTER_CONSTANT(VIR_STORAGE_VOL_WIPE_ALG_ZERO, WIPE_ALG_ZERO);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_WIPE_ALG_NNSA, WIPE_ALG_NNSA);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_WIPE_ALG_DOD, WIPE_ALG_DOD);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_WIPE_ALG_BSI, WIPE_ALG_BSI);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_WIPE_ALG_GUTMANN, WIPE_ALG_GUTMANN);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_WIPE_ALG_SCHNEIER, WIPE_ALG_SCHNEIER);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_WIPE_ALG_PFITZNER7, WIPE_ALG_PFITZNER7);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_WIPE_ALG_PFITZNER33, WIPE_ALG_PFITZNER33);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_WIPE_ALG_RANDOM, WIPE_ALG_RANDOM);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_WIPE_ALG_TRIM, WIPE_ALG_TRIM);

      REGISTER_CONSTANT(VIR_STORAGE_VOL_RESIZE_ALLOCATE, RESIZE_ALLOCATE);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_RESIZE_DELTA, RESIZE_DELTA);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_RESIZE_SHRINK, RESIZE_SHRINK);

      REGISTER_CONSTANT(VIR_STORAGE_VOL_CREATE_PREALLOC_METADATA, CREATE_PREALLOC_METADATA);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_CREATE_REFLINK, CREATE_REFLINK);

      REGISTER_CONSTANT(VIR_STORAGE_VOL_USE_ALLOCATION, USE_ALLOCATION);
      REGISTER_CONSTANT(VIR_STORAGE_VOL_GET_PHYSICAL, GET_PHYSICAL);

      stash = gv_stashpv( "Sys::Virt::Secret", TRUE );
      REGISTER_CONSTANT(VIR_SECRET_USAGE_TYPE_NONE, USAGE_TYPE_NONE);
      REGISTER_CONSTANT(VIR_SECRET_USAGE_TYPE_VOLUME, USAGE_TYPE_VOLUME);
      REGISTER_CONSTANT(VIR_SECRET_USAGE_TYPE_CEPH, USAGE_TYPE_CEPH);
      REGISTER_CONSTANT(VIR_SECRET_USAGE_TYPE_ISCSI, USAGE_TYPE_ISCSI);
      REGISTER_CONSTANT(VIR_SECRET_USAGE_TYPE_TLS, USAGE_TYPE_TLS);


      REGISTER_CONSTANT(VIR_CONNECT_LIST_SECRETS_EPHEMERAL, LIST_EPHEMERAL);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_SECRETS_NO_EPHEMERAL, LIST_NO_EPHEMERAL);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_SECRETS_PRIVATE, LIST_PRIVATE);
      REGISTER_CONSTANT(VIR_CONNECT_LIST_SECRETS_NO_PRIVATE, LIST_NO_PRIVATE);

      REGISTER_CONSTANT(VIR_SECRET_EVENT_ID_LIFECYCLE, EVENT_ID_LIFECYCLE);
      REGISTER_CONSTANT(VIR_SECRET_EVENT_ID_VALUE_CHANGED, EVENT_ID_VALUE_CHANGED);

      REGISTER_CONSTANT(VIR_SECRET_EVENT_DEFINED, EVENT_DEFINED);
      REGISTER_CONSTANT(VIR_SECRET_EVENT_UNDEFINED, EVENT_UNDEFINED);


      stash = gv_stashpv( "Sys::Virt::Stream", TRUE );
      REGISTER_CONSTANT(VIR_STREAM_NONBLOCK, NONBLOCK);

      REGISTER_CONSTANT(VIR_STREAM_EVENT_READABLE, EVENT_READABLE);
      REGISTER_CONSTANT(VIR_STREAM_EVENT_WRITABLE, EVENT_WRITABLE);
      REGISTER_CONSTANT(VIR_STREAM_EVENT_ERROR, EVENT_ERROR);
      REGISTER_CONSTANT(VIR_STREAM_EVENT_HANGUP, EVENT_HANGUP);



      stash = gv_stashpv( "Sys::Virt::Error", TRUE );

      REGISTER_CONSTANT(VIR_ERR_NONE, LEVEL_NONE);
      REGISTER_CONSTANT(VIR_ERR_WARNING, LEVEL_WARNING);
      REGISTER_CONSTANT(VIR_ERR_ERROR, LEVEL_ERROR);

      REGISTER_CONSTANT(VIR_FROM_NONE, FROM_NONE);
      REGISTER_CONSTANT(VIR_FROM_XEN, FROM_XEN);
      REGISTER_CONSTANT(VIR_FROM_XEND, FROM_XEND);
      REGISTER_CONSTANT(VIR_FROM_XENSTORE, FROM_XENSTORE);
      REGISTER_CONSTANT(VIR_FROM_SEXPR, FROM_SEXPR);
      REGISTER_CONSTANT(VIR_FROM_XML, FROM_XML);
      REGISTER_CONSTANT(VIR_FROM_DOM, FROM_DOM);
      REGISTER_CONSTANT(VIR_FROM_RPC, FROM_RPC);
      REGISTER_CONSTANT(VIR_FROM_PROXY, FROM_PROXY);
      REGISTER_CONSTANT(VIR_FROM_CONF, FROM_CONF);
      REGISTER_CONSTANT(VIR_FROM_QEMU, FROM_QEMU);
      REGISTER_CONSTANT(VIR_FROM_NET, FROM_NET);
      REGISTER_CONSTANT(VIR_FROM_TEST, FROM_TEST);
      REGISTER_CONSTANT(VIR_FROM_REMOTE, FROM_REMOTE);
      REGISTER_CONSTANT(VIR_FROM_OPENVZ, FROM_OPENVZ);
      REGISTER_CONSTANT(VIR_FROM_XENXM, FROM_XENXM);
      REGISTER_CONSTANT(VIR_FROM_STATS_LINUX, FROM_STATS_LINUX);
      REGISTER_CONSTANT(VIR_FROM_LXC, FROM_LXC);
      REGISTER_CONSTANT(VIR_FROM_STORAGE, FROM_STORAGE);
      REGISTER_CONSTANT(VIR_FROM_NETWORK, FROM_NETWORK);
      REGISTER_CONSTANT(VIR_FROM_DOMAIN, FROM_DOMAIN);
      REGISTER_CONSTANT(VIR_FROM_UML, FROM_UML);
      REGISTER_CONSTANT(VIR_FROM_NODEDEV, FROM_NODEDEV);
      REGISTER_CONSTANT(VIR_FROM_XEN_INOTIFY, FROM_XEN_INOTIFY);
      REGISTER_CONSTANT(VIR_FROM_SECURITY, FROM_SECURITY);
      REGISTER_CONSTANT(VIR_FROM_VBOX, FROM_VBOX);
      REGISTER_CONSTANT(VIR_FROM_INTERFACE, FROM_INTERFACE);
      REGISTER_CONSTANT(VIR_FROM_ONE, FROM_ONE);
      REGISTER_CONSTANT(VIR_FROM_ESX, FROM_ESX);
      REGISTER_CONSTANT(VIR_FROM_PHYP, FROM_PHYP);
      REGISTER_CONSTANT(VIR_FROM_SECRET, FROM_SECRET);
      REGISTER_CONSTANT(VIR_FROM_CPU, FROM_CPU);
      REGISTER_CONSTANT(VIR_FROM_XENAPI, FROM_XENAPI);
      REGISTER_CONSTANT(VIR_FROM_NWFILTER, FROM_NWFILTER);
      REGISTER_CONSTANT(VIR_FROM_HOOK, FROM_HOOK);
      REGISTER_CONSTANT(VIR_FROM_DOMAIN_SNAPSHOT, FROM_DOMAIN_SNAPSHOT);
      REGISTER_CONSTANT(VIR_FROM_AUDIT, FROM_AUDIT);
      REGISTER_CONSTANT(VIR_FROM_SYSINFO, FROM_SYSINFO);
      REGISTER_CONSTANT(VIR_FROM_STREAMS, FROM_STREAMS);
      REGISTER_CONSTANT(VIR_FROM_VMWARE, FROM_VMWARE);
      REGISTER_CONSTANT(VIR_FROM_EVENT, FROM_EVENT);
      REGISTER_CONSTANT(VIR_FROM_LIBXL, FROM_LIBXL);
      REGISTER_CONSTANT(VIR_FROM_LOCKING, FROM_LOCKING);
      REGISTER_CONSTANT(VIR_FROM_HYPERV, FROM_HYPERV);
      REGISTER_CONSTANT(VIR_FROM_CAPABILITIES, FROM_CAPABILITIES);
      REGISTER_CONSTANT(VIR_FROM_AUTH, FROM_AUTH);
      REGISTER_CONSTANT(VIR_FROM_URI, FROM_URI);
      REGISTER_CONSTANT(VIR_FROM_DBUS, FROM_DBUS);
      REGISTER_CONSTANT(VIR_FROM_DEVICE, FROM_DEVICE);
      REGISTER_CONSTANT(VIR_FROM_PARALLELS, FROM_PARALLELS);
      REGISTER_CONSTANT(VIR_FROM_SSH, FROM_SSH);
      REGISTER_CONSTANT(VIR_FROM_LOCKSPACE, FROM_LOCKSPACE);
      REGISTER_CONSTANT(VIR_FROM_INITCTL, FROM_INITCTL);
      REGISTER_CONSTANT(VIR_FROM_CGROUP, FROM_CGROUP);
      REGISTER_CONSTANT(VIR_FROM_IDENTITY, FROM_IDENTITY);
      REGISTER_CONSTANT(VIR_FROM_ACCESS, FROM_ACCESS);
      REGISTER_CONSTANT(VIR_FROM_SYSTEMD, FROM_SYSTEMD);
      REGISTER_CONSTANT(VIR_FROM_BHYVE, FROM_BHYVE);
      REGISTER_CONSTANT(VIR_FROM_CRYPTO, FROM_CRYPTO);
      REGISTER_CONSTANT(VIR_FROM_FIREWALL, FROM_FIREWALL);
      REGISTER_CONSTANT(VIR_FROM_POLKIT, FROM_POLKIT);
      REGISTER_CONSTANT(VIR_FROM_THREAD, FROM_THREAD);
      REGISTER_CONSTANT(VIR_FROM_ADMIN, FROM_ADMIN);
      REGISTER_CONSTANT(VIR_FROM_LOGGING, FROM_LOGGING);
      REGISTER_CONSTANT(VIR_FROM_XENXL, FROM_XENXL);
      REGISTER_CONSTANT(VIR_FROM_PERF, FROM_PERF);
      REGISTER_CONSTANT(VIR_FROM_LIBSSH, FROM_LIBSSH);


      REGISTER_CONSTANT(VIR_ERR_OK, ERR_OK);
      REGISTER_CONSTANT(VIR_ERR_INTERNAL_ERROR, ERR_INTERNAL_ERROR);
      REGISTER_CONSTANT(VIR_ERR_NO_MEMORY, ERR_NO_MEMORY);
      REGISTER_CONSTANT(VIR_ERR_NO_SUPPORT, ERR_NO_SUPPORT);
      REGISTER_CONSTANT(VIR_ERR_UNKNOWN_HOST, ERR_UNKNOWN_HOST);
      REGISTER_CONSTANT(VIR_ERR_NO_CONNECT, ERR_NO_CONNECT);
      REGISTER_CONSTANT(VIR_ERR_INVALID_CONN, ERR_INVALID_CONN);
      REGISTER_CONSTANT(VIR_ERR_INVALID_DOMAIN, ERR_INVALID_DOMAIN);
      REGISTER_CONSTANT(VIR_ERR_INVALID_ARG, ERR_INVALID_ARG);
      REGISTER_CONSTANT(VIR_ERR_OPERATION_FAILED, ERR_OPERATION_FAILED);
      REGISTER_CONSTANT(VIR_ERR_GET_FAILED, ERR_GET_FAILED);
      REGISTER_CONSTANT(VIR_ERR_POST_FAILED, ERR_POST_FAILED);
      REGISTER_CONSTANT(VIR_ERR_HTTP_ERROR, ERR_HTTP_ERROR);
      REGISTER_CONSTANT(VIR_ERR_SEXPR_SERIAL, ERR_SEXPR_SERIAL);
      REGISTER_CONSTANT(VIR_ERR_NO_XEN, ERR_NO_XEN);
      REGISTER_CONSTANT(VIR_ERR_XEN_CALL, ERR_XEN_CALL);
      REGISTER_CONSTANT(VIR_ERR_OS_TYPE, ERR_OS_TYPE);
      REGISTER_CONSTANT(VIR_ERR_NO_KERNEL, ERR_NO_KERNEL);
      REGISTER_CONSTANT(VIR_ERR_NO_ROOT, ERR_NO_ROOT);
      REGISTER_CONSTANT(VIR_ERR_NO_SOURCE, ERR_NO_SOURCE);
      REGISTER_CONSTANT(VIR_ERR_NO_TARGET, ERR_NO_TARGET);
      REGISTER_CONSTANT(VIR_ERR_NO_NAME, ERR_NO_NAME);
      REGISTER_CONSTANT(VIR_ERR_NO_OS, ERR_NO_OS);
      REGISTER_CONSTANT(VIR_ERR_NO_DEVICE, ERR_NO_DEVICE);
      REGISTER_CONSTANT(VIR_ERR_NO_XENSTORE, ERR_NO_XENSTORE);
      REGISTER_CONSTANT(VIR_ERR_DRIVER_FULL, ERR_DRIVER_FULL);
      REGISTER_CONSTANT(VIR_ERR_CALL_FAILED, ERR_CALL_FAILED);
      REGISTER_CONSTANT(VIR_ERR_XML_ERROR, ERR_XML_ERROR);
      REGISTER_CONSTANT(VIR_ERR_DOM_EXIST, ERR_DOM_EXIST);
      REGISTER_CONSTANT(VIR_ERR_OPERATION_DENIED, ERR_OPERATIONED_DENIED);
      REGISTER_CONSTANT(VIR_ERR_OPEN_FAILED, ERR_OPEN_FAILED);
      REGISTER_CONSTANT(VIR_ERR_READ_FAILED, ERR_READ_FAILED);
      REGISTER_CONSTANT(VIR_ERR_PARSE_FAILED, ERR_PARSE_FAILED);
      REGISTER_CONSTANT(VIR_ERR_CONF_SYNTAX, ERR_CONF_SYNTAX);
      REGISTER_CONSTANT(VIR_ERR_WRITE_FAILED, ERR_WRITE_FAILED);
      REGISTER_CONSTANT(VIR_ERR_XML_DETAIL, ERR_XML_DETAIL);
      REGISTER_CONSTANT(VIR_ERR_INVALID_NETWORK, ERR_INVALID_NETWORK);
      REGISTER_CONSTANT(VIR_ERR_NETWORK_EXIST, ERR_NETWORK_EXIST);
      REGISTER_CONSTANT(VIR_ERR_SYSTEM_ERROR, ERR_SYSTEM_ERROR);
      REGISTER_CONSTANT(VIR_ERR_RPC, ERR_RPC);
      REGISTER_CONSTANT(VIR_ERR_GNUTLS_ERROR, ERR_GNUTLS_ERROR);
      REGISTER_CONSTANT(VIR_WAR_NO_NETWORK, WAR_NO_NETWORK);
      REGISTER_CONSTANT(VIR_ERR_NO_DOMAIN, ERR_NO_DOMAIN);
      REGISTER_CONSTANT(VIR_ERR_NO_NETWORK, ERR_NO_NETWORK);
      REGISTER_CONSTANT(VIR_ERR_INVALID_MAC, ERR_INVALID_MAC);
      REGISTER_CONSTANT(VIR_ERR_AUTH_FAILED, ERR_AUTH_FAILED);
      REGISTER_CONSTANT(VIR_ERR_INVALID_STORAGE_POOL, ERR_INVALID_STORAGE_POOL);
      REGISTER_CONSTANT(VIR_ERR_INVALID_STORAGE_VOL, ERR_INVALID_STORAGE_VOL);
      REGISTER_CONSTANT(VIR_WAR_NO_STORAGE, WAR_NO_STORAGE);
      REGISTER_CONSTANT(VIR_ERR_NO_STORAGE_POOL, ERR_NO_STORAGE_POOL);
      REGISTER_CONSTANT(VIR_ERR_NO_STORAGE_VOL, ERR_NO_STORAGE_VOL);
      REGISTER_CONSTANT(VIR_WAR_NO_NODE, WAR_NO_NODE);
      REGISTER_CONSTANT(VIR_ERR_INVALID_NODE_DEVICE, ERR_INVALID_NODE_DEVICE);
      REGISTER_CONSTANT(VIR_ERR_NO_NODE_DEVICE, ERR_NO_NODE_DEVICE);
      REGISTER_CONSTANT(VIR_ERR_NO_SECURITY_MODEL, ERR_NO_SECURITY_MODEL);
      REGISTER_CONSTANT(VIR_ERR_OPERATION_INVALID, ERR_OPERATION_INVALID);
      REGISTER_CONSTANT(VIR_WAR_NO_INTERFACE, WAR_NO_INTERFACE);
      REGISTER_CONSTANT(VIR_ERR_NO_INTERFACE, ERR_NO_INTERFACE);
      REGISTER_CONSTANT(VIR_ERR_INVALID_INTERFACE, ERR_INVALID_INTERFACE);
      REGISTER_CONSTANT(VIR_ERR_MULTIPLE_INTERFACES, ERR_MULTIPLE_INTERFACES);
      REGISTER_CONSTANT(VIR_WAR_NO_NWFILTER, WAR_NO_NWFILTER);
      REGISTER_CONSTANT(VIR_ERR_INVALID_NWFILTER, ERR_INVALID_NWFILTER);
      REGISTER_CONSTANT(VIR_ERR_NO_NWFILTER, ERR_NO_NWFILTER);
      REGISTER_CONSTANT(VIR_ERR_BUILD_FIREWALL, ERR_BUILD_FIREWALL);
      REGISTER_CONSTANT(VIR_WAR_NO_SECRET, WAR_NO_SECRET);
      REGISTER_CONSTANT(VIR_ERR_INVALID_SECRET, ERR_INVALID_SECRET);
      REGISTER_CONSTANT(VIR_ERR_NO_SECRET, ERR_NO_SECRET);
      REGISTER_CONSTANT(VIR_ERR_CONFIG_UNSUPPORTED, ERR_CONFIG_UNSUPPORTED);
      REGISTER_CONSTANT(VIR_ERR_OPERATION_TIMEOUT, ERR_OPERATION_TIMEOUT);
      REGISTER_CONSTANT(VIR_ERR_MIGRATE_PERSIST_FAILED, ERR_MIGRATE_PERSIST_FAILED);
      REGISTER_CONSTANT(VIR_ERR_HOOK_SCRIPT_FAILED, ERR_HOOK_SCRIPT_FAILED);
      REGISTER_CONSTANT(VIR_ERR_INVALID_DOMAIN_SNAPSHOT, ERR_INVALID_DOMAIN_SNAPSHOT);
      REGISTER_CONSTANT(VIR_ERR_NO_DOMAIN_SNAPSHOT, ERR_NO_DOMAIN_SNAPSHOT);
      REGISTER_CONSTANT(VIR_ERR_INVALID_STREAM, ERR_INVALID_STREAM);
      REGISTER_CONSTANT(VIR_ERR_ARGUMENT_UNSUPPORTED, ERR_ARGUMENT_UNSUPPORTED);
      REGISTER_CONSTANT(VIR_ERR_STORAGE_PROBE_FAILED, ERR_STORAGE_PROBE_FAILED);
      REGISTER_CONSTANT(VIR_ERR_STORAGE_POOL_BUILT, ERR_STORAGE_POOL_BUILT);
      REGISTER_CONSTANT(VIR_ERR_SNAPSHOT_REVERT_RISKY, ERR_SNAPSHOT_REVERT_RISKY);
      REGISTER_CONSTANT(VIR_ERR_OPERATION_ABORTED, ERR_OPERATION_ABORTED);
      REGISTER_CONSTANT(VIR_ERR_AUTH_CANCELLED, ERR_AUTH_CANCELLED);
      REGISTER_CONSTANT(VIR_ERR_NO_DOMAIN_METADATA, ERR_NO_DOMAIN_METADATA);
      REGISTER_CONSTANT(VIR_ERR_MIGRATE_UNSAFE, ERR_MIGRATE_UNSAFE);
      REGISTER_CONSTANT(VIR_ERR_OVERFLOW, ERR_OVERFLOW);
      REGISTER_CONSTANT(VIR_ERR_BLOCK_COPY_ACTIVE, ERR_BLOCK_COPY_ACTIVE);
      REGISTER_CONSTANT(VIR_ERR_AGENT_UNRESPONSIVE, ERR_AGENT_UNRESPONSIVE);
      REGISTER_CONSTANT(VIR_ERR_OPERATION_UNSUPPORTED, ERR_OPERATION_UNSUPPORTED);
      REGISTER_CONSTANT(VIR_ERR_SSH, ERR_SSH);
      REGISTER_CONSTANT(VIR_ERR_RESOURCE_BUSY, ERR_RESOURCE_BUSY);
      REGISTER_CONSTANT(VIR_ERR_ACCESS_DENIED, ERR_ACCESS_DENIED);
      REGISTER_CONSTANT(VIR_ERR_DBUS_SERVICE, ERR_DBUS_SERVICE);
      REGISTER_CONSTANT(VIR_ERR_STORAGE_VOL_EXIST, ERR_STORAGE_VOL_EXIST);
      REGISTER_CONSTANT(VIR_ERR_CPU_INCOMPATIBLE, ERR_CPU_INCOMPATIBLE);
      REGISTER_CONSTANT(VIR_ERR_XML_INVALID_SCHEMA, ERR_INVALID_SCHEMA);
      REGISTER_CONSTANT(VIR_ERR_MIGRATE_FINISH_OK, ERR_MIGRATE_FINISH_OK);
      REGISTER_CONSTANT(VIR_ERR_AUTH_UNAVAILABLE, ERR_AUTH_UNAVAILABLE);
      REGISTER_CONSTANT(VIR_ERR_NO_SERVER, ERR_NO_SERVER);
      REGISTER_CONSTANT(VIR_ERR_NO_CLIENT, ERR_NO_CLIENT);
      REGISTER_CONSTANT(VIR_ERR_AGENT_UNSYNCED, ERR_AGENT_UNSYNCED);
      REGISTER_CONSTANT(VIR_ERR_LIBSSH, ERR_LIBSSH);
    }
