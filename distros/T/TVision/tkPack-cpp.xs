// This 'tkPack.c' is taken from tk unmodified.
// Here we hijack this file on source level, providing it with spoofed tkInt.h,
// so tcl/tk packer thinks it works for tcl/tk, but actually it works for us.

#include "tkPack.c"

#define _NO_TV
#include "TVision.h"

// Override dXSBOOTARGSXSAPIVERCHK, because in 5.40 we don't pass check in
// Perl_xs_handshake(...) or similar.
#define dXSBOOTARGSXSAPIVERCHK dXSARGS
// ... I don't know the reason of the failure, and also I don't know why this step
// is not needed in TVision-methods.xs
// TODO fix this

MODULE=TVision PACKAGE=TVision

int pack(SV *widget, ...)
    CODE:
	// TView *v = sv2tv(a); TBD TODO
	// pack .b -side left
	Tcl_Obj *objv[100];
	objv[0] = sv_2mortal(newSVpv("pack",0)); // tk geometry command
	AV *av = (AV*) SvRV(ST(0));
	SV **sv = av_fetch(av, 2, 0);
	//TODO free this sv!!!!
	objv[1] = *sv; // name of the widget, eg .b
	for (int i=1; i<items; i++) {
	    objv[i+1] = ST(i);
	}
	void *mw=0;
	printf("b4 Tk_PackObjCmd, nam=%s\n", SvPV_nolen(objv[0]));
	if (Tk_PackObjCmd(mw, my_perl, items+1, objv) == TCL_ERROR) {
	    printf("error\n");
	}
	printf("a4 Tk_PackObjCmd\n");
        RETVAL = 5;
    OUTPUT:
	RETVAL

MODULE=TVision_tkpack PACKAGE=TVision

BOOT:
    //printf("in tkPack-boot\n");
