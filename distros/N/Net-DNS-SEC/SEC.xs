
#define XS_Id "$Id: SEC.xs 1664 2018-04-05 10:03:14Z willem $"


#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <openssl/opensslv.h>

#if (OPENSSL_VERSION_NUMBER < 0x00908000L)
#error	Incompatible OpenSSL version
#endif

#include <openssl/bn.h>
#include <openssl/evp.h>
#include <openssl/objects.h>
#include <openssl/opensslconf.h>

#ifdef OPENSSL_NO_EC
#define NO_ECDSA
#define NO_EdDSA
#endif

#ifndef NO_ECDSA
#include <openssl/ec.h>
#include <openssl/ecdsa.h>
#endif

#include <openssl/dsa.h>
#include <openssl/rsa.h>

#ifdef __cplusplus
}
#endif


#ifdef LIBRESSL_VERSION_NUMBER
#undef  OPENSSL_VERSION_NUMBER
#define OPENSSL_VERSION_NUMBER 0x10001080L
#define LIB_VERSION LIBRESSL_VERSION_NUMBER
#endif

#ifndef LIB_VERSION
#define LIB_VERSION OPENSSL_VERSION_NUMBER
#endif


#if (OPENSSL_VERSION_NUMBER < 0x10101003L)
#define NO_EdDSA
#endif


#if (OPENSSL_VERSION_NUMBER < 0x10100000L)

int DSA_set0_pqg(DSA *d, BIGNUM *p, BIGNUM *q, BIGNUM *g)
{
	/* If the fields p, q and g in d are NULL, the corresponding input
	* parameters MUST be non-NULL.
	*/
	if ((d->p == NULL && p == NULL)
		|| (d->q == NULL && q == NULL)
		|| (d->g == NULL && g == NULL))
		return 0;

	if (p != NULL) {
		BN_free(d->p);
		d->p = p;
	}
	if (q != NULL) {
		BN_free(d->q);
		d->q = q;
	}
	if (g != NULL) {
		BN_free(d->g);
		d->g = g;
	}
	return 1;
}

int DSA_set0_key(DSA *d, BIGNUM *pub_key, BIGNUM *priv_key)
{
	/* If the field pub_key in d is NULL, the corresponding input
	* parameters MUST be non-NULL.  The priv_key field may
	* be left NULL.
	*/
	if (d->pub_key == NULL && pub_key == NULL) return 0;

	if (pub_key != NULL) {
		d->pub_key = pub_key;
	}
	if (priv_key != NULL) {
		d->priv_key = priv_key;
	}
	return 1;
}

void DSA_SIG_get0(const DSA_SIG *sig, const BIGNUM **pr, const BIGNUM **ps)
{
	if (pr != NULL) *pr = sig->r;
	if (ps != NULL) *ps = sig->s;
}

int DSA_SIG_set0(DSA_SIG *sig, BIGNUM *r, BIGNUM *s)
{
	if (sig->r != NULL) BN_free(sig->r);
	sig->r = r;
	if (sig->s != NULL) BN_free(sig->s);
	sig->s = s;
	return 1;
}

int RSA_set0_key(RSA *r, BIGNUM *n, BIGNUM *e, BIGNUM *d)
{
	BN_free(r->n);
	r->n = n;
	BN_free(r->e);
	r->e = e;
	BN_free(r->d);
	r->d = d;
	return 1;
}

int RSA_set0_factors(RSA *r, BIGNUM *p, BIGNUM *q)
{
	BN_free(r->p);
	r->p = p;
	BN_free(r->q);
	r->q = q;
	return 1;
}


#ifndef NO_ECDSA

void ECDSA_SIG_get0(const ECDSA_SIG *sig, const BIGNUM **pr, const BIGNUM **ps)
{
	if (pr != NULL) *pr = sig->r;
	if (ps != NULL) *ps = sig->s;
}

int ECDSA_SIG_set0(ECDSA_SIG *sig, BIGNUM *r, BIGNUM *s)
{
	if (sig->r != NULL) BN_free(sig->r);
	sig->r = r;
	if (sig->s != NULL) BN_free(sig->s);
	sig->s = s;
	return 1;
}


#if (OPENSSL_VERSION_NUMBER < 0x10001000L)

int EC_KEY_set_public_key_affine_coordinates(EC_KEY *eckey, BIGNUM *x, BIGNUM *y)
{
	const EC_GROUP *group;
	EC_POINT *key = NULL;
	BIGNUM *tx, *ty;
	BN_CTX *ctx = NULL;
	int retval = 0;

	if (!(group = EC_KEY_get0_group(eckey))) goto cleanup;
	if (!(key = EC_POINT_new(group))) goto cleanup;
	if (!(ctx = BN_CTX_new())) goto cleanup;
	tx = BN_CTX_get(ctx);
	ty = BN_CTX_get(ctx);
	if (!EC_POINT_set_affine_coordinates_GFp(group, key, x, y, ctx)) goto cleanup;
	if (!EC_POINT_get_affine_coordinates_GFp(group, key, tx, ty, ctx)) goto cleanup;
	if (BN_cmp(x, tx) || BN_cmp(y, ty)) goto cleanup;
	if (!EC_KEY_set_public_key(eckey, key)) goto cleanup;
	retval = EC_KEY_check_key(eckey);

	cleanup:
	if (key) EC_POINT_free(key);
	if (ctx) BN_CTX_free(ctx);
	return retval;
}

#endif
#endif
#endif


int checkerr(const int ret)
{
	if ( ret != 1 ) croak("libcrypto method failed");
	return ret;
}


MODULE = Net::DNS::SEC	PACKAGE = Net::DNS::SEC::libcrypto

PROTOTYPES: DISABLE

SV*
VERSION(void)
    PREINIT:
	SV *v_SV = newSVpv( XS_Id, 16 );
	char *v;
    CODE:
	v = (char*) SvEND(v_SV);
	v = v - 4;
	RETVAL = newSVpvf( "%s %8.8lx", v, LIB_VERSION );
    OUTPUT:
	RETVAL


####	DSA	####

DSA*
DSA_new()

void
DSA_free(DSA *dsa)

int
DSA_set0_pqg(DSA *d, SV *p_SV, SV *q_SV, SV *g_SV)
    PREINIT:
	BIGNUM *p;
	BIGNUM *q;
	BIGNUM *g;
	unsigned char *bin;
	STRLEN len;
    CODE:
	bin = (unsigned char*) SvPV( p_SV, len );
	p = BN_bin2bn( bin, len, NULL );
	bin = (unsigned char*) SvPV( q_SV, len );
	q = BN_bin2bn( bin, len, NULL );
	bin = (unsigned char*) SvPV( g_SV, len );
	g = BN_bin2bn( bin, len, NULL );
	RETVAL = DSA_set0_pqg( d, p, q, g );
	checkerr(RETVAL);
    OUTPUT:
	RETVAL

int
DSA_set0_key(DSA *dsa, SV *y_SV, SV *x_SV)
    PREINIT:
	BIGNUM *x = NULL;
	BIGNUM *y = NULL;
	unsigned char *bin;
	STRLEN len;
    CODE:
	if (x_SV) {
		bin = (unsigned char*) SvPV( x_SV, len );
		x = BN_bin2bn( bin, len, NULL );
	}
	if (y_SV) {
		bin = (unsigned char*) SvPV( y_SV, len );
		y = BN_bin2bn( bin, len, NULL );
	}
	RETVAL = DSA_set0_key( dsa, y, x );
	checkerr(RETVAL);
    OUTPUT:
	RETVAL

DSA_SIG*
DSA_SIG_new()

void
DSA_SIG_free(DSA_SIG *sig)

void
DSA_SIG_get0(DSA_SIG *sig)
    PREINIT:
	const BIGNUM *r = NULL;
	const BIGNUM *s = NULL;
	unsigned char bin[32];
	int len = 0;
    PPCODE:
	DSA_SIG_get0( sig, &r, &s );
	if (r) len = BN_bn2bin( r, bin );
	XPUSHs(sv_2mortal(newSVpvn( (char*)bin, len )));
	if (s) len = BN_bn2bin( s, bin );
	XPUSHs(sv_2mortal(newSVpvn( (char*)bin, len )));

int
DSA_SIG_set0(DSA_SIG *sig, SV *r_SV, SV *s_SV)
    PREINIT:
	BIGNUM *r;
	BIGNUM *s;
	unsigned char *bin;
	STRLEN len;
    CODE:
	bin = (unsigned char*) SvPV( r_SV, len );
	r = BN_bin2bn( bin, len, NULL );
	bin = (unsigned char*) SvPV( s_SV, len );
	s = BN_bin2bn( bin, len, NULL );
	RETVAL = DSA_SIG_set0( sig, r, s );
	checkerr(RETVAL);
    OUTPUT:
	RETVAL

DSA_SIG*
DSA_do_sign(SV *dgst, DSA *dsa)
    PREINIT:
        DSA_SIG *sig;
	const unsigned char *bin;
	STRLEN len = 0;
    CODE:
	bin = (unsigned char*) SvPV( dgst, len );
	sig = DSA_do_sign( bin, len, dsa );
	RETVAL = sig;
    OUTPUT:
	RETVAL

int
DSA_do_verify(SV *dgst, DSA_SIG *sig, DSA *dsa)
    PREINIT:
	const unsigned char *bin = NULL;
	STRLEN len = 0;
    CODE:
	bin = (unsigned char*) SvPV( dgst, len );
	RETVAL = DSA_do_verify( bin, len, sig, dsa );
    OUTPUT:
	RETVAL


####	ECDSA	####

#ifndef NO_ECDSA

# Creates new EC_KEY object using prescribed curve
# as underlying EC_GROUP object.
EC_KEY*
EC_KEY_new_by_curve_name(int nid)

EC_KEY*
EC_KEY_new()

EC_KEY*
EC_KEY_dup(EC_KEY *src)

void
EC_KEY_free(EC_KEY *key)

int
EC_KEY_set_private_key(EC_KEY *key, SV *prv_SV)
    PREINIT:
	BIGNUM *prv;
	unsigned char *bin;
	STRLEN len;
    CODE:
	bin = (unsigned char*) SvPV( prv_SV, len );
	prv = BN_bin2bn( bin, len, NULL );
	RETVAL = EC_KEY_set_private_key( key, prv );
	BN_clear_free(prv);
	checkerr(RETVAL);
    OUTPUT:
	RETVAL

int
EC_KEY_set_public_key_affine_coordinates(EC_KEY *key, SV *x_SV, SV *y_SV)
    PREINIT:
	BIGNUM *x;
	BIGNUM *y;
	unsigned char *bin;
	STRLEN len;
    CODE:
	bin = (unsigned char*) SvPV( x_SV, len );
	x = BN_bin2bn( bin, len, NULL );
	bin = (unsigned char*) SvPV( y_SV, len );
	y = BN_bin2bn( bin, len, NULL );
	RETVAL = EC_KEY_set_public_key_affine_coordinates( key, x, y );
	BN_free(x);
	BN_free(y);
	checkerr(RETVAL);
    OUTPUT:
	RETVAL

ECDSA_SIG*
ECDSA_SIG_new()

void
ECDSA_SIG_free(ECDSA_SIG *sig)

void
ECDSA_SIG_get0(ECDSA_SIG *sig)
    PREINIT:
	const BIGNUM *r = NULL;
	const BIGNUM *s = NULL;
	unsigned char bin[128];
	int len = 0;
    PPCODE:
	ECDSA_SIG_get0( sig, &r, &s );
	if (r) len = BN_bn2bin( r, bin );
	XPUSHs(sv_2mortal(newSVpvn( (char*)bin, len )));
	if (s) len = BN_bn2bin( s, bin );
	XPUSHs(sv_2mortal(newSVpvn( (char*)bin, len )));

int
ECDSA_SIG_set0(ECDSA_SIG *sig, SV *r_SV, SV *s_SV)
    PREINIT:
	BIGNUM *r;
	BIGNUM *s;
	unsigned char *bin;
	STRLEN len;
    CODE:
	bin = (unsigned char*) SvPV( r_SV, len );
	r = BN_bin2bn( bin, len, NULL );
	bin = (unsigned char*) SvPV( s_SV, len );
	s = BN_bin2bn( bin, len, NULL );
	RETVAL = ECDSA_SIG_set0( sig, r, s );
	checkerr(RETVAL);
    OUTPUT:
	RETVAL

ECDSA_SIG*
ECDSA_sign(SV *dgst, EC_KEY *key)
    PREINIT:
	ECDSA_SIG *sig;
	const unsigned char *bin;
	STRLEN len;
    CODE:
	bin = (unsigned char*) SvPV( dgst, len );
	sig = ECDSA_do_sign( bin, (int)len, key );
	RETVAL = sig;
    OUTPUT:
	RETVAL

int
ECDSA_verify(SV *dgst, ECDSA_SIG *sig, EC_KEY *key)
    PREINIT:
	const unsigned char *bin;
	STRLEN  len;
    CODE:
	bin = (unsigned char*) SvPV( dgst, len );
	RETVAL = ECDSA_do_verify( bin, (int)len, sig, key );
    OUTPUT:
	RETVAL

#endif


####	EdDSA	####

#ifndef NO_EdDSA

SV*
EdDSA_sign(int nid, SV *message, SV *private_key)
    PREINIT:
	const unsigned char *m;
	STRLEN  mlen;
	const unsigned char *k;
	STRLEN  klen;
	EVP_PKEY *evpkey;
	EVP_MD_CTX *ctx;
	unsigned char sigbuf[128];
	STRLEN slen = sizeof(sigbuf);
	int r;
    CODE:
	m = (unsigned char*) SvPV( message, mlen );
	k = (unsigned char*) SvPV( private_key, klen );
	evpkey = EVP_PKEY_new_raw_private_key( nid, NULL, k, klen );

	ctx = EVP_MD_CTX_new();
	checkerr( EVP_MD_CTX_init(ctx) );
	checkerr( EVP_DigestSignInit( ctx, NULL, NULL, NULL, evpkey ) );

	r = EVP_DigestSign( ctx, sigbuf, &slen, m, mlen );
	RETVAL = newSVpvn( (char*)sigbuf, slen );
	EVP_PKEY_free(evpkey);
	EVP_MD_CTX_free(ctx);
	checkerr(r);
    OUTPUT:
	RETVAL

int
EdDSA_verify(int nid, SV *message, SV *signature, SV *public_key)
    PREINIT:
	const unsigned char *m;
	STRLEN  mlen;
	const unsigned char *s;
	STRLEN  slen;
	const unsigned char *k;
	STRLEN  klen;
	EVP_PKEY *evpkey;
	EVP_MD_CTX *ctx;
    CODE:
	m = (unsigned char*) SvPV( message, mlen );
	s = (unsigned char*) SvPV( signature, slen );
	k = (unsigned char*) SvPV( public_key, klen );
	evpkey = EVP_PKEY_new_raw_public_key( nid, NULL, k, klen );

	ctx = EVP_MD_CTX_new();
	checkerr( EVP_MD_CTX_init(ctx) );
	checkerr( EVP_DigestVerifyInit( ctx, NULL, NULL, NULL, evpkey ) );

	RETVAL = EVP_DigestVerify( ctx, s, slen, m, mlen );
	EVP_PKEY_free(evpkey);
	EVP_MD_CTX_free(ctx);
    OUTPUT:
	RETVAL

#endif


####	RSA	####

RSA*
RSA_new()

void
RSA_free(RSA *r)

int
RSA_set0_factors(RSA *r, SV *p_SV, SV *q_SV)
    PREINIT:
	BIGNUM *p;
	BIGNUM *q;
	unsigned char *bin;
	STRLEN len;
    CODE:
	bin = (unsigned char*) SvPV( p_SV, len );
	p = BN_bin2bn( bin, len, NULL );
	bin = (unsigned char*) SvPV( q_SV, len );
	q = BN_bin2bn( bin, len, NULL );
	RETVAL = RSA_set0_factors( r, p, q );
	checkerr(RETVAL);
    OUTPUT:
	RETVAL

int
RSA_set0_key(RSA *r, SV *n_SV, SV *e_SV, SV *d_SV)
    PREINIT:
	BIGNUM *d;
	BIGNUM *e;
	BIGNUM *n;
	unsigned char *bin;
	STRLEN len;
    CODE:
	bin = (unsigned char*) SvPV( d_SV, len );
	d = BN_bin2bn( bin, len, NULL );
	bin = (unsigned char*) SvPV( e_SV, len );
	e = BN_bin2bn( bin, len, NULL );
	bin = (unsigned char*) SvPV( n_SV, len );
	n = BN_bin2bn( bin, len, NULL );
	RETVAL = RSA_set0_key( r, n, e, d );
	checkerr(RETVAL);
    OUTPUT:
	RETVAL

SV*
RSA_sign(int type, SV *msg, RSA *rsa)
    PREINIT:
	unsigned char *m;
	STRLEN	mlen;
	unsigned char s[256];
	unsigned int slen;
    CODE:
	m = (unsigned char*) SvPV( msg, mlen );
	RSA_sign( type, m, mlen, s, &slen, rsa );
	RETVAL = newSVpvn( (char*)s, slen );
    OUTPUT:
	RETVAL

int
RSA_verify(int type, SV *msg, SV *sig, RSA *rsa)
    PREINIT:
	unsigned char *m;
	STRLEN	mlen;
	unsigned char *s;
	STRLEN	slen;
    CODE:
	m = (unsigned char*) SvPV( msg, mlen );
	s = (unsigned char*) SvPV( sig, slen );
	RETVAL = RSA_verify( type, m, mlen, s, slen, rsa );
    OUTPUT:
	RETVAL

####################

