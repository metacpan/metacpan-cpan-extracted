#include "src/blowfish/blowfish.c"
#include "src/ed25519/keypair.c"
#include "src/ed25519/sign.c"
#include "src/ed25519/verify.c"
#include "src/ed25519/sha512.c"
#define select(a,b,c) ed25519_select (a, b, c)
#include "src/ed25519/ge.c"
#include "src/ed25519/fe.c"
#define load_3(x) sc_load_3(x)
#define load_4(x) sc_load_4(x)
#include "src/ed25519/sc.c"

MODULE = Net::SSH::Perl                         PACKAGE = Net::SSH::Perl::Key::Ed25519

PROTOTYPES: ENABLE

blf_ctx *
bf_init()
CODE:
	{
		Newxz(RETVAL, 1, blf_ctx);
		Blowfish_initstate(RETVAL);
	}
OUTPUT:
	RETVAL

void
bf_expandstate(ctx, sv_data, sv_key)
	blf_ctx *ctx
	SV *sv_data
	SV *sv_key
CODE:
	{
		STRLEN datalen; unsigned char *data = (unsigned char *) SvPVbyte(sv_data,datalen);
		STRLEN keylen; unsigned char *key = (unsigned char *) SvPVbyte(sv_key,keylen);
		Blowfish_expandstate(ctx, data, datalen, key, keylen);
	}

void
bf_expand0state(ctx,sv_key)
	blf_ctx *ctx
	SV *sv_key
CODE:
	{
		STRLEN keylen;
		unsigned char *key = (unsigned char *) SvPVbyte(sv_key,keylen);
		Blowfish_expand0state(ctx,key,keylen);
	}

SV *
bf_encrypt_iterate(ctx, sv_data, sv_rounds)
	blf_ctx *ctx
	SV *sv_data
	SV *sv_rounds
CODE:
	{
		STRLEN datalen;
		unsigned char *data = (unsigned char *) SvPVbyte(sv_mortalcopy(sv_data),datalen);
		if (datalen % 8)
			croak("data must be in 8-byte chunks");
		
		uint16_t words = datalen / 4;
		uint32_t cdata[words];
		uint16_t j = 0;
		int i;
		int rounds = SvIVx(sv_rounds);

		for (i=0; i<words; i++)
			cdata[i] = Blowfish_stream2word(data, datalen, &j);
		for (i=0; i<rounds; i++)
			blf_enc(ctx, cdata, sizeof(cdata) / sizeof(uint64_t));

		for (i=0; i<words; i++) {
			data[4 * i + 3] = (cdata[i] >> 24) & 0xff;
			data[4 * i + 2] = (cdata[i] >> 16) & 0xff;
			data[4 * i + 1] = (cdata[i] >>  8) & 0xff;
			data[4 * i ] = cdata[i] & 0xff;
		}
		RETVAL = newSVpvn ((char *) data, datalen);
	}
OUTPUT:
	RETVAL

void
ed25519_generate_keypair (secret)
	SV *secret
PPCODE:
	{
		STRLEN secret_l; unsigned char *secret_p;

		unsigned char public_key[32];
		unsigned char private_key[64];

		secret_p = (unsigned char *)SvPVbyte (secret, secret_l);

		if (secret_l != 32)
			croak ("secret has wrong length (!= 32)");

		ed25519_create_keypair (public_key, private_key, (unsigned char *)secret_p);

		EXTEND (SP, 2);
		PUSHs (sv_2mortal (newSVpvn ((char *)public_key, sizeof public_key)));
		PUSHs (sv_2mortal (newSVpvn ((char *)private_key, sizeof private_key)));
     }

SV *
ed25519_sign_message (message, private_key)
	SV *message;
	SV *private_key;
CODE:
	{
		unsigned char signature[64];

		STRLEN message_l    ; char *message_p     = SvPVbyte (message    , message_l    );
		STRLEN private_key_l; char *private_key_p = SvPVbyte (private_key, private_key_l);

		if (private_key_l != 64)
			croak ("private key has wrong length (!= 64)");

		ed25519_sign (signature, (unsigned char *)message_p, message_l, (unsigned char *)private_key_p);

		RETVAL = newSVpvn ((char *)signature, sizeof signature);
	}
OUTPUT:
	RETVAL

bool
ed25519_verify_message (SV *message, SV *public_key, SV *signature)
CODE:
	{
		STRLEN signature_l ; char *signature_p  = SvPVbyte (signature , signature_l );
		STRLEN message_l   ; char *message_p    = SvPVbyte (message   , message_l   );
		STRLEN public_key_l; char *public_key_p = SvPVbyte (public_key, public_key_l);

		if (public_key_l != 32)
			croak ("public key has wrong length (!= 32)");

		RETVAL = ed25519_verify ((unsigned char *)signature_p, (unsigned char *)message_p, message_l, (unsigned char *)public_key_p);
	}
OUTPUT:
	RETVAL
