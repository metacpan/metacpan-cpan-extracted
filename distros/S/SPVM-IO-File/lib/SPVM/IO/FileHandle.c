#include "spvm_native.h"
#include <stdio.h>

int32_t SPVM__IO__FileHandle__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {

  // File handle
  void* ofh = stack[0].oval;
  if (ofh != NULL) {
    FILE* fh = (FILE*)env->get_pointer(env, ofh);
    if (fh) {
      int32_t ret = fclose(fh);
      env->set_pointer(env, ofh, NULL);
      
      if (ret == EOF) {
        return env->die(env, "Can't close file handle at %s line %d", "IO/FileHandle.c", __LINE__);
      }
    }
  }
  
  return 0;
}
