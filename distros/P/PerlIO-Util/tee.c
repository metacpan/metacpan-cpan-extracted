/*
	:tee - write to files.

	Usage: open(my $out, '>>:tee', \*STDOUT, \*SOCKET, $file, \$scalar)
	       $out->push_layer(tee => $another);
*/

#include "perlioutil.h"

#define TeeOut(f) (PerlIOSelf(f, PerlIOTee)->out)
#define TeeArg(f) (PerlIOSelf(f, PerlIOTee)->arg)

/* copied from perlio.c */
static PerlIO_funcs *
PerlIO_layer_from_ref(pTHX_ SV* const sv)
{
    dVAR;
    /*
     * For any scalar type load the handler which is bundled with perl
     */
    if (SvTYPE(sv) < SVt_PVAV) {
	PerlIO_funcs *f = PerlIO_find_layer(aTHX_ STR_WITH_LEN("scalar"), 1);
	/* This isn't supposed to happen, since PerlIO::scalar is core,
	 * but could happen anyway in smaller installs or with PAR */
	if (!f)
	    PerlIOUtil_warnif(aTHX_ packWARN(WARN_LAYER), "Unknown PerlIO layer \"scalar\"");
	return f;
    }

    /*
     * For other types allow if layer is known but don't try and load it
     */
    switch (SvTYPE(sv)) {
    case SVt_PVAV:
	return PerlIO_find_layer(aTHX_ STR_WITH_LEN("Array"), 0);
    case SVt_PVHV:
	return PerlIO_find_layer(aTHX_ STR_WITH_LEN("Hash"), 0);
    case SVt_PVCV:
	return PerlIO_find_layer(aTHX_ STR_WITH_LEN("Code"), 0);
    case SVt_PVGV:
	return PerlIO_find_layer(aTHX_ STR_WITH_LEN("Glob"), 0);
    default:
	return NULL;
    }
} /* PerlIO_layer_from_ref() */

static PerlIO*
PerlIO_dup(pTHX_ PerlIO* newfp, PerlIO* const oldfp, CLONE_PARAMS* const params, int const flags){
	if(PerlIOValid(oldfp)){
		PerlIO* (*my_dup)(pTHX_ PerlIO*, PerlIO*, CLONE_PARAMS*, int);

		my_dup = PerlIOBase(oldfp)->tab->Dup;

		if(!newfp)	newfp  = PerlIO_allocate(aTHX);
		if(!my_dup)	my_dup = PerlIOBase_dup;

		return my_dup(aTHX_ newfp, oldfp, params, flags);
	}

	SETERRNO(EBADF, SS_IVCHAN);
	return NULL;
}

typedef struct {
	struct _PerlIO base; /* virtual table and flags */

	SV* arg;

	PerlIO* out;
} PerlIOTee;


static PerlIO*
PerlIOTee_open(pTHX_ PerlIO_funcs* const self, PerlIO_list_t* const layers, IV const n,
		  const char* const mode, int const fd, int const imode, int const perm,
		  PerlIO* f, int const narg, SV** const args){
	SV* arg;

	if(!(PerlIOUnix_oflags(mode) & O_WRONLY)){ /* cannot open:tee for reading */
		SETERRNO(EINVAL, LIB_INVARG);
		return NULL;
	}

	f = PerlIOUtil_openn(aTHX_ NULL, layers, n, mode,
				fd, imode, perm, f, 1, args);

	if(!f){
		return NULL;
	}

	if(narg > 1){
		int i;
		for(i = 1; i < narg; i++){
			if(!PerlIO_push(aTHX_ f, self, mode, args[i])){
				PerlIO_close(f);
				return NULL;
			}
		}
	}

	arg = PerlIOArg;
	if(arg && SvOK(arg)){
		if(!PerlIO_push(aTHX_ f, self, mode, arg)){
			PerlIO_close(f);
			return NULL;
		}
	}

	return f;
}


static SV*
parse_fname(pTHX_ SV* const arg, const char** const mode){
	STRLEN len;
	const char* pv = SvPV_const(arg, len);

	switch (*pv){
	case '>':
		pv++;
		len--;
		if(*pv == '>'){ /* ">> file" */
			pv++;
			len--;
			*mode = "a";
		}
		else{ /* "> file" */
			*mode = "w";
		}
		while(isSPACE(*pv)){
			pv++;
			len--;
		}
		break;

	case '+':
	case '<':
	case '|':
		return NULL;
	default:
		/* noop */;
	}
	return newSVpvn(pv, len);
}

static IO*
sv_2io_or_null(pTHX_ SV* sv){
	if(SvROK(sv)) sv = SvRV(sv);

	switch(SvTYPE(sv)){
	case SVt_PVGV:
		return GvIO(sv);
	case SVt_PVIO:
		return (IO*)sv;
	default:
		NOOP;
	}
	return NULL;
}

static IV
PerlIOTee_pushed(pTHX_ PerlIO* const f, const char* mode, SV* const arg, PerlIO_funcs* const tab){
	PerlIO* nx;
	IO* io;
	PerlIOTee* const proto = (mode && !arg) ? (PerlIOTee*)(mode) : NULL; /* dup */

	PERL_UNUSED_ARG(tab);

	if(!(PerlIOValid(f) && (nx = PerlIONext(f)) && PerlIOValid(nx))){
		SETERRNO(EBADF, SS_IVCHAN);
		return -1;
	}


	if(!IOLflag(nx, PERLIO_F_CANWRITE)) goto cannot_tee;

	if(arg && !SvOK(arg)){
		SETERRNO(EINVAL, LIB_INVARG);
		return -1;
	}

	if(proto){ /* dup */
		TeeOut(f) = proto->out;
		TeeArg(f) = proto->arg;
	}
	else if((io = sv_2io_or_null(aTHX_ arg))){ /* pushed \*FILEHANDLE */
		if(!( IoOFP(io) && IOLflag(IoOFP(io), PERLIO_F_CANWRITE) )){
			cannot_tee:
			SETERRNO(EBADF, SS_IVCHAN);
			return -1;
		}

		TeeArg(f) = SvREFCNT_inc_simple_NN( arg );
		TeeOut(f) = IoOFP(io);
	}
	else{
		PerlIO_list_t* const layers = PL_def_layerlist;
		PerlIO_funcs* tab = NULL;

		TAINT_IF(SvTAINTED(arg));
		TAINT_PROPER(":tee");

		if(SvPOK(arg) && SvCUR(arg) > 1){
			TeeArg(f) = parse_fname(aTHX_ arg, &mode);
			if(!TeeArg(f)){
				SETERRNO(EINVAL, LIB_INVARG);
				return -1;
			}
		}
		else{
			TeeArg(f) = newSVsv(arg);
		}

		if( SvROK(TeeArg(f)) ){
			tab = PerlIO_layer_from_ref(aTHX_ SvRV(TeeArg(f)));
		}

		if(!mode){
			mode = "w";
		}

		TeeOut(f) = PerlIOUtil_openn(aTHX_ tab, layers,
			layers->cur, mode, -1, 0, 0, NULL, 1, &(TeeArg(f)));

		/*dump_perlio(aTHX_ TeeOut(f), 0);*/
	}
	if(!PerlIOValid(TeeOut(f))){
		return -1; /* failure */
	}

	PerlIOBase(f)->flags = PerlIOBase(nx)->flags;

	IOLflag_on(TeeOut(f),
		PerlIOBase(f)->flags & (PERLIO_F_UTF8 | PERLIO_F_LINEBUF | PERLIO_F_UNBUF));

	return 0;
}

static IV
PerlIOTee_popped(pTHX_ PerlIO* const f){
#if 0
	printf("#popped:%s(my_perl=%p, f=%p) arg=%p(%d), out=%p\n",
		PerlIOBase(f)->tab->name, my_perl, f,
		TeeArg(f), (TeeArg(f) ? (int)SvREFCNT(TeeArg(f)) : 0), TeeOut(f));
#endif

	if(TeeArg(f)){
		if(sv_2io_or_null(aTHX_ TeeArg(f)) == NULL){
			PerlIO_close(TeeOut(f));
		}
		if(SvREFCNT(TeeArg(f)) > 0) /* for 5.8.8 */
			SvREFCNT_dec(TeeArg(f));

	}
	else if(TeeOut(f)){ /* dup()-ed fp */
		PerlIO_close(TeeOut(f));
	}
	return 0;
}

static IV
PerlIOTee_binmode(pTHX_ PerlIO* const f){
	if(!PerlIOValid(f)){
		return -1;
	}

	PerlIOBase_binmode(aTHX_ f); /* remove PERLIO_F_UTF8 */

	PerlIO_binmode(aTHX_ PerlIONext(f), '>', O_BINARY, NULL);

	/* warn("Tee_binmode %s", PerlIOBase(f)->tab->name); */
	/* there is a case where an unknown layer is supplied */
	if( PerlIOBase(f)->tab != &PerlIO_tee ){
#if 0 /* May, 2008 */
		PerlIO* t = PerlIONext(f);
		int n = 0;
		int ok = 0;

		while(PerlIOValid(t)){
			if(PerlIOBase(t)->tab == &PerlIO_tee){
				n++;
				if(PerlIO_binmode(aTHX_ TeeOut(t), '>'/*not used*/,
					O_BINARY, NULL)){
					ok++;
				}
			}

			t = PerlIONext(t);
		}
		return n == ok ? 0 : -1;
#endif
		return 0;
	}

	return PerlIO_binmode(aTHX_ TeeOut(f), '>'/*not used*/,
				O_BINARY, NULL) ? 0 : -1;
}

static SV*
PerlIOTee_getarg(pTHX_ PerlIO* const f, CLONE_PARAMS* const param, int const flags){
	PERL_UNUSED_ARG(flags);

	return PerlIO_sv_dup(aTHX_ TeeArg(f), param);
}

static PerlIO*
PerlIOTee_dup(pTHX_ PerlIO* f, PerlIO* const o, CLONE_PARAMS* const param, int const flags){
#if 0
	printf("#dup:%s (my_perl=%p, f=%p, o=%p, {proto_perl=%p,flags=0x%x}, flags=%d)\n",
		PerlIOBase(o)->tab->name, my_perl, f, o, param->proto_perl,
		(unsigned)param->flags, flags);
#endif

	f = PerlIO_dup(aTHX_ f, PerlIONext(o), param, flags);

	if(f){
		PerlIOTee proto;
#if 0
		IO* io;
		proto.arg = PerlIOTee_getarg(aTHX_ o, param, flags);
		if((io = sv_2io_or_null(aTHX_ proto.arg))){
			proto.out = IoOFP(io);
		}
		else{
			proto.out = PerlIO_fdupopen(aTHX_ TeeOut(o), param, flags);
		}
#else
		if(!SvROK(TeeArg(o))){
			proto.arg = PerlIO_sv_dup(aTHX_ TeeArg(o), param);
			//SvREFCNT_inc_simple_void_NN(proto.arg);
		}
		else{
			proto.arg = NULL;
		}

		proto.out = PerlIO_dup(aTHX_ NULL, TeeOut(o), param, flags);
#endif

#if 0
		printf("# newarg=%p(%d), oldarg=%p(%d)\n",
			proto.arg, (int)(proto.arg ? SvREFCNT(proto.arg) : 0),
			TeeArg(o), (int)(TeeArg(o) ? SvREFCNT(TeeArg(o)) : 0) );
#endif
		f = PerlIO_push(aTHX_ f, PerlIOBase(o)->tab, (const char*)&proto, NULL);
	}

	return f;
}

static SSize_t
PerlIOTee_write(pTHX_ PerlIO* const f, const void* const vbuf, Size_t const count){
	if(PerlIO_write(TeeOut(f), vbuf, count) != (SSize_t)count){
		PerlIOUtil_warnif(aTHX_ packWARN(WARN_IO), "Failed to write to tee-out");
	}

	return PerlIO_write(PerlIONext(f), vbuf, count);
}

static IV
PerlIOTee_flush(pTHX_ PerlIO* const f){
	if(TeeOut(f) && PerlIO_flush(TeeOut(f)) != 0){
		PerlIOUtil_warnif(aTHX_ packWARN(WARN_IO), "Failed to flush tee-out");
	}

	return PerlIO_flush(PerlIONext(f));
}

static IV
PerlIOTee_seek(pTHX_ PerlIO* const f, Off_t const offset, int const whence){
	if(PerlIO_seek(TeeOut(f), offset, whence) != 0){
		PerlIOUtil_warnif(aTHX_ packWARN(WARN_IO), "Failed to seek tee-out");
	}

	return PerlIO_seek(PerlIONext(f), offset, whence);
}

static Off_t
PerlIOTee_tell(pTHX_ PerlIO* const f){
	PerlIO* const nx = PerlIONext(f);

	return PerlIO_tell(nx);
}

PerlIO*
PerlIOTee_teeout(pTHX_ const PerlIO* const f){
	return PerlIOValid(f) ? TeeOut(f) : NULL;
}


PERLIO_FUNCS_DECL(PerlIO_tee) = {
    sizeof(PerlIO_funcs),
    "tee",
    sizeof(PerlIOTee),
    PERLIO_K_BUFFERED | PERLIO_K_RAW | PERLIO_K_MULTIARG,
    PerlIOTee_pushed,
    PerlIOTee_popped,
    PerlIOTee_open,
    PerlIOTee_binmode,
    PerlIOTee_getarg,
    NULL, /* fileno */
    PerlIOTee_dup,
    NULL, /* read */
    NULL, /* unread */
    PerlIOTee_write,
    PerlIOTee_seek,
    PerlIOTee_tell,
    NULL, /* close */
    PerlIOTee_flush,
    NULL, /* fill */
    NULL, /* eof */
    NULL, /* error */
    NULL, /* clearerror */
    NULL, /* setlinebuf */
    NULL, /* get_base */
    NULL, /* bufsiz */
    NULL, /* get_ptr */
    NULL, /* get_cnt */
    NULL, /* set_ptrcnt */
};


