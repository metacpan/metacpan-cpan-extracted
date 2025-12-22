#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

void tweetnacl_crypto_sk_to_pk(unsigned char *pk, const unsigned char *sk);

MODULE = Monero::Keys		PACKAGE = Monero::Keys

SV *
_generate_pk_from_sk(SV* sk)
    CODE:
    {
        int rv;
        unsigned char *sk_data=NULL;
        unsigned char pk_data[32];
        STRLEN sk_len = 0;

        if (SvOK(sk)) {
          sk_data = (unsigned char *)SvPVbyte(sk, sk_len);
        }
        if (sk_len != 32) croak("FATAL: seed must be 32 bytes long");
        tweetnacl_crypto_sk_to_pk(pk_data, sk_data);
        RETVAL = newSVpv((char *)pk_data, 32);
    }
    OUTPUT:
        RETVAL

