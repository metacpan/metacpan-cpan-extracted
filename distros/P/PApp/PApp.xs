#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* 5.14 no longer exports these, a pity */
OP *Perl_pp_helem (pTHX);

#if _POSIX_SOURCE
#include <unistd.h>
#endif
#include <string.h>

/* agni */

#define CACHEp "_cache"
#define CACHEl (sizeof (CACHEp) - 1)
static U32 CACHEh;
static SV *CACHEs;
#define ATTRp  "_attr"
#define ATTRl  (sizeof (ATTRp) - 1)
static U32 ATTRh;
static SV *ATTRs;
#define TYPEp  "_type"
#define TYPEl  (sizeof (TYPEp) - 1)
static U32 TYPEh;
static SV *TYPEs;
#define PATHp   "_path"
#define PATHl   (sizeof (PATHp) - 1)
static U32 PATHh;
static SV *PATHs;
#define GIDp   "_gid"
#define GIDl   (sizeof (GIDp) - 1)
static U32 GIDh;
static SV *GIDs;
#define INSTANCEp   "_gid"
#define INSTANCEl   (sizeof (INSTANCEp) - 1)
static U32 INSTANCEh;
static SV *INSTANCEs;

static MGVTBL vtbl_agni_object = {0, 0, 0, 0, 0};

#define MAKEVERS(r,v,s) (((r) << 24) || ((v) << 12) || (s))
#define PERLVERS MAKEVERS(PERL_REVISION, PERL_VERSION, PERL_SUBVERSION)

static const char *
AGNI_OBJ_STRING (SV *self)
{
  static char s[80];
  HE *path = hv_fetch_ent ((HV *)SvRV (self), PATHs, 0, PATHh);
  HE *gid  = hv_fetch_ent ((HV *)SvRV (self), GIDs , 0, GIDh);

  sprintf (s, "agni::%s::%s",
      path ? SvPV_nolen (HeVAL (path)) : "?",
      gid  ? SvPV_nolen (HeVAL (gid )) : "?");

  return s;
}

static void
compute_hash (char *key, I32 len, SV **sv, U32 *hash)
{
  *sv = newSVpvn (key, len);
  PERL_HASH (*hash, key, len);
}

static SV *
obj_by_gid (SV *obj, SV *gid)
{
  dSP;
  SV **path = hv_fetch ((HV *)SvRV (obj), "_path", 5, 0);

  if (path && *path)
    {
      PUSHMARK (SP); EXTEND (SP, 2); PUSHs (*path); PUSHs (gid);
      PUTBACK;

      if (call_pv ("Agni::path_obj_by_gid", G_SCALAR) == 1)
        {
          SPAGAIN;

          obj = POPs;

          if (SvOK (obj))
            {
              if (!sv_isobject (obj))
                croak ("FATAL: path_obj_by_gid(%s/%s) did not return an object",
                       SvPV_nolen (*path), SvPV_nolen (gid));

              return obj;
            }
        }
      else if (SvTRUE (ERRSV))
        croak (0);
    }

  return 0;
}

static SV *
agni_key2obj (SV *self, SV **key, int need_member)
{
  SV *tobj;
  char *key_ = SvPV_nolen (*key);

  /* GID or NAME fetch. */
  if (key_[0] >= '1' && key_[0] <= '9')
    {
      /* GID, fetch obj. */
      tobj = obj_by_gid (self, *key);

      if (!tobj)
        croak ("unable to resolve type '%s' while accessing member by GID", key_);
    }
  else
    {
      /* NAME, fetch tobj and GID. */
      HV *hvt;
      HE *he;

      SvRMAGICAL_off (SvRV (self));
      he = hv_fetch_ent ((HV *)SvRV (self), TYPEs, 0, TYPEh);
      SvRMAGICAL_on (SvRV (self));
      if (!he)
        croak ("FATAL: object %s has no " TYPEp " member", AGNI_OBJ_STRING (self));

      hvt = (HV *)SvRV (HeVAL (he));
      he = hv_fetch_ent (hvt, *key, 0, 0);

      if (!he)
        if (need_member)
          croak ("object %s has no data member named '%s'", AGNI_OBJ_STRING (self), key_);
        else
          return 0;

      tobj = HeVAL (he);

      if (!SvROK (tobj) || !SvOBJECT (SvRV (tobj)))
        croak ("type object for '%s' is not an object (bug in populate method?)", key_);

      {
        HV *hv = (HV *)SvRV (tobj);

        SvRMAGICAL_off (hv);
        he = hv_fetch_ent (hv, GIDs, 0, GIDh);
        SvRMAGICAL_on (hv);
      }

      if (!he)
        croak ("FATAL: type object for '%s' has no GID", key_);

      *key = HeVAL (he);
    }

  return tobj;
}

/* return a mortalized scalar or zero */
static SV *
agni_fetch (SV *self, SV *key)
{
  static int recurse;

  HE *he;
  SV *ret = 0;
  HV *hv = (HV *)SvRV (self);

  if (recurse++ > 1000)
    croak ("deep recursion in PApp::agni_fetch, aborting");

  /* _-keys go into $self, non-_-keys are store'ed immediately */
  if (SvPV_nolen (key)[0] == '_')
    {
      SvRMAGICAL_off (hv);
      HE *he = hv_fetch_ent (hv, key, 0, 0);
      SvRMAGICAL_on (hv);

      if (he)
        ret = HeVAL (he);
    }
  else
    {
      SV *tobj = agni_key2obj (self, &key, 0);
      dSP;

      if (tobj)
        {
          HE *he;
          HV *hvc;
          
          SvRMAGICAL_off (hv);
          he = hv_fetch_ent (hv, CACHEs, 0, CACHEh);
          SvRMAGICAL_on (hv);

          if (!he)
            croak ("FATAL: FETCH called on an object without _cache");

          hvc = (HV *)SvRV (HeVAL (he));
          he = hv_fetch_ent (hvc, key, 0, 0);

          /* if cached, do not call fetch */
          if (he)
            ret = HeVAL (he);
          else
            {
              SV *saveerr = SvOK (ERRSV) ? sv_mortalcopy (ERRSV) : 0; /* this is necessary because we can't use KEEPERR, or can we? */
              SV *data;
              int c;

              /* $tobj->fetch($self) */
              PUSHMARK (SP); EXTEND (SP, 2); PUSHs (tobj); PUSHs (self); PUTBACK;
              c = call_method ("fetch", G_SCALAR | G_EVAL);
              SPAGAIN;
              if (SvTRUE (ERRSV))
                croak (0);

              if (c == 1)
                data = POPs;
              else if (c == 0)
                data = &PL_sv_undef;
              else
                croak ("TYPE->fetch must return at most one return value");

              /* $tobj->thaw($data) */
              PUSHMARK (SP); EXTEND (SP, 3); PUSHs (tobj); PUSHs (data); PUSHs (self); PUTBACK;
              c = call_method ("thaw", G_SCALAR | G_EVAL);
              SPAGAIN;
              if (SvTRUE (ERRSV))
                croak (0);

              if (c < 0 || c > 1)
                croak ("TYPE->thaw must return at most one return value");

              /* reuse thaw return values for ourselves. */

              if (saveerr)
                sv_setsv (ERRSV, saveerr);

              ret = POPs;
            }
        }

      PUTBACK;
    }

  --recurse;

  return ret;
}

static void
agni_store (SV *self, SV *key, SV *value)
{
  HV *hv = (HV*) SvRV (self);

  /* _-keys go into $self, non-_-keys are store'ed immediately */
  if (SvPV_nolen (key)[0] == '_')
    {
      SvRMAGICAL_off (hv);
      hv_store_ent (hv, key, newSVsv (value), 0);
      SvRMAGICAL_on (hv);
    }
  else
    {
      SV *saveerr = SvOK (ERRSV) ? sv_mortalcopy (ERRSV) : 0; /* this is necessary because we can't use KEEPERR, or can we? */
      SV *data;
      int c;
      SV *tobj = agni_key2obj (self, &key, 1);
      dSP;

      PUSHMARK (SP); EXTEND (SP, 3); PUSHs (tobj); PUSHs (value); PUSHs (self); PUTBACK;
      c = call_method ("freeze", G_SCALAR | G_EVAL);
      SPAGAIN;

      if (SvTRUE (ERRSV))
        croak (0);

      if (c == 1)
        data = POPs;
      else if (c == 0)
        data = &PL_sv_undef;
      else
        croak ("TYPE->freeze must return at most one return value");

      PUSHMARK (SP); EXTEND (SP, 3); PUSHs (tobj); PUSHs (self); PUSHs (data); PUTBACK;
      call_method ("store", G_VOID | G_DISCARD | G_EVAL);
      SPAGAIN;

      if (SvTRUE (ERRSV))
        croak (0);

      if (saveerr)
        sv_setsv (ERRSV, saveerr);

      PUTBACK;
    }
}

static OP *
agni_fetch_op (pTHX)
{

  dSP;
  MAGIC *mg;

  if (PL_op->op_flags & ~(OPf_WANT | OPf_KIDS)
      || PL_op->op_private & (OPpDEREF | OPpLVAL_DEFER)
      || !SvRMAGICAL (TOPm1s)
      || !(mg = mg_find (TOPm1s, PERL_MAGIC_tied))
      || mg->mg_virtual != &vtbl_agni_object
      )
    return Perl_pp_helem (aTHX);
  else
    {
      SV *sv = POPs;
      HV *hv = (HV *)POPs;
      I32 mark = SP - PL_stack_base;

      ENTER;
      PUTBACK;
      sv = agni_fetch (SvTIED_obj ((SV *)hv, mg), sv); /* newmortal, but.. */
      LEAVE;

      SP = PL_stack_base + mark;
      XPUSHs (sv ? sv_2mortal (newSVsv (sv)) : &PL_sv_undef);

      RETURN;
    }
}

static OP *
agni_store_op (pTHX)
{
  return Perl_pp_helem (aTHX);
}

static void
agni_try_patch (OP *(CPERLscope(*search))(pTHX), OP *(CPERLscope(*replace))(pTHX))
{
  /* dynamically find the op (horrors) and possibly PATCH it */
  {
    int ix = PL_savestack_ix;

    while (ix > 0)
      switch (PL_savestack[--ix].any_i32)
        {
          case SAVEt_INT:
            ix -= 2;
            break;
          case SAVEt_OP:
            {
              OP *op = (OP*)PL_savestack[--ix].any_ptr;

              if (op->op_ppaddr != search)
                return;

              op->op_ppaddr = replace;
            }
            return;
          default:
            /*printf ("unknown saveop %d\n", PL_savestack[ix].any_i32);*/
            return;
        }
notfound:
    ;
  }
}

/* papp */

/*
 * return wether the given sv really is a "scalar value" (i.e. something
 * we can setsv on without getting a headache.)
 */
#define sv_is_scalar_type(sv)	\
	(SvTYPE (sv) != SVt_PVAV \
	&& SvTYPE (sv) != SVt_PVHV \
	&& SvTYPE (sv) != SVt_PVCV \
	&& SvTYPE (sv) != SVt_PVIO)

/*****************************************************************************/

/*
 * the expectation that perl strings have an appended zero is spread all over this file, yet
 * it breaks it itself almost everywhere.
 */

typedef unsigned char uchar;

static uchar e64[ 64] = "0123456789-ABCDEFGHIJKLMNOPQRSTUVWXYZ.abcdefghijklmnopqrstuvwxyz";
static uchar d64[256];

#define x64_enclen(len) (((len) * 4 + 2) / 3)

#define INT_ERR(s) croak ("internal error " s)

static void
x64_enc (uchar *dst, uchar *src, STRLEN len)
{
  while (len >= 3)
    {
      *dst++ = e64[                          src[0] & 0x3f ];
      *dst++ = e64[((src[0] & 0xc0) >> 2) | (src[1] & 0x0f)];
      *dst++ = e64[((src[1] & 0xf0) >> 2) | (src[2] & 0x03)];
      *dst++ = e64[((src[2] & 0xfc) >> 2)                  ];
      src += 3; len -= 3;
    }

  switch (len)
    {
      case 2:
        *dst++ = e64[                          src[0] & 0x3f ];
        *dst++ = e64[((src[0] & 0xc0) >> 2) | (src[1] & 0x0f)];
        *dst++ = e64[((src[1] & 0xf0) >> 2)                  ];
        break;
      case 1:
        *dst++ = e64[                          src[0] & 0x3f ];
        *dst++ = e64[((src[0] & 0xc0) >> 2)                  ];
        break;
      case 0:
        break;
    }
}

/* 0 host, 1 le, 2 be */
static void
pack64 (uchar *buf, const char *str, int mode)
{
  unsigned long long val;

  val = strtoull (str, 0, 0);

  switch (mode)
    {
      case 1:
#if BYTEORDER != 0x4321 && BYTEORDER != 0x87654321
      case 0:
#endif
        buf[0] = val      ;
        buf[1] = val >>  8;
        buf[2] = val >> 16;
        buf[3] = val >> 24;
        buf[4] = val >> 32;
        buf[5] = val >> 40;
        buf[6] = val >> 48;
        buf[7] = val >> 56;
        break;
      case 2:
#if BYTEORDER == 0x4321 || BYTEORDER == 0x87654321
      case 0:
#endif
        buf[0] = val >> 56;
        buf[1] = val >> 48;
        buf[2] = val >> 40;
        buf[3] = val >> 32;
        buf[4] = val >> 24;
        buf[5] = val >> 16;
        buf[6] = val >>  8;
        buf[7] = val      ;
        break;
    }
}

static I32
papp_filter_read (pTHX_ int idx, SV *buf_sv, int maxlen)
{
  dSP;
  SV *datasv = FILTER_DATA (idx);

  ENTER;
  SAVETMPS;
  PUSHMARK (SP);
  XPUSHs (sv_2mortal (newSViv (idx)));
  XPUSHs (buf_sv);
  XPUSHs (sv_2mortal (newSViv (maxlen)));
  PUTBACK;
  maxlen = call_sv ((SV* )IoBOTTOM_GV (datasv), G_SCALAR);
  SPAGAIN;

  if (maxlen != 1)
    croak ("papp_filter_read: filter read function must return a single integer");

  maxlen = POPi;
  FREETMPS;
  LEAVE;

  if (maxlen <= 0)
    {
      SvREFCNT_dec (IoBOTTOM_GV (datasv));
      filter_del (papp_filter_read);
    }

  return maxlen;
}

/*****************************************************************************/

/* cache these gv's for quick access */
static GV *cipher_e,
          *location,
          *userid,
          *stateid,
          *sessionid,
          *state,
          *arguments,
          *surlstyle,
          *big_p;
          
static void
append_modpath(SV *r, HV *hv)
{
  SV **module = hv_fetch (hv, "\x00", 1, 0);

  if (module)
    sv_catsv (r, *module);

  if (hv_iterinit (hv) > 0)
    {
      HE *he;

      while ((he = hv_iternext (hv)))
        {
          I32 len;
          char *key;
          SV *val;

          key = hv_iterkey (he, &len);

          if (len == 1 && !*key)
            continue;

          val = hv_iterval (hv, he);

          if (!SvROK (val) || SvTYPE (SvRV (val)) != SVt_PVHV)
            croak ("modpath_freeze: hashref expected (1)");

          val = SvRV (val);

          if (!HvKEYS ((HV *)val))
            continue;

          sv_catpvn (r, "+", 1);
          sv_catpvn (r, key, len);
          sv_catpvn (r, "=", 1);
          append_modpath (r, (HV *)val);
        }
    }
    sv_catpvn (r, "-", 1);
}

static SV *
modpath_freeze (SV *modules)
{
  SV *r = newSVpvn ("", 0);

  if (!SvROK (modules) || SvTYPE (SvRV (modules)) != SVt_PVHV)
    croak ("modpath_freeze: hashref expected (0)");

  append_modpath (r, (HV *)SvRV (modules));

  do {
    SvCUR_set (r, SvCUR (r) - 1); /* chop final '-' */
  } while (SvCUR (r) && SvEND (r)[-1] == '-');

  return r;
}

static HV *
modpath_thaw (char **srcp, char *end)
{
  HV *hv = newHV ();
  char *src = *srcp;

  if (src < end)
    {
      char *path;
      
      path = src;
      while (src < end && *src != '=' && *src != '-' && *src != '+' && *src != '/')
        src++;

      if (src - path) /* do not store "empty" paths */
        if (!hv_store (hv, "\x00", 1, newSVpvn (path, src - path), 0))
          INT_ERR ("insert_modpath_1");

      while (src < end && *src == '+')
        {
          char *module;
          HV *hash;

          src++;

          module = src;
          while (src < end && *src != '=' && *src != '-' && *src != '+' && *src != '/')
            src++;

          if (*src != '=')
            croak ("malformed module path (=)");

          *srcp = src + 1;
          hash = modpath_thaw (srcp, end);

          if (HvKEYS (hash)) /* optimization, do not store empty components */
            if (!hv_store (hv, module, src - module, newRV_noinc ((SV *)hash), 0))
              INT_ERR ("insert_modpath_2");

          src = *srcp;
        }

      if (src < end && *src++ != '-')
        croak ("malformed module path (-)");
    }

  *srcp = src;

  return hv;
}

/* for the given path, find the corresponding hash and element name */
static char *
find_path (SV *path, HV **hashp)
{
  char *str = SvPV_nolen (path);
  char *elem = strrchr (str, '/');
  HV *hash;

  if (!elem)
    croak ("non-absolute element path (%s) not supported by find_path", str);

  if (*str == '-')
    {
      hash = GvHV (arguments);
      str++;
    }
  else
    hash = GvHV (state);

  /* unless root module (this is unclean) */
  if (elem != str)
    {
      SV **modhash = hv_fetch (hash, str, elem - str, 1);

      /* create it if necessary */
      if (!SvROK (*modhash) || SvTYPE (SvRV (*modhash)) != SVt_PVHV)
        sv_setsv (*modhash, newRV_noinc ((SV *)newHV ()));

      hash = (HV *)SvRV (*modhash);
    }

  *hashp = hash;
  return elem + 1;
}

#define SURL_SUFFIX	0x41
#define SURL_STYLE	0x42

#define SURL_EXEC_IMMED	0x91

#define SURL_PUSH	0x01
#define SURL_POP	0x81
#define SURL_UNSHIFT	0x02
#define SURL_SHIFT	0x82

static AV *
rv2av(SV *sv)
{
  AV *av;

  if (!sv)
    return 0;
  else if (SvROK (sv))
    av = (AV *)SvRV (sv);
  else if (SvOK (sv))
    av = 0;
  else
    {
      SV *rv;
      av = newAV ();
      rv = newRV_noinc ((SV *)av);
      sv_setsv_mg (sv, rv);
      SvREFCNT_dec (rv);
    }

  if (!av || SvTYPE ((SV *)av) != SVt_PVAV)
    croak ("attempted surl push/unshift to a non-array-reference");

  return av;
}

static SV *
find_keysv (SV *arg, int may_delete)
{
  SV *sv;
  HV *hash;
  char *elem;

  if (SvROK (arg))
    {
      sv = SvRV (arg);
      if (!sv_is_scalar_type (sv))
        croak ("find_keysv: tried to assign scalar to non-scalar reference (2)");
    }
  else if (may_delete && 0) /* optimization removed for agni */
    {
      elem = find_path (arg, &hash);
      /* setting an element to undef may delete it */
      hv_delete (hash, elem, SvEND (arg) - elem, G_DISCARD);
      sv = 0;
    }
  else
    {
      elem = find_path (arg, &hash);
      sv = *hv_fetch (hash, elem, SvEND (arg) - elem, 1);
    }

  return sv;
}

/* do path resolution. not much yet. */
static SV *
expand_path (char *path, STRLEN pathlen, char *cwd, STRLEN cwdlen)
{
  SV *res = newSV (0);

  if (*path == '-')
    {
      sv_catpvn (res, path, 1);
      path++; pathlen--;
    }

  if (*path != '/')
    croak ("relative state paths no longer supported, downgrade to PApp 1.x");

  sv_catpvn (res, path, pathlen);

  return res;
}

#define surl_expand_path(path,pathlen) expand_path ((path), (pathlen), 0, 0)

/* checks wether this surl argument is a single arg (1) or key->value (0) */
/* should be completely pluggable, i.e. by subclassing/calling PApp::SURL->gen */
#define SURL_NOARG(sv) (SvROK (sv) && (sv_isa (sv, "PApp::Callback::Function") \
                                       || sv_isa (sv, "Agni::Callback")))

/*****************************************************************************/

MODULE = PApp		PACKAGE = PApp

BOOT:
{
  cipher_e     = gv_fetchpv ("PApp::cipher_e"    , TRUE, SVt_PV);
  location     = gv_fetchpv ("PApp::location"    , TRUE, SVt_PV);
  big_p        = gv_fetchpv ("PApp::P"           , TRUE, SVt_PV);
  state        = gv_fetchpv ("PApp::state"       , TRUE, SVt_PV);
  arguments    = gv_fetchpv ("PApp::arguments"   , TRUE, SVt_PV);
  userid       = gv_fetchpv ("PApp::userid"      , TRUE, SVt_IV);
  stateid      = gv_fetchpv ("PApp::stateid"     , TRUE, SVt_IV);
  sessionid    = gv_fetchpv ("PApp::sessionid"   , TRUE, SVt_IV);
  surlstyle    = gv_fetchpv ("PApp::surlstyle"   , TRUE, SVt_IV);
}

# the most complex piece of shit
void
surl(...)
	PROTOTYPE: @
        ALIAS:
           salternative = 1
	PPCODE:
{
        int i;
        UV xalternative;
        SV *surl;
        AV *args = newAV ();
        SV *path = 0;
        char *svp; STRLEN svl;
        int style = 1;

        if (SvIOK (GvSV (surlstyle)))
          style = SvIV (GvSV (surlstyle));

        {
          int has_module = items;
          int j;
          for (j = 0; j < items; j++)
            if (SURL_NOARG (ST(j)))
              has_module++;

          has_module &= 1;

          if (has_module)
            croak ("surl no longer supports module arguments, downgrade to PApp 1.x");
        }

        for (; i < items; i++)
          {
            SV *arg = ST(i);

            if (SURL_NOARG (arg))
              {
                /* SURL_EXEC() */
                av_push (args, newSVpvn ("\x00\x01", 2));
                av_push (args, NEWSV (0,0));
                av_push (args, newSVpv ("/papp_execonce", 0));
                av_push (args, SvREFCNT_inc (arg));
              }
            else
              {
                SV *val = ST(i+1);
                i++;

                if (SvROK (arg))
                  {
                    if (!sv_is_scalar_type (SvRV (arg)))
                      croak ("surl: tried to assign scalar to non-scalar reference (e.g. 'surl \\@x => 5')");

                    arg = newSVsv (arg);
                    val = newSVsv (val);
                  }
                else if (SvPOK (arg) && SvCUR (arg) == 2 && !*SvPV_nolen (arg))
                  /* do not expand SURL_xxx constants */
                  {
                    int surlmod = (unsigned char)SvPV_nolen (arg)[1];

                    if (surlmod == SURL_STYLE)
                      {
                        style = SvIV (val);
                        continue;
                      }
                    else if (surlmod == SURL_SUFFIX)
                      {
                        path = val;
                        continue;
                      }
                    else if (surlmod == SURL_EXEC_IMMED)
                      {
                        if (!SvROK (val))
                          croak ("INTERNAL ERROR SURL_EXEC_IMMED");

                        val = newSVsv (SvRV (val));
                      }
                    else if ((surlmod == SURL_POP || surlmod == SURL_SHIFT)
                             && !SvROK (val))
                      {
                        svp = SvPV (val, svl);
                        val = surl_expand_path (svp, svl);
                      }
                    else
                      {
                        val = newSVsv (val);
                      }

                    SvREFCNT_inc (arg);
                  }
                else
                  {
                    svp = SvPV (arg, svl);
                    arg = surl_expand_path (svp, svl);
                    val = newSVsv (val);
                  }

                av_push (args, arg);
                av_push (args, val);
              }
          }

        if (ix == 1)
          {
            /* salternative */
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) args)));
          }
        else
          {
            surl = sv_mortalcopy (GvSV (location));
            sv_catpvn (surl, "/", 1);

            if (style == 3 && GIMME_V != G_ARRAY)
              {
                SvREFCNT_dec (args);
                XPUSHs (surl);
              }
            else
              {
                AV *av;
                SV **he = hv_fetch ((HV *)GvHV (state), "papp_alternative", 16, 0);

                if (!he || !SvROK ((SV *)*he))
                  croak ("$state{papp_alternative} not an arrayref");

                av = (AV *)SvRV ((SV *)*he);
                av_push (av, newRV_noinc ((SV *) args));
                xalternative = av_len (av);

                if (GIMME_V != G_VOID)
                  {
                    uchar key[x64_enclen (16)];
                    int count;
                    UV xuserid    = SvUV (GvSV (userid));
                    UV xstateid   = SvUV (GvSV (stateid));
                    UV xsessionid = SvUV (GvSV (sessionid));

                    key[ 0] = xuserid     ; key[ 1] = xuserid      >> 8; key[ 2] = xuserid      >> 16; key[ 3] = xuserid      >> 24;
                    key[ 4] = xstateid    ; key[ 5] = xstateid     >> 8; key[ 6] = xstateid     >> 16; key[ 7] = xstateid     >> 24;
                    key[ 8] = xalternative; key[ 9] = xalternative >> 8; key[10] = xalternative >> 16; key[11] = xalternative >> 24;
                    key[12] = xsessionid  ; key[13] = xsessionid   >> 8; key[14] = xsessionid   >> 16; key[15] = xsessionid   >> 24;

                    ENTER;
                    PUSHMARK (SP);
                    XPUSHs (GvSV (cipher_e));
                    XPUSHs (sv_2mortal (newSVpvn ((char *)key, 16)));
                    PUTBACK;
                    count = call_method ("encrypt", G_SCALAR);
                    SPAGAIN;

                    assert (count == 1);

                    x64_enc (key, POPp, 16);

                    LEAVE;

                    if (style == 1) /* url */
                      {
                        sv_catpvn (surl, "/", 1);
                        sv_catpvn (surl, key, x64_enclen (16));
                      }
                    else if (style == 2) /* get */
                      {
                        if (path)
                          {
                            sv_catpvn (surl, "/", 1);
                            sv_catsv (surl, path);
                          }

                        sv_catpvn (surl, "?papp=", 6);
                        sv_catpvn (surl, key, x64_enclen (16));
                      }
                    else if (style == 3) /* empty */
                      ;
                    else
                      croak ("illegal surlstyle %d requested", style);

                    XPUSHs (surl);
                    if (style == 3 && GIMME_V == G_ARRAY)
                      XPUSHs (sv_2mortal (newSVpvn (key, x64_enclen (16))));
                  }
              }
          }
}

SV *
expand_path(path, cwd)
	SV	*path
        SV	*cwd
        PROTOTYPE: $$
        CODE:
        STRLEN cwdlen;
        char *cwdp = SvPV (cwd, cwdlen);
        STRLEN pathlen;
        char *pathp = SvPV (path, pathlen);

        RETVAL = expand_path (pathp, pathlen, cwdp, cwdlen);
	OUTPUT:
	RETVAL

# interpret argument => value pairs
void
set_alternative(array)
	SV *	array
        PROTOTYPE: $
        CODE:

        if (!SvROK (array) || SvTYPE (SvRV (array)) != SVt_PVAV)
          croak ("arrayref expected as argument to set_alternative");
        else
          {
            AV *av = (AV *)SvRV (array);
            int len = av_len (av);
            int flags = 0, i = 0;

            if (!(len & 1)) /* odd array length? */
              croak ("odd alternative arrays are no longer supported, downgrade to PApp 1.x");

            while (i < len)
              {
                SV *arg = *av_fetch (av, i++, 1);
                SV *val = *av_fetch (av, i++, 1);

                if (!SvROK (arg) && SvCUR (arg) == 2 && !*SvPV_nolen (arg))
                  {
                    /* SURL_xxx constant */
                    int surlmod = (unsigned char)SvPV_nolen (arg)[1];

                    if (surlmod & 0x80)
                      {
                        if (surlmod == SURL_POP || surlmod == SURL_SHIFT)
                          {
                            AV *av = rv2av (find_keysv (val, 0));

                            if (av && av_len (av) >= 0)
                              {
                                if (surlmod == SURL_POP)
                                  SvREFCNT_dec (av_pop (av));
                                else
                                  SvREFCNT_dec (av_shift (av));
                              }
                          }
                        else if (surlmod == SURL_EXEC_IMMED)
                          {
                            PUSHMARK (SP); PUTBACK;
                            call_sv (val, G_VOID | G_DISCARD);
                            SPAGAIN;
                          }
                        else
                          croak ("set_alternative: unsupported surlmod (%02x)", surlmod);
                      }
                    else
                      flags |= surlmod;
                  }
                else
                  {
                    SV *sv = find_keysv (arg, !flags && !SvOK (val));

                    if (sv)
                      {
                        int arrayop = flags & 3;

                        if (arrayop)
                          {
                            AV *av = rv2av (sv);

                            if (arrayop == SURL_PUSH)
                              av_push (av, SvREFCNT_inc (val));
                            else if (arrayop == SURL_UNSHIFT)
                              {
                                av_unshift (av, 1);
                                if (!av_store (av, 0, SvREFCNT_inc (val)))
                                  SvREFCNT_dec (val);
                              }
                            else
                              croak ("illegal arrayop in set_alternative");
                          }
                        else
                          sv_setsv_mg (sv, val);
                      }

                    flags = 0;
                  }
              }
          }

void
find_path (path)
	SV *	path
        PROTOTYPE: $
        PPCODE:
        HV *hash;
        char *elem = find_path (path, &hash);

        EXTEND (SP, 2);
        PUSHs (sv_2mortal (newRV_inc ((SV *)hash)));
        PUSHs (sv_2mortal (newSVpv (elem, 0)));

SV *
modpath_freeze(modules)
	SV * modules
        PROTOTYPE: $
        CODE:
        RETVAL = modpath_freeze (modules);
	OUTPUT:
        RETVAL

SV *
modpath_thaw(modulepath)
	SV * modulepath
        PROTOTYPE: $
        CODE:
        char *src, *end;
        STRLEN dc;
        
        src = SvPV (modulepath, dc);
        end = src + dc;

        RETVAL = newRV_noinc ((SV *)modpath_thaw (&src, end));
	OUTPUT:
        RETVAL

# destroy %P, %S and %state, but do not call DESTROY
# TODO: why %P here and not in update_state?
void
_destroy_state()
	CODE:
        HV *hv = PL_defstash;
        PL_defstash = 0;
        hv_clear (GvHV (state));
        PL_defstash = hv;
        hv_clear (GvHV (big_p));

void
_set_params(...)
        CODE:
        int i;
        HV *hv = GvHV (big_p);

        for (i = 1; i < items; i += 2)
          {
            STRLEN klen;
            char *key = SvPV (ST(i-1), klen);
            SV *val = SvREFCNT_inc (ST(i));
            SV **ent = hv_fetch (hv, key, klen, 0);

            if (ent)
              {
                if (SvROK (*ent))
                  av_push ((AV *)SvRV (*ent), val);
                else
                  {
                    AV *av = newAV ();

                    av_push (av, *ent);
                    av_push (av, val);

                    *ent =  newRV_noinc ((SV *)av);
                  }
              }
            else
              hv_store (hv, key, klen, val, 0);
          }

MODULE = PApp		PACKAGE = PApp::Util

void
_exit(code=0)
	int	code
        CODE:
#if _POSIX_SOURCE
        _exit (code);
#else
        exit (code);
#endif

char *
sv_peek(sv)
	SV *	sv
        PROTOTYPE: $
        CODE:
        RETVAL = sv_peek (sv);
	OUTPUT:
	RETVAL

void
sv_dump(sv)
	SV *	sv
        PROTOTYPE: $
        CODE:
        sv_dump (SvROK (sv) ? SvRV (sv) : sv);

void
filter_add(cb)
	SV *	cb
        PROTOTYPE: $
        CODE:
        SV *datasv = NEWSV (0,0);

        SvUPGRADE (datasv, SVt_PVIO);
        IoBOTTOM_GV (datasv) = (GV *)newSVsv (cb);
        filter_add (papp_filter_read, datasv);

I32
filter_read(idx, sv, maxlen)
	int	idx
	SV *	sv
        int	maxlen
	CODE:
        RETVAL = FILTER_READ (idx, sv, maxlen);
        OUTPUT:
        RETVAL

MODULE = PApp		PACKAGE = PApp::X64

BOOT:
{
  unsigned char c;

  for (c = 0; c < 64; c++)
    d64[e64[c]] = c;
}

PROTOTYPES: ENABLE

SV *
enc(data)
	SV *	data
        CODE:
{
        STRLEN len;
        uchar *src = (uchar *) SvPV (data, len);
        uchar *dst;

        RETVAL = NEWSV (0, x64_enclen(len));
        SvPOK_only (RETVAL);
        SvCUR_set (RETVAL, x64_enclen(len));
        dst = (uchar *)SvPV_nolen (RETVAL);

        x64_enc (dst, src, len);
}
	OUTPUT:
        RETVAL

SV *
dec(data)
	SV *	data
        CODE:
{
        STRLEN len;
        uchar a, b, c, d;
        uchar *src = (uchar *) SvPV (data, len);
        uchar *dst;

        RETVAL = NEWSV (0, len * 3 / 4 + 5);
        SvPOK_only (RETVAL);
        SvCUR_set (RETVAL, len * 3 / 4);
        dst = (uchar *)SvPV_nolen (RETVAL);

        while (len >= 4)
          {
            a = d64[*src++];
            b = d64[*src++];
            c = d64[*src++];
            d = d64[*src++];

            *dst++ = ((b << 2) & 0xc0) | a;
            *dst++ = ((c << 2) & 0xf0) | (b & 0x0f);
            *dst++ = ((d << 2) & 0xfc) | (c & 0x03);

            len -= 4;
          }

        switch (len)
          {
            case 3:
              a = d64[*src++];
              b = d64[*src++];
              c = d64[*src++];

              *dst++ = ((b << 2) & 0xc0) | a;
              *dst++ = ((c << 2) & 0xf0) | (b & 0x0f);
              break;
            case 2:
              a = d64[*src++];
              b = d64[*src++];

              *dst++ = ((b << 2) & 0xc0) | a;
              break;
            case 1:
              croak ("x64-encoded string malformed");
              abort ();
            case 0:
              break;
          }
}
	OUTPUT:
        RETVAL

MODULE = PApp		PACKAGE = Agni

#if UVSIZE == 8

UV
bit64(UV a)
        PROTOTYPE: $
        CODE:
        RETVAL = 1 << a;
        OUTPUT:
	RETVAL

UV
not64(UV a)
        PROTOTYPE: $
        CODE:
        RETVAL = ~a;
        OUTPUT:
	RETVAL

UV
and64 (UV a, UV b)
        PROTOTYPE: $$
        CODE:
        RETVAL = a & b;
        OUTPUT:
	RETVAL

UV
or64 (UV a, UV b)
        PROTOTYPE: $$
        CODE:
        RETVAL = a | b;
        OUTPUT:
	RETVAL

UV
andnot64 (UV a, UV b)
        PROTOTYPE: $$
        CODE:
        RETVAL =  a & ~b;
        OUTPUT:
	RETVAL

#else

char *
not64 (char *a)
        PROTOTYPE: $
        ALIAS:
           bit64 = 1
        CODE:
        unsigned long long a_, c_;
        char c[64];

        a_ = strtoull (a, 0, 0);

        c_ = ix == 0 ? ~a_
           : ix == 1 ? 1 << a_
           :           -1;

        sprintf (c, "%llu", c_);
        
        RETVAL = c;
        OUTPUT:
	RETVAL

char *
and64 (char *a, char *b)
        PROTOTYPE: $$
        ALIAS:
           or64     = 1
           andnot64 = 2
        CODE:
        unsigned long long a_, b_, c_;
        char c[64];

        a_ = strtoull (a, 0, 0);
        b_ = strtoull (b, 0, 0);

        c_ = ix == 0 ? a_ & b_
           : ix == 1 ? a_ | b_
           : ix == 2 ? a_ & ~b_
           :           -1;

        sprintf (c, "%llu", c_);
        
        RETVAL = c;
        OUTPUT:
	RETVAL

#endif

char *
unpack64(sv)
        SV *sv;
        PROTOTYPE: $
        ALIAS:
           unpack64_le = 1
           unpack64_be = 2
        CODE:
        char buf[64];
        STRLEN len;
        char *v = SvPV (sv, len);
        char *p = v;

        if (len < 8)
          XSRETURN_UNDEF;
#if BYTEORDER == 0x4321 || BYTEORDER == 0x87654321
        if(ix == 1)
#else
        if(ix == 2)
#endif
        {
          char t;
          p = &buf[16];
          buf[16] = v[7];
          buf[17] = v[6];
          buf[18] = v[5];
          buf[19] = v[4];
          buf[20] = v[3];
          buf[21] = v[2];
          buf[22] = v[1];
          buf[23] = v[0];
        }
        sprintf(buf, "%llu", *((unsigned long long *) p));

        RETVAL = buf;
        OUTPUT:
        RETVAL

SV *
pack64(v)
        char *v;
        PROTOTYPE: $
        ALIAS:
           pack64_le = 1
           pack64_be = 2
        CODE:
        uchar buf[8];

        pack64 (buf, v, ix);

        RETVAL = newSVpvn(buf, 8);
        OUTPUT:
        RETVAL

BOOT:
	compute_hash (CACHEp   , CACHEl   , &CACHEs   , &CACHEh);
	compute_hash (TYPEp    , TYPEl    , &TYPEs    , &TYPEh);
	compute_hash (ATTRp    , ATTRl    , &ATTRs    , &ATTRh);
	compute_hash (PATHp    , PATHl    , &PATHs    , &PATHh);
	compute_hash (GIDp     , GIDl     , &GIDs     , &GIDh);
	compute_hash (INSTANCEp, INSTANCEl, &INSTANCEs, &INSTANCEh);

SV *
agnibless(SV *rv, char *classname)
        CODE:
        HV *hv = (HV *)SvRV (rv);

        sv_unmagic ((SV *)hv, PERL_MAGIC_tied);

        RETVAL = newSVsv (sv_bless (rv, gv_stashpv(classname, TRUE)));

        if (!hv_fetch_ent (hv, ATTRs, 0, ATTRh))
          hv_store_ent (hv, ATTRs, newRV_noinc ((SV *)newHV ()), ATTRh);

        if (!hv_fetch_ent (hv, TYPEs, 0, TYPEh))
          hv_store_ent (hv, TYPEs, newRV_noinc ((SV *)newHV ()), TYPEh);

        if (!hv_fetch_ent (hv, CACHEs, 0, CACHEh))
          hv_store_ent (hv, CACHEs, newRV_noinc ((SV *)newHV ()), CACHEh);

        sv_magicext ((SV *)hv, Nullsv, PERL_MAGIC_tied, &vtbl_agni_object, Nullch, 0);

        OUTPUT:
        RETVAL

void
rmagical_off(SV *rv)
	ALIAS:
          rmagical_on = 1
	CODE:
        if (ix)
          SvRMAGICAL_on (SvRV (rv));
        else
          SvRMAGICAL_off (SvRV (rv));

void
isobject(SV *rv)
	CODE:
        if (sv_isobject (rv))
          XSRETURN_YES;
        else
          XSRETURN_NO;

void
obj_of (SV *ref)
	PROTOTYPE: $
	PPCODE:

        if (SvROK (ref) && SvMAGICAL (SvRV (ref)))
          {
            MAGIC *mg = mg_find (SvRV (ref), PERL_MAGIC_tiedelem);

            if (mg && mg->mg_obj)
              {
                XPUSHs (newSVsv (mg->mg_obj));
                XSRETURN (1);
              }
          }

        XPUSHs (&PL_sv_undef);
        XSRETURN (1);

SV *
_data_special_key (SV *self, SV *obj)
	CODE:
        if (sv_isobject (self) && sv_isobject (obj))
          {
            uchar k[8+8];

            HV *shv = (HV *)SvRV (self);

            SvRMAGICAL_off (shv);
            pack64 (k, SvPV_nolen (HeVAL (hv_fetch_ent (shv, GIDs, 0, GIDh))), 2);
            SvRMAGICAL_on (shv);

            if (SvTRUE (HeVAL (hv_fetch_ent (shv, INSTANCEs, 0, INSTANCEh))))
              {
                HV *ohv = (HV *)SvRV (obj);
                
                SvRMAGICAL_off (ohv);
                pack64 (k + 8, SvPV_nolen (HeVAL (hv_fetch_ent (ohv, GIDs, 0, GIDh))), 2);
                SvRMAGICAL_on (ohv);

                RETVAL = newSVpvn (k, 16);
              }
            else
              {
                RETVAL = newSVpvn (k, 8);
              }
          }
        else
          croak ("_data_special_key must be called with two references");

	OUTPUT:
        RETVAL

MODULE = PApp		PACKAGE = agni::object

void
DESTROY(SV *rv)
	CODE:
        /* turn magic off before destruction, to ease perls job */
        SvRMAGICAL_off (SvRV (rv));

void
FETCH(SV *self, SV *key)
        PPCODE:
        agni_try_patch (Perl_pp_helem, agni_fetch_op);
{
        SV *ret;
        PUTBACK;
        ret = agni_fetch (self, key);
        SPAGAIN;
        if (ret)
          XPUSHs (ret);
}

void
STORE(SV *self, SV *key, SV *value)
        PPCODE:
        /*agni_try_patch (Perl_pp_helem, agni_store_op);*/
        PUTBACK;
        agni_store (self, key, value);
        SPAGAIN;

void
EXISTS(SV *self, SV *key)
        PPCODE:
        HV *hv = (HV*) SvRV (self);
        HV *hvt;
        char *key_ = SvPV_nolen (key);
        
        SvRMAGICAL_off (hv);

        /* check _-keys in $self and non-_-keys in $self->{_type} */
        if (key_[0] == '_')
          hvt = hv;
        else if (key_[0] >= '1' && key_[0] <= '9')
          hvt = (HV *)SvRV (*(hv_fetch (hv, ATTRp, ATTRl, 0)));
        else
          hvt = (HV *)SvRV (*(hv_fetch (hv, TYPEp, TYPEl, 0)));

        XPUSHs (sv_2mortal (newSViv (hv_exists_ent (hvt, key, 0))));

        SvRMAGICAL_on (hv);

void
DELETE(SV *self, SV *key)
        PPCODE:
        HV *hv = (HV*) SvRV (self);
        char *key_ = SvPV_nolen (key);
        SV *value;
        
        SvRMAGICAL_off (hv);

        if (key_[0] != '_' || 1)
          {
            value = hv_delete_ent (hv, key, 0, 0);

            if (value)
              XPUSHs (value);
          }

        SvRMAGICAL_on (hv);

void
NEXTKEY(self, ...)
	SV *	self
        ALIAS:
          FIRSTKEY = 1
        PPCODE:
        HV *hv = (HV*) SvRV (self);
        HV *hvt;
        HE *he;

        SvRMAGICAL_off (hv);

        hvt = (HV *)SvRV (*(hv_fetch (hv, TYPEp, TYPEl, 0)));

        if (ix)
          hv_iterinit (hvt);

        he = hv_iternext (hvt);

        if (he)
          XPUSHs (hv_iterkeysv (he));

        SvRMAGICAL_on (hv);


