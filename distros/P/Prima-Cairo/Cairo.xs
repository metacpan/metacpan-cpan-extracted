#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <DeviceBitmap.h>
#include <Widget.h>
#include <Image.h>
#include <img_conv.h>
#include <Icon.h>
#include <Application.h>
#include <Printer.h>

#ifdef PRIMA_PLATFORM_X11
#include <unix/guts.h>
#define Drawable        XDrawable
#define Font            XFont
#include <cairo.h>
#include <cairo-xlib.h>
#ifdef HAVE_X11_EXTENSIONS_XRENDER_H
#include <cairo-xlib-xrender.h>
#endif
#define sys (( PDrawableSysData) var-> sysData)
UnixGuts * pguts;
#else
#include <win32/win32guts.h>
#include <cairo.h>
#include <cairo-win32.h>
#define sys (( PDrawableData) var-> sysData)
#endif

#define REQ_TARGET_APPLICATION 0
#define REQ_TARGET_WINDOW      1
#define REQ_TARGET_BITMAP      2
#define REQ_TARGET_PIXMAP      3
#define REQ_TARGET_IMAGE       4
#define REQ_TARGET_PRINTER     5

#define var (( PDrawable) widget)
PWidget_vmt CWidget;
PDeviceBitmap_vmt CDeviceBitmap;
PImage_vmt CImage;
PIcon_vmt CIcon;
PApplication_vmt CApplication;
PPrinter_vmt CPrinter;

void*
apc_cairo_surface_create( Handle widget, int request)
{
	cairo_surface_t * result = NULL;
#ifdef PRIMA_PLATFORM_X11
	Point p;
	Visual *visual;
	if ( pguts == NULL )
		pguts = (UnixGuts*) apc_system_action("unix_guts");

	XCHECKPOINT;

	switch ( request) {
	case REQ_TARGET_BITMAP:
		result = cairo_xlib_surface_create_for_bitmap(DISP, sys->gdrawable, ScreenOfDisplay(DISP,SCREEN), var->w, var->h);
		break;
	case REQ_TARGET_WINDOW:
		p = apc_widget_get_size( widget );
#ifdef HAVE_X11_EXTENSIONS_XRENDER_H
		if ( sys-> flags. layered )
			result = cairo_xlib_surface_create_with_xrender_format(DISP, sys->gdrawable, ScreenOfDisplay(DISP,SCREEN), pguts->xrender_argb_pic_format, p.x, p.y);
		else
#endif
	 		result = cairo_xlib_surface_create(DISP, sys->gdrawable, VISUAL, p.x, p.y);
		break;
	case REQ_TARGET_PRINTER:
		break;
	default:
#ifdef HAVE_X11_EXTENSIONS_XRENDER_H
		if ( sys-> flags. layered )
			result = cairo_xlib_surface_create_with_xrender_format(DISP, sys->gdrawable, ScreenOfDisplay(DISP,SCREEN), pguts->xrender_argb_pic_format, var->w, var->h);
		else
#endif
			result = cairo_xlib_surface_create(DISP, sys->gdrawable, VISUAL, var->w, var->h);
	}

	XCHECKPOINT;
#else
	result = ( request == REQ_TARGET_PRINTER ) ?
        	cairo_win32_printing_surface_create(sys-> ps) : (
#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 14, 0)
		sys-> options. aptLayered ? cairo_win32_surface_create_with_format(sys-> ps, CAIRO_FORMAT_ARGB32) :
#endif
        	cairo_win32_surface_create(sys-> ps));
#endif
	return (void*) result;
}

static Byte rev_bytes[256];
static void
init_rev_bytes()
{
	int i = 0;
    	static const int end = 1;

    	if ( *((char *) &end) == 0x01 ) {
		// little-endian
		for ( i = 0; i < 256; i++) {
			unsigned int j,r = 0;
			Byte x = i;
			for (j = 0; j < 8; j++) {
				if ( x & 0x80 ) r |= 0x100;
				x <<= 1;
				r >>= 1;
			}
			rev_bytes[i] = r & 0xff;
		}
	} else {
		// big-endian
		for ( i = 0; i < 256; i++) rev_bytes[i] = i;
	}
}

static void
rev_memcpy(register Byte *dst, register Byte *src, register unsigned int stride)
{
	while (stride-- > 0) *dst++ = rev_bytes[*src++];
}

static void
invert( register Byte *dst, register unsigned int stride)
{
	while (stride-- > 0) {
		register Byte x = ~*dst;
		*dst++ = x;
	}
}

#define T_FROM_CAIRO  0
#define T_TO_CAIRO    0x100
#define T_LE          0
#define T_BE          0x1000
#define T_PALETTE     0
#define T_RGB         0
#define T_ARGB        0x2000
#define T_A1          0
#define T_A8          0x4000
#define T_A0          0x8000

MODULE = Prima::Cairo      PACKAGE = Prima::Cairo

BOOT:
{
	PRIMA_VERSION_BOOTCHECK;
	CWidget = (PWidget_vmt)gimme_the_vmt( "Prima::Widget");
	CDeviceBitmap = (PDeviceBitmap_vmt)gimme_the_vmt( "Prima::DeviceBitmap");
	CImage = (PImage_vmt)gimme_the_vmt( "Prima::Image");
	CIcon = (PIcon_vmt)gimme_the_vmt( "Prima::Icon");
	CApplication = (PApplication_vmt)gimme_the_vmt( "Prima::Application");
	CPrinter = (PPrinter_vmt)gimme_the_vmt( "Prima::Printer");
	init_rev_bytes();
}

PROTOTYPES: ENABLE

void
copy_image_data(im,s,direction)
	SV * im;
	UV s;
	int direction;
PREINIT:
	Handle image;
	int i, w, h, dest_stride, src_stride, mask_stride, stride, selector, cformat;
	Byte *dest_buf, *src_buf, *mask_buf, *mask_buf_byte;
	Byte colorref_mono[2] = {255,0};
	Byte colorref_byte[2] = {1,0};
	cairo_surface_t * surface;
    	static const int end = 1;
CODE:
	surface = INT2PTR(cairo_surface_t*,s);
	dest_stride = cairo_image_surface_get_stride(surface);
	dest_buf    = cairo_image_surface_get_data(surface);
	cformat     = cairo_image_surface_get_format(surface);

	if ( !(image = gimme_the_mate(im)) || !kind_of( image, CImage))
		croak("bad object: not an image");
	switch (PImage(image)->type) {
	case imBW:
		if ( cformat != CAIRO_FORMAT_A1 ) croak("bad surface: not in a1 format");
		break;
	case imByte:
		if ( cformat != CAIRO_FORMAT_A8 ) croak("bad surface: not in a8 format");
		break;
	case imRGB:
		if (kind_of( image, CIcon)) {
			if (cformat != CAIRO_FORMAT_ARGB32) croak("bad surface: not in argb32 format"); 
		} else {
			if (cformat != CAIRO_FORMAT_RGB24 && cformat != CAIRO_FORMAT_ARGB32) croak("bad surface: not in rgb24/argb32 format");
		}
		break;

	}

	w   	   = PImage(image)->w;
	h   	   = PImage(image)->h;
	src_stride = PImage(image)->lineSize;
	src_buf    = PImage(image)->data + src_stride * ( h - 1);
	stride     = ( src_stride > dest_stride ) ? dest_stride : src_stride;
	selector   = (PImage(image)->type & imBPP) + (direction ? T_TO_CAIRO : T_FROM_CAIRO);

	if (cformat == CAIRO_FORMAT_ARGB32 && kind_of( image, CIcon)) {
		mask_stride   = PIcon(image)->maskLine;
		mask_buf      = PIcon(image)->mask + mask_stride * (h - 1);
		mask_buf_byte = malloc(w);
		selector |= T_ARGB | T_A1;
		if ( PIcon(image)->maskType == imbpp8) selector |= T_A8;
	} else if (direction && cformat == CAIRO_FORMAT_ARGB32) {
		mask_buf = mask_buf_byte = NULL;
		selector |= T_ARGB | T_A0;
	} else {
		mask_buf = mask_buf_byte = NULL;
		mask_stride = 0;
	}
    	
	if ( *((char *) &end) != 0x01 && (cformat == CAIRO_FORMAT_ARGB32 || cformat == CAIRO_FORMAT_RGB24) ) {
		// big-endian mess
		selector |= T_BE;
	} else 
		selector |= T_LE;
 
	for ( i = 0; i < h; i++, src_buf -= src_stride, dest_buf += dest_stride, mask_buf -= mask_stride ) {
		switch(selector) {
		/* from cairo surface */
		case T_FROM_CAIRO | T_LE | T_PALETTE | 1:
/*
 * @CAIRO_FORMAT_A1: each pixel is a 1-bit quantity holding
 *   an alpha value. Pixels are packed together into 32-bit
 *   quantities. The ordering of the bits matches the
 *   endianess of the platform. On a big-endian machine, the
 *   first pixel is in the uppermost bit, on a little-endian
 *   machine the first pixel is in the least-significant bit.
*/
			rev_memcpy(src_buf, dest_buf, stride);
			invert(src_buf, stride);
			break;
		case T_FROM_CAIRO | T_LE | T_PALETTE | 8:
			memcpy(src_buf, dest_buf, w);
			break;
		case T_FROM_CAIRO | T_LE | T_RGB | 24:
			bc_rgbi_rgb(dest_buf, src_buf, w);
			break;
		case T_FROM_CAIRO | T_LE | T_ARGB | 24 | T_A1 :
			bc_rgbi_rgb(dest_buf, src_buf, w);
			{
				int j;
				Byte * alpha = dest_buf + 3;
				for (j = 0; j < w; j++, alpha += 4) mask_buf_byte[j] = (*alpha < 127) ? 0 : 1;
			}
			bc_byte_mono_cr( mask_buf_byte, mask_buf, w, colorref_byte);
			break;
		case T_FROM_CAIRO | T_LE | T_ARGB | 24 | T_A8 :
			bc_rgbi_rgb(dest_buf, src_buf, w);
			{
				int j;
				Byte * alpha = dest_buf + 3;
				for (j = 0; j < w; j++, alpha += 4) mask_buf[j] = *alpha;
			}
			break;
		case T_FROM_CAIRO | T_BE | T_RGB | 24:
			bc_ibgr_rgb(dest_buf, src_buf, w);
			break;
		case T_FROM_CAIRO | T_BE | T_ARGB | 24 | T_A1:
			bc_ibgr_rgb(dest_buf, src_buf, w);
			{
				int j;
				Byte * alpha = dest_buf;
				for (j = 0; j < w; j++, alpha += 4) mask_buf_byte[j] = (*alpha < 127) ? 0 : 1;
			}
			bc_byte_mono_cr( mask_buf_byte, mask_buf, w, colorref_byte);
			break;
		case T_FROM_CAIRO | T_BE | T_ARGB | 24 | T_A8:
			bc_ibgr_rgb(dest_buf, src_buf, w);
			{
				int j;
				Byte * alpha = dest_buf;
				for (j = 0; j < w; j++, alpha += 4) mask_buf[j] = *alpha;
			}
			break;
		/* to cairo surface */
		case T_TO_CAIRO | T_LE | T_PALETTE | 1:
			rev_memcpy(dest_buf, src_buf, stride);
			invert(dest_buf, stride);
			break;
		case T_TO_CAIRO | T_LE | T_PALETTE | 8:
			memcpy(dest_buf, src_buf, w);
			break;
		case T_TO_CAIRO | T_LE | T_RGB | 24:
			bc_rgb_rgbi(src_buf, dest_buf, w);
			break;
		case T_TO_CAIRO | T_LE | T_ARGB | 24 | T_A0:
			bc_rgb_rgbi(src_buf, dest_buf, w);
			{
				int j;
				Byte * alpha = dest_buf + 3;
				for (j = 0; j < w; j++, alpha += 4) *alpha = 0xff;
			}
			break;
		case T_TO_CAIRO | T_LE | T_ARGB | 24 | T_A1:
			bc_rgb_rgbi(src_buf, dest_buf, w);
			bc_mono_byte_cr( mask_buf, mask_buf_byte, w, colorref_mono);
			{
				int j;
				Byte * alpha = dest_buf + 3;
				for (j = 0; j < w; j++, alpha += 4) *alpha = mask_buf_byte[j];
			}
			break;
		case T_TO_CAIRO | T_LE | T_ARGB | 24 | T_A8:
			bc_rgb_rgbi(src_buf, dest_buf, w);
			{
				int j;
				Byte * alpha = dest_buf + 3;
				for (j = 0; j < w; j++, alpha += 4) *alpha = mask_buf[j];
			}
			break;
		case T_TO_CAIRO | T_BE | T_RGB | 24:
			bc_rgb_ibgr(src_buf, dest_buf, w);
			break;
		case T_TO_CAIRO | T_BE | T_ARGB | 24 | T_A0:
			bc_rgb_ibgr(src_buf, dest_buf, w);
			{
				int j;
				Byte * alpha = dest_buf;
				for (j = 0; j < w; j++, alpha += 4) *alpha = 0xff;
			}
			break;
		case T_TO_CAIRO | T_BE | T_ARGB | 24 | T_A1:
			bc_rgb_ibgr(src_buf, dest_buf, w);
			bc_mono_byte_cr( mask_buf, mask_buf_byte, w, colorref_mono);
			{
				int j;
				Byte * alpha = dest_buf;
				for (j = 0; j < w; j++, alpha += 4) *alpha = mask_buf_byte[j];
			}
			break;
		case T_TO_CAIRO | T_BE | T_ARGB | 24 | T_A8:
			bc_rgb_ibgr(src_buf, dest_buf, w);
			{
				int j;
				Byte * alpha = dest_buf;
				for (j = 0; j < w; j++, alpha += 4) *alpha = mask_buf[i];
			}
			break;
		default:
			croak("panic: unknown conversion %x", selector);
		}
	}
	if (mask_buf_byte) free( mask_buf_byte);
OUTPUT:	

SV*
surface_create(sv)
	SV *sv
PREINIT:
	Handle object;
	void* context;
	int request;
	Bool need_paint_state = 0;
CODE:
	RETVAL = 0;
	
	if ( !(object = gimme_the_mate(sv)))
		croak("not a object");

	if ( kind_of( object, CApplication)) {
		request = REQ_TARGET_APPLICATION;
		need_paint_state = 1;
	}
	else if ( kind_of( object, CWidget))
		request = REQ_TARGET_WINDOW;
	else if ( kind_of( object, CDeviceBitmap)) 
		request = (((PDeviceBitmap)object)->type == dbtBitmap) ? REQ_TARGET_BITMAP : REQ_TARGET_PIXMAP;
	else if ( kind_of( object, CImage)) {
		request = REQ_TARGET_IMAGE;
		need_paint_state = 1;
	}
	else if ( kind_of( object, CPrinter)) {
		request = REQ_TARGET_PRINTER;
		need_paint_state = 1;
	}
	else
		croak("bad object");

	if ( need_paint_state && !PObject(object)-> options. optInDraw )
		croak("object not in paint state");
	context = apc_cairo_surface_create(object, request);

	RETVAL = newSV(0);
	sv_setref_pv(RETVAL, "Prima::Cairo::Surface", context);
OUTPUT:
	RETVAL

