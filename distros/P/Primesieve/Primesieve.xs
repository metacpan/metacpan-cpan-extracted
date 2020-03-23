#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdlib.h>
#include <primesieve.h>

typedef primesieve_iterator *Primesieve;


MODULE = Primesieve		PACKAGE = Primesieve

PROTOTYPES: ENABLE

void
generate_primes (start, stop)
        UV start
        UV stop
PREINIT:
        size_t i;
        size_t size;
        UV *ret;
PPCODE:
        ret = primesieve_generate_primes (start, stop, &size, UINT64_PRIMES);
        if (!size) {
                XSRETURN_EMPTY;
        }
        if (GIMME_V == G_ARRAY) {
                EXTEND (SP, size);
                for (i = 0; i < size; i++) {
                        mPUSHu (ret[i]);
                }
        } else {
                AV *av;
                av = newAV ();
                av_extend (av, size);
                XPUSHs (newRV_noinc ((SV*)av));
                for (i = 0; i < size; i++) {
                        av_push (av, newSVuv (ret[i]));
                }
        }
        primesieve_free (ret);
        


void
generate_n_primes (n, start)
        UV n
        UV start
PREINIT:
        size_t i;
        UV *ret;
PPCODE:
        if (!n) {
                XSRETURN_EMPTY;
        }
        ret = (UV*) primesieve_generate_n_primes (n, start, UINT64_PRIMES);
        if (GIMME_V == G_ARRAY) {
                EXTEND (SP, n);
                for (i = 0; i < n; i++) {
                            mPUSHu (ret[i]);
                }
        } else {
                AV *av;
                av = newAV ();
                av_extend (av, n);
                XPUSHs (newRV_noinc ((SV*)av));
                for (i = 0; i < n; i++) {
                        av_push (av, newSVuv (ret[i]));
                }
        }
        primesieve_free (ret);


UV
nth_prime (n, start)
    IV n
    UV start
CODE:
        RETVAL = primesieve_nth_prime (n, start);
OUTPUT:
        RETVAL

UV
count_primes (start, stop)
        UV start
        UV stop
ALIAS:
        count_twins = 1
        count_triplets = 2
        count_quadruplets = 3
        count_quintuplets = 4
        count_sextuplets = 5
CODE:
        switch (ix) {
            case 0: RETVAL = primesieve_count_primes (start, stop); break;
            case 1: RETVAL = primesieve_count_twins (start, stop); break;
            case 2: RETVAL = primesieve_count_triplets (start, stop); break;
            case 3: RETVAL = primesieve_count_quadruplets (start, stop); break;
            case 4: RETVAL = primesieve_count_quintuplets (start, stop); break;
            case 5: RETVAL = primesieve_count_sextuplets (start, stop); break;
        }
OUTPUT:
        RETVAL

void
print_primes (start, stop)
        UV start
        UV stop
ALIAS:
        print_twins = 1
        print_triplets = 2
        print_quadruplets = 3
        print_quintuplets = 4
        print_sextuplets = 5
CODE:
        switch (ix) {
            case 0: primesieve_print_primes (start, stop); break;
            case 1: primesieve_print_twins (start, stop); break;
            case 2: primesieve_print_triplets (start, stop); break;
            case 3: primesieve_print_quadruplets (start, stop); break;
            case 4: primesieve_print_quintuplets (start, stop); break;
            case 5: primesieve_print_sextuplets (start, stop); break;
        }

UV
get_max_stop ()
CODE:
        RETVAL = primesieve_get_max_stop ();
OUTPUT:
        RETVAL

UV
get_sieve_size ()
CODE:
        RETVAL = primesieve_get_sieve_size ();
OUTPUT:
        RETVAL


IV
get_num_threads ()
CODE:
        RETVAL = primesieve_get_num_threads ();
OUTPUT:
        RETVAL

void
set_sieve_size (newsize)
        IV newsize
CODE:
        primesieve_set_sieve_size (newsize);

void
set_num_threads (threads)
        IV threads
CODE:
        primesieve_set_num_threads (threads);

Primesieve
new (class)
CODE:
        RETVAL = malloc (sizeof (*RETVAL));
        primesieve_init (RETVAL);
OUTPUT:
        RETVAL

void
DESTROY (it)
        Primesieve it
CODE:
        primesieve_free_iterator (it);
        free (it);

UV
next_prime (it)
        Primesieve it
CODE:
        RETVAL = primesieve_next_prime (it);
OUTPUT:
        RETVAL

#if PRIMESIEVE_VERSION_MAJOR >= 6

UV
prev_prime (it)
        Primesieve it
CODE:
        RETVAL = primesieve_prev_prime (it);
OUTPUT:
        RETVAL

#endif

void
skipto (it, start, stop_hint)
        Primesieve it
        UV start
        UV stop_hint
CODE:
        primesieve_skipto (it, start, stop_hint);
