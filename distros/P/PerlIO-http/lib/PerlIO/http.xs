#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perliol.h"

#ifndef ETIMEDOUT
#define ETIMEDOUT EIO
#endif

static IV PerlIOHttp_pushed(pTHX_ PerlIO *f, const char *mode, SV *arg, PerlIO_funcs *tab) {
	if (!PerlIOValid(f)) {
		SETERRNO(EBADF, SS_IVCHAN);
	}
	else {
		SETERRNO(EINVAL, LIB_INVARG);
		if (ckWARN(WARN_LAYER))
			Perl_warn(aTHX_ "Can't push :http on existing handle");
	}
	return -1;
}

SV* S_get_tiny(pTHX_ size_t narg, SV** args) {
	int i, cnt;
	SV* ret;
	dSP;

	ENTER;
	PUSHMARK(SP);
	PUSHMARK(SP);
	EXTEND(SP, 1);
	mPUSHp("HTTP::Tiny", 10);
	PUTBACK;
	cnt = call_method("new", G_SCALAR | G_EVAL);
	if (!cnt)
		return NULL;
	SPAGAIN;
	EXTEND(SP, narg);
	for (i = 0; i < narg; ++i)
		PUSHs(args[i]);
	PUTBACK;
	call_method("get", G_SCALAR | G_EVAL);
	if (!cnt)
		return NULL;
	SPAGAIN;
	ret = POPs;
	LEAVE;
	return ret;
}
#define get_tiny(narg, args) S_get_tiny(aTHX_ narg, args)

static PerlIO* PerlIOHttp_open(pTHX_ PerlIO_funcs *self, PerlIO_list_t *layers, IV n, const char *mode, int fd, int imode, int perm, PerlIO *old, int narg, SV **args) {
	SV *tiny;
	if (narg < 1) {
		SETERRNO(EINVAL, LIB_INVARG);
		return NULL;
	}
	if (mode[0] != 'r' || strchr(mode + 1, '+')) {
		if (ckWARN(WARN_IO))
			Perl_warn(aTHX_ "Only reading is supported for HTTP");
		SETERRNO(EINVAL, LIB_INVARG);
		return NULL;
	}
	tiny = get_tiny(narg, args);
	if (!tiny) {
		errno = EIO;
		return NULL;
	}
	if (SvTRUE(*hv_fetchs((HV*)SvRV(tiny), "success", 0))) {
		SV* content = sv_2mortal(newRV_inc(*hv_fetchs((HV*)SvRV(tiny), "content", 0)));
		PerlIO* ret = PerlIO_allocate(aTHX);
		PerlIO_funcs * vtable = PerlIO_find_layer(aTHX, "scalar", 6, TRUE);
		PerlIO_push(aTHX_ ret, vtable, mode, content);
		return ret;
	}
	else {
		switch (SvIV(*hv_fetchs((HV*)SvRV(tiny), "status", 0))) {
			case 404:
			case 410:
				SETERRNO(ENOENT,RMS_FNF);
				break;
			case 401:
			case 402:
			case 403:
			case 405:
			case 407:
			case 511:
				SETERRNO(EACCES,RMS_PRV);
				break;
			case 400:
			case 406:
				SETERRNO(EINVAL, LIB_INVARG);
				break;
			case 408:
			case 598:
				errno = ETIMEDOUT;
				break;
			case 599:
				if (ckWARN(WARN_IO))
					Perl_warn(aTHX_ "%s", SvPV_nolen(*hv_fetchs((HV*)SvRV(tiny), "content", 0)));
				/* fallthrough */
			case 500:
			default:
				errno = EIO;
				break;
		}
		return NULL;
	}
}

const PerlIO_funcs PerlIO_http = {
	sizeof(PerlIO_funcs),
	"http",
	0,
	PERLIO_K_MULTIARG,
	PerlIOHttp_pushed,
	NULL,
	PerlIOHttp_open,
};

MODULE = PerlIO::http				PACKAGE = PerlIO::http

BOOT:
	PUSHSTACKi(PERLSI_MAGIC);
	load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("HTTP::Tiny"), NULL, NULL);
	PerlIO_define_layer(aTHX_ (PerlIO_funcs*)&PerlIO_http);
	POPSTACK;
