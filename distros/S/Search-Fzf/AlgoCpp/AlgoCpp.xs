/* #ifdef __cplusplus */
/* extern "C" { */
/* #include "EXTERN.h" */
/* #include "perl.h" */
/* #include "XSUB.h" */
/* #include "ppport.h" */
/* } */
/* #endif */

/* include your class headers here */
#include "algo.h"

/* AV* test() { */
/*     testCFun(); */
/*     printf("hello world\n"); */
/*     AV* ret = newAV(); */
/*     av_push(ret, newSViv(1)); */
/*     av_push(ret, newSViv(2)); */
/*     av_push(ret, newSViv(3)); */
/*     return ret; */
/* } */

/* We need one MODULE... line to start the actual XS section of the file.
 * The XS++ preprocessor will output its own MODULE and PACKAGE lines */
MODULE = Search::Fzf::AlgoCpp		PACKAGE = Search::FZF::AlgoCpp


## The include line executes xspp with the supplied typemap and the
## xsp interface code for our class.
## It will include the output of the xsubplusplus run.

INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- algo.xsp

## list you c function define here
## AV*
## test()
