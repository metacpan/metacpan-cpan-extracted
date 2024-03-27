// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "spvm_socket_util.h"

#include <assert.h>

static const char* FILE_NAME = "Sys/Socket/Ipv6_mreq.c";

int32_t SPVM__Sys__Socket__Ipv6_mreq__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  struct ipv6_mreq* multi_request = env->new_memory_block(env, stack, sizeof(struct ipv6_mreq));

  void* obj_multi_request = env->new_pointer_object_by_name(env, stack, "Sys::Socket::Ipv6_mreq", multi_request, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_multi_request;
  
  return 0;
}


int32_t SPVM__Sys__Socket__Ipv6_mreq__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_multi_request = stack[0].oval;
  
  struct ipv6_mreq* multi_request = env->get_pointer(env, stack, obj_multi_request);
  
  assert(multi_request);
  
  env->free_memory_block(env, stack, multi_request);
  env->set_pointer(env, stack, obj_multi_request, NULL);
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ipv6_mreq__ipv6mr_multiaddr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  struct ipv6_mreq* multi_request = env->get_pointer(env, stack, obj_self);
  
  struct in6_addr address = multi_request->ipv6mr_multiaddr;

  struct in6_addr* address_ret = env->new_memory_block(env, stack, sizeof(struct in6_addr));
  *address_ret = address;

  void* obj_address_ret = env->new_pointer_object_by_name(env, stack, "Sys::Socket::In6_addr", address_ret, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_address_ret;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ipv6_mreq__set_ipv6mr_multiaddr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct ipv6_mreq* multi_request = env->get_pointer(env, stack, obj_self);
  
  void* obj_address = stack[1].oval;
  struct in6_addr* address = env->get_pointer(env, stack, obj_address);

  multi_request->ipv6mr_multiaddr = *address;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ipv6_mreq__ipv6mr_interface(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  struct ipv6_mreq* multi_request = env->get_pointer(env, stack, obj_self);
  
  int32_t interface_index = multi_request->ipv6mr_interface;
  
  stack[0].ival = interface_index;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ipv6_mreq__set_ipv6mr_interface(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct ipv6_mreq* multi_request = env->get_pointer(env, stack, obj_self);
  
  int32_t interface_index = stack[1].ival;
  multi_request->ipv6mr_interface = interface_index;
  
  return 0;
}
