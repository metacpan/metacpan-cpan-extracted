#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdlib.h>
#include <sys/time.h>
#include <time.h>

I32 get_random( pTHX_ IV max_random, SV* s ) {
	struct timeval  tv;
	struct timezone tz;
	gettimeofday( &tv, &tz );

	struct tm *tm = localtime( &tv.tv_sec );
	srand( tv.tv_sec + tv.tv_usec );

	sv_setiv( s, rand() % max_random );
}

MODULE = Scalar::Random		PACKAGE = Scalar::Random		

void
randomize(SV * target, IV max_random)
	CODE:
		struct ufuncs uf;
    	uf.uf_val   = &get_random;
    	uf.uf_set   = NULL;
    	uf.uf_index = max_random + 1;

    	sv_magic(target, 0, PERL_MAGIC_uvar, (char*)&uf, sizeof(uf));
		srand( time(NULL) );
