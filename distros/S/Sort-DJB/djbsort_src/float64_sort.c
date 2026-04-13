/* WARNING: auto-generated (by autogen/useint); do not edit */

#include "djbsort.h"
#include "float64_sort.h"
#include "crypto_int64.h"

void float64_sort(double *x,long long n)
{
  int64_t *y = (int64_t *) x;
  long long j;

  for (j = 0;j < n;++j) {
    int64_t yj = y[j];
    yj ^= ((uint64_t) crypto_int64_negative_mask(yj)) >> 1;
    y[j] = yj;
  }
  djbsort_int64(y,n);
  for (j = 0;j < n;++j) {
    int64_t yj = y[j];
    yj ^= ((uint64_t) crypto_int64_negative_mask(yj)) >> 1;
    y[j] = yj;
  }
}
