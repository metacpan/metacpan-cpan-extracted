#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <shadow.h>

MODULE = Passwd::Linux		PACKAGE = Passwd::Linux		

int
xs_getlock()
    CODE:
        
        RETVAL = lckpwdf();
                          
	OUTPUT:     
	RETVAL      

int
xs_releaselock()
    CODE:

        RETVAL = ulckpwdf();

    OUTPUT:
    RETVAL
		
