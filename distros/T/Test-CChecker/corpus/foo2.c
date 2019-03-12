#if ! FOO_BAR_BAZ
#include <stdio.h>
#endif
int
main(int argc, char *argv[])
{
#if FOO_BAR_BAZ
  return 0;
#else
  printf("NOT DEFINED");
  return 1;
#endif
}
