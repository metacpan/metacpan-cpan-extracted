#include "mt.h"

#include <stdlib.h>
#include <stdio.h>

/* This code is based on mt19937ar.c, written by Takuji Nishimura and
   Makoto Matsumoto (20020126). Further details are available at
   <http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/emt.html>.

   REFERENCE
   M. Matsumoto and T. Nishimura,
   "Mersenne Twister: A 623-Dimensionally Equidistributed Uniform
   Pseudo-Random Number Generator",
   ACM Transactions on Modeling and Computer Simulation,
   Vol. 8, No. 1, January 1998, pp 3--30. */

void mt_init_seed( struct mt *m, uint32_t seed )
{
    int i;
    uint32_t *mt;

    mt = m->mt;
    mt[0] = seed & 0xffffffff;
    for ( i = 1; i < N; i++ )
        mt[i] = 1812433253 * (mt[i-1]^(mt[i-1]>>30)) + i;
    m->mti = N;
}

struct mt *mt_setup(uint32_t seed)
{
    struct mt *self = malloc(sizeof(struct mt));

    if (self)
        mt_init_seed( self, seed );

    return self;
}

struct mt *mt_setup_array( uint32_t *array, int n )
{
    int i, j, k;
    struct mt *self = malloc(sizeof(struct mt));
    uint32_t *mt;

    if (self) {
        mt_init_seed( self, 19650218UL );

        i = 1; j = 0;
        k = ( N > n ? N : n );
        mt = self->mt;

        for (; k; k--) {
            mt[i] = (mt[i] ^ ((mt[i-1] ^ (mt[i-1] >> 30)) * 1664525UL))
                    + array[j] + j;
            i++; j++;
            if (i>=N) { mt[0] = mt[N-1]; i=1; }
            if (j>=n) j=0;
        }
        for (k=N-1; k; k--) {
            mt[i] = (mt[i] ^ ((mt[i-1] ^ (mt[i-1] >> 30)) * 1566083941UL)) - i;
            i++;
            if (i>=N) { mt[0] = mt[N-1]; i=1; }
        }

        mt[0] = 0x80000000UL;
    }

    return self;
}

void mt_free(struct mt *self)
{
    free(self);
}

/* Returns a pseudorandom number which is uniformly distributed in [0,1) */
double mt_genrand(struct mt *self)
{
    int kk;
    uint32_t y;
    static uint32_t mag01[2] = {0x0, 0x9908b0df};
    static const uint32_t UP_MASK = 0x80000000, LOW_MASK = 0x7fffffff;

    if (self->mti >= N) {
        for (kk = 0; kk < N-M; kk++) {
            y = (self->mt[kk] & UP_MASK) | (self->mt[kk+1] & LOW_MASK);
            self->mt[kk] = self->mt[kk+M] ^ (y >> 1) ^ mag01[y & 1];
        }

        for (; kk < N-1; kk++) {
            y = (self->mt[kk] & UP_MASK) | (self->mt[kk+1] & LOW_MASK);
            self->mt[kk] = self->mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 1];
        }

        y = (self->mt[N-1] & UP_MASK) | (self->mt[0] & LOW_MASK);
        self->mt[N-1] = self->mt[M-1] ^ (y >> 1) ^ mag01[y & 1];

        self->mti = 0;
    }
  
    y  = self->mt[self->mti++];
    y ^= y >> 11;
    y ^= y <<  7 & 0x9d2c5680;
    y ^= y << 15 & 0xefc60000;
    y ^= y >> 18;

    return y*(1.0/4294967296.0);
}
