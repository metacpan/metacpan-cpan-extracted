#include "spvm_native.h"

#include <assert.h>

#ifdef _WIN32
  #include <ws2tcpip.h>
  #include <winsock2.h>
  #include <io.h>
#else
  #include <sys/types.h>
  #include <sys/socket.h>
  #include <netinet/in.h>
  #include <netinet/ip.h>
#endif

const char* FILE_NAME = "Sys/Socket/Ip_mreq.c";

int32_t SPVM__Sys__Socket__Ip_mreq__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  struct ip_mreq* multi_request = env->new_memory_stack(env, stack, sizeof(struct ip_mreq));

  void* obj_multi_request = env->new_pointer_by_name(env, stack, "Sys::Socket::Ip_mreq", multi_request, &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_multi_request;
  
  return 0;
}


int32_t SPVM__Sys__Socket__Ip_mreq__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_multi_request = stack[0].oval;
  
  struct ip_mreq* multi_request = env->get_pointer(env, stack, obj_multi_request);
  
  assert(multi_request);
  
  env->free_memory_stack(env, stack, multi_request);
  env->set_pointer(env, stack, obj_multi_request, NULL);
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ip_mreq__imr_multiaddr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_self = stack[0].oval;
  
  struct ip_mreq* multi_request = env->get_pointer(env, stack, obj_self);
  
  struct in_addr address = multi_request->imr_multiaddr;

  struct in_addr* address_ret = env->new_memory_stack(env, stack, sizeof(struct in_addr));
  *address_ret = address;

  void* obj_address_ret = env->new_pointer_by_name(env, stack, "Sys::Socket::In_addr", address_ret, &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_address_ret;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ip_mreq__set_imr_multiaddr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct ip_mreq* multi_request = env->get_pointer(env, stack, obj_self);
  
  void* obj_address = stack[1].oval;
  struct in_addr* address = env->get_pointer(env, stack, obj_address);

  multi_request->imr_multiaddr = *address;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ip_mreq__imr_interface(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_self = stack[0].oval;
  
  struct ip_mreq* multi_request = env->get_pointer(env, stack, obj_self);
  
  struct in_addr imr_interface = multi_request->imr_interface;

  struct in_addr* imr_interface_ret = env->new_memory_stack(env, stack, sizeof(struct in_addr));
  *imr_interface_ret = imr_interface;

  void* obj_imr_interface_ret = env->new_pointer_by_name(env, stack, "Sys::Socket::In_addr", imr_interface_ret, &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_imr_interface_ret;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ip_mreq__set_imr_interface(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct ip_mreq* multi_request = env->get_pointer(env, stack, obj_self);
  
  void* obj_imr_interface = stack[1].oval;
  struct in_addr* imr_interface = env->get_pointer(env, stack, obj_imr_interface);

  multi_request->imr_interface = *imr_interface;
  
  return 0;
}
