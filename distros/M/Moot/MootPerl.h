/*-*- Mode: C++; coding: utf-8; c-basic-offset: 2; -*-*/
extern "C" {
 #include "EXTERN.h"
 #include "perl.h"
 #include "XSUB.h"
};
//#include "ppport.h"

#include <moot.h>

/*======================================================================
 * Debugging
 */
/*#define MOOTDEBUG 1*/

#if defined(MOOTDEBUG) || defined(MOOT_PERL_DEBUG)
# define MOOT_PERL_DEBUG_EVAL(code_) code_
#else
# define MOOT_PERL_DEBUG_EVAL(code_)
#endif

/*======================================================================
 * typedefs
 */
//typedef moot::mootLexfreqs mootLexfreqs;
//typedef moot::mootNgrams   mootNgrams;
typedef moot::mootHMM::TagID   TagID;
typedef moot::mootHMM::TagID   TokID;
typedef moot::mootHMM::ClassID ClassID;
typedef moot::mootTokString    TokStr;
typedef moot::mootTagString    TagStr;

typedef unsigned int	       TokenIOFormatMask;


/*======================================================================
 * Constants
 */
extern const char *moot_version_string;


/*======================================================================
 * macros
 */
#if defined(SvPVutf8_nolen)
# define sv2stdstring(sv,str,utf8) \
  str = ((utf8) ? SvPVutf8_nolen(sv) : SvPV_nolen(sv))
#else
  static inline
  void sv2stdstring(SV *sv, std::string &str, U32 utf8)
  {
    STRLEN len;
    char *pv = sv_2pvutf8(sv, &len);
    str.assign(pv,len);
  }
#endif /* defined(SvPVutf8_nolen) */

#if defined(newSVpvn_utf8)
# define stdstring2sv(str,utf8) \
  newSVpvn_utf8((str).data(), (str).size(), utf8)
#else
 static inline
 SV* stdstring2sv(const std::string &str, U32 utf8)
 {
   SV *sv = newSVpvn(str.data(), str.size());
   if (utf8) {
     SvUTF8_on(sv);
   }
   return sv;
 }
#endif /* defined(newSVpvn_utf8) */

/*======================================================================
 * Conversions: copy
 */
HV*           token2hv(const mootToken *tok, U32 utf8=TRUE);        //-- copies: type,text,tag,analyses
mootToken    *hv2token(HV *hv, mootToken *tok=NULL, U32 utf8=TRUE); //-- copies: type,text,tag,analyses,data=hv

AV*           sentence2av(const mootSentence *s, U32 utf8=TRUE);
mootSentence *av2sentence(AV *av, mootSentence *s=NULL, U32 utf8=TRUE);

mootTagSet *av2tagset(AV *tsav, mootTagSet *tagset, U32 utf8=TRUE);

/*======================================================================
 * Conversions: in-place
 */
void sentence2tokdata(mootSentence *s, U32 utf8=TRUE);

/*======================================================================
 * TokenIO class name conversions
 */
const char *TokenReaderClass(const moot::TokenReader *tr);
const char *TokenWriterClass(const moot::TokenWriter *tw);

const char *sv_getclass(SV *sv);

/*======================================================================
 * mootPerlInputFH: mootio stream wrapper for perl stream input
 */
class mootPerlInputFH : virtual public mootio::mistream
{
public:
  SV  *ioref; //-- underlying SV*
  PerlIO *io; //-- == IoIFP( sv_2io(ioref) )

public:
  mootPerlInputFH(SV *sv=NULL);
  virtual ~mootPerlInputFH(void);

  virtual bool valid(void);
  virtual bool eof(void);

  //-- get a single byte
  virtual int getbyte(void);

  //-- guts ganked from LibXML.xs LibXML_read_perl(SV * ioref, char * buffer, int len)
  virtual mootio::ByteCount read(char *buf, size_t n);
};

/*======================================================================
 * mootPerlInputBuf: mootio stream wrapper for perl buffer input
 */
class mootPerlInputBuf : virtual public mootio::micbuffer
{
public:
  SV  *sv; //-- underlying SV*

public:
  mootPerlInputBuf(SV *svbuf=NULL);
  virtual ~mootPerlInputBuf(void);
};


/*======================================================================
 * mootPerlOutputFH: mootio stream wrapper for perl stream output
 */
class mootPerlOutputFH : virtual public mootio::mostream
{
public:
  SV  *ioref; //-- underlying SV*
  PerlIO *io; //-- == IoIFP( sv_2io(ioref) )

public:
  mootPerlOutputFH(SV *sv=NULL);
  virtual ~mootPerlOutputFH(void);

  virtual bool valid(void);
  virtual bool eof(void);

  virtual bool flush(void);
  virtual bool close(void);

  virtual bool write(const char *buf, size_t n);
  virtual bool putbyte(unsigned char c);
  virtual bool puts(const char *s);
  virtual bool puts(const std::string &s);
  virtual bool vprintf(const char *fmt, va_list &ap);
};
