/* 
  This file is original utf8proc.c. To use utf8proc in SPVM, the symbol "utf8proc", "UTF8PROC" is renamed to "SPVM__Unicode__utf8proc", "SPVM_UTF8PROC"
*/

/* -*- mode: c; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*- */
/*
 *  Copyright (c) 2018 Steven G. Johnson, Jiahao Chen, Peter Colberg, Tony Kelman, Scott P. Jones, and other contributors.
 *  Copyright (c) 2009 Public Software Group e. V., Berlin, Germany
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a
 *  copy of this software and associated documentation files (the "Software"),
 *  to deal in the Software without restriction, including without limitation
 *  the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *  and/or sell copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or methodstantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *  DEALINGS IN THE SOFTWARE.
 */

#include "SPVM__Unicode__utf8proc.h"

/*
 *  This library contains derived data from a modified version of the
 *  Unicode data files.
 *
 *  The original data files are available at
 *  http://www.unicode.org/Public/UNIDATA/
 *
 *  Please notice the copyright statement in the file "SPVM__Unicode__utf8proc_data.c".
 */

#include "SPVM__Unicode__utf8proc_data.c"

/*
 *  File name:    SPVM__Unicode__utf8proc.c
 *
 *  Description:
 *  Implementation of libSPVM__Unicode__utf8proc.
 */

#ifndef SSIZE_MAX
#define SSIZE_MAX ((size_t)SIZE_MAX/2)
#endif
#ifndef UINT16_MAX
#  define UINT16_MAX 65535U
#endif

const SPVM__Unicode__utf8proc_int8_t SPVM__Unicode__utf8proc_utf8class[256] = {
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
  2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0 };

#define SPVM_UTF8PROC_HANGUL_SBASE 0xAC00
#define SPVM_UTF8PROC_HANGUL_LBASE 0x1100
#define SPVM_UTF8PROC_HANGUL_VBASE 0x1161
#define SPVM_UTF8PROC_HANGUL_TBASE 0x11A7
#define SPVM_UTF8PROC_HANGUL_LCOUNT 19
#define SPVM_UTF8PROC_HANGUL_VCOUNT 21
#define SPVM_UTF8PROC_HANGUL_TCOUNT 28
#define SPVM_UTF8PROC_HANGUL_NCOUNT 588
#define SPVM_UTF8PROC_HANGUL_SCOUNT 11172
/* END is exclusive */
#define SPVM_UTF8PROC_HANGUL_L_START  0x1100
#define SPVM_UTF8PROC_HANGUL_L_END    0x115A
#define SPVM_UTF8PROC_HANGUL_L_FILLER 0x115F
#define SPVM_UTF8PROC_HANGUL_V_START  0x1160
#define SPVM_UTF8PROC_HANGUL_V_END    0x11A3
#define SPVM_UTF8PROC_HANGUL_T_START  0x11A8
#define SPVM_UTF8PROC_HANGUL_T_END    0x11FA
#define SPVM_UTF8PROC_HANGUL_S_START  0xAC00
#define SPVM_UTF8PROC_HANGUL_S_END    0xD7A4

/* Should follow semantic-versioning rules (semver.org) based on API
   compatibility.  (Note that the shared-library version number will
   be different, being based on ABI compatibility.): */
#define STRINGIZEx(x) #x
#define STRINGIZE(x) STRINGIZEx(x)
const char *SPVM__Unicode__utf8proc_version(void) {
  return STRINGIZE(SPVM_UTF8PROC_VERSION_MAJOR) "." STRINGIZE(SPVM_UTF8PROC_VERSION_MINOR) "." STRINGIZE(SPVM_UTF8PROC_VERSION_PATCH) "";
}

const char *SPVM__Unicode__utf8proc_errmsg(SPVM__Unicode__utf8proc_ssize_t errcode) {
  switch (errcode) {
    case SPVM_UTF8PROC_ERROR_NOMEM:
    return "Memory for processing UTF-8 data could not be allocated.";
    case SPVM_UTF8PROC_ERROR_OVERFLOW:
    return "UTF-8 string is too long to be processed.";
    case SPVM_UTF8PROC_ERROR_INVALIDUTF8:
    return "Invalid UTF-8 string";
    case SPVM_UTF8PROC_ERROR_NOTASSIGNED:
    return "Unassigned Unicode code point found in UTF-8 string.";
    case SPVM_UTF8PROC_ERROR_INVALIDOPTS:
    return "Invalid options for UTF-8 processing chosen.";
    default:
    return "An unknown error occurred while processing UTF-8 data.";
  }
}

#define utf_cont(ch)  (((ch) & 0xc0) == 0x80)
SPVM__Unicode__utf8proc_ssize_t SPVM__Unicode__utf8proc_iterate(
  const SPVM__Unicode__utf8proc_uint8_t *str, SPVM__Unicode__utf8proc_ssize_t strlen, SPVM__Unicode__utf8proc_int32_t *dst
) {
  SPVM__Unicode__utf8proc_uint32_t uc;
  const SPVM__Unicode__utf8proc_uint8_t *end;

  *dst = -1;
  if (!strlen) return 0;
  end = str + ((strlen < 0) ? 4 : strlen);
  uc = *str++;
  if (uc < 0x80) {
    *dst = uc;
    return 1;
  }
  // Must be between 0xc2 and 0xf4 inclusive to be valid
  if ((uc - 0xc2) > (0xf4-0xc2)) return SPVM_UTF8PROC_ERROR_INVALIDUTF8;
  if (uc < 0xe0) {         // 2-byte sequence
     // Must have valid continuation character
     if (str >= end || !utf_cont(*str)) return SPVM_UTF8PROC_ERROR_INVALIDUTF8;
     *dst = ((uc & 0x1f)<<6) | (*str & 0x3f);
     return 2;
  }
  if (uc < 0xf0) {        // 3-byte sequence
     if ((str + 1 >= end) || !utf_cont(*str) || !utf_cont(str[1]))
        return SPVM_UTF8PROC_ERROR_INVALIDUTF8;
     // Check for surrogate chars
     if (uc == 0xed && *str > 0x9f)
         return SPVM_UTF8PROC_ERROR_INVALIDUTF8;
     uc = ((uc & 0xf)<<12) | ((*str & 0x3f)<<6) | (str[1] & 0x3f);
     if (uc < 0x800)
         return SPVM_UTF8PROC_ERROR_INVALIDUTF8;
     *dst = uc;
     return 3;
  }
  // 4-byte sequence
  // Must have 3 valid continuation characters
  if ((str + 2 >= end) || !utf_cont(*str) || !utf_cont(str[1]) || !utf_cont(str[2]))
     return SPVM_UTF8PROC_ERROR_INVALIDUTF8;
  // Make sure in correct range (0x10000 - 0x10ffff)
  if (uc == 0xf0) {
    if (*str < 0x90) return SPVM_UTF8PROC_ERROR_INVALIDUTF8;
  } else if (uc == 0xf4) {
    if (*str > 0x8f) return SPVM_UTF8PROC_ERROR_INVALIDUTF8;
  }
  *dst = ((uc & 7)<<18) | ((*str & 0x3f)<<12) | ((str[1] & 0x3f)<<6) | (str[2] & 0x3f);
  return 4;
}

SPVM__Unicode__utf8proc_bool SPVM__Unicode__utf8proc_codepoint_valid(SPVM__Unicode__utf8proc_int32_t uc) {
    return (((SPVM__Unicode__utf8proc_uint32_t)uc)-0xd800 > 0x07ff) && ((SPVM__Unicode__utf8proc_uint32_t)uc < 0x110000);
}

SPVM__Unicode__utf8proc_ssize_t SPVM__Unicode__utf8proc_encode_char(SPVM__Unicode__utf8proc_int32_t uc, SPVM__Unicode__utf8proc_uint8_t *dst) {
  if (uc < 0x00) {
    return 0;
  } else if (uc < 0x80) {
    dst[0] = (SPVM__Unicode__utf8proc_uint8_t) uc;
    return 1;
  } else if (uc < 0x800) {
    dst[0] = (SPVM__Unicode__utf8proc_uint8_t)(0xC0 + (uc >> 6));
    dst[1] = (SPVM__Unicode__utf8proc_uint8_t)(0x80 + (uc & 0x3F));
    return 2;
  // Note: we allow encoding 0xd800-0xdfff here, so as not to change
  // the API, however, these are actually invalid in UTF-8
  } else if (uc < 0x10000) {
    dst[0] = (SPVM__Unicode__utf8proc_uint8_t)(0xE0 + (uc >> 12));
    dst[1] = (SPVM__Unicode__utf8proc_uint8_t)(0x80 + ((uc >> 6) & 0x3F));
    dst[2] = (SPVM__Unicode__utf8proc_uint8_t)(0x80 + (uc & 0x3F));
    return 3;
  } else if (uc < 0x110000) {
    dst[0] = (SPVM__Unicode__utf8proc_uint8_t)(0xF0 + (uc >> 18));
    dst[1] = (SPVM__Unicode__utf8proc_uint8_t)(0x80 + ((uc >> 12) & 0x3F));
    dst[2] = (SPVM__Unicode__utf8proc_uint8_t)(0x80 + ((uc >> 6) & 0x3F));
    dst[3] = (SPVM__Unicode__utf8proc_uint8_t)(0x80 + (uc & 0x3F));
    return 4;
  } else return 0;
}

/* internal "unsafe" version that does not check whether uc is in range */
SPVM__Unicode__utf8proc_ssize_t unsafe_encode_char(SPVM__Unicode__utf8proc_int32_t uc, SPVM__Unicode__utf8proc_uint8_t *dst) {
   if (uc < 0x00) {
      return 0;
   } else if (uc < 0x80) {
      dst[0] = (SPVM__Unicode__utf8proc_uint8_t)uc;
      return 1;
   } else if (uc < 0x800) {
      dst[0] = (SPVM__Unicode__utf8proc_uint8_t)(0xC0 + (uc >> 6));
      dst[1] = (SPVM__Unicode__utf8proc_uint8_t)(0x80 + (uc & 0x3F));
      return 2;
   } else if (uc == 0xFFFF) {
       dst[0] = (SPVM__Unicode__utf8proc_uint8_t)0xFF;
       return 1;
   } else if (uc == 0xFFFE) {
       dst[0] = (SPVM__Unicode__utf8proc_uint8_t)0xFE;
       return 1;
   } else if (uc < 0x10000) {
      dst[0] = (SPVM__Unicode__utf8proc_uint8_t)(0xE0 + (uc >> 12));
      dst[1] = (SPVM__Unicode__utf8proc_uint8_t)(0x80 + ((uc >> 6) & 0x3F));
      dst[2] = (SPVM__Unicode__utf8proc_uint8_t)(0x80 + (uc & 0x3F));
      return 3;
   } else if (uc < 0x110000) {
      dst[0] = (SPVM__Unicode__utf8proc_uint8_t)(0xF0 + (uc >> 18));
      dst[1] = (SPVM__Unicode__utf8proc_uint8_t)(0x80 + ((uc >> 12) & 0x3F));
      dst[2] = (SPVM__Unicode__utf8proc_uint8_t)(0x80 + ((uc >> 6) & 0x3F));
      dst[3] = (SPVM__Unicode__utf8proc_uint8_t)(0x80 + (uc & 0x3F));
      return 4;
   } else return 0;
}

/* internal "unsafe" version that does not check whether uc is in range */
const SPVM__Unicode__utf8proc_property_t *unsafe_get_property(SPVM__Unicode__utf8proc_int32_t uc) {
  /* ASSERT: uc >= 0 && uc < 0x110000 */
  return SPVM__Unicode__utf8proc_properties + (
    SPVM__Unicode__utf8proc_stage2table[
      SPVM__Unicode__utf8proc_stage1table[uc >> 8] + (uc & 0xFF)
    ]
  );
}

const SPVM__Unicode__utf8proc_property_t *SPVM__Unicode__utf8proc_get_property(SPVM__Unicode__utf8proc_int32_t uc) {
  return uc < 0 || uc >= 0x110000 ? SPVM__Unicode__utf8proc_properties : unsafe_get_property(uc);
}

/* return whether there is a grapheme break between boundclasses lbc and tbc
   (according to the definition of extended grapheme clusters)

  Rule numbering refers to TR29 Version 29 (Unicode 9.0.0):
  http://www.unicode.org/reports/tr29/tr29-29.html

  CAVEATS:
   Please note that evaluation of GB10 (grapheme breaks between emoji zwj sequences)
   and GB 12/13 (regional indicator code points) require knowledge of previous characters
   and are thus not handled by this function. This may result in an incorrect break before
   an E_Modifier class codepoint and an incorrectly missing break between two
   REGIONAL_INDICATOR class code points if such support does not exist in the caller.

   See the special support in grapheme_break_extended, for required bookkeeping by the caller.
*/
SPVM__Unicode__utf8proc_bool grapheme_break_simple(int lbc, int tbc) {
  return
    (lbc == SPVM_UTF8PROC_BOUNDCLASS_START) ? true :       // GB1
    (lbc == SPVM_UTF8PROC_BOUNDCLASS_CR &&                 // GB3
     tbc == SPVM_UTF8PROC_BOUNDCLASS_LF) ? false :         // ---
    (lbc >= SPVM_UTF8PROC_BOUNDCLASS_CR && lbc <= SPVM_UTF8PROC_BOUNDCLASS_CONTROL) ? true :  // GB4
    (tbc >= SPVM_UTF8PROC_BOUNDCLASS_CR && tbc <= SPVM_UTF8PROC_BOUNDCLASS_CONTROL) ? true :  // GB5
    (lbc == SPVM_UTF8PROC_BOUNDCLASS_L &&                  // GB6
     (tbc == SPVM_UTF8PROC_BOUNDCLASS_L ||                 // ---
      tbc == SPVM_UTF8PROC_BOUNDCLASS_V ||                 // ---
      tbc == SPVM_UTF8PROC_BOUNDCLASS_LV ||                // ---
      tbc == SPVM_UTF8PROC_BOUNDCLASS_LVT)) ? false :      // ---
    ((lbc == SPVM_UTF8PROC_BOUNDCLASS_LV ||                // GB7
      lbc == SPVM_UTF8PROC_BOUNDCLASS_V) &&                // ---
     (tbc == SPVM_UTF8PROC_BOUNDCLASS_V ||                 // ---
      tbc == SPVM_UTF8PROC_BOUNDCLASS_T)) ? false :        // ---
    ((lbc == SPVM_UTF8PROC_BOUNDCLASS_LVT ||               // GB8
      lbc == SPVM_UTF8PROC_BOUNDCLASS_T) &&                // ---
     tbc == SPVM_UTF8PROC_BOUNDCLASS_T) ? false :          // ---
    (tbc == SPVM_UTF8PROC_BOUNDCLASS_EXTEND ||             // GB9
     tbc == SPVM_UTF8PROC_BOUNDCLASS_ZWJ ||                // ---
     tbc == SPVM_UTF8PROC_BOUNDCLASS_SPACINGMARK ||        // GB9a
     lbc == SPVM_UTF8PROC_BOUNDCLASS_PREPEND) ? false :    // GB9b
    (lbc == SPVM_UTF8PROC_BOUNDCLASS_E_ZWG &&              // GB11 (requires additional handling below)
     tbc == SPVM_UTF8PROC_BOUNDCLASS_EXTENDED_PICTOGRAPHIC) ? false : // ----
    (lbc == SPVM_UTF8PROC_BOUNDCLASS_REGIONAL_INDICATOR &&          // GB12/13 (requires additional handling below)
     tbc == SPVM_UTF8PROC_BOUNDCLASS_REGIONAL_INDICATOR) ? false :  // ----
    true; // GB999
}

SPVM__Unicode__utf8proc_bool grapheme_break_extended(int lbc, int tbc, SPVM__Unicode__utf8proc_int32_t *state)
{
  int lbc_override = ((state && *state != SPVM_UTF8PROC_BOUNDCLASS_START)
                      ? *state : lbc);
  SPVM__Unicode__utf8proc_bool break_permitted = grapheme_break_simple(lbc_override, tbc);
  if (state) {
    // Special support for GB 12/13 made possible by GB999. After two RI
    // class codepoints we want to force a break. Do this by resetting the
    // second RI's bound class to SPVM_UTF8PROC_BOUNDCLASS_OTHER, to force a break
    // after that character according to GB999 (unless of course such a break is
    // forbidden by a different rule such as GB9).
    if (*state == tbc && tbc == SPVM_UTF8PROC_BOUNDCLASS_REGIONAL_INDICATOR)
      *state = SPVM_UTF8PROC_BOUNDCLASS_OTHER;
    // Special support for GB11 (emoji extend* zwj / emoji)
    else if (*state == SPVM_UTF8PROC_BOUNDCLASS_EXTENDED_PICTOGRAPHIC) {
      if (tbc == SPVM_UTF8PROC_BOUNDCLASS_EXTEND) // fold EXTEND codepoints into emoji
        *state = SPVM_UTF8PROC_BOUNDCLASS_EXTENDED_PICTOGRAPHIC;
      else if (tbc == SPVM_UTF8PROC_BOUNDCLASS_ZWJ)
        *state = SPVM_UTF8PROC_BOUNDCLASS_E_ZWG; // state to record emoji+zwg combo
      else
        *state = tbc;
    }
    else
      *state = tbc;
  }
  return break_permitted;
}

SPVM__Unicode__utf8proc_bool SPVM__Unicode__utf8proc_grapheme_break_stateful(
    SPVM__Unicode__utf8proc_int32_t c1, SPVM__Unicode__utf8proc_int32_t c2, SPVM__Unicode__utf8proc_int32_t *state) {

  return grapheme_break_extended(SPVM__Unicode__utf8proc_get_property(c1)->boundclass,
                                 SPVM__Unicode__utf8proc_get_property(c2)->boundclass,
                                 state);
}


SPVM__Unicode__utf8proc_bool SPVM__Unicode__utf8proc_grapheme_break(
    SPVM__Unicode__utf8proc_int32_t c1, SPVM__Unicode__utf8proc_int32_t c2) {
  return SPVM__Unicode__utf8proc_grapheme_break_stateful(c1, c2, NULL);
}

SPVM__Unicode__utf8proc_int32_t seqindex_decode_entry(const SPVM__Unicode__utf8proc_uint16_t **entry)
{
  SPVM__Unicode__utf8proc_int32_t entry_cp = **entry;
  if ((entry_cp & 0xF800) == 0xD800) {
    *entry = *entry + 1;
    entry_cp = ((entry_cp & 0x03FF) << 10) | (**entry & 0x03FF);
    entry_cp += 0x10000;
  }
  return entry_cp;
}

SPVM__Unicode__utf8proc_int32_t seqindex_decode_index(const SPVM__Unicode__utf8proc_uint32_t seqindex)
{
  const SPVM__Unicode__utf8proc_uint16_t *entry = &SPVM__Unicode__utf8proc_sequences[seqindex];
  return seqindex_decode_entry(&entry);
}

SPVM__Unicode__utf8proc_ssize_t seqindex_write_char_decomposed(SPVM__Unicode__utf8proc_uint16_t seqindex, SPVM__Unicode__utf8proc_int32_t *dst, SPVM__Unicode__utf8proc_ssize_t bufsize, SPVM__Unicode__utf8proc_option_t options, int *last_boundclass) {
  SPVM__Unicode__utf8proc_ssize_t written = 0;
  const SPVM__Unicode__utf8proc_uint16_t *entry = &SPVM__Unicode__utf8proc_sequences[seqindex & 0x1FFF];
  int len = seqindex >> 13;
  if (len >= 7) {
    len = *entry;
    entry++;
  }
  for (; len >= 0; entry++, len--) {
    SPVM__Unicode__utf8proc_int32_t entry_cp = seqindex_decode_entry(&entry);

    written += SPVM__Unicode__utf8proc_decompose_char(entry_cp, dst+written,
      (bufsize > written) ? (bufsize - written) : 0, options,
    last_boundclass);
    if (written < 0) return SPVM_UTF8PROC_ERROR_OVERFLOW;
  }
  return written;
}

SPVM__Unicode__utf8proc_int32_t SPVM__Unicode__utf8proc_tolower(SPVM__Unicode__utf8proc_int32_t c)
{
  SPVM__Unicode__utf8proc_int32_t cl = SPVM__Unicode__utf8proc_get_property(c)->lowercase_seqindex;
  return cl != UINT16_MAX ? seqindex_decode_index(cl) : c;
}

SPVM__Unicode__utf8proc_int32_t SPVM__Unicode__utf8proc_toupper(SPVM__Unicode__utf8proc_int32_t c)
{
  SPVM__Unicode__utf8proc_int32_t cu = SPVM__Unicode__utf8proc_get_property(c)->uppercase_seqindex;
  return cu != UINT16_MAX ? seqindex_decode_index(cu) : c;
}

SPVM__Unicode__utf8proc_int32_t SPVM__Unicode__utf8proc_totitle(SPVM__Unicode__utf8proc_int32_t c)
{
  SPVM__Unicode__utf8proc_int32_t cu = SPVM__Unicode__utf8proc_get_property(c)->titlecase_seqindex;
  return cu != UINT16_MAX ? seqindex_decode_index(cu) : c;
}

/* return a character width analogous to wcwidth (except runtime and
   hopefully less buggy than most system wcwidth functions). */
int SPVM__Unicode__utf8proc_charwidth(SPVM__Unicode__utf8proc_int32_t c) {
  return SPVM__Unicode__utf8proc_get_property(c)->charwidth;
}

SPVM__Unicode__utf8proc_category_t SPVM__Unicode__utf8proc_category(SPVM__Unicode__utf8proc_int32_t c) {
  return SPVM__Unicode__utf8proc_get_property(c)->category;
}

/* Comment out to suppress warnings of SPVM Unicode module
const char *SPVM__Unicode__utf8proc_category_string(SPVM__Unicode__utf8proc_int32_t c) {
  const char s[][3] = {"Cn","Lu","Ll","Lt","Lm","Lo","Mn","Mc","Me","Nd","Nl","No","Pc","Pd","Ps","Pe","Pi","Pf","Po","Sm","Sc","Sk","So","Zs","Zl","Zp","Cc","Cf","Cs","Co"};
  return s[SPVM__Unicode__utf8proc_category(c)];
}
*/

#define SPVM__Unicode__utf8proc_decompose_lump(replacement_uc) \
  return SPVM__Unicode__utf8proc_decompose_char((replacement_uc), dst, bufsize, \
  options & ~SPVM_UTF8PROC_LUMP, last_boundclass)

SPVM__Unicode__utf8proc_ssize_t SPVM__Unicode__utf8proc_decompose_char(SPVM__Unicode__utf8proc_int32_t uc, SPVM__Unicode__utf8proc_int32_t *dst, SPVM__Unicode__utf8proc_ssize_t bufsize, SPVM__Unicode__utf8proc_option_t options, int *last_boundclass) {
  const SPVM__Unicode__utf8proc_property_t *property;
  SPVM__Unicode__utf8proc_propval_t category;
  SPVM__Unicode__utf8proc_int32_t hangul_sindex;
  if (uc < 0 || uc >= 0x110000) return SPVM_UTF8PROC_ERROR_NOTASSIGNED;
  property = unsafe_get_property(uc);
  category = property->category;
  hangul_sindex = uc - SPVM_UTF8PROC_HANGUL_SBASE;
  if (options & (SPVM_UTF8PROC_COMPOSE|SPVM_UTF8PROC_DECOMPOSE)) {
    if (hangul_sindex >= 0 && hangul_sindex < SPVM_UTF8PROC_HANGUL_SCOUNT) {
      SPVM__Unicode__utf8proc_int32_t hangul_tindex;
      if (bufsize >= 1) {
        dst[0] = SPVM_UTF8PROC_HANGUL_LBASE +
          hangul_sindex / SPVM_UTF8PROC_HANGUL_NCOUNT;
        if (bufsize >= 2) dst[1] = SPVM_UTF8PROC_HANGUL_VBASE +
          (hangul_sindex % SPVM_UTF8PROC_HANGUL_NCOUNT) / SPVM_UTF8PROC_HANGUL_TCOUNT;
      }
      hangul_tindex = hangul_sindex % SPVM_UTF8PROC_HANGUL_TCOUNT;
      if (!hangul_tindex) return 2;
      if (bufsize >= 3) dst[2] = SPVM_UTF8PROC_HANGUL_TBASE + hangul_tindex;
      return 3;
    }
  }
  if (options & SPVM_UTF8PROC_REJECTNA) {
    if (!category) return SPVM_UTF8PROC_ERROR_NOTASSIGNED;
  }
  if (options & SPVM_UTF8PROC_IGNORE) {
    if (property->ignorable) return 0;
  }
  if (options & SPVM_UTF8PROC_STRIPNA) {
    if (!category) return 0;
  }
  if (options & SPVM_UTF8PROC_LUMP) {
    if (category == SPVM_UTF8PROC_CATEGORY_ZS) SPVM__Unicode__utf8proc_decompose_lump(0x0020);
    if (uc == 0x2018 || uc == 0x2019 || uc == 0x02BC || uc == 0x02C8)
      SPVM__Unicode__utf8proc_decompose_lump(0x0027);
    if (category == SPVM_UTF8PROC_CATEGORY_PD || uc == 0x2212)
      SPVM__Unicode__utf8proc_decompose_lump(0x002D);
    if (uc == 0x2044 || uc == 0x2215) SPVM__Unicode__utf8proc_decompose_lump(0x002F);
    if (uc == 0x2236) SPVM__Unicode__utf8proc_decompose_lump(0x003A);
    if (uc == 0x2039 || uc == 0x2329 || uc == 0x3008)
      SPVM__Unicode__utf8proc_decompose_lump(0x003C);
    if (uc == 0x203A || uc == 0x232A || uc == 0x3009)
      SPVM__Unicode__utf8proc_decompose_lump(0x003E);
    if (uc == 0x2216) SPVM__Unicode__utf8proc_decompose_lump(0x005C);
    if (uc == 0x02C4 || uc == 0x02C6 || uc == 0x2038 || uc == 0x2303)
      SPVM__Unicode__utf8proc_decompose_lump(0x005E);
    if (category == SPVM_UTF8PROC_CATEGORY_PC || uc == 0x02CD)
      SPVM__Unicode__utf8proc_decompose_lump(0x005F);
    if (uc == 0x02CB) SPVM__Unicode__utf8proc_decompose_lump(0x0060);
    if (uc == 0x2223) SPVM__Unicode__utf8proc_decompose_lump(0x007C);
    if (uc == 0x223C) SPVM__Unicode__utf8proc_decompose_lump(0x007E);
    if ((options & SPVM_UTF8PROC_NLF2LS) && (options & SPVM_UTF8PROC_NLF2PS)) {
      if (category == SPVM_UTF8PROC_CATEGORY_ZL ||
          category == SPVM_UTF8PROC_CATEGORY_ZP)
        SPVM__Unicode__utf8proc_decompose_lump(0x000A);
    }
  }
  if (options & SPVM_UTF8PROC_STRIPMARK) {
    if (category == SPVM_UTF8PROC_CATEGORY_MN ||
      category == SPVM_UTF8PROC_CATEGORY_MC ||
      category == SPVM_UTF8PROC_CATEGORY_ME) return 0;
  }
  if (options & SPVM_UTF8PROC_CASEFOLD) {
    if (property->casefold_seqindex != UINT16_MAX) {
      return seqindex_write_char_decomposed(property->casefold_seqindex, dst, bufsize, options, last_boundclass);
    }
  }
  if (options & (SPVM_UTF8PROC_COMPOSE|SPVM_UTF8PROC_DECOMPOSE)) {
    if (property->decomp_seqindex != UINT16_MAX &&
        (!property->decomp_type || (options & SPVM_UTF8PROC_COMPAT))) {
      return seqindex_write_char_decomposed(property->decomp_seqindex, dst, bufsize, options, last_boundclass);
    }
  }
  if (options & SPVM_UTF8PROC_CHARBOUND) {
    SPVM__Unicode__utf8proc_bool boundary;
    int tbc = property->boundclass;
    boundary = grapheme_break_extended(*last_boundclass, tbc, last_boundclass);
    if (boundary) {
      if (bufsize >= 1) dst[0] = 0xFFFF;
      if (bufsize >= 2) dst[1] = uc;
      return 2;
    }
  }
  if (bufsize >= 1) *dst = uc;
  return 1;
}

SPVM__Unicode__utf8proc_ssize_t SPVM__Unicode__utf8proc_decompose(
  const SPVM__Unicode__utf8proc_uint8_t *str, SPVM__Unicode__utf8proc_ssize_t strlen,
  SPVM__Unicode__utf8proc_int32_t *buffer, SPVM__Unicode__utf8proc_ssize_t bufsize, SPVM__Unicode__utf8proc_option_t options
) {
    return SPVM__Unicode__utf8proc_decompose_custom(str, strlen, buffer, bufsize, options, NULL, NULL);
}

SPVM__Unicode__utf8proc_ssize_t SPVM__Unicode__utf8proc_decompose_custom(
  const SPVM__Unicode__utf8proc_uint8_t *str, SPVM__Unicode__utf8proc_ssize_t strlen,
  SPVM__Unicode__utf8proc_int32_t *buffer, SPVM__Unicode__utf8proc_ssize_t bufsize, SPVM__Unicode__utf8proc_option_t options,
  SPVM__Unicode__utf8proc_custom_func custom_func, void *custom_data
) {
  /* strlen will be ignored, if SPVM_UTF8PROC_NULLTERM is set in options */
  SPVM__Unicode__utf8proc_ssize_t wpos = 0;
  if ((options & SPVM_UTF8PROC_COMPOSE) && (options & SPVM_UTF8PROC_DECOMPOSE))
    return SPVM_UTF8PROC_ERROR_INVALIDOPTS;
  if ((options & SPVM_UTF8PROC_STRIPMARK) &&
      !(options & SPVM_UTF8PROC_COMPOSE) && !(options & SPVM_UTF8PROC_DECOMPOSE))
    return SPVM_UTF8PROC_ERROR_INVALIDOPTS;
  {
    SPVM__Unicode__utf8proc_int32_t uc;
    SPVM__Unicode__utf8proc_ssize_t rpos = 0;
    SPVM__Unicode__utf8proc_ssize_t decomp_result;
    int boundclass = SPVM_UTF8PROC_BOUNDCLASS_START;
    while (1) {
      if (options & SPVM_UTF8PROC_NULLTERM) {
        rpos += SPVM__Unicode__utf8proc_iterate(str + rpos, -1, &uc);
        /* checking of return value is not necessary,
           as 'uc' is < 0 in case of error */
        if (uc < 0) return SPVM_UTF8PROC_ERROR_INVALIDUTF8;
        if (rpos < 0) return SPVM_UTF8PROC_ERROR_OVERFLOW;
        if (uc == 0) break;
      } else {
        if (rpos >= strlen) break;
        rpos += SPVM__Unicode__utf8proc_iterate(str + rpos, strlen - rpos, &uc);
        if (uc < 0) return SPVM_UTF8PROC_ERROR_INVALIDUTF8;
      }
      if (custom_func != NULL) {
        uc = custom_func(uc, custom_data);   /* user-specified custom mapping */
      }
      decomp_result = SPVM__Unicode__utf8proc_decompose_char(
        uc, buffer + wpos, (bufsize > wpos) ? (bufsize - wpos) : 0, options,
        &boundclass
      );
      if (decomp_result < 0) return decomp_result;
      wpos += decomp_result;
      /* prohibiting integer overflows due to too long strings: */
      if (wpos < 0 ||
          wpos > (SPVM__Unicode__utf8proc_ssize_t)(SSIZE_MAX/sizeof(SPVM__Unicode__utf8proc_int32_t)/2))
        return SPVM_UTF8PROC_ERROR_OVERFLOW;
    }
  }
  if ((options & (SPVM_UTF8PROC_COMPOSE|SPVM_UTF8PROC_DECOMPOSE)) && bufsize >= wpos) {
    SPVM__Unicode__utf8proc_ssize_t pos = 0;
    while (pos < wpos-1) {
      SPVM__Unicode__utf8proc_int32_t uc1, uc2;
      const SPVM__Unicode__utf8proc_property_t *property1, *property2;
      uc1 = buffer[pos];
      uc2 = buffer[pos+1];
      property1 = unsafe_get_property(uc1);
      property2 = unsafe_get_property(uc2);
      if (property1->combining_class > property2->combining_class &&
          property2->combining_class > 0) {
        buffer[pos] = uc2;
        buffer[pos+1] = uc1;
        if (pos > 0) pos--; else pos++;
      } else {
        pos++;
      }
    }
  }
  return wpos;
}

SPVM__Unicode__utf8proc_ssize_t SPVM__Unicode__utf8proc_normalize_utf32(SPVM__Unicode__utf8proc_int32_t *buffer, SPVM__Unicode__utf8proc_ssize_t length, SPVM__Unicode__utf8proc_option_t options) {
  /* SPVM_UTF8PROC_NULLTERM option will be ignored, 'length' is never ignored */
  if (options & (SPVM_UTF8PROC_NLF2LS | SPVM_UTF8PROC_NLF2PS | SPVM_UTF8PROC_STRIPCC)) {
    SPVM__Unicode__utf8proc_ssize_t rpos;
    SPVM__Unicode__utf8proc_ssize_t wpos = 0;
    SPVM__Unicode__utf8proc_int32_t uc;
    for (rpos = 0; rpos < length; rpos++) {
      uc = buffer[rpos];
      if (uc == 0x000D && rpos < length-1 && buffer[rpos+1] == 0x000A) rpos++;
      if (uc == 0x000A || uc == 0x000D || uc == 0x0085 ||
          ((options & SPVM_UTF8PROC_STRIPCC) && (uc == 0x000B || uc == 0x000C))) {
        if (options & SPVM_UTF8PROC_NLF2LS) {
          if (options & SPVM_UTF8PROC_NLF2PS) {
            buffer[wpos++] = 0x000A;
          } else {
            buffer[wpos++] = 0x2028;
          }
        } else {
          if (options & SPVM_UTF8PROC_NLF2PS) {
            buffer[wpos++] = 0x2029;
          } else {
            buffer[wpos++] = 0x0020;
          }
        }
      } else if ((options & SPVM_UTF8PROC_STRIPCC) &&
          (uc < 0x0020 || (uc >= 0x007F && uc < 0x00A0))) {
        if (uc == 0x0009) buffer[wpos++] = 0x0020;
      } else {
        buffer[wpos++] = uc;
      }
    }
    length = wpos;
  }
  if (options & SPVM_UTF8PROC_COMPOSE) {
    SPVM__Unicode__utf8proc_int32_t *starter = NULL;
    SPVM__Unicode__utf8proc_int32_t current_char;
    const SPVM__Unicode__utf8proc_property_t *starter_property = NULL, *current_property;
    SPVM__Unicode__utf8proc_propval_t max_combining_class = -1;
    SPVM__Unicode__utf8proc_ssize_t rpos;
    SPVM__Unicode__utf8proc_ssize_t wpos = 0;
    SPVM__Unicode__utf8proc_int32_t composition;
    for (rpos = 0; rpos < length; rpos++) {
      current_char = buffer[rpos];
      current_property = unsafe_get_property(current_char);
      if (starter && current_property->combining_class > max_combining_class) {
        /* combination perhaps possible */
        SPVM__Unicode__utf8proc_int32_t hangul_lindex;
        SPVM__Unicode__utf8proc_int32_t hangul_sindex;
        hangul_lindex = *starter - SPVM_UTF8PROC_HANGUL_LBASE;
        if (hangul_lindex >= 0 && hangul_lindex < SPVM_UTF8PROC_HANGUL_LCOUNT) {
          SPVM__Unicode__utf8proc_int32_t hangul_vindex;
          hangul_vindex = current_char - SPVM_UTF8PROC_HANGUL_VBASE;
          if (hangul_vindex >= 0 && hangul_vindex < SPVM_UTF8PROC_HANGUL_VCOUNT) {
            *starter = SPVM_UTF8PROC_HANGUL_SBASE +
              (hangul_lindex * SPVM_UTF8PROC_HANGUL_VCOUNT + hangul_vindex) *
              SPVM_UTF8PROC_HANGUL_TCOUNT;
            starter_property = NULL;
            continue;
          }
        }
        hangul_sindex = *starter - SPVM_UTF8PROC_HANGUL_SBASE;
        if (hangul_sindex >= 0 && hangul_sindex < SPVM_UTF8PROC_HANGUL_SCOUNT &&
            (hangul_sindex % SPVM_UTF8PROC_HANGUL_TCOUNT) == 0) {
          SPVM__Unicode__utf8proc_int32_t hangul_tindex;
          hangul_tindex = current_char - SPVM_UTF8PROC_HANGUL_TBASE;
          if (hangul_tindex >= 0 && hangul_tindex < SPVM_UTF8PROC_HANGUL_TCOUNT) {
            *starter += hangul_tindex;
            starter_property = NULL;
            continue;
          }
        }
        if (!starter_property) {
          starter_property = unsafe_get_property(*starter);
        }
        if (starter_property->comb_index < 0x8000 &&
            current_property->comb_index != UINT16_MAX &&
            current_property->comb_index >= 0x8000) {
          int sidx = starter_property->comb_index;
          int idx = current_property->comb_index & 0x3FFF;
          if (idx >= SPVM__Unicode__utf8proc_combinations[sidx] && idx <= SPVM__Unicode__utf8proc_combinations[sidx + 1] ) {
            idx += sidx + 2 - SPVM__Unicode__utf8proc_combinations[sidx];
            if (current_property->comb_index & 0x4000) {
              composition = (SPVM__Unicode__utf8proc_combinations[idx] << 16) | SPVM__Unicode__utf8proc_combinations[idx+1];
            } else
              composition = SPVM__Unicode__utf8proc_combinations[idx];

            if (composition > 0 && (!(options & SPVM_UTF8PROC_STABLE) ||
                !(unsafe_get_property(composition)->comp_exclusion))) {
              *starter = composition;
              starter_property = NULL;
              continue;
            }
          }
        }
      }
      buffer[wpos] = current_char;
      if (current_property->combining_class) {
        if (current_property->combining_class > max_combining_class) {
          max_combining_class = current_property->combining_class;
        }
      } else {
        starter = buffer + wpos;
        starter_property = NULL;
        max_combining_class = -1;
      }
      wpos++;
    }
    length = wpos;
  }
  return length;
}

SPVM__Unicode__utf8proc_ssize_t SPVM__Unicode__utf8proc_reencode(SPVM__Unicode__utf8proc_int32_t *buffer, SPVM__Unicode__utf8proc_ssize_t length, SPVM__Unicode__utf8proc_option_t options) {
  /* SPVM_UTF8PROC_NULLTERM option will be ignored, 'length' is never ignored
     ASSERT: 'buffer' has one spare byte of free space at the end! */
  length = SPVM__Unicode__utf8proc_normalize_utf32(buffer, length, options);
  if (length < 0) return length;
  {
    SPVM__Unicode__utf8proc_ssize_t rpos, wpos = 0;
    SPVM__Unicode__utf8proc_int32_t uc;
    if (options & SPVM_UTF8PROC_CHARBOUND) {
        for (rpos = 0; rpos < length; rpos++) {
            uc = buffer[rpos];
            wpos += unsafe_encode_char(uc, ((SPVM__Unicode__utf8proc_uint8_t *)buffer) + wpos);
        }
    } else {
        for (rpos = 0; rpos < length; rpos++) {
            uc = buffer[rpos];
            wpos += SPVM__Unicode__utf8proc_encode_char(uc, ((SPVM__Unicode__utf8proc_uint8_t *)buffer) + wpos);
        }
    }
    ((SPVM__Unicode__utf8proc_uint8_t *)buffer)[wpos] = 0;
    return wpos;
  }
}

SPVM__Unicode__utf8proc_ssize_t SPVM__Unicode__utf8proc_map(
  const SPVM__Unicode__utf8proc_uint8_t *str, SPVM__Unicode__utf8proc_ssize_t strlen, SPVM__Unicode__utf8proc_uint8_t **dstptr, SPVM__Unicode__utf8proc_option_t options
) {
    return SPVM__Unicode__utf8proc_map_custom(str, strlen, dstptr, options, NULL, NULL);
}

SPVM__Unicode__utf8proc_ssize_t SPVM__Unicode__utf8proc_map_custom(
  const SPVM__Unicode__utf8proc_uint8_t *str, SPVM__Unicode__utf8proc_ssize_t strlen, SPVM__Unicode__utf8proc_uint8_t **dstptr, SPVM__Unicode__utf8proc_option_t options,
  SPVM__Unicode__utf8proc_custom_func custom_func, void *custom_data
) {
  SPVM__Unicode__utf8proc_int32_t *buffer;
  SPVM__Unicode__utf8proc_ssize_t result;
  *dstptr = NULL;
  result = SPVM__Unicode__utf8proc_decompose_custom(str, strlen, NULL, 0, options, custom_func, custom_data);
  if (result < 0) return result;
  buffer = (SPVM__Unicode__utf8proc_int32_t *) malloc(result * sizeof(SPVM__Unicode__utf8proc_int32_t) + 1);
  if (!buffer) return SPVM_UTF8PROC_ERROR_NOMEM;
  result = SPVM__Unicode__utf8proc_decompose_custom(str, strlen, buffer, result, options, custom_func, custom_data);
  if (result < 0) {
    free(buffer);
    return result;
  }
  result = SPVM__Unicode__utf8proc_reencode(buffer, result, options);
  if (result < 0) {
    free(buffer);
    return result;
  }
  {
    SPVM__Unicode__utf8proc_int32_t *newptr;
    newptr = (SPVM__Unicode__utf8proc_int32_t *) realloc(buffer, (size_t)result+1);
    if (newptr) buffer = newptr;
  }
  *dstptr = (SPVM__Unicode__utf8proc_uint8_t *)buffer;
  return result;
}

SPVM__Unicode__utf8proc_uint8_t *SPVM__Unicode__utf8proc_NFD(const SPVM__Unicode__utf8proc_uint8_t *str) {
  SPVM__Unicode__utf8proc_uint8_t *retval;
  SPVM__Unicode__utf8proc_map(str, 0, &retval, SPVM_UTF8PROC_NULLTERM | SPVM_UTF8PROC_STABLE |
    SPVM_UTF8PROC_DECOMPOSE);
  return retval;
}

SPVM__Unicode__utf8proc_uint8_t *SPVM__Unicode__utf8proc_NFC(const SPVM__Unicode__utf8proc_uint8_t *str) {
  SPVM__Unicode__utf8proc_uint8_t *retval;
  SPVM__Unicode__utf8proc_map(str, 0, &retval, SPVM_UTF8PROC_NULLTERM | SPVM_UTF8PROC_STABLE |
    SPVM_UTF8PROC_COMPOSE);
  return retval;
}

SPVM__Unicode__utf8proc_uint8_t *SPVM__Unicode__utf8proc_NFKD(const SPVM__Unicode__utf8proc_uint8_t *str) {
  SPVM__Unicode__utf8proc_uint8_t *retval;
  SPVM__Unicode__utf8proc_map(str, 0, &retval, SPVM_UTF8PROC_NULLTERM | SPVM_UTF8PROC_STABLE |
    SPVM_UTF8PROC_DECOMPOSE | SPVM_UTF8PROC_COMPAT);
  return retval;
}

SPVM__Unicode__utf8proc_uint8_t *SPVM__Unicode__utf8proc_NFKC(const SPVM__Unicode__utf8proc_uint8_t *str) {
  SPVM__Unicode__utf8proc_uint8_t *retval;
  SPVM__Unicode__utf8proc_map(str, 0, &retval, SPVM_UTF8PROC_NULLTERM | SPVM_UTF8PROC_STABLE |
    SPVM_UTF8PROC_COMPOSE | SPVM_UTF8PROC_COMPAT);
  return retval;
}

SPVM__Unicode__utf8proc_uint8_t *SPVM__Unicode__utf8proc_NFKC_Casefold(const SPVM__Unicode__utf8proc_uint8_t *str) {
  SPVM__Unicode__utf8proc_uint8_t *retval;
  SPVM__Unicode__utf8proc_map(str, 0, &retval, SPVM_UTF8PROC_NULLTERM | SPVM_UTF8PROC_STABLE |
    SPVM_UTF8PROC_COMPOSE | SPVM_UTF8PROC_COMPAT | SPVM_UTF8PROC_CASEFOLD | SPVM_UTF8PROC_IGNORE);
  return retval;
}

