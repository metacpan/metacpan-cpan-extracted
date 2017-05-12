
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc
#define NEED_sv_2pv_flags
#include "ppport.h"


MODULE = Redis::Parser::XS		PACKAGE = Redis::Parser::XS		

PROTOTYPES: ENABLE


SV *
parse_redis (buf, res)
    PROTOTYPE: $$
    CODE:
        char     *start, *end, *p, *mark, *mark2, *saved;
        AV       *av, *av2, *avout;
        size_t    num, len;
        size_t    i;

        if ( !SvOK (ST(0)) || !SvPOK (ST(0)) ) {
            warn("1st arg of parse_redis must be a string scalar");
            XSRETURN_UNDEF;
        }

        if ( !SvOK (ST(1)) || !SvRV (ST(1)) || 
             SvTYPE (SvRV(ST(1))) != SVt_PVAV  )
        {
            warn("2nd arg of parse_redis must be an arrayref");
            XSRETURN_UNDEF;
        }

        avout = (AV *) SvRV (ST(1));

        start = SvPV_nolen (ST(0));
        end   = start + SvCUR (ST(0)); 
        p     = start - 1;
        mark  = start;

    firstbyte:

        p++;

        if (p >= end) {
            goto eof;
        }

        switch (*p) {


            /* bulk reply */

            case '$':

                mark = p;
                len = 0;

                for ( p++ ; p < end ; p++ ) {

                    if ( isDIGIT (*p) ) {
                        len = len * 10 + (*p - '0');
                    }

                    if ( *p == 10  &&  *(p - 1) == 13 ) {  /* CR LF */

                        if ( isDIGIT (*(mark + 1)) ) {

                            if ( end - p - 1 < len + 2 ) {
                                p = mark;
                                goto eof;
                            }

                            av = newAV ();
                            av_push (av, newSVpvn (mark, 1));
                            av_push (av, newSVpvn (p + 1, len));
                            av_push (avout, newRV_noinc ((SV *) av));

                            p += len + 2;

                        } else if ( *(mark + 1) == '-') {

                            av = newAV ();
                            av_push (av, newSVpvn (mark, 1));
                            av_push (av, &PL_sv_undef);
                            av_push (avout, newRV_noinc ((SV *) av));

                        } else {
                            p = mark;
                            goto eof; 
                        }

                        goto firstbyte;
                    }
                }

                p = mark;
                break;


            /* multi bulk reply */

            case '*':

                mark = p;
                num = 0;

                for ( p++ ; p < end ; p++ ) {

                    if ( isDIGIT (*p) ) {
                        num = num * 10 + (*p - '0');
                    }

                    if ( *p == 10  &&  *(p - 1) == 13 ) {  /* CR LF */

                        if ( isDIGIT (*(mark + 1)) && num != 0 ) {

                            saved = p;

                            for ( i = 0; i < num; i++ ) {

                                p++;

                                if (p >= end) {
                                    p = mark;
                                    goto eof;
                                }

                                mark2 = p;
                                len = 0;

                                for ( p++ ; p < end ; p++ ) {

                                    if ( isDIGIT (*p) ) {
                                        len = len * 10 + (*p - '0');
                                    }

                                    if ( *p == 10  &&  *(p - 1) == 13 ) { 

                                      if ( *(mark2) == '$' ) {

                                        if ( isDIGIT (*(mark2 + 1)) ) {

                                            if ( end - p - 1  < len + 2 ) {
                                                p = mark;
                                                goto eof;
                                            }

                                            p += len + 2;
                                            goto cont;

                                        } else if ( *(mark2 + 1) == '-') {

                                            goto cont;

                                        } else {
                                            p = mark;
                                            goto eof; 
                                        }

                                      } else if ( *(mark2) == '+' ||
                                                  *(mark2) == '-' ||
                                                  *(mark2) == ':'    ) {

                                        goto cont;

                                      } else {

                                        XSRETURN_UNDEF;
                                      }
                                    }
                                }

                                p = mark;
                                goto eof;

                            cont:
                                continue;
                                
                            }

                            /*  message is complete and correct,
                             *  otherwise we would have bailed already
                             */

                            p = saved;

                            av2 = newAV ();
                            av  = newAV ();
                            av_push (avout, newRV_noinc ((SV *) av2));
                            av_push (av2,   newSVpvn (mark, 1));
                            av_push (av2,   newRV_noinc ((SV *) av));

                            for ( i = 0; i < num; i++ ) {

                                p++;
                                mark2 = p;
                                len = 0;

                                for ( p++ ; p < end ; p++ ) {

                                    if ( isDIGIT (*p) ) {
                                        len = len * 10 + (*p - '0');
                                    }

                                    if ( *p == 10  &&  *(p - 1) == 13 ) { 
                                      
                                      if ( *(mark2) == '$' ) {  

                                        if ( isDIGIT (*(mark2 + 1)) ) {
 
                                            av_push ( av, 
                                                      newSVpvn (p + 1, len) );

                                            p += len + 2;

                                        } else if ( *(mark2 + 1) == '-') {

                                            av_push ( av, &PL_sv_undef );

                                            break;
                                        }

                                        break;

                                      } else if ( *(mark2) == '+' ||
                                                  *(mark2) == '-' ||
                                                  *(mark2) == ':'    ) {
                                        AV *avtmp;
                                        
                                        avtmp = newAV ();
                                        av_push (avtmp, 
                                            newSVpvn (mark2, 1));
                                        av_push (avtmp, 
                                            newSVpvn (mark2 + 1, 
                                                (p - mark2 - 2)));
                                        av_push (av, 
                                            newRV_noinc ((SV *) avtmp));

                                        break;

                                      } else {

                                        XSRETURN_UNDEF; /* never happens */
                                      }
                                    }
                                }
                            }

                            goto firstbyte;

                        } else if ( isDIGIT (*(mark + 1)) && num == 0 ) {

                            av = newAV ();
                            av_push (av, newSVpvn (mark, 1));
                            av_push (av, newRV_noinc ((SV *) newAV ()));
                            av_push (avout, newRV_noinc ((SV *) av));

                        } else if ( *(mark + 1) == '-') {

                            av = newAV ();
                            av_push (av, newSVpvn (mark, 1));
                            av_push (av, &PL_sv_undef);
                            av_push (avout, newRV_noinc ((SV *) av));

                        } else {
                            p = mark;
                            goto eof; 
                        }

                        goto firstbyte;
                    }
                }

                p = mark;
                break;


            /* status reply, error reply, integer reply */

            case '+':
            case '-':
            case ':':

                mark = p;

                for ( p++ ; p < end ; p++ ) {

                    if ( *p == 10  &&  *(p - 1) == 13 ) {  /* CR LF */

                        av = newAV ();
                        av_push (av, newSVpvn (mark, 1));
                        av_push (av, newSVpvn (mark + 1, (p - mark - 2)));
                        av_push (avout, newRV_noinc ((SV *) av));

                        goto firstbyte;
                    }
                }

                p = mark;
                break;


            /* junk */
                
            default:
                
                if (p == start) {    /* incorrect first byte == junk */
                    XSRETURN_UNDEF;
                }

                break;
        }

    eof:

        if (p - start == 0) {
            XSRETURN_PV ("0 but true");
        } else {
            RETVAL = newSViv(p - start);
        }

    OUTPUT:
        RETVAL

