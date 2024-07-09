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

#include "DataChecks.h"

static OP *pp_is(pTHX)
{
  dSP;
  SV *checkspec = POPs;
  SV *value = POPs;

  /* TODO: Really we should build the checker at compiletime */
  struct DataChecks_Checker *checker = make_checkdata(checkspec);

  PUSHs(boolSV(check_value(checker, value)));

  free_checkdata(checker);

  RETURN;
}

static const struct XSParseInfixHooks hooks_is = {
  .cls            = XPI_CLS_MATCH_MISC,
  .permit_hintkey = "Syntax::Operator::Is/is",
  .ppaddr         = &pp_is,
};

MODULE = Syntax::Operator::Is    PACKAGE = Syntax::Operator::Is

BOOT:
  boot_xs_parse_infix(0.43);
  boot_data_checks(0.02);

  register_xs_parse_infix("Syntax::Operator::Is::is", &hooks_is, NULL);
