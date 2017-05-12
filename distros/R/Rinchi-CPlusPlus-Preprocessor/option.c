/*
 * UUID: a61871db-f300-11dc-bb01-00502c05c241
 * Author: Brian M. Ames, bames@apk.net
 * Copyright: Copyright (C) 2008 by Brian M. Ames
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <popt.h>
#include "parser_routines.h"

#define CL_OPT_DEF 1
#define CL_OPT_DEP 2
#define CL_OPT_OUT 3
#define CL_OPT_UOC 4
#define CL_OPT_INC 5

int drop_lines=0;
extern int yypp_debug;
int tree_debug=0;
int out_comments=0;
int out_location=0;
int mod_time=0;
char *defbuf;
char *dfilepath;
char *ofilepath;
char *ifilepath;
const char **fargv;
char *uocbuf;
char *incbuf;
extern FILE *infile;
//extern FILE *outfile;
extern FILE *depfile;

#define DEFINE_OPTION(longName, shortName, argInfo, arg, val, descript, argDescript) \
 {#longName, shortName, argInfo, &arg, val, descript, argDescript},

/*
 *
 */
struct poptOption optionTable[] = {
  POPT_AUTOHELP
#include "option.def"
  {NULL,  '\0', POPT_ARG_NONE,   NULL,          0, NULL, NULL}
};

poptContext optionContext;

/*
 *
 */
void parseArgv(int argc, const char **argv) {
  int flags = 0;
  int result;
  optionContext = poptGetContext("main", argc, argv, optionTable, flags);
  poptSetOtherOptionHelp(optionContext, "[OPTION...] filename");
  if (argc == 1 || (argc > 1 && (strcmp(argv[1],"--help")==0 || strcmp(argv[1],"-?")==0))) {
    printf("CPlusPlus Preprocessor.\n");
    printf("  Created by Brian M. Ames.\n");
    poptPrintHelp(optionContext, stdout, 0);
    exit(0);
  }
  while((result = poptGetNextOpt(optionContext)) > 0) {
    switch(result) {
    case CL_OPT_DEF:
      handle_command_line_define(defbuf);
      break;
    case CL_OPT_DEP:
      printf("dep %s\n", dfilepath);
      if (depfile == NULL) {
        depfile = fopen(dfilepath,"w");
        if (!depfile) {
          fprintf(stderr,"could not open dependency file '%s'\n",dfilepath);
        }
      } else {
        fprintf(stderr,"more than one dependency file specified\n");
      }
      break;
    case CL_OPT_OUT:
/*
      if (outfile == NULL) {
        outfile = fopen(ofilepath,"w");
        if (!outfile) {
          fprintf(stderr,"could not open output file '%s'\n",ofilepath);
          exit(1);
        }
      } else {
        fprintf(stderr,"more than one output file specified\n");
        exit(1);
      } */
      break;
    case CL_OPT_UOC:
      define_use_on_code(uocbuf);
      break;
    case CL_OPT_INC:
      define_include_directory(strdup(incbuf));
      break;
    default:
      break;
    }
  }
  poptFreeContext(optionContext);
}


