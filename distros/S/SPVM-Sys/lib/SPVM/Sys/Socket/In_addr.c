// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "spvm_socket_util.h"

#include <assert.h>

static const char* FILE_NAME = "Sys/Socket/In_addr.c";

int32_t SPVM__Sys__Socket__In_addr__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  struct in_addr* address = env->new_memory_block(env, stack, sizeof(struct in_addr));
  
  void* obj_address = env->new_pointer_object_by_name(env, stack, "Sys::Socket::In_addr", address, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_address;
  
  return 0;
}

int32_t SPVM__Sys__Socket__In_addr__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_address = stack[0].oval;
  
  struct in_addr* address = env->get_pointer(env, stack, obj_address);
  
  assert(address);
  
  env->free_memory_block(env, stack, address);
  env->set_pointer(env, stack, obj_address, NULL);
  
  return 0;
}

int32_t SPVM__Sys__Socket__In_addr__s_addr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_address = stack[0].oval;
  
  struct in_addr* address = env->get_pointer(env, stack, obj_address);
  
  assert(address);
  
  stack[0].ival = address->s_addr;
  
  return 0;
}

int32_t SPVM__Sys__Socket__In_addr__set_s_addr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_address = stack[0].oval;
  
  struct in_addr* address = env->get_pointer(env, stack, obj_address);
  
  assert(address);
  
  address->s_addr = stack[1].ival;
  
  return 0;
}
