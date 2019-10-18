/* vi: set ft=c inde=: */

/* Perls before 5.18 lack isIDCONT_uni, but baring minor differences of weird
 * Unicode characters, isALNUM_uni is close enough
 */
#ifndef isIDCONT_uni
#define isIDCONT_uni(c)       isALNUM_uni(c)
#endif

#define sv_cat_c(sv, c)  MY_sv_cat_c(aTHX_ sv, c)
static void MY_sv_cat_c(pTHX_ SV *sv, U32 c)
{
  char ds[UTF8_MAXBYTES + 1], *d;
  d = (char *)uvchr_to_utf8((U8 *)ds, c);
  if (d - ds > 1) {
    sv_utf8_upgrade(sv);
  }
  sv_catpvn(sv, ds, d - ds);
}

#define lex_consume(s)  MY_lex_consume(aTHX_ s)
static int MY_lex_consume(pTHX_ char *s)
{
  /* I want strprefix() */
  size_t i;
  for(i = 0; s[i]; i++) {
    if(s[i] != PL_parser->bufptr[i])
      return 0;
  }

  lex_read_to(PL_parser->bufptr + i);
  return i;
}

#define lex_scan_ident()  MY_lex_scan_ident(aTHX)
static SV *MY_lex_scan_ident(pTHX)
{
  /* Inspired by
   *   https://metacpan.org/source/MAUKE/Function-Parameters-1.0705/Parameters.xs#L265
   */
  I32 c;
  bool at_start;
  SV *ret = newSVpvs("");
  if(lex_bufutf8())
    SvUTF8_on(ret);

  at_start = TRUE;

  c = lex_peek_unichar(0);

  while(c != -1) {
    if(at_start ? isIDFIRST_uni(c) : isALNUM_uni(c)) {
      at_start = FALSE;
      sv_cat_c(ret, lex_read_unichar(0));

      c = lex_peek_unichar(0);
    }
    else
      break;
  }

  if(SvCUR(ret))
    return ret;

  SvREFCNT_dec(ret);
  return NULL;
}

#define lex_scan_attr()  MY_lex_scan_attr(aTHX)
static SV *MY_lex_scan_attr(pTHX)
{
  SV *ret = lex_scan_ident();
  if(!ret)
    return ret;

  lex_read_space(0);

  if(lex_peek_unichar(0) != '(')
    return ret;
  sv_cat_c(ret, lex_read_unichar(0));

  int count = 1;
  I32 c = lex_peek_unichar(0);
  while(count && c != -1) {
    if(c == '(')
      count++;
    if(c == ')')
      count--;
    if(c == '\\') {
      /* The next char does not bump count even if it is ( or );
       * the \\ is still captured
       */
      sv_cat_c(ret, lex_read_unichar(0));
      c = lex_peek_unichar(0);
      if(c == -1)
        goto unterminated;
    }

    sv_cat_c(ret, lex_read_unichar(0));
    c = lex_peek_unichar(0);
  }

  if(c != -1)
    return ret;

unterminated:
  croak("Unterminated attribute parameter in attribute list");
}

#define lex_scan_attrs(compcv)  MY_lex_scan_attrs(aTHX_ compcv)
static OP *MY_lex_scan_attrs(pTHX_ CV *compcv)
{
  /* Attributes are supplied to newATTRSUB() as an OP_LIST containing
   * OP_CONSTs, one attribute in each as a plain SV. Note that we don't have
   * to parse inside the contents of the parens; that is handled by the
   * attribute handlers themselves
   */
  OP *attrs = NULL;
  SV *attr;

  lex_read_space(0);
  while((attr = lex_scan_attr())) {
    lex_read_space(0);

    if(compcv && strEQ(SvPV_nolen(attr), "lvalue")) {
      CvLVALUE_on(compcv);
    }

    if(!attrs)
      attrs = newLISTOP(OP_LIST, 0, NULL, NULL);

    attrs = op_append_elem(OP_LIST, attrs, newSVOP(OP_CONST, 0, attr));
  }

  return attrs;
}

#define lex_scan_lexvar()  MY_lex_scan_lexvar(aTHX)
static SV *MY_lex_scan_lexvar(pTHX)
{
  int sigil = lex_peek_unichar(0);
  switch(sigil) {
    case '$':
    case '@':
    case '%':
      lex_read_unichar(0);
      break;

    default:
      croak("Expected a lexical variable");
  }

  SV *ret = lex_scan_ident();
  if(!ret)
    return NULL;

  /* prepend sigil - which we know to be a single byte */
  SvGROW(ret, SvCUR(ret) + 1);
  Move(SvPVX(ret), SvPVX(ret) + 1, SvCUR(ret), char);
  SvPVX(ret)[0] = sigil;
  SvCUR(ret)++;

  SvPVX(ret)[SvCUR(ret)] = 0;

  return ret;
}

#define lex_scan_parenthesized()  MY_lex_scan_parenthesized(aTHX)
static SV *MY_lex_scan_parenthesized(pTHX)
{
  I32 c;
  int parencount = 0;
  SV *ret = newSVpvs("");
  if(lex_bufutf8())
    SvUTF8_on(ret);

  c = lex_peek_unichar(0);

  while(c != -1) {
    sv_cat_c(ret, lex_read_unichar(0));

    switch(c) {
      case '(': parencount++; break;
      case ')': parencount--; break;
    }
    if(!parencount)
      break;

    c = lex_peek_unichar(0);
  }

  if(SvCUR(ret))
    return ret;

  SvREFCNT_dec(ret);
  return NULL;
}

#define parse_lexvar()  MY_parse_lexvar(aTHX)
static PADOFFSET MY_parse_lexvar(pTHX)
{
  /* TODO: Rewrite this in terms of using lex_scan_lexvar()
  */
  char *lexname = PL_parser->bufptr;

  if(lex_read_unichar(0) != '$')
    croak("Expected a lexical scalar at %s", lexname);

  if(!isIDFIRST_uni(lex_peek_unichar(0)))
    croak("Expected a lexical scalar at %s", lexname);
  lex_read_unichar(0);
  while(isIDCONT_uni(lex_peek_unichar(0)))
    lex_read_unichar(0);

  /* Forbid $_ */
  if(PL_parser->bufptr - lexname == 2 && lexname[1] == '_')
    croak("Can't use global $_ in \"my\"");

  return pad_add_name_pvn(lexname, PL_parser->bufptr - lexname, 0, NULL, NULL);
}
