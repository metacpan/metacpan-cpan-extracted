/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseInfix.h"

static OP *new_op_lexmeth(pTHX_ U32 flags, OP *lhs, OP *rhs, SV **parsedata, void *hookdata)
{
  /* LHS can be any ol' expression as the invocant, that's fine */
  OP *invocant = lhs;

  /* RHS must be an OP_ENTERSUB whose final kid is an OP_PADCV */
  if(rhs->op_type != OP_ENTERSUB)
    croak("Expected ->& to see a method call on RHS");

  OP *args = cUNOPx(rhs)->op_first;
  /* This should be an OP_LIST or a nulled-out ex-list */
  if(!(args->op_type == OP_LIST || (args->op_type == OP_NULL && args->op_targ == OP_LIST)))
    croak("ARGH expected to find list of args for OP_ENTERSUB");

  /* args should be a LIST whose first is OP_PUSHMARK and last is an OP_PADCV */
  OP *pushmark = cLISTOPx(args)->op_first;
  if(pushmark->op_type != OP_PUSHMARK)
    croak("ARGH expected to find an OP_PUSHMARK as first arg");

  OP *rv2cvop = cLISTOPx(args)->op_last;
  if(rv2cvop->op_type != OP_NULL || rv2cvop->op_targ != OP_RV2CV)
    croak("ARGH expected to find a NULL (ex-RV2CV)");
  OP *cvop = cUNOPx(rv2cvop)->op_first;
  if(cvop->op_type != OP_PADCV)
    croak("Expected a lexical function call on RHS of ->&");

  bool has_args = OpSIBLING(pushmark) != rv2cvop;
  if(has_args && rv2cvop->op_private & OPpENTERSUB_NOPAREN)
    croak("Lexical method call ->& with arguments must use parentheses");

  /* TODO: Assert that the CV of the lastarg is definitely a `my method` and
   * not simply `my sub`. But for that we'll first have to accept `my method`
   * as sub syntax.
   */

  /* All seems well; now just splice the invocant expression to be the first
   * argument after the pushmark
   */
  op_sibling_splice(args, pushmark, 0, invocant);

  /* The overall result is now simply the modified OP_ENTERSUB on the RHS */
  return rhs;
}

static const struct XSParseInfixHooks hooks_lexmeth = {
  .cls = XPI_CLS_HIGH_MISC,
  .new_op = &new_op_lexmeth,
};

MODULE = Object::Pad::LexicalMethods    PACKAGE = Object::Pad::LexicalMethods

BOOT:
  boot_xs_parse_infix(0.44);

  register_xs_parse_infix("Object::Pad::LexicalMethods::->&", &hooks_lexmeth, NULL);
