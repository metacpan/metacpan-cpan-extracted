/* 
 * Public Domain getopt header
 *
 * $Id: rasqal_getopt.h 3311 2004-02-23 14:36:45Z cmdjb $
 *
 */

#ifndef RASQAL_GETOPT_H
#define RASQAL_GETOPT_H

#ifdef __cplusplus
extern "C" {
#endif

int getopt(int argc, char * const argv[], const char *optstring);
extern char *optarg;
extern int optind, opterr, optopt;

#ifdef __cplusplus
}
#endif

#endif
