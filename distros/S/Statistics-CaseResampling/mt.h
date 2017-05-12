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

struct mt {
    uint32_t mt[N];
    int mti;
};

struct mt *mt_setup(uint32_t seed);
struct mt *mt_setup_array(uint32_t *array, int n);
void mt_free(struct mt *self);
double mt_genrand(struct mt *self);

#endif
