/*
 * Safe::Hole - make a hole to the original main compartment in the Safe compartment
 * Copyright 1999-2001, Sey Nakajima, All rights reserved.
 * This program is free software under the GPL.
 */
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#define OP_MASK_BUF_SIZE (MAXO + 100)

/* A reference to a dummy string with the real opmask, if any, attached as magic */

static SV* _get_current_opmask() {
    SV *opmask;
    SV *saved_PL_op_mask = NULL;
    opmask = newSVpvn("Opcode Mask",11);
    if ( PL_op_mask ) {
       saved_PL_op_mask = sv_2mortal(newSVpvn(PL_op_mask,OP_MASK_BUF_SIZE));
    }
    sv_magic(opmask,saved_PL_op_mask,'~',"Safe::Hole opmask",17);
    return newRV_noinc(opmask);
}

MODULE = Safe::Hole		PACKAGE = Safe::Hole		

void
_hole_call_sv(stashref, opmask, codesv)
    SV *	stashref
    SV *        opmask
    SV *	codesv
PPCODE:
    /*** This code is copied from Opcode::_safe_call_sv and modified ***/
    GV *gv;
    AV *av;
    SV *saved_PL_op_mask;
    MAGIC *magic;
    I32 j,ac;

    ENTER;

    if ( SvTRUE(opmask)) {
	SAVEVPTR(PL_op_mask);
	if ( SvMAGICAL(opmask) &&
	     (magic = mg_find(opmask, '~')) &&
	      magic->mg_ptr &&
	      !strncmp(magic->mg_ptr,"Safe::Hole opmask",17) ) {	
	    if ( saved_PL_op_mask = magic->mg_obj ) {
		PL_op_mask = SvPVX(saved_PL_op_mask);
	    } else 	{
		PL_op_mask = NULL;
	    }
	} else {
	    croak("Opmask argument lacks suitable 'Safe::Hole opmask' magic");
        }
    }	

    save_aptr(&PL_endav);
    PL_endav = (AV*)sv_2mortal((SV*)newAV()); /* ignore END blocks for now	*/

    save_hptr(&PL_defstash);		/* save current default stack	*/
    save_hptr(&PL_globalstash);		/* save current global stash	*/
    /* the assignment to global defstash changes our sense of 'main'	*/
    if( !SvROK(stashref) || SvTYPE(SvRV(stashref)) != SVt_PVHV )
    	croak("stash reference required");
    PL_defstash = (HV*)SvRV(stashref);
    PL_globalstash = GvHV(gv_fetchpv("CORE::GLOBAL::", GV_ADDWARN, SVt_PVHV));

    /* defstash must itself contain a main:: so we'll add that now	*/
    /* take care with the ref counts (was cause of long standing bug)	*/
    /* XXX I'm still not sure if this is right, GV_ADDWARN should warn!	*/
    gv = gv_fetchpv("main::", GV_ADDWARN, SVt_PVHV);
    sv_free((SV*)GvHV(gv));
    GvHV(gv) = (HV*)SvREFCNT_inc(PL_defstash);
    PUSHMARK(SP);

    perl_call_sv(codesv, GIMME);
    SPAGAIN; /* for the PUTBACK added by xsubpp */
    LEAVE;

SV*
_get_current_opmask()
