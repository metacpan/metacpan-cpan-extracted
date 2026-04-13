/* WARNING: auto-generated (by autogen/useint); do not edit */

#include "djbsort.h"
#include "uint32down_sort.h"

void uint32down_sort(uint32_t *x,long long n)
{
  long long j;
  for (j = 0;j < n;++j) x[j] ^= 0x7fffffff;
  djbsort_int32((int32_t *) x,n);
  for (j = 0;j < n;++j) x[j] ^= 0x7fffffff;
}
