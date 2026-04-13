/* WARNING: auto-generated (by autogen/useint); do not edit */

#include "djbsort.h"
#include "uint64down_sort.h"

void uint64down_sort(uint64_t *x,long long n)
{
  long long j;
  for (j = 0;j < n;++j) x[j] ^= 0x7fffffffffffffffULL;
  djbsort_int64((int64_t *) x,n);
  for (j = 0;j < n;++j) x[j] ^= 0x7fffffffffffffffULL;
}
