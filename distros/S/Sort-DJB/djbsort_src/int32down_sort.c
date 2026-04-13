/* WARNING: auto-generated (by autogen/useint); do not edit */

#include "djbsort.h"
#include "int32down_sort.h"

void int32down_sort(int32_t *x,long long n)
{
  long long j;
  for (j = 0;j < n;++j) x[j] ^= -1;
  djbsort_int32(x,n);
  for (j = 0;j < n;++j) x[j] ^= -1;
}
