// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/err.h>
#include <openssl/lhash.h>
#include <openssl/rand.h>
#include <openssl/buffer.h>
#include <openssl/ssl.h>
#include <openssl/pkcs12.h>
#include <openssl/comp.h>
#include <openssl/md4.h>
#include <openssl/md5.h>
#include <openssl/ripemd.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>
#include <openssl/engine.h>
#include <openssl/ocsp.h>

static const char* FILE_NAME = "Net/SSLeay/Constant.c";

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_VERSION_TEXT(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  char *version = OPENSSL_VERSION_TEXT;
  
  void* obj_version = env->new_string_nolen(env, stack, version);
  
  stack[0].oval = obj_version;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__Constant__ASN1_STRFLGS_ESC_CTRL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ASN1_STRFLGS_ESC_CTRL
  stack[0].ival = ASN1_STRFLGS_ESC_CTRL;
  return 0;
#else
  env->die(env, stack, "ASN1_STRFLGS_ESC_CTRL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__ASN1_STRFLGS_ESC_MSB(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ASN1_STRFLGS_ESC_MSB
  stack[0].ival = ASN1_STRFLGS_ESC_MSB;
  return 0;
#else
  env->die(env, stack, "ASN1_STRFLGS_ESC_MSB is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__ASN1_STRFLGS_ESC_QUOTE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ASN1_STRFLGS_ESC_QUOTE
  stack[0].ival = ASN1_STRFLGS_ESC_QUOTE;
  return 0;
#else
  env->die(env, stack, "ASN1_STRFLGS_ESC_QUOTE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__ASN1_STRFLGS_RFC2253(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ASN1_STRFLGS_RFC2253
  stack[0].ival = ASN1_STRFLGS_RFC2253;
  return 0;
#else
  env->die(env, stack, "ASN1_STRFLGS_RFC2253 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__EVP_PKS_DSA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef EVP_PKS_DSA
  stack[0].ival = EVP_PKS_DSA;
  return 0;
#else
  env->die(env, stack, "EVP_PKS_DSA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__EVP_PKS_EC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef EVP_PKS_EC
  stack[0].ival = EVP_PKS_EC;
  return 0;
#else
  env->die(env, stack, "EVP_PKS_EC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__EVP_PKS_RSA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef EVP_PKS_RSA
  stack[0].ival = EVP_PKS_RSA;
  return 0;
#else
  env->die(env, stack, "EVP_PKS_RSA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__EVP_PKT_ENC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef EVP_PKT_ENC
  stack[0].ival = EVP_PKT_ENC;
  return 0;
#else
  env->die(env, stack, "EVP_PKT_ENC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__EVP_PKT_EXCH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef EVP_PKT_EXCH
  stack[0].ival = EVP_PKT_EXCH;
  return 0;
#else
  env->die(env, stack, "EVP_PKT_EXCH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__EVP_PKT_EXP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef EVP_PKT_EXP
  stack[0].ival = EVP_PKT_EXP;
  return 0;
#else
  env->die(env, stack, "EVP_PKT_EXP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__EVP_PKT_SIGN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef EVP_PKT_SIGN
  stack[0].ival = EVP_PKT_SIGN;
  return 0;
#else
  env->die(env, stack, "EVP_PKT_SIGN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__EVP_PK_DH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef EVP_PK_DH
  stack[0].ival = EVP_PK_DH;
  return 0;
#else
  env->die(env, stack, "EVP_PK_DH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__EVP_PK_DSA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef EVP_PK_DSA
  stack[0].ival = EVP_PK_DSA;
  return 0;
#else
  env->die(env, stack, "EVP_PK_DSA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__EVP_PK_EC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef EVP_PK_EC
  stack[0].ival = EVP_PK_EC;
  return 0;
#else
  env->die(env, stack, "EVP_PK_EC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__EVP_PK_RSA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef EVP_PK_RSA
  stack[0].ival = EVP_PK_RSA;
  return 0;
#else
  env->die(env, stack, "EVP_PK_RSA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__GEN_DIRNAME(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef GEN_DIRNAME
  stack[0].ival = GEN_DIRNAME;
  return 0;
#else
  env->die(env, stack, "GEN_DIRNAME is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__GEN_DNS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef GEN_DNS
  stack[0].ival = GEN_DNS;
  return 0;
#else
  env->die(env, stack, "GEN_DNS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__GEN_EDIPARTY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef GEN_EDIPARTY
  stack[0].ival = GEN_EDIPARTY;
  return 0;
#else
  env->die(env, stack, "GEN_EDIPARTY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__GEN_EMAIL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef GEN_EMAIL
  stack[0].ival = GEN_EMAIL;
  return 0;
#else
  env->die(env, stack, "GEN_EMAIL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__GEN_IPADD(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef GEN_IPADD
  stack[0].ival = GEN_IPADD;
  return 0;
#else
  env->die(env, stack, "GEN_IPADD is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__GEN_OTHERNAME(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef GEN_OTHERNAME
  stack[0].ival = GEN_OTHERNAME;
  return 0;
#else
  env->die(env, stack, "GEN_OTHERNAME is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__GEN_RID(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef GEN_RID
  stack[0].ival = GEN_RID;
  return 0;
#else
  env->die(env, stack, "GEN_RID is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__GEN_URI(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef GEN_URI
  stack[0].ival = GEN_URI;
  return 0;
#else
  env->die(env, stack, "GEN_URI is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__GEN_X400(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef GEN_X400
  stack[0].ival = GEN_X400;
  return 0;
#else
  env->die(env, stack, "GEN_X400 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__LIBRESSL_VERSION_NUMBER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef LIBRESSL_VERSION_NUMBER
  stack[0].ival = LIBRESSL_VERSION_NUMBER;
  return 0;
#else
  env->die(env, stack, "LIBRESSL_VERSION_NUMBER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__MBSTRING_ASC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MBSTRING_ASC
  stack[0].ival = MBSTRING_ASC;
  return 0;
#else
  env->die(env, stack, "MBSTRING_ASC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__MBSTRING_BMP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MBSTRING_BMP
  stack[0].ival = MBSTRING_BMP;
  return 0;
#else
  env->die(env, stack, "MBSTRING_BMP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__MBSTRING_FLAG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MBSTRING_FLAG
  stack[0].ival = MBSTRING_FLAG;
  return 0;
#else
  env->die(env, stack, "MBSTRING_FLAG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__MBSTRING_UNIV(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MBSTRING_UNIV
  stack[0].ival = MBSTRING_UNIV;
  return 0;
#else
  env->die(env, stack, "MBSTRING_UNIV is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__MBSTRING_UTF8(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MBSTRING_UTF8
  stack[0].ival = MBSTRING_UTF8;
  return 0;
#else
  env->die(env, stack, "MBSTRING_UTF8 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_OCSP_sign(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_OCSP_sign
  stack[0].ival = NID_OCSP_sign;
  return 0;
#else
  env->die(env, stack, "NID_OCSP_sign is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_SMIMECapabilities(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_SMIMECapabilities
  stack[0].ival = NID_SMIMECapabilities;
  return 0;
#else
  env->die(env, stack, "NID_SMIMECapabilities is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_X500(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_X500
  stack[0].ival = NID_X500;
  return 0;
#else
  env->die(env, stack, "NID_X500 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_X509(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_X509
  stack[0].ival = NID_X509;
  return 0;
#else
  env->die(env, stack, "NID_X509 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_ad_OCSP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_ad_OCSP
  stack[0].ival = NID_ad_OCSP;
  return 0;
#else
  env->die(env, stack, "NID_ad_OCSP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_ad_ca_issuers(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_ad_ca_issuers
  stack[0].ival = NID_ad_ca_issuers;
  return 0;
#else
  env->die(env, stack, "NID_ad_ca_issuers is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_algorithm(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_algorithm
  stack[0].ival = NID_algorithm;
  return 0;
#else
  env->die(env, stack, "NID_algorithm is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_authority_key_identifier(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_authority_key_identifier
  stack[0].ival = NID_authority_key_identifier;
  return 0;
#else
  env->die(env, stack, "NID_authority_key_identifier is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_basic_constraints(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_basic_constraints
  stack[0].ival = NID_basic_constraints;
  return 0;
#else
  env->die(env, stack, "NID_basic_constraints is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_bf_cbc(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_bf_cbc
  stack[0].ival = NID_bf_cbc;
  return 0;
#else
  env->die(env, stack, "NID_bf_cbc is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_bf_cfb64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_bf_cfb64
  stack[0].ival = NID_bf_cfb64;
  return 0;
#else
  env->die(env, stack, "NID_bf_cfb64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_bf_ecb(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_bf_ecb
  stack[0].ival = NID_bf_ecb;
  return 0;
#else
  env->die(env, stack, "NID_bf_ecb is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_bf_ofb64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_bf_ofb64
  stack[0].ival = NID_bf_ofb64;
  return 0;
#else
  env->die(env, stack, "NID_bf_ofb64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_cast5_cbc(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_cast5_cbc
  stack[0].ival = NID_cast5_cbc;
  return 0;
#else
  env->die(env, stack, "NID_cast5_cbc is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_cast5_cfb64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_cast5_cfb64
  stack[0].ival = NID_cast5_cfb64;
  return 0;
#else
  env->die(env, stack, "NID_cast5_cfb64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_cast5_ecb(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_cast5_ecb
  stack[0].ival = NID_cast5_ecb;
  return 0;
#else
  env->die(env, stack, "NID_cast5_ecb is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_cast5_ofb64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_cast5_ofb64
  stack[0].ival = NID_cast5_ofb64;
  return 0;
#else
  env->die(env, stack, "NID_cast5_ofb64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_certBag(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_certBag
  stack[0].ival = NID_certBag;
  return 0;
#else
  env->die(env, stack, "NID_certBag is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_certificate_policies(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_certificate_policies
  stack[0].ival = NID_certificate_policies;
  return 0;
#else
  env->die(env, stack, "NID_certificate_policies is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_client_auth(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_client_auth
  stack[0].ival = NID_client_auth;
  return 0;
#else
  env->die(env, stack, "NID_client_auth is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_code_sign(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_code_sign
  stack[0].ival = NID_code_sign;
  return 0;
#else
  env->die(env, stack, "NID_code_sign is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_commonName(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_commonName
  stack[0].ival = NID_commonName;
  return 0;
#else
  env->die(env, stack, "NID_commonName is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_countryName(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_countryName
  stack[0].ival = NID_countryName;
  return 0;
#else
  env->die(env, stack, "NID_countryName is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_crlBag(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_crlBag
  stack[0].ival = NID_crlBag;
  return 0;
#else
  env->die(env, stack, "NID_crlBag is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_crl_distribution_points(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_crl_distribution_points
  stack[0].ival = NID_crl_distribution_points;
  return 0;
#else
  env->die(env, stack, "NID_crl_distribution_points is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_crl_number(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_crl_number
  stack[0].ival = NID_crl_number;
  return 0;
#else
  env->die(env, stack, "NID_crl_number is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_crl_reason(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_crl_reason
  stack[0].ival = NID_crl_reason;
  return 0;
#else
  env->die(env, stack, "NID_crl_reason is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_delta_crl(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_delta_crl
  stack[0].ival = NID_delta_crl;
  return 0;
#else
  env->die(env, stack, "NID_delta_crl is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_des_cbc(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_des_cbc
  stack[0].ival = NID_des_cbc;
  return 0;
#else
  env->die(env, stack, "NID_des_cbc is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_des_cfb64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_des_cfb64
  stack[0].ival = NID_des_cfb64;
  return 0;
#else
  env->die(env, stack, "NID_des_cfb64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_des_ecb(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_des_ecb
  stack[0].ival = NID_des_ecb;
  return 0;
#else
  env->die(env, stack, "NID_des_ecb is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_des_ede(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_des_ede
  stack[0].ival = NID_des_ede;
  return 0;
#else
  env->die(env, stack, "NID_des_ede is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_des_ede3(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_des_ede3
  stack[0].ival = NID_des_ede3;
  return 0;
#else
  env->die(env, stack, "NID_des_ede3 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_des_ede3_cbc(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_des_ede3_cbc
  stack[0].ival = NID_des_ede3_cbc;
  return 0;
#else
  env->die(env, stack, "NID_des_ede3_cbc is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_des_ede3_cfb64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_des_ede3_cfb64
  stack[0].ival = NID_des_ede3_cfb64;
  return 0;
#else
  env->die(env, stack, "NID_des_ede3_cfb64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_des_ede3_ofb64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_des_ede3_ofb64
  stack[0].ival = NID_des_ede3_ofb64;
  return 0;
#else
  env->die(env, stack, "NID_des_ede3_ofb64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_des_ede_cbc(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_des_ede_cbc
  stack[0].ival = NID_des_ede_cbc;
  return 0;
#else
  env->die(env, stack, "NID_des_ede_cbc is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_des_ede_cfb64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_des_ede_cfb64
  stack[0].ival = NID_des_ede_cfb64;
  return 0;
#else
  env->die(env, stack, "NID_des_ede_cfb64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_des_ede_ofb64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_des_ede_ofb64
  stack[0].ival = NID_des_ede_ofb64;
  return 0;
#else
  env->die(env, stack, "NID_des_ede_ofb64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_des_ofb64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_des_ofb64
  stack[0].ival = NID_des_ofb64;
  return 0;
#else
  env->die(env, stack, "NID_des_ofb64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_description(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_description
  stack[0].ival = NID_description;
  return 0;
#else
  env->die(env, stack, "NID_description is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_desx_cbc(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_desx_cbc
  stack[0].ival = NID_desx_cbc;
  return 0;
#else
  env->die(env, stack, "NID_desx_cbc is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_dhKeyAgreement(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_dhKeyAgreement
  stack[0].ival = NID_dhKeyAgreement;
  return 0;
#else
  env->die(env, stack, "NID_dhKeyAgreement is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_dnQualifier(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_dnQualifier
  stack[0].ival = NID_dnQualifier;
  return 0;
#else
  env->die(env, stack, "NID_dnQualifier is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_dsa(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_dsa
  stack[0].ival = NID_dsa;
  return 0;
#else
  env->die(env, stack, "NID_dsa is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_dsaWithSHA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_dsaWithSHA
  stack[0].ival = NID_dsaWithSHA;
  return 0;
#else
  env->die(env, stack, "NID_dsaWithSHA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_dsaWithSHA1(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_dsaWithSHA1
  stack[0].ival = NID_dsaWithSHA1;
  return 0;
#else
  env->die(env, stack, "NID_dsaWithSHA1 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_dsaWithSHA1_2(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_dsaWithSHA1_2
  stack[0].ival = NID_dsaWithSHA1_2;
  return 0;
#else
  env->die(env, stack, "NID_dsaWithSHA1_2 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_dsa_2(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_dsa_2
  stack[0].ival = NID_dsa_2;
  return 0;
#else
  env->die(env, stack, "NID_dsa_2 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_email_protect(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_email_protect
  stack[0].ival = NID_email_protect;
  return 0;
#else
  env->die(env, stack, "NID_email_protect is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_ext_key_usage(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_ext_key_usage
  stack[0].ival = NID_ext_key_usage;
  return 0;
#else
  env->die(env, stack, "NID_ext_key_usage is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_ext_req(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_ext_req
  stack[0].ival = NID_ext_req;
  return 0;
#else
  env->die(env, stack, "NID_ext_req is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_friendlyName(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_friendlyName
  stack[0].ival = NID_friendlyName;
  return 0;
#else
  env->die(env, stack, "NID_friendlyName is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_givenName(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_givenName
  stack[0].ival = NID_givenName;
  return 0;
#else
  env->die(env, stack, "NID_givenName is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_hmacWithSHA1(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_hmacWithSHA1
  stack[0].ival = NID_hmacWithSHA1;
  return 0;
#else
  env->die(env, stack, "NID_hmacWithSHA1 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_id_ad(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_id_ad
  stack[0].ival = NID_id_ad;
  return 0;
#else
  env->die(env, stack, "NID_id_ad is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_id_ce(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_id_ce
  stack[0].ival = NID_id_ce;
  return 0;
#else
  env->die(env, stack, "NID_id_ce is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_id_kp(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_id_kp
  stack[0].ival = NID_id_kp;
  return 0;
#else
  env->die(env, stack, "NID_id_kp is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_id_pbkdf2(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_id_pbkdf2
  stack[0].ival = NID_id_pbkdf2;
  return 0;
#else
  env->die(env, stack, "NID_id_pbkdf2 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_id_pe(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_id_pe
  stack[0].ival = NID_id_pe;
  return 0;
#else
  env->die(env, stack, "NID_id_pe is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_id_pkix(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_id_pkix
  stack[0].ival = NID_id_pkix;
  return 0;
#else
  env->die(env, stack, "NID_id_pkix is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_id_qt_cps(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_id_qt_cps
  stack[0].ival = NID_id_qt_cps;
  return 0;
#else
  env->die(env, stack, "NID_id_qt_cps is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_id_qt_unotice(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_id_qt_unotice
  stack[0].ival = NID_id_qt_unotice;
  return 0;
#else
  env->die(env, stack, "NID_id_qt_unotice is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_idea_cbc(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_idea_cbc
  stack[0].ival = NID_idea_cbc;
  return 0;
#else
  env->die(env, stack, "NID_idea_cbc is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_idea_cfb64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_idea_cfb64
  stack[0].ival = NID_idea_cfb64;
  return 0;
#else
  env->die(env, stack, "NID_idea_cfb64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_idea_ecb(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_idea_ecb
  stack[0].ival = NID_idea_ecb;
  return 0;
#else
  env->die(env, stack, "NID_idea_ecb is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_idea_ofb64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_idea_ofb64
  stack[0].ival = NID_idea_ofb64;
  return 0;
#else
  env->die(env, stack, "NID_idea_ofb64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_info_access(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_info_access
  stack[0].ival = NID_info_access;
  return 0;
#else
  env->die(env, stack, "NID_info_access is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_initials(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_initials
  stack[0].ival = NID_initials;
  return 0;
#else
  env->die(env, stack, "NID_initials is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_invalidity_date(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_invalidity_date
  stack[0].ival = NID_invalidity_date;
  return 0;
#else
  env->die(env, stack, "NID_invalidity_date is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_issuer_alt_name(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_issuer_alt_name
  stack[0].ival = NID_issuer_alt_name;
  return 0;
#else
  env->die(env, stack, "NID_issuer_alt_name is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_keyBag(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_keyBag
  stack[0].ival = NID_keyBag;
  return 0;
#else
  env->die(env, stack, "NID_keyBag is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_key_usage(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_key_usage
  stack[0].ival = NID_key_usage;
  return 0;
#else
  env->die(env, stack, "NID_key_usage is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_localKeyID(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_localKeyID
  stack[0].ival = NID_localKeyID;
  return 0;
#else
  env->die(env, stack, "NID_localKeyID is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_localityName(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_localityName
  stack[0].ival = NID_localityName;
  return 0;
#else
  env->die(env, stack, "NID_localityName is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_md2(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_md2
  stack[0].ival = NID_md2;
  return 0;
#else
  env->die(env, stack, "NID_md2 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_md2WithRSAEncryption(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_md2WithRSAEncryption
  stack[0].ival = NID_md2WithRSAEncryption;
  return 0;
#else
  env->die(env, stack, "NID_md2WithRSAEncryption is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_md5(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_md5
  stack[0].ival = NID_md5;
  return 0;
#else
  env->die(env, stack, "NID_md5 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_md5WithRSA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_md5WithRSA
  stack[0].ival = NID_md5WithRSA;
  return 0;
#else
  env->die(env, stack, "NID_md5WithRSA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_md5WithRSAEncryption(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_md5WithRSAEncryption
  stack[0].ival = NID_md5WithRSAEncryption;
  return 0;
#else
  env->die(env, stack, "NID_md5WithRSAEncryption is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_md5_sha1(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_md5_sha1
  stack[0].ival = NID_md5_sha1;
  return 0;
#else
  env->die(env, stack, "NID_md5_sha1 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_mdc2(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_mdc2
  stack[0].ival = NID_mdc2;
  return 0;
#else
  env->die(env, stack, "NID_mdc2 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_mdc2WithRSA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_mdc2WithRSA
  stack[0].ival = NID_mdc2WithRSA;
  return 0;
#else
  env->die(env, stack, "NID_mdc2WithRSA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_ms_code_com(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_ms_code_com
  stack[0].ival = NID_ms_code_com;
  return 0;
#else
  env->die(env, stack, "NID_ms_code_com is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_ms_code_ind(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_ms_code_ind
  stack[0].ival = NID_ms_code_ind;
  return 0;
#else
  env->die(env, stack, "NID_ms_code_ind is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_ms_ctl_sign(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_ms_ctl_sign
  stack[0].ival = NID_ms_ctl_sign;
  return 0;
#else
  env->die(env, stack, "NID_ms_ctl_sign is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_ms_efs(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_ms_efs
  stack[0].ival = NID_ms_efs;
  return 0;
#else
  env->die(env, stack, "NID_ms_efs is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_ms_ext_req(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_ms_ext_req
  stack[0].ival = NID_ms_ext_req;
  return 0;
#else
  env->die(env, stack, "NID_ms_ext_req is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_ms_sgc(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_ms_sgc
  stack[0].ival = NID_ms_sgc;
  return 0;
#else
  env->die(env, stack, "NID_ms_sgc is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_name(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_name
  stack[0].ival = NID_name;
  return 0;
#else
  env->die(env, stack, "NID_name is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_netscape(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_netscape
  stack[0].ival = NID_netscape;
  return 0;
#else
  env->die(env, stack, "NID_netscape is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_netscape_base_url(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_netscape_base_url
  stack[0].ival = NID_netscape_base_url;
  return 0;
#else
  env->die(env, stack, "NID_netscape_base_url is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_netscape_ca_policy_url(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_netscape_ca_policy_url
  stack[0].ival = NID_netscape_ca_policy_url;
  return 0;
#else
  env->die(env, stack, "NID_netscape_ca_policy_url is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_netscape_ca_revocation_url(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_netscape_ca_revocation_url
  stack[0].ival = NID_netscape_ca_revocation_url;
  return 0;
#else
  env->die(env, stack, "NID_netscape_ca_revocation_url is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_netscape_cert_extension(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_netscape_cert_extension
  stack[0].ival = NID_netscape_cert_extension;
  return 0;
#else
  env->die(env, stack, "NID_netscape_cert_extension is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_netscape_cert_sequence(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_netscape_cert_sequence
  stack[0].ival = NID_netscape_cert_sequence;
  return 0;
#else
  env->die(env, stack, "NID_netscape_cert_sequence is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_netscape_cert_type(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_netscape_cert_type
  stack[0].ival = NID_netscape_cert_type;
  return 0;
#else
  env->die(env, stack, "NID_netscape_cert_type is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_netscape_comment(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_netscape_comment
  stack[0].ival = NID_netscape_comment;
  return 0;
#else
  env->die(env, stack, "NID_netscape_comment is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_netscape_data_type(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_netscape_data_type
  stack[0].ival = NID_netscape_data_type;
  return 0;
#else
  env->die(env, stack, "NID_netscape_data_type is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_netscape_renewal_url(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_netscape_renewal_url
  stack[0].ival = NID_netscape_renewal_url;
  return 0;
#else
  env->die(env, stack, "NID_netscape_renewal_url is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_netscape_revocation_url(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_netscape_revocation_url
  stack[0].ival = NID_netscape_revocation_url;
  return 0;
#else
  env->die(env, stack, "NID_netscape_revocation_url is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_netscape_ssl_server_name(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_netscape_ssl_server_name
  stack[0].ival = NID_netscape_ssl_server_name;
  return 0;
#else
  env->die(env, stack, "NID_netscape_ssl_server_name is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_ns_sgc(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_ns_sgc
  stack[0].ival = NID_ns_sgc;
  return 0;
#else
  env->die(env, stack, "NID_ns_sgc is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_organizationName(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_organizationName
  stack[0].ival = NID_organizationName;
  return 0;
#else
  env->die(env, stack, "NID_organizationName is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_organizationalUnitName(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_organizationalUnitName
  stack[0].ival = NID_organizationalUnitName;
  return 0;
#else
  env->die(env, stack, "NID_organizationalUnitName is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pbeWithMD2AndDES_CBC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pbeWithMD2AndDES_CBC
  stack[0].ival = NID_pbeWithMD2AndDES_CBC;
  return 0;
#else
  env->die(env, stack, "NID_pbeWithMD2AndDES_CBC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pbeWithMD2AndRC2_CBC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pbeWithMD2AndRC2_CBC
  stack[0].ival = NID_pbeWithMD2AndRC2_CBC;
  return 0;
#else
  env->die(env, stack, "NID_pbeWithMD2AndRC2_CBC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pbeWithMD5AndCast5_CBC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pbeWithMD5AndCast5_CBC
  stack[0].ival = NID_pbeWithMD5AndCast5_CBC;
  return 0;
#else
  env->die(env, stack, "NID_pbeWithMD5AndCast5_CBC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pbeWithMD5AndDES_CBC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pbeWithMD5AndDES_CBC
  stack[0].ival = NID_pbeWithMD5AndDES_CBC;
  return 0;
#else
  env->die(env, stack, "NID_pbeWithMD5AndDES_CBC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pbeWithMD5AndRC2_CBC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pbeWithMD5AndRC2_CBC
  stack[0].ival = NID_pbeWithMD5AndRC2_CBC;
  return 0;
#else
  env->die(env, stack, "NID_pbeWithMD5AndRC2_CBC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pbeWithSHA1AndDES_CBC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pbeWithSHA1AndDES_CBC
  stack[0].ival = NID_pbeWithSHA1AndDES_CBC;
  return 0;
#else
  env->die(env, stack, "NID_pbeWithSHA1AndDES_CBC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pbeWithSHA1AndRC2_CBC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pbeWithSHA1AndRC2_CBC
  stack[0].ival = NID_pbeWithSHA1AndRC2_CBC;
  return 0;
#else
  env->die(env, stack, "NID_pbeWithSHA1AndRC2_CBC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pbe_WithSHA1And128BitRC2_CBC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pbe_WithSHA1And128BitRC2_CBC
  stack[0].ival = NID_pbe_WithSHA1And128BitRC2_CBC;
  return 0;
#else
  env->die(env, stack, "NID_pbe_WithSHA1And128BitRC2_CBC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pbe_WithSHA1And128BitRC4(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pbe_WithSHA1And128BitRC4
  stack[0].ival = NID_pbe_WithSHA1And128BitRC4;
  return 0;
#else
  env->die(env, stack, "NID_pbe_WithSHA1And128BitRC4 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pbe_WithSHA1And2_Key_TripleDES_CBC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pbe_WithSHA1And2_Key_TripleDES_CBC
  stack[0].ival = NID_pbe_WithSHA1And2_Key_TripleDES_CBC;
  return 0;
#else
  env->die(env, stack, "NID_pbe_WithSHA1And2_Key_TripleDES_CBC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pbe_WithSHA1And3_Key_TripleDES_CBC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pbe_WithSHA1And3_Key_TripleDES_CBC
  stack[0].ival = NID_pbe_WithSHA1And3_Key_TripleDES_CBC;
  return 0;
#else
  env->die(env, stack, "NID_pbe_WithSHA1And3_Key_TripleDES_CBC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pbe_WithSHA1And40BitRC2_CBC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pbe_WithSHA1And40BitRC2_CBC
  stack[0].ival = NID_pbe_WithSHA1And40BitRC2_CBC;
  return 0;
#else
  env->die(env, stack, "NID_pbe_WithSHA1And40BitRC2_CBC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pbe_WithSHA1And40BitRC4(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pbe_WithSHA1And40BitRC4
  stack[0].ival = NID_pbe_WithSHA1And40BitRC4;
  return 0;
#else
  env->die(env, stack, "NID_pbe_WithSHA1And40BitRC4 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pbes2(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pbes2
  stack[0].ival = NID_pbes2;
  return 0;
#else
  env->die(env, stack, "NID_pbes2 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pbmac1(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pbmac1
  stack[0].ival = NID_pbmac1;
  return 0;
#else
  env->die(env, stack, "NID_pbmac1 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs
  stack[0].ival = NID_pkcs;
  return 0;
#else
  env->die(env, stack, "NID_pkcs is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs3(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs3
  stack[0].ival = NID_pkcs3;
  return 0;
#else
  env->die(env, stack, "NID_pkcs3 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs7(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs7
  stack[0].ival = NID_pkcs7;
  return 0;
#else
  env->die(env, stack, "NID_pkcs7 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs7_data(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs7_data
  stack[0].ival = NID_pkcs7_data;
  return 0;
#else
  env->die(env, stack, "NID_pkcs7_data is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs7_digest(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs7_digest
  stack[0].ival = NID_pkcs7_digest;
  return 0;
#else
  env->die(env, stack, "NID_pkcs7_digest is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs7_encrypted(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs7_encrypted
  stack[0].ival = NID_pkcs7_encrypted;
  return 0;
#else
  env->die(env, stack, "NID_pkcs7_encrypted is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs7_enveloped(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs7_enveloped
  stack[0].ival = NID_pkcs7_enveloped;
  return 0;
#else
  env->die(env, stack, "NID_pkcs7_enveloped is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs7_signed(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs7_signed
  stack[0].ival = NID_pkcs7_signed;
  return 0;
#else
  env->die(env, stack, "NID_pkcs7_signed is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs7_signedAndEnveloped(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs7_signedAndEnveloped
  stack[0].ival = NID_pkcs7_signedAndEnveloped;
  return 0;
#else
  env->die(env, stack, "NID_pkcs7_signedAndEnveloped is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs8ShroudedKeyBag(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs8ShroudedKeyBag
  stack[0].ival = NID_pkcs8ShroudedKeyBag;
  return 0;
#else
  env->die(env, stack, "NID_pkcs8ShroudedKeyBag is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs9(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs9
  stack[0].ival = NID_pkcs9;
  return 0;
#else
  env->die(env, stack, "NID_pkcs9 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs9_challengePassword(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs9_challengePassword
  stack[0].ival = NID_pkcs9_challengePassword;
  return 0;
#else
  env->die(env, stack, "NID_pkcs9_challengePassword is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs9_contentType(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs9_contentType
  stack[0].ival = NID_pkcs9_contentType;
  return 0;
#else
  env->die(env, stack, "NID_pkcs9_contentType is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs9_countersignature(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs9_countersignature
  stack[0].ival = NID_pkcs9_countersignature;
  return 0;
#else
  env->die(env, stack, "NID_pkcs9_countersignature is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs9_emailAddress(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs9_emailAddress
  stack[0].ival = NID_pkcs9_emailAddress;
  return 0;
#else
  env->die(env, stack, "NID_pkcs9_emailAddress is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs9_extCertAttributes(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs9_extCertAttributes
  stack[0].ival = NID_pkcs9_extCertAttributes;
  return 0;
#else
  env->die(env, stack, "NID_pkcs9_extCertAttributes is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs9_messageDigest(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs9_messageDigest
  stack[0].ival = NID_pkcs9_messageDigest;
  return 0;
#else
  env->die(env, stack, "NID_pkcs9_messageDigest is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs9_signingTime(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs9_signingTime
  stack[0].ival = NID_pkcs9_signingTime;
  return 0;
#else
  env->die(env, stack, "NID_pkcs9_signingTime is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs9_unstructuredAddress(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs9_unstructuredAddress
  stack[0].ival = NID_pkcs9_unstructuredAddress;
  return 0;
#else
  env->die(env, stack, "NID_pkcs9_unstructuredAddress is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_pkcs9_unstructuredName(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_pkcs9_unstructuredName
  stack[0].ival = NID_pkcs9_unstructuredName;
  return 0;
#else
  env->die(env, stack, "NID_pkcs9_unstructuredName is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_private_key_usage_period(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_private_key_usage_period
  stack[0].ival = NID_private_key_usage_period;
  return 0;
#else
  env->die(env, stack, "NID_private_key_usage_period is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_rc2_40_cbc(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_rc2_40_cbc
  stack[0].ival = NID_rc2_40_cbc;
  return 0;
#else
  env->die(env, stack, "NID_rc2_40_cbc is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_rc2_64_cbc(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_rc2_64_cbc
  stack[0].ival = NID_rc2_64_cbc;
  return 0;
#else
  env->die(env, stack, "NID_rc2_64_cbc is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_rc2_cbc(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_rc2_cbc
  stack[0].ival = NID_rc2_cbc;
  return 0;
#else
  env->die(env, stack, "NID_rc2_cbc is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_rc2_cfb64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_rc2_cfb64
  stack[0].ival = NID_rc2_cfb64;
  return 0;
#else
  env->die(env, stack, "NID_rc2_cfb64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_rc2_ecb(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_rc2_ecb
  stack[0].ival = NID_rc2_ecb;
  return 0;
#else
  env->die(env, stack, "NID_rc2_ecb is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_rc2_ofb64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_rc2_ofb64
  stack[0].ival = NID_rc2_ofb64;
  return 0;
#else
  env->die(env, stack, "NID_rc2_ofb64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_rc4(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_rc4
  stack[0].ival = NID_rc4;
  return 0;
#else
  env->die(env, stack, "NID_rc4 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_rc4_40(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_rc4_40
  stack[0].ival = NID_rc4_40;
  return 0;
#else
  env->die(env, stack, "NID_rc4_40 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_rc5_cbc(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_rc5_cbc
  stack[0].ival = NID_rc5_cbc;
  return 0;
#else
  env->die(env, stack, "NID_rc5_cbc is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_rc5_cfb64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_rc5_cfb64
  stack[0].ival = NID_rc5_cfb64;
  return 0;
#else
  env->die(env, stack, "NID_rc5_cfb64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_rc5_ecb(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_rc5_ecb
  stack[0].ival = NID_rc5_ecb;
  return 0;
#else
  env->die(env, stack, "NID_rc5_ecb is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_rc5_ofb64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_rc5_ofb64
  stack[0].ival = NID_rc5_ofb64;
  return 0;
#else
  env->die(env, stack, "NID_rc5_ofb64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_ripemd160(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_ripemd160
  stack[0].ival = NID_ripemd160;
  return 0;
#else
  env->die(env, stack, "NID_ripemd160 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_ripemd160WithRSA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_ripemd160WithRSA
  stack[0].ival = NID_ripemd160WithRSA;
  return 0;
#else
  env->die(env, stack, "NID_ripemd160WithRSA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_rle_compression(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_rle_compression
  stack[0].ival = NID_rle_compression;
  return 0;
#else
  env->die(env, stack, "NID_rle_compression is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_rsa(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_rsa
  stack[0].ival = NID_rsa;
  return 0;
#else
  env->die(env, stack, "NID_rsa is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_rsaEncryption(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_rsaEncryption
  stack[0].ival = NID_rsaEncryption;
  return 0;
#else
  env->die(env, stack, "NID_rsaEncryption is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_rsadsi(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_rsadsi
  stack[0].ival = NID_rsadsi;
  return 0;
#else
  env->die(env, stack, "NID_rsadsi is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_safeContentsBag(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_safeContentsBag
  stack[0].ival = NID_safeContentsBag;
  return 0;
#else
  env->die(env, stack, "NID_safeContentsBag is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_sdsiCertificate(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_sdsiCertificate
  stack[0].ival = NID_sdsiCertificate;
  return 0;
#else
  env->die(env, stack, "NID_sdsiCertificate is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_secretBag(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_secretBag
  stack[0].ival = NID_secretBag;
  return 0;
#else
  env->die(env, stack, "NID_secretBag is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_serialNumber(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_serialNumber
  stack[0].ival = NID_serialNumber;
  return 0;
#else
  env->die(env, stack, "NID_serialNumber is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_server_auth(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_server_auth
  stack[0].ival = NID_server_auth;
  return 0;
#else
  env->die(env, stack, "NID_server_auth is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_sha(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_sha
  stack[0].ival = NID_sha;
  return 0;
#else
  env->die(env, stack, "NID_sha is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_sha1(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_sha1
  stack[0].ival = NID_sha1;
  return 0;
#else
  env->die(env, stack, "NID_sha1 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_sha1WithRSA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_sha1WithRSA
  stack[0].ival = NID_sha1WithRSA;
  return 0;
#else
  env->die(env, stack, "NID_sha1WithRSA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_sha1WithRSAEncryption(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_sha1WithRSAEncryption
  stack[0].ival = NID_sha1WithRSAEncryption;
  return 0;
#else
  env->die(env, stack, "NID_sha1WithRSAEncryption is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_shaWithRSAEncryption(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_shaWithRSAEncryption
  stack[0].ival = NID_shaWithRSAEncryption;
  return 0;
#else
  env->die(env, stack, "NID_shaWithRSAEncryption is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_stateOrProvinceName(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_stateOrProvinceName
  stack[0].ival = NID_stateOrProvinceName;
  return 0;
#else
  env->die(env, stack, "NID_stateOrProvinceName is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_subject_alt_name(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_subject_alt_name
  stack[0].ival = NID_subject_alt_name;
  return 0;
#else
  env->die(env, stack, "NID_subject_alt_name is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_subject_key_identifier(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_subject_key_identifier
  stack[0].ival = NID_subject_key_identifier;
  return 0;
#else
  env->die(env, stack, "NID_subject_key_identifier is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_surname(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_surname
  stack[0].ival = NID_surname;
  return 0;
#else
  env->die(env, stack, "NID_surname is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_sxnet(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_sxnet
  stack[0].ival = NID_sxnet;
  return 0;
#else
  env->die(env, stack, "NID_sxnet is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_time_stamp(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_time_stamp
  stack[0].ival = NID_time_stamp;
  return 0;
#else
  env->die(env, stack, "NID_time_stamp is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_title(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_title
  stack[0].ival = NID_title;
  return 0;
#else
  env->die(env, stack, "NID_title is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_undef(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_undef
  stack[0].ival = NID_undef;
  return 0;
#else
  env->die(env, stack, "NID_undef is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_uniqueIdentifier(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_uniqueIdentifier
  stack[0].ival = NID_uniqueIdentifier;
  return 0;
#else
  env->die(env, stack, "NID_uniqueIdentifier is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_x509Certificate(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_x509Certificate
  stack[0].ival = NID_x509Certificate;
  return 0;
#else
  env->die(env, stack, "NID_x509Certificate is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_x509Crl(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_x509Crl
  stack[0].ival = NID_x509Crl;
  return 0;
#else
  env->die(env, stack, "NID_x509Crl is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__NID_zlib_compression(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NID_zlib_compression
  stack[0].ival = NID_zlib_compression;
  return 0;
#else
  env->die(env, stack, "NID_zlib_compression is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OCSP_RESPONSE_STATUS_INTERNALERROR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OCSP_RESPONSE_STATUS_INTERNALERROR
  stack[0].ival = OCSP_RESPONSE_STATUS_INTERNALERROR;
  return 0;
#else
  env->die(env, stack, "OCSP_RESPONSE_STATUS_INTERNALERROR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OCSP_RESPONSE_STATUS_MALFORMEDREQUEST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OCSP_RESPONSE_STATUS_MALFORMEDREQUEST
  stack[0].ival = OCSP_RESPONSE_STATUS_MALFORMEDREQUEST;
  return 0;
#else
  env->die(env, stack, "OCSP_RESPONSE_STATUS_MALFORMEDREQUEST is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OCSP_RESPONSE_STATUS_SIGREQUIRED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OCSP_RESPONSE_STATUS_SIGREQUIRED
  stack[0].ival = OCSP_RESPONSE_STATUS_SIGREQUIRED;
  return 0;
#else
  env->die(env, stack, "OCSP_RESPONSE_STATUS_SIGREQUIRED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OCSP_RESPONSE_STATUS_SUCCESSFUL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OCSP_RESPONSE_STATUS_SUCCESSFUL
  stack[0].ival = OCSP_RESPONSE_STATUS_SUCCESSFUL;
  return 0;
#else
  env->die(env, stack, "OCSP_RESPONSE_STATUS_SUCCESSFUL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OCSP_RESPONSE_STATUS_TRYLATER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OCSP_RESPONSE_STATUS_TRYLATER
  stack[0].ival = OCSP_RESPONSE_STATUS_TRYLATER;
  return 0;
#else
  env->die(env, stack, "OCSP_RESPONSE_STATUS_TRYLATER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OCSP_RESPONSE_STATUS_UNAUTHORIZED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OCSP_RESPONSE_STATUS_UNAUTHORIZED
  stack[0].ival = OCSP_RESPONSE_STATUS_UNAUTHORIZED;
  return 0;
#else
  env->die(env, stack, "OCSP_RESPONSE_STATUS_UNAUTHORIZED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_BUILT_ON(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_BUILT_ON
  stack[0].ival = OPENSSL_BUILT_ON;
  return 0;
#else
  env->die(env, stack, "OPENSSL_BUILT_ON is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_CFLAGS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_CFLAGS
  stack[0].ival = OPENSSL_CFLAGS;
  return 0;
#else
  env->die(env, stack, "OPENSSL_CFLAGS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_CPU_INFO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_CPU_INFO
  stack[0].ival = OPENSSL_CPU_INFO;
  return 0;
#else
  env->die(env, stack, "OPENSSL_CPU_INFO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_DIR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_DIR
  stack[0].ival = OPENSSL_DIR;
  return 0;
#else
  env->die(env, stack, "OPENSSL_DIR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_ENGINES_DIR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_ENGINES_DIR
  stack[0].ival = OPENSSL_ENGINES_DIR;
  return 0;
#else
  env->die(env, stack, "OPENSSL_ENGINES_DIR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_FULL_VERSION_STRING(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_FULL_VERSION_STRING
  stack[0].ival = OPENSSL_FULL_VERSION_STRING;
  return 0;
#else
  env->die(env, stack, "OPENSSL_FULL_VERSION_STRING is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INFO_CONFIG_DIR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INFO_CONFIG_DIR
  stack[0].ival = OPENSSL_INFO_CONFIG_DIR;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INFO_CONFIG_DIR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INFO_CPU_SETTINGS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INFO_CPU_SETTINGS
  stack[0].ival = OPENSSL_INFO_CPU_SETTINGS;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INFO_CPU_SETTINGS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INFO_DIR_FILENAME_SEPARATOR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INFO_DIR_FILENAME_SEPARATOR
  stack[0].ival = OPENSSL_INFO_DIR_FILENAME_SEPARATOR;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INFO_DIR_FILENAME_SEPARATOR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INFO_DSO_EXTENSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INFO_DSO_EXTENSION
  stack[0].ival = OPENSSL_INFO_DSO_EXTENSION;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INFO_DSO_EXTENSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INFO_ENGINES_DIR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INFO_ENGINES_DIR
  stack[0].ival = OPENSSL_INFO_ENGINES_DIR;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INFO_ENGINES_DIR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INFO_LIST_SEPARATOR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INFO_LIST_SEPARATOR
  stack[0].ival = OPENSSL_INFO_LIST_SEPARATOR;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INFO_LIST_SEPARATOR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INFO_MODULES_DIR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INFO_MODULES_DIR
  stack[0].ival = OPENSSL_INFO_MODULES_DIR;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INFO_MODULES_DIR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INFO_SEED_SOURCE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INFO_SEED_SOURCE
  stack[0].ival = OPENSSL_INFO_SEED_SOURCE;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INFO_SEED_SOURCE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_MODULES_DIR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_MODULES_DIR
  stack[0].ival = OPENSSL_MODULES_DIR;
  return 0;
#else
  env->die(env, stack, "OPENSSL_MODULES_DIR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_PLATFORM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_PLATFORM
  stack[0].ival = OPENSSL_PLATFORM;
  return 0;
#else
  env->die(env, stack, "OPENSSL_PLATFORM is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_VERSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_VERSION
  stack[0].ival = OPENSSL_VERSION;
  return 0;
#else
  env->die(env, stack, "OPENSSL_VERSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_VERSION_MAJOR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_VERSION_MAJOR
  stack[0].ival = OPENSSL_VERSION_MAJOR;
  return 0;
#else
  env->die(env, stack, "OPENSSL_VERSION_MAJOR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_VERSION_MINOR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_VERSION_MINOR
  stack[0].ival = OPENSSL_VERSION_MINOR;
  return 0;
#else
  env->die(env, stack, "OPENSSL_VERSION_MINOR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_VERSION_NUMBER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_VERSION_NUMBER
  stack[0].ival = OPENSSL_VERSION_NUMBER;
  return 0;
#else
  env->die(env, stack, "OPENSSL_VERSION_NUMBER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_VERSION_PATCH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_VERSION_PATCH
  stack[0].ival = OPENSSL_VERSION_PATCH;
  return 0;
#else
  env->die(env, stack, "OPENSSL_VERSION_PATCH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_VERSION_STRING(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_VERSION_STRING
  stack[0].ival = OPENSSL_VERSION_STRING;
  return 0;
#else
  env->die(env, stack, "OPENSSL_VERSION_STRING is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__RSA_3(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef RSA_3
  stack[0].ival = RSA_3;
  return 0;
#else
  env->die(env, stack, "RSA_3 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__RSA_F4(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef RSA_F4
  stack[0].ival = RSA_F4;
  return 0;
#else
  env->die(env, stack, "RSA_F4 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL2_MT_CLIENT_CERTIFICATE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL2_MT_CLIENT_CERTIFICATE
  stack[0].ival = SSL2_MT_CLIENT_CERTIFICATE;
  return 0;
#else
  env->die(env, stack, "SSL2_MT_CLIENT_CERTIFICATE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL2_MT_CLIENT_FINISHED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL2_MT_CLIENT_FINISHED
  stack[0].ival = SSL2_MT_CLIENT_FINISHED;
  return 0;
#else
  env->die(env, stack, "SSL2_MT_CLIENT_FINISHED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL2_MT_CLIENT_HELLO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL2_MT_CLIENT_HELLO
  stack[0].ival = SSL2_MT_CLIENT_HELLO;
  return 0;
#else
  env->die(env, stack, "SSL2_MT_CLIENT_HELLO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL2_MT_CLIENT_MASTER_KEY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL2_MT_CLIENT_MASTER_KEY
  stack[0].ival = SSL2_MT_CLIENT_MASTER_KEY;
  return 0;
#else
  env->die(env, stack, "SSL2_MT_CLIENT_MASTER_KEY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL2_MT_ERROR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL2_MT_ERROR
  stack[0].ival = SSL2_MT_ERROR;
  return 0;
#else
  env->die(env, stack, "SSL2_MT_ERROR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL2_MT_REQUEST_CERTIFICATE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL2_MT_REQUEST_CERTIFICATE
  stack[0].ival = SSL2_MT_REQUEST_CERTIFICATE;
  return 0;
#else
  env->die(env, stack, "SSL2_MT_REQUEST_CERTIFICATE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL2_MT_SERVER_FINISHED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL2_MT_SERVER_FINISHED
  stack[0].ival = SSL2_MT_SERVER_FINISHED;
  return 0;
#else
  env->die(env, stack, "SSL2_MT_SERVER_FINISHED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL2_MT_SERVER_HELLO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL2_MT_SERVER_HELLO
  stack[0].ival = SSL2_MT_SERVER_HELLO;
  return 0;
#else
  env->die(env, stack, "SSL2_MT_SERVER_HELLO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL2_MT_SERVER_VERIFY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL2_MT_SERVER_VERIFY
  stack[0].ival = SSL2_MT_SERVER_VERIFY;
  return 0;
#else
  env->die(env, stack, "SSL2_MT_SERVER_VERIFY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL2_VERSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL2_VERSION
  stack[0].ival = SSL2_VERSION;
  return 0;
#else
  env->die(env, stack, "SSL2_VERSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_CCS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_CCS
  stack[0].ival = SSL3_MT_CCS;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_CCS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_CERTIFICATE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_CERTIFICATE
  stack[0].ival = SSL3_MT_CERTIFICATE;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_CERTIFICATE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_CERTIFICATE_REQUEST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_CERTIFICATE_REQUEST
  stack[0].ival = SSL3_MT_CERTIFICATE_REQUEST;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_CERTIFICATE_REQUEST is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_CERTIFICATE_STATUS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_CERTIFICATE_STATUS
  stack[0].ival = SSL3_MT_CERTIFICATE_STATUS;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_CERTIFICATE_STATUS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_CERTIFICATE_URL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_CERTIFICATE_URL
  stack[0].ival = SSL3_MT_CERTIFICATE_URL;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_CERTIFICATE_URL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_CERTIFICATE_VERIFY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_CERTIFICATE_VERIFY
  stack[0].ival = SSL3_MT_CERTIFICATE_VERIFY;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_CERTIFICATE_VERIFY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_CHANGE_CIPHER_SPEC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_CHANGE_CIPHER_SPEC
  stack[0].ival = SSL3_MT_CHANGE_CIPHER_SPEC;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_CHANGE_CIPHER_SPEC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_CLIENT_HELLO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_CLIENT_HELLO
  stack[0].ival = SSL3_MT_CLIENT_HELLO;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_CLIENT_HELLO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_CLIENT_KEY_EXCHANGE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_CLIENT_KEY_EXCHANGE
  stack[0].ival = SSL3_MT_CLIENT_KEY_EXCHANGE;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_CLIENT_KEY_EXCHANGE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_ENCRYPTED_EXTENSIONS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_ENCRYPTED_EXTENSIONS
  stack[0].ival = SSL3_MT_ENCRYPTED_EXTENSIONS;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_ENCRYPTED_EXTENSIONS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_END_OF_EARLY_DATA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_END_OF_EARLY_DATA
  stack[0].ival = SSL3_MT_END_OF_EARLY_DATA;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_END_OF_EARLY_DATA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_FINISHED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_FINISHED
  stack[0].ival = SSL3_MT_FINISHED;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_FINISHED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_HELLO_REQUEST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_HELLO_REQUEST
  stack[0].ival = SSL3_MT_HELLO_REQUEST;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_HELLO_REQUEST is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_KEY_UPDATE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_KEY_UPDATE
  stack[0].ival = SSL3_MT_KEY_UPDATE;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_KEY_UPDATE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_MESSAGE_HASH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_MESSAGE_HASH
  stack[0].ival = SSL3_MT_MESSAGE_HASH;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_MESSAGE_HASH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_NEWSESSION_TICKET(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_NEWSESSION_TICKET
  stack[0].ival = SSL3_MT_NEWSESSION_TICKET;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_NEWSESSION_TICKET is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_NEXT_PROTO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_NEXT_PROTO
  stack[0].ival = SSL3_MT_NEXT_PROTO;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_NEXT_PROTO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_SERVER_DONE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_SERVER_DONE
  stack[0].ival = SSL3_MT_SERVER_DONE;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_SERVER_DONE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_SERVER_HELLO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_SERVER_HELLO
  stack[0].ival = SSL3_MT_SERVER_HELLO;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_SERVER_HELLO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_SERVER_KEY_EXCHANGE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_SERVER_KEY_EXCHANGE
  stack[0].ival = SSL3_MT_SERVER_KEY_EXCHANGE;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_SERVER_KEY_EXCHANGE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_MT_SUPPLEMENTAL_DATA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_MT_SUPPLEMENTAL_DATA
  stack[0].ival = SSL3_MT_SUPPLEMENTAL_DATA;
  return 0;
#else
  env->die(env, stack, "SSL3_MT_SUPPLEMENTAL_DATA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_RT_ALERT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_RT_ALERT
  stack[0].ival = SSL3_RT_ALERT;
  return 0;
#else
  env->die(env, stack, "SSL3_RT_ALERT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_RT_APPLICATION_DATA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_RT_APPLICATION_DATA
  stack[0].ival = SSL3_RT_APPLICATION_DATA;
  return 0;
#else
  env->die(env, stack, "SSL3_RT_APPLICATION_DATA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_RT_CHANGE_CIPHER_SPEC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_RT_CHANGE_CIPHER_SPEC
  stack[0].ival = SSL3_RT_CHANGE_CIPHER_SPEC;
  return 0;
#else
  env->die(env, stack, "SSL3_RT_CHANGE_CIPHER_SPEC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_RT_HANDSHAKE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_RT_HANDSHAKE
  stack[0].ival = SSL3_RT_HANDSHAKE;
  return 0;
#else
  env->die(env, stack, "SSL3_RT_HANDSHAKE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_RT_HEADER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_RT_HEADER
  stack[0].ival = SSL3_RT_HEADER;
  return 0;
#else
  env->die(env, stack, "SSL3_RT_HEADER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_RT_INNER_CONTENT_TYPE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_RT_INNER_CONTENT_TYPE
  stack[0].ival = SSL3_RT_INNER_CONTENT_TYPE;
  return 0;
#else
  env->die(env, stack, "SSL3_RT_INNER_CONTENT_TYPE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL3_VERSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL3_VERSION
  stack[0].ival = SSL3_VERSION;
  return 0;
#else
  env->die(env, stack, "SSL3_VERSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSLEAY_BUILT_ON(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSLEAY_BUILT_ON
  stack[0].ival = SSLEAY_BUILT_ON;
  return 0;
#else
  env->die(env, stack, "SSLEAY_BUILT_ON is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSLEAY_CFLAGS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSLEAY_CFLAGS
  stack[0].ival = SSLEAY_CFLAGS;
  return 0;
#else
  env->die(env, stack, "SSLEAY_CFLAGS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSLEAY_DIR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSLEAY_DIR
  stack[0].ival = SSLEAY_DIR;
  return 0;
#else
  env->die(env, stack, "SSLEAY_DIR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSLEAY_PLATFORM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSLEAY_PLATFORM
  stack[0].ival = SSLEAY_PLATFORM;
  return 0;
#else
  env->die(env, stack, "SSLEAY_PLATFORM is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSLEAY_VERSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSLEAY_VERSION
  stack[0].ival = SSLEAY_VERSION;
  return 0;
#else
  env->die(env, stack, "SSLEAY_VERSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_CB_ACCEPT_EXIT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_CB_ACCEPT_EXIT
  stack[0].ival = SSL_CB_ACCEPT_EXIT;
  return 0;
#else
  env->die(env, stack, "SSL_CB_ACCEPT_EXIT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_CB_ACCEPT_LOOP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_CB_ACCEPT_LOOP
  stack[0].ival = SSL_CB_ACCEPT_LOOP;
  return 0;
#else
  env->die(env, stack, "SSL_CB_ACCEPT_LOOP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_CB_ALERT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_CB_ALERT
  stack[0].ival = SSL_CB_ALERT;
  return 0;
#else
  env->die(env, stack, "SSL_CB_ALERT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_CB_CONNECT_EXIT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_CB_CONNECT_EXIT
  stack[0].ival = SSL_CB_CONNECT_EXIT;
  return 0;
#else
  env->die(env, stack, "SSL_CB_CONNECT_EXIT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_CB_CONNECT_LOOP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_CB_CONNECT_LOOP
  stack[0].ival = SSL_CB_CONNECT_LOOP;
  return 0;
#else
  env->die(env, stack, "SSL_CB_CONNECT_LOOP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_CB_EXIT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_CB_EXIT
  stack[0].ival = SSL_CB_EXIT;
  return 0;
#else
  env->die(env, stack, "SSL_CB_EXIT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_CB_HANDSHAKE_DONE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_CB_HANDSHAKE_DONE
  stack[0].ival = SSL_CB_HANDSHAKE_DONE;
  return 0;
#else
  env->die(env, stack, "SSL_CB_HANDSHAKE_DONE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_CB_HANDSHAKE_START(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_CB_HANDSHAKE_START
  stack[0].ival = SSL_CB_HANDSHAKE_START;
  return 0;
#else
  env->die(env, stack, "SSL_CB_HANDSHAKE_START is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_CB_LOOP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_CB_LOOP
  stack[0].ival = SSL_CB_LOOP;
  return 0;
#else
  env->die(env, stack, "SSL_CB_LOOP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_CB_READ(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_CB_READ
  stack[0].ival = SSL_CB_READ;
  return 0;
#else
  env->die(env, stack, "SSL_CB_READ is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_CB_READ_ALERT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_CB_READ_ALERT
  stack[0].ival = SSL_CB_READ_ALERT;
  return 0;
#else
  env->die(env, stack, "SSL_CB_READ_ALERT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_CB_WRITE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_CB_WRITE
  stack[0].ival = SSL_CB_WRITE;
  return 0;
#else
  env->die(env, stack, "SSL_CB_WRITE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_CB_WRITE_ALERT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_CB_WRITE_ALERT
  stack[0].ival = SSL_CB_WRITE_ALERT;
  return 0;
#else
  env->die(env, stack, "SSL_CB_WRITE_ALERT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_ERROR_NONE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_ERROR_NONE
  stack[0].ival = SSL_ERROR_NONE;
  return 0;
#else
  env->die(env, stack, "SSL_ERROR_NONE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_ERROR_SSL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_ERROR_SSL
  stack[0].ival = SSL_ERROR_SSL;
  return 0;
#else
  env->die(env, stack, "SSL_ERROR_SSL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_ERROR_SYSCALL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_ERROR_SYSCALL
  stack[0].ival = SSL_ERROR_SYSCALL;
  return 0;
#else
  env->die(env, stack, "SSL_ERROR_SYSCALL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_ERROR_WANT_ACCEPT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_ERROR_WANT_ACCEPT
  stack[0].ival = SSL_ERROR_WANT_ACCEPT;
  return 0;
#else
  env->die(env, stack, "SSL_ERROR_WANT_ACCEPT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_ERROR_WANT_CONNECT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_ERROR_WANT_CONNECT
  stack[0].ival = SSL_ERROR_WANT_CONNECT;
  return 0;
#else
  env->die(env, stack, "SSL_ERROR_WANT_CONNECT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_ERROR_WANT_READ(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_ERROR_WANT_READ
  stack[0].ival = SSL_ERROR_WANT_READ;
  return 0;
#else
  env->die(env, stack, "SSL_ERROR_WANT_READ is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_ERROR_WANT_WRITE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_ERROR_WANT_WRITE
  stack[0].ival = SSL_ERROR_WANT_WRITE;
  return 0;
#else
  env->die(env, stack, "SSL_ERROR_WANT_WRITE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_ERROR_WANT_X509_LOOKUP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_ERROR_WANT_X509_LOOKUP
  stack[0].ival = SSL_ERROR_WANT_X509_LOOKUP;
  return 0;
#else
  env->die(env, stack, "SSL_ERROR_WANT_X509_LOOKUP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_ERROR_ZERO_RETURN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_ERROR_ZERO_RETURN
  stack[0].ival = SSL_ERROR_ZERO_RETURN;
  return 0;
#else
  env->die(env, stack, "SSL_ERROR_ZERO_RETURN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_FILETYPE_ASN1(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_FILETYPE_ASN1
  stack[0].ival = SSL_FILETYPE_ASN1;
  return 0;
#else
  env->die(env, stack, "SSL_FILETYPE_ASN1 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_FILETYPE_PEM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_FILETYPE_PEM
  stack[0].ival = SSL_FILETYPE_PEM;
  return 0;
#else
  env->die(env, stack, "SSL_FILETYPE_PEM is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_CLIENT_CERTIFICATE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_CLIENT_CERTIFICATE
  stack[0].ival = SSL_F_CLIENT_CERTIFICATE;
  return 0;
#else
  env->die(env, stack, "SSL_F_CLIENT_CERTIFICATE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_CLIENT_HELLO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_CLIENT_HELLO
  stack[0].ival = SSL_F_CLIENT_HELLO;
  return 0;
#else
  env->die(env, stack, "SSL_F_CLIENT_HELLO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_CLIENT_MASTER_KEY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_CLIENT_MASTER_KEY
  stack[0].ival = SSL_F_CLIENT_MASTER_KEY;
  return 0;
#else
  env->die(env, stack, "SSL_F_CLIENT_MASTER_KEY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_D2I_SSL_SESSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_D2I_SSL_SESSION
  stack[0].ival = SSL_F_D2I_SSL_SESSION;
  return 0;
#else
  env->die(env, stack, "SSL_F_D2I_SSL_SESSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_GET_CLIENT_FINISHED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_GET_CLIENT_FINISHED
  stack[0].ival = SSL_F_GET_CLIENT_FINISHED;
  return 0;
#else
  env->die(env, stack, "SSL_F_GET_CLIENT_FINISHED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_GET_CLIENT_HELLO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_GET_CLIENT_HELLO
  stack[0].ival = SSL_F_GET_CLIENT_HELLO;
  return 0;
#else
  env->die(env, stack, "SSL_F_GET_CLIENT_HELLO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_GET_CLIENT_MASTER_KEY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_GET_CLIENT_MASTER_KEY
  stack[0].ival = SSL_F_GET_CLIENT_MASTER_KEY;
  return 0;
#else
  env->die(env, stack, "SSL_F_GET_CLIENT_MASTER_KEY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_GET_SERVER_FINISHED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_GET_SERVER_FINISHED
  stack[0].ival = SSL_F_GET_SERVER_FINISHED;
  return 0;
#else
  env->die(env, stack, "SSL_F_GET_SERVER_FINISHED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_GET_SERVER_HELLO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_GET_SERVER_HELLO
  stack[0].ival = SSL_F_GET_SERVER_HELLO;
  return 0;
#else
  env->die(env, stack, "SSL_F_GET_SERVER_HELLO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_GET_SERVER_VERIFY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_GET_SERVER_VERIFY
  stack[0].ival = SSL_F_GET_SERVER_VERIFY;
  return 0;
#else
  env->die(env, stack, "SSL_F_GET_SERVER_VERIFY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_I2D_SSL_SESSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_I2D_SSL_SESSION
  stack[0].ival = SSL_F_I2D_SSL_SESSION;
  return 0;
#else
  env->die(env, stack, "SSL_F_I2D_SSL_SESSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_READ_N(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_READ_N
  stack[0].ival = SSL_F_READ_N;
  return 0;
#else
  env->die(env, stack, "SSL_F_READ_N is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_REQUEST_CERTIFICATE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_REQUEST_CERTIFICATE
  stack[0].ival = SSL_F_REQUEST_CERTIFICATE;
  return 0;
#else
  env->die(env, stack, "SSL_F_REQUEST_CERTIFICATE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SERVER_HELLO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SERVER_HELLO
  stack[0].ival = SSL_F_SERVER_HELLO;
  return 0;
#else
  env->die(env, stack, "SSL_F_SERVER_HELLO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_CERT_NEW(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_CERT_NEW
  stack[0].ival = SSL_F_SSL_CERT_NEW;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_CERT_NEW is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_GET_NEW_SESSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_GET_NEW_SESSION
  stack[0].ival = SSL_F_SSL_GET_NEW_SESSION;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_GET_NEW_SESSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_NEW(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_NEW
  stack[0].ival = SSL_F_SSL_NEW;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_NEW is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_READ(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_READ
  stack[0].ival = SSL_F_SSL_READ;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_READ is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_RSA_PRIVATE_DECRYPT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_RSA_PRIVATE_DECRYPT
  stack[0].ival = SSL_F_SSL_RSA_PRIVATE_DECRYPT;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_RSA_PRIVATE_DECRYPT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_RSA_PUBLIC_ENCRYPT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_RSA_PUBLIC_ENCRYPT
  stack[0].ival = SSL_F_SSL_RSA_PUBLIC_ENCRYPT;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_RSA_PUBLIC_ENCRYPT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_SESSION_NEW(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_SESSION_NEW
  stack[0].ival = SSL_F_SSL_SESSION_NEW;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_SESSION_NEW is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_SESSION_PRINT_FP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_SESSION_PRINT_FP
  stack[0].ival = SSL_F_SSL_SESSION_PRINT_FP;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_SESSION_PRINT_FP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_SET_FD(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_SET_FD
  stack[0].ival = SSL_F_SSL_SET_FD;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_SET_FD is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_SET_RFD(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_SET_RFD
  stack[0].ival = SSL_F_SSL_SET_RFD;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_SET_RFD is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_SET_WFD(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_SET_WFD
  stack[0].ival = SSL_F_SSL_SET_WFD;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_SET_WFD is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_USE_CERTIFICATE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_USE_CERTIFICATE
  stack[0].ival = SSL_F_SSL_USE_CERTIFICATE;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_USE_CERTIFICATE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_USE_CERTIFICATE_ASN1(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_USE_CERTIFICATE_ASN1
  stack[0].ival = SSL_F_SSL_USE_CERTIFICATE_ASN1;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_USE_CERTIFICATE_ASN1 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_USE_CERTIFICATE_FILE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_USE_CERTIFICATE_FILE
  stack[0].ival = SSL_F_SSL_USE_CERTIFICATE_FILE;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_USE_CERTIFICATE_FILE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_USE_PRIVATEKEY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_USE_PRIVATEKEY
  stack[0].ival = SSL_F_SSL_USE_PRIVATEKEY;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_USE_PRIVATEKEY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_USE_PRIVATEKEY_ASN1(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_USE_PRIVATEKEY_ASN1
  stack[0].ival = SSL_F_SSL_USE_PRIVATEKEY_ASN1;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_USE_PRIVATEKEY_ASN1 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_USE_PRIVATEKEY_FILE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_USE_PRIVATEKEY_FILE
  stack[0].ival = SSL_F_SSL_USE_PRIVATEKEY_FILE;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_USE_PRIVATEKEY_FILE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_USE_RSAPRIVATEKEY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_USE_RSAPRIVATEKEY
  stack[0].ival = SSL_F_SSL_USE_RSAPRIVATEKEY;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_USE_RSAPRIVATEKEY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_USE_RSAPRIVATEKEY_ASN1(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_USE_RSAPRIVATEKEY_ASN1
  stack[0].ival = SSL_F_SSL_USE_RSAPRIVATEKEY_ASN1;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_USE_RSAPRIVATEKEY_ASN1 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_SSL_USE_RSAPRIVATEKEY_FILE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_SSL_USE_RSAPRIVATEKEY_FILE
  stack[0].ival = SSL_F_SSL_USE_RSAPRIVATEKEY_FILE;
  return 0;
#else
  env->die(env, stack, "SSL_F_SSL_USE_RSAPRIVATEKEY_FILE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_F_WRITE_PENDING(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_F_WRITE_PENDING
  stack[0].ival = SSL_F_WRITE_PENDING;
  return 0;
#else
  env->die(env, stack, "SSL_F_WRITE_PENDING is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_MIN_RSA_MODULUS_LENGTH_IN_BYTES(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_MIN_RSA_MODULUS_LENGTH_IN_BYTES
  stack[0].ival = SSL_MIN_RSA_MODULUS_LENGTH_IN_BYTES;
  return 0;
#else
  env->die(env, stack, "SSL_MIN_RSA_MODULUS_LENGTH_IN_BYTES is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER
  stack[0].ival = SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER;
  return 0;
#else
  env->die(env, stack, "SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_MODE_AUTO_RETRY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_MODE_AUTO_RETRY
  stack[0].ival = SSL_MODE_AUTO_RETRY;
  return 0;
#else
  env->die(env, stack, "SSL_MODE_AUTO_RETRY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_MODE_ENABLE_PARTIAL_WRITE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_MODE_ENABLE_PARTIAL_WRITE
  stack[0].ival = SSL_MODE_ENABLE_PARTIAL_WRITE;
  return 0;
#else
  env->die(env, stack, "SSL_MODE_ENABLE_PARTIAL_WRITE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_MODE_RELEASE_BUFFERS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_MODE_RELEASE_BUFFERS
  stack[0].ival = SSL_MODE_RELEASE_BUFFERS;
  return 0;
#else
  env->die(env, stack, "SSL_MODE_RELEASE_BUFFERS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_NOTHING(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_NOTHING
  stack[0].ival = SSL_NOTHING;
  return 0;
#else
  env->die(env, stack, "SSL_NOTHING is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_ALL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_ALL
  stack[0].ival = SSL_OP_ALL;
  return 0;
#else
  env->die(env, stack, "SSL_OP_ALL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_ALLOW_NO_DHE_KEX(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_ALLOW_NO_DHE_KEX
  stack[0].ival = SSL_OP_ALLOW_NO_DHE_KEX;
  return 0;
#else
  env->die(env, stack, "SSL_OP_ALLOW_NO_DHE_KEX is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_ALLOW_UNSAFE_LEGACY_RENEGOTIATION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_ALLOW_UNSAFE_LEGACY_RENEGOTIATION
  stack[0].ival = SSL_OP_ALLOW_UNSAFE_LEGACY_RENEGOTIATION;
  return 0;
#else
  env->die(env, stack, "SSL_OP_ALLOW_UNSAFE_LEGACY_RENEGOTIATION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_CIPHER_SERVER_PREFERENCE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_CIPHER_SERVER_PREFERENCE
  stack[0].ival = SSL_OP_CIPHER_SERVER_PREFERENCE;
  return 0;
#else
  env->die(env, stack, "SSL_OP_CIPHER_SERVER_PREFERENCE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_CISCO_ANYCONNECT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_CISCO_ANYCONNECT
  stack[0].ival = SSL_OP_CISCO_ANYCONNECT;
  return 0;
#else
  env->die(env, stack, "SSL_OP_CISCO_ANYCONNECT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_COOKIE_EXCHANGE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_COOKIE_EXCHANGE
  stack[0].ival = SSL_OP_COOKIE_EXCHANGE;
  return 0;
#else
  env->die(env, stack, "SSL_OP_COOKIE_EXCHANGE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_CRYPTOPRO_TLSEXT_BUG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_CRYPTOPRO_TLSEXT_BUG
  stack[0].ival = SSL_OP_CRYPTOPRO_TLSEXT_BUG;
  return 0;
#else
  env->die(env, stack, "SSL_OP_CRYPTOPRO_TLSEXT_BUG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS
  stack[0].ival = SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS;
  return 0;
#else
  env->die(env, stack, "SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_ENABLE_MIDDLEBOX_COMPAT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_ENABLE_MIDDLEBOX_COMPAT
  stack[0].ival = SSL_OP_ENABLE_MIDDLEBOX_COMPAT;
  return 0;
#else
  env->die(env, stack, "SSL_OP_ENABLE_MIDDLEBOX_COMPAT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_EPHEMERAL_RSA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_EPHEMERAL_RSA
  stack[0].ival = SSL_OP_EPHEMERAL_RSA;
  return 0;
#else
  env->die(env, stack, "SSL_OP_EPHEMERAL_RSA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_LEGACY_SERVER_CONNECT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_LEGACY_SERVER_CONNECT
  stack[0].ival = SSL_OP_LEGACY_SERVER_CONNECT;
  return 0;
#else
  env->die(env, stack, "SSL_OP_LEGACY_SERVER_CONNECT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_MICROSOFT_BIG_SSLV3_BUFFER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_MICROSOFT_BIG_SSLV3_BUFFER
  stack[0].ival = SSL_OP_MICROSOFT_BIG_SSLV3_BUFFER;
  return 0;
#else
  env->die(env, stack, "SSL_OP_MICROSOFT_BIG_SSLV3_BUFFER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_MICROSOFT_SESS_ID_BUG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_MICROSOFT_SESS_ID_BUG
  stack[0].ival = SSL_OP_MICROSOFT_SESS_ID_BUG;
  return 0;
#else
  env->die(env, stack, "SSL_OP_MICROSOFT_SESS_ID_BUG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_MSIE_SSLV2_RSA_PADDING(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_MSIE_SSLV2_RSA_PADDING
  stack[0].ival = SSL_OP_MSIE_SSLV2_RSA_PADDING;
  return 0;
#else
  env->die(env, stack, "SSL_OP_MSIE_SSLV2_RSA_PADDING is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NETSCAPE_CA_DN_BUG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NETSCAPE_CA_DN_BUG
  stack[0].ival = SSL_OP_NETSCAPE_CA_DN_BUG;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NETSCAPE_CA_DN_BUG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NETSCAPE_CHALLENGE_BUG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NETSCAPE_CHALLENGE_BUG
  stack[0].ival = SSL_OP_NETSCAPE_CHALLENGE_BUG;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NETSCAPE_CHALLENGE_BUG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NETSCAPE_DEMO_CIPHER_CHANGE_BUG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NETSCAPE_DEMO_CIPHER_CHANGE_BUG
  stack[0].ival = SSL_OP_NETSCAPE_DEMO_CIPHER_CHANGE_BUG;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NETSCAPE_DEMO_CIPHER_CHANGE_BUG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NETSCAPE_REUSE_CIPHER_CHANGE_BUG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NETSCAPE_REUSE_CIPHER_CHANGE_BUG
  stack[0].ival = SSL_OP_NETSCAPE_REUSE_CIPHER_CHANGE_BUG;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NETSCAPE_REUSE_CIPHER_CHANGE_BUG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NON_EXPORT_FIRST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NON_EXPORT_FIRST
  stack[0].ival = SSL_OP_NON_EXPORT_FIRST;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NON_EXPORT_FIRST is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NO_ANTI_REPLAY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NO_ANTI_REPLAY
  stack[0].ival = SSL_OP_NO_ANTI_REPLAY;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NO_ANTI_REPLAY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NO_CLIENT_RENEGOTIATION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NO_CLIENT_RENEGOTIATION
  stack[0].ival = SSL_OP_NO_CLIENT_RENEGOTIATION;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NO_CLIENT_RENEGOTIATION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NO_COMPRESSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NO_COMPRESSION
  stack[0].ival = SSL_OP_NO_COMPRESSION;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NO_COMPRESSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NO_ENCRYPT_THEN_MAC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NO_ENCRYPT_THEN_MAC
  stack[0].ival = SSL_OP_NO_ENCRYPT_THEN_MAC;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NO_ENCRYPT_THEN_MAC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NO_QUERY_MTU(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NO_QUERY_MTU
  stack[0].ival = SSL_OP_NO_QUERY_MTU;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NO_QUERY_MTU is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NO_RENEGOTIATION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NO_RENEGOTIATION
  stack[0].ival = SSL_OP_NO_RENEGOTIATION;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NO_RENEGOTIATION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NO_SESSION_RESUMPTION_ON_RENEGOTIATION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NO_SESSION_RESUMPTION_ON_RENEGOTIATION
  stack[0].ival = SSL_OP_NO_SESSION_RESUMPTION_ON_RENEGOTIATION;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NO_SESSION_RESUMPTION_ON_RENEGOTIATION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NO_SSL_MASK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NO_SSL_MASK
  stack[0].ival = SSL_OP_NO_SSL_MASK;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NO_SSL_MASK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NO_SSLv2(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NO_SSLv2
  stack[0].ival = SSL_OP_NO_SSLv2;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NO_SSLv2 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NO_SSLv3(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NO_SSLv3
  stack[0].ival = SSL_OP_NO_SSLv3;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NO_SSLv3 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NO_TICKET(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NO_TICKET
  stack[0].ival = SSL_OP_NO_TICKET;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NO_TICKET is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NO_TLSv1(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NO_TLSv1
  stack[0].ival = SSL_OP_NO_TLSv1;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NO_TLSv1 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NO_TLSv1_1(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NO_TLSv1_1
  stack[0].ival = SSL_OP_NO_TLSv1_1;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NO_TLSv1_1 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NO_TLSv1_2(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NO_TLSv1_2
  stack[0].ival = SSL_OP_NO_TLSv1_2;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NO_TLSv1_2 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_NO_TLSv1_3(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_NO_TLSv1_3
  stack[0].ival = SSL_OP_NO_TLSv1_3;
  return 0;
#else
  env->die(env, stack, "SSL_OP_NO_TLSv1_3 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_PKCS1_CHECK_1(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_PKCS1_CHECK_1
  stack[0].ival = SSL_OP_PKCS1_CHECK_1;
  return 0;
#else
  env->die(env, stack, "SSL_OP_PKCS1_CHECK_1 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_PKCS1_CHECK_2(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_PKCS1_CHECK_2
  stack[0].ival = SSL_OP_PKCS1_CHECK_2;
  return 0;
#else
  env->die(env, stack, "SSL_OP_PKCS1_CHECK_2 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_PRIORITIZE_CHACHA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_PRIORITIZE_CHACHA
  stack[0].ival = SSL_OP_PRIORITIZE_CHACHA;
  return 0;
#else
  env->die(env, stack, "SSL_OP_PRIORITIZE_CHACHA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_SAFARI_ECDHE_ECDSA_BUG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_SAFARI_ECDHE_ECDSA_BUG
  stack[0].ival = SSL_OP_SAFARI_ECDHE_ECDSA_BUG;
  return 0;
#else
  env->die(env, stack, "SSL_OP_SAFARI_ECDHE_ECDSA_BUG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_SINGLE_DH_USE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_SINGLE_DH_USE
  stack[0].ival = SSL_OP_SINGLE_DH_USE;
  return 0;
#else
  env->die(env, stack, "SSL_OP_SINGLE_DH_USE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_SINGLE_ECDH_USE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_SINGLE_ECDH_USE
  stack[0].ival = SSL_OP_SINGLE_ECDH_USE;
  return 0;
#else
  env->die(env, stack, "SSL_OP_SINGLE_ECDH_USE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_SSLEAY_080_CLIENT_DH_BUG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_SSLEAY_080_CLIENT_DH_BUG
  stack[0].ival = SSL_OP_SSLEAY_080_CLIENT_DH_BUG;
  return 0;
#else
  env->die(env, stack, "SSL_OP_SSLEAY_080_CLIENT_DH_BUG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_SSLREF2_REUSE_CERT_TYPE_BUG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_SSLREF2_REUSE_CERT_TYPE_BUG
  stack[0].ival = SSL_OP_SSLREF2_REUSE_CERT_TYPE_BUG;
  return 0;
#else
  env->die(env, stack, "SSL_OP_SSLREF2_REUSE_CERT_TYPE_BUG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_TLSEXT_PADDING(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_TLSEXT_PADDING
  stack[0].ival = SSL_OP_TLSEXT_PADDING;
  return 0;
#else
  env->die(env, stack, "SSL_OP_TLSEXT_PADDING is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_TLS_BLOCK_PADDING_BUG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_TLS_BLOCK_PADDING_BUG
  stack[0].ival = SSL_OP_TLS_BLOCK_PADDING_BUG;
  return 0;
#else
  env->die(env, stack, "SSL_OP_TLS_BLOCK_PADDING_BUG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_TLS_D5_BUG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_TLS_D5_BUG
  stack[0].ival = SSL_OP_TLS_D5_BUG;
  return 0;
#else
  env->die(env, stack, "SSL_OP_TLS_D5_BUG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_OP_TLS_ROLLBACK_BUG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_OP_TLS_ROLLBACK_BUG
  stack[0].ival = SSL_OP_TLS_ROLLBACK_BUG;
  return 0;
#else
  env->die(env, stack, "SSL_OP_TLS_ROLLBACK_BUG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_READING(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_READING
  stack[0].ival = SSL_READING;
  return 0;
#else
  env->die(env, stack, "SSL_READING is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_RECEIVED_SHUTDOWN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_RECEIVED_SHUTDOWN
  stack[0].ival = SSL_RECEIVED_SHUTDOWN;
  return 0;
#else
  env->die(env, stack, "SSL_RECEIVED_SHUTDOWN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_BAD_AUTHENTICATION_TYPE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_BAD_AUTHENTICATION_TYPE
  stack[0].ival = SSL_R_BAD_AUTHENTICATION_TYPE;
  return 0;
#else
  env->die(env, stack, "SSL_R_BAD_AUTHENTICATION_TYPE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_BAD_CHECKSUM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_BAD_CHECKSUM
  stack[0].ival = SSL_R_BAD_CHECKSUM;
  return 0;
#else
  env->die(env, stack, "SSL_R_BAD_CHECKSUM is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_BAD_MAC_DECODE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_BAD_MAC_DECODE
  stack[0].ival = SSL_R_BAD_MAC_DECODE;
  return 0;
#else
  env->die(env, stack, "SSL_R_BAD_MAC_DECODE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_BAD_RESPONSE_ARGUMENT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_BAD_RESPONSE_ARGUMENT
  stack[0].ival = SSL_R_BAD_RESPONSE_ARGUMENT;
  return 0;
#else
  env->die(env, stack, "SSL_R_BAD_RESPONSE_ARGUMENT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_BAD_SSL_FILETYPE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_BAD_SSL_FILETYPE
  stack[0].ival = SSL_R_BAD_SSL_FILETYPE;
  return 0;
#else
  env->die(env, stack, "SSL_R_BAD_SSL_FILETYPE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_BAD_SSL_SESSION_ID_LENGTH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_BAD_SSL_SESSION_ID_LENGTH
  stack[0].ival = SSL_R_BAD_SSL_SESSION_ID_LENGTH;
  return 0;
#else
  env->die(env, stack, "SSL_R_BAD_SSL_SESSION_ID_LENGTH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_BAD_STATE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_BAD_STATE
  stack[0].ival = SSL_R_BAD_STATE;
  return 0;
#else
  env->die(env, stack, "SSL_R_BAD_STATE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_BAD_WRITE_RETRY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_BAD_WRITE_RETRY
  stack[0].ival = SSL_R_BAD_WRITE_RETRY;
  return 0;
#else
  env->die(env, stack, "SSL_R_BAD_WRITE_RETRY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_CHALLENGE_IS_DIFFERENT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_CHALLENGE_IS_DIFFERENT
  stack[0].ival = SSL_R_CHALLENGE_IS_DIFFERENT;
  return 0;
#else
  env->die(env, stack, "SSL_R_CHALLENGE_IS_DIFFERENT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_CIPHER_TABLE_SRC_ERROR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_CIPHER_TABLE_SRC_ERROR
  stack[0].ival = SSL_R_CIPHER_TABLE_SRC_ERROR;
  return 0;
#else
  env->die(env, stack, "SSL_R_CIPHER_TABLE_SRC_ERROR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_INVALID_CHALLENGE_LENGTH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_INVALID_CHALLENGE_LENGTH
  stack[0].ival = SSL_R_INVALID_CHALLENGE_LENGTH;
  return 0;
#else
  env->die(env, stack, "SSL_R_INVALID_CHALLENGE_LENGTH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_NO_CERTIFICATE_SET(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_NO_CERTIFICATE_SET
  stack[0].ival = SSL_R_NO_CERTIFICATE_SET;
  return 0;
#else
  env->die(env, stack, "SSL_R_NO_CERTIFICATE_SET is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_NO_CERTIFICATE_SPECIFIED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_NO_CERTIFICATE_SPECIFIED
  stack[0].ival = SSL_R_NO_CERTIFICATE_SPECIFIED;
  return 0;
#else
  env->die(env, stack, "SSL_R_NO_CERTIFICATE_SPECIFIED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_NO_CIPHER_LIST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_NO_CIPHER_LIST
  stack[0].ival = SSL_R_NO_CIPHER_LIST;
  return 0;
#else
  env->die(env, stack, "SSL_R_NO_CIPHER_LIST is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_NO_CIPHER_MATCH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_NO_CIPHER_MATCH
  stack[0].ival = SSL_R_NO_CIPHER_MATCH;
  return 0;
#else
  env->die(env, stack, "SSL_R_NO_CIPHER_MATCH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_NO_PRIVATEKEY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_NO_PRIVATEKEY
  stack[0].ival = SSL_R_NO_PRIVATEKEY;
  return 0;
#else
  env->die(env, stack, "SSL_R_NO_PRIVATEKEY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_NO_PUBLICKEY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_NO_PUBLICKEY
  stack[0].ival = SSL_R_NO_PUBLICKEY;
  return 0;
#else
  env->die(env, stack, "SSL_R_NO_PUBLICKEY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_NULL_SSL_CTX(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_NULL_SSL_CTX
  stack[0].ival = SSL_R_NULL_SSL_CTX;
  return 0;
#else
  env->die(env, stack, "SSL_R_NULL_SSL_CTX is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_PEER_DID_NOT_RETURN_A_CERTIFICATE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_PEER_DID_NOT_RETURN_A_CERTIFICATE
  stack[0].ival = SSL_R_PEER_DID_NOT_RETURN_A_CERTIFICATE;
  return 0;
#else
  env->die(env, stack, "SSL_R_PEER_DID_NOT_RETURN_A_CERTIFICATE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_PEER_ERROR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_PEER_ERROR
  stack[0].ival = SSL_R_PEER_ERROR;
  return 0;
#else
  env->die(env, stack, "SSL_R_PEER_ERROR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_PEER_ERROR_CERTIFICATE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_PEER_ERROR_CERTIFICATE
  stack[0].ival = SSL_R_PEER_ERROR_CERTIFICATE;
  return 0;
#else
  env->die(env, stack, "SSL_R_PEER_ERROR_CERTIFICATE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_PEER_ERROR_NO_CIPHER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_PEER_ERROR_NO_CIPHER
  stack[0].ival = SSL_R_PEER_ERROR_NO_CIPHER;
  return 0;
#else
  env->die(env, stack, "SSL_R_PEER_ERROR_NO_CIPHER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_PEER_ERROR_UNSUPPORTED_CERTIFICATE_TYPE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_PEER_ERROR_UNSUPPORTED_CERTIFICATE_TYPE
  stack[0].ival = SSL_R_PEER_ERROR_UNSUPPORTED_CERTIFICATE_TYPE;
  return 0;
#else
  env->die(env, stack, "SSL_R_PEER_ERROR_UNSUPPORTED_CERTIFICATE_TYPE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_PUBLIC_KEY_ENCRYPT_ERROR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_PUBLIC_KEY_ENCRYPT_ERROR
  stack[0].ival = SSL_R_PUBLIC_KEY_ENCRYPT_ERROR;
  return 0;
#else
  env->die(env, stack, "SSL_R_PUBLIC_KEY_ENCRYPT_ERROR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_PUBLIC_KEY_IS_NOT_RSA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_PUBLIC_KEY_IS_NOT_RSA
  stack[0].ival = SSL_R_PUBLIC_KEY_IS_NOT_RSA;
  return 0;
#else
  env->die(env, stack, "SSL_R_PUBLIC_KEY_IS_NOT_RSA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_READ_WRONG_PACKET_TYPE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_READ_WRONG_PACKET_TYPE
  stack[0].ival = SSL_R_READ_WRONG_PACKET_TYPE;
  return 0;
#else
  env->die(env, stack, "SSL_R_READ_WRONG_PACKET_TYPE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_SHORT_READ(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_SHORT_READ
  stack[0].ival = SSL_R_SHORT_READ;
  return 0;
#else
  env->die(env, stack, "SSL_R_SHORT_READ is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_SSL_SESSION_ID_IS_DIFFERENT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_SSL_SESSION_ID_IS_DIFFERENT
  stack[0].ival = SSL_R_SSL_SESSION_ID_IS_DIFFERENT;
  return 0;
#else
  env->die(env, stack, "SSL_R_SSL_SESSION_ID_IS_DIFFERENT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_UNABLE_TO_EXTRACT_PUBLIC_KEY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_UNABLE_TO_EXTRACT_PUBLIC_KEY
  stack[0].ival = SSL_R_UNABLE_TO_EXTRACT_PUBLIC_KEY;
  return 0;
#else
  env->die(env, stack, "SSL_R_UNABLE_TO_EXTRACT_PUBLIC_KEY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_UNKNOWN_REMOTE_ERROR_TYPE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_UNKNOWN_REMOTE_ERROR_TYPE
  stack[0].ival = SSL_R_UNKNOWN_REMOTE_ERROR_TYPE;
  return 0;
#else
  env->die(env, stack, "SSL_R_UNKNOWN_REMOTE_ERROR_TYPE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_UNKNOWN_STATE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_UNKNOWN_STATE
  stack[0].ival = SSL_R_UNKNOWN_STATE;
  return 0;
#else
  env->die(env, stack, "SSL_R_UNKNOWN_STATE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_R_X509_LIB(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_R_X509_LIB
  stack[0].ival = SSL_R_X509_LIB;
  return 0;
#else
  env->die(env, stack, "SSL_R_X509_LIB is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_SENT_SHUTDOWN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_SENT_SHUTDOWN
  stack[0].ival = SSL_SENT_SHUTDOWN;
  return 0;
#else
  env->die(env, stack, "SSL_SENT_SHUTDOWN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_SESSION_ASN1_VERSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_SESSION_ASN1_VERSION
  stack[0].ival = SSL_SESSION_ASN1_VERSION;
  return 0;
#else
  env->die(env, stack, "SSL_SESSION_ASN1_VERSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_SESS_CACHE_BOTH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_SESS_CACHE_BOTH
  stack[0].ival = SSL_SESS_CACHE_BOTH;
  return 0;
#else
  env->die(env, stack, "SSL_SESS_CACHE_BOTH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_SESS_CACHE_CLIENT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_SESS_CACHE_CLIENT
  stack[0].ival = SSL_SESS_CACHE_CLIENT;
  return 0;
#else
  env->die(env, stack, "SSL_SESS_CACHE_CLIENT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_SESS_CACHE_NO_AUTO_CLEAR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_SESS_CACHE_NO_AUTO_CLEAR
  stack[0].ival = SSL_SESS_CACHE_NO_AUTO_CLEAR;
  return 0;
#else
  env->die(env, stack, "SSL_SESS_CACHE_NO_AUTO_CLEAR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_SESS_CACHE_NO_INTERNAL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_SESS_CACHE_NO_INTERNAL
  stack[0].ival = SSL_SESS_CACHE_NO_INTERNAL;
  return 0;
#else
  env->die(env, stack, "SSL_SESS_CACHE_NO_INTERNAL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_SESS_CACHE_NO_INTERNAL_LOOKUP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_SESS_CACHE_NO_INTERNAL_LOOKUP
  stack[0].ival = SSL_SESS_CACHE_NO_INTERNAL_LOOKUP;
  return 0;
#else
  env->die(env, stack, "SSL_SESS_CACHE_NO_INTERNAL_LOOKUP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_SESS_CACHE_NO_INTERNAL_STORE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_SESS_CACHE_NO_INTERNAL_STORE
  stack[0].ival = SSL_SESS_CACHE_NO_INTERNAL_STORE;
  return 0;
#else
  env->die(env, stack, "SSL_SESS_CACHE_NO_INTERNAL_STORE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_SESS_CACHE_OFF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_SESS_CACHE_OFF
  stack[0].ival = SSL_SESS_CACHE_OFF;
  return 0;
#else
  env->die(env, stack, "SSL_SESS_CACHE_OFF is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_SESS_CACHE_SERVER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_SESS_CACHE_SERVER
  stack[0].ival = SSL_SESS_CACHE_SERVER;
  return 0;
#else
  env->die(env, stack, "SSL_SESS_CACHE_SERVER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_ST_ACCEPT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_ST_ACCEPT
  stack[0].ival = SSL_ST_ACCEPT;
  return 0;
#else
  env->die(env, stack, "SSL_ST_ACCEPT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_ST_BEFORE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_ST_BEFORE
  stack[0].ival = SSL_ST_BEFORE;
  return 0;
#else
  env->die(env, stack, "SSL_ST_BEFORE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_ST_CONNECT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_ST_CONNECT
  stack[0].ival = SSL_ST_CONNECT;
  return 0;
#else
  env->die(env, stack, "SSL_ST_CONNECT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_ST_INIT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_ST_INIT
  stack[0].ival = SSL_ST_INIT;
  return 0;
#else
  env->die(env, stack, "SSL_ST_INIT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_ST_OK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_ST_OK
  stack[0].ival = SSL_ST_OK;
  return 0;
#else
  env->die(env, stack, "SSL_ST_OK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_ST_READ_BODY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_ST_READ_BODY
  stack[0].ival = SSL_ST_READ_BODY;
  return 0;
#else
  env->die(env, stack, "SSL_ST_READ_BODY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_ST_READ_HEADER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_ST_READ_HEADER
  stack[0].ival = SSL_ST_READ_HEADER;
  return 0;
#else
  env->die(env, stack, "SSL_ST_READ_HEADER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_VERIFY_CLIENT_ONCE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_VERIFY_CLIENT_ONCE
  stack[0].ival = SSL_VERIFY_CLIENT_ONCE;
  return 0;
#else
  env->die(env, stack, "SSL_VERIFY_CLIENT_ONCE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_VERIFY_FAIL_IF_NO_PEER_CERT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_VERIFY_FAIL_IF_NO_PEER_CERT
  stack[0].ival = SSL_VERIFY_FAIL_IF_NO_PEER_CERT;
  return 0;
#else
  env->die(env, stack, "SSL_VERIFY_FAIL_IF_NO_PEER_CERT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_VERIFY_NONE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_VERIFY_NONE
  stack[0].ival = SSL_VERIFY_NONE;
  return 0;
#else
  env->die(env, stack, "SSL_VERIFY_NONE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_VERIFY_PEER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_VERIFY_PEER
  stack[0].ival = SSL_VERIFY_PEER;
  return 0;
#else
  env->die(env, stack, "SSL_VERIFY_PEER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_VERIFY_POST_HANDSHAKE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_VERIFY_POST_HANDSHAKE
  stack[0].ival = SSL_VERIFY_POST_HANDSHAKE;
  return 0;
#else
  env->die(env, stack, "SSL_VERIFY_POST_HANDSHAKE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_WRITING(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_WRITING
  stack[0].ival = SSL_WRITING;
  return 0;
#else
  env->die(env, stack, "SSL_WRITING is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_X509_LOOKUP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_X509_LOOKUP
  stack[0].ival = SSL_X509_LOOKUP;
  return 0;
#else
  env->die(env, stack, "SSL_X509_LOOKUP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__TLS1_1_VERSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TLS1_1_VERSION
  stack[0].ival = TLS1_1_VERSION;
  return 0;
#else
  env->die(env, stack, "TLS1_1_VERSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__TLS1_2_VERSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TLS1_2_VERSION
  stack[0].ival = TLS1_2_VERSION;
  return 0;
#else
  env->die(env, stack, "TLS1_2_VERSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__TLS1_3_VERSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TLS1_3_VERSION
  stack[0].ival = TLS1_3_VERSION;
  return 0;
#else
  env->die(env, stack, "TLS1_3_VERSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__TLS1_VERSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TLS1_VERSION
  stack[0].ival = TLS1_VERSION;
  return 0;
#else
  env->die(env, stack, "TLS1_VERSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__TLSEXT_STATUSTYPE_ocsp(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TLSEXT_STATUSTYPE_ocsp
  stack[0].ival = TLSEXT_STATUSTYPE_ocsp;
  return 0;
#else
  env->die(env, stack, "TLSEXT_STATUSTYPE_ocsp is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__V_OCSP_CERTSTATUS_GOOD(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef V_OCSP_CERTSTATUS_GOOD
  stack[0].ival = V_OCSP_CERTSTATUS_GOOD;
  return 0;
#else
  env->die(env, stack, "V_OCSP_CERTSTATUS_GOOD is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__V_OCSP_CERTSTATUS_REVOKED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef V_OCSP_CERTSTATUS_REVOKED
  stack[0].ival = V_OCSP_CERTSTATUS_REVOKED;
  return 0;
#else
  env->die(env, stack, "V_OCSP_CERTSTATUS_REVOKED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__V_OCSP_CERTSTATUS_UNKNOWN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef V_OCSP_CERTSTATUS_UNKNOWN
  stack[0].ival = V_OCSP_CERTSTATUS_UNKNOWN;
  return 0;
#else
  env->die(env, stack, "V_OCSP_CERTSTATUS_UNKNOWN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_CHECK_FLAG_ALWAYS_CHECK_SUBJECT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_CHECK_FLAG_ALWAYS_CHECK_SUBJECT
  stack[0].ival = X509_CHECK_FLAG_ALWAYS_CHECK_SUBJECT;
  return 0;
#else
  env->die(env, stack, "X509_CHECK_FLAG_ALWAYS_CHECK_SUBJECT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_CHECK_FLAG_MULTI_LABEL_WILDCARDS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_CHECK_FLAG_MULTI_LABEL_WILDCARDS
  stack[0].ival = X509_CHECK_FLAG_MULTI_LABEL_WILDCARDS;
  return 0;
#else
  env->die(env, stack, "X509_CHECK_FLAG_MULTI_LABEL_WILDCARDS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_CHECK_FLAG_NEVER_CHECK_SUBJECT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_CHECK_FLAG_NEVER_CHECK_SUBJECT
  stack[0].ival = X509_CHECK_FLAG_NEVER_CHECK_SUBJECT;
  return 0;
#else
  env->die(env, stack, "X509_CHECK_FLAG_NEVER_CHECK_SUBJECT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS
  stack[0].ival = X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS;
  return 0;
#else
  env->die(env, stack, "X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_CHECK_FLAG_NO_WILDCARDS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_CHECK_FLAG_NO_WILDCARDS
  stack[0].ival = X509_CHECK_FLAG_NO_WILDCARDS;
  return 0;
#else
  env->die(env, stack, "X509_CHECK_FLAG_NO_WILDCARDS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS
  stack[0].ival = X509_CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS;
  return 0;
#else
  env->die(env, stack, "X509_CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_FILETYPE_ASN1(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_FILETYPE_ASN1
  stack[0].ival = X509_FILETYPE_ASN1;
  return 0;
#else
  env->die(env, stack, "X509_FILETYPE_ASN1 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_FILETYPE_DEFAULT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_FILETYPE_DEFAULT
  stack[0].ival = X509_FILETYPE_DEFAULT;
  return 0;
#else
  env->die(env, stack, "X509_FILETYPE_DEFAULT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_FILETYPE_PEM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_FILETYPE_PEM
  stack[0].ival = X509_FILETYPE_PEM;
  return 0;
#else
  env->die(env, stack, "X509_FILETYPE_PEM is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_PURPOSE_ANY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_PURPOSE_ANY
  stack[0].ival = X509_PURPOSE_ANY;
  return 0;
#else
  env->die(env, stack, "X509_PURPOSE_ANY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_PURPOSE_CRL_SIGN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_PURPOSE_CRL_SIGN
  stack[0].ival = X509_PURPOSE_CRL_SIGN;
  return 0;
#else
  env->die(env, stack, "X509_PURPOSE_CRL_SIGN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_PURPOSE_NS_SSL_SERVER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_PURPOSE_NS_SSL_SERVER
  stack[0].ival = X509_PURPOSE_NS_SSL_SERVER;
  return 0;
#else
  env->die(env, stack, "X509_PURPOSE_NS_SSL_SERVER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_PURPOSE_OCSP_HELPER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_PURPOSE_OCSP_HELPER
  stack[0].ival = X509_PURPOSE_OCSP_HELPER;
  return 0;
#else
  env->die(env, stack, "X509_PURPOSE_OCSP_HELPER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_PURPOSE_SMIME_ENCRYPT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_PURPOSE_SMIME_ENCRYPT
  stack[0].ival = X509_PURPOSE_SMIME_ENCRYPT;
  return 0;
#else
  env->die(env, stack, "X509_PURPOSE_SMIME_ENCRYPT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_PURPOSE_SMIME_SIGN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_PURPOSE_SMIME_SIGN
  stack[0].ival = X509_PURPOSE_SMIME_SIGN;
  return 0;
#else
  env->die(env, stack, "X509_PURPOSE_SMIME_SIGN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_PURPOSE_SSL_CLIENT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_PURPOSE_SSL_CLIENT
  stack[0].ival = X509_PURPOSE_SSL_CLIENT;
  return 0;
#else
  env->die(env, stack, "X509_PURPOSE_SSL_CLIENT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_PURPOSE_SSL_SERVER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_PURPOSE_SSL_SERVER
  stack[0].ival = X509_PURPOSE_SSL_SERVER;
  return 0;
#else
  env->die(env, stack, "X509_PURPOSE_SSL_SERVER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_PURPOSE_TIMESTAMP_SIGN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_PURPOSE_TIMESTAMP_SIGN
  stack[0].ival = X509_PURPOSE_TIMESTAMP_SIGN;
  return 0;
#else
  env->die(env, stack, "X509_PURPOSE_TIMESTAMP_SIGN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_TRUST_COMPAT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_TRUST_COMPAT
  stack[0].ival = X509_TRUST_COMPAT;
  return 0;
#else
  env->die(env, stack, "X509_TRUST_COMPAT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_TRUST_EMAIL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_TRUST_EMAIL
  stack[0].ival = X509_TRUST_EMAIL;
  return 0;
#else
  env->die(env, stack, "X509_TRUST_EMAIL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_TRUST_OBJECT_SIGN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_TRUST_OBJECT_SIGN
  stack[0].ival = X509_TRUST_OBJECT_SIGN;
  return 0;
#else
  env->die(env, stack, "X509_TRUST_OBJECT_SIGN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_TRUST_OCSP_REQUEST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_TRUST_OCSP_REQUEST
  stack[0].ival = X509_TRUST_OCSP_REQUEST;
  return 0;
#else
  env->die(env, stack, "X509_TRUST_OCSP_REQUEST is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_TRUST_OCSP_SIGN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_TRUST_OCSP_SIGN
  stack[0].ival = X509_TRUST_OCSP_SIGN;
  return 0;
#else
  env->die(env, stack, "X509_TRUST_OCSP_SIGN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_TRUST_SSL_CLIENT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_TRUST_SSL_CLIENT
  stack[0].ival = X509_TRUST_SSL_CLIENT;
  return 0;
#else
  env->die(env, stack, "X509_TRUST_SSL_CLIENT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_TRUST_SSL_SERVER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_TRUST_SSL_SERVER
  stack[0].ival = X509_TRUST_SSL_SERVER;
  return 0;
#else
  env->die(env, stack, "X509_TRUST_SSL_SERVER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_TRUST_TSA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_TRUST_TSA
  stack[0].ival = X509_TRUST_TSA;
  return 0;
#else
  env->die(env, stack, "X509_TRUST_TSA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_AKID_ISSUER_SERIAL_MISMATCH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_AKID_ISSUER_SERIAL_MISMATCH
  stack[0].ival = X509_V_ERR_AKID_ISSUER_SERIAL_MISMATCH;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_AKID_ISSUER_SERIAL_MISMATCH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_AKID_SKID_MISMATCH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_AKID_SKID_MISMATCH
  stack[0].ival = X509_V_ERR_AKID_SKID_MISMATCH;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_AKID_SKID_MISMATCH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_APPLICATION_VERIFICATION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_APPLICATION_VERIFICATION
  stack[0].ival = X509_V_ERR_APPLICATION_VERIFICATION;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_APPLICATION_VERIFICATION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_CA_KEY_TOO_SMALL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_CA_KEY_TOO_SMALL
  stack[0].ival = X509_V_ERR_CA_KEY_TOO_SMALL;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_CA_KEY_TOO_SMALL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_CA_MD_TOO_WEAK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_CA_MD_TOO_WEAK
  stack[0].ival = X509_V_ERR_CA_MD_TOO_WEAK;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_CA_MD_TOO_WEAK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_CERT_CHAIN_TOO_LONG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_CERT_CHAIN_TOO_LONG
  stack[0].ival = X509_V_ERR_CERT_CHAIN_TOO_LONG;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_CERT_CHAIN_TOO_LONG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_CERT_HAS_EXPIRED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_CERT_HAS_EXPIRED
  stack[0].ival = X509_V_ERR_CERT_HAS_EXPIRED;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_CERT_HAS_EXPIRED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_CERT_NOT_YET_VALID(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_CERT_NOT_YET_VALID
  stack[0].ival = X509_V_ERR_CERT_NOT_YET_VALID;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_CERT_NOT_YET_VALID is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_CERT_REJECTED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_CERT_REJECTED
  stack[0].ival = X509_V_ERR_CERT_REJECTED;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_CERT_REJECTED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_CERT_REVOKED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_CERT_REVOKED
  stack[0].ival = X509_V_ERR_CERT_REVOKED;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_CERT_REVOKED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_CERT_SIGNATURE_FAILURE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_CERT_SIGNATURE_FAILURE
  stack[0].ival = X509_V_ERR_CERT_SIGNATURE_FAILURE;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_CERT_SIGNATURE_FAILURE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_CERT_UNTRUSTED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_CERT_UNTRUSTED
  stack[0].ival = X509_V_ERR_CERT_UNTRUSTED;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_CERT_UNTRUSTED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_CRL_HAS_EXPIRED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_CRL_HAS_EXPIRED
  stack[0].ival = X509_V_ERR_CRL_HAS_EXPIRED;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_CRL_HAS_EXPIRED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_CRL_NOT_YET_VALID(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_CRL_NOT_YET_VALID
  stack[0].ival = X509_V_ERR_CRL_NOT_YET_VALID;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_CRL_NOT_YET_VALID is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_CRL_PATH_VALIDATION_ERROR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_CRL_PATH_VALIDATION_ERROR
  stack[0].ival = X509_V_ERR_CRL_PATH_VALIDATION_ERROR;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_CRL_PATH_VALIDATION_ERROR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_CRL_SIGNATURE_FAILURE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_CRL_SIGNATURE_FAILURE
  stack[0].ival = X509_V_ERR_CRL_SIGNATURE_FAILURE;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_CRL_SIGNATURE_FAILURE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_DANE_NO_MATCH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_DANE_NO_MATCH
  stack[0].ival = X509_V_ERR_DANE_NO_MATCH;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_DANE_NO_MATCH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT
  stack[0].ival = X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_DIFFERENT_CRL_SCOPE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_DIFFERENT_CRL_SCOPE
  stack[0].ival = X509_V_ERR_DIFFERENT_CRL_SCOPE;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_DIFFERENT_CRL_SCOPE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_EE_KEY_TOO_SMALL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_EE_KEY_TOO_SMALL
  stack[0].ival = X509_V_ERR_EE_KEY_TOO_SMALL;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_EE_KEY_TOO_SMALL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_EMAIL_MISMATCH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_EMAIL_MISMATCH
  stack[0].ival = X509_V_ERR_EMAIL_MISMATCH;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_EMAIL_MISMATCH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_ERROR_IN_CERT_NOT_AFTER_FIELD(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_ERROR_IN_CERT_NOT_AFTER_FIELD
  stack[0].ival = X509_V_ERR_ERROR_IN_CERT_NOT_AFTER_FIELD;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_ERROR_IN_CERT_NOT_AFTER_FIELD is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_ERROR_IN_CERT_NOT_BEFORE_FIELD(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_ERROR_IN_CERT_NOT_BEFORE_FIELD
  stack[0].ival = X509_V_ERR_ERROR_IN_CERT_NOT_BEFORE_FIELD;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_ERROR_IN_CERT_NOT_BEFORE_FIELD is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_ERROR_IN_CRL_LAST_UPDATE_FIELD(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_ERROR_IN_CRL_LAST_UPDATE_FIELD
  stack[0].ival = X509_V_ERR_ERROR_IN_CRL_LAST_UPDATE_FIELD;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_ERROR_IN_CRL_LAST_UPDATE_FIELD is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_ERROR_IN_CRL_NEXT_UPDATE_FIELD(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_ERROR_IN_CRL_NEXT_UPDATE_FIELD
  stack[0].ival = X509_V_ERR_ERROR_IN_CRL_NEXT_UPDATE_FIELD;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_ERROR_IN_CRL_NEXT_UPDATE_FIELD is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_EXCLUDED_VIOLATION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_EXCLUDED_VIOLATION
  stack[0].ival = X509_V_ERR_EXCLUDED_VIOLATION;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_EXCLUDED_VIOLATION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_HOSTNAME_MISMATCH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_HOSTNAME_MISMATCH
  stack[0].ival = X509_V_ERR_HOSTNAME_MISMATCH;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_HOSTNAME_MISMATCH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_INVALID_CA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_INVALID_CA
  stack[0].ival = X509_V_ERR_INVALID_CA;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_INVALID_CA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_INVALID_CALL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_INVALID_CALL
  stack[0].ival = X509_V_ERR_INVALID_CALL;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_INVALID_CALL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_INVALID_EXTENSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_INVALID_EXTENSION
  stack[0].ival = X509_V_ERR_INVALID_EXTENSION;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_INVALID_EXTENSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_INVALID_NON_CA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_INVALID_NON_CA
  stack[0].ival = X509_V_ERR_INVALID_NON_CA;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_INVALID_NON_CA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_INVALID_POLICY_EXTENSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_INVALID_POLICY_EXTENSION
  stack[0].ival = X509_V_ERR_INVALID_POLICY_EXTENSION;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_INVALID_POLICY_EXTENSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_INVALID_PURPOSE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_INVALID_PURPOSE
  stack[0].ival = X509_V_ERR_INVALID_PURPOSE;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_INVALID_PURPOSE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_IP_ADDRESS_MISMATCH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_IP_ADDRESS_MISMATCH
  stack[0].ival = X509_V_ERR_IP_ADDRESS_MISMATCH;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_IP_ADDRESS_MISMATCH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_KEYUSAGE_NO_CERTSIGN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_KEYUSAGE_NO_CERTSIGN
  stack[0].ival = X509_V_ERR_KEYUSAGE_NO_CERTSIGN;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_KEYUSAGE_NO_CERTSIGN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_KEYUSAGE_NO_CRL_SIGN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_KEYUSAGE_NO_CRL_SIGN
  stack[0].ival = X509_V_ERR_KEYUSAGE_NO_CRL_SIGN;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_KEYUSAGE_NO_CRL_SIGN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_KEYUSAGE_NO_DIGITAL_SIGNATURE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_KEYUSAGE_NO_DIGITAL_SIGNATURE
  stack[0].ival = X509_V_ERR_KEYUSAGE_NO_DIGITAL_SIGNATURE;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_KEYUSAGE_NO_DIGITAL_SIGNATURE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_NO_EXPLICIT_POLICY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_NO_EXPLICIT_POLICY
  stack[0].ival = X509_V_ERR_NO_EXPLICIT_POLICY;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_NO_EXPLICIT_POLICY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_NO_VALID_SCTS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_NO_VALID_SCTS
  stack[0].ival = X509_V_ERR_NO_VALID_SCTS;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_NO_VALID_SCTS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_OCSP_CERT_UNKNOWN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_OCSP_CERT_UNKNOWN
  stack[0].ival = X509_V_ERR_OCSP_CERT_UNKNOWN;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_OCSP_CERT_UNKNOWN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_OCSP_VERIFY_FAILED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_OCSP_VERIFY_FAILED
  stack[0].ival = X509_V_ERR_OCSP_VERIFY_FAILED;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_OCSP_VERIFY_FAILED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_OCSP_VERIFY_NEEDED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_OCSP_VERIFY_NEEDED
  stack[0].ival = X509_V_ERR_OCSP_VERIFY_NEEDED;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_OCSP_VERIFY_NEEDED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_OUT_OF_MEM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_OUT_OF_MEM
  stack[0].ival = X509_V_ERR_OUT_OF_MEM;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_OUT_OF_MEM is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_PATH_LENGTH_EXCEEDED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_PATH_LENGTH_EXCEEDED
  stack[0].ival = X509_V_ERR_PATH_LENGTH_EXCEEDED;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_PATH_LENGTH_EXCEEDED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_PATH_LOOP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_PATH_LOOP
  stack[0].ival = X509_V_ERR_PATH_LOOP;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_PATH_LOOP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_PERMITTED_VIOLATION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_PERMITTED_VIOLATION
  stack[0].ival = X509_V_ERR_PERMITTED_VIOLATION;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_PERMITTED_VIOLATION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_PROXY_CERTIFICATES_NOT_ALLOWED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_PROXY_CERTIFICATES_NOT_ALLOWED
  stack[0].ival = X509_V_ERR_PROXY_CERTIFICATES_NOT_ALLOWED;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_PROXY_CERTIFICATES_NOT_ALLOWED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_PROXY_PATH_LENGTH_EXCEEDED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_PROXY_PATH_LENGTH_EXCEEDED
  stack[0].ival = X509_V_ERR_PROXY_PATH_LENGTH_EXCEEDED;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_PROXY_PATH_LENGTH_EXCEEDED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_PROXY_SUBJECT_NAME_VIOLATION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_PROXY_SUBJECT_NAME_VIOLATION
  stack[0].ival = X509_V_ERR_PROXY_SUBJECT_NAME_VIOLATION;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_PROXY_SUBJECT_NAME_VIOLATION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN
  stack[0].ival = X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_STORE_LOOKUP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_STORE_LOOKUP
  stack[0].ival = X509_V_ERR_STORE_LOOKUP;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_STORE_LOOKUP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_SUBJECT_ISSUER_MISMATCH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_SUBJECT_ISSUER_MISMATCH
  stack[0].ival = X509_V_ERR_SUBJECT_ISSUER_MISMATCH;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_SUBJECT_ISSUER_MISMATCH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_SUBTREE_MINMAX(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_SUBTREE_MINMAX
  stack[0].ival = X509_V_ERR_SUBTREE_MINMAX;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_SUBTREE_MINMAX is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_SUITE_B_CANNOT_SIGN_P_384_WITH_P_256(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_SUITE_B_CANNOT_SIGN_P_384_WITH_P_256
  stack[0].ival = X509_V_ERR_SUITE_B_CANNOT_SIGN_P_384_WITH_P_256;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_SUITE_B_CANNOT_SIGN_P_384_WITH_P_256 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_SUITE_B_INVALID_ALGORITHM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_SUITE_B_INVALID_ALGORITHM
  stack[0].ival = X509_V_ERR_SUITE_B_INVALID_ALGORITHM;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_SUITE_B_INVALID_ALGORITHM is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_SUITE_B_INVALID_CURVE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_SUITE_B_INVALID_CURVE
  stack[0].ival = X509_V_ERR_SUITE_B_INVALID_CURVE;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_SUITE_B_INVALID_CURVE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_SUITE_B_INVALID_SIGNATURE_ALGORITHM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_SUITE_B_INVALID_SIGNATURE_ALGORITHM
  stack[0].ival = X509_V_ERR_SUITE_B_INVALID_SIGNATURE_ALGORITHM;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_SUITE_B_INVALID_SIGNATURE_ALGORITHM is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_SUITE_B_INVALID_VERSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_SUITE_B_INVALID_VERSION
  stack[0].ival = X509_V_ERR_SUITE_B_INVALID_VERSION;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_SUITE_B_INVALID_VERSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_SUITE_B_LOS_NOT_ALLOWED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_SUITE_B_LOS_NOT_ALLOWED
  stack[0].ival = X509_V_ERR_SUITE_B_LOS_NOT_ALLOWED;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_SUITE_B_LOS_NOT_ALLOWED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_UNABLE_TO_DECODE_ISSUER_PUBLIC_KEY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_UNABLE_TO_DECODE_ISSUER_PUBLIC_KEY
  stack[0].ival = X509_V_ERR_UNABLE_TO_DECODE_ISSUER_PUBLIC_KEY;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_UNABLE_TO_DECODE_ISSUER_PUBLIC_KEY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_UNABLE_TO_DECRYPT_CERT_SIGNATURE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_UNABLE_TO_DECRYPT_CERT_SIGNATURE
  stack[0].ival = X509_V_ERR_UNABLE_TO_DECRYPT_CERT_SIGNATURE;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_UNABLE_TO_DECRYPT_CERT_SIGNATURE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_UNABLE_TO_DECRYPT_CRL_SIGNATURE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_UNABLE_TO_DECRYPT_CRL_SIGNATURE
  stack[0].ival = X509_V_ERR_UNABLE_TO_DECRYPT_CRL_SIGNATURE;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_UNABLE_TO_DECRYPT_CRL_SIGNATURE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_UNABLE_TO_GET_CRL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_UNABLE_TO_GET_CRL
  stack[0].ival = X509_V_ERR_UNABLE_TO_GET_CRL;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_UNABLE_TO_GET_CRL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_UNABLE_TO_GET_CRL_ISSUER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_UNABLE_TO_GET_CRL_ISSUER
  stack[0].ival = X509_V_ERR_UNABLE_TO_GET_CRL_ISSUER;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_UNABLE_TO_GET_CRL_ISSUER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT
  stack[0].ival = X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY
  stack[0].ival = X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE
  stack[0].ival = X509_V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_UNHANDLED_CRITICAL_CRL_EXTENSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_UNHANDLED_CRITICAL_CRL_EXTENSION
  stack[0].ival = X509_V_ERR_UNHANDLED_CRITICAL_CRL_EXTENSION;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_UNHANDLED_CRITICAL_CRL_EXTENSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_UNHANDLED_CRITICAL_EXTENSION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_UNHANDLED_CRITICAL_EXTENSION
  stack[0].ival = X509_V_ERR_UNHANDLED_CRITICAL_EXTENSION;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_UNHANDLED_CRITICAL_EXTENSION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_UNNESTED_RESOURCE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_UNNESTED_RESOURCE
  stack[0].ival = X509_V_ERR_UNNESTED_RESOURCE;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_UNNESTED_RESOURCE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_UNSPECIFIED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_UNSPECIFIED
  stack[0].ival = X509_V_ERR_UNSPECIFIED;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_UNSPECIFIED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_UNSUPPORTED_CONSTRAINT_SYNTAX(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_UNSUPPORTED_CONSTRAINT_SYNTAX
  stack[0].ival = X509_V_ERR_UNSUPPORTED_CONSTRAINT_SYNTAX;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_UNSUPPORTED_CONSTRAINT_SYNTAX is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_UNSUPPORTED_CONSTRAINT_TYPE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_UNSUPPORTED_CONSTRAINT_TYPE
  stack[0].ival = X509_V_ERR_UNSUPPORTED_CONSTRAINT_TYPE;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_UNSUPPORTED_CONSTRAINT_TYPE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_UNSUPPORTED_EXTENSION_FEATURE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_UNSUPPORTED_EXTENSION_FEATURE
  stack[0].ival = X509_V_ERR_UNSUPPORTED_EXTENSION_FEATURE;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_UNSUPPORTED_EXTENSION_FEATURE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_ERR_UNSUPPORTED_NAME_SYNTAX(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_ERR_UNSUPPORTED_NAME_SYNTAX
  stack[0].ival = X509_V_ERR_UNSUPPORTED_NAME_SYNTAX;
  return 0;
#else
  env->die(env, stack, "X509_V_ERR_UNSUPPORTED_NAME_SYNTAX is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_ALLOW_PROXY_CERTS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_ALLOW_PROXY_CERTS
  stack[0].ival = X509_V_FLAG_ALLOW_PROXY_CERTS;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_ALLOW_PROXY_CERTS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_CB_ISSUER_CHECK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_CB_ISSUER_CHECK
  stack[0].ival = X509_V_FLAG_CB_ISSUER_CHECK;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_CB_ISSUER_CHECK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_CHECK_SS_SIGNATURE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_CHECK_SS_SIGNATURE
  stack[0].ival = X509_V_FLAG_CHECK_SS_SIGNATURE;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_CHECK_SS_SIGNATURE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_CRL_CHECK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_CRL_CHECK
  stack[0].ival = X509_V_FLAG_CRL_CHECK;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_CRL_CHECK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_CRL_CHECK_ALL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_CRL_CHECK_ALL
  stack[0].ival = X509_V_FLAG_CRL_CHECK_ALL;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_CRL_CHECK_ALL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_EXPLICIT_POLICY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_EXPLICIT_POLICY
  stack[0].ival = X509_V_FLAG_EXPLICIT_POLICY;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_EXPLICIT_POLICY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_EXTENDED_CRL_SUPPORT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_EXTENDED_CRL_SUPPORT
  stack[0].ival = X509_V_FLAG_EXTENDED_CRL_SUPPORT;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_EXTENDED_CRL_SUPPORT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_IGNORE_CRITICAL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_IGNORE_CRITICAL
  stack[0].ival = X509_V_FLAG_IGNORE_CRITICAL;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_IGNORE_CRITICAL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_INHIBIT_ANY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_INHIBIT_ANY
  stack[0].ival = X509_V_FLAG_INHIBIT_ANY;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_INHIBIT_ANY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_INHIBIT_MAP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_INHIBIT_MAP
  stack[0].ival = X509_V_FLAG_INHIBIT_MAP;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_INHIBIT_MAP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_LEGACY_VERIFY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_LEGACY_VERIFY
  stack[0].ival = X509_V_FLAG_LEGACY_VERIFY;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_LEGACY_VERIFY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_NOTIFY_POLICY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_NOTIFY_POLICY
  stack[0].ival = X509_V_FLAG_NOTIFY_POLICY;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_NOTIFY_POLICY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_NO_ALT_CHAINS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_NO_ALT_CHAINS
  stack[0].ival = X509_V_FLAG_NO_ALT_CHAINS;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_NO_ALT_CHAINS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_NO_CHECK_TIME(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_NO_CHECK_TIME
  stack[0].ival = X509_V_FLAG_NO_CHECK_TIME;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_NO_CHECK_TIME is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_PARTIAL_CHAIN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_PARTIAL_CHAIN
  stack[0].ival = X509_V_FLAG_PARTIAL_CHAIN;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_PARTIAL_CHAIN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_POLICY_CHECK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_POLICY_CHECK
  stack[0].ival = X509_V_FLAG_POLICY_CHECK;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_POLICY_CHECK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_POLICY_MASK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_POLICY_MASK
  stack[0].ival = X509_V_FLAG_POLICY_MASK;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_POLICY_MASK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_SUITEB_128_LOS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_SUITEB_128_LOS
  stack[0].ival = X509_V_FLAG_SUITEB_128_LOS;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_SUITEB_128_LOS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_SUITEB_128_LOS_ONLY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_SUITEB_128_LOS_ONLY
  stack[0].ival = X509_V_FLAG_SUITEB_128_LOS_ONLY;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_SUITEB_128_LOS_ONLY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_SUITEB_192_LOS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_SUITEB_192_LOS
  stack[0].ival = X509_V_FLAG_SUITEB_192_LOS;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_SUITEB_192_LOS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_TRUSTED_FIRST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_TRUSTED_FIRST
  stack[0].ival = X509_V_FLAG_TRUSTED_FIRST;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_TRUSTED_FIRST is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_USE_CHECK_TIME(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_USE_CHECK_TIME
  stack[0].ival = X509_V_FLAG_USE_CHECK_TIME;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_USE_CHECK_TIME is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_USE_DELTAS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_USE_DELTAS
  stack[0].ival = X509_V_FLAG_USE_DELTAS;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_USE_DELTAS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_FLAG_X509_STRICT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_FLAG_X509_STRICT
  stack[0].ival = X509_V_FLAG_X509_STRICT;
  return 0;
#else
  env->die(env, stack, "X509_V_FLAG_X509_STRICT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__X509_V_OK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X509_V_OK
  stack[0].ival = X509_V_OK;
  return 0;
#else
  env->die(env, stack, "X509_V_OK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_COMPAT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_COMPAT
  stack[0].ival = XN_FLAG_COMPAT;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_COMPAT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_DN_REV(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_DN_REV
  stack[0].ival = XN_FLAG_DN_REV;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_DN_REV is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_DUMP_UNKNOWN_FIELDS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_DUMP_UNKNOWN_FIELDS
  stack[0].ival = XN_FLAG_DUMP_UNKNOWN_FIELDS;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_DUMP_UNKNOWN_FIELDS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_FN_ALIGN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_FN_ALIGN
  stack[0].ival = XN_FLAG_FN_ALIGN;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_FN_ALIGN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_FN_LN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_FN_LN
  stack[0].ival = XN_FLAG_FN_LN;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_FN_LN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_FN_MASK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_FN_MASK
  stack[0].ival = XN_FLAG_FN_MASK;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_FN_MASK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_FN_NONE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_FN_NONE
  stack[0].ival = XN_FLAG_FN_NONE;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_FN_NONE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_FN_OID(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_FN_OID
  stack[0].ival = XN_FLAG_FN_OID;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_FN_OID is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_FN_SN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_FN_SN
  stack[0].ival = XN_FLAG_FN_SN;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_FN_SN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_MULTILINE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_MULTILINE
  stack[0].ival = XN_FLAG_MULTILINE;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_MULTILINE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_ONELINE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_ONELINE
  stack[0].ival = XN_FLAG_ONELINE;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_ONELINE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_RFC2253(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_RFC2253
  stack[0].ival = XN_FLAG_RFC2253;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_RFC2253 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_SEP_COMMA_PLUS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_SEP_COMMA_PLUS
  stack[0].ival = XN_FLAG_SEP_COMMA_PLUS;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_SEP_COMMA_PLUS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_SEP_CPLUS_SPC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_SEP_CPLUS_SPC
  stack[0].ival = XN_FLAG_SEP_CPLUS_SPC;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_SEP_CPLUS_SPC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_SEP_MASK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_SEP_MASK
  stack[0].ival = XN_FLAG_SEP_MASK;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_SEP_MASK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_SEP_MULTILINE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_SEP_MULTILINE
  stack[0].ival = XN_FLAG_SEP_MULTILINE;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_SEP_MULTILINE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_SEP_SPLUS_SPC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_SEP_SPLUS_SPC
  stack[0].ival = XN_FLAG_SEP_SPLUS_SPC;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_SEP_SPLUS_SPC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__XN_FLAG_SPC_EQ(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef XN_FLAG_SPC_EQ
  stack[0].ival = XN_FLAG_SPC_EQ;
  return 0;
#else
  env->die(env, stack, "XN_FLAG_SPC_EQ is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_NO_LOAD_SSL_STRINGS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_NO_LOAD_SSL_STRINGS
  stack[0].ival = OPENSSL_INIT_NO_LOAD_SSL_STRINGS;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_NO_LOAD_SSL_STRINGS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_LOAD_SSL_STRINGS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_LOAD_SSL_STRINGS
  stack[0].ival = OPENSSL_INIT_LOAD_SSL_STRINGS;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_LOAD_SSL_STRINGS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_NO_LOAD_CRYPTO_STRINGS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_NO_LOAD_CRYPTO_STRINGS
  stack[0].ival = OPENSSL_INIT_NO_LOAD_CRYPTO_STRINGS;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_NO_LOAD_CRYPTO_STRINGS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_LOAD_CRYPTO_STRINGS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_LOAD_CRYPTO_STRINGS
  stack[0].ival = OPENSSL_INIT_LOAD_CRYPTO_STRINGS;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_LOAD_CRYPTO_STRINGS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_ADD_ALL_CIPHERS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_ADD_ALL_CIPHERS
  stack[0].ival = OPENSSL_INIT_ADD_ALL_CIPHERS;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_ADD_ALL_CIPHERS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_ADD_ALL_DIGESTS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_ADD_ALL_DIGESTS
  stack[0].ival = OPENSSL_INIT_ADD_ALL_DIGESTS;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_ADD_ALL_DIGESTS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_NO_ADD_ALL_CIPHERS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_NO_ADD_ALL_CIPHERS
  stack[0].ival = OPENSSL_INIT_NO_ADD_ALL_CIPHERS;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_NO_ADD_ALL_CIPHERS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_NO_ADD_ALL_DIGESTS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_NO_ADD_ALL_DIGESTS
  stack[0].ival = OPENSSL_INIT_NO_ADD_ALL_DIGESTS;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_NO_ADD_ALL_DIGESTS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_LOAD_CONFIG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_LOAD_CONFIG
  stack[0].ival = OPENSSL_INIT_LOAD_CONFIG;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_LOAD_CONFIG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_NO_LOAD_CONFIG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_NO_LOAD_CONFIG
  stack[0].ival = OPENSSL_INIT_NO_LOAD_CONFIG;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_NO_LOAD_CONFIG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_ASYNC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_ASYNC
  stack[0].ival = OPENSSL_INIT_ASYNC;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_ASYNC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_ENGINE_RDRAND(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_ENGINE_RDRAND
  stack[0].ival = OPENSSL_INIT_ENGINE_RDRAND;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_ENGINE_RDRAND is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_ENGINE_DYNAMIC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_ENGINE_DYNAMIC
  stack[0].ival = OPENSSL_INIT_ENGINE_DYNAMIC;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_ENGINE_DYNAMIC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_ENGINE_OPENSSL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_ENGINE_OPENSSL
  stack[0].ival = OPENSSL_INIT_ENGINE_OPENSSL;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_ENGINE_OPENSSL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_ENGINE_CRYPTODEV(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_ENGINE_CRYPTODEV
  stack[0].ival = OPENSSL_INIT_ENGINE_CRYPTODEV;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_ENGINE_CRYPTODEV is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_ENGINE_CAPI(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_ENGINE_CAPI
  stack[0].ival = OPENSSL_INIT_ENGINE_CAPI;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_ENGINE_CAPI is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_ENGINE_PADLOCK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_ENGINE_PADLOCK
  stack[0].ival = OPENSSL_INIT_ENGINE_PADLOCK;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_ENGINE_PADLOCK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_ENGINE_AFALG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_ENGINE_AFALG
  stack[0].ival = OPENSSL_INIT_ENGINE_AFALG;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_ENGINE_AFALG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_ENGINE_ALL_BUILTIN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_ENGINE_ALL_BUILTIN
  stack[0].ival = OPENSSL_INIT_ENGINE_ALL_BUILTIN;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_ENGINE_ALL_BUILTIN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_ATFORK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_ATFORK
  stack[0].ival = OPENSSL_INIT_ATFORK;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_ATFORK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__OPENSSL_INIT_NO_ATEXIT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef OPENSSL_INIT_NO_ATEXIT
  stack[0].ival = OPENSSL_INIT_NO_ATEXIT;
  return 0;
#else
  env->die(env, stack, "OPENSSL_INIT_NO_ATEXIT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__TLSEXT_NAMETYPE_host_name(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TLSEXT_NAMETYPE_host_name
  stack[0].ival = TLSEXT_NAMETYPE_host_name;
  return 0;
#else
  env->die(env, stack, "TLSEXT_NAMETYPE_host_name is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__EVP_MAX_MD_SIZE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef EVP_MAX_MD_SIZE
  stack[0].ival = EVP_MAX_MD_SIZE;
  return 0;
#else
  env->die(env, stack, "EVP_MAX_MD_SIZE is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Net__SSLeay__Constant__SSL_MODE_SEND_FALLBACK_SCSV(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SSL_MODE_SEND_FALLBACK_SCSV
  stack[0].ival = SSL_MODE_SEND_FALLBACK_SCSV;
  return 0;
#else
  env->die(env, stack, "SSL_MODE_SEND_FALLBACK_SCSV is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}
