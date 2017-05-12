#include "src/chacha/chacha.c"
#include "src/chacha/poly1305.c"

MODULE = Crypt::OpenSSH::ChachaPoly		PACKAGE = Crypt::OpenSSH::ChachaPoly		

PROTOTYPES: ENABLE

Crypt::OpenSSH::ChachaPoly
new(class,key)
	SV *class
	SV *key
CODE:
	{
		STRLEN keysize;
		keysize = SvCUR(key);

		if (keysize != 16 && keysize != 32)
			croak ("The key must be 128 or 256 bits long");

		Newxz(RETVAL, 1, struct chacha_ctx);
		chacha_keysetup(RETVAL, (unsigned char *) SvPV_nolen(key), keysize*8);
	}
OUTPUT:
	RETVAL

SV *
encrypt(self,data)
	Crypt::OpenSSH::ChachaPoly self
	SV *data
ALIAS:
	decrypt = 1
CODE:
	{
		STRLEN size;
		void *bytes = SvPV(data,size);

		if (size) {
			RETVAL = NEWSV (0, size);
			SvPOK_only (RETVAL);
			SvCUR_set (RETVAL, size);
			chacha_encrypt_bytes(self, bytes, (unsigned char *) SvPV_nolen(RETVAL), (int) size);
		} else {
			RETVAL = newSVpv ("", 0);
		}

	}
OUTPUT:
	RETVAL

void
ivsetup(self,iv,counter)
	Crypt::OpenSSH::ChachaPoly self
	SV *iv
	SV *counter
CODE:
	{
		STRLEN iv_l ; unsigned char *iv_p = (unsigned char *) SvPVbyte (iv, iv_l);
		/* anything beyond 64 bits is ignored */
		if (iv_l < 8) {
			croak("ivsetup: iv must be 64 bits long!");
		}
		STRLEN counter_l ; unsigned char *counter_p = (unsigned char *) SvPVbyte (counter, counter_l);
		if (counter_l == 0)
			counter_p = NULL;
		/* anything beyond 8 chars is ignored */
		else if (counter_l < 8)
			croak ("ivsetup: counter must be 64 bits long!");
		chacha_ivsetup(self, iv_p, counter_p);
	}

void
DESTROY(self)
        Crypt::OpenSSH::ChachaPoly self
CODE:
        Safefree(self);

SV *
poly1305(self,data,key)
	Crypt::OpenSSH::ChachaPoly self
	SV *data
	SV *key
CODE:
	{
		STRLEN size;
		void *databytes = SvPV(data,size);

		STRLEN keysize;
		keysize = SvCUR(key);
		if (keysize != POLY1305_KEYLEN)
			croak("Key is incorrect size");
		void *keybytes = SvPV_nolen(key);

		RETVAL = NEWSV(0, POLY1305_TAGLEN);
		SvPOK_only (RETVAL);
		SvCUR_set (RETVAL, POLY1305_TAGLEN);
		poly1305_auth((unsigned char *) SvPV_nolen(RETVAL),databytes,(int) size,keybytes);
	}
OUTPUT:
	RETVAL
