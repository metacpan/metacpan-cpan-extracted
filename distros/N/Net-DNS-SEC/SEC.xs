
#define XS_Id "$Id: SEC.xs 1975 2024-04-22 14:41:36Z willem $"


=head1 NAME

Net::DNS::SEC::libcrypto - Perl interface to OpenSSL libcrypto

=head1 DESCRIPTION

Perl XS extension providing bindings to the OpenSSL libcrypto library
upon which the Net::DNS::SEC cryptographic components are built.

=head1 COPYRIGHT

Copyright (c)2018-2024 Dick Franks

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
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <openssl/opensslv.h>

#ifdef OPENSSL_VERSION_NUMBER
#define OPENSSL_RELEASE	( OPENSSL_VERSION_NUMBER>>4 )	/* 0xMMmm0000 */
#else
#define OPENSSL_RELEASE	( OPENSSL_VERSION_MAJOR<<24 | OPENSSL_VERSION_MINOR<<16 )
#endif

#if (OPENSSL_RELEASE < 0x03000000)
#define API_1_1_1
#include <openssl/dsa.h>
#include <openssl/ecdsa.h>
#include <openssl/rsa.h>
#else
#include <openssl/core_names.h>
#include <openssl/param_build.h>
static OSSL_LIB_CTX *libctx = NULL;
#endif

#include <openssl/bn.h>
#include <openssl/err.h>
#include <openssl/evp.h>

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

#ifdef OPENSSL_NO_ECX
#define NO_EdDSA
#endif

#ifdef OPENSSL_NO_SM3
#define NO_SM3
#endif


#if (OPENSSL_RELEASE < 0x01000100)
#error	ancient libcrypto version
#include OPENSSL_VERSION_TEXT /* in error log; by any means, however reprehensible! */
#endif


#if (OPENSSL_RELEASE < 0x03040000)
#define EOL 20260409
#endif

#if (OPENSSL_RELEASE < 0x03030000)
#undef  EOL
#define EOL 20251123
#endif

#if (OPENSSL_RELEASE < 0x03020000)
#undef  EOL
#define EOL 20250314
#endif

#if (OPENSSL_RELEASE < 0x03010000)
#undef  EOL
#define EOL 20260907
#endif

#if (OPENSSL_RELEASE < 0x03000000)
#undef  EOL
#define EOL 20230911
#define NO_SM3
#ifndef NID_ED25519
#define NO_EdDSA
#endif
#endif


#if (OPENSSL_RELEASE < 0x01010000)
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


#if (OPENSSL_RELEASE < 0x01010100)
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


#ifdef OPENSSL_IS_BORINGSSL
#undef  EOL
#define NO_DSA
#endif

#ifdef LIBRESSL_VERSION_NUMBER
#undef  EOL
#define NO_DSA
#endif


#define SV2BN(sv)	BN_bin2bn( (unsigned char*) SvPVX(sv), SvCUR(sv), NULL )
#define UNDEF		newSVpvn("",0)
#define UNUSED(sv)	sv=sv;

#define checkerr(arg)	checkret( (arg), __LINE__ )
void checkret(const int ret, int line)
{
	if ( ret <= 0 ) croak( "libcrypto error (%s line %d)", __FILE__, line );
}


#ifdef EVP_PKEY_PUBLIC_KEY
int EVP_PKEY_fromparams(EVP_PKEY_CTX *ctx, EVP_PKEY **ppkey, int selection, OSSL_PARAM_BLD *bld)
{
	int retval;
	OSSL_PARAM *params = OSSL_PARAM_BLD_to_param(bld);
	checkerr( EVP_PKEY_fromdata_init(ctx) );
	retval = EVP_PKEY_fromdata( ctx, ppkey, selection, params );
	OSSL_PARAM_free(params);
	return retval;
}
#endif


#ifdef EOL
char* selecttxt(int d1, int d2, char *txt)
{	/* select text based on ISO date comparison */
	return ( d1 > d2 ) ? txt : "";
}
#endif


MODULE = Net::DNS::SEC	PACKAGE = Net::DNS::SEC::libcrypto

PROTOTYPES: ENABLE

SV*
VERSION(void)
    INIT:
	char *v = SvEND( newSVpv(XS_Id, 17) );
#ifdef EOL
	time_t today = time( NULL );
	char buf[10];
	char *txt;
#endif
    CODE:
#ifdef EOL
	strftime( buf, sizeof buf, "%Y%m%d", gmtime(&today) );
	txt = selecttxt( EOL, atoi(buf), "" );	/* get 100% coverage by calling this twice */
	txt = selecttxt( atoi(buf), EOL, "	[UNSUPPORTED]" );
	RETVAL = newSVpvf( "%s	%s%s", v-5, OPENSSL_VERSION_TEXT, txt );
#else
	RETVAL = newSVpvf( "%s	%s", v-5, OPENSSL_VERSION_TEXT );
#endif
    OUTPUT:
	RETVAL


####	EVP	####

EVP_PKEY*
EVP_PKEY_new()

SV*
EVP_sign(SV *message, EVP_PKEY *pkey, const EVP_MD *md=NULL)
    INIT:
#define msgbuf (unsigned char*) SvPVX(message)
#define msglen SvCUR(message)
	EVP_MD_CTX *ctx = EVP_MD_CTX_new();
	unsigned char sigbuf[512];		/* RFC3110(2) */
	STRLEN buflen = sizeof(sigbuf);
	int error;
    CODE:
	checkerr( EVP_DigestSignInit( ctx, NULL, md, NULL, pkey ) );
	error = EVP_DigestSign( ctx, sigbuf, &buflen, msgbuf, msglen );
	EVP_MD_CTX_free(ctx);
	EVP_PKEY_free(pkey);
	checkerr(error);
	RETVAL = newSVpvn( (char*)sigbuf, buflen );
    OUTPUT:
	RETVAL

int
EVP_verify(SV *message, SV *signature, EVP_PKEY *pkey, const EVP_MD *md=NULL)
    INIT:
#define sigbuf (unsigned char*) SvPVX(signature)
#define siglen SvCUR(signature)
	EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    CODE:
	checkerr( EVP_DigestVerifyInit( ctx, NULL, md, NULL, pkey ) );
	RETVAL = EVP_DigestVerify( ctx, sigbuf, siglen, msgbuf, msglen );
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
    CODE:
	checkerr( EVP_DigestUpdate( ctx, msgbuf, msglen ) );

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


#ifndef NO_SM3
const EVP_MD*
EVP_sm3()

#endif


####	DSA	####

#ifndef NO_DSA

EVP_PKEY*
EVP_PKEY_new_DSA(SV *p_SV, SV *q_SV, SV *g_SV, SV *y_SV, SV *x_SV=UNDEF )
    INIT:
#ifdef API_1_1_1
	DSA *dsa = DSA_new();
#else
	EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new_from_name( libctx, "DSA", NULL );
	OSSL_PARAM_BLD *bld = OSSL_PARAM_BLD_new();
	BIGNUM *p, *q, *g, *x, *y;
#endif
    CODE:
#ifdef API_1_1_1
	RETVAL = EVP_PKEY_new();
	checkerr( DSA_set0_pqg( dsa, SV2BN(p_SV), SV2BN(q_SV), SV2BN(g_SV) ) );
	checkerr( DSA_set0_key( dsa, SV2BN(y_SV), SV2BN(x_SV) ) );
	checkerr( EVP_PKEY_assign( RETVAL, EVP_PKEY_DSA, (char*)dsa ) );
#else
	RETVAL = NULL;
	checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_FFC_P, p=SV2BN(p_SV) ) );
	checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_FFC_Q, q=SV2BN(q_SV) ) );
	checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_FFC_G, g=SV2BN(g_SV) ) );
	checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_PUB_KEY, y=SV2BN(y_SV) ) );
	if ( SvCUR(x_SV) > 0 ) {
		checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_PRIV_KEY, x=SV2BN(x_SV) ) );
		checkerr( EVP_PKEY_fromparams( ctx, &RETVAL, EVP_PKEY_KEYPAIR, bld ) );
		BN_free(x);
	} else {
		checkerr( EVP_PKEY_fromparams( ctx, &RETVAL, EVP_PKEY_PUBLIC_KEY, bld ) );
	}
	OSSL_PARAM_BLD_free(bld);
	EVP_PKEY_CTX_free(ctx);
	BN_free(p);
	BN_free(q);
	BN_free(g);
	BN_free(y);
#endif
    OUTPUT:
	RETVAL

#endif


####	RSA	####

#ifndef NO_RSA

EVP_PKEY*
EVP_PKEY_new_RSA(SV *n_SV, SV *e_SV, SV *d_SV=UNDEF, SV *p1_SV=UNDEF, SV *p2_SV=UNDEF, SV *e1_SV=UNDEF, SV *e2_SV=UNDEF, SV *c_SV=UNDEF )
    INIT:
#ifdef API_1_1_1
	RSA *rsa = RSA_new();
#else
	EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new_from_name( libctx, "RSA", NULL );
	OSSL_PARAM_BLD *bld = OSSL_PARAM_BLD_new();
	BIGNUM *n, *e, *d, *p1, *p2, *e1, *e2, *c;
#endif
    CODE:
#ifdef API_1_1_1
	RETVAL = EVP_PKEY_new();
	checkerr( RSA_set0_factors( rsa, SV2BN(p1_SV), SV2BN(p2_SV) ) );
	checkerr( RSA_set0_key( rsa, SV2BN(n_SV), SV2BN(e_SV), SV2BN(d_SV) ) );
	checkerr( EVP_PKEY_assign( RETVAL, EVP_PKEY_RSA, (char*)rsa ) );
	UNUSED(e1_SV); UNUSED(e2_SV); UNUSED(c_SV);	/* suppress unused variable warnings */
#else
	RETVAL = NULL;
	checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_RSA_N, n=SV2BN(n_SV) ) );
	checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_RSA_E, e=SV2BN(e_SV) ) );
	if ( SvCUR(d_SV) > 0 ) {
		checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_RSA_D, d=SV2BN(d_SV) ) );
		checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_RSA_FACTOR1, p1=SV2BN(p1_SV) ) );
		checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_RSA_FACTOR2, p2=SV2BN(p2_SV) ) );
		checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_RSA_EXPONENT1, e1=SV2BN(e1_SV) ) );
		checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_RSA_EXPONENT2, e2=SV2BN(e2_SV) ) );
		checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_RSA_COEFFICIENT1, c=SV2BN(c_SV) ) );
		checkerr( EVP_PKEY_fromparams( ctx, &RETVAL, EVP_PKEY_KEYPAIR, bld ) );
		BN_free(d);
		BN_free(p1);
		BN_free(p2);
		BN_free(e1);
		BN_free(e2);
		BN_free(c);
	} else {
		checkerr( EVP_PKEY_fromparams( ctx, &RETVAL, EVP_PKEY_PUBLIC_KEY, bld ) );
	}
	OSSL_PARAM_BLD_free(bld);
	EVP_PKEY_CTX_free(ctx);
	BN_free(n);
	BN_free(e);
#endif
    OUTPUT:
	RETVAL

#endif


####	ECDSA	####

#ifndef NO_ECDSA

EVP_PKEY*
EVP_PKEY_new_ECDSA(SV *curve, SV *qx_SV, SV *qy_SV=UNDEF )
    INIT:
#ifdef API_1_1_1
	EC_KEY *eckey = NULL;
	BIGNUM *qx, *qy;
#else
	EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new_from_name( libctx, "EC", NULL );
	OSSL_PARAM_BLD *bld = OSSL_PARAM_BLD_new();
	SV *ksv = newSVpvn("\4",1);
	BIGNUM *qx;
#endif
	char *name = SvPVX(curve);
    CODE:
#ifdef API_1_1_1
	RETVAL = EVP_PKEY_new();
	if ( strcmp(name,"P-256") == 0 ) eckey = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
	if ( strcmp(name,"P-384") == 0 ) eckey = EC_KEY_new_by_curve_name(NID_secp384r1);
	if ( SvCUR(qy_SV) > 0 ) {
		checkerr( EC_KEY_set_public_key_affine_coordinates( eckey, qx=SV2BN(qx_SV), qy=SV2BN(qy_SV) ) );
		BN_free(qx);
		BN_free(qy);
	} else {
		checkerr( EC_KEY_set_private_key( eckey, qx=SV2BN(qx_SV) ) );
		BN_clear_free(qx);
	}
	checkerr( EVP_PKEY_assign( RETVAL, EVP_PKEY_EC, (char*)eckey ) );
#else
	RETVAL = NULL;
	checkerr( OSSL_PARAM_BLD_push_utf8_string( bld, OSSL_PKEY_PARAM_GROUP_NAME, name, 0 ) );
	if ( SvCUR(qy_SV) > 0 ) {
		sv_catpvn_nomg(ksv, SvPVX(qx_SV), SvCUR(qx_SV));
		sv_catpvn_nomg(ksv, SvPVX(qy_SV), SvCUR(qy_SV));
		checkerr( OSSL_PARAM_BLD_push_octet_string( bld, OSSL_PKEY_PARAM_PUB_KEY, SvPVX(ksv), SvCUR(ksv) ) );
		checkerr( EVP_PKEY_fromparams( ctx, &RETVAL, EVP_PKEY_PUBLIC_KEY, bld ) );
	} else {
		checkerr( OSSL_PARAM_BLD_push_BN( bld, OSSL_PKEY_PARAM_PRIV_KEY, qx=SV2BN(qx_SV) ) );
		checkerr( EVP_PKEY_fromparams( ctx, &RETVAL, EVP_PKEY_KEYPAIR, bld ) );
		BN_clear_free(qx);
	}
	OSSL_PARAM_BLD_free(bld);
	EVP_PKEY_CTX_free(ctx);
#endif
    OUTPUT:
	RETVAL

#endif


####	EdDSA	####

#ifndef NO_EdDSA

EVP_PKEY*
EVP_PKEY_new_EdDSA(SV *curve, SV *public, SV *private=NULL)
    INIT:
#ifdef API_1_1_1
	char *name = SvPVX(curve);
	int nid = 0;
#else
	OSSL_PARAM_BLD *bld = OSSL_PARAM_BLD_new();
	EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new_from_name( libctx, SvPVX(curve), NULL );
#endif
    CODE:
	RETVAL = NULL;
#ifdef API_1_1_1
	if ( strcmp(name,"ED25519") == 0 ) nid = NID_ED25519;
#ifdef NID_ED448		/* not yet implemented in BoringSSL & LibreSSL */
	if ( strcmp(name,"ED448") == 0 )   nid = NID_ED448;
#endif
	if ( private == NULL ) {
		RETVAL = EVP_PKEY_new_raw_public_key( nid, NULL, (unsigned char*) SvPVX(public), SvCUR(public) );
	} else {
		RETVAL = EVP_PKEY_new_raw_private_key( nid, NULL, (unsigned char*) SvPVX(private), SvCUR(private) );
	}
#else
	if ( private == NULL ) {
		checkerr( OSSL_PARAM_BLD_push_octet_string( bld, OSSL_PKEY_PARAM_PUB_KEY, SvPVX(public), SvCUR(public) ) );
		checkerr( EVP_PKEY_fromparams( ctx, &RETVAL, EVP_PKEY_PUBLIC_KEY, bld ) );
	} else {
		checkerr( OSSL_PARAM_BLD_push_octet_string( bld, OSSL_PKEY_PARAM_PRIV_KEY, SvPVX(private), SvCUR(private) ) );
		checkerr( EVP_PKEY_fromparams( ctx, &RETVAL, EVP_PKEY_KEYPAIR, bld ) );
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

