// Copyright (c) 2023 Yuki Kimoto
// MIT License

// Windows 8.1+
#define _WIN32_WINNT 0x0603

#include "spvm_native.h"
#include "spvm_socket_util.h"

#include <errno.h>
#include <assert.h>

#if defined(_WIN32)
#else
  #include <sys/un.h>
#endif

static const char* FILE_NAME = "Sys/Socket.c";

int32_t SPVM__Sys__Socket__htonl(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t hostlong = stack[0].ival;
  
  int32_t netlong = htonl(hostlong);
  
  stack[0].ival = netlong;
  
  return 0;
}

int32_t SPVM__Sys__Socket__htons(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int16_t hostshort = stack[0].sval;
  
  int16_t netshort = htons(hostshort);
  
  stack[0].sval = netshort;
  
  return 0;
}

int32_t SPVM__Sys__Socket__ntohl(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t netlong = stack[0].ival;
  
  int32_t hostlong = ntohl(netlong);
  
  stack[0].ival = hostlong;
  
  return 0;
}

int32_t SPVM__Sys__Socket__ntohs(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int16_t netshort = stack[0].sval;
  
  int16_t hostshort = htons(netshort);
  
  stack[0].sval = hostshort;
  
  return 0;
}

int32_t SPVM__Sys__Socket__inet_aton(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  int32_t InvalidNetworkAddress = env->get_basic_type_id_by_name(env, stack, "Sys::Socket::Error::InetInvalidNetworkAddress", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  void* obj_cp = stack[0].oval;
  
  if (!obj_cp) {
    return env->die(env, stack, "The address string $cp must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* cp = env->get_chars(env, stack, obj_cp);
  
  void* obj_inp = stack[1].oval;
  
  if (!obj_inp) {
    return env->die(env, stack, "The address data structure $inp must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  struct in_addr* st_in_addr = env->get_pointer(env, stack, obj_inp);
  
#if defined(_WIN32)
  int32_t status = inet_pton(AF_INET, cp, st_in_addr);
#else
  int32_t status = inet_aton(cp, st_in_addr);
#endif

  if (status == 0) {
    env->die(env, stack, "The got address is not a valid network address.", __func__, FILE_NAME, __LINE__);
    return InvalidNetworkAddress;
  }
  else if (status == -1) {
    env->die(env, stack, "[System Error]inet_aton() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__inet_ntoa(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_in = stack[0].oval;
  
  if (!obj_in) {
    return env->die(env, stack, "The address data structure $in must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  struct in_addr* in = env->get_pointer(env, stack, obj_in);
  
  char* output_address = inet_ntoa(*in);
  
  if (!output_address) {
    env->die(env, stack, "[System Error]inet_ntoa() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  void* obj_output_address;
  if (output_address) {
    obj_output_address = env->new_string(env, stack, output_address, strlen(output_address));
  }
  else {
    assert(0);
  }
  
  stack[0].oval = obj_output_address;
  
  return 0;
}

int32_t SPVM__Sys__Socket__inet_pton(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  int32_t InvalidNetworkAddress = env->get_basic_type_id_by_name(env, stack, "Sys::Socket::Error::InetInvalidNetworkAddress", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  int32_t In_addr = env->get_basic_type_id(env, stack, "Sys::Socket::In_addr");
  if (error_id) { return error_id; }
  
  int32_t In6_addr = env->get_basic_type_id(env, stack, "Sys::Socket::In6_addr");
  if (error_id) { return error_id; }
  
  int32_t af = stack[0].ival;
  
  if (!(af == AF_INET || af == AF_INET6)) {
    return env->die(env, stack, "The address family $af must be AF_INET or AF_INET6.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_src = stack[1].oval;
  
  if (!obj_src) {
    return env->die(env, stack, "The address string $src must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* src = env->get_chars(env, stack, obj_src);
  
  void* obj_dst = stack[2].oval;
  
  if (!obj_dst) {
    return env->die(env, stack, "The address data structure $dst must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  if (af == AF_INET) {
    if (!env->is_type_by_name(env, stack, obj_dst, "Sys::Socket::In_addr", 0)) {
      return env->die(env, stack, "The address data structure $dst must be the Sys::Socket::In_addr class.", __func__, FILE_NAME, __LINE__);
    }
  }
  else if (af == AF_INET6) {
    if (!env->is_type_by_name(env, stack, obj_dst, "Sys::Socket::In6_addr", 0)) {
      return env->die(env, stack, "The address data structure $dst must be the Sys::Socket::In6_addr class.", __func__, FILE_NAME, __LINE__);
    }
  }
  else {
    return env->die(env, stack, "The type of The address data structure $dst is invalid.", __func__, FILE_NAME, __LINE__);
  }
  
  void* dst = env->get_pointer(env, stack, obj_dst);
  
  int32_t status = inet_pton(af, src, dst);
  
  if (status == 0) {
    env->die(env, stack, "The got address is not a valid network address.", __func__, FILE_NAME, __LINE__);
    return InvalidNetworkAddress;
  }
  else if (status == -1) {
    env->die(env, stack, "[System Error]inet_pton() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__inet_ntop(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  // The address family
  int32_t af = stack[0].ival;
  
  if (!(af == AF_INET || af == AF_INET6)) {
    return env->die(env, stack, "The address family $af must be AF_INET or AF_INET6.", __func__, FILE_NAME, __LINE__);
  }
  
  // The input address
  void* obj_src = stack[1].oval;
  if (!obj_src) {
    return env->die(env, stack, "The address data structure $src must be defined.", __func__, FILE_NAME, __LINE__);
  }
  void* src = env->get_pointer(env, stack, obj_src);
  
  // The output address
  void* obj_dst = stack[2].oval;
  if (!obj_dst) {
    return env->die(env, stack, "The address string $dst must be defined.", __func__, FILE_NAME, __LINE__);
  }
  char* dst = (char*)env->get_chars(env, stack, obj_dst);
  
  // The size of the output address
  int32_t size = stack[3].ival;
  
  const char* dst_ret = inet_ntop(af, src, dst, size);
  
  if (!dst_ret) {
    env->die(env, stack, "[System Error]inet_ntop() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].oval = obj_dst;
  
  return 0;
}

int32_t SPVM__Sys__Socket__socket(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t domain = stack[0].ival;
  
  int32_t type = stack[1].ival;
  
  int32_t protocol = stack[2].ival;
  
  int32_t sockfd = socket(domain, type, protocol);
  
  if (sockfd == -1) {
    env->die(env, stack, "[System Error]socket() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = sockfd;
  
  return 0;
}

int32_t SPVM__Sys__Socket__connect(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  void* obj_addr = stack[1].oval;
  
  if (!obj_addr) {
    return env->die(env, stack, "The socket address $addr must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const struct sockaddr* addr = env->get_pointer(env, stack, obj_addr);
  
  int32_t addrlen = stack[2].ival;
  
  int32_t status = connect(sockfd, addr, addrlen);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]connect() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__bind(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  void* obj_addr = stack[1].oval;
  
  if (!obj_addr) {
    return env->die(env, stack, "The socket address $addr must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const struct sockaddr* addr = env->get_pointer(env, stack, obj_addr);
  
  int32_t addrlen = stack[2].ival;
  
  int32_t status = bind(sockfd, addr, addrlen);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]bind() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__accept(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  void* obj_addr = stack[1].oval;
  
  if (!obj_addr) {
    return env->die(env, stack, "The socket address $addr must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  struct sockaddr* addr = env->get_pointer(env, stack, obj_addr);
  
  int32_t* addrlen_ref = stack[2].iref;
  
  socklen_t sl_addrlen = *addrlen_ref;
  
  int32_t status = accept(sockfd, addr, &sl_addrlen);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]accept() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  *addrlen_ref = sl_addrlen;
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__listen(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  int32_t backlog = stack[1].ival;
  
  int32_t status = listen(sockfd, backlog);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]listen() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__shutdown(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  int32_t how = stack[1].ival;
  
  int32_t status = shutdown(sockfd, how);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]shutdown() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__closesocket(SPVM_ENV* env, SPVM_VALUE* stack) {
#if !defined(_WIN32)
  env->die(env, stack, "Sys::Socket#closesocket method is not supported in this system(!defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t s = stack[0].ival;
  
  int32_t status = closesocket(s);
  
  if (!(status == 0)) {
    env->die(env, stack, "[System Error]close() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Socket__recv(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  void* obj_buf = stack[1].oval;
  
  if (!obj_buf) {
    return env->die(env, stack, "The buffer $buf must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* buf = (char*)env->get_chars(env, stack, obj_buf);
  int32_t buf_length = env->length(env, stack, obj_buf);
  
  int32_t len = stack[2].ival;
  
  int32_t flags = stack[3].ival;
  
  int32_t buf_offset = stack[4].ival;
  if (!(len <= buf_length - buf_offset)) {
    return env->die(env, stack, "The data length $len must be less than the length of the buffer $buf minus the buffer offset $buf_offset.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t read_length = recv(sockfd, buf + buf_offset, len, flags);
  
  if (read_length == -1) {
    env->die(env, stack, "[System Error]recv() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = read_length;
  
  return 0;
}

int32_t SPVM__Sys__Socket__recvfrom(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  void* obj_buf = stack[1].oval;
  
  if (!obj_buf) {
    return env->die(env, stack, "The buffer $buf must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* buf = (char*)env->get_chars(env, stack, obj_buf);
  int32_t buf_length = env->length(env, stack, obj_buf);
  
  int32_t len = stack[2].ival;
  
  int32_t flags = stack[3].ival;
  
  void* obj_src_addr = stack[4].oval;
  
  struct sockaddr* src_addr = NULL;
  if (obj_src_addr) {
    src_addr = env->get_pointer(env, stack, obj_src_addr);
  }
  
  int32_t* addrlen_ref = stack[5].iref;
  
  int32_t buf_offset = stack[6].ival;
  
  if (!(len <= buf_length - buf_offset)) {
    return env->die(env, stack, "The data length $len must be less than the length of the buffer $buf minus the buffer offset $buf_offset.", __func__, FILE_NAME, __LINE__);
  }
  
  socklen_t addrlen_ref_tmp = -1;
  int32_t read_length = recvfrom(sockfd, buf + buf_offset, len, flags, src_addr, &addrlen_ref_tmp);
  
  if (read_length == -1) {
    env->die(env, stack, "[System Error]recvfrom() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  *addrlen_ref = addrlen_ref_tmp;
  
  stack[0].ival = read_length;
  
  return 0;
}

int32_t SPVM__Sys__Socket__send(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  void* obj_buf = stack[1].oval;
  
  if (!obj_buf) {
    return env->die(env, stack, "The buffer $buf must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* buf = env->get_chars(env, stack, obj_buf);
  int32_t buf_length = env->length(env, stack, obj_buf);
  
  int32_t len = stack[2].ival;
  
  int32_t flags = stack[3].ival;
  
  int32_t buf_offset = stack[4].ival;
  if (!(len <= buf_length - buf_offset)) {
    return env->die(env, stack, "The data length $len must be less than the length of the buffer $buf minus the buffer offset $buf_offset.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t bytes_length = send(sockfd, buf + buf_offset, len, flags);
  
  if (bytes_length == -1) {
    env->die(env, stack, "[System Error]send() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = bytes_length;
  
  return 0;
}

int32_t SPVM__Sys__Socket__sendto(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  void* obj_buf = stack[1].oval;
  
  if (!obj_buf) {
    return env->die(env, stack, "The buffer $buf must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* buf = env->get_chars(env, stack, obj_buf);
  int32_t buf_length = env->length(env, stack, obj_buf);
  
  int32_t len = stack[2].ival;
  
  int32_t flags = stack[3].ival;
  
  void* obj_addr = stack[4].oval;
  
  const struct sockaddr* addr = NULL;
  
  if (obj_addr) {
    addr = env->get_pointer(env, stack, obj_addr);
  }
  
  int32_t addrlen = stack[5].ival;
  
  int32_t buf_offset = stack[6].ival;
  if (!(len <= buf_length - buf_offset)) {
    return env->die(env, stack, "The data length $len must be less than the length of the buffer $buf minus the buffer offset $buf_offset.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t bytes_length = sendto(sockfd, buf + buf_offset, len, flags, addr, addrlen);
  
  if (bytes_length == -1) {
    env->die(env, stack, "[System Error]sendto() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = bytes_length;
  
  return 0;
}

int32_t SPVM__Sys__Socket__getpeername(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  void* obj_addr = stack[1].oval;
  
  if (!obj_addr) {
    return env->die(env, stack, "The socket address $addr must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  struct sockaddr* addr = env->get_pointer(env, stack, obj_addr);
  
  int32_t* addrlen_ref = stack[2].iref;
  
  socklen_t sl_addrlen = *addrlen_ref;
  
  int32_t status = getpeername(sockfd, addr, &sl_addrlen);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]getpeername() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  *addrlen_ref = sl_addrlen;
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__getsockname(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  void* obj_addr = stack[1].oval;
  
  if (!obj_addr) {
    return env->die(env, stack, "The socket address $addr must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  struct sockaddr* addr = env->get_pointer(env, stack, obj_addr);
  
  int32_t* addrlen_ref = stack[2].iref;
  
  socklen_t sl_addrlen = *addrlen_ref;
  
  int32_t status = getsockname(sockfd, addr, &sl_addrlen);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]getsockname() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  *addrlen_ref = sl_addrlen;
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__getsockopt(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  int32_t level = stack[1].ival;
  
  int32_t optname = stack[2].ival;
  
  void* obj_optval = stack[3].oval;
  char* optval = NULL;
  if (!obj_optval) {
    return env->die(env, stack, "The option value $optval must be defined.", __func__, FILE_NAME, __LINE__);
  }
  optval = (char*)env->get_chars(env, stack, obj_optval);
  int32_t optval_length = env->length(env, stack, obj_optval);
  
  int32_t* optlen_ref = stack[4].iref;
  if (!(*optlen_ref >= 0)) {
    env->die(env, stack, "The length stored at index 0 of $optlen_ref must be greater than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  if (!(*optlen_ref <= optval_length)) {
    env->die(env, stack, "The length stored at index 0 of $optlen_ref must be less than or equal to the length of the option value $optval.", __func__, FILE_NAME, __LINE__);
  }
  
  socklen_t socklen_t_optlen = *optlen_ref;
  int32_t status = getsockopt(sockfd, level, optname, optval, &socklen_t_optlen);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]getsockopt() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  *optlen_ref = socklen_t_optlen;
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__setsockopt(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  int32_t level = stack[1].ival;
  
  int32_t optname = stack[2].ival;
  
  void* obj_optval = stack[3].oval;
  char* optval = NULL;
  if (!obj_optval) {
    return env->die(env, stack, "The option value $optval must be defined.", __func__, FILE_NAME, __LINE__);
  }
  optval = (char*)env->get_chars(env, stack, obj_optval);
  int32_t optval_length = env->length(env, stack, obj_optval);
  
  socklen_t optlen = stack[4].ival;
  if (!(optlen >= 0)) {
    env->die(env, stack, "The length stored at index 0 of $optlen_ref must be greater than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  if (!(optlen <= optval_length)) {
    env->die(env, stack, "The length stored at index 0 of $optlen_ref must be less than or equal to the length of the option value $optval.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t status = setsockopt(sockfd, level, optname, optval, optlen);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]setsockopt() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__socketpair(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "Sys::Socket#socketpair method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  int32_t domain = stack[0].ival;
  
  int32_t type = stack[1].ival;
  
  int32_t protocol = stack[2].ival;
  
  void* obj_sv = stack[3].oval;
  
  if (!obj_sv) {
    return env->die(env, stack, "The socket pair $sv must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t* sv = env->get_elems_int(env, stack, obj_sv);
  int32_t sv_length = env->length(env, stack, obj_sv);
  
  if (!(sv_length == 2)) {
    return env->die(env, stack, "The length of the socket pair $sv must be equal to 2.", __func__, FILE_NAME, __LINE__);
  }
  
  int int_sv[2];
  int32_t status = socketpair(domain, type, protocol, int_sv);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]socketpair() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  sv[0] = int_sv[0];
  sv[1] = int_sv[1];
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Socket__gai_strerror(SPVM_ENV* env, SPVM_VALUE* stack);

int32_t SPVM__Sys__Socket__getaddrinfo(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t error_id = 0;
  
  void* obj_node = stack[0].oval;
  
  const char* node = NULL;
  if (obj_node) {
    node = env->get_chars(env, stack, obj_node);
  }
  
  void* obj_service = stack[1].oval;
  
  const char* service = NULL;
  if (obj_service) {
    service = env->get_chars(env, stack, obj_service);
  }
  
  void* obj_hints = stack[2].oval;
  
  struct addrinfo *hints = NULL;
  if (obj_hints) {
    hints = env->get_pointer(env, stack, obj_hints);
  }
  
  void* obj_res_array = stack[3].oval;
  if (!obj_res_array) {
    return env->die(env, stack, "The array $res_ref to store a response must be defined.", __func__, FILE_NAME, __LINE__);
  }
  int32_t res_array_length = env->length(env, stack, obj_res_array);
  if (!(res_array_length == 1)) {
    return env->die(env, stack, "The length of array $res_ref to store a response must be equal to 1.", __func__, FILE_NAME, __LINE__);
  }
  
  struct addrinfo *res = NULL;
  
  int32_t status = getaddrinfo(node, service, hints, &res);
  
  if (status == 0) {
    int32_t fields_length = 1;
    void* obj_res = env->new_pointer_object_by_name(env, stack, "Sys::Socket::AddrinfoLinkedList", res, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    env->set_elem_object(env, stack, obj_res_array, 0, obj_res);
  }
  else {
    stack[0].ival = status;
    SPVM__Sys__Socket__gai_strerror(env, stack);
    void* obj_gai_strerror = stack[0].oval;
    const char* ch_gai_strerror = env->get_chars(env, stack, obj_gai_strerror);
    env->die(env, stack, "[System Error]getaddrinfo() failed:%s.", ch_gai_strerror, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__getnameinfo(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_sa = stack[0].oval;
  
  if (!obj_sa) {
    return env->die(env, stack, "The socket address $sa must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const struct sockaddr* sa = env->get_pointer(env, stack, obj_sa);
  
  int32_t salen = stack[1].ival;
  
  void* obj_host = stack[2].oval;
  char* host = NULL;
  if (obj_host) {
    host = (char*)env->get_chars(env, stack, obj_host);
  }
  
  int32_t hostlen = stack[3].ival;
  
  void* obj_serv = stack[4].oval;
  char* serv = NULL;
  if (obj_serv) {
    serv = (char*)env->get_chars(env, stack, obj_serv);
  }
  
  int32_t servlen = stack[5].ival;
  
  int32_t flags = stack[6].ival;
  
  int32_t status = getnameinfo(sa, salen, host, hostlen, serv, servlen, flags);
  
  if (!(status == 0)) {
    stack[0].ival = status;
    SPVM__Sys__Socket__gai_strerror(env, stack);
    void* obj_gai_strerror = stack[0].oval;
    const char* ch_gai_strerror = env->get_chars(env, stack, obj_gai_strerror);
    env->die(env, stack, "[System Error]getnameinfo() failed:%s.", ch_gai_strerror, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__gai_strerror(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t errcode = stack[0].ival;
  
  const char* error_string = gai_strerror(errcode);
  
  if (error_string) {
    int32_t error_string_length = strlen(error_string);
    void* obj_error_string = env->new_string(env, stack, error_string, error_string_length);
    stack[0].oval = obj_error_string;
  }
  else {
    env->die(env, stack, "[System Error]gai_strerror() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  return 0;
}

int32_t SPVM__Sys__Socket__sockatmark(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
    env->die(env, stack, "Sys::Socket#sockatmark method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  int32_t sockfd = stack[0].ival;
  
  int32_t status = sockatmark(sockfd);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]sockatmark() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

