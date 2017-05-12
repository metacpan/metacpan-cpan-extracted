#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <stdlib.h>

#define MY_PKG "Syntax::Keyword::RawQuote"
#define HINTK_KEYWORDS MY_PKG "/keywords"

static int enabled(pTHX_ const char *kw_ptr, STRLEN kw_len) {
  HV *hints;
  SV **psv;
  char *p, *pv;
  STRLEN pv_len;


  /* No hints in effect */
  if (!(hints = GvHV(PL_hintgv))) {
    return 0;
  }

  /* No keywords in effect */
  if (!(psv = hv_fetchs(hints, HINTK_KEYWORDS, 0))) {
    return 0;
  }

  pv = SvPV(*psv, pv_len);

  /* Copied, with modifications, from mauke's Keyword::Simple.
   * Match ,keyword($|,) in pv. The Perl layer provides a , even
   * before the first value.
   */
  for (p = pv;
    (p = strchr(p + 1, *kw_ptr)) &&
    p <= pv + pv_len - kw_len;
  ) {
    if (
      (p[-1] == ',')
      && ((p + kw_len == pv + pv_len) || (p[kw_len] == ','))
      && (memcmp(kw_ptr, p, kw_len) == 0)
    ) {
      return 1;
    }
  }
  return 0;
}

/* Populate ender with the matching delimiter for delim (which is
 * a unichar) and return its length. As for quote-like operators,
 * [] {} <> and () are recognized as matching pairs, and other
 * characters match themselves.
 */
static STRLEN matching_delimiter(pTHX_ I32 delim, char *ender) {
  char *p;

  switch (delim) {
    case '[':
      ender[0] = ']';
      return 1;
    case '{':
      ender[0] = '}';
      return 1;
    case '<':
      ender[0] = '>';
      return 1;
    case '(':
      ender[0] = ')';
      return 1;
    default:
      p = uvchr_to_utf8(ender, delim);
      return p - ender;
  }
}

static const void *my_memmem(const void *haystack, size_t haystacklen,
    const void *needle, size_t needlelen) {
  const void *p;
  for (p = haystack;
    ((p = memchr(p, *((char *)needle), haystacklen - (p - haystack))) != NULL) &&
    p + needlelen <= haystack + haystacklen;
  ) {
    if (memcmp(p, needle, needlelen) == 0) {
      return p;
    }
  }
  return NULL;
}

/* The keyword has been recognized. What follows is the raw-quoted
 * string itself. Parse it (leaving the parser after the string) and return
 * an OP_CONST containing the string contents. Delimiters are handled the
 * same as quote-like operators, with the opening delimiter being the first
 * non-whitespace character after the keyword, and the closing delimiter being
 * the matching character if it's an ASCII bracket, or the same as the opening
 * delimiter otherwise. Unlike the built-in quote-likes, there is no backslashing.
 * The first occurrence of the closing delimiter ends the string.
 */
static OP* make_op(pTHX) {
  SV *str = newSVpvn("", 0);
  I32 delim;
  char ender[UTF8_MAXBYTES + 1];
  STRLEN ender_len;
  const char *end;

  /* Discard whitespace */
  lex_read_space(0);

  /* Get the opening delimiter as a unichar */
  delim = lex_read_unichar(0);
  /* And compute the matching close delimiter */
  ender_len = matching_delimiter(aTHX_ delim, ender);

  /* This is the equivalent of the UTF8 flag for linestr. Set it accordingly on the output. */
  if (lex_bufutf8()) {
    SvUTF8_on(str);
  }

  /* If we reach the end of linestr without finding the close delimiter... */
  while ((end = my_memmem(PL_parser->bufptr, PL_parser->bufend - PL_parser->bufptr, ender, ender_len)) == NULL) {
    /* Concatenate what we have before it goes away, */
    sv_catpvn(str, PL_parser->bufptr, PL_parser->bufend - PL_parser->bufptr);
    /* Tell the lexer that we consumed everything (rumor says that lex_next_chunk
     * doesn't always behave reliably otherwise),
     */
    lex_read_to(PL_parser->bufend);
    /* Read more input, */
    if (!lex_next_chunk(0)) {
      /* And complain if we got to EOF without finding the close delimiter */
      croak("Can't find string terminator %.*s anywhere before EOF", (int)ender_len, ender);
    }
  }
  /* 'end' now points to the beginning of the close delimiter. Copy
   * everything up to there into str
   */
  sv_catpvn(str, PL_parser->bufptr, end - PL_parser->bufptr);
  /* Consume the input plus the closing delimiter */
  lex_read_to(end + ender_len);
  /* And finally make the OP_CONST and return it. */
  return newSVOP(OP_CONST, 0, str);
}

static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static int my_keyword_plugin(pTHX_ char *kw_ptr, STRLEN kw_len, OP **op_ptr) {
  if (enabled(aTHX_ kw_ptr, kw_len)) {
    *op_ptr = make_op(aTHX);
    return KEYWORD_PLUGIN_EXPR;
  } else {
    return next_keyword_plugin(aTHX_ kw_ptr, kw_len, op_ptr);
  }
}

MODULE = Syntax::Keyword::RawQuote   PACKAGE = Syntax::Keyword::RawQuote
PROTOTYPES: ENABLE

BOOT:
{
  HV *const stash = gv_stashpvs(MY_PKG, GV_ADD);
  newCONSTSUB(stash, "HINTK_KEYWORDS", newSVpvs(HINTK_KEYWORDS));
  next_keyword_plugin = PL_keyword_plugin;
  PL_keyword_plugin = my_keyword_plugin;
}
