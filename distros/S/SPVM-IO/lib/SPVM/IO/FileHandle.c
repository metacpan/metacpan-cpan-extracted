#include "spvm_native.h"
#include <stdio.h>

const char* FILE_NAME = "IO/FileHandle.c";

int32_t SPVM__IO__FileHandle__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {

  // File handle
  void* ofh = stack[0].oval;
  if (ofh != NULL) {
    FILE* fh = (FILE*)env->get_pointer(env, stack, ofh);
    if (fh) {
      int32_t ret = fclose(fh);
      env->set_pointer(env, stack, ofh, NULL);
      
      if (ret == EOF) {
        return env->die(env, stack, "Can't close the file handle at %s line %d", FILE_NAME, __LINE__);
      }
    }
  }
  
  return 0;
}
