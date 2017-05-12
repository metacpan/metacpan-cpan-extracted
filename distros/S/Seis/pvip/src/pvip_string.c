#include <stdlib.h>
#include <inttypes.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <stdarg.h>
#include "pvip.h"

PVIPString *PVIP_string_new() {
    PVIPString *str = malloc(sizeof(PVIPString));
    memset(str, 0, sizeof(PVIPString));
    assert(str);
    str->len    = 0;
    str->buflen = 1024;
    str->buf    = malloc(str->buflen);
    return str;
}

void PVIP_string_destroy(PVIPString *str) {
    free(str->buf);
    str->buf = NULL;
    free(str);
}

PVIP_BOOL PVIP_string_concat(PVIPString *str, const char *src, size_t len) {
    if (str->len + len > str->buflen) {
        str->buflen = ( str->len + len ) * 2;
        str->buf    = realloc(str->buf, str->buflen);
        if (!str->buf) {
            return PVIP_FALSE;
        }
    }
    memcpy(str->buf + str->len, src, len);
    str->len += len;
    return PVIP_TRUE;
}

PVIP_BOOL PVIP_string_concat_int(PVIPString *str, int64_t n) {
    char buf[1024];
    int res = snprintf(buf, 1023, "%" PRIi64, n);
    return PVIP_string_concat(str, buf, res);
}

PVIP_BOOL PVIP_string_concat_number(PVIPString *str, double n) {
    char buf[1024];
    int res = snprintf(buf, 1023, "%f", n);
    for (; res>1; --res) { /* remove trailing zeros */
        if (buf[res-1]!='0') {
            break;
        }
    }
    return PVIP_string_concat(str, buf, res);
}

PVIP_BOOL PVIP_string_concat_char(PVIPString *str, char c) {
    return PVIP_string_concat(str, &c, 1);
}

void PVIP_string_say(PVIPString *str) {
    fwrite(str->buf, 1, str->len, stdout);
    fwrite("\n", 1, 1, stdout);
}

PVIP_BOOL PVIP_string_vprintf(PVIPString *str, const char*format, va_list ap) {
    int size = vsnprintf(str->buf + str->len, str->buflen - str->len, format, ap);
    if (size > str->buflen - str->len) {
        str->buflen += size + 1;
        str->buf    = realloc(str->buf, str->buflen);
        if (!str->buf) {
            return PVIP_FALSE;
        }
        return PVIP_string_printf(str, format, ap);
    }
    str->len += size;
    return PVIP_TRUE;
}

PVIP_BOOL PVIP_string_printf(PVIPString *str, const char*format, ...) {
    va_list va;
    va_start(va, format);
    PVIP_BOOL retval = PVIP_string_vprintf(str, format, va);
    va_end(va);
    return retval;
}

const char *PVIP_string_c_str(PVIPString *str) {
    if (str->buflen == str->len) {
        str->buflen++;
        str->buf    = realloc(str->buf, str->buflen);
        if (!str->buf) {
            return NULL;
        }
    }
    str->buf[str->len+1-1] = '\0';
    return str->buf;
}

