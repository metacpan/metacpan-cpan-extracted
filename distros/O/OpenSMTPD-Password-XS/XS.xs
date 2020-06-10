#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <pwd.h>
#include <unistd.h>

#include "ppport.h"


MODULE = OpenSMTPD::Password::XS		PACKAGE = OpenSMTPD::Password::XS		

int
checkhash(const char *password, const char *goodhash)
	INIT:
		int rv;
	CODE:
		rv = crypt_checkpass(password, goodhash);

		RETVAL = (rv == 0) ? 1 : 0;

	OUTPUT:
		RETVAL

SV *
newhash(const char *password)
	INIT:
		int rv;
		char buf [_PASSWORD_LEN];

	PPCODE:
		rv = crypt_newhash(password, "bcrypt,a", buf, sizeof(buf));
		if (rv == 0)
			XPUSHs(sv_2mortal(newSVpv(buf, 0)));
		else
			XPUSHs(sv_newmortal());	
