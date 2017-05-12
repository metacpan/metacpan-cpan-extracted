/* -*- Mode: C++; c-basic-offset 2; */
#include "MootPerl.h"

#undef VERSION
#include <mootConfig.h>

/*======================================================================
 * Constants
 */
const char *moot_version_string = PACKAGE_VERSION;

/*======================================================================
 * Conversions
 */

/*--------------------------------------------------------------*/
HV* token2hv(const mootToken *tok, U32 utf8)
{
  HV *hv = newHV();

  //-- token: analyses
  AV *anav = newAV();
  for (mootToken::Analyses::const_iterator ai=tok->tok_analyses.begin();
       ai != tok->tok_analyses.end();
       ai++)
    {
      HV *anhv = newHV();
      hv_stores(anhv, "tag",     stdstring2sv(ai->tag,utf8));
      hv_stores(anhv, "details", stdstring2sv(ai->details,utf8));
      hv_stores(anhv, "prob",    newSVnv(ai->prob));
      //sv_2mortal((SV*)anhv); //-- combine with newRV_inc() in av_push()?
      av_push(anav, newRV_noinc((SV*)anhv));
    }
  //sv_2mortal((SV*)anav); //-- use in combination with newRV_inc() in hv_stores()?

  //-- token: hash
  hv_stores(hv, "type",     newSVuv(tok->tok_type));
  hv_stores(hv, "text",     stdstring2sv(tok->tok_text,utf8));
  hv_stores(hv, "tag",      stdstring2sv(tok->tok_besttag,utf8));
  hv_stores(hv, "analyses", newRV_noinc((SV*)anav));
  if (tok->tok_location.offset != 0 || tok->tok_location.length != 0) {
    //-- token: location: only stored if offset or length is nonzero
    hv_stores(hv, "offset",   newSVuv(tok->tok_location.offset));
    hv_stores(hv, "length",   newSVuv(tok->tok_location.length));
  }

  sv_2mortal((SV*)hv);
  return hv;
}


/*--------------------------------------------------------------*/
mootToken *hv2token(HV *hv, mootToken *tok, U32 utf8)
{
  SV **svpp, **avrvpp;
  if (!tok) tok = new mootToken();
  tok->tok_data = (void*)hv;

  if ((svpp=hv_fetchs(hv,"type",0))) tok->tok_type=(mootTokenType)SvUV(*svpp);
  if ((svpp=hv_fetchs(hv,"text",0))) sv2stdstring(*svpp,tok->tok_text,utf8);
  if ((svpp=hv_fetchs(hv,"tag",0)))  sv2stdstring(*svpp,tok->tok_besttag,utf8);
  if ((svpp=hv_fetchs(hv,"offset",0))) tok->tok_location.offset=(OffsetT)SvUV(*svpp);
  if ((svpp=hv_fetchs(hv,"length",0))) tok->tok_location.length=(OffsetT)SvUV(*svpp);

  if ((avrvpp=hv_fetchs(hv,"analyses",0))) {
    AV *anav = (AV*)SvRV(*avrvpp);
    I32 avlen = av_len(anav);
    for (I32 avi=0; avi <= avlen; avi++) {
      SV **anhvrv = av_fetch(anav,avi,0);
      if (!anhvrv || !*anhvrv) continue;
      HV *anhv = (HV*)SvRV(*anhvrv);
      mootToken::Analysis an;
      if ((svpp=hv_fetchs(anhv,"tag",0))) sv2stdstring(*svpp,an.tag,utf8);
      if ((svpp=hv_fetchs(anhv,"details",0))) sv2stdstring(*svpp,an.details,utf8);
      if ((svpp=hv_fetchs(anhv,"prob",0))) an.prob=SvNV(*svpp);
      tok->tok_analyses.push_back(an);
    }
  }

  return tok;
}

/*--------------------------------------------------------------*/
AV* sentence2av(const mootSentence *s, U32 utf8)
{
  AV *sav = newAV();
  for (mootSentence::const_iterator si=s->begin(); si != s->end(); si++) {
    HV *tokhv = token2hv(&(*si), utf8);
    av_push(sav, newRV_inc((SV*)tokhv));    
  }
  sv_2mortal((SV*)sav);
  return sav;
}

/*--------------------------------------------------------------*/
mootSentence *av2sentence(AV *sav, mootSentence *s, U32 utf8)
{
  if (!s) s = new mootSentence();

  I32 slen = av_len(sav);
  for (I32 si=0; si <= slen; si++) {
    SV **tokhvrv = av_fetch(sav,si,0);
    if (!tokhvrv || !*tokhvrv) continue;
    s->push_back(mootToken());
    hv2token((HV*)SvRV(*tokhvrv), &(s->back()), utf8);
  }

  return s;
}

/*--------------------------------------------------------------*/
mootTagSet *av2tagset(AV *tsav, mootTagSet *tagset, U32 utf8)
{
  if (!tagset) tagset = new mootTagSet();

  I32 tslen = av_len(tsav);
  for (I32 si=0; si <= tslen; si++) {
    SV **svpp = av_fetch(tsav,si,0);
    if (!svpp || !*svpp) continue;
    std::string tagstr;
    sv2stdstring(*svpp, tagstr, utf8);
    tagset->insert(tagstr);
  }

  return tagset;
}

/*======================================================================
 * Conversions: in-place
 */

/*--------------------------------------------------------------*/
void sentence2tokdata(mootSentence *s, U32 utf8)
{
  for (mootSentence::iterator si=s->begin(); si != s->end(); si++) {
    HV *tokhv = (HV*)si->tok_data;
    hv_stores(tokhv, "tag", stdstring2sv(si->tok_besttag,utf8));
  }
}

/*======================================================================
 * TokenIO class name conversions
 */

//--------------------------------------------------------------
const char *TokenReaderClass(const TokenReader *tr)
{
  if (!tr) return "null";
  else if (tr->tr_name == "TokenReader")       return "Moot::TokenReader";
  else if (tr->tr_name == "TokenReaderNative") return "Moot::TokenReader::Native";
  else if (tr->tr_name == "TokenReaderExpat")  return "Moot::TokenReader::XML";
  else if (tr->tr_name == "wasteTokenScanner") return "Moot::Waste::Scanner";
  else if (tr->tr_name == "wasteLexer")        return "Moot::Waste::Lexer";
  else if (tr->tr_name == "wasteLexerReader")  return "Moot::Waste::Lexer";
  return tr->tr_name.c_str();
}

//--------------------------------------------------------------
const char *TokenWriterClass(const TokenWriter *tw)
{
  if (!tw) return "null";
  else if (tw->tw_name == "TokenWriter")       return "Moot::TokenWriter";
  else if (tw->tw_name == "TokenWriterNative") return "Moot::TokenWriter::Native";
  else if (tw->tw_name == "TokenWriterExpat")  return "Moot::TokenWriter::XML";
  else if (tw->tw_name == "wasteDecoder")      return "Moot::Waste::Decoder";
  return tw->tw_name.c_str();
}

//--------------------------------------------------------------
const char *sv_getclass(SV *sv)
{
  if (!sv || !SvROK(sv))
    return NULL;
  HV *stash = SvSTASH(SvRV(sv));
  if (!stash) return NULL;
  return HvNAME(stash);
}

/*======================================================================
 * mootPerlInputFH
 */

//--------------------------------------------------------------
mootPerlInputFH::mootPerlInputFH(SV *sv) 
  : ioref(sv),
    io(NULL)
{
  if (ioref) {
    SvREFCNT_inc(ioref);
    io = IoIFP( sv_2io(ioref) );
  }
}

//--------------------------------------------------------------
mootPerlInputFH::~mootPerlInputFH(void)
{
  if (ioref) {
    SvREFCNT_dec(ioref);
  }
}

//--------------------------------------------------------------
bool mootPerlInputFH::eof(void)
{
  if (!io) return true;
  //return PerlIO_eof(io);  //-- BUGGY
  int c = PerlIO_getc(io);
  if (c==EOF) return true;
  PerlIO_ungetc(io,c);
  return false;
}

//--------------------------------------------------------------
bool mootPerlInputFH::valid(void)
{
  bool rc = (io != NULL && !PerlIO_error(io));
  return rc;
}

//--------------------------------------------------------------
int mootPerlInputFH::getbyte(void)
{
  if (eof() || !valid()) return EOF;
  return PerlIO_getc(io);
}

//--------------------------------------------------------------
mootio::ByteCount mootPerlInputFH::read(char *buf, size_t n)
{
  if (eof() || !valid())
    return 0;
  return (mootio::ByteCount)PerlIO_read(io, buf, n);
};


/*======================================================================
 * mootPerlInputBuf
 */

//--------------------------------------------------------------
mootPerlInputBuf::mootPerlInputBuf(SV *svbuf) 
  : micbuffer(NULL,0),
    sv(svbuf)
{
  if (sv) {
    STRLEN len;
    SvREFCNT_inc(sv);
    const char *data = SvPVutf8(svbuf, len);
    this->assign(data,len);
  }
}

//--------------------------------------------------------------
mootPerlInputBuf::~mootPerlInputBuf(void)
{
  if (sv) {
    SvREFCNT_dec(sv);
  }
}

/*======================================================================
 * mootPerlOutputFH
 */

//--------------------------------------------------------------
mootPerlOutputFH::mootPerlOutputFH(SV *sv)
  : ioref(sv),
    io(NULL)
{
  if (ioref) {
    SvREFCNT_inc(ioref);
    io = IoIFP( sv_2io(ioref) );
  }
}

//--------------------------------------------------------------
mootPerlOutputFH::~mootPerlOutputFH(void)
{
  this->close();
  if (ioref) {
    SvREFCNT_dec(ioref);
  }
}

//--------------------------------------------------------------
bool mootPerlOutputFH::valid(void)
{
  return io != NULL && !PerlIO_error(io);
}

//--------------------------------------------------------------
bool mootPerlOutputFH::eof(void)
{
  return io == NULL || PerlIO_eof(io);
}

//--------------------------------------------------------------
bool mootPerlOutputFH::flush(void)
{
  if (io) PerlIO_flush(io);
  return this->valid();
}

//--------------------------------------------------------------
bool mootPerlOutputFH::close(void)
{
  return this->flush();
}

//--------------------------------------------------------------
bool mootPerlOutputFH::write(const char *buf, size_t n)
{
  if (!io) return false;
  int nwrote = PerlIO_write(io, buf, n);
  return (nwrote==n);
}

//--------------------------------------------------------------
bool mootPerlOutputFH::putbyte(unsigned char c)
{
  if (!io) return false;
  PerlIO_putc(io, c);
  return this->valid();
}

//--------------------------------------------------------------
bool mootPerlOutputFH::puts(const char *s)
{
  return this->write(s,strlen(s));
}

//--------------------------------------------------------------
bool mootPerlOutputFH::puts(const std::string &s)
{
  return this->write(s.data(),s.size());
}

//--------------------------------------------------------------
bool mootPerlOutputFH::vprintf(const char *fmt, va_list &ap)
{
  if (!io) return false;
  int nwrote = PerlIO_vprintf(io,fmt,ap);
  return nwrote >= 0;
}
