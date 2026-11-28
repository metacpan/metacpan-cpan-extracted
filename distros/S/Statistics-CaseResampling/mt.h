#ifndef _S_CS_MATH_MT_H_
#define _S_CS_MATH_MT_H_

#if defined(_MSC_VER)
typedef unsigned __int32 uint32_t;
#elif defined(__linux__) || defined(__GLIBC__) || defined(__WIN32__) || defined(__APPLE__)
#include <stdint.h>
#elif defined(__osf__)
#include <inttypes.h>
#else
#include <sys/types.h>
#endif

enum { N = 624, M = 397 };

#if defined(_MSC_VER)
typedef unsigned __int64 cs_u64;
#else
typedef unsigned long long cs_u64;
#endif

struct mt {
    uint32_t mt[N];
    int mti;
    int auto_seeded;
    long pid;
};

struct mt *mt_setup(uint32_t seed);
struct mt *mt_setup_array(uint32_t *array, int n);
void mt_free(struct mt *self);
int mt_os_entropy(uint32_t *out, int nwords);
uint32_t mt_genrand_int32(struct mt *self);
uint32_t mt_genrand_bounded(struct mt *self, uint32_t range);
double mt_genrand(struct mt *self);

#endif
