/*
 * UUID: d06a9c9c-f594-11dc-8f19-00502c05c241
 * Author: Brian M. Ames, bames@apk.net
 * Copyright: Copyright (C) 2008 by Brian M. Ames
 */

#include <stdlib.h>
#include <string.h>


#ifndef __USE_GNU

/*
 * This function copies the null-terminated string S or at most
 * SIZE characters  into a newly allocated string.  The string is 
 * allocated using `malloc'.  If `malloc' cannot allocate
 * space for the new string, `strndup' returns a null pointer.
 * Otherwise it returns a pointer to the new string.

 * If the length of S is more than SIZE, then `strndup' copies just
 * the first SIZE characters and adds a closing null terminator.
 * Otherwise all characters are copied and the string is terminated.

 * 'strndup' is available as a GNU extension.
 */

char *strndup(const char *S, size_t SIZE) {
  size_t len_S;
  size_t sz_malloc;
  char *retval;

  // determine the length of the result
  len_S = strlen(S);
  sz_malloc = ((len_S > SIZE) ? SIZE : len_S) + 1;

  // Allocate and copy
  retval = (char *) malloc(sz_malloc);

  if (retval != NULL) {
    strncpy(retval, S, SIZE);
    retval[sz_malloc-1] = 0;  // strncpy doesn't guarantee a null here.
  }

  return retval;
}

#endif

/*
 * Duplicate a string less first and last characters.
 */
char *strdup_less(const char *str) {
  size_t size = strlen(str)-2;
  if(size >= 0) {
    return strndup(str+1, size);
  } else {
    return 0;
  }
}

