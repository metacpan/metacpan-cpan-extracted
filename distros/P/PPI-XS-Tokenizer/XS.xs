#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#include "CPPTokenizerWrapper.h"

using namespace PPITokenizer; // is this bad?
// potentially bad, too:
#include "src/tokenizer.h"

#include "const-c.inc"


MODULE = PPI::XS::Tokenizer		PACKAGE = PPI::XS::Tokenizer

INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- --typemap=typemap.xsp XS/Tokenizer.xsp

MODULE = PPI::XS::Tokenizer		PACKAGE = PPI::XS::Tokenizer::Constants

INCLUDE: const-xs.inc


