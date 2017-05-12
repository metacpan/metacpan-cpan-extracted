#/*-*- Mode: C++ -*- */

MODULE = Moot		PACKAGE = Moot::TokenWriter

PROTOTYPES: DISABLE

##=====================================================================
## TokenWriter: Constructors etc.

##--------------------------------------------------------------
## -- NO abstract constructor!
#TokenWriter *
#new(char *CLASS, TokenIOFormatMask fmt=tiofWellDone)
#CODE:
#  RETVAL=new TokenWriter();
#OUTPUT:
#  RETVAL

##--------------------------------------------------------------
void
DESTROY(TokenWriter* tw)
CODE:
 if (tw) delete tw;

##=====================================================================
## TokenWriter: Output Selection

##--------------------------------------------------------------
void
close(TokenWriter* tw)
CODE:
 tw->close();

##--------------------------------------------------------------
int
opened(TokenWriter* tw)
CODE:
 RETVAL = tw->opened() ? 1 : 0;
OUTPUT:
 RETVAL

##--------------------------------------------------------------
void
to_fh(TokenWriter* tw, SV *ioref)
PREINIT:
 mootPerlOutputFH *mfh;
CODE:
 mfh = new mootPerlOutputFH(ioref);
 tw->to_mstream(mfh);
 tw->tw_ostream_created = true;

##--------------------------------------------------------------
void
to_file(TokenWriter* tw, const char *filename)
CODE:
 tw->to_filename(filename);

##--------------------------------------------------------------
## to_string(): wrapped perl-side with string-fh; otherwise we would need full-blown mootio wrapper
#void to_string(TokenWriter* tw, SV *buf)

##=====================================================================
## TokenWriter: Token Stream Operations
##=====================================================================

##--------------------------------------------------------------
void
put_token(TokenWriter *tw, HV *tok)
PREINIT:
 mootToken mtok;
CODE:
 hv2token(tok,&mtok);
 tw->put_token(mtok);

##--------------------------------------------------------------
void
put_tokens(TokenWriter *tw, AV *tokens)
PREINIT:
 mootSentence ms;
CODE:
 av2sentence(tokens,&ms);
 tw->put_tokens(ms);

##--------------------------------------------------------------
void
put_sentence(TokenWriter *tw, AV *sent)
PREINIT:
 mootSentence ms;
CODE:
 av2sentence(sent,&ms);
 tw->put_sentence(ms);

##--------------------------------------------------------------
void
put_comment_block_begin(TokenWriter *tw)
CODE:
 tw->put_comment_block_begin();

##--------------------------------------------------------------
void
put_comment_block_end(TokenWriter *tw)
CODE:
 tw->put_comment_block_end();


##--------------------------------------------------------------
void
put_comment(TokenWriter *tw, SV *comment_str)
PREINIT:
 STRLEN len;
 char *buf;
CODE:
 buf = SvPV(comment_str, len);
 tw->put_comment_buffer(buf,len);


##--------------------------------------------------------------
void
put_raw(TokenWriter *tw, SV *raw_str);
PREINIT:
 STRLEN len;
 char *buf;
CODE:
 buf = SvPV(raw_str, len);
 tw->put_raw_buffer(buf,len);



##=====================================================================
## TokenWriter: Accessors

##--------------------------------------------------------------
TokenIOFormatMask
format(TokenWriter* tw, ...)
CODE:
 if (items > 1) {
   TokenIOFormatMask fmt = SvUV( ST(1) );
   tw->tw_format = fmt;
 }
 RETVAL = (TokenIOFormatMask)tw->tw_format;
OUTPUT:
 RETVAL

##--------------------------------------------------------------
const char *
name(TokenWriter* tw, ...)
CODE:
 if (items > 1) {
   const char *myname = SvPV_nolen( ST(1) );
   tw->tw_name = myname;
 }
 RETVAL = tw->tw_name.c_str();
OUTPUT:
 RETVAL


##=====================================================================
## TokenWriterNative
##=====================================================================

MODULE = Moot		PACKAGE = Moot::TokenWriter::Native

TokenWriterNative *
new(char *CLASS, TokenIOFormatMask fmt=tiofWellDone)
CODE:
  RETVAL=new TokenWriterNative(fmt, CLASS);
OUTPUT:
  RETVAL

##=====================================================================
## TokenWriterXML
##=====================================================================

MODULE = Moot		PACKAGE = Moot::TokenWriter::XML

##--------------------------------------------------------------
TokenWriterExpat *
new(char *CLASS, TokenIOFormatMask fmt=tiofXML)
CODE:
  RETVAL=new TokenWriterExpat(fmt);
  RETVAL->tw_name = CLASS;
OUTPUT:
  RETVAL

