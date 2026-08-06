#include "stencil.h"

UV stencil_stat_buf_grows = 0;

void stencil_buf_init(pTHX_ stencil_buf *b, size_t hint)
{
    if (hint < 64)
        hint = 64;
    b->sv   = newSV(hint);
    SvPOK_on(b->sv);
    b->cur  = SvPVX(b->sv);
    b->end  = SvPVX(b->sv) + SvLEN(b->sv) - 1;
    b->utf8 = 0;
#ifdef PERL_IMPLICIT_CONTEXT
    b->perl = aTHX;
#endif
}

void stencil_buf_grow(stencil_buf *b, size_t need)
{
#ifdef PERL_IMPLICIT_CONTEXT
    dTHXa(b->perl);
#endif
    size_t used   = (size_t)(b->cur - SvPVX(b->sv));
    size_t want   = used + need + 1;
    stencil_stat_buf_grows++;
    size_t newcap = SvLEN(b->sv) + (SvLEN(b->sv) >> 1);
    if (newcap < want)
        newcap = want;
    SvGROW(b->sv, (STRLEN)newcap);
    b->cur = SvPVX(b->sv) + used;
    b->end = SvPVX(b->sv) + SvLEN(b->sv) - 1;
}

SV *stencil_buf_done(stencil_buf *b)
{
    SvCUR_set(b->sv, (STRLEN)(b->cur - SvPVX(b->sv)));
    *b->cur = '\0';
    if (b->utf8)
        SvUTF8_on(b->sv);
    return b->sv;
}
