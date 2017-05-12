/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <adns.h>

static HV *adns_query_stash;

static SV *
_obj2sv(pTHX_ void *ptr, SV * klass, char * ctype) {
    if (ptr) {
	SV *rv;
	SV *sv = newSVpvf("%s(0x%x)", ctype, ptr);
	SV *mgobj = sv_2mortal(newSViv(PTR2IV(ptr)));
	SvREADONLY_on(mgobj);
	sv_magic(sv, mgobj, '~', ctype, 0);
	/* SvREADONLY_on(sv); */
	rv = newRV_noinc(sv);
	if (SvOK(klass)) {
	    HV *stash;
	    if (SvROK(klass))
		stash = SvSTASH(klass);
	    else
		stash = gv_stashsv(klass, 1);
	    
	    sv_bless(rv, stash);
	}
	return rv;
    }
    return &PL_sv_undef;
}

static void *
_sv2obj(pTHX_ SV* self, char * ctype, int required) {
    SV *sv = SvRV(self);
    if (sv) {
        if (SvTYPE(sv) == SVt_PVMG || SvTYPE(sv) == SVt_PVHV) {
            MAGIC *mg = mg_find(sv, '~');
            if (mg) {
                if (strcmp(ctype, mg->mg_ptr) == 0 && mg->mg_obj) {
                    return INT2PTR(void *, SvIV(mg->mg_obj));
                }
            }
        }
    }
    if (required) {
        Perl_croak(aTHX_ "object of class %s expected", ctype);
    }
    return NULL;
}

static SV *
_adns_status2sv(pTHX_ adns_status status) {
    SV *sv = newSVpv(adns_strerror(status), 0);
    SvUPGRADE(sv, SVt_PVIV);
    SvIOK_on(sv);
    SvIV_set(sv, status);
    return sv;
}

static SV *
_fd_set2sv(pTHX_ fd_set *set, int maxfd) {
    int len = (maxfd + 7) >> 3;
    SV *sv = newSV(len);
    char *pv;
    int i;

    SvPOK_on(sv);
    SvCUR_set(sv, len);
    pv = SvPVX(sv);
    if (len) {
        pv[len-1] = 0;
        pv[len] = 0;
    }
    for (i = 0; i < maxfd; i++) {
        if (FD_ISSET(i, set))
            pv[i>>3] |= (1 << (i & 7));
    }
    return sv;
}

static SV *
_sv2fd_set(pTHX_ SV *sv, fd_set *set, int *maxfd) {
    FD_ZERO(set);
    if (SvOK(sv)) {
        STRLEN len;
        char *pv = SvPV(sv, len);
        int i;
        for (i = 0; i < (len >> 8); i++) {
            if (pv[i<<3] & (1 << (i & 7))) {
                if (i > *maxfd)
                    *maxfd = i;
                FD_SET(i, set);
            }
        }
    }
}

static SV*
make_sv_query(pTHX) {
    HV *hv = newHV();
    return newRV_noinc((SV *)hv);
}

static int
init_sv_query(pTHX_ SV *sv, adns_query query, const char *owner, adns_rrtype type) {
    HV *hv;
    const char *type_pv, *format_pv;
    
    assert(SvROK(sv));
    hv = (HV*)SvRV(sv);
    if (!(errno = adns_rr_info(type, &type_pv, &format_pv, 0, 0, 0))) {
        if (owner)
            hv_store(hv, "owner", 5, newSVpv(owner, 0), 0);
        if (format_pv)
            hv_store(hv, "format", 6, newSVpv(format_pv, 0), 0);
        if (type_pv) {
            SV *type_sv = newSVpv(type_pv, 0);
            SvUPGRADE(type_sv, SVt_PVIV);
            SvIOK_on(type_sv);
            SvIV_set(type_sv, type & adns_rrt_typemask);
            hv_store(hv, "type", 4,  type_sv, 0);
        }
        if (query) {
            SV *mgobj = sv_2mortal(newSViv(PTR2IV(query)));
            SvREADONLY_on(mgobj);
            sv_magic((SV*)hv, mgobj, '~', "adns_query", 0);
            sv_bless(sv, adns_query_stash);
        }
    }
    return errno;
}

static int
answer_sv_query(pTHX_ SV *sv, adns_answer *answer) {
    HV *hv;
    const char *type_pv, *format_pv;
    int len;
    
    assert(answer);
    assert(SvROK(sv));
    hv = (HV*)SvRV(sv);
    sv_unmagic((SV*)hv, '~');
    
    hv_store(hv, "status", 6, _adns_status2sv(aTHX_ answer->status), 0);

    if (answer->cname)
        hv_store(hv, "cname", 5, newSVpv(answer->cname, 0), 0);

    if (answer->owner)
        hv_store(hv, "owner", 5, newSVpv(answer->owner, 0), 0);

    if (!(errno = adns_rr_info(answer->type, &type_pv, &format_pv, &len, 0, 0))) {
        if (format_pv)
            hv_store(hv, "format", 6, newSVpv(format_pv, 0), 0);

        if (type_pv) {
            SV *type_sv = newSVpv(type_pv, 0);
            SvUPGRADE(type_sv, SVt_PVIV);
            SvIOK_on(type_sv);
            SvIV_set(type_sv, answer->type & adns_rrt_typemask);
            hv_store(hv, "type", 4,  type_sv, 0);
        }

        if (format_pv)
            hv_store(hv, "format", 6, newSVpv(format_pv, 0), 0);

        if (answer->nrrs) {
            char *show;
            int ri;
            
            int i;
            AV *rr;
            
            rr = newAV();
            hv_store(hv, "records", 7, newRV_noinc((SV*)rr), 0);
            
            for (i=0; i<answer->nrrs; i++) {
                if (errno = adns_rr_info(answer->type, 0, 0, 0,
                                         answer->rrs.bytes + i * len, &show))
                    break;

                av_push(rr, newSVpv(show, 0));
                free(show);
            }
        }
    }
    return errno;
}

MODULE = Net::ADNS		PACKAGE = Net::ADNS		PREFIX = adns_
PROTOTYPES: DISABLE

BOOT:
adns_query_stash = gv_stashsv(newSVpv("Net::ADNS::Query", 0), 1);
#include "constants.h"

adns_state
adns_init(klass, flags=0, config=0)
    SV *klass
    adns_initflags flags
    const char *config
CODE:
    RETVAL = 0;
    if (config) {
        adns_init_strcfg(&RETVAL, flags, 0, config);
    }
    else {
        adns_init(&RETVAL, flags, 0);
    }
OUTPUT:
    RETVAL

SV *
adns_synchronous(self, owner, type, flags=0)
    adns_state self
    const char *owner
    adns_rrtype type
    adns_queryflags flags
PREINIT:
    adns_answer *answer;
CODE:
    RETVAL = &PL_sv_undef;
    if (!(errno = adns_synchronous(self, owner, type, flags, &answer))) {
        SV *sv = make_sv_query(aTHX);
        if (init_sv_query(aTHX_ sv, 0, owner, type) ||
            answer_sv_query(aTHX_ sv, answer)) {
            SvREFCNT_dec(sv);
        }
        else
            RETVAL = sv;
    }
OUTPUT:
    RETVAL

SV *
adns_submit(self, owner, type, flags=0)
    adns_state self
    char *owner
    adns_rrtype type
    adns_queryflags flags
PREINIT:
    adns_query query;
    SV *rv = make_sv_query(aTHX);
CODE:
    RETVAL = &PL_sv_undef;
    if(errno = adns_submit(self, owner, type, flags, rv, &query)) {
        SvREFCNT_dec(rv);
    }
    else {
        if (!init_sv_query(aTHX_ rv, query, owner, type))
            RETVAL = newSVsv(rv);
    }
OUTPUT:
    RETVAL

void
open_queries(self)
    adns_state self
PREINIT:
    int n;
    SV *wrapper;
PPCODE:
    adns_forallqueries_begin(self);
    for ( n = 0;
          adns_forallqueries_next(self, (void**)(&wrapper));
          n++)
        XPUSHs(sv_2mortal(newSVsv(wrapper)));
    XSRETURN(n);

SV *
adns_wait(self, query=0)
    adns_state self
    adns_query query
PREINIT:
    adns_answer *answer = 0;
    SV *query_sv = 0;
    int r;
CODE:
    RETVAL = &PL_sv_undef;
    if (!(errno = adns_wait(self, &query, &answer, (void**)(&query_sv)))) {
        assert(query_sv);
        assert(answer);
        answer_sv_query(aTHX_ query_sv, answer);
        free(answer);
        RETVAL = query_sv;
    }
OUTPUT:
    RETVAL

SV *
adns_check(self, query=0)
    adns_state self
    adns_query query
PREINIT:
    adns_answer *answer = 0;
    SV *query_sv = 0;
    int r;
CODE:
    RETVAL = &PL_sv_undef;
    if (!(errno = adns_check(self, &query, &answer, (void**)(&query_sv)))) {
        assert(query_sv);
        assert(answer);
        answer_sv_query(aTHX_ query_sv, answer);
        free(answer);
        RETVAL = query_sv;
    }
OUTPUT:
    RETVAL

void
adns_cancel(self, query)
    adns_state self
    adns_query query
PREINIT:
    adns_query q;
    SV *wrapper;
CODE:
    adns_forallqueries_begin(self);
    while(q = adns_forallqueries_next(self, (void**)(&wrapper))) {
        if (q == query) {
            sv_2mortal(wrapper);
            break;
        }
    }

void
adns_DESTROY(self)
    adns_state self
PREINIT:
    adns_query q;
    SV *wrapper;
CODE:
    adns_forallqueries_begin(self);
    while(adns_forallqueries_next(self, (void**)(&wrapper))) {
        HV *hv;
        assert(wrapper);
        assert(SvRV(wrapper));
        hv = (HV*)SvRV(wrapper);
        sv_unmagic((SV*)hv, '~');
        sv_2mortal(wrapper);
    }
    adns_finish(self);
    sv_unmagic(SvRV(ST(0)), '~');

SV *
adns_process(self)
    adns_state self
CODE:
    if (!(errno = adns_processany(self)))
        RETVAL = &PL_sv_yes;
    else
        RETVAL = &PL_sv_undef;
OUTPUT:
    RETVAL

SV *
adns_first_timeout(self)
    adns_state self
PREINIT:
    struct timeval *tv_mod = 0;
    struct timeval tv_buf;
    struct timeval now;
CODE:
    gettimeofday(&now, NULL);
    adns_firsttimeout(self, &tv_mod, &tv_buf, now);
    RETVAL = (tv_mod
              ? newSVnv(tv_buf.tv_sec + 1e-6 * tv_buf.tv_usec)
              : &PL_sv_undef);
OUTPUT:
    RETVAL

void
adns_before_select(self)
    adns_state self;
PREINIT:
    fd_set rfds, wfds, efds;
    int maxfd = 0;
    struct timeval *tv_mod = 0;
    struct timeval tv_buf, now;
PPCODE:
    FD_ZERO(&rfds); FD_ZERO(&wfds); FD_ZERO(&efds);
    gettimeofday(&now, NULL);
    adns_beforeselect(self,
                      &maxfd, &rfds, &wfds, &efds,
                      &tv_mod, &tv_buf, &now);
    /* fprintf(stderr, "maxfd: %d\n", maxfd); fflush(stderr); */
    XPUSHs(sv_2mortal(_fd_set2sv(aTHX_ &rfds, maxfd)));
    XPUSHs(sv_2mortal(_fd_set2sv(aTHX_ &wfds, maxfd)));
    XPUSHs(sv_2mortal(_fd_set2sv(aTHX_ &efds, maxfd)));
    if (tv_mod) {
        XPUSHs(sv_2mortal(newSVnv(tv_buf.tv_sec + 1e-6 * tv_buf.tv_usec)));
        XSRETURN(4);
    }
    else
        XSRETURN(3);
 
void
adns_after_select(self, rfds, wfds, efds)
    adns_state self
    SV *rfds
    SV *wfds
    SV *efds
PREINIT:
    int maxfd = 0;
    fd_set r, w, e;
    int i, len;
    char *pv;
    struct timeval now;
CODE:
    gettimeofday(&now, 0);
    _sv2fd_set(aTHX_ rfds, &r, &maxfd);
    _sv2fd_set(aTHX_ wfds, &w, &maxfd);
    _sv2fd_set(aTHX_ efds, &e, &maxfd);
    adns_afterselect(self, maxfd, &r, &w, &e, &now);

