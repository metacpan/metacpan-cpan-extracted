#include "spvm_native.h"

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <signal.h>

#ifdef _WIN32
# include <ws2tcpip.h>
# include <io.h>
#else
# include <sys/fcntl.h>
# include <sys/types.h>
# include <sys/socket.h>
# include <netinet/in.h>
# include <netdb.h>
# include <arpa/inet.h>
# include <unistd.h>
# define closesocket(fd) close(fd)
#endif

// Module file name
static const char* MFILE = "IO/Socket/INET.c";

int32_t SPVM__IO__Socket__INET__new(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t e;

#ifdef _WIN32
  // Load WinSock DLL
  WSADATA wsa;
  WSAStartup(MAKEWORD(2, 2), &wsa);
#else
  // Ignore SIGPIPE in unix like system
  signal(SIGPIPE, SIG_IGN);
#endif

  // Dest string. Domain or IP address
  void* obj_deststr = stack[0].oval;
  const char* deststr = (const char*)env->get_elems_byte(env, stack,  obj_deststr);
  
  // Port
  int32_t port = stack[1].ival;
  
  // Socket fd
  int32_t fd = socket(AF_INET, SOCK_STREAM, 0);
  if (fd < 0) {
    return env->die(env, stack,  "Can't create socket", MFILE, __LINE__);
  }
  
  // Socket information
  struct sockaddr_in server;
  server.sin_family = AF_INET;
  server.sin_addr.s_addr = inet_addr(deststr);
  server.sin_port = htons(port);
  
  // Get IP address from domain
  if (server.sin_addr.s_addr == 0xffffffff) {
    // Find host
    struct hostent *host;
    host = gethostbyname(deststr);
    if (host == NULL) {
      return env->die(env, stack,  "host not found : %s", deststr, MFILE, __LINE__);
    }
    
    // No IP address
    unsigned int **addrptr = (unsigned int **)host->h_addr_list;
    if (*addrptr == NULL) {
      return env->die(env, stack,  "Can't get ip address from host information : %s", deststr, MFILE, __LINE__);
    }
    server.sin_addr.s_addr = *(*addrptr);
  }
  
  // Connect
  int32_t ret = connect(fd, (struct sockaddr *)&server, sizeof(server));
  if (ret != 0) {
    return env->die(env, stack,  "Can't connect to HTTP server : %s:%d", deststr, port, MFILE, __LINE__);
  }
  
  // Create IO::Socket::INET object
  void* obj_socket = env->new_object_by_name(env, stack,  "IO::Socket::INET", &e, __FILE__, __LINE__);
  if (e) { return e; }
  
  // Set fd
  env->set_field_int_by_name(env, stack, obj_socket, "fd", fd, &e, MFILE, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_socket;
  
  return 0;
}

int32_t SPVM__IO__Socket__INET__read(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e;

  void* obj_socket = stack[0].oval;
  void* obj_buffer = stack[1].oval;
  const char* buffer = (const char*)env->get_elems_byte(env, stack,  obj_buffer);
  int32_t length = env->length(env, stack,  obj_buffer);
  
  int32_t fd = env->get_field_int_by_name(env, stack,  obj_socket, "fd", &e, MFILE, __LINE__);
  if (e) { return e; }

  if (fd < 0) {
    return env->die(env, stack,  "Handle is closed", MFILE, __LINE__);
  }
  
  /* HTTPリクエスト送信 */
  int32_t read_length = recv(fd, (char*)buffer, length, 0);
  if (read_length < 0) {
    return env->die(env, stack,  "Socket read error", MFILE, __LINE__);
  }
  
  stack[0].ival = read_length;
  
  return 0;
}

int32_t SPVM__IO__Socket__INET__write(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e;

  void* obj_socket = stack[0].oval;
  void* obj_buffer = stack[1].oval;
  const char* buffer = (const char*)env->get_elems_byte(env, stack,  obj_buffer);
  int32_t length = stack[2].ival;
  
  int32_t fd = env->get_field_int_by_name(env, stack,  obj_socket, "fd", &e, MFILE, __LINE__);
  if (e) { return e; }
  
  if (fd < 0) {
    return env->die(env, stack,  "Handle is closed", MFILE, __LINE__);
  }
  
  /* HTTPリクエスト送信 */
  int32_t write_length = send(fd, buffer, length, 0);
  
  if (write_length < 0) {
    return env->die(env, stack,  "Socket write error", MFILE, __LINE__);
  }
  
  stack[0].ival = write_length;
  
  return 0;
}

int32_t SPVM__IO__Socket__INET__close(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t e;
  
  void* obj_socket = stack[0].oval;
  
  int32_t fd = env->get_field_int_by_name(env, stack,  obj_socket, "fd", &e, MFILE, __LINE__);
  if (e) { return e; }
  
  if (fd >= 0) {
    int32_t ret = closesocket(fd);
    if (ret == 0) {
      env->set_field_int_by_name(env, stack,  obj_socket, "fd", -1, &e, MFILE, __LINE__);
      if (e) { return e; }
    }
    else {
      return env->die(env, stack,  "Fail close", MFILE, __LINE__);
    }
  }
  
  return 0;
}

int32_t SPVM__IO__Socket__INET__fileno(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e;

  // Self
  void* obj_self = stack[0].oval;
  if (!obj_self) { return env->die(env, stack,  "Self must be defined", MFILE, __LINE__); }
  
  // File fh
  int32_t fd = env->get_field_int_by_name(env, stack,  obj_self, "fd", &e, MFILE, __LINE__);
  if (e) { return e; }
  
  stack[0].ival = fd;

  return 0;
}

int32_t SPVM__IO__Socket__INET___cleanup_wsa(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  // Unload WinSock DLL
#ifdef _WIN32
  WSACleanup();
#endif
  
  return 0;
}
