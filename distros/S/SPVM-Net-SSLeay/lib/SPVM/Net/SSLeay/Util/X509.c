// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

#include <openssl/x509v3.h>

static const char* FILE_NAME = "Net/SSLeay/Util/X509.c";

int32_t SPVM__Net__SSLeay__Util__X509__get_ocsp_uri(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_cert = stack[0].oval;
  
  if (!obj_cert) {
    return env->die(env, stack, "The X509 object $cert must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  X509* cert = env->get_pointer(env, stack, obj_cert);
  
  AUTHORITY_INFO_ACCESS* info = X509_get_ext_d2i(cert, NID_info_access, NULL, NULL);
  
  void* obj_ocsp_uri = NULL;
  
  if (info) {
    for (int32_t i = 0; i < sk_ACCESS_DESCRIPTION_num(info); i++) {
      ACCESS_DESCRIPTION *ad = sk_ACCESS_DESCRIPTION_value(info, i);
      
      if (OBJ_obj2nid(ad->method) == NID_ad_OCSP && ad->location->type == GEN_URI) {
        
        const char* ocsp_uri = (const char*)ASN1_STRING_get0_data(ad->location->d.uniformResourceIdentifier);
        int32_t ocsp_uri_length = ASN1_STRING_length(ad->location->d.uniformResourceIdentifier);
        
        obj_ocsp_uri = env->new_string(env, stack, ocsp_uri, ocsp_uri_length);
        
        break;
      }
    }
  }
  
  stack[0].oval = obj_ocsp_uri;
  
  return 0;
}
