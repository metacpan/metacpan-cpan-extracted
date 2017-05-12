#include <panda/lib.h>
#include <stdexcept>
#include <cstdlib>
#include <new>

namespace panda { namespace lib {

char* itoa (int64_t i) {
    const int INT_DIGITS = 19; /* enough for 64 bit integer */
    static char buf[INT_DIGITS + 2]; /* Room for INT_DIGITS digits, - and '\0' */
    char *p = buf + INT_DIGITS + 1;   /* points to terminating '\0' */
    if (i >= 0) {
        do {
            *--p = '0' + (i % 10);
            i /= 10;
        } while (i != 0);
        return p;
    }
    else {            /* i < 0 */
        do {
            *--p = '0' - (i % 10);
            i /= 10;
        } while (i != 0);
        *--p = '-';
    }
    return p;
}

char* crypt_xor (const char* source, size_t slen, const char* key, size_t klen, char* dest) {
    unsigned char* buf;
    if (dest) buf = (unsigned char*) dest;
    else {
        buf = (unsigned char*) std::malloc(slen+1); // space for '0'
        if (!buf) throw std::bad_alloc();
    }
    for (size_t i = 0; i < slen; ++i) dest[i] = ((unsigned char) source[i]) ^ ((unsigned char) key[i % klen]);
    dest[slen] = 0;
    return (char*) dest;
}

}}
