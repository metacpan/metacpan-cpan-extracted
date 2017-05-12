#ifndef _CPPTokenizerWrapper_h_
#define _CPPTokenizerWrapper_h_

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

namespace PPITokenizer {
  class Tokenizer;
  class Token;
  class ExtendedToken;

  class CPPTokenizerWrapper {
    public:
      CPPTokenizerWrapper(SV* source);
      ~CPPTokenizerWrapper();
      SV* get_token();

    private:
      Tokenizer* fTokenizer;
      AV* fLines;

      enum SpecialTokenTypes {
        eSimple = 0,
        eExtended,
        eQuoteSingle,
        eQuoteDouble,
        eBacktick,
        eAttribute,
        eHereDoc
      };
      static const char* fgTokenClasses[43];
      static const int fgSpecialToken[43];

      static SV* S_newPerlObject(const char* className); /// Create a new Perl (hash) object blessed into className
      static char* S_stealPV(SV* sv, STRLEN& len); /// Steals ownership of the PV (string) contents of the scalar
      static void S_makeSections(ExtendedToken* token, HV* objHash);
      static void S_handleHereDoc(ExtendedToken* token, HV* objHash);
      static const char* S_getQuoteOperatorString(Token* token, unsigned long* length);
  };
}
#endif
