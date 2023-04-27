// Copyright (c) 2023 Yuki Kimoto
// MIT License

// The original source code is MIME/QuotedPrint.xs

#include "spvm_native.h"

#include <assert.h>
#include <stdio.h>

#include <string>
#include <iostream>

extern "C" {

#define MAX_LINE  76 /* size of encoded lines */

#ifndef isXDIGIT
#   define isXDIGIT isxdigit
#endif

#define FILE_NAME "SPVM/MIME/QuotedPrint.cpp"

#define qp_isplain(c) ((c) == '\t' || (((c) >= ' ' && (c) <= '~') && (c) != '='))

int32_t SPVM__MIME__QuotedPrint__encode_qp(SPVM_ENV* env, SPVM_VALUE* stack) {

        const char *eol;
        int32_t eol_len;
        int32_t binary;
        int32_t sv_len;
        int32_t linelen;
        char *beg;
        char *end;
        char *p;
        char *p_beg;
        int32_t p_len;
        uint32_t had_utf8;

        int32_t items = env->get_args_stack_length(env, stack);

        void* obj_str = stack[0].oval;
        
        if (!obj_str) {
                return env->die(env, stack, "The $string must be defined", __func__, FILE_NAME, __LINE__);
        }
        
        beg = (char*)env->get_chars(env, stack, obj_str);
        sv_len = env->length(env, stack, obj_str);
        
        void* obj_eol = NULL;
        if (items > 1) {
          obj_eol = stack[1].oval;
        }
        
        if (obj_eol) {
                eol = env->get_chars(env, stack, obj_eol);
                eol_len = env->length(env, stack, obj_eol);
        }
        else {
                eol = "\n";
                eol_len = 1;
        }
        
        binary = 0;
        if (items > 2) {
          binary = stack[2].ival;
        }
        
        end = beg + sv_len;
        
        std::string RETVAL("");
        
        linelen = 0;

        p = beg;
        while (1) {
            p_beg = p;

            while (p < end && qp_isplain(*p)) {
                p++;
            }
            if (p == end || *p == '\n') {
                while (p > p_beg && (*(p - 1) == '\t' || *(p - 1) == ' '))
                    p--;
            }

            p_len = p - p_beg;
            if (p_len) {
                if (eol_len) {
                    while (p_len > MAX_LINE - 1 - linelen) {
                        int32_t len = MAX_LINE - 1 - linelen;
                        RETVAL.append(p_beg, len);
                        p_beg += len;
                        p_len -= len;
                        RETVAL.append("=", 1);
                        RETVAL.append(eol, eol_len);
                        linelen = 0;
                    }
                }
                if (p_len) {
                    RETVAL.append(p_beg, p_len);
                    linelen += p_len;
                }
            }

            if (p == end) {
                break;
            }
            else if (*p == '\n' && eol_len && !binary) {
                if (linelen == 1 && RETVAL.length() > eol_len + 1 && (RETVAL.end()-eol_len)[-2] == '=') {
                    (RETVAL.end()-eol_len)[-2] = (RETVAL.end())[-1];
                    RETVAL.resize(RETVAL.length() - 1);
                }
                else {
                    RETVAL.append(eol, eol_len);
                }
                p++;
                linelen = 0;
            }
            else {
                assert(p < end);
                if (eol_len && linelen > MAX_LINE - 4 && !(linelen == MAX_LINE - 3 && p + 1 < end && p[1] == '\n' && !binary)) {
                    RETVAL.append("=", 1);
                    RETVAL.append(eol, eol_len);
                    linelen = 0;
                }
                char tmp_buffer[5] = {0};
                snprintf(tmp_buffer, 5, "=%02X", (unsigned char)*p);
                RETVAL.append(tmp_buffer);
                p++;
                linelen += 3;
            }

            if (RETVAL.length() > 80 && RETVAL.length() - RETVAL.length() < 3) {
                int32_t expected_len = (RETVAL.length() * sv_len) / (p - beg);
                RETVAL.reserve(expected_len);
            }
        }

        if (RETVAL.length() && eol_len && linelen) {
            RETVAL.append("=", 1);
            RETVAL.append(eol, eol_len);
        }

        void* obj_RETVAL = env->new_string(env, stack, (const char*)RETVAL.c_str(), RETVAL.length());
        
        stack[0].oval = obj_RETVAL;
        
        return 0;
}


int32_t SPVM__MIME__QuotedPrint__decode_qp(SPVM_ENV* env, SPVM_VALUE* stack) {

        void* obj_str = stack[0].oval;
        
        if (!obj_str) {
                return env->die(env, stack, "The $string must be defined", __func__, FILE_NAME, __LINE__);
        }
        
        int32_t len = env->length(env, stack, obj_str);
        char *str = (char*)env->get_chars(env, stack, obj_str);
        char const* end = str + len;
        char *r;
        char *whitespace = 0;

        void* obj_RETVAL = env->new_string(env, stack, NULL, len ? len : 1);
        r = (char*)env->get_chars(env, stack, obj_RETVAL);
        while (str < end) {
            if (*str == ' ' || *str == '\t') {
                if (!whitespace)
                    whitespace = str;
                str++;
            }
            else if (*str == '\r' && (str + 1) < end && str[1] == '\n') {
                str++;
            }
            else if (*str == '\n') {
                whitespace = 0;
                *r++ = *str++;
            }
            else {
                if (whitespace) {
                    while (whitespace < str) {
                        *r++ = *whitespace++;
                    }
                    whitespace = 0;
                }
                if (*str == '=') {
                    if ((str + 2) < end && isXDIGIT(str[1]) && isXDIGIT(str[2])) {
                        char buf[3];
                        str++;
                        buf[0] = *str++;
                        buf[1] = *str++;
                        buf[2] = '\0';
                        *r++ = (char)strtol(buf, 0, 16);
                    }
                    else {
                        /* look for soft line break */
                        char *p = str + 1;
                        while (p < end && (*p == ' ' || *p == '\t'))
                            p++;
                        if (p < end && *p == '\n')
                            str = p + 1;
                        else if ((p + 1) < end && *p == '\r' && *(p + 1) == '\n')
                            str = p + 2;
                        else
                            *r++ = *str++; /* give up */
                    }
                }
                else {
                    *r++ = *str++;
                }
            }
        }
        if (whitespace) {
            while (whitespace < str) {
                *r++ = *whitespace++;
            }
        }
        *r = '\0';
        int32_t rlen = r - env->get_chars(env, stack, obj_RETVAL);
        
        env->shorten(env, stack, obj_RETVAL, rlen);
        
        stack[0].oval = obj_RETVAL;
        
        return 0;
}

}
