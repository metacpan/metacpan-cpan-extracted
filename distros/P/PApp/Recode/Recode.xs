#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <iconv.h>

/*
 * the expectation that perl strings have an appended zero is spread all over this file, yet
 * it breaks it itself almost everywhere.
 */

/*****************************************************************************/

typedef struct pconv {
  iconv_t *iconv;
  SV *to, *from, *fallback;
} *PApp__Recode__Pconv;

static struct pconv *
pconv_new (SV *tocode, SV *fromcode, SV *fallback)
{
  struct pconv *self;
  iconv_t iconv;

  if ((iconv = iconv_open (SvPV_nolen (tocode),
                           SvPV_nolen (fromcode))) == (iconv_t) - 1)
    return 0;

  New (0, self, 1, struct pconv); /* selten so eine hässliche API gesehen... */
  self->iconv    = iconv;
  self->to       = newSVsv (tocode);
  self->from     = newSVsv (fromcode);
  self->fallback = fallback ? newSVsv (fallback) : 0;

  return self;
}

static void
pconv_destroy (struct pconv *self)
{
  (void) iconv_close (self->iconv);
  SvREFCNT_dec (self->to);
  SvREFCNT_dec (self->from);
  if (self->fallback)
    SvREFCNT_dec (self->fallback);

  Safefree (self);
}

/*
 * if !fallback, do a plain conversion. if !!fallback, do a conversion
 * from utf8 with fallback and warn if the iconv implementation does an
 * implementation defined conversion.
 */
static SV *
plain_iconv (iconv_t self, SV *string, SV *fallback)
{
  char *icursor, *save_icursor;
  char *ocursor;
  size_t ibl, save_ibl, obl, obufsize, obufnext;
  SV *res;		/* Perl return string */
  SV *replace = 0;	/* fallback replacement */
  static int warned = 0;

  res = newSVpvn ("", 0);

  icursor = SvPV (string, ibl);

  /* start with a slightly larger buffer than necessary,
   * then increase it exponentially. maybe we should start with
   * a fixed but relatively large size and increase in constant steps? */
  obufsize = ibl + ((ibl + 15) >> 4) + 1;
  obufnext = (ibl << 1) + 1;

  ocursor = SvGROW (res, obl = obufsize);

  while (ibl != 0)
    {
      size_t ret;

      ret = iconv (self, &icursor, &ibl, &ocursor, &obl);

      if (ret == (size_t)-1)
	{
	  switch (errno)
	    {
	    case E2BIG:
              /* enlarge buffer and position pointer where we left */
              ret = ocursor - SvPVX (res);
              ocursor = SvGROW (res, obufsize) + ret;
              obl = obufsize - ret;

              obufsize = obufnext; obufnext <<= 1;
	      break;

	    case EILSEQ:
              if (fallback)
                {
                  if (replace)
                    {
                      ocursor = "PApp::Recode::PConv: conversion of fallback sequence '%s' failed";
                      goto raiserr;
                    }
                  else
                    {
                      dSP;
                      STRLEN retlen;
                      int count;
                      UV chr =
#ifdef utf8_to_uv
                        utf8_to_uv (icursor, ibl, &retlen, UTF8_CHECK_ONLY); /* <<DEVEL9916 */
#else
                        utf8n_to_uvchr (icursor, ibl, &retlen, UTF8_CHECK_ONLY); /* >=DEVEL9916 */
#endif

                      if (retlen == (STRLEN) -1)
                        {
                          ocursor = "PApp::Recode::PConv: non-utf8-character in input detected";
                          goto raiserr;
                        }

                      /* call fallback */
                      ENTER;
                      SAVETMPS;
                      
                      PUSHMARK(SP);
                      XPUSHs (sv_2mortal (newSVuv (chr)));
                      PUTBACK;

                      count = call_sv (fallback, G_SCALAR);

                      if (count != 1)
                        {
                          ocursor = "PApp::Recode::PConv: fallback function did not return a single value";
                          goto raiserr;
                        }

                      save_icursor = icursor + retlen;
                      save_ibl     = ibl - retlen;

                      replace = SvREFCNT_inc (POPs);
                      icursor = SvPV (replace, retlen);
                      ibl     = retlen;

                      SPAGAIN;
                      FREETMPS;
                      LEAVE;

                      if (!ibl)
                        {
                          ocursor = "pconv: fallback function did not provide non-empty replacement string";
                          goto raiserr;
                        }

                      break;
                    }
                }
              else
                {
                  /*ocursor = "pconv: illegal multibyte character sequence encountered during character conversion";*/
                  SvREFCNT_dec (res);
                  return 0;
                }

              abort (); /* NOTREACHED */

	    case EINVAL:
              ocursor = "incomplete multibyte character sequence encountered during character conversion";
              goto raiserr;

	    default:
              /* some unknown error */
              ocursor = "PApp::Recode::PConv: illegal multibyte character sequence encountered during character conversion";
              icursor = strerror (errno);
              goto raiserr;
	    }
	}
      else if (ret > 0)
        {
          if (fallback && !warned)
            {
              warn ("pconv warning: your iconv implementation is not supported because it does NOT act funny");
              warned = 1;
            }
        }
      else
        if (replace)
          {
            icursor = save_icursor;
            ibl     = save_ibl;
            SvREFCNT_dec (replace);
            replace = 0;
          }
    }

  SvCUR_set (res, ocursor - SvPVX (res));

  return res;

raiserr:
  SvREFCNT_dec (res);
  if (replace)
    SvREFCNT_dec (replace);

  croak (ocursor, icursor);
}

/* this is called when plain_iconv failed. In this case we do it the slow way. */
static SV *
safe_iconv (const char *tocode, const char *fromcode, SV *string, SV *fallback)
{
  SV *res;
  iconv_t iconv;
  
  if (strcmp (fromcode, "utf-8"))
    {
      iconv = iconv_open ("utf-8", fromcode);
      if (!iconv)
        croak ("PApp::Recode::Pconv: conversion from %s to utf-8 not available (%s)", fromcode, strerror (errno));

      string = plain_iconv (iconv, string, 0);
      iconv_close (iconv); 

      if (!string)
        return Nullsv;
    }
  else /* from utf-8 is a veeery common case, since PAPP_CHARSET == UTF-8 */
    SvREFCNT_inc (string);

  iconv = iconv_open (tocode, "utf-8");

  if (!iconv)
    {
      SvREFCNT_dec (string);
      croak ("PApp::Recode::Pconv: conversion from utf-8 to %s not available (%s)", tocode, strerror (errno));
    }

  /* now we relying on glibc's non-unix behaviour of returning EILSEQ on
     unconvertible characters. warn for other implementations. */

  res = plain_iconv (iconv, string, fallback);
  iconv_close (iconv);
  SvREFCNT_dec (string);

  return res;
}

MODULE = PApp::Recode		PACKAGE = PApp::Recode::Pconv

PROTOTYPES: ENABLE

PApp::Recode::Pconv
new(class, tocode, fromcode, fallback = Nullsv)
	SV *	class
	SV *	tocode
	SV *	fromcode
	SV *	fallback
        PROTOTYPE: $$$;$
	CODE:
        RETVAL = pconv_new (tocode, fromcode, fallback);
	OUTPUT:
	RETVAL

PApp::Recode::Pconv
open(tocode, fromcode, fallback = Nullsv)
	SV *	tocode
	SV *	fromcode
	SV *	fallback
        PROTOTYPE: $$;$
	CODE:
        RETVAL = pconv_new (tocode, fromcode, fallback);
	OUTPUT:
	RETVAL

SV *
convert(self, string, reset = FALSE)
	PApp::Recode::Pconv	self
	SV *	string
        int	reset
        PROTOTYPE: $$;$
        ALIAS:
        	convert_fresh = 1
                reset         = 2
	CODE:
          /* reset conversion state when restart != 0 */
          if (reset || ix)
	    {
              size_t ibl, obl;
	      (void) iconv (self->iconv, NULL, &ibl, NULL, &obl);

              if (ix == 2)
                XSRETURN_EMPTY;
            }

          RETVAL = plain_iconv (self->iconv, string, 0);

          if (!RETVAL && self->fallback)
            RETVAL = safe_iconv (SvPV_nolen (self->to),
                                 SvPV_nolen (self->from),
                                 string, self->fallback);

          if (!RETVAL)
            croak ("PApp::Recode::PConv: character conversion from %s to %s failed (%s)",
                   SvPV_nolen (self->from), SvPV_nolen (self->to), strerror (errno));

	OUTPUT:
	RETVAL

void
DESTROY(self)
	PApp::Recode::Pconv	self
	CODE:
        pconv_destroy (self);

