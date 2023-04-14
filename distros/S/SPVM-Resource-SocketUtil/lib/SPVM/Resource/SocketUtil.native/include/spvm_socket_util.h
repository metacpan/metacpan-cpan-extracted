// Copyright (c) 2023 Yuki Kimoto
// MIT License

#ifndef SPVM__SOCKET_UTIL_H
#define SPVM__SOCKET_UTIL_H

#include "spvm_native.h"

#ifdef _WIN32
  #include <ws2tcpip.h>
  #include <winsock2.h>
  #include <io.h>
  #include <winerror.h>
#else
  #include <unistd.h>
  #include <sys/types.h>
  #include <sys/socket.h>
  #include <netinet/in.h>
  #include <netinet/ip.h>
  #include <netdb.h>
  #include <arpa/inet.h>
#endif

#include <errno.h>

int32_t spvm_socket_errno (void);

void* spvm_socket_strerror_string (SPVM_ENV* env, SPVM_VALUE* stack, int32_t error_number, int32_t length);

const char* spvm_socket_strerror(SPVM_ENV* env, SPVM_VALUE* stack, int32_t error_number, int32_t length);

#endif
