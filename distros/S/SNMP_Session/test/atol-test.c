/*
 atol-test.c

 Date Created: Sun Jun 22 21:20:45 1997
 Author:       Simon Leinen  <simon@switch.ch>
 */

#include <stdlib.h>
#include <stdio.h>

void atol_test (const char *);

int
main (int argc, char **argv)
{
  unsigned k;

  for (k = 1; k < argc; ++k)
    {
      atol_test (argv[k]);
    }
  return 0;
}

void
atol_test (const char *string)
{
  long l, l2;
  unsigned long ul;
  long long ll;

  l = atol (string);
  l2 = strtol (string, 0, 10);
  ul = strtoul (string, 0, 10);
  ll = atoll (string);
  printf ("%s => %ld(atol) %lld(atoll) %ld(strtol) %lu(strtoul)\n", string, l, ll, l2, ul);
}
