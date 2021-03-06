/* ====================================================================
 * Copyright (c) 2000-2001 by Soheil Seyfaie. All rights reserved.
 * This program is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 * ====================================================================
 *
 * $Author: soheil $
 * $Id: Gradient.xs,v 1.1 2001/09/24 00:37:41 soheil Exp $
 */


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "SWF.h"
#include "perl_swf.h"


MODULE = SWF::Gradient		PACKAGE = SWF::Gradient		PREFIX = SWFGradient_
PROTOTYPES: ENABLE


SWF::Gradient
SWFGradient_new(package="SWF::Gradient")
	char *package
	CODE:
        RETVAL = newSWFGradient();
        ST(0) = sv_newmortal();
        sv_setref_pv(ST(0), package, (void*)RETVAL);



void
SWFGradient_addEntry(gradient, ratio, r, g, b, a=0xff)
	SWF::Gradient	gradient
	float		ratio
	byte		r
	byte		g
	byte		b
	byte		a

void
destroySWFGradient(gradient)
	SWF::Gradient	gradient
	ALIAS:
        SWF::Gradient::DESTROY = 1
        CODE:
        S_DEBUG(2, fprintf(stderr, "Gradient DESTROY CALLED\n"));
        destroySWFGradient(gradient);

