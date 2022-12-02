#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <math.h>

enum PendingStackType {
    array, map, set, attribute, push
};
struct pending_stack {
    AV *data;
    struct pending_stack *prev;
    long expected;
    enum PendingStackType type;
};

void
add_value(struct pending_stack *target, SV *v)
{
    if(!target)
        return;

    av_push(
        target->data,
        v
    );
}

MODULE = Net::Async::Redis::XS  PACKAGE = Net::Async::Redis::XS

PROTOTYPES: DISABLE

AV *
decode_buffer(SV *this, SV *p)
PPCODE:
    /* Plain bytestring required: no magic, no UTF-8, no nonsense */
    if(SvTYPE(p) != SVt_PV)
        croak("expected a string");
    if(SvUTF8(p))
        sv_utf8_downgrade(p, true);

    STRLEN len;
    const char *in = SvPVbyte(p, len);
    const char *ptr = in;
    const char *end = in + len;
    struct pending_stack *ps = NULL;
    AV *results = (AV *) sv_2mortal((SV *) newAV());
    int extracted_item = 0;
    SV *extracted = &PL_sv_undef;
    /* Shortcut for "we have incomplete data" */
    if(*end != '\0') {
        croak("no trailing null?");
    }

    if(len >= 3 && *(end - 1) == '\x0A' && *(end - 2) == '\x0D') {
        while(*ptr && ptr < end) {
            switch(*ptr++) {
                case '*': { /* array */
                    int n = 0;
                    while(*ptr >= '0' && *ptr <= '9' && ptr < end) {
                        n = (n * 10) + (*ptr - '0');
                        ++ptr;
                    }
                    if(ptr + 2 > end) {
                        goto end_parsing;
                    }
                    if(ptr[0] != '\x0D' || ptr[1] != '\x0A') {
                        croak("protocol violation - array length not followed by CRLF");
                    }
                    ptr += 2;
                    AV *x = (AV *) sv_2mortal((SV *)newAV());
                    if(n > 0) {
                        av_extend(x, n);
                    }
                    struct pending_stack *pn = Newx(pn, 1, struct pending_stack);
                    pn->data = x;
                    pn->prev = ps;
                    pn->expected = n;
                    pn->type = array;
                    ps = pn;
                    break;
                }
                case '>': { /* push (pubsub) */
                    int n = 0;
                    while(*ptr >= '0' && *ptr <= '9' && ptr < end) {
                        n = (n * 10) + (*ptr - '0');
                        ++ptr;
                    }
                    if(ptr + 2 > end) {
                        goto end_parsing;
                    }
                    if(ptr[0] != '\x0D' || ptr[1] != '\x0A') {
                        croak("protocol violation - push length not followed by CRLF");
                    }
                    ptr += 2;
                    AV *x = (AV *) sv_2mortal((SV *)newAV());
                    if(n > 0) {
                        av_extend(x, n);
                    }
                    struct pending_stack *pn = Newx(pn, 1, struct pending_stack);
                    pn->data = x;
                    pn->prev = ps;
                    pn->expected = n;
                    pn->type = push;
                    ps = pn;
                    break;
                }
                case '%': { /* hash */
                    int n = 0;
                    while(*ptr >= '0' && *ptr <= '9' && ptr < end) {
                        n = (n * 10) + (*ptr - '0');
                        ++ptr;
                    }
                    if(ptr + 2 > end) {
                        goto end_parsing;
                    }
                    /* Hash of key/value pairs */
                    n = n * 2;
                    if(ptr[0] != '\x0D' || ptr[1] != '\x0A') {
                        croak("protocol violation - number of hash entries not followed by CRLF");
                    }
                    ptr += 2;
                    AV *x = (AV *) sv_2mortal((SV *)newAV());
                    if(n > 0) {
                        av_extend(x, n);
                    }
                    struct pending_stack *pn = Newx(pn, 1, struct pending_stack);
                    pn->data = x;
                    pn->prev = ps;
                    pn->expected = n;
                    pn->type = map;
                    ps = pn;
                    break;
                }
                case ':': { /* integer */
                    int n = 0;
                    int negative = 0;
                    if(*ptr == '-') {
                        negative = 1;
                        ++ptr;
                    }
                    while(*ptr >= '0' && *ptr <= '9' && ptr < end) {
                        n = (n * 10) + (*ptr - '0');
                        ++ptr;
                    }
                    if(negative) {
                        n = -n;
                    }
                    if(ptr + 2 > end) {
                        goto end_parsing;
                    }
                    if(ptr[0] != '\x0D' || ptr[1] != '\x0A') {
                        croak("protocol violation - integer not followed by CRLF\n");
                    }
                    ptr += 2;
                    SV *v = newSViv(n);
                    if(ps) {
                        add_value(ps, v);
                    } else {
                        av_push(results, v);
                        extracted_item = 1;
                    }
                    break;
                }
                case ',': { /* decimal floating-point */
                    float n = 0;
                    int negative = 0;
                    if(*ptr == '-') {
                        negative = 1;
                        ++ptr;
                    }
                    int fraction = 0;
                    int digits = 0;
                    while((*ptr == '.' || (*ptr >= '0' && *ptr <= '9')) && ptr < end) {
                        if(*ptr == '.') {
                            fraction = 1;
                        } else {
                            n = (n * 10) + (*ptr - '0');
                            if(fraction) {
                                ++digits;
                            }
                        }
                        ++ptr;
                    }
                    if(digits > 0) {
                        n = n / pow(10, digits);
                    }
                    if(negative) {
                        n = -n;
                    }
                    if(ptr + 2 > end) {
                        goto end_parsing;
                    }
                    if(ptr[0] != '\x0D' || ptr[1] != '\x0A') {
                        croak("protocol violation - decimal numebr not followed by CRLF\n");
                    }
                    ptr += 2;
                    SV *v = newSVnv(n);
                    if(ps) {
                        add_value(ps, v);
                    } else {
                        av_push(results, v);
                        extracted_item = 1;
                    }
                    break;
                }
                case '$': { /* bulk string */
                    int n = 0;
                    SV *v;
                    if(ptr[0] == '-' && ptr[1] == '1') {
                        if(ptr + 4 > end) {
                            goto end_parsing;
                        }
                        // null
                        ptr += 2;
                        v = &PL_sv_undef;
                    } else {
                        while(*ptr >= '0' && *ptr <= '9' && ptr < end) {
                            n = (n * 10) + (*ptr - '0');
                            ++ptr;
                        }
                        if(ptr + n + 4 > end) {
                            goto end_parsing;
                        }
                        if(ptr[0] != '\x0D' || ptr[1] != '\x0A') {
                            croak("protocol violation - bulk string length not followed by CRLF");
                        }
                        ptr += 2;
                        v = newSVpvn(ptr, n);
                        ptr += n;
                    }
                    if(ptr[0] != '\x0D' || ptr[1] != '\x0A') {
                        croak("protocol violation - bulk string not terminated by CRLF");
                    }
                    ptr += 2;
                    if(ps) {
                        add_value(ps, v);
                    } else {
                        av_push(results, v);
                        extracted_item = 1;
                    }
                    break;
                }
                case '+': { /* string */
                    const char *start = ptr;
                    while(*ptr && (ptr[0] != '\x0D' && ptr[1] != '\x0A' && ptr < end)) {
                        ++ptr;
                    }
                    if(ptr + 2 > end) {
                        goto end_parsing;
                    }
                    if(ptr[0] != '\x0D' || ptr[1] != '\x0A') {
                        croak("protocol violation - string not terminated by CRLF");
                    }
                    int n = ptr - start;
                    SV *v = newSVpvn(start, n);
                    ptr += 2;
                    if(ps) {
                        add_value(ps, v);
                    } else {
                        av_push(results, v);
                        extracted_item = 1;
                    }
                    break;
                }
                case '-': { /* error */
                    const char *start = ptr;
                    while(*ptr && (ptr[0] != '\x0D' && ptr[1] != '\x0A' && ptr < end)) {
                        ++ptr;
                    }
                    if(ptr + 2 > end) {
                        goto end_parsing;
                    }
                    if(ptr[0] != '\x0D' || ptr[1] != '\x0A') {
                        croak("protocol violation - error not terminated by CRLF");
                    }
                    int n = ptr - start;
                    char *str = Newx(str, n + 1, char);
                    strncpy(str, start, n);
                    str[n] = '\0';
                    ptr += 2;
                    SV *v = newSVpvn(str, n);
                    SV *rv = SvRV(this);

                    /* Remove anything we processed - we're doing this _before_ the call,
                     * since it may throw an exception */
                    sv_chop(p, ptr);
                    ptr = SvPVbyte(p, len);
                    end = ptr + len - 1;
                    if(hv_exists((HV *) rv, "error", 5)) {
                        SV **cv_ptr = hv_fetchs((HV *) rv, "error", 0);
                        if(cv_ptr) {
                            CV *cv = (CV *) *cv_ptr;
                            dSP;
                            ENTER;
                            SAVETMPS;
                            PUSHMARK(SP);
                            EXTEND(SP, 1);
                            PUSHs(sv_2mortal(v));
                            PUTBACK;
                            call_sv((SV *) cv, G_VOID | G_DISCARD);
                            FREETMPS;
                            LEAVE;
                        } else {
                            warn("no CV for ->{error}");
                        }
                    } else {
                        warn("no ->{error} handler");
                    }
                    /* Note that we are _not_ setting extracted_item here, because there
                     * were no items to put in results, and we've already updated the buffer
                     * to move past the error item. */
                    break;
                }
                case '_': { /* single-character null */
                    int n = 0;
                    SV *v = &PL_sv_undef;
                    if(ptr + 2 > end) {
                        goto end_parsing;
                    }
                    if(ptr[0] != '\x0D' || ptr[1] != '\x0A') {
                        croak("protocol violation");
                    }
                    ptr += 2;
                    if(ps) {
                        add_value(ps, v);
                    } else {
                        av_push(results, v);
                        extracted_item = 1;
                    }
                    break;
                }
                default:
                    croak("Unknown type %d, bail out", ptr[-1]);
            }

            while(ps && av_count(ps->data) >= ps->expected) {
                AV *data = ps->data;
                struct pending_stack *orig = ps;
                ps = orig->prev;
                SV *value_ref = newRV((SV *) data);
                if(ps) {
                    av_push(
                        ps->data,
                        value_ref
                   );
                } else {
                    switch(orig->type) {
                    case push: {
                        SV *rv = SvRV(this);
                        if(hv_exists((HV *) rv, "pubsub", 5)) {
                            SV **cv_ptr = hv_fetchs((HV *) rv, "pubsub", 0);
                            if(cv_ptr) {
                                CV *cv = (CV *) *cv_ptr;
                                dSP;
                                ENTER;
                                SAVETMPS;
                                PUSHMARK(SP);
                                EXTEND(SP, 1);
                                PUSHs(sv_2mortal(value_ref));
                                PUTBACK;
                                call_sv((SV *) cv, G_VOID | G_DISCARD);
                                FREETMPS;
                                LEAVE;
                            } else {
                                warn("no CV for ->{pubsub}");
                            }
                        } else {
                            warn("no ->{pubsub} handler");
                        }
                        break;
                    }
                    case attribute:
                        warn("attribute received, but ignored");
                        break;
                    default:
                        av_push(
                            results,
                            value_ref
                        );
                        extracted_item = 1;
                        break;
                    }
                }
                Safefree(orig);
            }
            if(extracted_item) {
                /* Remove anything we processed */
                sv_chop(p, ptr);
                ptr = SvPVbyte(p, len);
                end = ptr + len;
                extracted_item = 0;
                if (GIMME_V == G_SCALAR) {
                    extracted = av_shift(results);
                    break;
                }
            }
        }
    }
end_parsing:
    /* Clean up our temporary parse stack */
    while(ps) {
        struct pending_stack *orig = ps;
        ps = ps->prev;
        Safefree(orig);
    }

    /* Flatten our results back into scalars for return */
    if (GIMME_V == G_LIST) {
        long count = av_count(results);
        if(count) {
            EXTEND(SP, count);
            for(int i = 0; i < count; ++i) {
                mPUSHs(av_shift(results));
            }
        }
    } else if (GIMME_V == G_SCALAR) {
        mXPUSHs(extracted);
    }
