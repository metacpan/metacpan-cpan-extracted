#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "sha.h"
#include "sha512.h"

typedef struct digeststate {
  union {
    SHA_INFO sha_info;
    SHA_INFO512 sha_info512;
  } u;
  int digestsize;
} *Digest__SHA256;

MODULE = Digest::SHA256 PACKAGE = Digest::SHA256

PROTOTYPES: ENABLE

Digest::SHA256
new(digestsize=256)
     int digestsize;
    CODE:
      switch (digestsize) {
      case 256:
      case 384:
      case 512:
	break;
      default:
	croak("wrong digest size: digest must be either 256, 384, or 512 bits long");
	break;
      }
      Newz(0, RETVAL, 1, struct digeststate);
      RETVAL->digestsize = digestsize;
      switch (RETVAL->digestsize) {
      case 256:
	sha_init(&RETVAL->u.sha_info);
	break;
      case 384:
	sha_init384(&RETVAL->u.sha_info512);
	break;
      default:
	sha_init512(&RETVAL->u.sha_info512);
	break;
      }
    OUTPUT:
	RETVAL

void
DESTROY(context)
	Digest::SHA256	context
    CODE:
	{
	    safefree((char *) context);
	}

void
reset(context)
	Digest::SHA256	context
    CODE:
	{
	  switch (context->digestsize) {
	  case 256:
	    sha_init(&context->u.sha_info);
	    break;
	  case 384:
	    sha_init384(&context->u.sha_info512);
	    break;
	  default:
	    sha_init512(&context->u.sha_info512);
	    break;
	  }
	}

void
add(context, ...)
	Digest::SHA256	context
    CODE:
	{
	  SV *svdata;
	  STRLEN len;
	  unsigned char *data;
	  int i;

	  for (i = 1; i < items; i++) {
	    data = (unsigned char *) (SvPV(ST(i), len));
	    switch (context->digestsize) {
	    case 256:  
	      sha_update(&context->u.sha_info, data, len);
	      break;
	    default:
	      sha_update512(&context->u.sha_info512, data, len);
	      break;
	    }
	  }
	}


SV *
digest(context)
	Digest::SHA256	context
    CODE:
	{
	  Uint8 d_str[64];

	  switch (context->digestsize) {
	  case 256:
	    sha_final(&context->u.sha_info);
	    sha_unpackdigest(d_str, &context->u.sha_info);
	    break;
	  case 384:
	    sha_final512(&context->u.sha_info512);
	    sha_unpackdigest384(d_str, &context->u.sha_info512);
	    break;
	  default:
	    sha_final512(&context->u.sha_info512);
	    sha_unpackdigest512(d_str, &context->u.sha_info512);
	    break;
	  }

	  ST(0) = sv_2mortal(newSVpv(d_str, 64));
	}

int
length(self)
     Digest::SHA256 self
     CODE:
       RETVAL = self->digestsize;
     OUTPUT:
       RETVAL
