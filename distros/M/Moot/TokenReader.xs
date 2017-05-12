#/*-*- Mode: C++ -*- */

MODULE = Moot		PACKAGE = Moot::TokenReader

PROTOTYPES: DISABLE

##=====================================================================
## TokenReader: Constructors etc.

##--------------------------------------------------------------
## -- NO abstract constructor!
#TokenReader *
#new(char *CLASS, TokenIOFormatMask fmt=tiofWellDone)
#CODE:
#  RETVAL=new TokenReader();
#OUTPUT:
#  RETVAL

##--------------------------------------------------------------
void
DESTROY(TokenReader* tr)
CODE:
 //fprintf(stderr, "TokenReader::DESTROY(%s) --> %p=%i\n", sv_getclass(ST(0)), tr,tr);
 if (tr) delete tr;

##=====================================================================
## TokenReader: Input Selection

##--------------------------------------------------------------
void
close(TokenReader* tr)
CODE:
 tr->close();

##--------------------------------------------------------------
int
opened(TokenReader* tr)
CODE:
 RETVAL = tr->opened() ? 1 : 0;
OUTPUT:
 RETVAL

##--------------------------------------------------------------
void
from_fh(TokenReader* tr, SV *ioref)
PREINIT:
 mootPerlInputFH *mfh;
CODE:
 mfh = new mootPerlInputFH(ioref);
 tr->from_mstream(mfh);
 tr->tr_istream_created = true;

##--------------------------------------------------------------
void
from_file(TokenReader* tr, const char *filename)
CODE:
 tr->from_filename(filename);

##--------------------------------------------------------------
void
from_string(TokenReader* tr, SV *buf)
PREINIT:
 mootPerlInputBuf *mfh;
CODE:
 mfh = new mootPerlInputBuf(buf);
 tr->from_mstream(mfh);
 tr->tr_istream_created = true;

##=====================================================================
## Token-Level Access
##=====================================================================

##--------------------------------------------------------------
HV*
get_token(TokenReader* tr, bool utf8=TRUE)
PREINIT:
  mootTokenType toktyp;
CODE:
  toktyp = tr->get_token();
  if (toktyp==TokTypeEOF) {
    XSRETURN_UNDEF;
  }
  else RETVAL = token2hv( tr->token(), utf8 );
OUTPUT:
  RETVAL

##--------------------------------------------------------------
AV*
get_sentence(TokenReader* tr, bool utf8=TRUE)
PREINIT:
  mootTokenType toktyp;
CODE:
  toktyp = tr->get_sentence();
  if (toktyp==TokTypeEOF) {
    XSRETURN_UNDEF;
  }
  else RETVAL = sentence2av( tr->sentence(), utf8 );
OUTPUT:
  RETVAL

##=====================================================================
## TokenReader: Accessors

##--------------------------------------------------------------
TokenIOFormatMask
format(TokenReader* tr, ...)
CODE:
 if (items > 1) {
   TokenIOFormatMask fmt = SvUV( ST(1) );
   tr->tr_format = fmt;
 }
 RETVAL = (TokenIOFormatMask)tr->tr_format;
OUTPUT:
 RETVAL

##--------------------------------------------------------------
const char *
name(TokenReader* tr, ...)
CODE:
 if (items > 1) {
   const char *myname = SvPV_nolen( ST(1) );
   tr->tr_name = myname;
 }
 RETVAL = tr->tr_name.c_str();
OUTPUT:
 RETVAL

##--------------------------------------------------------------
size_t
line_number(TokenReader* tr, ...)
CODE:
 if (items > 1) {
   size_t n = (size_t)SvUV( ST(1) );
   tr->line_number(n);
 }
 RETVAL = tr->line_number();
OUTPUT:
 RETVAL

##--------------------------------------------------------------
size_t
column_number(TokenReader* tr, ...)
CODE:
 if (items > 1) {
   size_t n = (size_t)SvUV( ST(1) );
   tr->column_number(n);
 }
 RETVAL = tr->column_number();
OUTPUT:
 RETVAL

##--------------------------------------------------------------
size_t
byte_number(TokenReader* tr, ...)
CODE:
 if (items > 1) {
   size_t n = (size_t)SvUV( ST(1) );
   tr->byte_number(n);
 }
RETVAL = (size_t)tr->byte_number();
OUTPUT:
 RETVAL

##=====================================================================
## TokenReaderNative
##=====================================================================

MODULE = Moot		PACKAGE = Moot::TokenReader::Native

TokenReaderNative *
new(char *CLASS, TokenIOFormatMask fmt=tiofWellDone)
CODE:
  RETVAL=new TokenReaderNative(fmt, CLASS);
OUTPUT:
  RETVAL

##=====================================================================
## TokenReaderXML
##=====================================================================

MODULE = Moot		PACKAGE = Moot::TokenReader::XML

##--------------------------------------------------------------
TokenReaderExpat *
new(char *CLASS, TokenIOFormatMask fmt=tiofXML)
CODE:
  RETVAL=new TokenReaderExpat(fmt);
  RETVAL->tr_name = CLASS;
OUTPUT:
  RETVAL

