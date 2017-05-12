/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2009-2012 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <termkey.h>

/* Because of Perl's safe signal handling, we have to always enable the
 * TERMKEY_FLAG_EINTR flag, and implement retry logic ourselves in the
 * wrappings of termkey_waitkey and termkey_advisereadable
 */

/* We can reuse the preinterpret fields in this structure, knowing that
 * they'll never be used for more than one type at once
 */
#define FIELD_BUTTON  0
#define FIELD_INITIAL 0
#define FIELD_LINE   1
#define FIELD_MODE   1
#define FIELD_COL    2
#define FIELD_VALUE  2

typedef struct key_extended {
  TermKeyKey k;
  SV        *termkey;
  TermKeyMouseEvent mouseev;
  int        fields[3];
} *Term__TermKey__Key;

typedef struct termkey_with_fh {
  TermKey *tk;
  SV      *fh;
  int      flag_eintr;
} *Term__TermKey;

static void setup_constants(void)
{
  HV *stash;
  AV *export;

  stash = gv_stashpvn("Term::TermKey", 13, TRUE);
  export = get_av("Term::TermKey::EXPORT", TRUE);

#define DO_CONSTANT(c) \
  newCONSTSUB(stash, #c+8, newSViv(c)); \
  av_push(export, newSVpv(#c+8, 0));

  DO_CONSTANT(TERMKEY_TYPE_UNICODE)
  DO_CONSTANT(TERMKEY_TYPE_FUNCTION)
  DO_CONSTANT(TERMKEY_TYPE_KEYSYM)
  DO_CONSTANT(TERMKEY_TYPE_MOUSE)
  DO_CONSTANT(TERMKEY_TYPE_POSITION)
  DO_CONSTANT(TERMKEY_TYPE_MODEREPORT)
  DO_CONSTANT(TERMKEY_TYPE_UNKNOWN_CSI)

  DO_CONSTANT(TERMKEY_RES_NONE)
  DO_CONSTANT(TERMKEY_RES_KEY)
  DO_CONSTANT(TERMKEY_RES_EOF)
  DO_CONSTANT(TERMKEY_RES_AGAIN)
  DO_CONSTANT(TERMKEY_RES_ERROR)

  DO_CONSTANT(TERMKEY_KEYMOD_SHIFT)
  DO_CONSTANT(TERMKEY_KEYMOD_ALT)
  DO_CONSTANT(TERMKEY_KEYMOD_CTRL)

  DO_CONSTANT(TERMKEY_MOUSE_UNKNOWN)
  DO_CONSTANT(TERMKEY_MOUSE_PRESS)
  DO_CONSTANT(TERMKEY_MOUSE_DRAG)
  DO_CONSTANT(TERMKEY_MOUSE_RELEASE)

  DO_CONSTANT(TERMKEY_FLAG_NOINTERPRET)
  DO_CONSTANT(TERMKEY_FLAG_CONVERTKP)
  DO_CONSTANT(TERMKEY_FLAG_RAW)
  DO_CONSTANT(TERMKEY_FLAG_UTF8)
  DO_CONSTANT(TERMKEY_FLAG_NOTERMIOS)
  DO_CONSTANT(TERMKEY_FLAG_SPACESYMBOL)
  DO_CONSTANT(TERMKEY_FLAG_CTRLC)
  DO_CONSTANT(TERMKEY_FLAG_EINTR)

  DO_CONSTANT(TERMKEY_CANON_SPACESYMBOL)
  DO_CONSTANT(TERMKEY_CANON_DELBS)

  DO_CONSTANT(TERMKEY_FORMAT_LONGMOD)
  DO_CONSTANT(TERMKEY_FORMAT_CARETCTRL)
  DO_CONSTANT(TERMKEY_FORMAT_ALTISMETA)
  DO_CONSTANT(TERMKEY_FORMAT_WRAPBRACKET)
  DO_CONSTANT(TERMKEY_FORMAT_MOUSE_POS)

  DO_CONSTANT(TERMKEY_FORMAT_VIM)
}

static struct key_extended *get_keystruct_or_new(SV *sv, const char *funcname, SV *termkey)
{
  struct key_extended *key;
  if(sv && !SvOK(sv)) {
    Newx(key, 1, struct key_extended);
    sv_setref_pv(sv, "Term::TermKey::Key", (void*)key);
    key->termkey = NULL;
  }
  else if(sv_derived_from(sv, "Term::TermKey::Key")) {
    IV tmp = SvIV((SV*)SvRV(sv));
    key = INT2PTR(struct key_extended *, tmp);
  }
  else
    Perl_croak(aTHX_ "%s: %s is not of type %s",
                funcname,
                "key", "Term::TermKey::Key");

  if(!key->termkey ||
     SvRV(key->termkey) != SvRV(termkey)) {
    if(key->termkey)
      SvREFCNT_dec(key->termkey);

    key->termkey = newRV_inc(SvRV(termkey));
  }

  return key;
}

static void preinterpret_key(Term__TermKey__Key key, TermKey *tk)
{
  if(key->k.type == TERMKEY_TYPE_MOUSE)
    termkey_interpret_mouse(tk, &key->k, &key->mouseev, &key->fields[FIELD_BUTTON], &key->fields[FIELD_LINE], &key->fields[FIELD_COL]);
  else if(key->k.type == TERMKEY_TYPE_POSITION)
    termkey_interpret_position(tk, &key->k, &key->fields[FIELD_LINE], &key->fields[FIELD_COL]);
  else if(key->k.type == TERMKEY_TYPE_MODEREPORT)
    termkey_interpret_modereport(tk, &key->k, &key->fields[FIELD_INITIAL], &key->fields[FIELD_MODE], &key->fields[FIELD_VALUE]);
}


MODULE = Term::TermKey::Key  PACKAGE = Term::TermKey::Key    PREFIX = key_

void
DESTROY(self)
  Term::TermKey::Key self
  CODE:
    SvREFCNT_dec(self->termkey);
    Safefree(self);

int
type(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type;
  OUTPUT:
    RETVAL

bool
type_is_unicode(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type == TERMKEY_TYPE_UNICODE;
  OUTPUT:
    RETVAL

bool
type_is_function(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type == TERMKEY_TYPE_FUNCTION;
  OUTPUT:
    RETVAL

bool
type_is_keysym(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type == TERMKEY_TYPE_KEYSYM;
  OUTPUT:
    RETVAL

bool
type_is_mouse(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type == TERMKEY_TYPE_MOUSE;
  OUTPUT:
    RETVAL

bool
type_is_position(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type == TERMKEY_TYPE_POSITION;
  OUTPUT:
    RETVAL

bool
type_is_modereport(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type == TERMKEY_TYPE_MODEREPORT;
  OUTPUT:
    RETVAL

bool
type_is_unknown_csi(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type == TERMKEY_TYPE_UNKNOWN_CSI;
  OUTPUT:
    RETVAL

int
codepoint(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type == TERMKEY_TYPE_UNICODE ? self->k.code.codepoint : 0;
  OUTPUT:
    RETVAL

int
number(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type == TERMKEY_TYPE_FUNCTION ? self->k.code.number : 0;
  OUTPUT:
    RETVAL

int
sym(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type == TERMKEY_TYPE_KEYSYM ? self->k.code.sym : TERMKEY_SYM_NONE;
  OUTPUT:
    RETVAL

int
modifiers(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.modifiers;
  OUTPUT:
    RETVAL

bool
modifier_shift(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.modifiers & TERMKEY_KEYMOD_SHIFT;
  OUTPUT:
    RETVAL

bool
modifier_alt(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.modifiers & TERMKEY_KEYMOD_ALT;
  OUTPUT:
    RETVAL

bool
modifier_ctrl(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.modifiers & TERMKEY_KEYMOD_CTRL;
  OUTPUT:
    RETVAL

SV *
termkey(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = newRV_inc(SvRV(self->termkey));
  OUTPUT:
    RETVAL

SV *
utf8(self)
  Term::TermKey::Key self
  CODE:
    if(self->k.type == TERMKEY_TYPE_UNICODE) {
      IV tmp;
      TermKey *termkey;

      RETVAL = newSVpv(self->k.utf8, 0);

      tmp = SvIV((SV*)SvRV(self->termkey));
      termkey = (INT2PTR(Term__TermKey, tmp))->tk;

      if(termkey_get_flags(termkey) & TERMKEY_FLAG_UTF8)
        SvUTF8_on(RETVAL);
    }
    else
      RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
mouseev(self)
  Term::TermKey::Key self
  CODE:
    if(self->k.type == TERMKEY_TYPE_MOUSE)
      RETVAL = newSViv(self->mouseev);
    else
      RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
button(self)
  Term::TermKey::Key self
  CODE:
    if(self->k.type == TERMKEY_TYPE_MOUSE)
      RETVAL = newSViv(self->fields[FIELD_BUTTON]);
    else
      RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
line(self)
  Term::TermKey::Key self
  CODE:
    if(self->k.type == TERMKEY_TYPE_MOUSE || self->k.type == TERMKEY_TYPE_POSITION)
      RETVAL = newSViv(self->fields[FIELD_LINE]);
    else
      RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
col(self)
  Term::TermKey::Key self
  CODE:
    if(self->k.type == TERMKEY_TYPE_MOUSE || self->k.type == TERMKEY_TYPE_POSITION)
      RETVAL = newSViv(self->fields[FIELD_COL]);
    else
      RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
initial(self)
  Term::TermKey::Key self
  CODE:
    if(self->k.type == TERMKEY_TYPE_MODEREPORT) {
      char str[2] = { self->fields[FIELD_INITIAL], 0 };
      RETVAL = newSVpv(str, 0);
    }
    else
      RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
mode(self)
  Term::TermKey::Key self
  CODE:
    if(self->k.type == TERMKEY_TYPE_MODEREPORT)
      RETVAL = newSViv(self->fields[FIELD_MODE]);
    else
      RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
value(self)
  Term::TermKey::Key self
  CODE:
    if(self->k.type == TERMKEY_TYPE_MODEREPORT)
      RETVAL = newSViv(self->fields[FIELD_VALUE]);
    else
      RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL


MODULE = Term::TermKey      PACKAGE = Term::TermKey      PREFIX = termkey_

BOOT:
  TERMKEY_CHECK_VERSION;
  setup_constants();

Term::TermKey
new(package, fh, flags=0)
  SV *fh
  int flags
  INIT:
    int fd;
  CODE:
    Newx(RETVAL, 1, struct termkey_with_fh);
    if(!SvOK(fh)) {
      fd = -1;
      RETVAL->fh = NULL;
    }
    else if(SvROK(fh)) {
      fd = PerlIO_fileno(IoIFP(sv_2io(fh)));
      RETVAL->fh = SvREFCNT_inc(SvRV(fh));
    }
    else {
      fd = SvIV(fh);
      RETVAL->fh = NULL;
    }
    RETVAL->tk = termkey_new(fd, flags | TERMKEY_FLAG_EINTR);
    RETVAL->flag_eintr = flags & TERMKEY_FLAG_EINTR;
  OUTPUT:
    RETVAL

Term::TermKey
new_abstract(package, termtype, flags=0)
  char *termtype
  int flags
  CODE:
    Newx(RETVAL, 1, struct termkey_with_fh);
    RETVAL->tk = termkey_new_abstract(termtype, flags | TERMKEY_FLAG_EINTR);
    RETVAL->flag_eintr = flags & TERMKEY_FLAG_EINTR;
    RETVAL->fh = NULL;
  OUTPUT:
    RETVAL

void
DESTROY(self)
  Term::TermKey self
  CODE:
    termkey_destroy(self->tk);
    if(self->fh)
      SvREFCNT_dec(self->fh);
    Safefree(self);
  OUTPUT:

int
start(self)
  Term::TermKey self
  CODE:
    RETVAL = termkey_start(self->tk);
  OUTPUT:
    RETVAL

int
stop(self)
  Term::TermKey self
  CODE:
    RETVAL = termkey_stop(self->tk);
  OUTPUT:
    RETVAL

int
is_started(self)
  Term::TermKey self
  CODE:
    RETVAL = termkey_is_started(self->tk);
  OUTPUT:
    RETVAL

int
get_flags(self)
  Term::TermKey self
  CODE:
    /* Still need to read flags out of underlying termkey instance to get
     * flags it might modify - UTF-8 or RAW */
    RETVAL = self->flag_eintr |
             (termkey_get_flags(self->tk) & ~TERMKEY_FLAG_EINTR);
  OUTPUT:
    RETVAL

void
set_flags(self, newflags)
  Term::TermKey self
  int newflags
  CODE:
    self->flag_eintr = newflags & TERMKEY_FLAG_EINTR;
    termkey_set_flags(self->tk, newflags | TERMKEY_FLAG_EINTR);
  OUTPUT:

int
get_canonflags(self)
  Term::TermKey self
  CODE:
    RETVAL = termkey_get_canonflags(self->tk);
  OUTPUT:
    RETVAL

void
set_canonflags(self, newcanonflags)
  Term::TermKey self
  int newcanonflags
  CODE:
    termkey_set_canonflags(self->tk, newcanonflags);
  OUTPUT:

int
get_waittime(self)
  Term::TermKey self
  CODE:
    RETVAL = termkey_get_waittime(self->tk);
  OUTPUT:
    RETVAL

void
set_waittime(self, msec)
  Term::TermKey self
  int msec
  CODE:
    termkey_set_waittime(self->tk, msec);
  OUTPUT:

size_t
get_buffer_remaining(self)
  Term::TermKey self
  CODE:
    RETVAL = termkey_get_buffer_remaining(self->tk);
  OUTPUT:
    RETVAL

size_t
get_buffer_size(self)
  Term::TermKey self
  CODE:
    RETVAL = termkey_get_buffer_size(self->tk);
  OUTPUT:
    RETVAL

void
set_buffer_size(self, size)
  Term::TermKey self
  size_t size
  CODE:
    if(!termkey_set_buffer_size(self->tk, size))
      croak("termkey_set_buffer_size(): ", strerror(errno));

int
getkey(self, key)
  Term::TermKey self
  Term::TermKey::Key key = NO_INIT
  PREINIT:
    TermKeyResult res;
  PPCODE:
    key = get_keystruct_or_new(ST(1), "Term::TermKey::getkey", ST(0));
    res = termkey_getkey(self->tk, &key->k);
    
    if(res == TERMKEY_RES_KEY)
      preinterpret_key(key, self->tk);

    mPUSHi(res);
    XSRETURN(1);

int
getkey_force(self, key)
  Term::TermKey self
  Term::TermKey::Key key = NO_INIT
  PREINIT:
    TermKeyResult res;
  PPCODE:
    key = get_keystruct_or_new(ST(1), "Termk::TermKey::getkey_force", ST(0));
    res = termkey_getkey_force(self->tk, &key->k);

    if(res == TERMKEY_RES_KEY)
      preinterpret_key(key, self->tk);

    mPUSHi(res);
    XSRETURN(1);

void
waitkey(self, key)
  Term::TermKey self
  Term::TermKey::Key key = NO_INIT
  PREINIT:
    TermKeyResult res;
  PPCODE:
    key = get_keystruct_or_new(ST(1), "Term::TermKey::waitkey", ST(0));

    while(1) {
      res = termkey_waitkey(self->tk, &key->k);

      if(res != TERMKEY_RES_ERROR)
        break;
      if(errno != EINTR || self->flag_eintr)
        break;

      PERL_ASYNC_CHECK();
    }

    if(res == TERMKEY_RES_KEY)
      preinterpret_key(key, self->tk);

    mPUSHi(res);
    XSRETURN(1);

int
advisereadable(self)
  Term::TermKey self
  CODE:
    while(1) {
      RETVAL = termkey_advisereadable(self->tk);

      if(RETVAL != TERMKEY_RES_ERROR)
        break;
      if(errno != EINTR || self->flag_eintr)
        break;

      PERL_ASYNC_CHECK();
    }
  OUTPUT:
    RETVAL

size_t
push_bytes(self, bytes)
  Term::TermKey self
  SV           *bytes
  CODE:
    RETVAL = termkey_push_bytes(self->tk, SvPV_nolen(bytes), SvCUR(bytes));
  OUTPUT:
    RETVAL

const char *
get_keyname(self, sym)
  Term::TermKey self
  int sym
  CODE:
    RETVAL = termkey_get_keyname(self->tk, sym);
  OUTPUT:
    RETVAL

int
keyname2sym(self, keyname)
  Term::TermKey self
  const char *keyname
  CODE:
    RETVAL = termkey_keyname2sym(self->tk, keyname);
  OUTPUT:
    RETVAL

void
interpret_mouse(self, key)
  Term::TermKey self
  Term::TermKey::Key key
  PREINIT:
    TermKeyMouseEvent ev;
    int button;
    int line, col;
  PPCODE:
    if(termkey_interpret_mouse(self->tk, &key->k, &ev, &button, &line, &col) != TERMKEY_RES_KEY)
      XSRETURN(0);
    mPUSHi(ev);
    mPUSHi(button);
    mPUSHi(line);
    mPUSHi(col);
    XSRETURN(4);

void
interpret_unknown_csi(self, key)
  Term::TermKey self
  Term::TermKey::Key key
  PREINIT:
    size_t nargs = 16;
    long args[16];
    unsigned long cmd;
    char str[4];
    int i;
  PPCODE:
    if(termkey_interpret_csi(self->tk, &key->k, args, &nargs, &cmd) != TERMKEY_RES_KEY)
      XSRETURN(0);

    i = 0;
    // Initial byte first
    if((cmd >> 8) & 0xff)
      str[i++] = (cmd >> 8) & 0xff;
    // Intermediate byte second
    if((cmd >> 16) & 0xff)
      str[i++] = (cmd >> 16) & 0xff;
    // Command byte last
    str[i++] = cmd & 0xff;
    str[i] = 0;

    mPUSHp(str, i);

    for(i = 0; i < nargs; i++)
      mPUSHi(args[i]);

    XSRETURN(nargs + 1);

SV *
format_key(self, key, format)
  Term::TermKey self
  Term::TermKey::Key key
  int format
  CODE:
    RETVAL = newSVpvn("", 50);
    SvCUR_set(RETVAL, termkey_strfkey(self->tk, SvPV_nolen(RETVAL), SvLEN(RETVAL), &key->k, format));
    if(termkey_get_flags(self->tk) & TERMKEY_FLAG_UTF8)
      SvUTF8_on(RETVAL);
  OUTPUT:
    RETVAL

SV *
parse_key(self, str, format)
  Term::TermKey self
  char *str
  int format
  PREINIT:
    char *ret;
    Term__TermKey__Key key;
  CODE:
    RETVAL = newSV(0);
    key = get_keystruct_or_new(RETVAL, "Term::TermKey::parse_key", ST(0));

    ret = termkey_strpkey(self->tk, str, &key->k, format);

    if(!ret || ret[0]) {
      SvREFCNT_dec(RETVAL);
      XSRETURN_UNDEF;
    }
  OUTPUT:
    RETVAL

SV *
parse_key_at_pos(self, str, format)
  Term::TermKey self
  SV *str
  int format
  PREINIT:
    char *str_base, *str_start, *str_end;
    MAGIC *posmg = NULL;
    Term__TermKey__Key key;
  CODE:
    if(SvREADONLY(str))
      croak("str must not be a string literal");

    str_start = str_base = SvPV_nolen(str);

    if(SvTYPE(str) >= SVt_PVMG && SvMAGIC(str))
      posmg = mg_find(str, PERL_MAGIC_regex_global);
    if(posmg)
      str_start += posmg->mg_len; /* already in bytes */

    RETVAL = newSV(0);
    key = get_keystruct_or_new(RETVAL, "Term::TermKey::parse_key_at_pos", ST(0));

    str_end = termkey_strpkey(self->tk, str_start, &key->k, format);

    if(!str_end) {
      SvREFCNT_dec(RETVAL);
      XSRETURN_UNDEF;
    }

    if(!posmg)
      posmg = sv_magicext(str, NULL, PERL_MAGIC_regex_global, &PL_vtbl_mglob,
                          NULL, 0);

    posmg->mg_len = str_end - str_base; /* already in bytes */
  OUTPUT:
    RETVAL

int
keycmp(self, key1, key2)
  Term::TermKey self
  Term::TermKey::Key key1
  Term::TermKey::Key key2
  CODE:
    RETVAL = termkey_keycmp(self->tk, &key1->k, &key2->k);
  OUTPUT:
    RETVAL
