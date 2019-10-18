/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef wrap_keyword_plugin
#  include "wrap_keyword_plugin.c.inc"
#endif

#include "lexer-additions.c.inc"

static OP *newPADSVOP(PADOFFSET padix)
{
  OP *op = newOP(OP_PADSV, 0);
  op->op_targ = padix;
  return op;
}

static XOP xop_slotpad;
static OP *pp_slotpad(pTHX)
{
  UNOP_AUX_item *aux = cUNOP_AUX->op_aux;
  I32 slotix = aux[0].iv;
  PADOFFSET targ = PL_op->op_targ;

  SV *self = PAD_SV(1);
  SV **slots = AvARRAY((AV *)SvRV(self));

  if(PAD_SV(targ))
    SvREFCNT_dec(PAD_SV(targ));

  PAD_SVl(targ) = SvREFCNT_inc(slots[slotix]);

  return PL_op->op_next;
}

static OP *newSLOTPADOP(PADOFFSET padix, I32 slotix)
{
  UNOP_AUX_item *aux = (UNOP_AUX_item *)PerlMemShared_malloc(sizeof(UNOP_AUX_item) * 1);
  aux[0].iv = slotix;

  OP *op = newUNOP_AUX(OP_CUSTOM, 0, NULL, aux);
  op->op_targ = padix;
  op->op_ppaddr = &pp_slotpad;

  return op;
}


#define get_class_slots(stash)  MY_get_class_slots(aTHX_ stash)
static AV *MY_get_class_slots(pTHX_ HV *stash)
{
  GV **gvp = (GV **)hv_fetchs(stash, "SLOTS", 0);
  if(gvp)
    return GvAV(*gvp);

  gvp = (GV **)hv_fetchs(PL_curstash, "SLOTS", GV_ADD);
  GV *gv = *gvp;
  gv_init_pvn(gv, PL_curstash, "SLOTS", 5, 0);
  GvMULTI_on(gv);

  AV *slots = GvAVn(*gvp);

  /* Reserve slotix=0 for something special maybe? */
  av_push(slots, newSV(0));

  return slots;
}

#define get_this_class_slots()  MY_get_this_class_slots(aTHX)
static AV *MY_get_this_class_slots(pTHX)
{
  return get_class_slots(PL_curstash);
}


static int keyword_class(pTHX_ OP **op_ptr)
{
  lex_read_space(0);

  SV *packagename = lex_scan_ident(); // TODO: accept Package::Names
  if(!packagename)
    croak("Expected 'class' to be followed by package name");

  lex_read_space(0);

  ENTER;

  /* CARGOCULT from perl/op.c:Perl_package() */
  {
    SAVEGENERICSV(PL_curstash);
    save_item(PL_curstname);

    PL_curstash = (HV *)SvREFCNT_inc(gv_stashsv(packagename, GV_ADD));
    sv_setsv(PL_curstname, packagename);

    PL_hints |= HINT_BLOCK_SCOPE;
    PL_parser->copline = NOLINE;
  }

  // TODO: Accept VERSION

  {
    SV *isaname = newSVpvf("%s::ISA", SvPV_nolen(PL_curstname));
    SAVEFREESV(isaname);

    AV *isa = get_av(SvPV_nolen(isaname), GV_ADD);
    if(av_top_index(isa) >= 0)
      croak("Already have an @ISA list");

    av_push(isa, newSVpvs("Object::Pad::_base"));
  }

  // TODO: Accept ';' here to end a statement and set default class for
  // following code
  I32 save_ix = block_start(TRUE);
  OP *body = parse_block(0);
  body = block_end(save_ix, body);

  LEAVE;

  /* CARGOCULT from perl/perly.y:PACKAGE BAREWORD BAREWORD '{' */
  /* a block is a loop that happens once */
  *op_ptr = newWHILEOP(0, 1, NULL, NULL, body, NULL, 0);
  return KEYWORD_PLUGIN_STMT;
}

static int keyword_has(pTHX_ OP **op_ptr)
{
  lex_read_space(0);
  SV *name = lex_scan_lexvar();
  if(!name)
    croak("Expected a slot name");

  AV *slots = get_this_class_slots();

  // TODO: Check for name collisions
  av_push(slots, name);

  *op_ptr = newOP(OP_NULL, 0);
  return KEYWORD_PLUGIN_STMT;
}

static int keyword_method(pTHX_ OP **op_ptr)
{
  lex_read_space(0);
  SV *name = lex_scan_ident();
  lex_read_space(0);

  I32 floor_ix = start_subparse(FALSE, name ? 0 : CVf_ANON);
  SAVEFREESV(PL_compcv);

  OP *attrs = NULL;
  if(lex_peek_unichar(0) == ':') {
    lex_read_unichar(0);

    attrs = lex_scan_attrs(PL_compcv);
  }

  // TODO: Parse sub signatures
  // steal much code from F:AA here

  I32 save_ix = block_start(TRUE);

  OP *slotops = NULL;
  {
    PADOFFSET selfix = pad_add_name_pvs("$self", 0, NULL, NULL);
    if(selfix != 1)
      croak("ARGH: Expected that selfix = 1");

    slotops = op_append_list(OP_LINESEQ, slotops,
      /* $self = shift */
      newBINOP(OP_SASSIGN, 0, newOP(OP_SHIFT, 0), newPADSVOP(selfix)));

    AV *slots = get_this_class_slots();
    for(int slotix = 1; slotix <= av_top_index(slots); slotix++) {
      SV *slotname = (AvARRAY(slots))[slotix];

      PADOFFSET padix = pad_add_name_pvn(SvPV_nolen(slotname), SvCUR(slotname), 0, NULL, NULL);

      slotops = op_append_list(OP_LINESEQ, slotops,
        /* alias the padix from the slot */
        newSLOTPADOP(padix, slotix));
    }

    intro_my();
  }

  OP *body = parse_block(0);
  SvREFCNT_inc(PL_compcv);
  body = block_end(save_ix, body);

  if(PL_parser->error_count) {
    /* parse_block() still sometimes returns a valid body even if a parse
     * error happens.
     * We need to destroy this partial body before returning a valid(ish)
     * state to the keyword hook mechanism, so it will find the error count
     * correctly
     *   See https://rt.cpan.org/Ticket/Display.html?id=130417
     */
    op_free(body);
    *op_ptr = newOP(OP_NULL, 0);
    return name ? KEYWORD_PLUGIN_STMT : KEYWORD_PLUGIN_EXPR;
  }

  body = op_append_list(OP_LINESEQ, slotops, body);

  CV *cv = newATTRSUB(floor_ix,
    name ? newSVOP(OP_CONST, 0, SvREFCNT_inc(name)) : NULL,
    NULL,
    attrs,
    body);

  if(name) {
    *op_ptr = newOP(OP_NULL, 0);

    SvREFCNT_dec(name);
    return KEYWORD_PLUGIN_STMT;
  }
  else {
    *op_ptr = newUNOP(OP_REFGEN, 0,
      newSVOP(OP_ANONCODE, 0, (SV *)cv));

    return KEYWORD_PLUGIN_EXPR;
  }
}

static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static int my_keyword_plugin(pTHX_ char *kw, STRLEN kwlen, OP **op_ptr)
{
  HV *hints = GvHV(PL_hintgv);

  if((PL_parser && PL_parser->error_count) ||
     !hints)
    return (*next_keyword_plugin)(aTHX_ kw, kwlen, op_ptr);

  if(kwlen == 5 && strEQ(kw, "class") &&
      hv_fetchs(hints, "Object::Pad/class", 0))
    return keyword_class(aTHX_ op_ptr);

  if(kwlen == 3 && strEQ(kw, "has") &&
      hv_fetchs(hints, "Object::Pad/has", 0))
    return keyword_has(aTHX_ op_ptr);

  if(kwlen == 6 && strEQ(kw, "method") &&
      hv_fetchs(hints, "Object::Pad/method", 0))
    return keyword_method(aTHX_ op_ptr);

  return (*next_keyword_plugin)(aTHX_ kw, kwlen, op_ptr);
}

MODULE = Object::Pad    PACKAGE = Object::Pad::_base

SV *
new(class, ...)
  SV *class
  INIT:
    HV *stash;
    AV *slots;
    AV *self;
  CODE:
    // TODO: It'd be nice if we could inject a 'new' into the class at 'class'
    // time which would know how to do the right thing
    stash = gv_stashsv(class, 0);
    slots = get_class_slots(stash);

    self = newAV();
    av_push(self, newSV(0));

    for(int slotix = 1; slotix <= av_top_index(slots); slotix++) {
      char *slotname = SvPV_nolen((AvARRAY(slots))[slotix]);
      switch(slotname[0]) {
        case '$':
          av_push(self, newSV(0));
          break;
        case '@':
          av_push(self, (SV *)newAV());
          break;
        case '%':
          av_push(self, (SV *)newHV());
          break;

        default:
          croak("ARGV: notsure how to handle a slot sigil %c\n", slotname[0]);
      }
    }

    RETVAL = newRV_noinc((SV *)self);
    sv_bless(RETVAL, stash);

    if(hv_fetchs(stash, "CREATE", 0)) {
      /* TODO: check it actually has a CV slot */
      dSP;

      ENTER;
      SAVETMPS;

      ST(0) = RETVAL;
      PUSHMARK(SP-items); // evilness
      PUTBACK;

      call_method("CREATE", G_VOID);

      FREETMPS;
      LEAVE;
    }

  OUTPUT:
    RETVAL

MODULE = Object::Pad    PACKAGE = Object::Pad

BOOT:
  XopENTRY_set(&xop_slotpad, xop_name, "slotpad");
  XopENTRY_set(&xop_slotpad, xop_desc, "slotpad()");
  XopENTRY_set(&xop_slotpad, xop_class, OA_UNOP_AUX);
  Perl_custom_op_register(aTHX_ &pp_slotpad, &xop_slotpad);

  wrap_keyword_plugin(&my_keyword_plugin, &next_keyword_plugin);
