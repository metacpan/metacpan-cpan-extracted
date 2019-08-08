#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <pwd.h>
#include <unistd.h>

#include "ppport.h"


MODULE = OpenBSD::Checkpass		PACKAGE = OpenBSD::Checkpass		

int
_checkpass(const char *password, const char *hash)
	CODE:
		RETVAL = crypt_checkpass(password, hash);
	OUTPUT:
		RETVAL

SV *
_newhash(const char *password)
	INIT:
		int rv;
		char buf[_PASSWORD_LEN];
	PPCODE:
		rv = crypt_newhash(password, "bcrypt,a", buf, sizeof(buf));
		if (rv == 0) {
			XPUSHs(sv_2mortal(newSVpv(buf, 0)));
		} else {
			XPUSHs(sv_newmortal());
		} 
