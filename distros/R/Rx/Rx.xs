#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "Dump.h"
#include "regcomp.h"

#include <stdio.h>
#include <string.h>
#define STREQ(a,b) (strcmp(a,b)==0)
#ifndef MJD_DB
#define MJD_DB 1
#endif
#if MJD_DB
#define DEBUG_printf(x) printf x
#else
#define DEBUG_printf(x) 
#endif

extern RXCALLBACK the_callback;
extern unsigned let_finish_naturally;

MODULE = Rx		PACKAGE = Rx		

BOOT:
DEBUG_printf(("Booted.\n"));

unsigned
_xs_callback_glue(id)
        unsigned id;
        CODE:
        {
         AV *items = newAV(), 
            *Ilya_minus = get_av("::-", 0), *Ilya_plus = get_av("::+", 0);
         I32 n_backrefs = av_len(Ilya_minus);
         SV *pre, *match, *post;
         unsigned brn;

         av_extend(items, n_backrefs + 4);  /* XXX */
         pre   = get_sv("::`", 0);
         match = get_sv("::&", 0);
         post  = get_sv("::'", 0);
         DEBUG_printf(("callback glue: ($`=%s, $&=%s, $'=%s)\n", 
                SvPV_nolen(pre), SvPV_nolen(match), SvPV_nolen(post)));

         printf("@+=%p, @-=%p\n", Ilya_plus, Ilya_minus);
         av_store(items, 0, newSVpvf("%u", id)); 
         av_store(items, 1, pre);
         av_store(items, 2, match);
         av_store(items, 3, post);
         for (brn = 1; brn <= n_backrefs; brn++) {       
           SV **start = av_fetch(Ilya_plus,  brn, 0), 
              **end   = av_fetch(Ilya_minus, brn, 0),
              *brp = 0;

           if (start && end) {
             I32 s = SvIV(*start), e = SvIV(*end);
             if (s >= 0 && e >= 0) {
               brp = newSVpv("abc" + s, e-s);
               printf("$%d: %s\n", brn, SvPV_nolen(brp));
             } else {
               printf("$%d is undef (s=%d, e=%d).\n", brn, s, e);
             }
           } else {
             printf("$%d is undef (start=%p, end=%p).\n", brn, start, end);
           }
           av_store(items, brn+3, brp);
         }

         if (! let_finish_naturally) {
           let_finish_naturally = (*the_callback)(id, items);
         }
         
        }
        OUTPUT:
        RETVAL

int
opname_to_num(node_type)
        char *node_type;
        CODE:
        {
          unsigned i;
          RETVAL = -1;
          for (i=0; i < reg_num; i++) {
            if (STREQ(reg_name[i], node_type)) {
              RETVAL = i;
              break;
            }
          }
        }
        OUTPUT:
        RETVAL

SV *
rxbytecode(regex_string, options)
        char *options;
        char *regex_string;
        CODE: 
        {
        PMOP *pm = _options_to_pm(options);
        regexp *compiled_regex;
        char *xend = strchr(regex_string, '\0');

          {
            int save_PL_reginterp_cnt = PL_reginterp_cnt;
            PL_reginterp_cnt = I32_MAX;
            compiled_regex = pregcomp((char *)regex_string, xend, pm);
            PL_reginterp_cnt = save_PL_reginterp_cnt;
          }
        printf("rxbytecode: length %d?\n", *compiled_regex->endp - *compiled_regex->startp);
        RETVAL = newSVpv((char *)(compiled_regex->program), 100);
        }
        OUTPUT:
        RETVAL

SV *
rxdump(regex_string, options="")
        char *options;
        char *regex_string;
        CODE: 
        {
        PMOP *pm = _options_to_pm(options);
        SV *dumped_regex = dump_regex(regex_string, pm);
        RETVAL = dumped_regex;
        }
        OUTPUT:
        RETVAL

void
test_it(regex_string, options, target)
        SV *regex_string;
        SV *options;
        SV *target;
        CODE:
        {
        SV *hregex;
        unsigned retval_count;
        dSP;

        hregex = instrument(SvPV_nolen(regex_string),  
                            SvPV_nolen(options), 
                            0);
        start(hregex, target, test_callback);
        }
        
SV *
pl_instrument(regex_string, options)
        SV *regex_string;
        SV *options;
        CODE:
        {
          RETVAL = instrument(SvPV_nolen(regex_string),
                              SvPV_nolen(options),
                              0);
        }       
        OUTPUT:
        RETVAL
        
