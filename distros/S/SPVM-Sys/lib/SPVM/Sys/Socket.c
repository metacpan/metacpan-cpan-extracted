// Windows 8.1+
#define _WIN32_WINNT 0x0603

#include "spvm_native.h"

#include <errno.h>
#include <assert.h>

#ifdef _WIN32
# include <ws2tcpip.h>
# include <winsock2.h>
# include <io.h>
# include <winerror.h>
#else
# include <sys/types.h>
# include <sys/socket.h>
# include <netinet/in.h>
# include <netinet/ip.h>
# include <netdb.h>
# include <arpa/inet.h>
# include <poll.h>
#endif

static const char* FILE_NAME = "Sys/Socket.c";

static int32_t FIELD_INDEX_ADDRINFO_MEMORY_ALLOCATED = 0;
static int32_t ADDRINFO_MEMORY_ALLOCATED_BY_NEW = 1;
static int32_t ADDRINFO_MEMORY_ALLOCATED_BY_GETADDRINFO = 2;

static int32_t socket_errno (void) {
#ifdef _WIN32
  return WSAGetLastError();
#else
  return errno;
#endif
}

#ifdef _WIN32
static void* socket_strerror_string_win (SPVM_ENV* env, SPVM_VALUE* stack, int32_t error_number, int32_t length) {
  char* error_message = NULL;
  FormatMessageA(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, 
                 NULL, error_number,
                 MAKELANGID(LANG_ENGLISH, SUBLANG_ENGLISH_US),
                 (LPSTR)&error_message, length, NULL);
  
  void* obj_error_message = env->new_string(env, stack, error_message, strlen(error_message));
  
  LocalFree(error_message);
  
  return obj_error_message;
}
#endif

static void* socket_strerror_string (SPVM_ENV* env, SPVM_VALUE* stack, int32_t error_number, int32_t length) {
  void*
#ifdef _WIN32
  obj_strerror_value = socket_strerror_string_win(env, stack, error_number, length);
#else
  obj_strerror_value = env->strerror_string(env, stack, error_number, length);
#endif
  return obj_strerror_value;
}


static const char* socket_strerror(SPVM_ENV* env, SPVM_VALUE* stack, int32_t error_number, int32_t length) {
  void* obj_socket_strerror = socket_strerror_string(env, stack, error_number, length);
  
  const char* ret_socket_strerror = NULL;
  if (obj_socket_strerror) {
    ret_socket_strerror = env->get_chars(env, stack, obj_socket_strerror);
  }
  
  return ret_socket_strerror;
}

int32_t SPVM__Sys__Socket__socket_errno(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t ret_socket_errno = socket_errno();
  
  stack[0].ival = ret_socket_errno;
  
  return 0;
}

int32_t SPVM__Sys__Socket__socket_strerror(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t error_number = stack[0].ival;
  int32_t length = stack[1].ival;
  
  void* obj_socket_strerror = socket_strerror_string(env, stack, error_number, length);
  
  stack[0].oval = obj_socket_strerror;
  
  return 0;
}

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

  int32_t e = 0;
  
  int32_t InvalidNetworkAddress = env->get_class_id_by_name(env, stack, "Sys::Socket::Error::InetInvalidNetworkAddress", &e, FILE_NAME, __LINE__);
  
  void* obj_cp = stack[0].oval;
  
  if (!obj_cp) {
    return env->die(env, stack, "The input address(cp) must be defined", FILE_NAME, __LINE__);
  }
  
  const char* cp = env->get_chars(env, stack, obj_cp);
  
  void* obj_inp = stack[1].oval;
  
  if (!obj_inp) {
    return env->die(env, stack, "The output address(inp) must be defined", FILE_NAME, __LINE__);
  }
  
  struct in_addr* st_in_addr = env->get_pointer(env, stack, obj_inp);
  
#ifdef _WIN32
  int32_t status = inet_pton(AF_INET, cp, st_in_addr);
#else
  int32_t status = inet_aton(cp, st_in_addr);
#endif

  if (status == 0) {
    env->die(env, stack, "The address is not a valid network address", FILE_NAME, __LINE__);
    return InvalidNetworkAddress;
  }
  else if (status == -1) {
    env->die(env, stack, "[System Error]inet_aton failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__inet_ntoa(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_in = stack[0].oval;
  
  if (!obj_in) {
    return env->die(env, stack, "The input address must be defined", FILE_NAME, __LINE__);
  }
  
  struct in_addr* in = env->get_pointer(env, stack, obj_in);
  
  char* output_address = inet_ntoa(*in);

  if (!output_address) {
    env->die(env, stack, "[System Error]inet_ntoa failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
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
  
  int32_t e = 0;
  
  int32_t InvalidNetworkAddress = env->get_class_id_by_name(env, stack, "Sys::Socket::Error::InetInvalidNetworkAddress", &e, FILE_NAME, __LINE__);
  
  if (e) { return e; }
  
  int32_t af = stack[0].ival;
  
  if (!(af == AF_INET || af == AF_INET6)) {
    return env->die(env, stack, "The address family must be AF_INET or AF_INET6", FILE_NAME, __LINE__);
  }
  
  void* obj_src = stack[1].oval;
  
  if (!obj_src) {
    return env->die(env, stack, "The input address(src) must be defined", FILE_NAME, __LINE__);
  }
  
  const char* src = env->get_chars(env, stack, obj_src);
  
  void* obj_dst = stack[2].oval;
  
  if (!obj_dst) {
    return env->die(env, stack, "The output address(dst) must be defined", FILE_NAME, __LINE__);
  }
  
  void* dst = env->get_pointer(env, stack, obj_dst);
  
  int32_t status = inet_pton(af, src, dst);
  
  if (status == 0) {
    env->die(env, stack, "The address is not a valid network address", FILE_NAME, __LINE__);
    return InvalidNetworkAddress;
  }
  else if (status == -1) {
    env->die(env, stack, "[System Error]inet_pton failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__inet_ntop(SPVM_ENV* env, SPVM_VALUE* stack) {

  // The address family
  int32_t af = stack[0].ival;

  if (!(af == AF_INET || af == AF_INET6)) {
    return env->die(env, stack, "The address family must be AF_INET or AF_INET6", FILE_NAME, __LINE__);
  }
  
  // The input address
  void* obj_src = stack[1].oval;
  if (!obj_src) {
    return env->die(env, stack, "The input address(src) must be defined", FILE_NAME, __LINE__);
  }
  void* src = env->get_pointer(env, stack, obj_src);
  
  // The output address
  void* obj_dst = stack[2].oval;
  if (!obj_dst) {
    return env->die(env, stack, "The output address(dst) must be defined", FILE_NAME, __LINE__);
  }
  char* dst = (char*)env->get_chars(env, stack, obj_dst);
  
  // The size of the output address
  int32_t size = stack[3].ival;
  
  const char* dst_ret = inet_ntop(af, src, dst, size);
  
  if (!dst_ret) {
    env->die(env, stack, "[System Error]inet_ntop failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
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
    env->die(env, stack, "[System Error]socket failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = sockfd;
  
  return 0;
}

int32_t SPVM__Sys__Socket__connect(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  void* obj_addr = stack[1].oval;
  
  if (!obj_addr) {
    return env->die(env, stack, "The address must be defined", FILE_NAME, __LINE__);
  }
  
  const struct sockaddr* addr = env->get_pointer(env, stack, obj_addr);
  
  int32_t addrlen = stack[2].ival;
  
  int32_t status = connect(sockfd, addr, addrlen);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]connect failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__bind(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  void* obj_addr = stack[1].oval;
  
  if (!obj_addr) {
    return env->die(env, stack, "The address must be defined", FILE_NAME, __LINE__);
  }
  
  const struct sockaddr* addr = env->get_pointer(env, stack, obj_addr);
  
  int32_t addrlen = stack[2].ival;
  
  int32_t status = bind(sockfd, addr, addrlen);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]bind failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__accept(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  void* obj_addr = stack[1].oval;
  
  if (!obj_addr) {
    return env->die(env, stack, "The address must be defined", FILE_NAME, __LINE__);
  }
  
  struct sockaddr* addr = env->get_pointer(env, stack, obj_addr);
  
  int32_t* addrlen_ref = stack[2].iref;
  
  socklen_t sl_addrlen = *addrlen_ref;
  
  int32_t status = accept(sockfd, addr, &sl_addrlen);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]accept failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
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
    env->die(env, stack, "[System Error]listen failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__recv(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;

  void* obj_buf = stack[1].oval;
  
  if (!obj_buf) {
    return env->die(env, stack, "The buffer must be defined", FILE_NAME, __LINE__);
  }
  
  char* buf = (char*)env->get_chars(env, stack, obj_buf);
  
  int32_t len = stack[2].ival;
  
  int32_t flags = stack[3].ival;
  
  int32_t bytes_length = recv(sockfd, buf, len, flags);
  
  if (bytes_length == -1) {
    env->die(env, stack, "[System Error]recv failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = bytes_length;
  
  return 0;
}

int32_t SPVM__Sys__Socket__send(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;

  void* obj_buf = stack[1].oval;
  
  if (!obj_buf) {
    return env->die(env, stack, "The buffer must be defined", FILE_NAME, __LINE__);
  }
  
  const char* buf = env->get_chars(env, stack, obj_buf);
  
  int32_t len = stack[2].ival;
  
  int32_t flags = stack[3].ival;
  
  int32_t bytes_length = send(sockfd, buf, len, flags);
  
  if (bytes_length == -1) {
    env->die(env, stack, "[System Error]send failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = bytes_length;
  
  return 0;
}

int32_t SPVM__Sys__Socket__getpeername(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  void* obj_addr = stack[1].oval;
  
  if (!obj_addr) {
    return env->die(env, stack, "The address must be defined", FILE_NAME, __LINE__);
  }
  
  struct sockaddr* addr = env->get_pointer(env, stack, obj_addr);
  
  int32_t* addrlen_ref = stack[2].iref;
  
  socklen_t sl_addrlen = *addrlen_ref;
  
  int32_t status = getpeername(sockfd, addr, &sl_addrlen);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]getpeername failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  *addrlen_ref = sl_addrlen;
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__getsockname(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  void* obj_addr = stack[1].oval;
  
  if (!obj_addr) {
    return env->die(env, stack, "The address must be defined", FILE_NAME, __LINE__);
  }
  
  struct sockaddr* addr = env->get_pointer(env, stack, obj_addr);
  
  int32_t* addrlen_ref = stack[2].iref;
  
  socklen_t sl_addrlen = *addrlen_ref;
  
  int32_t status = getsockname(sockfd, addr, &sl_addrlen);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]getsockname failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  *addrlen_ref = sl_addrlen;
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__socketpair(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "socketpair is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  
  int32_t domain = stack[0].ival;

  int32_t type = stack[1].ival;

  int32_t protocol = stack[2].ival;

  void* obj_sv = stack[3].oval;
  
  if (!obj_sv) {
    return env->die(env, stack, "The output of the socket pair(sv) must be defined", FILE_NAME, __LINE__);
  }
  
  int32_t* sv = env->get_elems_int(env, stack, obj_sv);
  int32_t sv_length = env->length(env, stack, obj_sv);
  
  if (!(sv_length >= 2)) {
    return env->die(env, stack, "The length of the output of the socket pair(sv) must be greater than or equal to 2", FILE_NAME, __LINE__);
  }
  
  int int_sv[2];
  int32_t status = socketpair(domain, type, protocol, int_sv);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]socketpair failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  sv[0] = int_sv[0];
  sv[1] = int_sv[1];
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Socket__setsockopt(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;

  int32_t level = stack[1].ival;

  int32_t optname = stack[2].ival;

  void* obj_optval = stack[3].oval;
  char* optval = NULL;
  if (!obj_optval) {
    return env->die(env, stack, "The option value must be defined", FILE_NAME, __LINE__);
  }
  optval = (char*)env->get_chars(env, stack, obj_optval);
  int32_t optval_length = env->length(env, stack, obj_optval);

  int32_t optlen = stack[4].ival;
  if (!(optlen >= 0)) {
    env->die(env, stack, "The option length must be greater than or equal to 0", FILE_NAME, __LINE__);
  }
  if (!(optlen <= optval_length)) {
    env->die(env, stack, "The length of the option value must be less than or equal to the option length", FILE_NAME, __LINE__);
  }
  
  int32_t status = setsockopt(sockfd, level, optname, optval, optlen);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]setsockopt failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__setsockopt_int(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t int32_optval = stack[3].ival;
  
  int int_optval = int32_optval;
  
  void* obj_optval = env->new_string(env, stack, NULL, sizeof(int));
  char* optval = (char*)env->get_chars(env, stack, obj_optval);
  memcpy(optval, &int_optval, sizeof(int));
  
  stack[3].oval = obj_optval;

  stack[4].ival = sizeof(int);
  
  return SPVM__Sys__Socket__setsockopt(env, stack);
}

int32_t SPVM__Sys__Socket__getsockopt(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;

  int32_t level = stack[1].ival;

  int32_t optname = stack[2].ival;
  
  void* obj_optval = stack[3].oval;
  char* optval = NULL;
  if (!obj_optval) {
    return env->die(env, stack, "The option value must be defined", FILE_NAME, __LINE__);
  }
  optval = (char*)env->get_chars(env, stack, obj_optval);
  int32_t optval_length = env->length(env, stack, obj_optval);

  int32_t* optlen_ref = stack[4].iref;
  if (!(*optlen_ref >= 0)) {
    env->die(env, stack, "The option length must be greater than or equal to 0", FILE_NAME, __LINE__);
  }
  if (!(*optlen_ref <= optval_length)) {
    env->die(env, stack, "The length of the option value must be less than or equal to the option length", FILE_NAME, __LINE__);
  }
  
  int int_optlen = *optlen_ref;
  int32_t status = getsockopt(sockfd, level, optname, optval, &int_optlen);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]getsockopt failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  *optlen_ref = int_optlen;
  
  stack[0].ival = status;
  
  return 0;
}


int32_t SPVM__Sys__Socket__getsockopt_int(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t int32_optval = stack[3].ival;
  
  int int_optval = int32_optval;
  
  void* obj_optval = env->new_string(env, stack, NULL, sizeof(int));
  char* optval = (char*)env->get_chars(env, stack, obj_optval);
  memcpy(optval, &int_optval, sizeof(int));
  
  stack[3].oval = obj_optval;
  
  int32_t optlen = sizeof(int);
  stack[4].iref = &optlen;
  
  return SPVM__Sys__Socket__getsockopt(env, stack);
}

int32_t SPVM__Sys__Socket__shutdown(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t sockfd = stack[0].ival;
  
  int32_t how = stack[1].ival;
  
  int32_t status = shutdown(sockfd, how);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]shutdown failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__ioctlsocket(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifndef _WIN32
  env->die(env, stack, "ioctlsocket is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  
  int32_t e = 0;
  
  int32_t s = stack[0].ival;
  
  int32_t cmd = stack[1].ival;
  
  int32_t* argp = stack[2].iref;
  
  u_long arg_u_long = (long)*argp;
  
  int32_t status = ioctlsocket(s, cmd, &arg_u_long);

  if (!(status == 0)) {
    env->die(env, stack, "[System Error]ioctlsocket failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  *argp = arg_u_long;
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Socket__closesocket(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifndef _WIN32
  env->die(env, stack, "The \"closesocket\" method in the class \"Sys::Socket\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  
  int32_t s = stack[0].ival;
  
  int32_t status = closesocket(s);
  
  if (!(status == 0)) {
    env->die(env, stack, "[System Error]closesocket failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Socket__WSAPoll(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifndef _WIN32
  env->die(env, stack, "The \"WSAPoll\" method in the class \"Sys::Socket\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  
  void* obj_fds = stack[0].oval;
  
  struct pollfd* fds = env->get_pointer(env, stack, obj_fds);
  
  int32_t nfds = stack[1].ival;
  
  int32_t timeout = stack[2].ival;
  
  int32_t status = WSAPoll(fds, nfds, timeout);
  
  if (status == SOCKET_ERROR) {
    env->die(env, stack, "[System Error]WSAPoll failed: %s", socket_strerror(env, stack, socket_errno(), 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Socket__gai_strerror(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t errcode = stack[0].ival;
  
  const char* error_string = gai_strerror(errcode);
  
  if (error_string) {
    int32_t error_string_length = strlen(error_string);
    void* obj_error_string = env->new_string(env, stack, error_string, error_string_length);
    stack[0].oval = obj_error_string;
  }
  else {
    stack[0].oval = NULL;
  }
  
  return 0;
}

int32_t SPVM__Sys__Socket__getaddrinfo_raw(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e = 0;
  
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
    return env->die(env, stack, "The response must be defined", FILE_NAME, __LINE__);
  }
  int32_t res_length = env->length(env, stack, obj_res_array);
  if (!(res_length >= 1)) {
    return env->die(env, stack, "The length of the array of the response must be greater than or equal to 1", FILE_NAME, __LINE__);
  }
  
  struct addrinfo *res = NULL;
  
  int32_t status = getaddrinfo(node, service, hints, &res);
  
  if (status == 0) {
    int32_t fields_length = 1;
    void* obj_res = env->new_pointer_with_fields_by_name(env, stack, "Sys::Socket::Addrinfo", res, fields_length, &e, FILE_NAME, __LINE__);
    if (e) { return e; }
    env->set_pointer_field_int(env, stack, obj_res, FIELD_INDEX_ADDRINFO_MEMORY_ALLOCATED, ADDRINFO_MEMORY_ALLOCATED_BY_GETADDRINFO);
    env->set_elem_object(env, stack, obj_res_array, 0, obj_res);
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__getaddrinfo(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e = 0;
  
  e = SPVM__Sys__Socket__getaddrinfo_raw(env, stack);
  if (e) { return e; }
  
  int32_t status = stack[0].ival;
  if (!(status == 0)) {
    stack[0].ival = status;
    SPVM__Sys__Socket__gai_strerror(env, stack);
    void* obj_gai_strerror = stack[0].oval;
    const char* ch_gai_strerror = env->get_chars(env, stack, obj_gai_strerror);
    env->die(env, stack, "[System Error]getaddrinfo failed: %s", ch_gai_strerror, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  return 0;
}

int32_t SPVM__Sys__Socket__getnameinfo_raw(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e = 0;
  
  void* obj_sa = stack[0].oval;
  
  if (!obj_sa) {
    return env->die(env, stack, "The socket address must be defined", FILE_NAME, __LINE__);
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
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Socket__getnameinfo(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e = 0;
  
  e = SPVM__Sys__Socket__getnameinfo_raw(env, stack);
  if (e) { return e; }
  
  int32_t status = stack[0].ival;
  if (!(status == 0)) {
    stack[0].ival = status;
    SPVM__Sys__Socket__gai_strerror(env, stack);
    void* obj_gai_strerror = stack[0].oval;
    const char* ch_gai_strerror = env->get_chars(env, stack, obj_gai_strerror);
    env->die(env, stack, "[System Error]getnameinfo failed: %s", ch_gai_strerror, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  return 0;
}
