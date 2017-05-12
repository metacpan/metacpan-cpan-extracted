
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "rx_fields.h"
#include "rx_lend.h"

START_MY_CXT

#ifdef RE_FIELDS_MAGIC
static int 
rx_mg_clear(pTHX_ SV *sv, MAGIC *mg) {
    Perl_croak(aTHX_ PL_no_modify);
    return 1;
}

static int 
rx_mg_copy(pTHX_ SV *sv, MAGIC *mg, SV *nsv, const char *name, int len)
{
    if (!SvANY(nsv))
	SvFLAGS(nsv) |= SVf_READONLY;
    return 1;
}

static MGVTBL rx_mg_vtbl = {
    NULL,	    /* get   */
    NULL,	    /* set   */
    NULL,	    /* len   */
    rx_mg_clear,    /* clear */
    NULL,           /* free  */
    rx_mg_copy      /* copy  */
};

static void
rx_destructor_later(pTHX_ ANY *p)
{
    dMY_CXT;

    SSPUSHANY(p[3]);
    SSPUSHANY(p[2]);
    SSPUSHANY(p[1]);

    GvHV(MY_CXT.match_gv) = (HV*) p[0].any_ptr;
    Safefree(p);
}

typedef struct {
    REGEXP  *rx;
    HV	    *old;
    IV	     ss_ix;
} rx_destructor_args;

static void
rx_destructor_now(pTHX_ rx_destructor_args *args)
{
    if (RxCHECK(args->rx) && 
	RxDATA(args->rx)->flags & RXf_MATCHED)
    {
	ANY *p;
	Newz(1299, p, 4, ANY);

	LEAVE_SCOPE(args->ss_ix);

	p[0].any_ptr = args->old;
	p[1] = SSPOPANY;
	p[2] = SSPOPANY;
	p[3] = SSPOPANY;

	SAVEDESTRUCTOR_X(rx_destructor_later, p);
    }

    Safefree(args);
}
#endif /* RE_FIELDS_MAGIC */

#ifdef RE_FIELDS_LEXICAL
static int 
rx_mg_get(pTHX_ SV *sv, MAGIC *mg) 
{
    REGEXP *rx = INT2PTR(REGEXP*, SvIVX(mg->mg_obj));

    if (!RxCHECK(rx) || (RxHINTMY(rx) && !RxMATCHED(rx)))
	sv_setsv(sv, &PL_sv_undef);
    else {
	REGEXP *save = PM_GETRE(PL_curpm);
	PM_SETRE(PL_curpm, rx);
	Perl_magic_get(aTHX_ sv, mg);
	PM_SETRE(PL_curpm, save);
    }
    return 0;
}

static int 
rx_mg_free(pTHX_ SV *sv, MAGIC *mg) {
    REGEXP *rx = INT2PTR(REGEXP*, SvIVX(mg->mg_obj));

    rx->refcnt--;
    return 1;
}

static MGVTBL rx_mg_elem_vtbl = {
    rx_mg_get,	    /* get   */
    NULL,	    /* set   */
    NULL,	    /* len   */
    NULL,	    /* clear */
    rx_mg_free,	    /* free  */
    NULL	    /* copy  */
};

static void
rx_install_padsv(pTHX_ const char *name, I32 len, SV *sv) 
{
    PADOFFSET offset;
    char buf[256] = { '$' };

    if (len > 250)
	croak("Identifier too long");

    strncpy(buf+1, name, len);
    buf[len+1] = '\0';

#ifdef RX_PAD_ADD_NAME
    pad_check_dup(buf, FALSE, Nullhv);
    offset = pad_add_name(buf, Nullhv, Nullhv, FALSE);
#else
    offset = pad_allocmy(buf);
#endif
    PL_curpad[offset] = sv;
    intro_my();
}

static IV
rx_hint(pTHX) 
{
    HV *hv = GvHVn(PL_hintgv);
    SV **svp = hv_fetch(hv, RE_FIELDS_HINT, strlen(RE_FIELDS_HINT), 0);
    return svp? SvIV(*svp) : 0;
}
#endif /* RE_FIELDS_LEXICAL */

static SV*
rx_digit_var(pTHX_ I32 digit, REGEXP *rx) 
{
    char buf[16];
    STRLEN len = sprintf(buf, "%"UVuf, digit);
    SV *sv;

#ifdef RE_FIELDS_LEXICAL
    sv = newSV(0);
    sv_magicext(sv, sv_2mortal(newSViv((IV) PTR2IV(rx))), '\0',
	        &rx_mg_elem_vtbl, buf, len);
    SvFLAGS(sv) |= (SVs_GMG|SVs_SMG);
    SvREADONLY_on(sv);
    rx->refcnt++;
#else
    sv = GvSV(gv_fetchpv(buf, TRUE, SVt_PV));
    SvREFCNT_inc(sv);
#endif
    return sv;
}

static HV*
rx_get_names(pTHX_ REGEXP *rx, I32 create) 
{
    if (RxCHECK(rx)) {
	MAGIC *mg;
	HV *hv = RxNAMES(rx);
	if (!hv && create) {
	    hv = newHV();
	  #ifdef RE_FIELDS_MAGIC
	    mg = sv_magicext((SV*) hv, Nullsv, 'U', &rx_mg_vtbl, Nullch, 0);
	    mg->mg_flags |= MGf_COPY;
	  #endif
	    RxNAMES(rx) = hv;
	}
	return hv;
    }
    return Nullhv;
}

void
rx_regfree(pTHX_ REGEXP *rx)
{
    if (RxCHECK(rx)) {
	rx_reg_data *data = RxDATA(rx);
	if (!data) 
	    croak("[Regexp::Fields] panic: rx_regfree");
	if (!data->names) {
	    if (rx->refcnt == 1) {
		rx->data->what[0] = 'f';
	    }
	    return;
	}
#ifdef RE_FIELDS_LEXICAL
	if ((rx->refcnt - HvKEYS(data->names)) == 1) {
#else
	if (rx->refcnt == 1) {
#endif
	    SvREFCNT_dec((SV*) data->names);
	    rx->data->what[0] = 'f';
	}
    }
}

#ifdef RE_FIELDS_MAGIC
void 
rx_regexec_start(pTHX_ REGEXP *rx, I32 flags) 
{
    if (RxCHECK(rx) && !(flags & REXEC_NOT_FIRST)) {
	dMY_CXT;
	rx_destructor_args *args;
	IV ix = PL_savestack_ix;

	RxDATA(rx)->flags &= ~RXf_MATCHED;

	/* XXX 
	 * We need to find the base of the PMOP's pseudo-scope.
	 * Currently the only thing that could be in there is
	 * PL_multiline, so... {cross-fingers}
	 */
	if (ix > 1 && PL_savestack[ix-1].any_i32 == SAVEt_INT
		   && PL_savestack[ix-2].any_i32 == PL_multiline)
	    ix -= 3;

	Newz(1299, args, 1, rx_destructor_args);
	args->ss_ix = ix;
	args->rx = rx;
	args->old = GvHV(MY_CXT.match_gv);

	SAVEDESTRUCTOR_X(rx_destructor_now, args);
	GvHV(MY_CXT.match_gv) = rx_get_names(aTHX_ rx, FALSE);
    }
}

void 
rx_regexec_fail(pTHX_ REGEXP *rx, I32 flags) {
    ; /* empty */
}
#endif /* RE_FIELDS_MAGIC */

void 
rx_regexec_match(pTHX_ REGEXP *rx, I32 flags) 
{

#ifdef RE_FIELDS_LEXICAL
    if (RxCHECK(rx))
	RxDATA(rx)->flags |= RXf_MATCHED;
#endif
}

void 
rx_regcomp_start(pTHX_pREXC) 
{
    rx_reg_data *p;
    if (RExC_rx->data)
	croak("rx->data unexpectedly populated");

    Newz(1299, p, 1, rx_reg_data);

    /* from S_add_reg_data: */
    Newc(1299, RExC_rx->data, sizeof(*RExC_rx->data), char, struct reg_data);
    New(1299, RExC_rx->data->what, 1, U8);
    RExC_rx->data->count = 1;
    RExC_rx->data->what[0] = 'x';
    RExC_rx->data->data[0] = p;

#ifdef RE_FIELDS_LEXICAL
    p->flags = rx_hint(aTHX);
#endif

}

void
rx_regcomp_parse(pTHX_ pREXC_ const char *name, I32 len) 
{
    SV *sv;
    HV *hv;

    hv = rx_get_names(aTHX_ RExC_rx, TRUE);

    if (hv_exists(hv, name, len)) {
	Perl_warner(aTHX_ WARN_MISC, 
		    "Field '%.*s' masks earlier declaration in same regex", len, name);
	hv_delete(hv, name, len, 0);
    }

    sv = rx_digit_var(aTHX_ RExC_npar, RExC_rx);
    hv_store(hv, name, len, sv, 0);

#ifdef RE_FIELDS_LEXICAL
    if (RxHINTMY(RExC_rx))
	rx_install_padsv(aTHX_ name, len, SvREFCNT_inc(sv));
#endif
}

void rx_uninstall(pTHX)
{
    PL_regexecp = Perl_regexec_flags;
    PL_regcompp = Perl_pregcomp;
    PL_regint_start = Perl_re_intuit_start;
    PL_regint_string = Perl_re_intuit_string;
    PL_regfree = Perl_pregfree;
}


void rx_install(pTHX) 
{
    PL_regexecp = my_regexec;
    PL_regcompp = my_regcomp;
    PL_regint_start = my_re_intuit_start;
    PL_regint_string = my_re_intuit_string;
    PL_regfree = my_regfree;

}


MODULE = Regexp::Fields  PACKAGE = Regexp::Fields  PREFIX = rx_

PROTOTYPES: DISABLE

BOOT:
{
    MY_CXT_INIT;
#ifdef RE_FIELDS_MAGIC
    /* force initialization of $& (blech) */
    GV *gv = gv_fetchpv("&", TRUE, SVt_PV);
    MAGIC *mg = sv_magicext((SV*) GvHVn(gv), Nullsv, 'U', &rx_mg_vtbl, Nullch, 0);
    mg->mg_flags |= MGf_COPY;
    MY_CXT.match_gv = gv;
#endif
    MY_CXT.empty_hv = newHV();
}

void
rx_RE_FIELDS_MAGIC(...)
PPCODE:
#ifdef RE_FIELDS_MAGIC
    XSRETURN_YES;
#else
    XSRETURN_NO;
#endif

void
rx_uninstall(...)
CODE:
    rx_uninstall(aTHX);

void
rx_install(...)
CODE:
    rx_install(aTHX);

void
rx_curpm_map(...)
ALIAS:
    Regexp::Fields::tie::curpm_map = 1
INIT:
    dMY_CXT;
    REGEXP *rx;
    HV *hv = Nullhv;
PPCODE:
    if (PL_curpm && (rx = PM_GETRE(PL_curpm)))
	hv = rx_get_names(aTHX_ rx, FALSE);
    if (!hv)
	hv = MY_CXT.empty_hv;
    XPUSHs(sv_2mortal(newRV_inc((SV*) hv)));

