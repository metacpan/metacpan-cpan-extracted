
#define XS_Id "$Id: SEC.xs 1853 2021-10-11 10:40:59Z willem $"


=head1 NAME

Net::DNS::SEC::libcrypto - Perl interface to OpenSSL libcrypto

=head1 DESCRIPTION

Perl XS extension providing access to the OpenSSL libcrypto library
upon which the Net::DNS::SEC cryptographic components are built.

=head1 COPYRIGHT

Copyright (c)2018-2021 Dick Franks

All Rights Reserved

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the original copyright notices appear in all copies and that both
copyright notice and this permission notice appear in supporting
documentation, and that the name of the author not be used in advertising
or publicity pertaining to distribution of the software without specific
prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut


#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT
#define PERL_REENTRANT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <openssl/opensslv.h>
#include <openssl/bn.h>
#include <openssl/err.h>

#ifndef OPENSSL_VERSION_NUMBER		/* 0xMNN00PP0L	retain backward compatibility */
#define OPENSSL_VERSION_NUMBER	\
	( (OPENSSL_VERSION_MAJOR<<28) | (OPENSSL_VERSION_MINOR<<20) | (OPENSSL_VERSION_PATCH<<4) | 0x0L )
#endif

#if (OPENSSL_VERSION_NUMBER < 0x40000000)
#define OBSOLETE_API
#undef  OSSL_DEPRECATED
#define OSSL_DEPRECATED(since)	extern
#include <openssl/evp.h>
#include <openssl/dsa.h>
#include <openssl/ec.h>
#include <openssl/ecdsa.h>
#include <openssl/rsa.h>
#else
#include <openssl/evp.h>
#include <openssl/core_names.h>
#include <openssl/param_build.h>
static OSSL_LIB_CTX *libctx = NULL;
#endif

#ifdef __cplusplus
}
#endif


#ifdef OPENSSL_NO_DSA
#define NO_DSA
#endif

#ifdef OPENSSL_NO_RSA
#define NO_RSA
#endif

#ifdef OPENSSL_NO_EC
#define NO_ECDSA
#define NO_EdDSA
#endif

#ifdef OPENSSL_IS_BORINGSSL
#define NO_SHA3
#endif

#ifdef LIBRESSL_VERSION_NUMBER
#undef OPENSSL_VERSION_NUMBER
#define OPENSSL_VERSION_NUMBER 0x10100000L
#endif


#if (OPENSSL_VERSION_NUMBER < 0x10001000)
#error	unsupported libcrypto version
#include OPENSSL_VERSION_TEXT /* in error log; by any means, however reprehensible! */
#endif


#if (OPENSSL_VERSION_NUMBER < 0x10100000)

#define EVP_MD_CTX_new()	EVP_MD_CTX_create()
#define EVP_MD_CTX_free(ctx)	EVP_MD_CTX_destroy((ctx))

int DSA_set0_pqg(DSA *d, BIGNUM *p, BIGNUM *q, BIGNUM *g)
{
	d->p = p;
	d->q = q;
	d->g = g;
	return 1;
}

int DSA_set0_key(DSA *d, BIGNUM *pub_key, BIGNUM *priv_key)
{
	d->priv_key = priv_key;
	d->pub_key  = pub_key;
	return 1;
}

int RSA_set0_key(RSA *r, BIGNUM *n, BIGNUM *e, BIGNUM *d)
{
	r->n = n;
	r->e = e;
	r->d = d;
	return 1;
}

int RSA_set0_factors(RSA *r, BIGNUM *p, BIGNUM *q)
{
	r->p = p;
	r->q = q;
	return 1;
}
#endif


#if (OPENSSL_VERSION_NUMBER < 0x10101000)
#define NO_EdDSA
#define NO_SHA3

int EVP_DigestSign(EVP_MD_CTX *ctx,
		unsigned char *sig, size_t *sig_len,
		const unsigned char *data, size_t data_len)
{
	EVP_DigestUpdate( ctx, data, data_len );
	return EVP_DigestSignFinal( ctx, sig, sig_len );
}

int EVP_DigestVerify(EVP_MD_CTX *ctx,
		const unsigned char *sig, size_t sig_len,
		const unsigned char *data, size_t data_len)
{
	EVP_DigestUpdate( ctx, data, data_len );
	return EVP_DigestVerifyFinal( ctx, sig, sig_len );
}
#endif


#define checkerr(arg)	checkret( (arg), __LINE__ )
void checkret(const int ret, int line)
{
	if ( ret <= 0 ) croak( "libcrypto error (%s line %d)", __FILE__, line );
}


#ifndef OBSOLETE_API
int EVP_PKEY_fromparams(EVP_PKEY_CTX *ctx, EVP_PKEY **ppkey, int selection, OSSL_PARAM_BLD *bld)
{
	OSSL_PARAM *params = OSSL_PARAM_BLD_to_param(bld);
	int retval;
	checkerr( EVP_PKEY_fromdata_init(ctx) );
	retval = EVP_PKEY_fromdata( ctx, ppkey, selection, params );
	OSSL_PARAM_free(params);
	return retval;
}
#endif


MODULE = Net::DNS::SEC	PACKAGE = Net::DNS::SEC::libcrypto

PROTOTYPES: ENABLE

SV*
VERSION(void)
    PREINIT:
	char *v = SvEND( newSVpv(XS_Id, 17) );
    CODE:
	RETVAL = newSVpvf( "%s	%s", v-5, OPENSSL_VERSION_TEXT );
    OUTPUT:
	RETVAL


####	EVP	####

EVP_PKEY*
EVP_PKEY_new()

SV*
EVP_sign(SV *message, EVP_PKEY *pkey, const EVP_MD *md=NULL)
    INIT:
	EVP_MD_CTX *ctx = EVP_MD_CTX_new();
	unsigned char *m = (unsigned char*) SvPVX(message);
	unsigned char sigbuf[512];		/* RFC3110(2) */
	STRLEN mlen = SvCUR(message);
	STRLEN slen = sizeof(sigbuf);
	int r;
    CODE:
	checkerr( EVP_DigestSignInit( ctx, NULL, md, NULL, pkey ) );
	r = EVP_DigestSign( ctx, sigbuf, &slen, m, mlen );
	EVP_MD_CTX_free(ctx);
	EVP_PKEY_free(pkey);
	checkerr(r);
	RETVAL = newSVpvn( (char*)sigbuf, slen );
    OUTPUT:
	RETVAL

int
EVP_verify(SV *message, SV *signature, EVP_PKEY *pkey, const EVP_MD *md=NULL)
    INIT:
	EVP_MD_CTX *ctx = EVP_MD_CTX_new();
	unsigned char *m = (unsigned char*) SvPVX(message);
	unsigned char *s = (unsigned char*) SvPVX(signature);
	STRLEN mlen = SvCUR(message);
	STRLEN slen = SvCUR(signature);
    CODE:
	checkerr( EVP_DigestVerifyInit( ctx, NULL, md, NULL, pkey ) );
	RETVAL = EVP_DigestVerify( ctx, s, slen, m, mlen );
	EVP_MD_CTX_free(ctx);
	EVP_PKEY_free(pkey);
    OUTPUT:
	RETVAL


EVP_MD_CTX*
EVP_MD_CTX_new()

void
EVP_MD_CTX_free(EVP_MD_CTX *ctx)

void
EVP_DigestInit(EVP_MD_CTX *ctx, const EVP_MD *type)
    CODE:
	checkerr( EVP_DigestInit( ctx, type ) );

void
EVP_DigestUpdate(EVP_MD_CTX *ctx, SV *message)
    INIT:
	unsigned char *m = (unsigned char*) SvPVX(message);
	STRLEN mlen = SvCUR(message);
    CODE:
	checkerr( EVP_DigestUpdate( ctx, m, mlen ) );

SV*
EVP_DigestFinal(EVP_MD_CTX *ctx)
    INIT:
	unsigned char digest[EVP_MAX_MD_SIZE];
	unsigned int size = sizeof(digest);
    CODE:
	checkerr( EVP_DigestFinal( ctx, digest, &size ) );
	RETVAL = newSVpvn( (char*)digest, size );
    OUTPUT:
	RETVAL


const EVP_MD*
EVP_md5()

const EVP_MD*
EVP_sha1()

const EVP_MD*
EVP_sha224()

const EVP_MD*
EVP_sha256()

const EVP_MD*
EVP_sha384()

const EVP_MD*
EVP_sha512()


#ifndef NO_SHA3
const EVP_MD*
EVP_sha3_224()

const EVP_MD*
EVP_sha3_256()

const EVP_MD*
EVP_sha3_384()

const EVP_MD*
EVP_sha3_512()

#endif


####	DSA	####

#ifndef NO_DSA

EVP_PKEY*
EVP_PKEY_new_DSA(SV *p_SV, SV *q_SV, SV *g_SV, SV *y_SV, SV *x_SV)
    INIT:
	BIGNUM *p = BN_bin2bn( (unsigned char*) SvPVX(p_SV), SvCUR(p_SV), NULL );
	BIGNUM *q = BN_bin2bn( (unsigned char*) SvPVX(q_SV), SvCUR(q_SV), NULL );
	BIGNUM *g = BN_bin2bn( (unsigned char*) SvPVX(g_SV), SvCUR(g_SV), NULL );
	BIGNUM *x = BN_bin2bn( (unsigned char*) SvPVX(x_SV), SvCUR(x_SV), NULL );
	BIGNUM *y = BN_bin2bn( (unsigned char*) SvPVX(y_SV), SvCUR(y_SV), NULL );
    CODE:
#ifdef OBSOLETE_API
	DSA *dsa = DSA_new();
	DSA_set0_pqg( dsa, p, q, g );
	DSA_set0_key( dsa, y, x );
	RETVAL = EVP_PKEY_new();
	EVP_PKEY_assign( RETVAL, EVP_PKEY_DSA, (char*)dsa );
#else
	EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new_from_name( libctx, "DSA", NULL );
	OSSL_PARAM_BLD *bld = OSSL_PARAM_BLD_new();
	checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_FFC_P, p ) );
	checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_FFC_Q, q ) );
	checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_FFC_G, g ) );
	checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_PUB_KEY, y ) );
	RETVAL = NULL;
	if ( SvCUR(x_SV) > 0 ) {
		checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_PRIV_KEY, x ) );
		checkerr( EVP_PKEY_fromparams( ctx, &RETVAL, EVP_PKEY_KEYPAIR, bld ) );
	} else {
		checkerr( EVP_PKEY_fromparams( ctx, &RETVAL, EVP_PKEY_PUBLIC_KEY, bld ) );
	}
	OSSL_PARAM_BLD_free(bld);
	EVP_PKEY_CTX_free(ctx);
	BN_free(p);
	BN_free(q);
	BN_free(g);
	BN_free(x);
	BN_free(y);
#endif
    OUTPUT:
	RETVAL

#endif


####	RSA	####

#ifndef NO_RSA

EVP_PKEY*
EVP_PKEY_new_RSA(SV *n_SV, SV *e_SV, SV *d_SV, SV *p_SV, SV *q_SV)
    INIT:
	BIGNUM *n = BN_bin2bn( (unsigned char*) SvPVX(n_SV), SvCUR(n_SV), NULL );
	BIGNUM *e = BN_bin2bn( (unsigned char*) SvPVX(e_SV), SvCUR(e_SV), NULL );
	BIGNUM *d = BN_bin2bn( (unsigned char*) SvPVX(d_SV), SvCUR(d_SV), NULL );
	BIGNUM *p = BN_bin2bn( (unsigned char*) SvPVX(p_SV), SvCUR(p_SV), NULL );
	BIGNUM *q = BN_bin2bn( (unsigned char*) SvPVX(q_SV), SvCUR(q_SV), NULL );
    CODE:
#ifdef OBSOLETE_API
	RSA *rsa = RSA_new();
	RSA_set0_factors( rsa, p, q );
	RSA_set0_key( rsa, n, e, d );
	RETVAL = EVP_PKEY_new();
	EVP_PKEY_assign( RETVAL, EVP_PKEY_RSA, (char*)rsa );
#else
	EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new_from_name( libctx, "RSA", NULL );
	OSSL_PARAM_BLD *bld = OSSL_PARAM_BLD_new();
	checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_RSA_N, n ) );
	checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_RSA_E, e ) );
	checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_RSA_D, d ) );
	RETVAL = NULL;
	if ( SvCUR(p_SV) > 0 ) {
		checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_RSA_FACTOR, p ) );
		checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_RSA_FACTOR, q ) );
		checkerr( EVP_PKEY_fromparams( ctx, &RETVAL, EVP_PKEY_KEYPAIR, bld ) );
	} else {
		checkerr( EVP_PKEY_fromparams( ctx, &RETVAL, EVP_PKEY_PUBLIC_KEY, bld ) );
	}
	OSSL_PARAM_BLD_free(bld);
	EVP_PKEY_CTX_free(ctx);
	BN_free(n);
	BN_free(e);
	BN_free(d);
	BN_free(p);
	BN_free(q);
#endif
    OUTPUT:
	RETVAL

#endif


####	ECDSA	####

#ifndef NO_ECDSA

EVP_PKEY*
EVP_PKEY_new_ECDSA(int nid, SV *qx_SV, SV *qy_SV)
    INIT:
	BIGNUM *qx = BN_bin2bn( (unsigned char*) SvPVX(qx_SV), SvCUR(qx_SV), NULL );
	BIGNUM *qy = BN_bin2bn( (unsigned char*) SvPVX(qy_SV), SvCUR(qy_SV), NULL );
#ifdef OBSOLETE_API
	EC_KEY *eckey = EC_KEY_new_by_curve_name(nid);
#else
	EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new_from_name( libctx, "EC", NULL );
	OSSL_PARAM_BLD *bld = OSSL_PARAM_BLD_new();
#endif
    CODE:
#ifdef OBSOLETE_API
	if ( SvCUR(qy_SV) > 0 ) {
		checkerr( EC_KEY_set_public_key_affine_coordinates( eckey, qx, qy ) );
	} else {
		checkerr( EC_KEY_set_private_key( eckey, qx ) );
	}
	RETVAL = EVP_PKEY_new();
	checkerr( EVP_PKEY_assign( RETVAL, EVP_PKEY_EC, (char*)eckey ) );
#else
	if ( nid == 415 ) checkerr( OSSL_PARAM_BLD_push_utf8_string( bld, OSSL_PKEY_PARAM_GROUP_NAME, "P-256", 0 ) );
	if ( nid == 715 ) checkerr( OSSL_PARAM_BLD_push_utf8_string( bld, OSSL_PKEY_PARAM_GROUP_NAME, "P-384", 0 ) );
	RETVAL = NULL;
	if ( SvCUR(qy_SV) > 0 ) {
		checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_EC_PUB_X, qx ) );
		checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_EC_PUB_Y, qy ) );
		checkerr( EVP_PKEY_fromparams( ctx, &RETVAL, EVP_PKEY_PUBLIC_KEY, bld ) );
	} else {
		checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_PRIV_KEY, qx ) );
		checkerr( EVP_PKEY_fromparams( ctx, &RETVAL, EVP_PKEY_KEYPAIR, bld ) );
	}
	OSSL_PARAM_BLD_free(bld);
	EVP_PKEY_CTX_free(ctx);
#endif
	BN_clear_free(qx);
	BN_clear_free(qy);
    OUTPUT:
	RETVAL

#endif


####	EdDSA	####

#ifndef NO_EdDSA

EVP_PKEY*
EVP_PKEY_new_raw_public_key(int nid, SV *key)
    ALIAS:
	EVP_PKEY_new_raw_private_key = 1
    INIT:
	unsigned char *rawkey = (unsigned char*) SvPVX(key);
	STRLEN keylen = SvCUR(key);
#ifndef OBSOLETE_API
	EVP_PKEY_CTX *ctx = NULL;
	OSSL_PARAM_BLD *bld = OSSL_PARAM_BLD_new();
#endif
    CODE:
#ifdef OBSOLETE_API
	if ( ix > 0 ) {
		RETVAL = EVP_PKEY_new_raw_private_key( nid, NULL, rawkey , keylen );
	} else {
		RETVAL = EVP_PKEY_new_raw_public_key( nid, NULL, rawkey , keylen );
	}
#else
	if ( nid == 1087 ) ctx = EVP_PKEY_CTX_new_from_name( libctx, "ED25519", NULL );
	if ( nid == 1088 ) ctx = EVP_PKEY_CTX_new_from_name( libctx, "ED448", NULL );
	RETVAL = NULL;
	if ( ix > 0 ) {
		checkerr( OSSL_PARAM_BLD_push_octet_string( bld, OSSL_PKEY_PARAM_PRIV_KEY, rawkey, keylen ) );
		checkerr( EVP_PKEY_fromparams( ctx, &RETVAL, EVP_PKEY_KEYPAIR, bld ) );
	} else {
		checkerr( OSSL_PARAM_BLD_push_octet_string( bld, OSSL_PKEY_PARAM_PUB_KEY, rawkey, keylen ) );
		checkerr( EVP_PKEY_fromparams( ctx, &RETVAL, EVP_PKEY_PUBLIC_KEY, bld ) );
	}
	OSSL_PARAM_BLD_free(bld);
	EVP_PKEY_CTX_free(ctx);
#endif
    OUTPUT:
	RETVAL

#endif


####################

void
checkerr(int ret)


#ifdef croak_memory_wrap
void
croak_memory_wrap()

#endif


#ifdef DEBUG
void
ERR_print_errors(SV *filename)
    CODE:
	BIO *bio = BIO_new_file( SvPVX(filename), "w" );
	ERR_print_errors(bio);
	BIO_free(bio);

#endif

####################

