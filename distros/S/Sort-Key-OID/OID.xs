/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define	set_bit(a,i)	((a)[(i) / 8] |= 1 << (7 - ((i) & 7)))

MODULE = Sort::Key::OID		PACKAGE = Sort::Key::OID		
PROTOTYPES: DISABLE
    
void
encode_oid(oid=NULL)
    SV *oid
PPCODE:
    if (!oid)
        oid = DEFSV;
    {
        STRLEN len;
        const char * str = SvPV(oid, len);
        STRLEN rlen = (len + 3) / 2;
        int i = 0;
        char *rstr;
        int ri = 0;
        int sep = -1;
        SV *ret = sv_2mortal(newSV(rlen));
        SvPOK_on(ret);
        rstr = SvPV_nolen(ret);
        Zero(rstr, rlen, char);

        while (i < len) {
            int j;
            int k, l;
            U32 v, lv, w;
            for (j = i, v = 0;
                 j < len && str[j] >= '0' && str[j] <= '9';
                 j++) {
                lv = v;
                v = v * 10 + (str[j] - '0');
                if (v < lv)
                    Perl_croak(aTHX_ "integer out of range inside OID");
            }
            if ((j == i) && (j > 0))
                goto bad_oid;
            if (j < len) {
                if (sep != -1) {
                    if (str[j] != sep)
                        goto bad_oid;
                }
                else {
                    if (isALNUM(str[j]))
                        goto bad_oid;
                    sep = str[j];
                }
            }
            i = j + 1;
            if (v == 0xffffffff) {
                k = 33;
                v = 3067833784U;
                for (k = 3; k < 32; k += 3) {
                    set_bit(rstr, ri);
                }
            }
            else {
                v++;
                for (w = 8, k = 3; k < 32 && v >= w; k += 3) {
                    v -= w;
                    w <<= 3;
                    set_bit(rstr, ri);
                    ri++;
                    /* printf("v: %u, w: %u, ri: %u, k: %u\n", v, w, ri, k); fflush(stdout); */
                }
            }
            
            if (k < 31)
                ri++;
            else
                k = 32;
            
            for (l = k; l;) {
                l--;
                if (v & ( 1 << l))
                    set_bit(rstr, ri);
                ri++;
            }
        }

        SvCUR_set(ret, (ri + 7) / 8);

        if (SvCUR(ret) > rlen)
            Perl_croak(aTHX_ "internal error, possible memory corruption");

        ST(0) = ret;
        XSRETURN(1);
        
        bad_oid:
        SvREFCNT_dec(ret);
        Perl_croak(aTHX_ "bad OID format");
    }
