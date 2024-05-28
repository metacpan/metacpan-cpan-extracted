extern "C" { 
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "XSUB.h" 
//#include "perl.h"
} 

/* include your class headers here */
#include "algo.h"


/* We need one MODULE... line to start the actual XS section of the file.
 * The XS++ preprocessor will output its own MODULE and PACKAGE lines */
MODULE = Search::Fzf::AlgoCpp		PACKAGE = Search::FZF::AlgoCpp


## The include line executes xspp with the supplied typemap and the
## xsp interface code for our class.
## It will include the output of the xsubplusplus run.

INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- algo.xsp

## list you c function define here
