/*----------------------------------------------------------------------------
 * Person Name Format - PersonName-Format.xs
 * Version v0.1.0
 * Copyright(c) 2026 DEGUEST Pte. Ltd.
 * Author: Jacques Deguest <jack@deguest.jp>
 * Created 2026/07/17
 * Modified 2026/07/19
 * All rights reserved
 *
 * XS implementations of key functions for PersonName-Format.
 *
 * This program is free software; you can redistribute  it  and/or  modify  it
 * under the same terms as Perl itself.
 *----------------------------------------------------------------------------
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*-------------------------------------------------------------------
 * pnf_first_grapheme( value )
 *
 * Delegates to PersonName::Format::PP::_first_grapheme() to extract
 * the first Unicode extended grapheme cluster from a Perl string SV.
 *
 * The pure-Perl implementation handles the two cases that \X does not
 * cover correctly on older Perl versions:
 *   - Regional Indicator pairs (UAX #29 rule GB12/GB13, Perl < 5.18)
 *   - ZWJ emoji sequences    (UAX #29 rule GB11,       Perl < 5.28)
 *
 * Returns a new mortal SV containing the grapheme, or an empty string
 * SV for an undefined or empty input.
 *-------------------------------------------------------------------*/
static SV*
pnf_first_grapheme(pTHX_ SV* value)
{
    dSP;
    SV* result;

    if (!SvOK(value) || SvCUR(value) == 0)
    {
        return newSVpvs("");
    }

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(value);
    PUTBACK;

    if (call_pv("PersonName::Format::PP::_first_grapheme", G_SCALAR) != 1)
    {
        croak("PersonName::Format::PP::_first_grapheme() did not return one value");
    }

    SPAGAIN;
    result = newSVsv(POPs);
    PUTBACK;

    FREETMPS;
    LEAVE;

    return result;
}

/*-------------------------------------------------------------------
 * pnf_script_code_for_uv( uv )
 *
 * Delegates to PersonName::Format::PP::_script_code_for_uv() to
 * resolve a Unicode codepoint (UV) to its ISO 15924 four-letter
 * script code (e.g. "Latn", "Hani", "Arab").
 *
 * On Perl 5.16 and later the PP function uses
 * Unicode::UCD::prop_value_aliases(); on earlier versions it falls
 * back to the bundled ScriptNames.pl data file.
 *
 * Returns a new SV containing the four-letter code string, or "Zzzz"
 * (Unknown) when no script can be determined.
 *-------------------------------------------------------------------*/
static SV*
pnf_script_code_for_uv(pTHX_ UV uv)
{
    dSP;
    SV* result;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVuv(uv)));
    PUTBACK;

    if (call_pv("PersonName::Format::PP::_script_code_for_uv", G_SCALAR) != 1)
    {
        croak("PersonName::Format::PP::_script_code_for_uv() did not return one value");
    }

    SPAGAIN;
    result = newSVsv(POPs);
    PUTBACK;

    FREETMPS;
    LEAVE;

    return result;
}

/*-------------------------------------------------------------------
 * pnf_first_significant_script( value )
 *
 * Iterates the codepoints of a Perl string SV and returns a new SV
 * holding the ISO 15924 code of the first script that is not Common
 * (Zyyy), Inherited (Zinh), or Unknown (Zzzz).  Returns NULL when no
 * significant script is found (empty string, all ASCII punctuation,
 * all digits, etc.).
 *
 * The SV is upgraded to its internal UTF-8 representation on a mortal
 * copy before reading.  This is required on Perl 5.10.1, where
 * SvUTF8() may not be set for decoded Unicode strings in certain XS
 * calling contexts, causing the byte-level iteration to see raw UTF-8
 * lead bytes (e.g. 0xE5 for U+5BAE 宮) rather than full codepoints,
 * and thus to misidentify the script as Latin.
 *-------------------------------------------------------------------*/
static SV*
pnf_first_significant_script(pTHX_ SV* value)
{
    STRLEN length;
    const U8* current;
    const U8* end;
    SV* value_utf8;

    if (!SvOK(value))
    {
        return NULL;
    }

    /* Force the SV to its internal UTF-8 representation before reading bytes.
     * On Perl 5.10.1, SvUTF8() may return 0 for decoded Unicode strings that
     * happen to contain only Latin-1 codepoints, or in certain calling contexts.
     * Working on a mortal copy avoids modifying a read-only or shared SV. */
    value_utf8 = sv_mortalcopy(value);
    sv_utf8_upgrade(value_utf8);

    current = (const U8*)SvPV(value_utf8, length);
    if (length == 0)
    {
        return NULL;
    }

    end = current + length;

    while (current < end)
    {
        UV uv;
        STRLEN char_length;
        SV* script;
        const char* code;
        STRLEN code_length;

#if PERL_VERSION >= 16
        uv = utf8_to_uvchr_buf(current, end, &char_length);
#else
        uv = utf8_to_uvchr(current, &char_length);
#endif
        if (char_length == 0 || current + char_length > end)
        {
            croak("Invalid UTF-8 sequence in person-name field");
        }

        current += char_length;
        script = pnf_script_code_for_uv(aTHX_ uv);
        code = SvPV(script, code_length);

        if (!((code_length == 4 && memEQ(code, "Zyyy", 4)) ||
              (code_length == 4 && memEQ(code, "Zinh", 4)) ||
              (code_length == 4 && memEQ(code, "Zzzz", 4))))
        {
            return script;
        }

        SvREFCNT_dec(script);
    }

    return NULL;
}

MODULE = PersonName::Format    PACKAGE = PersonName::Format
PROTOTYPES: DISABLE

#-------------------------------------------------------------------
# _first_grapheme( value )
#
# Returns the first Unicode extended grapheme cluster from the
# input string, or an empty string for an undefined or empty value.
#-------------------------------------------------------------------
SV*
_first_grapheme(value)
    SV* value

    CODE:
        RETVAL = pnf_first_grapheme(aTHX_ value);

    OUTPUT:
        RETVAL

#-------------------------------------------------------------------
# _get_name_script()
#
# Returns the ISO 15924 four-letter script code
# (e.g. "Hani", "Latn") of the first significant codepoint found
# in surname, then given.  Common (Zyyy), Inherited (Zinh), and
# Unknown (Zzzz) codepoints are skipped.  Returns "Zzzz" when no
# significant script is found in either field.
#-------------------------------------------------------------------
SV*
_get_name_script(surname, given)
    SV* surname
    SV* given

    PREINIT:
        SV* script;

    CODE:
        script = pnf_first_significant_script(aTHX_ surname);
        if( script == NULL )
        {
            script = pnf_first_significant_script(aTHX_ given);
        }
        if( script == NULL )
        {
            RETVAL = newSVpvs("Zzzz");
        }
        else
        {
            RETVAL = script;
        }

    OUTPUT:
        RETVAL
