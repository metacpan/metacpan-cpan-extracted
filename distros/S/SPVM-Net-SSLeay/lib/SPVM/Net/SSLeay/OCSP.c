// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <assert.h>

#include <openssl/ssl.h>
#include <openssl/err.h>

#include <openssl/ocsp.h>

static const char* FILE_NAME = "Net/SSLeay/OCSP.c";

int32_t SPVM__Net__SSLeay__OCSP__response_status_str(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  int64_t code = stack[0].lval;
  
  const char* status_str = OCSP_response_status_str(code);
  
  assert(status_str);
  
  void* obj_status_str = env->new_string_nolen(env, stack, status_str);
  
  stack[0].oval = obj_status_str;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OCSP__response_status(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_resp = stack[0].oval;
  
  if (!obj_resp) {
    return env->die(env, stack, "The OCSP response $resp must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  OCSP_RESPONSE* resp = env->get_pointer(env, stack, obj_resp);
  
  int32_t status = OCSP_response_status(resp);
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OCSP__basic_verify(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_bs = stack[0].oval;
  
  void* obj_certs = stack[1].oval;
  
  void* obj_st = stack[2].oval;
  
  int64_t flags = stack[3].lval;
  
  if (!obj_bs) {
    return env->die(env, stack, "The OCSP_BASICRESP object $bs must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!obj_certs) {
    return env->die(env, stack, "The untrusted certificates $certs must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!obj_st) {
    return env->die(env, stack, "The trusted certificat store $certs must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  OCSP_BASICRESP* bs = env->get_pointer(env, stack, obj_bs);
  
  STACK_OF(X509)* x509s_stack = sk_X509_new_null();
  
  int32_t list_length = env->length(env, stack, obj_certs);
  
  for (int32_t i = 0; i < list_length; i++) {
    void* obj_X509 = env->get_elem_object(env, stack, obj_certs, i);
    X509* X509 = env->get_pointer(env, stack, obj_X509);
    sk_X509_push(x509s_stack, X509);
  }
  
  X509_STORE* st = env->get_pointer(env, stack, obj_st);
  
  int32_t status = OCSP_basic_verify(bs, x509s_stack, st, flags);
  
  sk_X509_free(x509s_stack);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]OCSP_basic_verify failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OCSP__basic_add1_cert(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_resp = stack[0].oval;
  
  void* obj_cert = stack[1].oval;
  
  if (!obj_resp) {
    return env->die(env, stack, "The OCSP_BASICRESP object $resp must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!obj_cert) {
    return env->die(env, stack, "The X509 object $cert must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  OCSP_BASICRESP* resp = env->get_pointer(env, stack, obj_resp);
  
  X509* cert = env->get_pointer(env, stack, obj_cert);
  
  int32_t status = OCSP_basic_add1_cert(resp, cert);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]OCSP_basic_add1_cert failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  // OCSP_basic_add1_certy increments the reference count of cert.
  {
    void* obj_certs_list = env->get_field_object_by_name(env, stack, obj_resp, "certs_list", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    stack[0].oval = obj_certs_list;
    stack[1].oval = obj_cert;
    env->call_instance_method_by_name(env, stack, "push", 2, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OCSP__check_nonce(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_req = stack[0].oval;
  
  void* obj_resp = stack[1].oval;
  
  if (!obj_req) {
    return env->die(env, stack, "The OCSP_REQUEST object $req must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!obj_resp) {
    return env->die(env, stack, "The OCSP_BASICRESP $resp must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  OCSP_REQUEST* req = env->get_pointer(env, stack, obj_req);
  
  OCSP_BASICRESP* resp = env->get_pointer(env, stack, obj_resp);
  
  int32_t ret = OCSP_check_nonce(req, resp);
  
  stack[0].ival = ret;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OCSP__check_validity(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_thisupd = stack[0].oval;
  
  void* obj_nextupd = stack[1].oval;
  
  int64_t sec = stack[2].lval;
  
  int64_t maxsec = stack[3].lval;
  
  if (!obj_thisupd) {
    return env->die(env, stack, "The ASN1_GENERALIZEDTIME object $thisupd must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!obj_nextupd) {
    return env->die(env, stack, "The ASN1_GENERALIZEDTIME $nextupd must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  ASN1_GENERALIZEDTIME* thisupd = env->get_pointer(env, stack, obj_thisupd);
  
  ASN1_GENERALIZEDTIME* nextupd = env->get_pointer(env, stack, obj_nextupd);
  
  int32_t ret = OCSP_check_validity(thisupd, nextupd, sec, maxsec);
  
  int32_t success = ret != 0;
  if (!success) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]OCSP_check_validity failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  stack[0].ival = ret;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OCSP__resp_count(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_bs = stack[0].oval;
  
  if (!obj_bs) {
    return env->die(env, stack, "The OCSP_BASICRESP object $bs must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  OCSP_BASICRESP* bs = env->get_pointer(env, stack, obj_bs);
  
  int32_t count = OCSP_resp_count(bs);
  
  stack[0].ival = count;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OCSP__single_get0_status(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_single = stack[0].oval;
  
  int32_t* reason_ref = stack[1].iref;
  
  void* obj_revtime_ref = stack[2].oval;
  
  void* obj_thisupd_ref = stack[3].oval;
  
  void* obj_nextupd_ref = stack[4].oval;
  
  if (obj_single) {
    return env->die(env, stack, "The OCSP_SINGLERESP object $single must be undef.", __func__, FILE_NAME, __LINE__);
  }
  
  OCSP_SINGLERESP* single = env->get_pointer(env, stack, obj_single);
  
  if (!obj_revtime_ref) {
    return env->die(env, stack, "$revtime_ref must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t revtime_ref_length = env->length(env, stack, obj_revtime_ref);
  
  if (!(revtime_ref_length == 1)) {
    return env->die(env, stack, "The length of $revtime_ref must be 1.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!obj_thisupd_ref) {
    return env->die(env, stack, "$thisupd_ref must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t thisupd_ref_length = env->length(env, stack, obj_thisupd_ref);
  
  if (!(thisupd_ref_length == 1)) {
    return env->die(env, stack, "The length of $thisupd_ref must be 1.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!obj_nextupd_ref) {
    return env->die(env, stack, "$nextupd_ref must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t nextupd_ref_length = env->length(env, stack, obj_nextupd_ref);
  
  if (!(nextupd_ref_length == 1)) {
    return env->die(env, stack, "The length of $nextupd_ref must be 1.", __func__, FILE_NAME, __LINE__);
  }
  
  int reason_tmp = 0;
  ASN1_GENERALIZEDTIME* revtime_ref_tmp[1] = {0};
  
  ASN1_GENERALIZEDTIME* thisupd_ref_tmp[1] = {0};
  
  ASN1_GENERALIZEDTIME* nextupd_ref_tmp[1] = {0};
  
  int32_t status = OCSP_single_get0_status(single, &reason_tmp, revtime_ref_tmp, thisupd_ref_tmp, nextupd_ref_tmp);
  
  if (!(status == -1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]OCSP_single_get0_status failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  *reason_ref = reason_tmp;
  
  ASN1_GENERALIZEDTIME* revtime = ASN1_STRING_dup(revtime_ref_tmp[0]);
  void* obj_address_revtime = env->new_pointer_object_by_name(env, stack, "Address", revtime, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_revtime;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::ASN1_GENERALIZEDTIME", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_revtime = stack[0].oval;
  env->set_elem_object(env, stack, obj_revtime_ref, 0, obj_revtime);
  
  ASN1_GENERALIZEDTIME* thisupd = ASN1_STRING_dup(thisupd_ref_tmp[0]);
  void* obj_address_thisupd = env->new_pointer_object_by_name(env, stack, "Address", thisupd, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_thisupd;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::ASN1_GENERALIZEDTIME", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_thisupd = stack[0].oval;
  env->set_elem_object(env, stack, obj_thisupd_ref, 0, obj_thisupd);
  
  ASN1_GENERALIZEDTIME* nextupd = ASN1_STRING_dup(nextupd_ref_tmp[0]);
  void* obj_address_nextupd = env->new_pointer_object_by_name(env, stack, "Address", nextupd, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_nextupd;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::ASN1_GENERALIZEDTIME", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_nextupd = stack[0].oval;
  env->set_elem_object(env, stack, obj_nextupd_ref, 0, obj_nextupd);
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OCSP__resp_find(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_bs = stack[0].oval;
  
  void* obj_id = stack[1].oval;
  
  int32_t last = stack[2].ival;
  
  if (!obj_bs) {
    return env->die(env, stack, "The OCSP_BASICRESP object $bs must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  OCSP_BASICRESP* bs = env->get_pointer(env, stack, obj_bs);
  
  if (!obj_id) {
    return env->die(env, stack, "The OCSP_CERTID object $id must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  OCSP_CERTID* id = env->get_pointer(env, stack, obj_id);
  
  int32_t found_index = OCSP_resp_find(bs, id, last);
  
  int32_t success = found_index != -1;
  if (!success) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]OCSP_resp_find failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  stack[0].ival = found_index;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OCSP__resp_get0(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_bs = stack[0].oval;
  
  int32_t idx = stack[1].ival;
  
  if (!obj_bs) {
    return env->die(env, stack, "The OCSP_BASICRESP object $bs must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  OCSP_BASICRESP* bs = env->get_pointer(env, stack, obj_bs);
  
  OCSP_SINGLERESP* singleresp = OCSP_resp_get0(bs, idx);
  
  if (!singleresp) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]OCSP_resp_get failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  void* obj_address_singleresp = env->new_pointer_object_by_name(env, stack, "Address", singleresp, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_singleresp;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::OCSP_SINGLERESP", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_singleresp = stack[0].oval;
  
  env->set_no_free(env, stack, obj_singleresp, 1);
  
  env->set_field_object_by_name(env, stack, obj_singleresp, "ref_ocsp_basicresp", obj_bs, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_singleresp;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OCSP__response_get1_basic(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_resp = stack[0].oval;
  
  if (!obj_resp) {
    return env->die(env, stack, "The OCSP_RESPONSE object $resp must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  OCSP_RESPONSE* resp = env->get_pointer(env, stack, obj_resp);
  
  if (!(OCSP_response_status(resp) == OCSP_RESPONSE_STATUS_SUCCESSFUL)) {
    return env->die(env, stack, "OCSP_response_status($resp) must be OCSP_RESPONSE_STATUS_SUCCESSFUL.", __func__, FILE_NAME, __LINE__);
  }
  
  OCSP_BASICRESP* basicresp = OCSP_response_get1_basic(resp);
  
  if (!basicresp) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]OCSP_response_get1_basic failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  void* obj_address_basicresp = env->new_pointer_object_by_name(env, stack, "Address", basicresp, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_basicresp;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::OCSP_BASICRESP", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_basicresp = stack[0].oval;
  
  env->set_no_free(env, stack, obj_basicresp, 1);
  
  env->set_field_object_by_name(env, stack, obj_basicresp, "ref_ocsp_response", obj_resp, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_basicresp;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OCSP__cert_to_id(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_dgst = stack[0].oval;
  
  void* obj_subject = stack[1].oval;
  
  void* obj_issuer = stack[2].oval;
  
  EVP_MD* dgst = env->get_pointer(env, stack, obj_dgst);
  
  if (!obj_subject) {
    return env->die(env, stack, "The X509 object $subject must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  X509* subject = env->get_pointer(env, stack, obj_subject);
  
  if (!obj_issuer) {
    return env->die(env, stack, "The X509 object $issuer must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  X509* issuer = env->get_pointer(env, stack, obj_issuer);
  
  OCSP_CERTID* certid = OCSP_cert_to_id(dgst, subject, issuer);
  
  if (!certid) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]OCSP_cert_to_id failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  void* obj_address_certid = env->new_pointer_object_by_name(env, stack, "Address", certid, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_certid;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::CERTID", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_certid = stack[0].oval;
  
  stack[0].oval = obj_certid;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OCSP__request_add0_id(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_req = stack[0].oval;
  
  void* obj_cid = stack[1].oval;
  
  if (!obj_cid) {
    return env->die(env, stack, "The OCSP_REQUEST object $req must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  OCSP_REQUEST* req = env->get_pointer(env, stack, obj_req);
  
  if (!obj_cid) {
    return env->die(env, stack, "The Net::SSLeay::OCSP_CERTID object $cid must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  OCSP_CERTID* cid = env->get_pointer(env, stack, obj_cid);
  
  OCSP_ONEREQ* onereq = OCSP_request_add0_id(req, cid);
  
  if (!onereq) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]OCSP_request_add0_id failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  void* obj_address_onereq = env->new_pointer_object_by_name(env, stack, "Address", onereq, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_onereq;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::OCSP_ONEREQ", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_onereq = stack[0].oval;
  
  env->set_no_free(env, stack, obj_onereq, 1);
  
  // cid must not be freed before req is freed.
  {
    void* obj_ocsp_certids_list = env->get_field_object_by_name(env, stack, obj_req, "ocsp_certidids_list", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    stack[0].oval = obj_ocsp_certids_list;
    stack[1].oval = obj_cid;
    env->call_instance_method_by_name(env, stack, "push", 2, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
  }
  
  // req must not be freed before onereq is freed.
  env->set_field_object_by_name(env, stack, obj_onereq, "ref_ocsp_request", obj_req, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_onereq;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OCSP__request_add1_nonce(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_req = stack[0].oval;
  
  void* obj_val = stack[1].oval;
  
  int32_t len = stack[2].ival;
  
  if (!obj_req) {
    return env->die(env, stack, "The OCSP_REQUEST object $req must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  OCSP_REQUEST* req = env->get_pointer(env, stack, obj_req);
  
  unsigned char* val = NULL;
  if (obj_val) {
    val = (unsigned char*)env->get_chars(env, stack, obj_val);
  }
  
  int32_t status = OCSP_request_add1_nonce(req, val, len);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]OCSP_request_add1_nonce failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

