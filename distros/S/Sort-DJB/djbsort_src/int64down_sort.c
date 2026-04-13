/* WARNING: auto-generated (by autogen/useint); do not edit */

#include "djbsort.h"
#include "int64down_sort.h"

void int64down_sort(int64_t *x,long long n)
{
  long long j;
  for (j = 0;j < n;++j) x[j] ^= -1;
  djbsort_int64(x,n);
  for (j = 0;j < n;++j) x[j] ^= -1;
}
