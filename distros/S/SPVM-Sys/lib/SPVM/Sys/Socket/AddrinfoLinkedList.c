// Windows 8.1+
#define _WIN32_WINNT 0x0603

#include "spvm_native.h"

#include <assert.h>

#ifdef _WIN32
  #include <ws2tcpip.h>
  #include <winsock2.h>
  #include <io.h>
#else
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#endif

static const char* FILE_NAME = "Sys/Socket/AddrinfoLinkedList.c";

int32_t SPVM__Sys__Socket__AddrinfoLinkedList__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {

  void* obj_addrinfo = stack[0].oval;
  
  struct addrinfo* st_addrinfo = env->get_pointer(env, stack, obj_addrinfo);
  
  if (st_addrinfo) {
    freeaddrinfo(st_addrinfo);
  }
  
  env->set_pointer(env, stack, obj_addrinfo, NULL);
  
  return 0;
}

int32_t SPVM__Sys__Socket__AddrinfoLinkedList__to_array(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t e = 0;
  
  void* obj_addrinfo = stack[0].oval;
  
  struct addrinfo* st_addrinfo = env->get_pointer(env, stack, obj_addrinfo);
  
  int32_t length = 0;
  {
    struct addrinfo* cur_st_addrinfo = st_addrinfo;
    while (1) {
      if (cur_st_addrinfo) {
        length++;
        cur_st_addrinfo = cur_st_addrinfo->ai_next;
      }
      else {
        break;
      }
    }
  }
  
  int32_t addrinfo_basic_type_id = env->get_basic_type_id_by_name(env, stack, "Sys::Socket::Addrinfo", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  void* obj_addrinfos = env->new_object_array(env, stack, addrinfo_basic_type_id, length);
  
  int32_t index = 0;
  {
    struct addrinfo* cur_st_addrinfo = st_addrinfo;
    while (1) {
      if (cur_st_addrinfo) {
        
        int32_t fields_length = 1;
        
        struct addrinfo* tmp_st_addrinfo = NULL;
        tmp_st_addrinfo = env->new_memory_stack(env, stack, sizeof(struct addrinfo));
        memcpy(tmp_st_addrinfo, cur_st_addrinfo, sizeof(struct addrinfo));
        
        void* obj_addrinfo = env->new_pointer_by_name(env, stack, "Sys::Socket::Addrinfo", tmp_st_addrinfo, &e, FILE_NAME, __LINE__);
        if (e) { return e; }
        
        env->set_elem_object(env, stack, obj_addrinfos, index, obj_addrinfo);
        
        index++;
        cur_st_addrinfo = cur_st_addrinfo->ai_next;
      }
      else {
        break;
      }
    }
  }
  
  stack[0].oval = obj_addrinfos;
  
  return 0;
}
