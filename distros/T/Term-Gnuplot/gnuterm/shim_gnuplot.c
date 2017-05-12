#include <stdio.h>
#include <mousing.h>

static void
croak(char *str)
{
   fprintf(stderr, "%s\n", str);
}

#define SET_OPTIONS_FROM_STRING
#define GNUPLOT_OUTLINE_STDOUT
#define DONT_POLLUTE_INIT
#ifdef USE_ACTIVE_EVENTS
#  define DEFINE_GP4MOUSE
#endif
#include "Gnuplot.h"

static int dummy;
