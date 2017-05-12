/* 
 * Public Domain getopt header
 *
 * $Id: rdfproc_getopt.h 7208 2003-09-04 10:16:20Z cmdjb $
 *
 */

#ifndef RDFPROC_GETOPT_H
#define RDFPROC_GETOPT_H

int getopt(int argc, char * const argv[], const char *optstring);
extern char *optarg;
extern int optind, opterr, optopt;

#endif
