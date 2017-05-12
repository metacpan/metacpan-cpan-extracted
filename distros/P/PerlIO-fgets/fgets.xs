#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = PerlIO::fgets    PACKAGE = PerlIO::fgets

PROTOTYPES: ENABLE

void
fgets(fp, count)
    PerlIO *fp
    SSize_t count
  PROTOTYPE:
    *$
  PREINIT:
    dXSTARG;
  PPCODE:
    if (count < 0)
        XSRETURN_UNDEF;

    SvUPGRADE(TARG, SVt_PV);
    SvGROW(TARG, 256);
    SvCUR_set(TARG, 0);

    if (PerlIO_fast_gets(fp)) {

        while (count > 0) {
            SSize_t avail = PerlIO_get_cnt(fp);
            SSize_t take = 0;

            if (avail > 0)
                take = (count < avail) ? count : avail;

            if (take > 0) {
                STDCHAR *ptr = (STDCHAR *)PerlIO_get_ptr(fp);
                STDCHAR *found = memchr(ptr, '\n', take);

                if (found != NULL)
                    count = take = ++found - ptr;

                sv_catpvn_nomg(TARG, ptr, take);
                count -= take;
                avail -= take;
                PerlIO_set_ptrcnt(fp, (void *)ptr + take, avail);
            }

            if (count > 0 && avail <= 0)
                if (PerlIO_fill(fp) != 0)
                    break;
        }
    }
    else {
        int ch = EOF;

        while (count > 0) {
            SvGROW(TARG, SvCUR(TARG) + 256);
            STDCHAR *cur = SvPVX(TARG) + SvCUR(TARG);
            STDCHAR *end = SvPVX(TARG) + SvLEN(TARG) - 1;

            while (cur < end && count-- > 0 && (ch = PerlIO_getc(fp)) != EOF)
                if ((*cur++ = ch) == '\n')
                    break;

            SvCUR_set(TARG, cur - SvPVX(TARG));

            if (ch == EOF || ch == '\n')
                break;
        }
    }

    if (PerlIO_error(fp))
        XSRETURN_UNDEF;

    *SvEND(TARG) = '\0';
    SvPOK_only(TARG);
    PUSHTARG;

