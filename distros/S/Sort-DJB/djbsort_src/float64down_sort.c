/* WARNING: auto-generated (by autogen/useint); do not edit */

#include "djbsort.h"
#include "float64down_sort.h"
#include "crypto_int64.h"

void float64down_sort(double *x,long long n)
{
  int64_t *y = (int64_t *) x;
  long long j;

  for (j = 0;j < n;++j) {
    int64_t yj = y[j];
    yj ^= ((uint64_t) crypto_int64_negative_mask(yj)) >> 1;
    y[j] = yj ^ -1;
  }
  djbsort_int64(y,n);
  for (j = 0;j < n;++j) {
    int64_t yj = y[j] ^ -1;
    yj ^= ((uint64_t) crypto_int64_negative_mask(yj)) >> 1;
    y[j] = yj;
  }
}
