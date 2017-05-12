/*
	PerlIO::fse - File System Encoding

*/

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <perliol.h>

#include "ppport.h"

#define LayerFetch(layer, n) ((layer)->array[n].funcs)
#define LayerFetchSafe(layer, n) ( ((n) >= 0 && (n) < (layer)->cur) \
				? (layer)->array[n].funcs : PERLIO_FUNCS_CAST(&PerlIO_unix) )


#define DEFAULT_FSE "UTF-8"

#ifdef __CYGWIN__
#include <windows.h>
#endif

static PerlIO*
PerlIOUtil_openn(pTHX_ PerlIO_funcs* const force_tab, PerlIO_list_t* const layers, IV const n,
		const char* const mode, int const fd, int const imode, int const perm,
		PerlIO* f, int const narg, SV** const args){
	PerlIO_funcs* tab = NULL;
	IV i = n;

	while(--i >= 0){ /* find a layer with Open() */
		tab = LayerFetch(layers, i);
		if(tab && tab->Open){
			break;
		}
	}

	if(force_tab) tab = force_tab;

	if(tab && tab->Open){
		f = tab->Open(aTHX_ tab, layers, i,  mode,
				fd, imode, perm, f, narg, args);

		/* apply 'upper' layers
		   e.g. [ :unix :perlio :utf8 :creat ]
		                        ~~~~~        
		*/

		if(f && ++i < n){
			if(PerlIO_apply_layera(aTHX_ f, mode, layers, i, n) != 0){
				PerlIO_close(f);
				f = NULL;
			}
		}

	}
	else{
		SETERRNO(EINVAL, LIB_INVARG);
	}

	return f;
}

static IV
PerlIOUtil_useless_pushed(pTHX_ PerlIO* fp, const char* mode, SV* arg,
		PerlIO_funcs* tab){
	PERL_UNUSED_ARG(fp);
	PERL_UNUSED_ARG(mode);
	PERL_UNUSED_ARG(arg);

	if(ckWARN(WARN_LAYER)){
		Perl_warner(aTHX_ packWARN(WARN_LAYER), "Too late for %s layer", tab->name);
	}

	return -1;
}


static SV*
PerlIOFSE_get_fse(pTHX){
	SV* const fse = get_sv("PerlIO::fse::fse", GV_ADDMULTI);

	if (!SvOK(fse)) {
#if defined(WIN32) || defined(__CYGWIN__)
		unsigned long const codepage = GetACP();
		if(codepage != 0){
			Perl_sv_setpvf(aTHX_ fse, "cp%lu", codepage);
		}
#endif

		if(!PL_tainting){
			const char* const env_fse = PerlEnv_getenv("PERLIO_FSE");
			if(env_fse && *env_fse){
				sv_setpv(fse, env_fse);
			}
		}

		if(!SvOK(fse)){
			sv_setpvs(fse, DEFAULT_FSE);
		}
		PerlIO_debug("PerlIOFSE_initialize: encoding=%" SVf , fse);
	}

	return fse;
}

static SV*
PerlIOFSE_encode(pTHX_ SV* const enc, SV* const str){
	dSP;

	PUSHMARK(SP);
	EXTEND(SP, 2);
	PUSHs(enc);
	PUSHs(str);
	PUTBACK;

	call_pv("Encode::encode", G_SCALAR);

	SPAGAIN;

	return POPs; /* bytes */
}

static PerlIO*
PerlIOFSE_open(pTHX_ PerlIO_funcs* self, PerlIO_list_t* layers, IV n,
		const char* mode, int fd, int imode, int perm,
		PerlIO* f, int narg, SV** args){
	PERL_UNUSED_ARG(self);

	if(SvUTF8(args[0])){
		SV* const arg = PerlIOArg;
		SV* fse;
		SV* save;

		if(arg && SvOK(arg)){
			fse = arg;
		}
		else{
			fse = PerlIOFSE_get_fse(aTHX);
		}

		if(!SvOK(fse)){
			Perl_croak(aTHX_ "fse: encoding not set");
		}

		ENTER;
		SAVETMPS;

		save = args[0];
		args[0] = PerlIOFSE_encode(aTHX_ fse, args[0]);
	
		f = PerlIOUtil_openn(aTHX_ NULL, layers, n,
				mode, fd, imode, perm, f, narg, args);

		args[0] = save;

		FREETMPS;
		LEAVE;

		return f;
	}

	return PerlIOUtil_openn(aTHX_ NULL, layers, n,
			mode, fd, imode, perm, f, narg, args);

}

PERLIO_FUNCS_DECL(PerlIO_fse) = {
	sizeof(PerlIO_funcs),
	"fse",
	0, /* size */
	PERLIO_K_DUMMY, /* kind */
	PerlIOUtil_useless_pushed,
	NULL, /* popped */
	PerlIOFSE_open,
	NULL, /* binmode */
	NULL, /* arg */
	NULL, /* fileno */
	NULL, /* dup */
	NULL, /* read */
	NULL, /* unread */
	NULL, /* write */
	NULL, /* seek */
	NULL, /* tell */
	NULL, /* close */
	NULL, /* flush */
	NULL, /* fill */
	NULL, /* eof */
	NULL, /* error */
	NULL, /* clearerr */
	NULL, /* setlinebuf */
	NULL, /* get_base */
	NULL, /* bufsiz */
	NULL, /* get_ptr */
	NULL, /* get_cnt */
	NULL  /* set_ptrcnt */
};

MODULE = PerlIO::fse	PACKAGE = PerlIO::fse

PROTOTYPES: DISABLE

BOOT:
	PerlIO_define_layer(aTHX_ PERLIO_FUNCS_CAST(&PerlIO_fse));

SV*
get_fse(klass)
CODE:
	RETVAL = PerlIOFSE_get_fse(aTHX);
	SvREFCNT_inc_simple_void_NN(RETVAL);
OUTPUT:
	RETVAL

SV*
set_fse(klass, SV* encoding)
CODE:
	RETVAL = PerlIOFSE_get_fse(aTHX);
	SvREFCNT_inc_simple_void_NN(RETVAL);
	sv_setsv(RETVAL, encoding);
OUTPUT:
	RETVAL
