#ifndef __HARNESS_H
#define __HARNESS_H

char **regxstring_generate_random_strings_from_regex(
	const char *regx, /* the regex */
	int N,		  /* number of strings to produce */
	int debug	  /* set to 1 for debugging */
);

#endif
