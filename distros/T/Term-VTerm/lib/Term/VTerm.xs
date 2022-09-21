/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2014-2020 -- leonerd@leonerd.org.uk
 */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <vterm.h>

#include <string.h>

#ifdef HAVE_DMD_HELPER
#  define WANT_DMD_API_044
#  include "DMD_helper.h"
#endif

#define streq(a,b)  (!strcmp(a,b))

#define FREE_CB(v)  if(self->v) SvREFCNT_dec(self->v)

#ifdef tTHX
#  define dTHXa_FROM_SELF   dTHXa(self->myperl)
#else
#  define dTHXa_FROM_SELF
#endif

typedef struct Term__VTerm {
#ifdef tTHX
  tTHX myperl;
#endif
  VTerm *vt;

  struct {
    CV *text;
    CV *control;
    CV *escape;
    CV *csi;
    CV *osc;
    CV *dcs;
    CV *resize;
  } parser_cb;

  SV *strbuf;

} *Term__VTerm;

typedef VTermColor      *Term__VTerm__Color;
typedef VTermGlyphInfo  *Term__VTerm__GlyphInfo;
typedef VTermLineInfo   *Term__VTerm__LineInfo;
typedef VTermPos        *Term__VTerm__Pos;
typedef VTermRect       *Term__VTerm__Rect;
typedef VTermScreenCell *Term__VTerm__Screen__Cell;

typedef struct Term__VTerm__State {
#ifdef tTHX
  tTHX myperl;
#endif
  VTermState *state;
  SV         *vterm;

  int has_selection_cb : 1;

  struct {
    CV *putglyph;
    CV *movecursor;
    CV *scrollrect;
    CV *moverect;
    CV *erase;
    CV *initpen;
    CV *setpenattr;
    CV *settermprop;
    CV *bell;
    CV *resize;
    CV *setlineinfo;

    CV *selection_set;
    CV *selection_query;
  } cb;
} *Term__VTerm__State;

typedef struct Term__VTerm__Screen {
#ifdef tTHX
  tTHX myperl;
#endif
  VTermScreen *screen;
  SV          *vterm;

  struct {
    CV *damage;
    CV *moverect;
    CV *movecursor;
    CV *settermprop;
    CV *bell;
    CV *resize;
  } cb;
} *Term__VTerm__Screen;

#ifdef HAVE_DMD_HELPER
static int dmd_helper_vterm(pTHX_ DMDContext *ctx, const SV *sv)
{
  Term__VTerm self = INT2PTR(Term__VTerm, SvIV((SV *)sv));
  int ret = 0;

  if(self->parser_cb.text)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->parser_cb.text, "the 'text' parser callback");
  if(self->parser_cb.control)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->parser_cb.control, "the 'control' parser callback");
  if(self->parser_cb.escape)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->parser_cb.escape, "the 'escape' parser callback");
  if(self->parser_cb.csi)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->parser_cb.csi, "the 'csi' parser callback");
  if(self->parser_cb.osc)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->parser_cb.osc, "the 'osc' parser callback");
  if(self->parser_cb.dcs)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->parser_cb.dcs, "the 'dcs' parser callback");
  if(self->parser_cb.resize)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->parser_cb.resize, "the 'resize' parser callback");

  if(self->strbuf)
    ret += DMD_ANNOTATE_SV(sv, self->strbuf, "the temporary string buffer");

  return ret;
}

static int dmd_helper_vterm_state(pTHX_ DMDContext *ctx, const SV *sv)
{
  Term__VTerm__State self = INT2PTR(Term__VTerm__State, SvIV((SV *)sv));
  int ret = 0;

  if(self->vterm)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->vterm, "the vterm SV");

  if(self->cb.putglyph)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->cb.putglyph, "the 'putglyph' callback");
  if(self->cb.movecursor)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->cb.movecursor, "the 'movecursor' callback");
  if(self->cb.scrollrect)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->cb.scrollrect, "the 'scrollrect' callback");
  if(self->cb.moverect)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->cb.moverect, "the 'moverect' callback");
  if(self->cb.erase)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->cb.erase, "the 'erase' callback");
  if(self->cb.initpen)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->cb.initpen, "the 'initpen' callback");
  if(self->cb.setpenattr)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->cb.setpenattr, "the 'setpenattr' callback");
  if(self->cb.settermprop)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->cb.settermprop, "the 'settermprop' callback");
  if(self->cb.bell)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->cb.bell, "the 'bell' callback");
  if(self->cb.resize)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->cb.resize, "the 'resize' callback");
  if(self->cb.setlineinfo)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->cb.setlineinfo, "the 'setlineinfo' callback");

  return ret;
}

static int dmd_helper_vterm_screen(pTHX_ DMDContext *ctx, const SV *sv)
{
  Term__VTerm__Screen self = INT2PTR(Term__VTerm__Screen, SvIV((SV *)sv));
  int ret = 0;

  if(self->vterm)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->vterm, "the vterm SV");

  if(self->cb.damage)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->cb.damage, "the 'damage' callback");
  if(self->cb.moverect)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->cb.moverect, "the 'moverect' callback");
  if(self->cb.movecursor)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->cb.movecursor, "the 'movecursor' callback");
  if(self->cb.settermprop)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->cb.settermprop, "the 'settermprop' callback");
  if(self->cb.bell)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->cb.bell, "the 'bell' callback");
  if(self->cb.resize)
    ret += DMD_ANNOTATE_SV(sv, (const SV *)self->cb.resize, "the 'resize' callback");

  return ret;
}
#endif

#define newSVcolor(col)  S_newSVcolor(aTHX_ col)
static SV *S_newSVcolor(pTHX_ VTermColor *col)
{
  VTermColor *self;
  SV *sv = newSV(0);

  Newx(self, 1, VTermColor);
  *self = *col;

  sv_setref_pv(sv, "Term::VTerm::Color", self);
  return sv;
}

#define newSVlineinfo(info)  S_newSVlineinfo(aTHX_ info)
static SV *S_newSVlineinfo(pTHX_ const VTermLineInfo *info)
{
  VTermLineInfo *self;
  SV *sv = newSV(0);

  Newx(self, 1, VTermLineInfo);
  *self = *info;

  sv_setref_pv(sv, "Term::VTerm::LineInfo", self);
  return sv;
}

#define newSVglyphinfo(info)  S_newSVglyphinfo(aTHX_ info)
static SV *S_newSVglyphinfo(pTHX_ VTermGlyphInfo *info)
{
  VTermGlyphInfo *self;
  SV *sv = newSV(0);
  int nchars, i;

  for(nchars = 0; info->chars[nchars]; nchars++)
    ;
  nchars++; // include the terminating NUL

  Newxc(self, sizeof(VTermGlyphInfo) + nchars * sizeof(uint32_t), char, VTermGlyphInfo);
  *self = *info;
  self->chars = (uint32_t *)(((char *)self) + sizeof(VTermGlyphInfo));

  for(i = 0; i < nchars; i++)
    // This is our own glyphinfo so we're allowed to write it. Honest gov
    ((uint32_t *)self->chars)[i] = info->chars[i];

  sv_setref_pv(sv, "Term::VTerm::GlyphInfo", self);
  return sv;
}

#define newSVpos(pos)  S_newSVpos(aTHX_ pos)
static SV *S_newSVpos(pTHX_ VTermPos pos)
{
  VTermPos *self;
  SV *sv = newSV(0);

  Newx(self, 1, VTermPos);
  *self = pos;

  sv_setref_pv(sv, "Term::VTerm::Pos", self);
  return sv;
}

#define newSVrect(rect)  S_newSVrect(aTHX_ rect)
static SV *S_newSVrect(pTHX_ VTermRect rect)
{
  VTermRect *self;
  SV *sv = newSV(0);

  Newx(self, 1, VTermRect);
  *self = rect;

  sv_setref_pv(sv, "Term::VTerm::Rect", self);
  return sv;
}

#define newSVscreencell(cell)  S_newSVscreencell(aTHX_ cell)
static SV *S_newSVscreencell(pTHX_ VTermScreenCell cell)
{
  VTermScreenCell *self;
  SV *sv = newSV(0);

  Newx(self, 1, VTermScreenCell);
  *self = cell;

  sv_setref_pv(sv, "Term::VTerm::Screen::Cell", self);
  return sv;
}

#define newSVvalue(val, type)  S_newSVvalue(aTHX_ val, type)
static SV *S_newSVvalue(pTHX_ VTermValue *val, VTermValueType type)
{
  switch(type) {
    case VTERM_VALUETYPE_BOOL:
      return val->boolean ? &PL_sv_yes : &PL_sv_no;
    case VTERM_VALUETYPE_INT:
      return newSViv(val->number);
    case VTERM_VALUETYPE_COLOR:
      return newSVcolor(&val->color);

    case VTERM_VALUETYPE_STRING:
      croak("ARGH should never invoke newSVvalue() on type=VTERM_VALUETYPE_STRING");
  }
}

static int parser_text(const char *bytes, size_t len, void *user)
{
  Term__VTerm self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->parser_cb.text;

  SV *str = newSVpv(bytes, len);
  if(vterm_get_utf8(self->vt))
    SvUTF8_on(str);

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 1);
  mPUSHs(str);
  PUTBACK;

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return len;
}

static int parser_control(unsigned char control, void *user)
{
  Term__VTerm self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->parser_cb.control;

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 1);
  mPUSHi(control);
  PUTBACK;

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return 1;
}

static int parser_escape(const char *bytes, size_t len, void *user)
{
  Term__VTerm self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->parser_cb.escape;

  SV *str = newSVpv(bytes, len);

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 1);
  mPUSHs(str);
  PUTBACK;

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return len;
}

static int parser_csi(const char *leader, const long args[], int argcount, const char *intermed, char command, void *user)
{
  Term__VTerm self = user;
  dTHXa_FROM_SELF;
  dSP;
  int i;
  CV *cb = self->parser_cb.csi;

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);

  if(leader && *leader)
    mPUSHp(leader, 1);
  else
    PUSHs(&PL_sv_undef);

  mPUSHp(&command, 1);

  for(i = 0; i < argcount; i++) {
    AV *av = newAV();
    for( ; i < argcount; i++) {
      av_push(av, CSI_ARG_IS_MISSING(args[i]) ?
        &PL_sv_undef :
        newSViv(CSI_ARG(args[i])));

      if(!CSI_ARG_HAS_MORE(args[i]))
        break;
    }

    mXPUSHs(newRV((SV*)av));
  }

  PUTBACK;

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return 1;
}

static int parser_osc(int command, VTermStringFragment frag, void *user)
{
  Term__VTerm self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->parser_cb.osc;

  if(!cb)
    return 0;

  if(frag.initial)
    SvCUR_set(self->strbuf, 0);
  if(frag.len)
    sv_catpvn(self->strbuf, frag.str, frag.len);
  if(!frag.final)
    return 1;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  mPUSHi(command);
  PUSHs(self->strbuf);
  PUTBACK;

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return 1;
}

static int parser_dcs(const char *command, size_t commandlen, VTermStringFragment frag, void *user)
{
  Term__VTerm self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->parser_cb.dcs;

  if(!cb)
    return 0;

  if(frag.initial)
    SvCUR_set(self->strbuf, 0);
  if(frag.len)
    sv_catpvn(self->strbuf, frag.str, frag.len);
  if(!frag.final)
    return 1;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  mPUSHp(command, commandlen);
  PUSHs(self->strbuf);
  PUTBACK;

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return 1;
}

static int parser_resize(int rows, int cols, void *user)
{
  Term__VTerm self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->parser_cb.resize;

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  mPUSHi(rows);
  mPUSHi(cols);
  PUTBACK;

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;
}

static const VTermParserCallbacks parser_cbs = {
  .text    = parser_text,
  .control = parser_control,
  .escape  = parser_escape,
  .csi     = parser_csi,
  .osc     = parser_osc,
  .dcs     = parser_dcs,
  .resize  = parser_resize,
};

static int state_putglyph(VTermGlyphInfo *info, VTermPos pos, void *user)
{
  Term__VTerm__State self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->cb.putglyph;

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  mPUSHs(newSVglyphinfo(info));
  mPUSHs(newSVpos(pos));
  PUTBACK;

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return 1;
}

static int state_movecursor(VTermPos pos, VTermPos oldpos, int visible, void *user)
{
  Term__VTerm__State self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->cb.movecursor;

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 3);
  mPUSHs(newSVpos(pos));
  mPUSHs(newSVpos(oldpos));
  mPUSHi(visible);
  PUTBACK;

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return 1;
}

static int state_scrollrect(VTermRect rect, int downward, int rightward, void *user)
{
  Term__VTerm__State self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->cb.scrollrect;
  int ret;

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 3);
  mPUSHs(newSVrect(rect));
  mPUSHi(downward);
  mPUSHi(rightward);
  PUTBACK;

  call_sv((SV*)cb, G_SCALAR);

  SPAGAIN;

  ret = POPi;

  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

static int state_moverect(VTermRect dest, VTermRect src, void *user)
{
  Term__VTerm__State self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->cb.moverect;

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  mPUSHs(newSVrect(dest));
  mPUSHs(newSVrect(src));
  PUTBACK;

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return 1;
}

static int state_erase(VTermRect rect, int selective, void *user)
{
  Term__VTerm__State self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->cb.erase;

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  mPUSHs(newSVrect(rect));
  mPUSHi(selective);
  PUTBACK;

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return 1;
}

static int state_initpen(void *user)
{
  Term__VTerm__State self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->cb.initpen;

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return 1;
}

static int state_setpenattr(VTermAttr attr, VTermValue *val, void *user)
{
  Term__VTerm__State self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->cb.setpenattr;

  if(!cb)
    return 0;

  /* pen attrs are never VTERM_VALUETYPE_STRING */

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  mPUSHi(attr);
  mPUSHs(newSVvalue(val, vterm_get_attr_type(attr)));
  PUTBACK;

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return 1;
}

static int state_settermprop(VTermProp prop, VTermValue *val, void *user)
{
  Term__VTerm__State self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->cb.settermprop;
  VTermValueType type = vterm_get_prop_type(prop);
  SV *strbuf;

  if(!cb)
    return 0;

  if(type == VTERM_VALUETYPE_STRING) {
    strbuf = (INT2PTR(Term__VTerm, SvIV(SvRV(self->vterm))))->strbuf;

    if(val->string.initial)
      SvCUR_set(strbuf, 0);
    if(val->string.len)
      sv_catpvn(strbuf, val->string.str, val->string.len);
    if(!val->string.final)
      return 1;
  }

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  mPUSHi(prop);
  if(type == VTERM_VALUETYPE_STRING)
    PUSHs(strbuf);
  else
    mPUSHs(newSVvalue(val, type));
  PUTBACK;

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return 1;
}

static int state_bell(void *user)
{
  Term__VTerm__State self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->cb.bell;

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return 1;
}

static int state_setlineinfo(int row, const VTermLineInfo *info, const VTermLineInfo *oldinfo, void *user)
{
  Term__VTerm__State self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->cb.setlineinfo;
  int ret;

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 3);
  mPUSHi(row);
  mPUSHs(newSVlineinfo(info));
  mPUSHs(newSVlineinfo(oldinfo));
  PUTBACK;

  call_sv((SV*)cb, G_SCALAR);

  SPAGAIN;

  ret = POPi;

  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

static const VTermStateCallbacks state_cbs = {
  .putglyph    = state_putglyph,
  .movecursor  = state_movecursor,
  .scrollrect  = state_scrollrect,
  .moverect    = state_moverect,
  .erase       = state_erase,
  .initpen     = state_initpen,
  .setpenattr  = state_setpenattr,
  .settermprop = state_settermprop,
  .bell        = state_bell,
  .setlineinfo = state_setlineinfo,
};

static int state_selection_set(VTermSelectionMask mask, VTermStringFragment frag, void *user)
{
  Term__VTerm__State self = user;
  dTHXa_FROM_SELF;
  SV *strbuf;
  dSP;
  CV *cb = self->cb.selection_set;
  int ret;

  if(!cb)
    return 0;

  strbuf = (INT2PTR(Term__VTerm, SvIV(SvRV(self->vterm))))->strbuf;

  if(frag.initial)
    SvCUR_set(strbuf, 0);
  if(frag.len)
    sv_catpvn(strbuf, frag.str, frag.len);
  if(!frag.final)
    return 1;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  mPUSHi(mask);
  PUSHs(strbuf);
  PUTBACK;

  call_sv((SV*)cb, G_SCALAR);

  SPAGAIN;

  ret = POPi;

  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

static int state_selection_query(VTermSelectionMask mask, void *user)
{
  Term__VTerm__State self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->cb.selection_query;
  int ret;

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 1);
  mPUSHi(mask);
  PUTBACK;

  call_sv((SV*)cb, G_SCALAR);

  SPAGAIN;

  ret = POPi;

  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

static const VTermSelectionCallbacks state_selection_cbs = {
  .set   = state_selection_set,
  .query = state_selection_query,
};

static int screen_damage(VTermRect rect, void *user)
{
  Term__VTerm__Screen self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->cb.damage;
  SV *retsv;
  int ret;

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 1);
  mPUSHs(newSVrect(rect));
  PUTBACK;

  call_sv((SV*)cb, G_SCALAR);

  SPAGAIN;

  // TODO: This can raise 'Use of uninitialised value in subroutine entry' warnings
  retsv = POPs;
  if(!SvOK(retsv))
    Perl_warn(aTHX_ "Term::VTerm::Screen on_damage callback returned undef");
  else
    ret = SvIV(retsv);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

static int screen_moverect(VTermRect dest, VTermRect src, void *user)
{
  Term__VTerm__Screen self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->cb.moverect;

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  mPUSHs(newSVrect(dest));
  mPUSHs(newSVrect(src));
  PUTBACK;

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return 1;
}

static int screen_movecursor(VTermPos pos, VTermPos oldpos, int visible, void *user)
{
  Term__VTerm__Screen self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->cb.movecursor;

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 3);
  mPUSHs(newSVpos(pos));
  mPUSHs(newSVpos(oldpos));
  mPUSHi(visible);
  PUTBACK;

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return 1;
}

static int screen_settermprop(VTermProp prop, VTermValue *val, void *user)
{
  Term__VTerm__Screen self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->cb.settermprop;
  VTermValueType type = vterm_get_prop_type(prop);
  SV *strbuf;

  if(!cb)
    return 0;

  if(type == VTERM_VALUETYPE_STRING) {
    strbuf = (INT2PTR(Term__VTerm, SvIV(SvRV(self->vterm))))->strbuf;

    if(val->string.initial)
      SvCUR_set(strbuf, 0);
    if(val->string.len)
      sv_catpvn(strbuf, val->string.str, val->string.len);
    if(!val->string.final)
      return 1;
  }

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  mPUSHi(prop);
  if(type == VTERM_VALUETYPE_STRING)
    PUSHs(strbuf);
  else
    mPUSHs(newSVvalue(val, type));
  PUTBACK;

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return 1;
}

static int screen_bell(void *user)
{
  Term__VTerm__Screen self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->cb.bell;

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;

  return 1;
}

static int screen_resize(int rows, int cols, void *user)
{
  Term__VTerm__Screen self = user;
  dTHXa_FROM_SELF;
  dSP;
  CV *cb = self->cb.resize;

  if(!cb)
    return 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  mPUSHi(rows);
  mPUSHi(cols);
  PUTBACK;

  call_sv((SV*)cb, G_VOID);

  FREETMPS;
  LEAVE;
}

static const VTermScreenCallbacks screen_cbs = {
  .damage      = screen_damage,
  .moverect    = screen_moverect,
  .movecursor  = screen_movecursor,
  .settermprop = screen_settermprop,
  .bell        = screen_bell,
  .resize      = screen_resize,
};

static void S_setup_constants(pTHX)
{
  HV *stash  = gv_stashpvn("Term::VTerm", 11, TRUE);
  AV *export = get_av("Term::VTerm::EXPORT_OK", TRUE);

#define DO_CONSTANT(c) \
  newCONSTSUB(stash, #c+6, newSViv(c)); \
  av_push(export, newSVpv(#c+6, 0));

  DO_CONSTANT(VTERM_VALUETYPE_BOOL);
  DO_CONSTANT(VTERM_VALUETYPE_INT);
  DO_CONSTANT(VTERM_VALUETYPE_STRING);
  DO_CONSTANT(VTERM_VALUETYPE_COLOR);

  DO_CONSTANT(VTERM_ATTR_BOLD);
  DO_CONSTANT(VTERM_ATTR_UNDERLINE);
  DO_CONSTANT(VTERM_ATTR_ITALIC);
  DO_CONSTANT(VTERM_ATTR_BLINK);
  DO_CONSTANT(VTERM_ATTR_REVERSE);
  DO_CONSTANT(VTERM_ATTR_STRIKE);
  DO_CONSTANT(VTERM_ATTR_FONT);
  DO_CONSTANT(VTERM_ATTR_FOREGROUND);
  DO_CONSTANT(VTERM_ATTR_BACKGROUND);
  DO_CONSTANT(VTERM_ATTR_SMALL);
  DO_CONSTANT(VTERM_ATTR_BASELINE);

  DO_CONSTANT(VTERM_BASELINE_NORMAL);
  DO_CONSTANT(VTERM_BASELINE_RAISE);
  DO_CONSTANT(VTERM_BASELINE_LOWER);

  DO_CONSTANT(VTERM_PROP_CURSORVISIBLE);
  DO_CONSTANT(VTERM_PROP_CURSORBLINK);
  DO_CONSTANT(VTERM_PROP_ALTSCREEN);
  DO_CONSTANT(VTERM_PROP_TITLE);
  DO_CONSTANT(VTERM_PROP_ICONNAME);
  DO_CONSTANT(VTERM_PROP_REVERSE);
  DO_CONSTANT(VTERM_PROP_CURSORSHAPE);
  DO_CONSTANT(VTERM_PROP_MOUSE);

  DO_CONSTANT(VTERM_PROP_CURSORSHAPE_BLOCK);
  DO_CONSTANT(VTERM_PROP_CURSORSHAPE_UNDERLINE);
  DO_CONSTANT(VTERM_PROP_CURSORSHAPE_BAR_LEFT);

  DO_CONSTANT(VTERM_PROP_MOUSE_NONE);
  DO_CONSTANT(VTERM_PROP_MOUSE_CLICK);
  DO_CONSTANT(VTERM_PROP_MOUSE_DRAG);
  DO_CONSTANT(VTERM_PROP_MOUSE_MOVE);

  DO_CONSTANT(VTERM_MOD_SHIFT);
  DO_CONSTANT(VTERM_MOD_CTRL);
  DO_CONSTANT(VTERM_MOD_ALT);

  DO_CONSTANT(VTERM_DAMAGE_CELL);
  DO_CONSTANT(VTERM_DAMAGE_ROW);
  DO_CONSTANT(VTERM_DAMAGE_SCREEN);
  DO_CONSTANT(VTERM_DAMAGE_SCROLL);

  DO_CONSTANT(VTERM_KEY_ENTER);
  DO_CONSTANT(VTERM_KEY_TAB);
  DO_CONSTANT(VTERM_KEY_BACKSPACE);
  DO_CONSTANT(VTERM_KEY_ESCAPE);
  DO_CONSTANT(VTERM_KEY_UP);
  DO_CONSTANT(VTERM_KEY_DOWN);
  DO_CONSTANT(VTERM_KEY_LEFT);
  DO_CONSTANT(VTERM_KEY_RIGHT);
  DO_CONSTANT(VTERM_KEY_INS);
  DO_CONSTANT(VTERM_KEY_DEL);
  DO_CONSTANT(VTERM_KEY_HOME);
  DO_CONSTANT(VTERM_KEY_END);
  DO_CONSTANT(VTERM_KEY_PAGEUP);
  DO_CONSTANT(VTERM_KEY_PAGEDOWN);
  DO_CONSTANT(VTERM_KEY_FUNCTION_0);

  DO_CONSTANT(VTERM_SELECTION_CLIPBOARD);
  DO_CONSTANT(VTERM_SELECTION_PRIMARY);
  DO_CONSTANT(VTERM_SELECTION_SECONDARY);
  DO_CONSTANT(VTERM_SELECTION_SELECT);
  DO_CONSTANT(VTERM_SELECTION_CUT0);
}

MODULE = Term::VTerm        PACKAGE = Term::VTerm

Term::VTerm
_new(package,rows,cols)
  char *package
  int   rows
  int   cols
  INIT:
    VTerm *vt;
  CODE:
    vt = vterm_new(rows, cols);
    if(!vt)
      XSRETURN_UNDEF;

    Newxz(RETVAL, 1, struct Term__VTerm);
#ifdef tTHX
    RETVAL->myperl = aTHX;
#endif
    RETVAL->vt = vt;

    RETVAL->strbuf = newSV(256);
    SvPOK_on(RETVAL->strbuf);

  OUTPUT:
    RETVAL

void
DESTROY(self)
  Term::VTerm self
  INIT:
    struct ParserCallbackData *pcbdata;
  CODE:
    FREE_CB(parser_cb.text);
    FREE_CB(parser_cb.control);
    FREE_CB(parser_cb.escape);
    FREE_CB(parser_cb.csi);
    FREE_CB(parser_cb.osc);
    FREE_CB(parser_cb.dcs);
    FREE_CB(parser_cb.resize);

    SvREFCNT_dec(self->strbuf);

    vterm_free(self->vt);
    Safefree(self);

void
get_size(self)
  Term::VTerm self
  INIT:
    int rows, cols;
  PPCODE:
    vterm_get_size(self->vt, &rows, &cols);

    EXTEND(SP, 2);
    mPUSHi(rows);
    mPUSHi(cols);
    XSRETURN(2);

void
set_size(self,rows,cols)
  Term::VTerm self
  int         rows
  int         cols
  CODE:
    vterm_set_size(self->vt, rows, cols);

int
get_utf8(self)
  Term::VTerm self
  CODE:
    RETVAL = vterm_get_utf8(self->vt);
  OUTPUT:
    RETVAL

void
set_utf8(self,utf8)
  Term::VTerm self
  int         utf8
  CODE:
    vterm_set_utf8(self->vt, utf8);

size_t
input_write(self,str)
  Term::VTerm  self
  SV          *str
  CODE:
    if(SvUTF8(str))
      warn("Wide string in Term::VTerm::input_write()");
    RETVAL = vterm_input_write(self->vt, SvPV_nolen(str), SvCUR(str));
  OUTPUT:
    RETVAL

size_t
output_read(self,buffer,len)
  Term::VTerm  self
  SV          *buffer
  size_t       len
  CODE:
    sv_grow(buffer, len);
    RETVAL = vterm_output_read(self->vt, SvPVX(buffer), len);
    if(RETVAL > 0) {
      SvPOK_on(buffer);
      SvCUR_set(buffer, RETVAL);
    }
    else
      SvCUR_set(buffer, 0);
  OUTPUT:
    RETVAL

void
keyboard_unichar(self,c,mod=&PL_sv_undef)
  Term::VTerm  self
  int          c
  SV          *mod
  INIT:
    VTermModifier m = 0;
  CODE:
    if(SvOK(mod))
      m = SvIV(mod);
    m &= VTERM_MOD_SHIFT|VTERM_MOD_CTRL|VTERM_MOD_ALT;
    vterm_keyboard_unichar(self->vt, c, m);

void
keyboard_key(self,key,mod=&PL_sv_undef)
  Term::VTerm  self
  int          key
  SV          *mod
  INIT:
    VTermModifier m = 0;
  CODE:
    if(SvOK(mod))
      m = SvIV(mod);
    m &= VTERM_MOD_SHIFT|VTERM_MOD_CTRL|VTERM_MOD_ALT;
    vterm_keyboard_key(self->vt, key, m);

void
mouse_move(self,row,col,mod=&PL_sv_undef)
  Term::VTerm  self
  int          row
  int          col
  SV          *mod
  INIT:
    VTermModifier m = 0;
  CODE:
    if(SvOK(mod))
      m = SvIV(mod);
    m &= VTERM_MOD_SHIFT|VTERM_MOD_CTRL|VTERM_MOD_ALT;
    vterm_mouse_move(self->vt, row, col, m);

void
mouse_button(self,button,pressed,mod=&PL_sv_undef)
  Term::VTerm  self
  int          button
  bool         pressed
  SV          *mod
  INIT:
    VTermModifier m = 0;
  CODE:
    if(SvOK(mod))
      m = SvIV(mod);
    m &= VTERM_MOD_SHIFT|VTERM_MOD_CTRL|VTERM_MOD_ALT;
    vterm_mouse_button(self->vt, button, pressed, m);

void
parser_set_callbacks(self,...)
  Term::VTerm  self
  INIT:
    int i;
  CODE:
    vterm_parser_set_callbacks(self->vt, &parser_cbs, self);

    for(i = 1; i < items; i++) {
      char *name = SvPV_nolen(ST(i));
      SV *newcb;
      CV **cvp;
      i++;

      if     (streq(name, "on_text"   )) cvp = &self->parser_cb.text;
      else if(streq(name, "on_control")) cvp = &self->parser_cb.control;
      else if(streq(name, "on_escape"))  cvp = &self->parser_cb.escape;
      else if(streq(name, "on_csi"))     cvp = &self->parser_cb.csi;
      else if(streq(name, "on_osc"))     cvp = &self->parser_cb.osc;
      else if(streq(name, "on_dcs"))     cvp = &self->parser_cb.dcs;
      else if(streq(name, "on_resize"))  cvp = &self->parser_cb.resize;
      else
        croak("Unrecognised parser callback name '%s'", name);

      if(*cvp)
        SvREFCNT_dec(*cvp);

      if(i < items && (newcb = ST(i)) && SvOK(newcb))
        *cvp = (CV *)SvREFCNT_inc(newcb);
      else
        *cvp = NULL;
    }

Term::VTerm::State
obtain_state(self)
  Term::VTerm self
  INIT:
    VTermState *state;
  CODE:
    state = vterm_obtain_state(self->vt);
    if(!state)
      XSRETURN_UNDEF;

    Newxz(RETVAL, 1, struct Term__VTerm__State);
#ifdef tTHX
    RETVAL->myperl = aTHX;
#endif
    RETVAL->state = state;
    RETVAL->vterm = SvREFCNT_inc(ST(0));

    RETVAL->has_selection_cb = FALSE;

  OUTPUT:
    RETVAL

Term::VTerm::Screen
obtain_screen(self)
  Term::VTerm self
  INIT:
    VTermScreen *screen;
  CODE:
    screen = vterm_obtain_screen(self->vt);
    if(!screen)
      XSRETURN_UNDEF;

    Newxz(RETVAL, 1, struct Term__VTerm__Screen);
#ifdef tTHX
    RETVAL->myperl = aTHX;
#endif
    RETVAL->screen = screen;
    RETVAL->vterm  = SvREFCNT_inc(ST(0));

  OUTPUT:
    RETVAL

int
get_attr_type(attr)
  int attr
  CODE:
    RETVAL = vterm_get_attr_type(attr);
  OUTPUT:
    RETVAL

int
get_prop_type(prop)
  int prop
  CODE:
    RETVAL = vterm_get_prop_type(prop);
  OUTPUT:
    RETVAL


MODULE = Term::VTerm        PACKAGE = Term::VTerm::Color

SV *
_new_rgb(package,red,green,blue)
  char *package
  int   red
  int   green
  int   blue
  INIT:
    VTermColor color;
  CODE:
    vterm_color_rgb(&color, red, green, blue);
    RETVAL = newSVcolor(&color);
  OUTPUT:
    RETVAL

void
DESTROY(self)
  Term::VTerm::Color self
  CODE:
    Safefree(self);

bool
is_indexed(self)
  Term::VTerm::Color self
  ALIAS:
    is_indexed    = 0
    is_rgb        = 1
    is_default_fg = 2
    is_default_bg = 3
  CODE:
    switch(ix) {
      case 0: RETVAL = VTERM_COLOR_IS_INDEXED(self);    break;
      case 1: RETVAL = VTERM_COLOR_IS_RGB(self);        break;
      case 2: RETVAL = VTERM_COLOR_IS_DEFAULT_FG(self); break;
      case 3: RETVAL = VTERM_COLOR_IS_DEFAULT_BG(self); break;
    }
  OUTPUT:
    RETVAL

int
index(self)
  Term::VTerm::Color self
  CODE:
    if(!VTERM_COLOR_IS_INDEXED(self))
      XSRETURN_UNDEF;
    RETVAL = self->indexed.idx;
  OUTPUT:
    RETVAL

int
red(self)
  Term::VTerm::Color self
  ALIAS:
    red   = 0
    green = 1
    blue  = 2
  CODE:
    if(!VTERM_COLOR_IS_RGB(self))
      XSRETURN_UNDEF;
    switch(ix) {
      case 0: RETVAL = self->rgb.red;   break;
      case 1: RETVAL = self->rgb.green; break;
      case 2: RETVAL = self->rgb.blue;  break;
    }
  OUTPUT:
    RETVAL


MODULE = Term::VTerm        PACKAGE = Term::VTerm::GlyphInfo

void
DESTROY(self)
  Term::VTerm::GlyphInfo self
  CODE:
    Safefree(self);

void
chars(self)
  Term::VTerm::GlyphInfo self
  INIT:
    int i;
  PPCODE:
    for(i = 0; self->chars[i]; i++)
      mXPUSHi(self->chars[i]);
    XSRETURN(i);

SV *
str(self)
  Term::VTerm::GlyphInfo self
  CODE:
  {
    STRLEN len = 0;
    U8 *u8;
    int i;

    for(i = 0; self->chars[i]; i++)
      len += UNISKIP(self->chars[i]);

    RETVAL = newSV(len + 1);

    u8 = SvPVX(RETVAL);
    for(i = 0; self->chars[i]; i++)
      u8 = uvchr_to_utf8(u8, self->chars[i]);

    *u8 = 0;
    SvCUR_set(RETVAL, len);
    SvPOK_on(RETVAL);
    SvUTF8_on(RETVAL);
  }
  OUTPUT:
    RETVAL

int
width(self)
  Term::VTerm::GlyphInfo self
  ALIAS:
    width = 0
    dhl   = 1
  CODE:
    switch(ix) {
      case 0: RETVAL = self->width; break;
      case 1: RETVAL = self->dhl;   break;
    }
  OUTPUT:
    RETVAL

bool
protected_cell(self)
  Term::VTerm::GlyphInfo self
  ALIAS:
    protected_cell = 0
    dwl            = 1
  CODE:
    switch(ix) {
      case 0: RETVAL = self->protected_cell; break;
      case 1: RETVAL = self->dwl;            break;
    }
  OUTPUT:
    RETVAL


MODULE = Term::VTerm        PACKAGE = Term::VTerm::LineInfo

void
DESTROY(self)
  Term::VTerm::LineInfo self
  CODE:
    Safefree(self);

int
doublewidth(self)
  Term::VTerm::LineInfo self
  ALIAS:
    doublewidth  = 0
    doubleheight = 1
  CODE:
    switch(ix) {
      case 0: RETVAL = self->doublewidth;  break;
      case 1: RETVAL = self->doubleheight; break;
    }
  OUTPUT:
    RETVAL


MODULE = Term::VTerm        PACKAGE = Term::VTerm::Pos

SV *
_new(package,row,col)
  char *package
  int   row
  int   col
  INIT:
    VTermPos pos;
  CODE:
    pos.row = row;
    pos.col = col;
    RETVAL = newSVpos(pos);
  OUTPUT:
    RETVAL

void
DESTROY(self)
  Term::VTerm::Pos self
  CODE:
    Safefree(self);

int
row(self)
  Term::VTerm::Pos self
  CODE:
    RETVAL = self->row;
  OUTPUT:
    RETVAL

int
col(self)
  Term::VTerm::Pos self
  CODE:
    RETVAL = self->col;
  OUTPUT:
    RETVAL


MODULE = Term::VTerm        PACKAGE = Term::VTerm::Rect

SV *
_new(package,start_row,end_row,start_col,end_col)
  char *package
  int   start_row
  int   end_row
  int   start_col
  int   end_col
  INIT:
    VTermRect rect;
  CODE:
    rect.start_row = start_row;
    rect.end_row   = end_row;
    rect.start_col = start_col;
    rect.end_col   = end_col;
    RETVAL = newSVrect(rect);
  OUTPUT:
    RETVAL

void
DESTROY(self)
  Term::VTerm::Rect self
  CODE:
    Safefree(self);

int
start_row(self)
  Term::VTerm::Rect self
  ALIAS:
    start_row = 0
    end_row   = 1
    start_col = 2
    end_col   = 3
  CODE:
    switch(ix) {
      case 0: RETVAL = self->start_row; break;
      case 1: RETVAL = self->end_row;   break;
      case 2: RETVAL = self->start_col; break;
      case 3: RETVAL = self->end_col;   break;
    }
  OUTPUT:
    RETVAL


MODULE = Term::VTerm        PACKAGE = Term::VTerm::Screen

void
DESTROY(self)
  Term::VTerm::Screen self
  CODE:
    FREE_CB(cb.damage);
    FREE_CB(cb.moverect);
    FREE_CB(cb.movecursor);
    FREE_CB(cb.settermprop);
    FREE_CB(cb.bell);
    FREE_CB(cb.resize);

    SvREFCNT_dec(self->vterm);
    Safefree(self);

void
enable_altscreen(self,enabled)
  Term::VTerm::Screen self
  bool                enabled
  CODE:
    vterm_screen_enable_altscreen(self->screen, enabled);

void
enable_reflow(self,enabled)
  Term::VTerm::Screen self
  bool                enabled
  CODE:
    vterm_screen_enable_reflow(self->screen, enabled);

void
flush_damage(self)
  Term::VTerm::Screen self
  CODE:
    vterm_screen_flush_damage(self->screen);

void
set_damage_merge(self,size)
  Term::VTerm::Screen self
  int                 size
  CODE:
    vterm_screen_set_damage_merge(self->screen, size);

void
reset(self,hard=&PL_sv_undef)
  Term::VTerm::Screen  self
  SV                  *hard
  CODE:
    vterm_screen_reset(self->screen, SvOK(hard) ? SvIV(hard) : 0);

SV *
get_cell(self,pos)
  Term::VTerm::Screen self
  Term::VTerm::Pos    pos
  INIT:
    VTermScreenCell cell;
  CODE:
    if(!vterm_screen_get_cell(self->screen, *pos, &cell))
      XSRETURN_UNDEF;

    RETVAL = newSVscreencell(cell);
  OUTPUT:
    RETVAL

SV *
get_text(self,rect)
  Term::VTerm::Screen self
  Term::VTerm::Rect   rect
  INIT:
    size_t len;
  CODE:
    len = vterm_screen_get_text(self->screen, NULL, 0, *rect);

    RETVAL = newSV(len + 1);
    vterm_screen_get_text(self->screen, SvPVX(RETVAL), len, *rect);
    SvPVX(RETVAL)[len] = 0;

    SvCUR_set(RETVAL, len);
    SvPOK_on(RETVAL);
    SvUTF8_on(RETVAL);
  OUTPUT:
    RETVAL

void
set_callbacks(self,...)
  Term::VTerm::Screen self
  INIT:
    int i;
  CODE:
    vterm_screen_set_callbacks(self->screen, &screen_cbs, self);

    for(i = 1; i < items; i++) {
      char *name = SvPV_nolen(ST(i));
      SV *newcb;
      CV **cvp;
      i++;

      if     (streq(name, "on_damage"     )) cvp = &self->cb.damage;
      else if(streq(name, "on_moverect"   )) cvp = &self->cb.moverect;
      else if(streq(name, "on_movecursor" )) cvp = &self->cb.movecursor;
      else if(streq(name, "on_settermprop")) cvp = &self->cb.settermprop;
      else if(streq(name, "on_bell"       )) cvp = &self->cb.bell;
      else if(streq(name, "on_resize"     )) cvp = &self->cb.resize;
      else
        croak("Unrecognised screen callback name '%s'", name);

      if(*cvp)
        SvREFCNT_dec(*cvp);

      if(i < items && (newcb = ST(i)) && SvOK(newcb))
        *cvp = (CV *)SvREFCNT_inc(newcb);
      else
        *cvp = NULL;
    }

SV *
convert_color_to_rgb(self,col)
  Term::VTerm::Screen self
  Term::VTerm::Color  col
  CODE:
    vterm_screen_convert_color_to_rgb(self->screen, col);
    RETVAL = newSVcolor(col);
  OUTPUT:
    RETVAL


MODULE = Term::VTerm        PACKAGE = Term::VTerm::Screen::Cell

void
DESTROY(self)
  Term::VTerm::Screen::Cell self
  CODE:
    Safefree(self);

void
chars(self)
  Term::VTerm::Screen::Cell self
  INIT:
    int i;
  PPCODE:
    for(i = 0; self->chars[i]; i++)
      mXPUSHi(self->chars[i]);
    XSRETURN(i);

SV *
str(self)
  Term::VTerm::Screen::Cell self
  CODE:
  {
    STRLEN len = 0;
    U8 *u8;
    int i;

    for(i = 0; self->chars[i]; i++)
      len += UNISKIP(self->chars[i]);

    RETVAL = newSV(len + 1);

    u8 = SvPVX(RETVAL);
    for(i = 0; self->chars[i]; i++)
      u8 = uvchr_to_utf8(u8, self->chars[i]);

    *u8 = 0;
    SvCUR_set(RETVAL, len);
    SvPOK_on(RETVAL);
    SvUTF8_on(RETVAL);
  }
  OUTPUT:
    RETVAL

int
width(self)
  Term::VTerm::Screen::Cell self
  ALIAS:
    width     = 0
    underline = 1
    font      = 2
    baseline  = 3
  CODE:
    switch(ix) {
      case 0: RETVAL = self->width;           break;
      case 1: RETVAL = self->attrs.underline; break;
      case 2: RETVAL = self->attrs.font;      break;
      case 3: RETVAL = self->attrs.baseline;  break;
    }
  OUTPUT:
    RETVAL

bool
bold(self)
  Term::VTerm::Screen::Cell self
  ALIAS:
    bold    = 0
    italic  = 1
    blink   = 2
    reverse = 3
    strike  = 4
    small   = 5
  CODE:
    switch(ix) {
      case 0: RETVAL = self->attrs.bold;    break;
      case 1: RETVAL = self->attrs.italic;  break;
      case 2: RETVAL = self->attrs.blink;   break;
      case 3: RETVAL = self->attrs.reverse; break;
      case 4: RETVAL = self->attrs.strike;  break;
      case 5: RETVAL = self->attrs.small;   break;
    }
  OUTPUT:
    RETVAL

SV *
fg(self)
  Term::VTerm::Screen::Cell self
  ALIAS:
    fg = 0
    bg = 1
  CODE:
    switch(ix) {
      case 0: RETVAL = newSVcolor(&self->fg); break;
      case 1: RETVAL = newSVcolor(&self->bg); break;
    }
  OUTPUT:
    RETVAL


MODULE = Term::VTerm        PACKAGE = Term::VTerm::State

void
DESTROY(self)
  Term::VTerm::State self
  CODE:
    FREE_CB(cb.putglyph);
    FREE_CB(cb.movecursor);
    FREE_CB(cb.scrollrect);
    FREE_CB(cb.moverect);
    FREE_CB(cb.erase);
    FREE_CB(cb.initpen);
    FREE_CB(cb.setpenattr);
    FREE_CB(cb.settermprop);
    FREE_CB(cb.bell);
    FREE_CB(cb.resize);
    FREE_CB(cb.setlineinfo);

    SvREFCNT_dec(self->vterm);
    Safefree(self);

void
reset(self,hard=&PL_sv_undef)
  Term::VTerm::State  self
  SV                 *hard
  CODE:
    vterm_state_reset(self->state, SvOK(hard) ? SvIV(hard) : 0);

Term::VTerm::Pos
get_cursorpos(self)
  Term::VTerm::State self
  CODE:
    Newx(RETVAL, 1, VTermPos);
    vterm_state_get_cursorpos(self->state, RETVAL);
  OUTPUT:
    RETVAL

void
get_default_colors(self)
  Term::VTerm::State self
  INIT:
    VTermColor fg, bg;
  PPCODE:
    vterm_state_get_default_colors(self->state, &fg, &bg);
    EXTEND(SP, 2);
    mPUSHs(newSVcolor(&fg));
    mPUSHs(newSVcolor(&bg));
    XSRETURN(2);

void
set_default_colors(self,fg,bg)
  Term::VTerm::State self
  Term::VTerm::Color fg
  Term::VTerm::Color bg
  CODE:
    vterm_state_set_default_colors(self->state, fg, bg);

SV *
get_palette_color(self,index)
  Term::VTerm::State self
  int                index
  INIT:
    VTermColor col;
  CODE:
    vterm_state_get_palette_color(self->state, index, &col);
    RETVAL = newSVcolor(&col);
  OUTPUT:
    RETVAL

SV *
get_penattr(self,attr)
  Term::VTerm::State self
  int                attr
  INIT:
    VTermValue val;
  CODE:
    vterm_state_get_penattr(self->state, attr, &val);
    RETVAL = newSVvalue(&val, vterm_get_attr_type(attr));
  OUTPUT:
    RETVAL

void
set_callbacks(self,...)
  Term::VTerm::State self
  INIT:
    int i;
  CODE:
    vterm_state_set_callbacks(self->state, &state_cbs, self);

    for(i = 1; i < items; i++) {
      char *name = SvPV_nolen(ST(i));
      SV *newcb;
      CV **cvp;
      i++;

      if     (streq(name, "on_putglyph"   )) cvp = &self->cb.putglyph;
      else if(streq(name, "on_movecursor" )) cvp = &self->cb.movecursor;
      else if(streq(name, "on_scrollrect" )) cvp = &self->cb.scrollrect;
      else if(streq(name, "on_moverect"   )) cvp = &self->cb.moverect;
      else if(streq(name, "on_erase"      )) cvp = &self->cb.erase;
      else if(streq(name, "on_initpen"    )) cvp = &self->cb.initpen;
      else if(streq(name, "on_setpenattr" )) cvp = &self->cb.setpenattr;
      else if(streq(name, "on_settermprop")) cvp = &self->cb.settermprop;
      else if(streq(name, "on_bell"       )) cvp = &self->cb.bell;
      else if(streq(name, "on_resize"     )) cvp = &self->cb.resize;
      else if(streq(name, "on_setlineinfo")) cvp = &self->cb.setlineinfo;
      else
        croak("Unrecognised state callback name '%s'", name);

      if(*cvp)
        SvREFCNT_dec(*cvp);

      if(i < items && (newcb = ST(i)) && SvOK(newcb))
        *cvp = (CV *)SvREFCNT_inc(newcb);
      else
        *cvp = NULL;
    }

void
set_selection_callbacks(self,...)
  Term::VTerm::State self
  INIT:
    int i;
  CODE:
    /* TODO: argument to set buffer size? */
    if(!self->has_selection_cb) {
      vterm_state_set_selection_callbacks(self->state, &state_selection_cbs, self,
        NULL, 4096);
      self->has_selection_cb = TRUE;
    }

    for(i = 1; i < items; i++) {
      char *name = SvPV_nolen(ST(i));
      SV *newcb;
      CV **cvp;
      i++;

      if     (streq(name, "on_set"  )) cvp = &self->cb.selection_set;
      else if(streq(name, "on_query")) cvp = &self->cb.selection_query;
      else
        croak("Unrecognised state callback name '%s'", name);

      if(*cvp)
        SvREFCNT_dec(*cvp);

      if(i < items && (newcb = ST(i)) && SvOK(newcb))
        *cvp = (CV *)SvREFCNT_inc(newcb);
      else
        *cvp = NULL;
    }

void
send_selection(self,mask,str)
  Term::VTerm::State self
  int mask
  SV *str
  INIT:
    STRLEN len;
    VTermStringFragment frag;
  CODE:
    frag = (VTermStringFragment){
      .str     = SvPVbyte(str, len),
      .initial = TRUE,
      .final   = TRUE,
    };
    frag.len = len;

    vterm_state_send_selection(self->state, mask, frag);

SV *
convert_color_to_rgb(self,col)
  Term::VTerm::State self
  Term::VTerm::Color col
  CODE:
    vterm_state_convert_color_to_rgb(self->state, col);
    RETVAL = newSVcolor(col);
  OUTPUT:
    RETVAL


BOOT:
  S_setup_constants(aTHX);
#ifdef HAVE_DMD_HELPER
  DMD_SET_PACKAGE_HELPER("Term::VTerm",         dmd_helper_vterm);
  DMD_SET_PACKAGE_HELPER("Term::VTerm::State",  dmd_helper_vterm_state);
  DMD_SET_PACKAGE_HELPER("Term::VTerm::Screen", dmd_helper_vterm_screen);
#endif
