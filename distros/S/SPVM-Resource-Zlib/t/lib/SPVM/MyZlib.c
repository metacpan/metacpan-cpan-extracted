#include "spvm_native.h"

#include <zlib.h>

int32_t SPVM__MyZlib__test_gzopen_gzread(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  
  void* sp_file = stack[0].oval;
  
  const char* file = env->get_chars(env, stack, sp_file);
  
  z_stream z;

  gzFile gz_fh = gzopen(file, "rb");
  
  if (gz_fh == NULL){
    return env->die(env, stack, "Can't open file \"%s\"\n", file);
  }
  
  char buffer[256] = {0};
  int32_t cnt;
  while((cnt = gzread(gz_fh, buffer, sizeof(buffer))) > 0){

  }

  printf("%s", buffer);
  
  return 0;
}
