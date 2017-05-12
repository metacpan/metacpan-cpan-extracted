/*
	PerlIO-Util/Util.xs
*/

#include "perlioutil.h"

#ifndef gv_stashpvs
#define gv_stashpvs(s, c) gv_stashpvn(s "", sizeof(s)-1, c)
#endif

PerlIO*
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

#define PutFlag(c) do{\
		if(PerlIOBase(f)->flags & (PERLIO_F_##c)){\
			sv_catpvs(sv, " " #c);\
		}\
	}while(0)

SV*
PerlIOUtil_inspect(pTHX_ PerlIO* f, int const level){
	int i;
	SV* const sv = newSVpvs(" ");

	for(i = 0; i < level; i++) sv_catpvs(sv, "  ");

	sv_catpvf(sv, "PerlIO 0x%p\n", f);

	if(!PerlIOValid(f)){
		for(i = 0; i <= level; i++) sv_catpvs(sv, "  ");

		sv_catpvs(sv, "(Invalid filehandle)\n");
	}

	while(PerlIOValid(f)){
		for(i = 0; i <= level; i++) sv_catpv(sv, "  ");

		sv_catpvf(sv, "0x%p:%s(%d)",
			*f, PerlIOBase(f)->tab->name,
			(int)PerlIO_fileno(f));
		PutFlag(EOF);
		PutFlag(CANWRITE);
		PutFlag(CANREAD);
		PutFlag(ERROR);
		PutFlag(TRUNCATE);
		PutFlag(APPEND);
		PutFlag(CRLF);
		PutFlag(UTF8);
		PutFlag(UNBUF);

		PutFlag(WRBUF);
		if(IOLflag(f, PERLIO_F_WRBUF)){
			sv_catpvf(sv, "(%" IVdf "/%" IVdf ")",
				(IV)PerlIO_get_cnt(f),
				(IV)PerlIO_get_bufsiz(f));
		}
		PutFlag(RDBUF);
		if(IOLflag(f, PERLIO_F_RDBUF)){
			sv_catpvf(sv, "(%" IVdf "/%" IVdf ")",
				(IV)PerlIO_get_cnt(f),
				(IV)PerlIO_get_bufsiz(f));
		}

		PutFlag(LINEBUF);
		PutFlag(TEMP);
		PutFlag(OPEN);
		PutFlag(FASTGETS);
		PutFlag(TTY);
		PutFlag(NOTREG);
		sv_catpvs(sv, "\n");

		if( strEQ(PerlIOBase(f)->tab->name, "tee") ){
			PerlIO* const teeout = PerlIOTee_teeout(aTHX_ f);
			SV* const t = PerlIOUtil_inspect(aTHX_ teeout, level+1);

			sv_catsv(sv, t);
			SvREFCNT_dec(t);
		}

		f = PerlIONext(f);
	}

	return sv;
}

void
PerlIOUtil_warnif(pTHX_ U32 const category, const char* const fmt, ...){
	if(ckWARN(category)){
		va_list args;
		va_start(args, fmt);
		vwarner(category, fmt, &args);
		va_end(args);
	}
}

MODULE = PerlIO::Util		PACKAGE = PerlIO::Util		

PROTOTYPES: DISABLE

BOOT:
	PerlIO_define_layer(aTHX_ PERLIO_FUNCS_CAST(&PerlIO_flock));
	PerlIO_define_layer(aTHX_ PERLIO_FUNCS_CAST(&PerlIO_creat));
	PerlIO_define_layer(aTHX_ PERLIO_FUNCS_CAST(&PerlIO_excl));
	PerlIO_define_layer(aTHX_ PERLIO_FUNCS_CAST(&PerlIO_tee));
	PerlIO_define_layer(aTHX_ PERLIO_FUNCS_CAST(&PerlIO_dir));
	PerlIO_define_layer(aTHX_ PERLIO_FUNCS_CAST(&PerlIO_reverse));

void
known_layers(...)
PREINIT:
	const PerlIO_list_t* const layers = PL_known_layers;
	int i;
PPCODE:
	EXTEND(SP, layers->cur);
	for(i = 0; i < layers->cur; i++){
		SV* const name = newSVpv( LayerFetch(layers, i)->name, 0);
		PUSHs( sv_2mortal(name) );
	}
	XSRETURN(layers->cur);

SV*
_gensym_ref(SV* pkg, SV* name)
PREINIT:
	STRLEN len;
	const char* pv;
	GV* const gv = (GV*)newSV(0);
CODE:
	pv = SvPV_const(name, len);
	/* see also pp_rv2gv() in pp.c */
	gv_init(gv, gv_stashsv(pkg, TRUE), pv, len, GV_ADD);
	RETVAL = newRV_noinc((SV*)gv);

	sv_bless(RETVAL, gv_stashpvs("IO::Handle", TRUE));
OUTPUT:
	RETVAL


MODULE = PerlIO::Util		PACKAGE = IO::Handle


#define undef (&PL_sv_undef)

void
push_layer(filehandle, layer, arg = undef)
	PerlIO* filehandle
	SV* layer
	SV* arg
PREINIT:
	PerlIO_funcs* tab;
	const char* laypv;
	STRLEN laylen;
PPCODE:
	laypv = SvPV_const(layer, laylen);
	if(laypv[0] == ':'){ /* ignore a layer prefix */
		laypv++;
		laylen--;
	}
	tab = PerlIO_find_layer(aTHX_ laypv, laylen, TRUE);
	if(tab){
		if(!PerlIO_push(aTHX_ filehandle, tab, NULL, arg)){
			Perl_croak(aTHX_ "push_layer() failed: %s",
				PerlIOValid(filehandle)
					? Strerror(errno)
					: "Invalid filehandle");
		}
	}
	else{
		Perl_croak(aTHX_ "Unknown PerlIO layer \"%.*s\"",
				(int)laylen, laypv);
	}
	XSRETURN(1); /* returns self */

void
pop_layer(filehandle)
	PerlIO* filehandle
PREINIT:
	const char* popped_layer;
PPCODE:
	if(!PerlIOValid(filehandle)) XSRETURN_EMPTY;
	popped_layer = PerlIOBase(filehandle)->tab->name;

	PerlIO_flush(filehandle);
	PerlIO_pop(aTHX_ filehandle);

	if(GIMME_V != G_VOID){
		XSRETURN_PV(popped_layer);
	}

MODULE = PerlIO::Util	PACKAGE = IO::Handle	PREFIX = perlio_


SV*
perlio_inspect(f)
	PerlIO* f
