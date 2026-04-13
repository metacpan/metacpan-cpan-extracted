/* WARNING: auto-generated (by autogen/useint); do not edit */

#include "djbsort.h"
#include "uint64_sort.h"

void uint64_sort(uint64_t *x,long long n)
{
  long long j;
  for (j = 0;j < n;++j) x[j] ^= 0x8000000000000000ULL;
  djbsort_int64((int64_t *) x,n);
  for (j = 0;j < n;++j) x[j] ^= 0x8000000000000000ULL;
}
