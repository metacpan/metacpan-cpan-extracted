#include "spvm_native.h"

#include <assert.h>

#ifdef _WIN32
  #include <ws2tcpip.h>
  #include <winsock2.h>
  #include <io.h>
#else
  #include <sys/socket.h>
  #include <netinet/in.h>
#endif

const char* FILE_NAME = "Sys/Socket/Ip_mreq_source.c";

int32_t SPVM__Sys__Socket__Ip_mreq_source__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  struct ip_mreq_source* multi_request_source = env->new_memory_stack(env, stack, sizeof(struct ip_mreq_source));

  void* obj_multi_request_source = env->new_pointer_by_name(env, stack, "Sys::Socket::Ip_mreq_source", multi_request_source, &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_multi_request_source;
  
  return 0;
}


int32_t SPVM__Sys__Socket__Ip_mreq_source__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_multi_request_source = stack[0].oval;
  
  struct ip_mreq_source* multi_request_source = env->get_pointer(env, stack, obj_multi_request_source);
  
  assert(multi_request_source);
  
  env->free_memory_stack(env, stack, multi_request_source);
  env->set_pointer(env, stack, obj_multi_request_source, NULL);
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ip_mreq_source__imr_multiaddr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_self = stack[0].oval;
  
  struct ip_mreq_source* multi_request_source = env->get_pointer(env, stack, obj_self);
  
  struct in_addr address = multi_request_source->imr_multiaddr;

  struct in_addr* address_ret = env->new_memory_stack(env, stack, sizeof(struct in_addr));
  *address_ret = address;

  void* obj_address_ret = env->new_pointer_by_name(env, stack, "Sys::Socket::In_addr", address_ret, &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_address_ret;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ip_mreq_source__set_imr_multiaddr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct ip_mreq_source* multi_request_source = env->get_pointer(env, stack, obj_self);
  
  void* obj_address = stack[1].oval;
  struct in_addr* address = env->get_pointer(env, stack, obj_address);

  multi_request_source->imr_multiaddr = *address;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ip_mreq_source__imr_interface(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_self = stack[0].oval;
  
  struct ip_mreq_source* multi_request_source = env->get_pointer(env, stack, obj_self);
  
  struct in_addr address = multi_request_source->imr_interface;

  struct in_addr* address_ret = env->new_memory_stack(env, stack, sizeof(struct in_addr));
  *address_ret = address;

  void* obj_address_ret = env->new_pointer_by_name(env, stack, "Sys::Socket::In_addr", address_ret, &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_address_ret;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ip_mreq_source__set_imr_interface(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct ip_mreq_source* multi_request_source = env->get_pointer(env, stack, obj_self);
  
  void* obj_address = stack[1].oval;
  struct in_addr* address = env->get_pointer(env, stack, obj_address);

  multi_request_source->imr_interface = *address;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ip_mreq_source__imr_sourceaddr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_self = stack[0].oval;
  
  struct ip_mreq_source* multi_request_source = env->get_pointer(env, stack, obj_self);
  
  struct in_addr address = multi_request_source->imr_sourceaddr;

  struct in_addr* address_ret = env->new_memory_stack(env, stack, sizeof(struct in_addr));
  *address_ret = address;

  void* obj_address_ret = env->new_pointer_by_name(env, stack, "Sys::Socket::In_addr", address_ret, &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_address_ret;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ip_mreq_source__set_imr_sourceaddr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct ip_mreq_source* multi_request_source = env->get_pointer(env, stack, obj_self);
  
  void* obj_address = stack[1].oval;
  struct in_addr* address = env->get_pointer(env, stack, obj_address);

  multi_request_source->imr_sourceaddr = *address;
  
  return 0;
}
