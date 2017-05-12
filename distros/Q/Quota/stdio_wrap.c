/*
 *  Access to the std I/O routines for people using sfio
 *  stdio FILE operators are needed by getmntent(3)
 */

#include <stdio.h>

FILE *std_fopen(const char *filename, const char *mode)
{
  return fopen(filename, mode);
}

int std_fclose(FILE *fd)
{
  return fclose(fd);
}

