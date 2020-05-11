
#define XS_Id "$Id: SEC.xs 1777 2020-05-07 08:24:01Z willem $"


=head1 NAME

Net::DNS::SEC::libcrypto - Perl interface to OpenSSL libcrypto

=head1 DESCRIPTION

Perl XS extension providing access to the OpenSSL libcrypto library
upon which the Net::DNS::SEC cryptographic components are built.

=head1 COPYRIGHT

Copyright (c)2018-2020 Dick Franks

All Rights Reserved

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the above copyright notice appear in all copies and that both that
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
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define OPENSSL_SUPPRESS_DEPRECATED
#include <openssl/opensslv.h>
#include <openssl/evp.h>
#include <openssl/bn.h>
#include <openssl/dsa.h>
#include <openssl/ec.h>
#include <openssl/ecdsa.h>
#include <openssl/rsa.h>

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
#define NO_ECCGOST
#define NO_ECDSA
#define NO_EdDSA
#endif


#ifndef OPENSSL_VERSION_NUMBER		/* 0xMNN00PP0L	retain backward compatibility */
#define OPENSSL_VERSION_NUMBER  \
	( (OPENSSL_VERSION_MAJOR<<28) | (OPENSSL_VERSION_MINOR<<20) | (OPENSSL_VERSION_PATCH<<4) | 0x0L )
#endif


#ifdef LIBRESSL_VERSION_NUMBER
#undef OPENSSL_VERSION_NUMBER
#define OPENSSL_VERSION_NUMBER 0x10100000L
#endif


#if (OPENSSL_VERSION_NUMBER < 0x10101000)
#define NO_ECCGOST
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


#if (OPENSSL_VERSION_NUMBER < 0x10001000)
#define NO_ECDSA
#error	unsupported libcrypto version
#include OPENSSL_VERSION_TEXT /* in error log; by any means, however reprehensible! */
#endif


#ifndef NO_ECCGOST
BIGNUM *bn_new_hex(const char *hex)
{
	BIGNUM *bn = BN_new();
	BN_hex2bn( &bn, hex );
	return bn;
}
#endif


void checkret(const int ret, int line)
{
	if ( ret != 1 ) croak("libcrypto error (%s line %d)", __FILE__, line);
}

#define checkerr(arg)	checkret( (arg), __LINE__ )
#define nocheckerr(arg)	/* NOOP */


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
	unsigned int mlen = SvCUR(message);
    CODE:
	checkerr( EVP_DigestUpdate( ctx, m, mlen ) );

SV*
EVP_DigestFinal(EVP_MD_CTX *ctx)
    INIT:
	unsigned char digest[EVP_MAX_MD_SIZE];
	unsigned int size = sizeof(digest);
	const EVP_MD *type = EVP_MD_CTX_md( ctx );
    CODE:
	checkerr( EVP_DigestFinal( ctx, digest, &size ) );
	checkerr( EVP_DigestInit( ctx, type ) );	/* reinitialise; behave like Digest::SHA */
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

void
EVP_PKEY_assign_DSA(EVP_PKEY *pkey, DSA *key)
    CODE:
	checkerr( EVP_PKEY_assign( pkey, EVP_PKEY_DSA, (char*)key ) );

DSA*
DSA_new()

void
DSA_set0_pqg(DSA *d, SV *p_SV, SV *q_SV, SV *g_SV)
    INIT:
	BIGNUM *p = BN_bin2bn( (unsigned char*) SvPVX(p_SV), SvCUR(p_SV), NULL );
	BIGNUM *q = BN_bin2bn( (unsigned char*) SvPVX(q_SV), SvCUR(q_SV), NULL );
	BIGNUM *g = BN_bin2bn( (unsigned char*) SvPVX(g_SV), SvCUR(g_SV), NULL );
    CODE:
	checkerr( DSA_set0_pqg( d, p, q, g ) );

void
DSA_set0_key(DSA *dsa, SV *y_SV, SV *x_SV)
    INIT:
	BIGNUM *x = BN_bin2bn( (unsigned char*) SvPVX(x_SV), SvCUR(x_SV), NULL );
	BIGNUM *y = BN_bin2bn( (unsigned char*) SvPVX(y_SV), SvCUR(y_SV), NULL );
    CODE:
	checkerr( DSA_set0_key( dsa, y, x ) );

#endif


####	RSA	####

#ifndef NO_RSA

void
EVP_PKEY_assign_RSA(EVP_PKEY *pkey, RSA *key)
    CODE:
	checkerr( EVP_PKEY_assign( pkey, EVP_PKEY_RSA, (char*)key ) );

RSA*
RSA_new()

void
RSA_set0_factors(RSA *r, SV *p_SV, SV *q_SV)
    INIT:
	BIGNUM *p = BN_bin2bn( (unsigned char*) SvPVX(p_SV), SvCUR(p_SV), NULL );
	BIGNUM *q = BN_bin2bn( (unsigned char*) SvPVX(q_SV), SvCUR(q_SV), NULL );
    CODE:
	checkerr( RSA_set0_factors( r, p, q ) );

void
RSA_set0_key(RSA *r, SV *n_SV, SV *e_SV, SV *d_SV)
    INIT:
	BIGNUM *d = BN_bin2bn( (unsigned char*) SvPVX(d_SV), SvCUR(d_SV), NULL );
	BIGNUM *e = BN_bin2bn( (unsigned char*) SvPVX(e_SV), SvCUR(e_SV), NULL );
	BIGNUM *n = BN_bin2bn( (unsigned char*) SvPVX(n_SV), SvCUR(n_SV), NULL );
    CODE:
	checkerr( RSA_set0_key( r, n, e, d ) );

#endif


####	ECDSA	####

#ifndef NO_ECDSA

void
EVP_PKEY_assign_EC_KEY(EVP_PKEY *pkey, EC_KEY *key)
    CODE:
	checkerr( EVP_PKEY_assign( pkey, EVP_PKEY_EC, (char*)key ) );

# Creates new EC_KEY object using prescribed curve
EC_KEY*
EC_KEY_new_by_curve_name(int nid)

void
EC_KEY_set_private_key(EC_KEY *key, SV *prv_SV)
    INIT:
	BIGNUM *prv = BN_bin2bn( (unsigned char*) SvPVX(prv_SV), SvCUR(prv_SV), NULL );
	int status;
    CODE:
	status = EC_KEY_set_private_key( key, prv );
	BN_clear_free(prv);
	checkerr(status);

void
EC_KEY_set_public_key_affine_coordinates(EC_KEY *key, SV *x_SV, SV *y_SV)
    INIT:
	BIGNUM *x = BN_bin2bn( (unsigned char*) SvPVX(x_SV), SvCUR(x_SV), NULL );
	BIGNUM *y = BN_bin2bn( (unsigned char*) SvPVX(y_SV), SvCUR(y_SV), NULL );
	int status;
    CODE:
	status = EC_KEY_set_public_key_affine_coordinates( key, x, y );
	BN_free(x);
	BN_free(y);
	checkerr(status);

#endif


####	EdDSA	####

#ifndef NO_EdDSA

EVP_PKEY*
EVP_PKEY_new_raw_private_key(int nid, SV *key)
    CODE:
	RETVAL = EVP_PKEY_new_raw_private_key( nid, NULL, (unsigned char*) SvPVX(key) , SvCUR(key) );
    OUTPUT:
	RETVAL

EVP_PKEY*
EVP_PKEY_new_raw_public_key(int nid, SV *key)
    CODE:
	RETVAL = EVP_PKEY_new_raw_public_key( nid, NULL, (unsigned char*) SvPVX(key) , SvCUR(key) );
    OUTPUT:
	RETVAL

#endif


####################

####	Verify-only support for obsolete ECC-GOST	####

#ifndef NO_ECCGOST

EC_KEY*
EC_KEY_new_ECCGOST()
    PREINIT:					# GOST_R_34_10_2001_CryptoPro_A
	BIGNUM *a = bn_new_hex("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFD94");
	BIGNUM *b = bn_new_hex("00A6");
	BIGNUM *p = bn_new_hex("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFD97");
	BIGNUM *q = bn_new_hex("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF6C611070995AD10045841B09B761B893");
	BIGNUM *x = bn_new_hex("01");
	BIGNUM *y = bn_new_hex("8D91E471E0989CDA27DF505A453F2B7635294F2DDF23E3B122ACC99C9E9F1E14");
	BIGNUM *h = bn_new_hex("01");
	BN_CTX *ctx = BN_CTX_new();
	EC_GROUP *group = EC_GROUP_new_curve_GFp(p, a, b, ctx);
	EC_POINT *G = EC_POINT_new(group);
    CODE:
	checkerr( EC_POINT_set_affine_coordinates(group, G, x, y, ctx) );
	checkerr( EC_GROUP_set_generator(group, G, q, h) );
	EC_POINT_free(G);
	BN_free(a);
	BN_free(b);
	BN_free(p);
	BN_free(q);
	BN_free(x);
	BN_free(y);
	BN_free(h);
	nocheckerr( EC_GROUP_check(group, ctx) );
	BN_CTX_free(ctx);
	RETVAL = EC_KEY_new();
	checkerr( EC_KEY_set_group(RETVAL, group) );
	EC_GROUP_free(group);
    OUTPUT:
	RETVAL

int
ECCGOST_verify(SV *H, SV *r_SV, SV *s_SV, EC_KEY *eckey)
    INIT:
	STRLEN len = SvCUR(H);
	unsigned char *bin = (unsigned char*) SvPVX(H);
	BIGNUM *alpha = BN_bin2bn( bin, len, NULL );
	BIGNUM *r = BN_bin2bn( (unsigned char*) SvPVX(r_SV), SvCUR(r_SV), NULL );
	BIGNUM *s = BN_bin2bn( (unsigned char*) SvPVX(s_SV), SvCUR(s_SV), NULL );
	const EC_GROUP *group = EC_KEY_get0_group(eckey);
	BN_CTX *ctx = BN_CTX_new();
	BIGNUM *e = BN_new();
	BIGNUM *m = BN_new();
	BIGNUM *q = BN_new();
	ECDSA_SIG *ecsig = ECDSA_SIG_new();
    CODE:
	checkerr( EC_GROUP_get_order(group, q, ctx) );
	checkerr( BN_mod(e, alpha, q, ctx) );
	if ( BN_is_zero(e) ) BN_set_word(e, 1);
	BN_free(alpha);

	/* algebraic transformation of ECC-GOST into equivalent ECDSA problem */
	checkerr( BN_mod_sub(m, q, s, q, ctx) );
	checkerr( BN_mod_sub(s, q, e, q, ctx) );
	BN_free(e);
	BN_free(q);

	checkerr( ECDSA_SIG_set0(ecsig, r, s) );

	BN_bn2binpad(m, bin, len);
	BN_free(m);
	RETVAL = ECDSA_do_verify( bin, len, ecsig, eckey );
	BN_CTX_free(ctx);
	EC_KEY_free(eckey);
	ECDSA_SIG_free(ecsig);
    OUTPUT:
	RETVAL

#endif

####################

void
checkerr(int ret)
    CODE:
	checkerr(ret);


#ifdef croak_memory_wrap
void
croak_memory_wrap()

#endif

####################

