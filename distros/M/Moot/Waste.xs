#/*-*- Mode: C++; c-basic-offset: 2; -*- */

##=====================================================================
## Moot::Waste::Scanner
##=====================================================================

MODULE = Moot		PACKAGE = Moot::Waste::Scanner

##--------------------------------------------------------------
wasteTokenScanner*
new(char *CLASS, TokenIOFormatMask fmt=tiofMedium|tiofLocation)
CODE:
 RETVAL=new wasteTokenScanner(fmt, CLASS);
 //fprintf(stderr, "%s::new() --> %p=%i\n", CLASS,RETVAL,RETVAL);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
void
reset(wasteTokenScanner* wts)
CODE:
 wts->scanner.reset();


##=====================================================================
## Moot::Waste::Lexer
## + uses TokenReader::tr_data to hold SV* of underlying reader
##=====================================================================

MODULE = Moot		PACKAGE = Moot::Waste::Lexer

##--------------------------------------------------------------
wasteLexerReader*
new(char *CLASS, TokenIOFormatMask fmt=tiofUnknown)
CODE:
 RETVAL=new wasteLexerReader(fmt, CLASS);
 //fprintf(stderr, "%s::new() --> %p=%i\n", CLASS,RETVAL,RETVAL);
OUTPUT:
 RETVAL

##-------------------------------------------------------------
void
close(wasteLexerReader *wl)
CODE:
 wl->close();  
 if (wl->tr_data) {
   SvREFCNT_dec( (SV*)wl->tr_data );
   wl->tr_data = NULL;
 }

##-------------------------------------------------------------
##int
##_scanner_refcnt(wasteLexerReader *wl)
##CODE:
## if (wl->tr_data) {
##   RETVAL = SvREFCNT((SV*)SvRV((SV*)wl->tr_data));
## } else {
##   RETVAL = -1;
## }
##OUTPUT:
## RETVAL

##-------------------------------------------------------------
SV*
_get_scanner(wasteLexerReader *wl)
CODE:
 if (!wl->tr_data || !wl->scanner) { XSRETURN_UNDEF; }
 RETVAL = newSVsv((SV*)wl->tr_data);
OUTPUT:
 RETVAL

##-------------------------------------------------------------
void
_set_scanner(wasteLexerReader *wl, SV *scanner_sv)
PREINIT:
  TokenReader *tr;
CODE:
  if( sv_isobject(scanner_sv) && (SvTYPE(SvRV(scanner_sv)) == SVt_PVMG) )
    tr = (TokenReader*)SvIV((SV*)SvRV( scanner_sv ));
  else {
    warn("Moot::Waste::Lexer::_set_scanner() -- scanner_sv is not a blessed SV reference");
    XSRETURN_UNDEF;
  }
  wl->from_reader(tr);
  wl->tr_data = newSVsv(scanner_sv);

##--------------------------------------------------------------
bool
dehyphenate(wasteLexerReader* wl, ...)
CODE:
 if (items > 1) {
   bool on = (bool)SvTRUE( ST(1) );
   wl->dehyph_mode(on);
 }
 RETVAL = wl->lexer.wl_dehyph_mode;
OUTPUT:
 RETVAL

##--------------------------------------------------------------
wasteLexicon*
stopwords(wasteLexerReader* wl)
PREINIT:
 const char *CLASS="Moot::Waste::Lexicon";
CODE:
 RETVAL = &wl->lexer.wl_stopwords;
OUTPUT:
 RETVAL

##--------------------------------------------------------------
wasteLexicon*
abbrevs(wasteLexerReader* wl)
PREINIT:
 const char *CLASS="Moot::Waste::Lexicon";
CODE:
 RETVAL = &wl->lexer.wl_abbrevs;
OUTPUT:
 RETVAL

##--------------------------------------------------------------
wasteLexicon*
conjunctions(wasteLexerReader* wl)
PREINIT:
 const char *CLASS="Moot::Waste::Lexicon";
CODE:
 RETVAL = &wl->lexer.wl_conjunctions;
OUTPUT:
 RETVAL


##=====================================================================
## Moot::Waste::Lexicon
## - NO standalone objects allowed: always accessed via wasteLexerReader (so we can skip ref-counting)
##=====================================================================

MODULE = Moot		PACKAGE = Moot::Waste::Lexicon

##--------------------------------------------------------------
## NO standalone objects!!!
#wasteLexicon*
#new(char *CLASS)
#CODE:
#  RETVAL=new wasteLexicon();
#OUTPUT:
#  RETVAL

##--------------------------------------------------------------
## NO standalone objects!!!
#void
#DESTROY(wasteLexicon* lx)
#CODE:
# //if (lx) delete lx;

##--------------------------------------------------------------
void
clear(wasteLexicon* lx)
CODE:
 lx->clear();

##--------------------------------------------------------------
size_t
size(wasteLexicon* lx)
CODE:
 RETVAL = lx->lex.size();
OUTPUT:
 RETVAL

##--------------------------------------------------------------
void
insert(wasteLexicon* lx, const char *str)
CODE:
 lx->insert(str);

##--------------------------------------------------------------
bool
lookup(wasteLexicon* lx, const char *str)
CODE:
 RETVAL = lx->lookup(str);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
bool
_load_reader(wasteLexicon* lx, TokenReader *reader)
CODE:
 RETVAL = lx->load(reader);
OUTPUT:
 RETVAL
 
##--------------------------------------------------------------
bool
_load_file(wasteLexicon* lx, const char *filename)
CODE:
 RETVAL = lx->load(filename);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
AV*
to_array(wasteLexicon* lx, bool utf8=TRUE)
CODE:
 RETVAL = newAV();
 for (wasteLexicon::Lexicon::const_iterator lxi=lx->lex.begin(); lxi!=lx->lex.end(); ++lxi) {
   SV *sv = stdstring2sv(*lxi, utf8);
   av_push(RETVAL, sv);
 }
 sv_2mortal((SV*)RETVAL);
OUTPUT:
 RETVAL


##=====================================================================
## Moot::Waste::Decoder
## + uses TokenWriter::tw_data to hold SV* of underlying writer
##=====================================================================

MODULE = Moot		PACKAGE = Moot::Waste::Decoder

##--------------------------------------------------------------
wasteDecoder*
new(char *CLASS, TokenIOFormatMask fmt=tiofUnknown)
CODE:
 RETVAL=new wasteDecoder(fmt, CLASS);
 //fprintf(stderr, "%s::new() --> %p=%i\n", CLASS,RETVAL,RETVAL);
OUTPUT:
 RETVAL

##-------------------------------------------------------------
void
close(wasteDecoder *wd)
CODE:
 wd->close();  
 if (wd->tw_data) {
   SvREFCNT_dec( (SV*)wd->tw_data );
   wd->tw_data = NULL;
 }

##-------------------------------------------------------------
SV*
_get_sink(wasteDecoder *wd)
CODE:
 if (!wd->tw_data || !wd->wd_sink) { XSRETURN_UNDEF; }
 RETVAL = newSVsv((SV*)wd->tw_data);
OUTPUT:
 RETVAL

##-------------------------------------------------------------
void
_set_sink(wasteDecoder *wd, SV *sink_sv)
PREINIT:
  TokenWriter *tw;
CODE:
  if( sv_isobject(sink_sv) && (SvTYPE(SvRV(sink_sv)) == SVt_PVMG) )
    tw = (TokenWriter*)SvIV((SV*)SvRV( sink_sv ));
  else {
    warn("Moot::Waste::Decoder::_set_sink() -- sink_sv is not a blessed SV reference");
    XSRETURN_UNDEF;
  }
  wd->to_writer(tw);
  wd->tw_data = newSVsv(sink_sv);

##-------------------------------------------------------------
size_t
buffer_size(wasteDecoder *wd)
CODE:
 RETVAL = wd->wd_buf.size();
OUTPUT:
 RETVAL

##-------------------------------------------------------------
bool
buffer_empty(wasteDecoder *wd)
CODE:
 RETVAL = wd->wd_buf.empty();
OUTPUT:
 RETVAL

##-------------------------------------------------------------
HV*
buffer_peek(wasteDecoder *wd, bool utf8=TRUE)
CODE:
 if (wd->wd_buf.empty()) { XSRETURN_UNDEF; }
 RETVAL = token2hv( &wd->wd_buf.front(), utf8 );
OUTPUT:
 RETVAL

##-------------------------------------------------------------
bool
buffer_can_shift(wasteDecoder *wd)
CODE:
 RETVAL = wd->buffer_can_shift();
OUTPUT:
 RETVAL

##-------------------------------------------------------------
void
buffer_shift(wasteDecoder *wd)
CODE:
 wd->buffer_shift();


##-------------------------------------------------------------
AV*
buffer_flush(wasteDecoder *wd, bool force=FALSE, bool utf8=TRUE)
CODE:
 if (wd->wd_buf.empty()) { XSRETURN_UNDEF; }
 RETVAL = newAV();
 while ( !wd->wd_buf.empty() && (force || wd->buffer_can_shift()) ) {
   HV *tokhv = token2hv( &(wd->buffer_peek()), utf8 );
   av_push(RETVAL, newRV_inc((SV*)tokhv));
   wd->buffer_shift();
 }
 sv_2mortal((SV*)RETVAL);
OUTPUT:
 RETVAL


##=====================================================================
## Moot::Waste::Annotator
## + uses TokenWriter::tw_data to hold SV* of underlying writer
##=====================================================================

MODULE = Moot		PACKAGE = Moot::Waste::Annotator

##--------------------------------------------------------------
wasteAnnotatorWriter*
new(char *CLASS, TokenIOFormatMask fmt=tiofMediumRare)
CODE:
 RETVAL=new wasteAnnotatorWriter(fmt, CLASS);
OUTPUT:
 RETVAL

##-------------------------------------------------------------
void
close(wasteAnnotatorWriter *waw)
CODE:
 waw->close();  
 if (waw->tw_data) {
   SvREFCNT_dec( (SV*)waw->tw_data );
   waw->tw_data = NULL;
 }

##-------------------------------------------------------------
SV*
_get_sink(wasteAnnotatorWriter *waw)
CODE:
 if (!waw->tw_data || !waw->waw_sink) { XSRETURN_UNDEF; }
 RETVAL = newSVsv((SV*)waw->tw_data);
OUTPUT:
 RETVAL

##-------------------------------------------------------------
void
_set_sink(wasteAnnotatorWriter *waw, SV *sink_sv)
PREINIT:
  TokenWriter *tw;
CODE:
  if( sv_isobject(sink_sv) && (SvTYPE(SvRV(sink_sv)) == SVt_PVMG) )
    tw = (TokenWriter*)SvIV((SV*)SvRV( sink_sv ));
  else {
    warn("Moot::Waste::AnnotatorWriter::_set_sink() -- sink_sv is not a blessed SV reference");
    XSRETURN_UNDEF;
  }
  waw->to_writer(tw);
  waw->tw_data = newSVsv(sink_sv);

##-------------------------------------------------------------
HV*
annotate(wasteAnnotatorWriter *waw, HV *tokhv)
PREINIT:
 mootToken mtok;
CODE:
 hv2token(tokhv, &mtok);
 waw->waw_annotator.annotate_token(mtok);
 RETVAL = token2hv(&mtok);
OUTPUT:
 RETVAL

