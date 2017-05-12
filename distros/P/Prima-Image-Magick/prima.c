/* $Id: prima.c,v 1.5 2012/08/01 08:11:16 dk Exp $ */
#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "prima.h"
#include <apricot.h>
#include <Image.h>
#include <img_conv.h>

void
read_prima_image_data( SV * input, pim_image * pim)
{
	int want_resample = 0;
	PImage i = ( PImage) gimme_the_mate( input);
	if ( i == NULL) croak("Cannot read Prima::Image data");

	pim-> data      = i-> data;
	pim-> line_size = i-> lineSize;
	pim-> width     = i-> w;
	pim-> height    = i-> h;
	pim-> bpp       = i-> type & imBPP;
	pim-> colors    = i-> palSize;
	pim-> palette   = (unsigned char*) i-> palette;
	pim-> category  = 0; 
	if ( i-> type & imGrayScale)
		pim-> category  |= IS_GRAY;
		want_resample = 1;
	if ( i-> type & imComplexNumber) {
		pim-> category  |= ( pim-> bpp == 16 * sizeof( float)) ? IS_FLOAT : IS_DOUBLE;
		pim-> category  |= IS_COMPLEX;
		want_resample = 1;
	} else if ( i-> type & imRealNumber) {
		pim-> category  |= ( pim-> bpp == 8 * sizeof( float)) ? IS_FLOAT : IS_DOUBLE;
		want_resample = 1;
	}
		
	if ( want_resample) {
		double srcLo = i-> self-> stats(( Handle) i, 0, isRangeLo, 0);
		double srcHi = i-> self-> stats(( Handle) i, 0, isRangeHi, 0);
		double dstHi = 255;
		double dstLo = 0;
	
		if ( srcHi != srcLo ) {
			pim-> resample_coeff_a = (dstHi - dstLo) / ( srcHi - srcLo );
			pim-> resample_coeff_b = (dstLo * srcHi - dstHi * srcLo) / ( srcHi - srcLo );
		} else {
			pim-> resample_coeff_a = 1.0;
			pim-> resample_coeff_b = 0.0;
		}
	}
}


void bytecopy  (pim_image*pim,void *s,void *d,int w) { memcpy          ( d, s, w); }
void bitexp    (pim_image*pim,void *s,void *d,int w) { bc_mono_graybyte( s, d, w, (PRGBColor)(pim->palette)); }
void nibbleexp (pim_image*pim,void *s,void *d,int w) { bc_nibble_graybyte( s, d, w, (PRGBColor)(pim->palette)); }
void bitrgb    (pim_image*pim,void *s,void *d,int w) { bc_mono_rgb     ( s, d, w, (PRGBColor)(pim->palette)); }
void nibblergb (pim_image*pim,void *s,void *d,int w) { bc_nibble_rgb   ( s, d, w, (PRGBColor)(pim->palette)); }
void bytergb   (pim_image*pim,void *s,void *d,int w) { bc_byte_rgb     ( s, d, w, (PRGBColor)(pim->palette)); }

#define RESAMPLE { while (w--) *d++ = *s++ * pim-> resample_coeff_a + pim-> resample_coeff_b + 0.5; }

void shorts(pim_image*pim,Short *s,Byte *d,int w)   RESAMPLE
void longs(pim_image*pim,Long *s,Byte *d,int w)   RESAMPLE
void floats(pim_image*pim,float *s,Byte *d,int w)   RESAMPLE
void doubles(pim_image*pim,double *s,Byte *d,int w) RESAMPLE

BitCopyProc *
get_prima_bitcopy_proc( int category, int bpp_from, int bpp_to )
{
	if ( category & IS_FLOAT) 
		return (BitCopyProc*) floats;
	if ( category & IS_DOUBLE) 
		return (BitCopyProc*) doubles;

	switch( bpp_to) {
	case 24:
		switch ( bpp_from) {
		case 1:
			return bitrgb;
		case 4:
			return nibblergb;
		case 8:
			return bytergb;
		}
		break;
	default:
		switch ( bpp_from) {
		case 1:
			return bitexp;
		case 4:
			return nibbleexp;
		case 16:
			return (BitCopyProc*) shorts;
		case 32:
			return (BitCopyProc*) longs;
		}
	}

	return bytecopy;
}

void
allocate_prima_image( SV * input, int width, int height, int rgb)
{
	PImage i = ( PImage) gimme_the_mate( input);
	if ( i == NULL) croak("Cannot read Prima::Image data");
	i-> self-> create_empty(( Handle) i, width, height, rgb ? imRGB : imByte);
}

void
prima_bootcheck(void)
{
	PRIMA_VERSION_BOOTCHECK;
}

#ifdef __cplusplus
}
#endif
