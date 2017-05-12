#ifndef PERLIO_UTIL_H
#define PERLIO_UTIL_H

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <perliol.h>

#include "ppport.h"

#define LayerFetch(layer, n) ((layer)->array[n].funcs)
#define LayerFetchSafe(layer, n) ( ((n) >= 0 && (n) < (layer)->cur) \
				? (layer)->array[n].funcs : PERLIO_FUNCS_CAST(&PerlIO_unix) )


#define IOLflag(f, flag)     (PerlIOBase((f))->flags & (flag))
#define IOLflag_on(f, flag)  (PerlIOBase((f))->flags |= (flag))
#define IOLflag_off(f, flag) (PerlIOBase((f))->flags &= ~(flag));

PerlIO*
PerlIOTee_teeout(pTHX_ const PerlIO* tee);

#define perlio_inspect(f) PerlIOUtil_inspect(aTHX_ f, 0)
SV*
PerlIOUtil_inspect(pTHX_ PerlIO* f, int level);

PerlIO*
PerlIOUtil_openn(pTHX_ PerlIO_funcs* tab, PerlIO_list_t* layers, IV n,
		const char* mode, int fd, int imode, int perm,
		PerlIO* f, int narg, SV** args);

void
PerlIOUtil_warnif(pTHX_ const U32 category, const char* fmt, ...)
	__attribute__format__(__printf__,pTHX_2,pTHX_3);

IV
PerlIOUtil_useless_pushed(pTHX_ PerlIO* fp, const char* mode, SV* arg,
		PerlIO_funcs* tab);

extern PERLIO_FUNCS_DECL(PerlIO_flock);
extern PERLIO_FUNCS_DECL(PerlIO_creat);
extern PERLIO_FUNCS_DECL(PerlIO_excl);
extern PERLIO_FUNCS_DECL(PerlIO_tee);
extern PERLIO_FUNCS_DECL(PerlIO_dir);
extern PERLIO_FUNCS_DECL(PerlIO_reverse);


#endif /*PERLIO_UTIL_H*/
