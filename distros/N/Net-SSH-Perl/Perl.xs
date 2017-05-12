#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

typedef struct chacha_ctx *Crypt__OpenSSH__ChachaPoly;

/* work around unportable mess in fixedint.h */
/* taken from libecb */
#ifdef _WIN32
  typedef   signed char   int8_t;
  typedef unsigned char  uint8_t;
  typedef   signed short  int16_t;
  typedef unsigned short uint16_t;
  typedef   signed int    int32_t;
  typedef unsigned int   uint32_t;
  #if __GNUC__
    typedef   signed long long int64_t;
    typedef unsigned long long uint64_t;
  #else /* _MSC_VER || __BORLANDC__ */
    typedef   signed __int64   int64_t;
    typedef unsigned __int64   uint64_t;
  #endif
  #define UINT64_C(v) v
#else
  #include <inttypes.h>
#endif
#define FIXEDINT_H_INCLUDED

MODULE = Net::SSH::Perl  PACKAGE = Net::SSH::Perl

INCLUDE: lib/Net/SSH/Perl/Key/Ed25519.xs
INCLUDE: lib/Net/SSH/Perl/Cipher/ChachaPoly.xs
