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

#if (defined(__amd64) || defined(__amd64__) || defined(__x86_64__) ||          \
     defined(__i386__) || defined(_M_AMD64) || defined(_M_IX86))
#define HAVE_AESGCM 1
#else
#define HAVE_AESGCM 0
#endif
#if SODIUM_LIBRARY_VERSION_MAJOR > 9 ||                                        \
  (SODIUM_LIBRARY_VERSION_MAJOR == 9 && SODIUM_LIBRARY_VERSION_MINOR >= 2)
#define HAVE_AEAD_DETACHED 1
#else
#define HAVE_AEAD_DETACHED 0
#endif

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

    /* Crypto Generics */
    _uint(crypto_auth_BYTES);
    _uint(crypto_auth_KEYBYTES);

    /* AESGCM stuff */
    _sint(HAVE_AESGCM);
    _sint(HAVE_AEAD_DETACHED);
    _uint(crypto_aead_aes256gcm_KEYBYTES);
    _uint(crypto_aead_aes256gcm_NPUBBYTES);
    _uint(crypto_aead_aes256gcm_ABYTES);

    /* chacha20poly1305 */
    _uint(crypto_aead_chacha20poly1305_KEYBYTES);
    _uint(crypto_aead_chacha20poly1305_NPUBBYTES);
    _uint(crypto_aead_chacha20poly1305_ABYTES);

    /* chacha20poly1305_ietf */
    _uint(crypto_aead_chacha20poly1305_IETF_KEYBYTES);
    _uint(crypto_aead_chacha20poly1305_IETF_NPUBBYTES);
    _uint(crypto_aead_chacha20poly1305_IETF_ABYTES);

    /* Public key Crypt - Pub Key Signatures */
    _uint(crypto_sign_PUBLICKEYBYTES);
    _uint(crypto_sign_SECRETKEYBYTES);
    _uint(crypto_sign_BYTES);
    _uint(crypto_sign_SEEDBYTES);
}

void
ffi_pl_bundle_init(const char* package, int argc, void* argv[])
{
    /* printf("Begin with sodium_init()\n"); */
    if (sodium_init() < 0) {
        printf("Could not initialize libsodium.");
    }
}
