#ifdef __cplusplus
extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}
#endif

/* include your class headers here */
#include "Agent.h"

/* We need one MODULE... line to start the actual XS section of the file.
 * The XS++ preprocessor will output its own MODULE and PACKAGE lines */
MODULE = NewRelic::Agent		PACKAGE = NewRelic::Agent

## The include line executes xspp with the supplied typemap and the
## xsp interface code for our class.
## It will include the output of the xsubplusplus run.

INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- NewRelic-Agent.xsp


