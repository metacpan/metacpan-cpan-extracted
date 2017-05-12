/* missing functions copied from perlio.c */

#include "perlioutil.h"

#if defined(WIN32)

PerlIO_funcs *
PerlIO_find_layer(pTHX_ const char *name, STRLEN len, int load)
{
    dVAR;
    IV i;
    if ((SSize_t) len <= 0)
	len = strlen(name);
    for (i = 0; i < PL_known_layers->cur; i++) {
	PerlIO_funcs * const f = PL_known_layers->array[i].funcs;
	if (memEQ(f->name, name, len) && f->name[len] == 0) {
	    PerlIO_debug("%.*s => %p\n", (int) len, name, (void*)f);
	    return f;
	}
    }
    if (load && PL_subname && PL_def_layerlist
	&& PL_def_layerlist->cur >= 2) {
	if (PL_in_load_module) {
	    Perl_croak(aTHX_ "Recursive call to Perl_load_module in PerlIO_find_layer");
	    return NULL;
	} else {
	    SV * const pkgsv = newSVpvs("PerlIO");
	    SV * const layer = newSVpvn(name, len);
	    CV * const cv    = get_cv("PerlIO::Layer::NoWarnings", FALSE);
	    ENTER;
	    SAVEINT(PL_in_load_module);
	    if (cv) {
		SAVEGENERICSV(PL_warnhook);
		PL_warnhook = (SV *) (SvREFCNT_inc_simple_NN(cv));
	    }
	    PL_in_load_module++;
	    /*
	     * The two SVs are magically freed by load_module
	     */
	    Perl_load_module(aTHX_ 0, pkgsv, NULL, layer, NULL);
	    PL_in_load_module--;
	    LEAVE;
	    return PerlIO_find_layer(aTHX_ name, len, 0);
	}
    }
    PerlIO_debug("Cannot find %.*s\n", (int) len, name);
    return NULL;
}


int
PerlIOUnix_oflags(const char *mode)
{
    int oflags = -1;
    if (*mode == IoTYPE_IMPLICIT || *mode == IoTYPE_NUMERIC)
	mode++;
    switch (*mode) {
    case 'r':
	oflags = O_RDONLY;
	if (*++mode == '+') {
	    oflags = O_RDWR;
	    mode++;
	}
	break;

    case 'w':
	oflags = O_CREAT | O_TRUNC;
	if (*++mode == '+') {
	    oflags |= O_RDWR;
	    mode++;
	}
	else
	    oflags |= O_WRONLY;
	break;

    case 'a':
	oflags = O_CREAT | O_APPEND;
	if (*++mode == '+') {
	    oflags |= O_RDWR;
	    mode++;
	}
	else
	    oflags |= O_WRONLY;
	break;
    }
    if (*mode == 'b') {
	oflags |= O_BINARY;
	oflags &= ~O_TEXT;
	mode++;
    }
    else if (*mode == 't') {
	oflags |= O_TEXT;
	oflags &= ~O_BINARY;
	mode++;
    }
    /*
     * Always open in binary mode
     */
    oflags |= O_BINARY;
    if (*mode || oflags == -1) {
	SETERRNO(EINVAL, LIB_INVARG);
	oflags = -1;
    }
    return oflags;
}



#endif /* WIN32 */
