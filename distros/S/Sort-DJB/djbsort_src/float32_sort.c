/* WARNING: auto-generated (by autogen/useint); do not edit */

#include "djbsort.h"
#include "float32_sort.h"
#include "crypto_int32.h"

void float32_sort(float *x,long long n)
{
  int32_t *y = (int32_t *) x;
  long long j;

  for (j = 0;j < n;++j) {
    int32_t yj = y[j];
    yj ^= ((uint32_t) crypto_int32_negative_mask(yj)) >> 1;
    y[j] = yj;
  }
  djbsort_int32(y,n);
  for (j = 0;j < n;++j) {
    int32_t yj = y[j];
    yj ^= ((uint32_t) crypto_int32_negative_mask(yj)) >> 1;
    y[j] = yj;
  }
}
