#include "spvm_native.h"
#include "spvm_socket_util.h"

#include <assert.h>

static const char* FILE_NAME = "Sys/Socket/Addrinfo.c";

int32_t SPVM__Sys__Socket__Addrinfo__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t e = 0;
  
  struct addrinfo* addrinfo = env->new_memory_stack(env, stack, sizeof(struct addrinfo));

  void* obj_addrinfo = env->new_pointer_by_name(env, stack, "Sys::Socket::Addrinfo", addrinfo, &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_addrinfo;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Addrinfo__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {

  void* obj_addrinfo = stack[0].oval;
  
  struct addrinfo* st_addrinfo = env->get_pointer(env, stack, obj_addrinfo);
  
  assert(st_addrinfo);
  
  env->free_memory_stack(env, stack, st_addrinfo);

  env->set_pointer(env, stack, obj_addrinfo, NULL);
  
  return 0;
}

int32_t SPVM__Sys__Socket__Addrinfo__ai_flags(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct addrinfo* st_addrinfo = env->get_pointer(env, stack, obj_self);
  
  stack[0].ival = st_addrinfo->ai_flags;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Addrinfo__set_ai_flags(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct addrinfo* st_addrinfo = env->get_pointer(env, stack, obj_self);
  
  st_addrinfo->ai_flags = stack[1].ival;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Addrinfo__ai_family(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct addrinfo* st_addrinfo = env->get_pointer(env, stack, obj_self);
  
  stack[0].ival = st_addrinfo->ai_family;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Addrinfo__set_ai_family(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct addrinfo* st_addrinfo = env->get_pointer(env, stack, obj_self);
  
  st_addrinfo->ai_family = stack[1].ival;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Addrinfo__ai_socktype(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct addrinfo* st_addrinfo = env->get_pointer(env, stack, obj_self);
  
  stack[0].ival = st_addrinfo->ai_socktype;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Addrinfo__set_ai_socktype(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct addrinfo* st_addrinfo = env->get_pointer(env, stack, obj_self);
  
  st_addrinfo->ai_socktype = stack[1].ival;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Addrinfo__ai_protocol(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct addrinfo* st_addrinfo = env->get_pointer(env, stack, obj_self);
  
  stack[0].ival = st_addrinfo->ai_protocol;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Addrinfo__set_ai_protocol(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct addrinfo* st_addrinfo = env->get_pointer(env, stack, obj_self);
  
  st_addrinfo->ai_protocol = stack[1].ival;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Addrinfo__ai_addrlen(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct addrinfo* st_addrinfo = env->get_pointer(env, stack, obj_self);
  
  stack[0].ival = (int32_t)st_addrinfo->ai_addrlen;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Addrinfo__set_ai_addrlen(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct addrinfo* st_addrinfo = env->get_pointer(env, stack, obj_self);
  
  st_addrinfo->ai_addrlen = (socklen_t)stack[1].ival;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Addrinfo__copy_ai_addr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_self = stack[0].oval;
  
  struct addrinfo* st_addrinfo = env->get_pointer(env, stack, obj_self);
  
  struct sockaddr* ai_addr = st_addrinfo->ai_addr;
  
  void* obj_ai_addr_clone = NULL;
  void* tmp_ai_addr = NULL;
  if (ai_addr) {
    const char* sockaddr_class_name = NULL;
    switch (ai_addr->sa_family) {
      
      case AF_INET: {
        sockaddr_class_name = "Sys::Socket::Sockaddr::In";
        tmp_ai_addr = env->new_memory_stack(env, stack, sizeof(struct sockaddr_in));
        memcpy(tmp_ai_addr, ai_addr, sizeof(struct sockaddr_in));
        break;
      }
      case AF_INET6: {
        sockaddr_class_name = "Sys::Socket::Sockaddr::In6";
        tmp_ai_addr = env->new_memory_stack(env, stack, sizeof(struct sockaddr_in6));
        memcpy(tmp_ai_addr, ai_addr, sizeof(struct sockaddr_in6));
        break;
      }
      default : {
        assert(0);
      }
    }
    
    // Calls the clone method.
    {
      void* obj_ai_addr = env->new_pointer_by_name(env, stack, sockaddr_class_name, tmp_ai_addr, &e, FILE_NAME, __LINE__);
      if (e) { return e; }
      
      stack[0].oval = obj_ai_addr;
      int32_t args_stack_length = 1;
      e = env->call_instance_method_by_name(env, stack, obj_ai_addr, "clone", args_stack_length, FILE_NAME, __LINE__);
      if (e) { return e; };
      obj_ai_addr_clone = stack[0].oval;
    }
  }
  
  stack[0].oval = obj_ai_addr_clone;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Addrinfo__copy_ai_canonname(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct addrinfo* st_addrinfo = env->get_pointer(env, stack, obj_self);
  
  char* ai_canonname = st_addrinfo->ai_canonname;
  
  void* obj_ai_canonname = NULL;
  if (ai_canonname) {
    obj_ai_canonname = env->new_string(env, stack, ai_canonname, strlen(ai_canonname));
  }
  
  stack[0].oval = obj_ai_canonname;
  
  return 0;
}
