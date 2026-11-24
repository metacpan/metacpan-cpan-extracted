#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <llama.h>

MODULE = PDL::Llama    PACKAGE = PDL::Llama

PROTOTYPES: DISABLE

void
backend_init()
  CODE:
    llama_backend_init();

void
backend_free()
  CODE:
    llama_backend_free();

int
supports_mmap()
  CODE:
    RETVAL = llama_supports_mmap() ? 1 : 0;
  OUTPUT:
    RETVAL

int
supports_mlock()
  CODE:
    RETVAL = llama_supports_mlock() ? 1 : 0;
  OUTPUT:
    RETVAL

int
supports_gpu_offload()
  CODE:
    RETVAL = llama_supports_gpu_offload() ? 1 : 0;
  OUTPUT:
    RETVAL

int
max_devices()
  CODE:
    RETVAL = (int)llama_max_devices();
  OUTPUT:
    RETVAL

const char *
print_system_info()
  CODE:
    RETVAL = llama_print_system_info();
  OUTPUT:
    RETVAL
