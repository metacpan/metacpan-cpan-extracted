/* vi: set ft=c inde=: */

/* Perls before 5.18 lack isIDCONT_uni, but baring minor differences of weird
 * Unicode characters, isALNUM_uni is close enough
 */
#ifndef isIDCONT_uni
#define isIDCONT_uni(c)       isALNUM_uni(c)
#endif

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

#define parse_lexvar()  MY_parse_lexvar(aTHX)
static PADOFFSET MY_parse_lexvar(pTHX)
{
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
