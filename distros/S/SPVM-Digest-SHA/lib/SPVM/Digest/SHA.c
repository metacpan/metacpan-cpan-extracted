#include "spvm_native.h"

#include <string.h>
#include <assert.h>

const char* FILE_NAME = "SPVM/Digest/SHA.c";

#define Copy(src, dest, nitems, type) memcpy(dest, src, (nitems) * sizeof(type))
#define Zero(dest, nitems, type) memset(dest, 0, (nitems) * sizeof(type))

#include "sha.c"

static const int ix2alg[] =
  {1,1,1,224,224,224,256,256,256,384,384,384,512,512,512,
  512224,512224,512224,512256,512256,512256};

#define MAX_WRITE_SIZE 16384

int32_t SPVM__Digest__SHA__new(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t e;
  
  int32_t alg = stack[0].ival;
  
  void* obj_self = env->new_object_by_name(env, stack, "Digest::SHA", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  SHA *state = env->new_memory_stack(env, stack, sizeof(SHA));

  if (!shainit(state, alg)) {
    env->free_memory_stack(env, stack, state);
    return env->die(env, stack, "Can't initalize SHA state. The specified algorithm is %d", alg, FILE_NAME, __LINE__);
  }
  
  void* obj_state = env->new_object_by_name(env, stack, "Digest::SHA::State", &e, FILE_NAME, __LINE__);
  
  env->set_pointer(env, stack, obj_state, state);
  
  env->set_field_object_by_name(env, stack, obj_self, "Digest::SHA", "state", "Digest::SHA::State", obj_state, &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Digest__SHA__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e;
  
  void* obj_self = stack[0].oval;
  
  void* obj_state = env->get_field_object_by_name(env, stack, obj_self, "Digest::SHA", "state", "Digest::SHA::State", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  SHA* state = env->get_pointer(env, stack, obj_state);
  assert(state);
  
  env->free_memory_stack(env, stack, state);
  
  return 0;
}

// SHA
static int32_t SPVM__Digest__SHA__sha(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  unsigned char *data;
  int32_t len;
  SHA sha;
  char *result;

  void* obj_data = stack[0].oval;
  
  if (!obj_data) {
    return env->die(env, stack, "The input data must be defined", FILE_NAME, __LINE__);
  }

  int32_t ix = stack[1].ival;

  int32_t alg = ix2alg[ix];
  if (!shainit(&sha, alg)) {
    return env->die(env, stack, "Can't initalize SHA state. The specified algorithm is %d", alg, FILE_NAME, __LINE__);
  }

  data = (unsigned char *)env->get_chars(env, stack, obj_data);
  len = env->length(env, stack, obj_data);
  
  while (len > MAX_WRITE_SIZE) {
    shawrite(data, MAX_WRITE_SIZE << 3, &sha);
    data += MAX_WRITE_SIZE;
    len  -= MAX_WRITE_SIZE;
  }
  shawrite(data, (ULNG) len << 3, &sha);

  shafinish(&sha);
  len = 0;
  
  if (ix % 3 == 0) {
    result = (char *) shadigest(&sha);
    len = sha.digestlen;
  }
  else if (ix % 3 == 1) {
    result = shahex(&sha);
  }
  else {
    result = shabase64(&sha);
  }

  void* obj_result = env->new_string(env, stack, result, len > 0 ? len : strlen(result));
  
  stack[0].oval = obj_result;
  return 0;
}

const static int32_t DIGEST_SHA_SHA1 = 0;
const static int32_t DIGEST_SHA_SHA1_HEX = 1;
const static int32_t DIGEST_SHA_SHA1_BASE64 = 2;
const static int32_t DIGEST_SHA_SHA224 = 3;
const static int32_t DIGEST_SHA_SHA224_HEX = 4;
const static int32_t DIGEST_SHA_SHA224_BASE64 = 5;
const static int32_t DIGEST_SHA_SHA256 = 6;
const static int32_t DIGEST_SHA_SHA256_HEX = 7;
const static int32_t DIGEST_SHA_SHA256_BASE64 = 8;
const static int32_t DIGEST_SHA_SHA384 = 9;
const static int32_t DIGEST_SHA_SHA384_HEX = 10;
const static int32_t DIGEST_SHA_SHA384_BASE64 = 11;
const static int32_t DIGEST_SHA_SHA512 = 12;
const static int32_t DIGEST_SHA_SHA512_HEX = 13;
const static int32_t DIGEST_SHA_SHA512_BASE64 = 14;
const static int32_t DIGEST_SHA_SHA512224 = 15;
const static int32_t DIGEST_SHA_SHA512224_HEX = 16;
const static int32_t DIGEST_SHA_SHA512224_BASE64 = 17;
const static int32_t DIGEST_SHA_SHA512256 = 18;
const static int32_t DIGEST_SHA_SHA512256_HEX = 19;
const static int32_t DIGEST_SHA_SHA512256_BASE64 = 20;

int32_t SPVM__Digest__SHA__sha1(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA1; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha1_hex(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA1_HEX; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha1_base64(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA1_BASE64; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha224(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA224; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha224_hex(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA224_HEX; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha224_base64(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA224_BASE64; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha256(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA256; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha256_hex(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA256_HEX; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha256_base64(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA256_BASE64; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha384(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA384; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha384_hex(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA384_HEX; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha384_base64(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA384_BASE64; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha512(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA512; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha512_hex(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA512_HEX; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha512_base64(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA512_BASE64; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha512224(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA512224; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha512224_hex(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA512224_HEX; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha512224_base64(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA512224_BASE64; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha512256(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA512256; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha512256_hex(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA512256_HEX; return SPVM__Digest__SHA__sha(env, stack); }
int32_t SPVM__Digest__SHA__sha512256_base64(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_SHA512256_BASE64; return SPVM__Digest__SHA__sha(env, stack); }

// HMAC SHA
static int32_t SPVM__Digest__SHA__hmac_sha(SPVM_ENV* env, SPVM_VALUE* stack) {
  unsigned char *key = (unsigned char *) "";
  unsigned char *data;
  int32_t len = 0;
  HMAC hmac;
  char *result;
  
  void* obj_data = stack[0].oval;
  
  if (!obj_data) {
    return env->die(env, stack, "The input data must be defined", FILE_NAME, __LINE__);
  }
  data = (unsigned char *)env->get_chars(env, stack, obj_data);

  void* obj_key = stack[1].oval;
  
  if (obj_key) {
    key = (unsigned char *)env->get_chars(env, stack, obj_key);
    len = env->length(env, stack, obj_key);
  }

  int32_t ix = stack[2].ival;
  int32_t alg = ix2alg[ix];
  if (hmacinit(&hmac, alg, key, (unsigned int) len) == NULL) {
    return env->die(env, stack, "Can't initalize HMAC. The specified algorithm is %d", alg, FILE_NAME, __LINE__);
  }
  len = env->length(env, stack, obj_data);
  while (len > MAX_WRITE_SIZE) {
    hmacwrite(data, MAX_WRITE_SIZE << 3, &hmac);
    data += MAX_WRITE_SIZE;
    len  -= MAX_WRITE_SIZE;
  }
  hmacwrite(data, (ULNG) len << 3, &hmac);
  hmacfinish(&hmac);
  len = 0;
  if (ix % 3 == 0) {
    result = (char *) hmacdigest(&hmac);
    len = hmac.digestlen;
  }
  else if (ix % 3 == 1) {
    result = hmachex(&hmac);
  }
  else {
    result = hmacbase64(&hmac);
  }
  
  
  void* obj_result = env->new_string(env, stack, result, len > 0 ? len : strlen(result));
  
  stack[0].oval = obj_result;
  return 0;
}

const static int32_t DIGEST_SHA_HMAC_SHA1 = 0;
const static int32_t DIGEST_SHA_HMAC_SHA1_HEX = 1;
const static int32_t DIGEST_SHA_HMAC_SHA1_BASE64 = 2;
const static int32_t DIGEST_SHA_HMAC_SHA224 = 3;
const static int32_t DIGEST_SHA_HMAC_SHA224_HEX = 4;
const static int32_t DIGEST_SHA_HMAC_SHA224_BASE64 = 5;
const static int32_t DIGEST_SHA_HMAC_SHA256 = 6;
const static int32_t DIGEST_SHA_HMAC_SHA256_HEX = 7;
const static int32_t DIGEST_SHA_HMAC_SHA256_BASE64 = 8;
const static int32_t DIGEST_SHA_HMAC_SHA384 = 9;
const static int32_t DIGEST_SHA_HMAC_SHA384_HEX = 10;
const static int32_t DIGEST_SHA_HMAC_SHA384_BASE64 = 11;
const static int32_t DIGEST_SHA_HMAC_SHA512 = 12;
const static int32_t DIGEST_SHA_HMAC_SHA512_HEX = 13;
const static int32_t DIGEST_SHA_HMAC_SHA512_BASE64 = 14;
const static int32_t DIGEST_SHA_HMAC_SHA512224 = 15;
const static int32_t DIGEST_SHA_HMAC_SHA512224_HEX = 16;
const static int32_t DIGEST_SHA_HMAC_SHA512224_BASE64 = 17;
const static int32_t DIGEST_SHA_HMAC_SHA512256 = 18;
const static int32_t DIGEST_SHA_HMAC_SHA512256_HEX = 19;
const static int32_t DIGEST_SHA_HMAC_SHA512256_BASE64 = 20;


int32_t SPVM__Digest__SHA__hmac_sha1(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA1; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha1_hex(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA1_HEX; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha1_base64(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA1_BASE64; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha224(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA224; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha224_hex(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA224_HEX; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha224_base64(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA224_BASE64; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha256(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA256; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha256_hex(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA256_HEX; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha256_base64(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA256_BASE64; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha384(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA384; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha384_hex(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA384_HEX; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha384_base64(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA384_BASE64; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha512(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA512; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha512_hex(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA512_HEX; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha512_base64(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA512_BASE64; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha512224(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA512224; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha512224_hex(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA512224_HEX; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha512224_base64(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA512224_BASE64; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha512256(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA512256; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha512256_hex(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA512256_HEX; return SPVM__Digest__SHA__hmac_sha(env, stack); }
int32_t SPVM__Digest__SHA__hmac_sha512256_base64(SPVM_ENV* env, SPVM_VALUE* stack) { stack[2].ival = DIGEST_SHA_HMAC_SHA512256_BASE64; return SPVM__Digest__SHA__hmac_sha(env, stack); }

int32_t SPVM__Digest__SHA__hashsize(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e;
  
  void* obj_self = stack[0].oval;
  
  void* obj_state = env->get_field_object_by_name(env, stack, obj_self, "Digest::SHA", "state", "Digest::SHA::State", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  SHA* state = env->get_pointer(env, stack, obj_state);
  
  int32_t hashsize = state->digestlen;
  
  stack[0].ival = hashsize;
  
  return 0;
}

int32_t SPVM__Digest__SHA__algorithm(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e;
  
  void* obj_self = stack[0].oval;
  
  void* obj_state = env->get_field_object_by_name(env, stack, obj_self, "Digest::SHA", "state", "Digest::SHA::State", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  SHA* state = env->get_pointer(env, stack, obj_state);
  
  int32_t hashsize = state->alg;
  
  stack[0].ival = hashsize;
  
  return 0;
}

int32_t SPVM__Digest__SHA__add(SPVM_ENV* env, SPVM_VALUE* stack) {
  int i;
  unsigned char *data;
  int32_t len;
  
  int32_t e;
  
  void* obj_self = stack[0].oval;
  
  void* obj_state = env->get_field_object_by_name(env, stack, obj_self, "Digest::SHA", "state", "Digest::SHA::State", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  void* obj_data = stack[1].oval;
  
  data = (unsigned char *)env->get_chars(env, stack, obj_data);
  len = env->length(env, stack, obj_data);
  
  SHA* state = env->get_pointer(env, stack, obj_state);
  
  while (len > MAX_WRITE_SIZE) {
    shawrite(data, MAX_WRITE_SIZE << 3, state);
    data += MAX_WRITE_SIZE;
    len  -= MAX_WRITE_SIZE;
  }
  shawrite(data, (ULNG) len << 3, state);
  
  return 0;
}

const static int32_t DIGEST_SHA_DIGEST = 0;
const static int32_t DIGEST_SHA_HEXDIGEST = 1;
const static int32_t DIGEST_SHA_B64DIGEST = 2;

static int32_t SPVM__Digest__SHA__digest_common(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e;
  
  int32_t len;
  char *result;
  
  void* obj_self = stack[0].oval;
  
  void* obj_state = env->get_field_object_by_name(env, stack, obj_self, "Digest::SHA", "state", "Digest::SHA::State", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  SHA* state = env->get_pointer(env, stack, obj_state);
  
  int32_t ix = stack[1].ival;
  
  shafinish(state);
  len = 0;
  if (ix == 0) {
    result = (char *) shadigest(state);
    len = state->digestlen;
  }
  else if (ix == 1) {
    result = shahex(state);
  }
  else {
    result = shabase64(state);
  }
  
  void* obj_result = env->new_string(env, stack, result, len > 0 ? len : strlen(result));
  
  stack[0].oval = obj_result;
  
  sharewind(state);
  
  return 0;
}

int32_t SPVM__Digest__SHA__digest(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_DIGEST; return SPVM__Digest__SHA__digest_common(env, stack); }
int32_t SPVM__Digest__SHA__hexdigest(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_HEXDIGEST; return SPVM__Digest__SHA__digest_common(env, stack); }
int32_t SPVM__Digest__SHA__b64digest(SPVM_ENV* env, SPVM_VALUE* stack) { stack[1].ival = DIGEST_SHA_B64DIGEST; return SPVM__Digest__SHA__digest_common(env, stack); }

int32_t SPVM__Digest__SHA__clone(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e;
  
  void* obj_self = stack[0].oval;

  void* obj_state = env->get_field_object_by_name(env, stack, obj_self, "Digest::SHA", "state", "Digest::SHA::State", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  SHA* state = env->get_pointer(env, stack, obj_state);

  void* obj_self_clone = env->new_object_by_name(env, stack, "Digest::SHA", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  SHA* state_clone = env->new_memory_stack(env, stack, sizeof(SHA));
  
  Copy(state, state_clone, 1, SHA);

  void* obj_state_clone = env->new_object_by_name(env, stack, "Digest::SHA::State", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  env->set_pointer(env, stack, obj_state_clone, state_clone);
  
  env->set_field_object_by_name(env, stack, obj_self_clone, "Digest::SHA", "state", "Digest::SHA::State", obj_state_clone, &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_self_clone;
  
  return 0;
}
