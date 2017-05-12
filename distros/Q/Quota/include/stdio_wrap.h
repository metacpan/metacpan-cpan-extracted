/*
 *  Access to the std I/O routines for people using sfio
 *  stdio FILE operators are needed by getmntent(3)
 */

FILE *std_fopen(const char *filename, const char *mode);
int std_fclose(FILE *fd);

