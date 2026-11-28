#include "mt.h"

#include <errno.h>
#include <stdlib.h>
#include <stdio.h>

#ifdef _WIN32
#  ifndef WIN32_LEAN_AND_MEAN
#    define WIN32_LEAN_AND_MEAN
#  endif
#  include <windows.h>
#elif !defined(__VMS) && (defined(__unix__) || defined(__unix) || defined(__APPLE__) || defined(__linux__) || defined(__CYGWIN__))
#  include <sys/types.h>
#  include <fcntl.h>
#  include <unistd.h>
#  define CS_HAVE_URANDOM 1
#endif

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

    if (self) {
        mt_init_seed( self, seed );
        self->auto_seeded = 0;
        self->pid = 0;
    }

    return self;
}

struct mt *mt_setup_array( uint32_t *array, int n )
{
    int i, j, k;
    struct mt *self = malloc(sizeof(struct mt));
    uint32_t *mt;

    if (self) {
        mt_init_seed( self, 19650218UL );
        self->auto_seeded = 0;
        self->pid = 0;

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
    if (self)
        free(self);
}

int mt_os_entropy(uint32_t *out, int nwords)
{
    if (out == NULL || nwords <= 0)
        return 0;
#ifdef _WIN32
    {
        typedef long (__stdcall *cs_bcrypt_fn)(void *, unsigned char *, unsigned long, unsigned long);
        typedef unsigned char (__stdcall *cs_rtl_fn)(void *, unsigned long);
        HMODULE hBcrypt;
        HMODULE hAdvapi;
        unsigned long nbytes = (unsigned long)((size_t)nwords * sizeof(uint32_t));

        hBcrypt = LoadLibraryA("bcrypt.dll");
        if (hBcrypt != NULL) {
            cs_bcrypt_fn fn = (cs_bcrypt_fn)GetProcAddress(hBcrypt, "BCryptGenRandom");
            if (fn != NULL && fn(NULL, (unsigned char *)out, nbytes, 0x00000002UL) == 0) {
                FreeLibrary(hBcrypt);
                return 1;
            }
            FreeLibrary(hBcrypt);
        }

        hAdvapi = LoadLibraryA("advapi32.dll");
        if (hAdvapi != NULL) {
            cs_rtl_fn fn = (cs_rtl_fn)GetProcAddress(hAdvapi, "SystemFunction036");
            if (fn != NULL && fn(out, nbytes) != 0) {
                FreeLibrary(hAdvapi);
                return 1;
            }
            FreeLibrary(hAdvapi);
        }
        return 0;
    }
#elif defined(CS_HAVE_URANDOM)
    {
        int saved_errno = errno;
        int fd;
        unsigned char *ptr = (unsigned char *)out;
        size_t need = (size_t)nwords * sizeof(uint32_t);
        size_t got = 0;

        fd = open("/dev/urandom", O_RDONLY);
        if (fd < 0) {
            errno = saved_errno;
            return 0;
        }
        while (got < need) {
            ssize_t r = read(fd, ptr + got, need - got);
            if (r < 0) {
                if (errno == EINTR)
                    continue;
                break;
            }
            if (r == 0)
                break;
            got += (size_t)r;
        }
        close(fd);
        errno = saved_errno;
        return (got == need) ? 1 : 0;
    }
#else
    return 0;
#endif
}

/* Returns a uniformly distributed 32-bit pseudorandom integer */
uint32_t mt_genrand_int32(struct mt *self)
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

    return y;
}

/* Returns an unbiased pseudorandom integer in [0, range) using Lemire's method */
uint32_t mt_genrand_bounded(struct mt *self, uint32_t range)
{
    uint32_t x, l;
    cs_u64 m;
    if (range <= 1)
        return 0;
    x = mt_genrand_int32(self);
    m = (cs_u64)x * (cs_u64)range;
    l = (uint32_t)m;
    if (l < range) {
        uint32_t t = (uint32_t)(0u - range) % range;
        while (l < t) {
            x = mt_genrand_int32(self);
            m = (cs_u64)x * (cs_u64)range;
            l = (uint32_t)m;
        }
    }
    return (uint32_t)(m >> 32);
}

/* Returns a pseudorandom number which is uniformly distributed in [0,1) */
double mt_genrand(struct mt *self)
{
    return mt_genrand_int32(self) * (1.0 / 4294967296.0);
}
