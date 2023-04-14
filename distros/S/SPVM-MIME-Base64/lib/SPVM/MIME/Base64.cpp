// Copyright (c) 2023 Yuki Kimoto
// MIT License

// The original source code is MIME/Base64.xs

#include "spvm_native.h"

#include <assert.h>
#include <stdio.h>

#include <string>
#include <iostream>

extern "C" {

#define MAX_LINE  76 /* size of encoded lines */

static const char basis_64[] =
   "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

#define XX      255     /* illegal base64 char */
#define EQ      254     /* padding */
#define INVALID XX

static const unsigned char index_64[256] = {
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,62, XX,XX,XX,63,
    52,53,54,55, 56,57,58,59, 60,61,XX,XX, XX,EQ,XX,XX,
    XX, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
    15,16,17,18, 19,20,21,22, 23,24,25,XX, XX,XX,XX,XX,
    XX,26,27,28, 29,30,31,32, 33,34,35,36, 37,38,39,40,
    41,42,43,44, 45,46,47,48, 49,50,51,XX, XX,XX,XX,XX,

    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
};

#ifndef isXDIGIT
#   define isXDIGIT isxdigit
#endif

#ifndef NATIVE_TO_ASCII
#   define NATIVE_TO_ASCII(ch) (ch)
#endif

#define FILE_NAME "SPVM/MIME/Base64.cpp"

int32_t SPVM__MIME__Base64__encode_base64(SPVM_ENV* env, SPVM_VALUE* stack) {
        char *str;     /* string to encode */
        int32_t len;   /* length of the string */
        const char*eol;/* the end-of-line sequence to use */
        int32_t eollen; /* length of the EOL sequence */
        char *r;       /* result string */
        int32_t rlen;   /* length of result string */
        unsigned char c1, c2, c3;
        int32_t chunk;
        uint32_t had_utf8;
        
        int32_t items = env->get_args_stack_length(env, stack);

        void* obj_str = stack[0].oval;
        
        if (!obj_str) {
                return env->die(env, stack, "The input must be defined", __func__, FILE_NAME, __LINE__);
        }

        rlen = env->length(env, stack, obj_str);
        str = (char*)env->get_chars(env, stack, obj_str);
        len = rlen;
        
        void* obj_eol = NULL;
        if (items > 1) {
          obj_eol = stack[1].oval;
        }

        /* set up EOL from the second argument if present, default to "\n" */
        if (obj_eol) {
            eollen = env->length(env, stack, obj_eol);
            eol = env->get_chars(env, stack, obj_eol);
        } else {
            eol = "\n";
            eollen = 1;
        }
        
        /* calculate the length of the result */
        rlen = (len+2) / 3 * 4;  /* encoded bytes */
        if (rlen) {
            /* add space for EOL */
            rlen += ((rlen-1) / MAX_LINE + 1) * eollen;
        }

        /* allocate a result buffer */
        void* obj_RETVAL = env->new_string(env, stack, NULL, rlen);
        r = (char*)env->get_chars(env, stack, obj_RETVAL);
        
        /* encode */
        for (chunk=0; len > 0; len -= 3, chunk++) {
            if (chunk == (MAX_LINE/4)) {
                const char *c = eol;
                const char *e = eol + eollen;
                while (c < e)
                    *r++ = *c++;
                chunk = 0;
            }
            
            
            c1 = *str++;
            c2 = len > 1 ? *str++ : '\0';
            *r++ = basis_64[c1>>2];
            *r++ = basis_64[((c1 & 0x3)<< 4) | ((c2 & 0xF0) >> 4)];
            if (len > 2) {
                c3 = *str++;
                *r++ = basis_64[((c2 & 0xF) << 2) | ((c3 & 0xC0) >>6)];
                *r++ = basis_64[c3 & 0x3F];
            } else if (len == 2) {
                *r++ = basis_64[(c2 & 0xF) << 2];
                *r++ = '=';
            } else { /* len == 1 */
                *r++ = '=';
                *r++ = '=';
            }
            if (len < 0) {
              exit(255);
            }
        }
        if (rlen) {
            /* append eol to the result string */
            const char *c = eol;
            const char *e = eol + eollen;
            while (c < e)
                *r++ = *c++;
        }
        *r = '\0';  /* every SV in perl should be NUL-terminated */
        
        stack[0].oval = obj_RETVAL;

        return 0;
}

int32_t SPVM__MIME__Base64__decode_base64(SPVM_ENV* env, SPVM_VALUE* stack) {

        int32_t len;
        register unsigned char *str;
        unsigned char const* end;
        char *r;
        unsigned char c[4];
        
        void* obj_str = stack[0].oval;
        
        if (!obj_str) {
                return env->die(env, stack, "The input must be defined", __func__, FILE_NAME, __LINE__);
        }
        
        len = env->length(env, stack, obj_str);
        str = (unsigned char*)env->get_chars(env, stack, obj_str);
        end = str + len;
        
        void* obj_RETVAL;
        {
            /* always enough, but might be too much */
            int32_t rlen = len * 3 / 4;
            obj_RETVAL = env->new_string(env, stack, NULL, rlen ? rlen : 1);
        }
        r = (char*)env->get_chars(env, stack, obj_RETVAL);

        while (str < end) {
            int32_t i = 0;
            do {
                unsigned char uc = index_64[NATIVE_TO_ASCII(*str++)];
                if (uc != INVALID)
                    c[i++] = uc;

                if (str == end) {
                    if (i < 4) {
                        if (i < 2) goto thats_it;
                        if (i == 2) c[2] = EQ;
                        c[3] = EQ;
                    }
                    break;
                }
            } while (i < 4);
        
            if (c[0] == EQ || c[1] == EQ) {
                break;
            }
            /* printf("c0=%d,c1=%d,c2=%d,c3=%d\n", c[0],c[1],c[2],c[3]);*/

            *r++ = (c[0] << 2) | ((c[1] & 0x30) >> 4);

            if (c[2] == EQ)
                break;
            *r++ = ((c[1] & 0x0F) << 4) | ((c[2] & 0x3C) >> 2);

            if (c[3] == EQ)
                break;
            *r++ = ((c[2] & 0x03) << 6) | c[3];
        }

      thats_it:
        env->shorten(env, stack, obj_RETVAL, r - env->get_chars(env, stack, obj_RETVAL));
        *r = '\0';
        
        stack[0].oval = obj_RETVAL;
        
        return 0;
}

int32_t SPVM__MIME__Base64__encoded_base64_length(SPVM_ENV* env, SPVM_VALUE* stack) {
        int32_t len;   /* length of the string */
        int32_t eollen; /* length of the EOL sequence */
        uint32_t had_utf8;

        int32_t items = env->get_args_stack_length(env, stack);

        void* obj_str = stack[0].oval;
        
        if (!obj_str) {
          return env->die(env, stack, "The input must be defined", __func__, FILE_NAME, __LINE__);
        }

        void* obj_eol = NULL;
        if (items > 1) {
          obj_eol = stack[1].oval;
        }
        
        if (obj_eol) {
            eollen = env->length(env, stack, obj_eol);
        } else {
            eollen = 1;
        }

        len = env->length(env, stack, obj_str);;

        int32_t RETVAL = (len+2) / 3 * 4;        /* encoded bytes */
        if (RETVAL) {
            RETVAL += ((RETVAL-1) / MAX_LINE + 1) * eollen;
        }
        
        stack[0].ival = RETVAL;
        
        return 0;
}

int32_t SPVM__MIME__Base64__decoded_base64_length(SPVM_ENV* env, SPVM_VALUE* stack) {
        int32_t len;
        register unsigned char *str;
        unsigned char const* end;
        int32_t i = 0;

        void* obj_str = stack[0].oval;
        
        if (!obj_str) {
                return env->die(env, stack, "The input must be defined", __func__, FILE_NAME, __LINE__);
        }
        
        len = env->length(env, stack, obj_str);
        str = (unsigned char*)env->get_chars(env, stack, obj_str);
        end = str + len;

        int32_t RETVAL = 0;
        while (str < end) {
            unsigned char uc = index_64[NATIVE_TO_ASCII(*str++)];
            if (uc == INVALID)
                continue;
            if (uc == EQ)
                break;
            if (i++) {
                RETVAL++;
                if (i == 4)
                    i = 0;
            }
        }

        stack[0].ival = RETVAL;
        
        return 0;
}

}
