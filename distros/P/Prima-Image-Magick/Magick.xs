/* $Id */
#ifdef __cplusplus
extern "C" {
#endif

#if !defined(WIN32)
#define MagickExport
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "prima.h"
#include <magick/MagickCore.h>
#include "mag.h"

#ifdef __cplusplus
}
#endif

MODULE        = Prima::Image::Magick		PACKAGE       = Prima::Image::Magick

BOOT:
{
	prima_bootcheck();
}

void 
convert_to_magick(prima_image,magick_image)
PROTOTYPE: DISABLE
PPCODE:
{
	pim_image pim;
	Image * ip;

	SV * sv;
	AV * av;
	HV * hv;

	ImageInfo *info;
	char sizebuf[64];
	unsigned char * buffer;
	int dst_bpp;
	ColorspaceType colorspace;
	StorageType pixeltype;
	BitCopyProc * bitcopyproc;
	
	/* check if the conversion is possible at all */
	read_prima_image_data( ST(0), &pim);
	dst_bpp  = pim. bpp;
	if ( pim. category & IS_COMPLEX) {
		/* represent a two-band image as a double-width image */
		pim. width *= 2;
		pim. bpp   /= 2;
	}

	/*
	force-convert all float/real/short/long etc pixels into 8-bit
	because even though ImageMagick understands these pixel types, it converts them internally
	to Char anyway, and doesn't normalize them. (note: it didn't convert them before, but something
	changed and it does so now). So we do that job ourselves -- we resample them explicitly to 0-255,
	and convert to 8 bit to avoid mis-interpertattion of non-byte data, in general
	*/

	if ( pim. category & IS_FLOAT) {
		pixeltype  = CharPixel;
		colorspace = GRAYColorspace;
		dst_bpp   = 8; /* force-convert to byte */
	} else if ( pim. category & IS_DOUBLE) {
		pixeltype  = CharPixel;
		colorspace = GRAYColorspace;
		dst_bpp   = 8; /* force-convert to byte */
	} else if ( pim. category & IS_GRAY) {
		if ( 
			pim. bpp != 1 &&
			pim. bpp != 4 &&
			pim. bpp != 8 &&
			pim. bpp != 16 &&
			pim. bpp != 32
		) 
			croak("Cannot convert this image type to magick");
		pixeltype = CharPixel;
		dst_bpp   = 8; /* force-convert to byte */
		colorspace = GRAYColorspace;
	} else if ( pim. bpp == 24) {
		colorspace = RGBColorspace;
		pixeltype = CharPixel;
	} else if ( pim. bpp <= 8) {
		/* force-convert to RGB */
		colorspace = RGBColorspace;
		pixeltype  = CharPixel;
		dst_bpp    = 24;
	} else {
		croak("Cannot convert this image type to magick");
	}

	bitcopyproc = get_prima_bitcopy_proc( pim.category, pim.bpp, dst_bpp );

	/* prepare magick image */
	sv = SvRV( ST( 1));
	if ( SvTYPE( sv) != SVt_PVAV)
		croak("Image::Magick object is not SVt_PVAV");
	hv = ( HV*) SvSTASH( sv);
	av = ( AV*) sv;
	if (( info = AcquireImageInfo()) == NULL)
		croak("cannot AcquireMagickInfo()");
        info-> colorspace = colorspace;
	sprintf( info-> size = sizebuf, "%dx%d", pim. width, pim. height);
	ip = AcquireImage( info);
	info-> size = NULL;
	DestroyImageInfo( info);
	if ( ip == NULL)
		croak("cannot AcquireImage()");

	/* repad and possibly convert */
	{
		int lw = dst_bpp / 8 * pim. width;
		unsigned int y, bw;
		unsigned char * in, * out;
		buffer = ( unsigned char *) malloc( lw * pim. height);
		if ( buffer == NULL) {
			DestroyImage( ip);
			croak("not enough memory (%d bytes)", lw * pim. height);
		}
		/* bzero( buffer, lw * pim. height); */

		if ( bitcopyproc == get_prima_bitcopy_proc( 0, 8, 8)) {
			/* count in bytes for memcpy */
			bw = pim. bpp / 8 * pim. width;
		} else {
			/* count in pixels for other types */
			bw = pim. width;
		}
		
		for ( 
			in = pim. data, y = 0, out = buffer + lw * ( pim. height - 1);
			y < pim. height;
			y++, in += pim. line_size, out -= lw
		)
			bitcopyproc( &pim, in, out, bw);
	}

	/* transfer */
	if ( !ImportImagePixels( 
		ip, 0, 0, 
		pim.width, pim.height, 
		( colorspace == GRAYColorspace) ? "I" : "BGR",
		pixeltype, buffer
	)) {
		free( buffer);
		DestroyImage( ip);
		magick_croak("ImportImagePixels", &ip-> exception);
	}
#if MagickLibVersion > 0x676
	ip->colorspace = colorspace;
#endif
	free( buffer);

	/* store as Image::Magick object */
	sv = newSViv(( IV) ip);
	av_push( av, sv_bless( newRV( sv), hv));
	SvREFCNT_dec( sv);
}

void 
convert_to_prima(magick_image,prima_image)
PROTOTYPE: DISABLE
PPCODE:
{
	Image * ip;
	pim_image pim;
#if MagickLibVersion > 0x676
	ExceptionInfo* exception;
#else
	ExceptionInfo  exception_buf;
	ExceptionInfo* exception = &exception_buf;
#endif
	unsigned char * buffer;

	SV * sv, **ssvv;
	AV * av;
	long n;

	/* get down to imagemagick object */
	sv = SvRV( ST(0));
	if ( SvTYPE( sv) != SVt_PVAV) 
		croak("Image::Magick object is not an array");
	av = ( AV*) sv;
	n = av_len( av);
	switch ( n) {
	case -1:
		croak("Image::Magick object is empty");
	case 0:
		if ( !( ssvv = av_fetch(av,0,0)))
			croak("cannot fetch image from Image::Magick object");
		sv = *ssvv;
		if ( !sv || !sv_isobject(sv) || SvTYPE(SvRV(sv)) != SVt_PVMG)
			croak("Image from Image::Magick object is invalid");
		ip = ( Image *) SvIV( SvRV( sv));
		break;
	default:
		croak("Image::Magick object contains more than one image, unsupported");
	}
	
	/* prepare prima object */
	allocate_prima_image( 
		ST( 1), 
		ip-> columns, 
		ip-> rows, 
		ip-> colorspace == RGBColorspace
	);
	read_prima_image_data( ST( 1), &pim);

	/* read pixels to a temp space */
	if ( !( buffer = malloc(
		pim. line_size * pim. height
	)))
		croak("not enough memory (%d bytes)", pim. line_size * pim. height);
	/* bzero( buffer, pim. line_size * pim. height); */
#if MagickLibVersion > 0x676
	exception = AcquireExceptionInfo();
#else
	GetExceptionInfo( exception);
#endif
	if ( !( ExportImagePixels( 
		ip, 
		0, 0, /* offsets */
		ip-> columns, ip-> rows,
		( ip-> colorspace == RGBColorspace) ? "BGR" : "I",
		CharPixel,
		buffer,
		exception
	))) {
#if MagickLibVersion > 0x676
	exception = DestroyExceptionInfo(exception);
#endif
		free( buffer);
		magick_croak( "ExportImagePixels", exception);
	}

	/* reshuffle */
	{
		unsigned char * in, * out;
		unsigned int lw, y;
		lw = pim. width * (( ip-> colorspace == RGBColorspace) ? 3 : 1);
		for (
			y = 0, in = buffer, out = pim. data + pim. line_size * ( pim. height - 1);
			y < pim. height;
			y++, in += lw, out -= pim. line_size
		)
			memcpy( out, in, lw);
	}
	free( buffer);
}
