// Copyright (c) 2023 Yuki Kimoto
// MIT License

#ifndef SPVM_SOCKET_UTIL_H
#define SPVM_SOCKET_UTIL_H

#include "spvm_native.h"

// This macro will be removed if Sys class does not use it.
#define SPVM_SOCKET_UTIL_DEFINE_SOCKADDR_UN

#ifdef _WIN32
  #include <ws2tcpip.h>
  #include <winsock2.h>
  #include <io.h>
  #include <winerror.h>
  
  #define UNIX_PATH_MAX 108
  struct sockaddr_un {
    ADDRESS_FAMILY sun_family;
    char sun_path[UNIX_PATH_MAX];
  };
#else
  #include <unistd.h>
  #include <sys/types.h>
  #include <sys/socket.h>
  #include <netinet/in.h>
  #include <netinet/ip.h>
  #include <netdb.h>
  #include <arpa/inet.h>
  #include <sys/un.h>
#endif

#include <errno.h>

int32_t spvm_socket_errno (void);

void* spvm_socket_strerror_string(SPVM_ENV* env, SPVM_VALUE* stack, int32_t error_number, int32_t length);

/* spvm_socket_strerror_string

  Gets an error string as an SPVM string given the error number <error_number> and the max length of the error string <length> and returns the error string.
  
  If <length> is 0, It is adjusted automatically.
  
  In Linux and Unix, this function calls strerror_string native API.
  
  In Windows, this function calls FormatMessageA function.
  
*/

const char* spvm_socket_strerror(SPVM_ENV* env, SPVM_VALUE* stack, int32_t error_number, int32_t length);

/* spvm_socket_strerror

  Calls spvm_socket_strerror_string function and gets data of char[] from its return value and returns the data.
  
  If the return value of spvm_socket_strerror_string function is NULL, returns NULL.

*/

const char* spvm_socket_strerror_nolen(SPVM_ENV* env, SPVM_VALUE* stack, int32_t error_number);

/* spvm_socket_strerror_nolen

  Alias for the following code.
  
  const char* ret = spvm_socket_strerror(env, stack, error_number, 0);
  
*/

#endif
