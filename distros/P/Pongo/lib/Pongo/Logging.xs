#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <mongoc/mongoc.h>
#include <bson/bson.h>
#define XS_BOTHVERSION_SETXSUBFN_POPMARK_BOOTCHECK 1

int mongoc_log_helper(int log_level, const char *log_domain, const char *format, ...) {
    va_list args;
    bson_string_t *str = bson_string_new(NULL);
    va_start(args, format);
    bson_string_append_vprintf(str, format, args);
    va_end(args);
    mongoc_log(log_level, log_domain, "%s", str->str);
    bson_string_free(str, true);
    return 1;
}

MODULE = Pongo::Logging PACKAGE = Pongo::Logging

IV
GET_MONGOC_LOG_LEVEL_ERROR()
    CODE:
        RETVAL = MONGOC_LOG_LEVEL_ERROR;
    OUTPUT:
        RETVAL

IV
GET_MONGOC_LOG_LEVEL_CRITICAL()
    CODE:
        RETVAL = MONGOC_LOG_LEVEL_CRITICAL;
    OUTPUT:
        RETVAL

IV
GET_MONGOC_LOG_LEVEL_WARNING()
    CODE:
        RETVAL = MONGOC_LOG_LEVEL_WARNING;
    OUTPUT:
        RETVAL

IV
GET_MONGOC_LOG_LEVEL_MESSAGE()
    CODE:
        RETVAL = MONGOC_LOG_LEVEL_MESSAGE;
    OUTPUT:
        RETVAL

IV
GET_MONGOC_LOG_LEVEL_INFO()
    CODE:
        RETVAL = MONGOC_LOG_LEVEL_INFO;
    OUTPUT:
        RETVAL

IV
GET_MONGOC_LOG_LEVEL_DEBUG()
    CODE:
        RETVAL = MONGOC_LOG_LEVEL_DEBUG;
    OUTPUT:
        RETVAL

IV
GET_MONGOC_LOG_LEVEL_TRACE()
    CODE:
        RETVAL = MONGOC_LOG_LEVEL_TRACE;
    OUTPUT:
        RETVAL

void
SET_LOG_HANDLER(log_func, user_data)
    CV *log_func;
    SV *user_data;
    CODE:
        mongoc_log_set_handler(log_func, user_data);

int
MONGO_LOG(log_level, log_domain, format, ...)
    int log_level;
    const char *log_domain;
    const char *format;
    CODE:
        RETVAL = mongoc_log_helper(log_level, log_domain, format);
    OUTPUT:
        RETVAL

const char *
mongoc_log_level_str(log_level)
    int log_level;
    CODE:
        RETVAL = mongoc_log_level_str(log_level);
    OUTPUT:
        RETVAL

int
mongoc_log_default_handler(log_level, log_domain, message, user_data)
    int log_level
    const char *log_domain
    const char *message
    void *user_data
    CODE:
        mongoc_log_default_handler(log_level, log_domain, message, user_data);
        RETVAL = 1;
    OUTPUT:
        RETVAL

void
LOG_TRACE_ENABLE()
    CODE:
        mongoc_log_trace_enable();

void
LOG_TRACE_DISABLE()
    CODE:
        mongoc_log_trace_disable();