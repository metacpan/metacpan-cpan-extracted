#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef AMBIGUOUS_WIDTH_IS_WIDE
#include "charwidth_ambiguous_is_wide.h"
#else
#include "charwidth_default.h"
#endif


static int _char_width(UV codepoint) {
    int min = 0;
    int max = width_table_len - 1;
    int mid;

    if (codepoint < width_table[0].start || codepoint > width_table[max].end) {
        return 1;
    } else {
        while (max >= min) {
            mid = (min + max) / 2;
            if (codepoint > width_table[mid].end) {
                min = mid + 1;
            } else if (codepoint < width_table[mid].start) {
                max = mid - 1;
            } else {
                return width_table[mid].width;
            }
        }
        return 1;
    }
}


MODULE = Term::Choose::LineFold::XS    PACKAGE = Term::Choose::LineFold::XS

PROTOTYPES: DISABLE


int
char_width(UV codepoint)
    CODE:
        RETVAL = _char_width(codepoint);
    OUTPUT:
        RETVAL



SV *
print_columns(SV *input)
    PREINIT:
        STRLEN len;
        const U8 *p, *end;
        UV codepoint;
        int width = 0;
        STRLEN clen;
    CODE:
        if (!SvOK(input)) {
            XSRETURN_UNDEF;
        }
        if (!SvPOK(input)) {
            input = sv_mortalcopy(input); // Ensure string
            SvPV_force(input, len);
        }
        p = (const U8 *) SvPVutf8(input, len);
        end = p + len;

        while (p < end) {
            codepoint = utf8_to_uvchr_buf(p, end, &clen);
            if (clen == -1 ) {
                codepoint = *p; // Interpret the invalid byte as a single character
                clen = 1;       // Advance by 1 byte

                // Option B: Stop processing on error
                // Perl_warn(aTHX_ "Malformed UTF-8 at byte offset %ld", (long)(p - (const U8 *)SvPVX(input)));
                // break;

                // Option C: Malformed UTF-8. Skip bad byte and keep going
                // p++;
                // continue;
            }
            p += clen;
            width += _char_width(codepoint);
        }

        RETVAL = newSViv(width);
    OUTPUT:
        RETVAL



SV*
cut_to_printwidth(SV *input, int max_width)
    PREINIT:
        STRLEN len;
        const U8 *p, *end;
        const U8 *split_point = NULL;
        const U8 *char_start;
        UV codepoint;
        int str_w = 0, this_w;
        STRLEN clen;
//        bool skip_padding;
    PPCODE:
        if (!SvOK(input)) {
            XSRETURN_UNDEF;
        }

        if (!SvPOK(input)) {
            input = sv_mortalcopy(input);
            SvPV_force(input, len);
        }

        const U8 *start = (const U8 *) SvPVutf8(input, len);
        p = start;
        end = p + len;

        while (p < end) {
            char_start = p;
            codepoint = utf8_to_uvchr_buf(p, end, &clen);

            if (clen == -1) {
                codepoint = *p;
                clen = 1;
            }

            this_w = _char_width(codepoint);

            if (str_w + this_w > max_width) {
                split_point = char_start;
                break;
            }

            //if (str_w + this_w == max_width) {
            //    p += clen;
            //    str_w += this_w;
            //    split_point = p;
            //    break;
            //}

            str_w += this_w;
            p += clen;
        }

        if (!split_point) {
            // Whole string fits
            if (GIMME_V == G_ARRAY) {
                XPUSHs(sv_2mortal(newSVsv(input)));
                XPUSHs(sv_2mortal(newSVpvn("", 0)));
            } else {
                XPUSHs(sv_2mortal(newSVsv(input)));
            }
        } else {
            STRLEN first_len = split_point - start;
            SV *first_part = newSVpvn((const char *)start, first_len);
            SvUTF8_on(first_part);

            if (str_w == max_width - 1) {
                sv_catpv(first_part, " ");
                str_w += 1;
            }

            if (GIMME_V == G_ARRAY) {
                STRLEN rest_len = end - split_point;
                SV *rest_part = newSVpvn((const char *)split_point, rest_len);
                SvUTF8_on(rest_part);

                XPUSHs(sv_2mortal(first_part));
                XPUSHs(sv_2mortal(rest_part));
            } else {
                XPUSHs(sv_2mortal(first_part));
            }
        }



SV *
adjust_to_printwidth(SV *input, int width)
    PREINIT:
        STRLEN len;
        const U8 *p, *end;
        UV codepoint;
        int str_w = 0, this_w;
        STRLEN clen;
        SV *result;
        const U8 *start;
    CODE:
        if (!SvOK(input)) {
            XSRETURN_UNDEF;
        }

        if (!SvPOK(input)) {
            input = sv_mortalcopy(input);
            SvPV_force(input, len);
        }

        p = (const U8 *) SvPVutf8(input, len);  // len is char length
        end = p + len;
        start = p;

        while (p < end) {
            codepoint = utf8_to_uvchr_buf(p, end, &clen);
            if (clen == (STRLEN)-1) {
                codepoint = *p;
                clen = 1;
            }

            this_w = _char_width(codepoint);
            if (str_w + this_w > width) {
                break;
            }

            str_w += this_w;
            p += clen;
        }

        len = (STRLEN)(p - start);  // Final cutoff length: now len is bytes length

        if (str_w == width) {
            RETVAL = newSVpvn((const char *)start, len);
        } else {
            result = newSVpvn((const char *)start, len);
            sv_catpvf(result, "%*s", width - str_w, "");
            RETVAL = result;
        }

        SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

