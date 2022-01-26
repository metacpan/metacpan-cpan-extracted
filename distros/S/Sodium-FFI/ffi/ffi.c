#include <ffi_platypus_bundle.h>
#include <string.h>
#include <stdint.h>
#include <sodium.h>

#if !defined(SODIUM_LIBRARY_MINIMAL)
#define SODIUM_LIBRARY_MINIMAL 0
#endif
#define _str(name) c->set_str(#name, name)
#define _sint(name) c->set_sint(#name, name)
#define _uint(name) c->set_uint(#name, name)

void
ffi_pl_bundle_constant(const char* package, ffi_platypus_constant_t* c)
{
    _str(SODIUM_VERSION_STRING);
    _uint(SIZE_MAX);
    _uint(randombytes_SEEDBYTES);
    _sint(SODIUM_LIBRARY_MINIMAL);
    _sint(SODIUM_LIBRARY_VERSION_MAJOR);
    _sint(SODIUM_LIBRARY_VERSION_MINOR);

    /* base_64 options */
    _sint(sodium_base64_VARIANT_ORIGINAL);
    _sint(sodium_base64_VARIANT_ORIGINAL_NO_PADDING);
    _sint(sodium_base64_VARIANT_URLSAFE);
    _sint(sodium_base64_VARIANT_URLSAFE_NO_PADDING);
}

void
ffi_pl_bundle_init(const char* package, int argc, void* argv[])
{
    /* printf("Begin with sodium_init()\n"); */
    if (sodium_init() < 0) {
        printf("Could not initialize libsodium.");
    }
}
