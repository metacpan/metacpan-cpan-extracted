#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

SV*  /* AV if want_pos or want_all, PV otherwise */
lcss(
    int         wide,      /* s and t are in the UTF8=1 format    */
    const char* s,         /* Format determined by utf8 parameter */
    STRLEN      s_len,     /* Byte length of s                    */
    const char* t,         /* Format determined by utf8 parameter */
    STRLEN      t_len,     /* Byte length of t                    */
    int         min,       /* Ignore substrings shorter than this */
    int         want_pos,  /* Return positions as well as strings */
    int         want_all   /* Return all matches, or just one     */
);
