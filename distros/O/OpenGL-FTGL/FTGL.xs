#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <FTGL/ftgl.h>

// The function _ErrorMsg(err) return the string corresponding
// to the error number err.
// We use the macros from fterrors.h

#undef __FTERRORS_H__
#define FT_ERROR_START_LIST  char * _ErrorMsg( FT_Error err ){\
switch (err) {
#define FT_ERRORDEF( e, v, s ) case e: return s;
#define FT_ERROR_END_LIST    default: return "unknown error"; }\
}
#include FT_ERRORS_H

MODULE = OpenGL::FTGL		PACKAGE = OpenGL::FTGL

# =========================== Font C-API
void
ftglCreateBitmapFont(file);
    const char *  file
  PREINIT:
    FTGLfont* RETVAL;
  PPCODE:
    RETVAL = ftglCreateBitmapFont(file);
	if ( RETVAL ) {
	  ST(0) = sv_newmortal();
	  sv_setref_pv(ST(0), "FTGLfontPtr", (void*)RETVAL);
	  XSRETURN(1);
	}
	else
	  XSRETURN_UNDEF;

void
ftglCreateBufferFont(file);
    const char *  file
  PREINIT:
    FTGLfont* RETVAL;
  PPCODE:
    RETVAL = ftglCreateBufferFont(file);
	if ( RETVAL ) {
	  ST(0) = sv_newmortal();
	  sv_setref_pv(ST(0), "FTGLfontPtr", (void*)RETVAL);
	  XSRETURN(1);
	}
	else
	  XSRETURN_UNDEF;

void
ftglCreateExtrudeFont(file);
    const char *  file
  PREINIT:
    FTGLfont* RETVAL;
  PPCODE:
    RETVAL = ftglCreateExtrudeFont(file);
	if ( RETVAL ) {
	  ST(0) = sv_newmortal();
	  sv_setref_pv(ST(0), "FTGLfontPtr", (void*)RETVAL);
	  XSRETURN(1);
	}
	else
	  XSRETURN_UNDEF;

void
ftglCreateOutlineFont(file);
    const char *  file
  PREINIT:
    FTGLfont* RETVAL;
  PPCODE:
    RETVAL = ftglCreateOutlineFont(file);
	if ( RETVAL ) {
	  ST(0) = sv_newmortal();
	  sv_setref_pv(ST(0), "FTGLfontPtr", (void*)RETVAL);
	  XSRETURN(1);
	}
	else
	  XSRETURN_UNDEF;

void
ftglCreatePixmapFont(file);
    const char *  file
  PREINIT:
    FTGLfont* RETVAL;
  PPCODE:
    RETVAL = ftglCreatePixmapFont(file);
	if ( RETVAL ) {
	  ST(0) = sv_newmortal();
	  sv_setref_pv(ST(0), "FTGLfontPtr", (void*)RETVAL);
	  XSRETURN(1);
	}
	else
	  XSRETURN_UNDEF;

void
ftglCreatePolygonFont(file);
    const char *  file
  PREINIT:
    FTGLfont* RETVAL;
  PPCODE:
    RETVAL = ftglCreatePolygonFont(file);
	if ( RETVAL ) {
	  ST(0) = sv_newmortal();
	  sv_setref_pv(ST(0), "FTGLfontPtr", (void*)RETVAL);
	  XSRETURN(1);
	}
	else
	  XSRETURN_UNDEF;

void
ftglCreateTextureFont(file);
    const char *  file
  PREINIT:
    FTGLfont* RETVAL;
  PPCODE:
    RETVAL = ftglCreateTextureFont(file);
	if ( RETVAL ) {
	  ST(0) = sv_newmortal();
	  sv_setref_pv(ST(0), "FTGLfontPtr", (void*)RETVAL);
	  XSRETURN(1);
	}
	else
	  XSRETURN_UNDEF;


void
ftglRenderFont (...)
  CODE:
  FTGLfont *  font;
  const char *  string;
  int  mode = FTGL_RENDER_ALL;
  
  if (items > 3 || items < 2)
      croak("Usage: ftglRenderFont (font, string [, mode]) )");
  if (sv_derived_from(ST(0), "FTGLfontPtr")) {
    IV tmp = SvIV((SV*)SvRV(ST(0)));
    font = INT2PTR(FTGLfont *,tmp);
  }
  else
    croak("OpenGL::FTGL::ftglRenderFont: font is not of type FTGLfontPtr");
  string = (const char *)SvPV_nolen(ST(1));
  if (items == 3)
    mode = (int)SvIV(ST(2));
  ftglRenderFont(font, string, mode);

int
ftglSetFontCharMap (font, encoding)
  FTGLfont * font
  FT_Encoding encoding

void
ftglGetFontCharMapList (font)
    FTGLfont *font;
  PREINIT:
	int n, i;
	FT_Encoding * p;
  PPCODE:
	n = ftglGetFontCharMapCount (font);
	if (n>0) {
	  p = ftglGetFontCharMapList(font);
	  EXTEND(SP, n);
	  for (i=0; i<n; i++,p++) {
	    PUSHs( sv_2mortal(newSViv(*p)) );
	  }
	  XSRETURN(n);
	}
	XSRETURN_EMPTY;

int
ftglSetFontFaceSize (...)
  CODE:
  FTGLfont *font;
  unsigned int size;
  unsigned int res = 0;

  if (items > 3 || items < 2)
      croak("Usage: ftglSetFontFaceSize (font, size [, resolution]) )");
  if (sv_derived_from(ST(0), "FTGLfontPtr")) {
    IV tmp = SvIV((SV*)SvRV(ST(0)));
    font = INT2PTR(FTGLfont *,tmp);
  }
  else
    croak("OpenGL::FTGL::ftglSetFontFaceSize: font is not of type FTGLfontPtr");

  size = (unsigned int)SvUV(ST(1));
  if (items == 3)
    res = (unsigned int)SvUV(ST(2));
  RETVAL = ftglSetFontFaceSize(font, size, res);

unsigned int
ftglGetFontFaceSize (font)
  FTGLfont *font

void
ftglSetFontDepth (font, depth)
  FTGLfont *font
  float depth

void
ftglSetFontOutset (font, front, back)
  FTGLfont *font
  float front
  float back

void
ftglSetFontDisplayList (font, useList)
  FTGLfont *font
  int useList

float
ftglGetFontAscender (font)
  FTGLfont *font

float
ftglGetFontDescender (font)
  FTGLfont *font

float
ftglGetFontLineHeight (font)
  FTGLfont *font

void
ftglGetFontBBox (...)
  PPCODE:
    FTGLfont *font;
    char *string;
    STRLEN len;
    float bounds[6];
	int i;
    if (items > 3 || items < 2)
      croak("Usage: ftglGetFontBBox( font, string [,len] )");
	if (sv_derived_from(ST(0), "FTGLfontPtr")) {
	    IV tmp = SvIV((SV*)SvRV(ST(0)));
	    font = INT2PTR(FTGLfont *,tmp);
	}
	else
	    croak("OpenGL::FTGL::ftglGetFontBBox: font is not of type FTGLfontPtr");
	string = SvPV(ST(1), len);
	if (items == 3) {
	  len = SvIV(ST(2));
	}
	ftglGetFontBBox(font, string, len, bounds);
	EXTEND(SP, 6);
	for (i=0; i<6; i++) {
	  PUSHs( sv_2mortal(newSVnv(bounds[i])) );
	  }
    XSRETURN(6);

float
ftglGetFontAdvance (font, string)
  FTGLfont *font
  const char *string

FT_Error
ftglGetFontError (font)
   FTGLfont *font

char *
ftglGetFontErrorMsg (font)
   FTGLfont *font;
   CODE:
     RETVAL = _ErrorMsg(ftglGetFontError(font));
   OUTPUT:
     RETVAL

MODULE = OpenGL::FTGL        PACKAGE = FTGLfontPtr

void
DESTROY(font)
    FTGLfont * font
    CODE:
	    // fprintf( stderr, "*** DESTROY\n");
        ftglDestroyFont(font);

MODULE = OpenGL::FTGL        PACKAGE = OpenGL::FTGL

char * 
_ErrorMsg(err)
  FT_Error err




