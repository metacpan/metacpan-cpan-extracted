#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


int ge_frombytes_vartime(unsigned char *s);

MODULE = Solana::SPLAddress		PACKAGE = Solana::SPLAddress

int
check_pub_address_is_ok(SV* address)
    CODE:
    {
        unsigned char* tmp = NULL;
        STRLEN len = 0;
        if (SvOK(address)) {
            tmp = (unsigned char*)SvPVbyte(address, len);
        }
        if (len != 32) croak("owner must be 32 bytes long");

        RETVAL = ge_frombytes_vartime(tmp) != -1;
    }
    OUTPUT:
        RETVAL
