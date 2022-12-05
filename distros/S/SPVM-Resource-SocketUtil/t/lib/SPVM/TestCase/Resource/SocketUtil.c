#include "spvm_native.h"

#include "spvm_socket_util.h"

int32_t SPVM__TestCase__Resource__SocketUtil__test(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  // spvm_socket_errno
  {
    errno = 0;
    int32_t socket_errno = spvm_socket_errno();
    if (!(errno == 0)) {
      stack[0].ival = 0;
    }
  }
  
  // spvm_socket_strerror_string
  {
    errno = 0;
    void* strerror = spvm_socket_strerror_string(env, stack, EWOULDBLOCK, 0);
    if (!strerror) {
      stack[0].ival = 0;
    }
  }

  // spvm_socket_strerror
  {
    errno = 0;
    const char* strerror = spvm_socket_strerror_string(env, stack, EWOULDBLOCK, 0);
    if (!(strlen(strerror) > 0)) {
      stack[0].ival = 0;
    }
  }
  
  stack[0].ival = 1;
  
  return 0;
}


