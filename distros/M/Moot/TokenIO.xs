#/*-*- Mode: C++ -*- */

MODULE = Moot		PACKAGE = Moot::TokenIO

##=====================================================================
## TokenIO: Static Methods
##=====================================================================

##-- disable perl prototypes
PROTOTYPES: DISABLE

##=====================================================================
## Format String <-> Bitmask Utilities

##------------------------------------------------------
TokenIOFormatMask
parse_format_string(const char *fmtString)
CODE:
  RETVAL = TokenIO::parse_format_string(fmtString);
OUTPUT:
  RETVAL

##------------------------------------------------------
TokenIOFormatMask
guess_filename_format(const char *filename)
CODE:
  RETVAL = TokenIO::guess_filename_format(filename);
OUTPUT:
  RETVAL

##------------------------------------------------------
bool
is_empty_format(TokenIOFormatMask fmt)
CODE:
  RETVAL = TokenIO::is_empty_format(fmt);
OUTPUT:
  RETVAL

##------------------------------------------------------
TokenIOFormatMask
sanitize_format(TokenIOFormatMask fmt, TokenIOFormatMask fmt_implied=0, TokenIOFormatMask fmt_default=0)
CODE:
  RETVAL = TokenIO::sanitize_format(fmt,fmt_implied,fmt_default);
OUTPUT:
  RETVAL

##------------------------------------------------------
TokenIOFormatMask
parse_format_request(const char *request, const char *filename="", TokenIOFormatMask fmt_implied=0, TokenIOFormatMask fmt_default=0)
CODE:
  RETVAL = TokenIO::parse_format_request(request,filename,fmt_implied,fmt_default);
OUTPUT:
  RETVAL

##------------------------------------------------------
const char *
format_canonical_string(TokenIOFormatMask fmt)
PREINIT:
  std::string tmp;
CODE:
  tmp    = TokenIO::format_canonical_string(fmt);
  RETVAL = tmp.c_str();
OUTPUT:
  RETVAL

##=====================================================================
## Format-Based Reader/Writer Creation

##------------------------------------------------------
TokenReader *
new_reader(TokenIOFormatMask fmt)
PREINIT:
  const char *CLASS;
CODE:
  RETVAL = TokenIO::new_reader(fmt);
  CLASS  = TokenReaderClass(RETVAL);
  RETVAL->tr_name = CLASS;
OUTPUT:
  RETVAL

##------------------------------------------------------
TokenWriter *
new_writer(TokenIOFormatMask fmt)
PREINIT:
  const char *CLASS;
CODE:
  RETVAL = TokenIO::new_writer(fmt);
  CLASS  = TokenWriterClass(RETVAL);
  RETVAL->tw_name = CLASS;
OUTPUT:
  RETVAL

##------------------------------------------------------
TokenReader *
file_reader(const char *filename, const char *fmt_request="", TokenIOFormatMask fmt_implied=tiofNone, TokenIOFormatMask fmt_default=tiofNone)
PREINIT:
  const char *CLASS;
CODE:
  RETVAL = TokenIO::file_reader(filename, fmt_request, fmt_implied, fmt_default);
  CLASS  = TokenReaderClass(RETVAL);
  RETVAL->tr_name = CLASS;
OUTPUT:
  RETVAL

##------------------------------------------------------
TokenWriter *
file_writer(const char *filename, const char *fmt_request=NULL, TokenIOFormatMask fmt_implied=tiofNone, TokenIOFormatMask fmt_default=tiofNone)
PREINIT:
  const char *CLASS;
CODE:
  RETVAL = TokenIO::file_writer(filename, fmt_request, fmt_implied, fmt_default);
  CLASS  = TokenWriterClass(RETVAL);
  RETVAL->tw_name = CLASS;
OUTPUT:
  RETVAL
