/* $Id: mag.c,v 1.1 2007/03/16 17:16:14 dk Exp $ */

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <magick/MagickCore.h>
#include "mag.h"

void magick_croak( char * what, ExceptionInfo * exception )
{
        char message[MaxTextExtent] = "unknown exception";
        if ((exception)->severity != UndefinedException)
#if MagickLibVersion > 0x676
                FormatLocaleString( 
#else
                FormatMagickString( 
#endif
                        message, 
                        MaxTextExtent,
                        "Exception %d: %s%s%s%s",
                        (exception)->severity, 
                        (exception)->reason ?
                                GetLocaleExceptionMessage(
                                        (exception)->severity,
                                        (exception)->reason
                        ) : "Unknown", 
                        (exception)->description ? " (" : "",
                        (exception)->description ? GetLocaleExceptionMessage(
                                (exception)->severity,
                                (exception)->description
                        ) : "",
                        (exception)->description ? ")" : ""
                );
	DestroyExceptionInfo( exception);
        croak("%s: %s", what, message);
}


#ifdef __cplusplus
}
#endif
