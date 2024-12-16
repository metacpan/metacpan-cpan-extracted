#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <bson/bson.h>
#define XS_BOTHVERSION_SETXSUBFN_POPMARK_BOOTCHECK 1

MODULE = Pongo::BSON PACKAGE = Pongo::BSON

PROTOTYPES: DISABLE

TYPEMAP : <<HERE

bson_t * T_PTROBJ
char ** T_PTROBJ
const bson_t * T_PTROBJ
bson_subtype_t T_PTROBJ
const uint8_t * T_PTROBJ
uint32_t T_PTROBJ
int64_t T_PTROBJ
const bson_oid_t * T_PTROBJ
const bson_decimal128_t * T_PTROBJ
int32_t T_PTROBJ
const bson_iter_t * T_PTROBJ
struct timeval * T_PTROBJ
const bson_value_t * T_PTROBJ
size_t * T_PTROBJ
const bson_json_opts_t * T_PTROBJ
uint32_t * T_PTROBJ
uint8_t * T_PTROBJ
bson_t ** T_PTROBJ
bson_writer_t * T_PTROBJ
bson_json_opts_t * T_PTROBJ
bson_json_opts_t T_PTROBJ
bson_json_mode_t T_PTROBJ
bson_error_t * T_PTROBJ
uint8_t ** T_PTROBJ
bson_realloc_func T_PTROBJ
bson_validate_flags_t  T_PTROBJ
bson_array_builder_t ** T_PTROBJ
bson_array_builder_t * T_PTROBJ
bson_context_t * T_PTROBJ
bson_decimal128_t * T_PTROBJ
bson_context_flags_t T_PTROBJ
const uint8_t ** T_PTROBJ
bson_subtype_t * T_PTROBJ
const char ** T_PTROBJ
const bson_oid_t ** T_PTROBJ
bson_iter_t * T_PTROBJ
const bson_visitor_t * T_PTROBJ
bson_type_t T_PTROBJ
bson_json_reader_t * T_PTROBJ
bson_json_reader_cb T_PTROBJ
bson_json_destroy_cb T_PTROBJ
bson_oid_t * T_PTROBJ
bson_value_t * T_PTROBJ
bson_reader_destroy_func_t T_PTROBJ
bson_reader_read_func_t T_PTROBJ
bson_reader_t * T_PTROBJ
bool * T_PTROBJ
off_t T_PTROBJ
bson_unichar_t T_PTROBJ
bson_string_t * T_PTROBJ
const bson_mem_vtable_t * T_PTROBJ

HERE

bool
append_array(bson, key, key_length, array)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *array;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        const bson_t *bson_array = (const bson_t*) SvIV(SvRV(array));
        RETVAL = bson_append_array(bson, bson_key, key_length, bson_array);
    OUTPUT:
        RETVAL

bool
append_array_begin(bson, key, key_length, child)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *child;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        bson_t *bson_child = (bson_t*) SvIV(SvRV(child));
        RETVAL = bson_append_array_begin(bson, bson_key, key_length, bson_child);
    OUTPUT:
        RETVAL

bool
append_array_end(bson, child)
    bson_t *bson;
    bson_t *child;
    CODE:
        RETVAL = bson_append_array_end(bson, child);
    OUTPUT:
        RETVAL

bool
append_binary(bson, key, key_length, subtype, binary, length)
    bson_t *bson;
    SV *key;
    int key_length;
    int subtype;
    SV *binary;
    uint32_t length;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        const uint8_t *bson_binary = (const uint8_t*) SvPV_nolen(binary);
        RETVAL = bson_append_binary(bson, bson_key, key_length, (bson_subtype_t)subtype, bson_binary, length);
    OUTPUT:
        RETVAL

bool
append_bool(bson, key, key_length, value)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *value;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        bool bson_value = SvTRUE(value);
        RETVAL = bson_append_bool(bson, bson_key, key_length, bson_value);
    OUTPUT:
        RETVAL

bool
append_code(bson, key, key_length, javascript)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *javascript;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        const char *bson_javascript = SvPV_nolen(javascript);
        RETVAL = bson_append_code(bson, bson_key, key_length, bson_javascript);
    OUTPUT:
        RETVAL

bool
append_code_with_scope(bson, key, key_length, javascript, scope)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *javascript;
    SV *scope;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        const char *bson_javascript = SvPV_nolen(javascript);
        const bson_t *bson_scope = (const bson_t*) SvIV(SvRV(scope));
        RETVAL = bson_append_code_with_scope(bson, bson_key, key_length, bson_javascript, bson_scope);
    OUTPUT:
        RETVAL

bool
append_date_time(bson, key, key_length, value)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *value;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        int64_t bson_value = SvIV(value);
        RETVAL = bson_append_date_time(bson, bson_key, key_length, bson_value);
    OUTPUT:
        RETVAL

bool
append_dbpointer(bson, key, key_length, collection, oid)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *collection;
    SV *oid;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        const char *bson_collection = SvPV_nolen(collection);
        const bson_oid_t *bson_oid = (const bson_oid_t*) SvIV(SvRV(oid));
        RETVAL = bson_append_dbpointer(bson, bson_key, key_length, bson_collection, bson_oid);
    OUTPUT:
        RETVAL

bool
append_decimal128(bson, key, key_length, value)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *value;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        const bson_decimal128_t *bson_value = (const bson_decimal128_t*) SvIV(SvRV(value));
        RETVAL = bson_append_decimal128(bson, bson_key, key_length, bson_value);
    OUTPUT:
        RETVAL

bool
append_document(bson, key, key_length, value)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *value;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        const bson_t *bson_value = (const bson_t*) SvIV(SvRV(value));
        RETVAL = bson_append_document(bson, bson_key, key_length, bson_value);
    OUTPUT:
        RETVAL

bool
append_document_begin(bson, key, key_length, child)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *child;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        bson_t *bson_child = (bson_t*) SvIV(SvRV(child));
        RETVAL = bson_append_document_begin(bson, bson_key, key_length, bson_child);
    OUTPUT:
        RETVAL

bool
append_document_end(bson, child)
    bson_t *bson;
    SV *child;
    CODE:
        bson_t *bson_child = (bson_t*) SvIV(SvRV(child));
        RETVAL = bson_append_document_end(bson, bson_child);
    OUTPUT:
        RETVAL

bool
append_double(bson, key, key_length, value)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *value;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        double bson_value = SvNV(value);
        RETVAL = bson_append_double(bson, bson_key, key_length, bson_value);
    OUTPUT:
        RETVAL

bool
append_int32(bson, key, key_length, value)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *value;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        int32_t bson_value = SvIV(value);
        RETVAL = bson_append_int32(bson, bson_key, key_length, bson_value);
    OUTPUT:
        RETVAL

bool
append_int64(bson, key, key_length, value)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *value;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        int64_t bson_value = SvIV(value);
        RETVAL = bson_append_int64(bson, bson_key, key_length, bson_value);
    OUTPUT:
        RETVAL

bool
append_iter(bson, key, key_length, iter)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *iter;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        const bson_iter_t *bson_iter = (const bson_iter_t*) SvIV(SvRV(iter));
        RETVAL = bson_append_iter(bson, bson_key, key_length, bson_iter);
    OUTPUT:
        RETVAL

bool
append_maxkey(bson, key, key_length)
    bson_t *bson;
    SV *key;
    int key_length;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        RETVAL = bson_append_maxkey(bson, bson_key, key_length);
    OUTPUT:
        RETVAL

bool
append_minkey(bson, key, key_length)
    bson_t *bson;
    SV *key;
    int key_length;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        RETVAL = bson_append_minkey(bson, bson_key, key_length);
    OUTPUT:
        RETVAL

bool
append_now_utc(bson, key, key_length)
    bson_t *bson;
    SV *key;
    int key_length;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        RETVAL = bson_append_now_utc(bson, bson_key, key_length);
    OUTPUT:
        RETVAL

bool
append_null(bson, key, key_length)
    bson_t *bson;
    SV *key;
    int key_length;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        RETVAL = bson_append_null(bson, bson_key, key_length);
    OUTPUT:
        RETVAL

bool
append_oid(bson, key, key_length, oid)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *oid;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        const bson_oid_t *bson_oid = (const bson_oid_t*) SvIV(SvRV(oid));
        RETVAL = bson_append_oid(bson, bson_key, key_length, bson_oid);
    OUTPUT:
        RETVAL

bool
append_regex(bson, key, key_length, regex, options)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *regex;
    SV *options;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        const char *bson_regex = SvPV_nolen(regex);
        const char *bson_options = SvPV_nolen(options);
        RETVAL = bson_append_regex(bson, bson_key, key_length, bson_regex, bson_options);
    OUTPUT:
        RETVAL

bool
append_regex_w_len(bson, key, key_length, regex, regex_length, options)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *regex;
    int regex_length;
    SV *options;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        const char *bson_regex = SvPV_nolen(regex);
        const char *bson_options = SvPV_nolen(options);
        RETVAL = bson_append_regex_w_len(bson, bson_key, key_length, bson_regex, regex_length, bson_options);
    OUTPUT:
        RETVAL

bool
append_symbol(bson, key, key_length, value, length)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *value;
    int length;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        const char *bson_value = SvPV_nolen(value);
        RETVAL = bson_append_symbol(bson, bson_key, key_length, bson_value, length);
    OUTPUT:
        RETVAL

bool
append_time_t(bson, key, key_length, value)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *value;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        time_t bson_value = SvIV(value);
        RETVAL = bson_append_time_t(bson, bson_key, key_length, bson_value);
    OUTPUT:
        RETVAL

bool
append_timestamp(bson, key, key_length, timestamp, increment)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *timestamp;
    SV *increment;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        uint32_t bson_timestamp = SvUV(timestamp);
        uint32_t bson_increment = SvUV(increment);
        RETVAL = bson_append_timestamp(bson, bson_key, key_length, bson_timestamp, bson_increment);
    OUTPUT:
        RETVAL

bool
append_timeval(bson, key, key_length, value)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *value;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        struct timeval *bson_value = (struct timeval*) SvIV(value);
        RETVAL = bson_append_timeval(bson, bson_key, key_length, bson_value);
    OUTPUT:
        RETVAL

bool
append_undefined(bson, key, key_length)
    bson_t *bson;
    SV *key;
    int key_length;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        RETVAL = bson_append_undefined(bson, bson_key, key_length);
    OUTPUT:
        RETVAL

bool
append_utf8(bson, key, key_length, value, length)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *value;
    int length;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        const char *bson_value = SvPV_nolen(value);
        RETVAL = bson_append_utf8(bson, bson_key, key_length, bson_value, length);
    OUTPUT:
        RETVAL

bool
append_value(bson, key, key_length, value)
    bson_t *bson;
    SV *key;
    int key_length;
    SV *value;
    CODE:
        const char *bson_key = SvPV_nolen(key);
        const bson_value_t *bson_value = (bson_value_t*) SvPV_nolen(value);
        RETVAL = bson_append_value(bson, bson_key, key_length, bson_value);
    OUTPUT:
        RETVAL

char *
array_as_canonical_extended_json(bson, length)
    SV *bson;
    SV *length;
    CODE:
        size_t len = 0;
        const bson_t *bson_ptr = (const bson_t*)SvPV_nolen(bson);
        RETVAL = bson_as_canonical_extended_json(bson_ptr, &len);
        sv_setiv(length, (IV)len);
    OUTPUT:
        RETVAL

char *
array_as_json(bson, length)
    SV *bson;
    SV *length;
    CODE:
        size_t len = 0;
        const bson_t *bson_ptr = (const bson_t*)SvPV_nolen(bson);
        RETVAL = bson_as_json(bson_ptr, &len);
        sv_setiv(length, (IV)len);
    OUTPUT:
        RETVAL

char *
array_as_relaxed_extended_json(bson, length)
    SV *bson;
    SV *length;
    CODE:
        size_t len = 0;
        const bson_t *bson_ptr = (const bson_t*)SvPV_nolen(bson);
        RETVAL = bson_as_relaxed_extended_json(bson_ptr, &len);
        sv_setiv(length, (IV)len);
    OUTPUT:
        RETVAL

char *
as_canonical_extended_json(bson, length)
    SV *bson;
    SV *length;
    CODE:
        size_t len = 0;
        const bson_t *bson_ptr = (const bson_t*)SvPV_nolen(bson);
        RETVAL = bson_as_canonical_extended_json(bson_ptr, &len);
        sv_setiv(length, (IV)len);
    OUTPUT:
        RETVAL

char *
as_json(bson, length)
    SV *bson;
    SV *length;
    CODE:
        size_t len = 0;
        const bson_t *bson_ptr = (const bson_t*)SvPV_nolen(bson);
        RETVAL = bson_as_json(bson_ptr, &len);
        sv_setiv(length, (IV)len);
    OUTPUT:
        RETVAL

char *
as_json_with_opts(bson, length, opts)
    SV *bson;
    SV *length;
    SV *opts;
    CODE:
        size_t len = 0;
        const bson_t *bson_ptr = (const bson_t*)SvPV_nolen(bson);
        const bson_json_opts_t *opts_ptr = (const bson_json_opts_t*)SvPV_nolen(opts);
        RETVAL = bson_as_json_with_opts(bson_ptr, &len, opts_ptr);
        sv_setiv(length, (IV)len);
    OUTPUT:
        RETVAL

char *
as_relaxed_extended_json(bson, length)
    SV *bson;
    SV *length;
    CODE:
        size_t len = 0;
        const bson_t *bson_ptr = (const bson_t*)SvPV_nolen(bson);
        RETVAL = bson_as_relaxed_extended_json(bson_ptr, &len);
        sv_setiv(length, (IV)len);
    OUTPUT:
        RETVAL

int
compare(bson, other)
    SV *bson;
    SV *other;
    CODE:
        const bson_t *bson_ptr = (const bson_t*)SvPV_nolen(bson);
        const bson_t *other_ptr = (const bson_t*)SvPV_nolen(other);
        RETVAL = bson_compare(bson_ptr, other_ptr);
    OUTPUT:
        RETVAL

bool
concat(dst, src)
    bson_t *dst;
    SV *src;
    CODE:
        const bson_t *src_ptr = (const bson_t*)SvPV_nolen(src);
        RETVAL = bson_concat(dst, src_ptr);
    OUTPUT:
        RETVAL

bson_t *
copy(bson)
    SV *bson;
    CODE:
        const bson_t *bson_ptr = (const bson_t*)SvPV_nolen(bson);
        RETVAL = bson_copy(bson_ptr);
    OUTPUT:
        RETVAL

void
copy_to(src, dst)
    SV *src;
    bson_t *dst;
    CODE:
        const bson_t *src_ptr = (const bson_t*)SvPV_nolen(src);
        bson_copy_to(src_ptr, dst);

void
copy_to_excluding_noinit(src, dst, first_exclude)
    SV *src;
    bson_t *dst;
    const char *first_exclude;
    CODE:
        const bson_t *src_ptr = (const bson_t*)SvPV_nolen(src);
        bson_copy_to_excluding_noinit(src_ptr, dst, first_exclude, NULL);

uint32_t
count_keys(bson)
    SV *bson;
    CODE:
        const bson_t *bson_ptr = (const bson_t*)SvPV_nolen(bson);
        RETVAL = bson_count_keys(bson_ptr);
    OUTPUT:
        RETVAL

void
destroy(bson)
    SV *bson;
    CODE:
        const bson_t *bson_ptr = (const bson_t*)SvPV_nolen(bson);
        bson_destroy(bson_ptr);

uint8_t *
destroy_with_steal(bson, steal, length)
    SV *bson;
    bool steal;
    uint32_t *length;
    CODE:
        const bson_t *bson_ptr = (const bson_t*)SvPV_nolen(bson);
        RETVAL = bson_destroy_with_steal(bson_ptr, steal, length);
    OUTPUT:
        RETVAL

bool
equal(bson, other)
    SV *bson;
    SV *other;
    CODE:
        const bson_t *bson_ptr = (const bson_t*)SvPV_nolen(bson);
        const bson_t *other_ptr = (const bson_t*)SvPV_nolen(other);
        RETVAL = bson_equal(bson_ptr, other_ptr);
    OUTPUT:
        RETVAL

const uint8_t *
get_data(bson)
    SV *bson;
    CODE:
        const bson_t *bson_ptr = (const bson_t*)SvPV_nolen(bson);
        RETVAL = bson_get_data(bson_ptr);
    OUTPUT:
        RETVAL

bool
has_field(bson, key)
    SV *bson;
    const char *key;
    CODE:
        const bson_t *bson_ptr = (const bson_t*)SvPV_nolen(bson);
        RETVAL = bson_has_field(bson_ptr, key);
    OUTPUT:
        RETVAL

void
init(b)
    SV *b;
    CODE:
        bson_t *bson_ptr = (bson_t*)SvPV_nolen(b);
        bson_init(bson_ptr);

bool
init_from_json(b, data, len, error)
    SV *b;
    const char *data;
    ssize_t len;
    SV *error;
    CODE:
        bson_t *bson_ptr = (bson_t*)SvPV_nolen(b);
        bson_error_t *error_ptr = (bson_error_t*)SvPV_nolen(error);
        RETVAL = bson_init_from_json(bson_ptr, data, len, error_ptr);
    OUTPUT:
        RETVAL

bool
init_static(b, data, length)
    SV *b;
    const uint8_t *data;
    size_t length;
    CODE:
        bson_t *bson_ptr = (bson_t*)SvPV_nolen(b);
        RETVAL = bson_init_static(bson_ptr, data, length);
    OUTPUT:
        RETVAL

bson_json_opts_t *
json_opts_new(mode, max_len)
    bson_json_mode_t mode;
    int32_t max_len;
    CODE:
        RETVAL = bson_json_opts_new(mode, max_len);
    OUTPUT:
        RETVAL

void
json_opts_destroy(opts)
    SV *opts;
    CODE:
        bson_json_opts_t *opts_ptr = (bson_json_opts_t*)SvPV_nolen(opts);
        bson_json_opts_destroy(opts_ptr);

bson_t *
new()
    CODE:
        RETVAL = bson_new();
    OUTPUT:
        RETVAL

bson_t *
new_from_buffer(buf, buf_len, realloc_func, realloc_func_ctx)
    SV *buf;
    SV *buf_len;
    SV *realloc_func;
    SV *realloc_func_ctx;
    CODE:
        uint8_t *buf_ptr = (uint8_t*)SvPV_nolen(buf);
        size_t buf_len_val = (size_t)SvIV(buf_len);
        bson_realloc_func realloc_func_ptr = (bson_realloc_func)SvIV(realloc_func);
        void *realloc_func_ctx_ptr = (void*)SvIV(realloc_func_ctx);
        RETVAL = bson_new_from_buffer(&buf_ptr, &buf_len_val, realloc_func_ptr, realloc_func_ctx_ptr);
    OUTPUT:
        RETVAL

bson_t *
new_from_data(data, length)
    SV *data;
    SV *length;
    CODE:
        uint8_t *data_ptr = (uint8_t*)SvPV_nolen(data);
        size_t length_val = (size_t)SvIV(length);
        RETVAL = bson_new_from_data(data_ptr, length_val);
    OUTPUT:
        RETVAL

bson_t *
new_from_json(data, len, error)
    SV *data;
    SV *len;
    SV *error;
    CODE:
        uint8_t *data_ptr = (uint8_t*)SvPV_nolen(data);
        ssize_t len_val = (ssize_t)SvIV(len);
        bson_error_t *error_ptr = (bson_error_t*)SvIV(error);
        RETVAL = bson_new_from_json(data_ptr, len_val, error_ptr);
    OUTPUT:
        RETVAL

void
reinit(b)
    SV *b;
    CODE:
        bson_t *b_ptr = (bson_t*)SvIV(b);
        bson_reinit(b_ptr);

uint8_t *
reserve_buffer(bson, size)
    SV *bson;
    SV *size;
    CODE:
        bson_t *b_ptr = (bson_t*)SvIV(bson);
        uint32_t size_val = (uint32_t)SvIV(size);
        RETVAL = bson_reserve_buffer(b_ptr, size_val);
    OUTPUT:
        RETVAL

bson_t *
sized_new(size)
    SV *size;
    CODE:
        size_t size_val = (size_t)SvIV(size);
        RETVAL = bson_sized_new(size_val);
    OUTPUT:
        RETVAL

bool
steal(dst, src)
    SV *dst;
    SV *src;
    CODE:
        bson_t *dst_ptr = (bson_t*)SvIV(dst);
        bson_t *src_ptr = (bson_t*)SvIV(src);
        RETVAL = bson_steal(dst_ptr, src_ptr);
    OUTPUT:
        RETVAL

bool
validate(bson, flags, offset)
    SV *bson;
    SV *flags;
    SV *offset;
    CODE:
        bson_t *b_ptr = (bson_t*)SvIV(bson);
        bson_validate_flags_t flags_val = (bson_validate_flags_t)SvIV(flags);
        size_t *offset_ptr = (size_t*)SvIV(offset);
        RETVAL = bson_validate(b_ptr, flags_val, offset_ptr);
    OUTPUT:
        RETVAL

bool
validate_with_error(bson, flags, error)
    SV *bson;
    SV *flags;
    SV *error;
    CODE:
        bson_t *b_ptr = (bson_t*)SvIV(bson);
        bson_validate_flags_t flags_val = (bson_validate_flags_t)SvIV(flags);
        bson_error_t *error_ptr = (bson_error_t*)SvIV(error);
        RETVAL = bson_validate_with_error(b_ptr, flags_val, error_ptr);
    OUTPUT:
        RETVAL

bool
validate_with_error_and_offset(bson, flags, offset, error)
    SV *bson;
    SV *flags;
    SV *offset;
    SV *error;
    CODE:
        bson_t *b_ptr = (bson_t*)SvIV(bson);
        bson_validate_flags_t flags_val = (bson_validate_flags_t)SvIV(flags);
        size_t *offset_ptr = (size_t*)SvIV(offset);
        bson_error_t *error_ptr = (bson_error_t*)SvIV(error);
        RETVAL = bson_validate_with_error_and_offset(b_ptr, flags_val, offset_ptr, error_ptr);
    OUTPUT:
        RETVAL

bool
append_array_builder_begin(bson, key, key_length, child)
    SV *bson;
    SV *key;
    SV *key_length;
    SV *child;
    CODE:
        bson_t *b_ptr = (bson_t*)SvIV(bson);
        const char *key_str = SvPV(key, PL_na);
        int key_length_val = (int)SvIV(key_length);
        bson_array_builder_t **child_ptr = (bson_array_builder_t**)SvIV(child);
        RETVAL = bson_append_array_builder_begin(b_ptr, key_str, key_length_val, child_ptr);
    OUTPUT:
        RETVAL

bool
append_array_builder_end(bson, child)
    SV *bson;
    SV *child;
    CODE:
        bson_t *b_ptr = (bson_t*)SvIV(bson);
        bson_array_builder_t *child_ptr = (bson_array_builder_t*)SvIV(child);
        RETVAL = bson_append_array_builder_end(b_ptr, child_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_value(bab, value)
    SV *bab;
    SV *value;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        const bson_value_t *value_ptr = (const bson_value_t*)SvIV(value);
        RETVAL = bson_array_builder_append_value(bab_ptr, value_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_array(bab, array)
    SV *bab;
    SV *array;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        const bson_t *array_ptr = (const bson_t*)SvIV(array);
        RETVAL = bson_array_builder_append_array(bab_ptr, array_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_binary(bab, subtype, binary, length)
    SV *bab;
    SV *subtype;
    SV *binary;
    SV *length;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        bson_subtype_t subtype_val = (bson_subtype_t)SvIV(subtype);
        const uint8_t *binary_ptr = (const uint8_t*)SvIV(binary);
        uint32_t length_val = (uint32_t)SvIV(length);
        RETVAL = bson_array_builder_append_binary(bab_ptr, subtype_val, binary_ptr, length_val);
    OUTPUT:
        RETVAL

bool
array_builder_append_bool(bab, value)
    SV *bab;
    SV *value;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        bool value_val = (bool)SvIV(value);
        RETVAL = bson_array_builder_append_bool(bab_ptr, value_val);
    OUTPUT:
        RETVAL

bool
array_builder_append_code(bab, javascript)
    SV *bab;
    SV *javascript;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        const char *javascript_str = SvPV(javascript, PL_na);
        RETVAL = bson_array_builder_append_code(bab_ptr, javascript_str);
    OUTPUT:
        RETVAL

bool
array_builder_append_code_with_scope(bab, javascript, scope)
    SV *bab;
    SV *javascript;
    SV *scope;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        const char *javascript_str = SvPV(javascript, PL_na);
        const bson_t *scope_ptr = (const bson_t*)SvIV(scope);
        RETVAL = bson_array_builder_append_code_with_scope(bab_ptr, javascript_str, scope_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_dbpointer(bab, collection, oid)
    SV *bab;
    SV *collection;
    SV *oid;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        const char *collection_str = SvPV(collection, PL_na);
        const bson_oid_t *oid_ptr = (const bson_oid_t*)SvIV(oid);
        RETVAL = bson_array_builder_append_dbpointer(bab_ptr, collection_str, oid_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_double(bab, value)
    SV *bab;
    double value;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        RETVAL = bson_array_builder_append_double(bab_ptr, value);
    OUTPUT:
        RETVAL

bool
array_builder_append_document(bab, value)
    SV *bab;
    SV *value;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        const bson_t *value_ptr = (const bson_t*)SvIV(value);
        RETVAL = bson_array_builder_append_document(bab_ptr, value_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_document_begin(bab, child)
    SV *bab;
    SV *child;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        bson_t *child_ptr = (bson_t*)SvIV(child);
        RETVAL = bson_array_builder_append_document_begin(bab_ptr, child_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_document_end(bab, child)
    SV *bab;
    SV *child;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        bson_t *child_ptr = (bson_t*)SvIV(child);
        RETVAL = bson_array_builder_append_document_end(bab_ptr, child_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_int32(bab, value)
    SV *bab;
    int32_t value;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        RETVAL = bson_array_builder_append_int32(bab_ptr, value);
    OUTPUT:
        RETVAL

bool
array_builder_append_int64(bab, value)
    SV *bab;
    int64_t value;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        RETVAL = bson_array_builder_append_int64(bab_ptr, value);
    OUTPUT:
        RETVAL

bool
array_builder_append_decimal128(bab, value)
    SV *bab;
    SV *value;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        bson_decimal128_t *value_ptr = (bson_decimal128_t*)SvIV(value);
        RETVAL = bson_array_builder_append_decimal128(bab_ptr, value_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_iter(bab, iter)
    SV *bab;
    SV *iter;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        RETVAL = bson_array_builder_append_iter(bab_ptr, iter_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_minkey(bab)
    SV *bab;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        RETVAL = bson_array_builder_append_minkey(bab_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_maxkey(bab)
    SV *bab;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        RETVAL = bson_array_builder_append_maxkey(bab_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_null(bab)
    SV *bab;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        RETVAL = bson_array_builder_append_null(bab_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_oid(bab, oid)
    SV *bab;
    SV *oid;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        bson_oid_t *oid_ptr = (bson_oid_t*)SvIV(oid);
        RETVAL = bson_array_builder_append_oid(bab_ptr, oid_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_regex(bab, regex, options)
    SV *bab;
    SV *regex;
    SV *options;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        const char *regex_str = SvPV(regex, PL_na);
        const char *options_str = SvPV(options, PL_na);
        RETVAL = bson_array_builder_append_regex(bab_ptr, regex_str, options_str);
    OUTPUT:
        RETVAL


bool
array_builder_append_regex_w_len(bab, regex, regex_length, options)
    SV *bab;
    SV *regex;
    int regex_length;
    SV *options;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        const char *regex_str = SvPV(regex, PL_na);
        const char *options_str = SvPV(options, PL_na);
        RETVAL = bson_array_builder_append_regex_w_len(bab_ptr, regex_str, regex_length, options_str);
    OUTPUT:
        RETVAL

bool
array_builder_append_utf8(bab, value, length)
    SV *bab;
    SV *value;
    int length;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        const char *value_str = SvPV(value, PL_na);
        RETVAL = bson_array_builder_append_utf8(bab_ptr, value_str, length);
    OUTPUT:
        RETVAL

bool
array_builder_append_symbol(bab, value, length)
    SV *bab;
    SV *value;
    int length;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        const char *value_str = SvPV(value, PL_na);
        RETVAL = bson_array_builder_append_symbol(bab_ptr, value_str, length);
    OUTPUT:
        RETVAL

bool
array_builder_append_time_t(bab, value)
    SV *bab;
    time_t value;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        RETVAL = bson_array_builder_append_time_t(bab_ptr, value);
    OUTPUT:
        RETVAL

bool
array_builder_append_timeval(bab, value)
    SV *bab;
    SV *value;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        struct timeval *value_ptr = (struct timeval*)SvIV(value);
        RETVAL = bson_array_builder_append_timeval(bab_ptr, value_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_date_time(bab, value)
    SV *bab;
    int64_t value;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        RETVAL = bson_array_builder_append_date_time(bab_ptr, value);
    OUTPUT:
        RETVAL

bool
array_builder_append_now_utc(bab)
    SV *bab;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        RETVAL = bson_array_builder_append_now_utc(bab_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_timestamp(bab, timestamp, increment)
    SV *bab;
    uint32_t timestamp;
    uint32_t increment;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        RETVAL = bson_array_builder_append_timestamp(bab_ptr, timestamp, increment);
    OUTPUT:
        RETVAL

bool
array_builder_append_undefined(bab)
    SV *bab;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        RETVAL = bson_array_builder_append_undefined(bab_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_array_builder_begin(bab, child)
    SV *bab;
    SV *child;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        bson_array_builder_t **child_ptr = (bson_array_builder_t**)SvIV(child);
        RETVAL = bson_array_builder_append_array_builder_begin(bab_ptr, child_ptr);
    OUTPUT:
        RETVAL

bool
array_builder_append_array_builder_end(bab, child)
    SV *bab;
    SV *child;
    CODE:
        bson_array_builder_t *bab_ptr = (bson_array_builder_t*)SvIV(bab);
        bson_array_builder_t **child_ptr = (bson_array_builder_t**)SvIV(child);
        RETVAL = bson_array_builder_append_array_builder_end(bab_ptr, child_ptr);
    OUTPUT:
        RETVAL

bson_context_t *
context_get_default()
    CODE:
        RETVAL = bson_context_get_default();
    OUTPUT:
        RETVAL

bson_context_t *
context_new(flags)
    bson_context_flags_t flags;
    CODE:
        RETVAL = bson_context_new(flags);
    OUTPUT:
        RETVAL

void
context_destroy(context)
    SV *context;
    CODE:
        bson_context_t *context_ptr = (bson_context_t*)SvIV(context);
        bson_context_destroy(context_ptr);

bool
decimal128_from_string(string, dec)
    SV *string;
    SV *dec;
    CODE:
        STRLEN len;
        const char *str = SvPV(string, len);
        bson_decimal128_t *dec_ptr = (bson_decimal128_t*)SvIV(dec);
        RETVAL = bson_decimal128_from_string(str, dec_ptr);
    OUTPUT:
        RETVAL

bool
decimal128_from_string_w_len(string, len, dec)
    SV *string;
    int len;
    SV *dec;
    CODE:
        STRLEN actual_len;
        const char *str = SvPV(string, actual_len);
        if (len > actual_len) len = actual_len;
        bson_decimal128_t *dec_ptr = (bson_decimal128_t*)SvIV(dec);
        RETVAL = bson_decimal128_from_string_w_len(str, len, dec_ptr);
    OUTPUT:
        RETVAL

void
decimal128_to_string(dec, str)
    SV *dec;
    SV *str;
    CODE:
        char buffer[128];
        bson_decimal128_t *dec_ptr = (bson_decimal128_t*)SvIV(dec);
        bson_decimal128_to_string(dec_ptr, buffer);
        sv_setpv(str, buffer);

void
set_error(error, domain, code, format, ...)
    SV *error;
    uint32_t domain;
    uint32_t code;
    const char *format;
    CODE:
        bson_error_t *error_ptr = (bson_error_t*)SvIV(error);
        bson_set_error(error_ptr, domain, code, format);

char *
strerror_r(err_code, buf, buflen)
    int err_code;
    SV *buf;
    size_t buflen;
    CODE:
        char *buf_ptr = SvPV_nolen(buf);
        RETVAL = bson_strerror_r(err_code, buf_ptr, buflen);
    OUTPUT:
        RETVAL

void
iter_array(iter, array_len, array)
    SV *iter;
    SV *array_len;
    SV *array;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        uint32_t *len_ptr = (uint32_t*)SvIV(array_len);
        const uint8_t **array_ptr = (const uint8_t**)SvIV(array);
        bson_iter_array(iter_ptr, len_ptr, array_ptr);

bool
iter_as_bool(iter)
    SV *iter;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        RETVAL = bson_iter_as_bool(iter_ptr);
    OUTPUT:
        RETVAL

double
iter_as_double(iter)
    SV *iter;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        RETVAL = bson_iter_as_double(iter_ptr);
    OUTPUT:
        RETVAL

int64_t
iter_as_int64(iter)
    SV *iter;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        RETVAL = bson_iter_as_int64(iter_ptr);
    OUTPUT:
        RETVAL

void
iter_binary(iter, subtype, binary_len, binary)
    SV *iter;
    SV *subtype;
    SV *binary_len;
    SV *binary;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        bson_subtype_t *subtype_ptr = (bson_subtype_t*)SvIV(subtype);
        uint32_t *binary_len_ptr = (uint32_t*)SvIV(binary_len);
        const uint8_t **binary_ptr = (const uint8_t**)SvIV(binary);
        bson_iter_binary(iter_ptr, subtype_ptr, binary_len_ptr, binary_ptr);

bool
iter_bool(iter)
    SV *iter;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        RETVAL = bson_iter_bool(iter_ptr);
    OUTPUT:
        RETVAL

const char *
iter_code(iter, length)
    SV *iter;
    SV *length;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        uint32_t *length_ptr = (uint32_t*)SvIV(length);
        RETVAL = bson_iter_code(iter_ptr, length_ptr);
    OUTPUT:
        RETVAL

const char *
iter_codewscope(iter, length, scope_len, scope)
    SV *iter;
    SV *length;
    SV *scope_len;
    SV *scope;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        uint32_t *length_ptr = (uint32_t*)SvIV(length);
        uint32_t *scope_len_ptr = (uint32_t*)SvIV(scope_len);
        const uint8_t **scope_ptr = (const uint8_t**)SvIV(scope);
        RETVAL = bson_iter_codewscope(iter_ptr, length_ptr, scope_len_ptr, scope_ptr);
    OUTPUT:
        RETVAL

int64_t
iter_date_time(iter)
    SV *iter;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        RETVAL = bson_iter_date_time(iter_ptr);
    OUTPUT:
        RETVAL

void
iter_dbpointer(iter, collection_len, collection, oid)
    SV *iter;
    SV *collection_len;
    SV *collection;
    SV *oid;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        uint32_t *collection_len_ptr = (uint32_t*)SvIV(collection_len);
        const char **collection_ptr = (const char**)SvIV(collection);
        const bson_oid_t **oid_ptr = (const bson_oid_t**)SvIV(oid);
        bson_iter_dbpointer(iter_ptr, collection_len_ptr, collection_ptr, oid_ptr);

bool
iter_decimal128(iter, dec)
    SV *iter;
    SV *dec;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        bson_decimal128_t *dec_ptr = (bson_decimal128_t*)SvIV(dec);
        RETVAL = bson_iter_decimal128(iter_ptr, dec_ptr);
    OUTPUT:
        RETVAL

void
iter_document(iter, document_len, document)
    SV *iter;
    SV *document_len;
    SV *document;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        uint32_t *document_len_ptr = (uint32_t*)SvIV(document_len);
        const uint8_t **document_ptr = (const uint8_t**)SvIV(document);
        bson_iter_document(iter_ptr, document_len_ptr, document_ptr);

double
iter_double(iter)
    SV *iter;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        RETVAL = bson_iter_double(iter_ptr);
    OUTPUT:
        RETVAL

char *
iter_dup_utf8(iter, length)
    SV *iter;
    SV *length;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        uint32_t *length_ptr = (uint32_t*)SvIV(length);
        RETVAL = bson_iter_dup_utf8(iter_ptr, length_ptr);
    OUTPUT:
        RETVAL

bool
iter_find(iter, key)
    SV *iter;
    SV *key;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        const char *key_ptr = SvPV_nolen(key);
        RETVAL = bson_iter_find(iter_ptr, key_ptr);
    OUTPUT:
        RETVAL

bool
iter_find_case(iter, key)
    SV *iter;
    SV *key;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        const char *key_ptr = SvPV_nolen(key);
        RETVAL = bson_iter_find_case(iter_ptr, key_ptr);
    OUTPUT:
        RETVAL

bool
iter_find_descendant(iter, dotkey, descendant)
    SV *iter;
    SV *dotkey;
    SV *descendant;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        const char *dotkey_ptr = SvPV_nolen(dotkey);
        bson_iter_t *descendant_ptr = (bson_iter_t*)SvIV(descendant);
        RETVAL = bson_iter_find_descendant(iter_ptr, dotkey_ptr, descendant_ptr);
    OUTPUT:
        RETVAL

bool
iter_find_w_len(iter, key, keylen)
    SV *iter;
    SV *key;
    int keylen;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        const char *key_ptr = SvPV_nolen(key);
        RETVAL = bson_iter_find_w_len(iter_ptr, key_ptr, keylen);
    OUTPUT:
        RETVAL

bool
iter_init(iter, bson)
    SV *iter;
    SV *bson;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        const bson_t *bson_ptr = (const bson_t*)SvIV(bson);
        RETVAL = bson_iter_init(iter_ptr, bson_ptr);
    OUTPUT:
        RETVAL

bool
iter_init_find(iter, bson, key)
    SV *iter;
    SV *bson;
    SV *key;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        const bson_t *bson_ptr = (const bson_t*)SvIV(bson);
        const char *key_ptr = SvPV_nolen(key);
        RETVAL = bson_iter_init_find(iter_ptr, bson_ptr, key_ptr);
    OUTPUT:
        RETVAL

bool
iter_init_find_case(iter, bson, key)
    SV *iter;
    SV *bson;
    SV *key;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        const bson_t *bson_ptr = (const bson_t*)SvIV(bson);
        const char *key_ptr = SvPV_nolen(key);
        RETVAL = bson_iter_init_find_case(iter_ptr, bson_ptr, key_ptr);
    OUTPUT:
        RETVAL

bool
iter_init_find_w_len(iter, bson, key, keylen)
    SV *iter;
    SV *bson;
    SV *key;
    int keylen;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        const bson_t *bson_ptr = (const bson_t*)SvIV(bson);
        const char *key_ptr = SvPV_nolen(key);
        RETVAL = bson_iter_init_find_w_len(iter_ptr, bson_ptr, key_ptr, keylen);
    OUTPUT:
        RETVAL

bool
iter_init_from_data(iter, data, length)
    SV *iter;
    SV *data;
    size_t length;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        const uint8_t *data_ptr = (const uint8_t*)SvPV_nolen(data);
        RETVAL = bson_iter_init_from_data(iter_ptr, data_ptr, length);
    OUTPUT:
        RETVAL

bool
iter_init_from_data_at_offset(iter, data, length, offset, keylen)
    SV *iter;
    SV *data;
    size_t length;
    uint32_t offset;
    uint32_t keylen;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        const uint8_t *data_ptr = (const uint8_t*)SvPV_nolen(data);
        RETVAL = bson_iter_init_from_data_at_offset(iter_ptr, data_ptr, length, offset, keylen);
    OUTPUT:
        RETVAL

int32_t
iter_int32(iter)
    SV *iter;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        RETVAL = bson_iter_int32(iter_ptr);
    OUTPUT:
        RETVAL

int64_t
iter_int64(iter)
    SV *iter;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        RETVAL = bson_iter_int64(iter_ptr);
    OUTPUT:
        RETVAL

const char *
iter_key(iter)
    SV *iter;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        RETVAL = bson_iter_key(iter_ptr);
    OUTPUT:
        RETVAL

uint32_t
iter_key_len(iter)
    SV *iter;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        RETVAL = bson_iter_key_len(iter_ptr);
    OUTPUT:
        RETVAL

bool
iter_next(iter)
    SV *iter;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        RETVAL = bson_iter_next(iter_ptr);
    OUTPUT:
        RETVAL

uint32_t
iter_offset(iter)
    SV *iter;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        RETVAL = bson_iter_offset(iter_ptr);
    OUTPUT:
        RETVAL

const bson_oid_t *
iter_oid(iter)
    SV *iter;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        RETVAL = bson_iter_oid(iter_ptr);
    OUTPUT:
        RETVAL

void
iter_overwrite_bool(iter, value)
    SV *iter;
    bool value;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        bson_iter_overwrite_bool(iter_ptr, value);

void
iter_overwrite_date_time(iter, value)
    SV *iter;
    int64_t value;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        bson_iter_overwrite_date_time(iter_ptr, value);

void
iter_overwrite_decimal128(iter, value)
    SV *iter;
    SV *value;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        const bson_decimal128_t *value_ptr = (const bson_decimal128_t*)SvIV(value);
        bson_iter_overwrite_decimal128(iter_ptr, value_ptr);

void
iter_overwrite_double(iter, value)
    SV *iter;
    double value;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        bson_iter_overwrite_double(iter_ptr, value);

void
iter_overwrite_int32(iter, value)
    SV *iter;
    int32_t value;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        bson_iter_overwrite_int32(iter_ptr, value);

void
iter_overwrite_int64(iter, value)
    SV *iter;
    int64_t value;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        bson_iter_overwrite_int64(iter_ptr, value);

void
iter_overwrite_oid(iter, value)
    SV *iter;
    SV *value;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        const bson_oid_t *value_ptr = (const bson_oid_t*)SvIV(value);
        bson_iter_overwrite_oid(iter_ptr, value_ptr);

void
iter_overwrite_timestamp(iter, timestamp, increment)
    SV *iter;
    uint32_t timestamp;
    uint32_t increment;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        bson_iter_overwrite_timestamp(iter_ptr, timestamp, increment);

bool
iter_recurse(iter, child)
    SV *iter;
    SV *child;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        bson_iter_t *child_ptr = (bson_iter_t*)SvIV(child);
        RETVAL = bson_iter_recurse(iter_ptr, child_ptr);
    OUTPUT:
        RETVAL

const char *
iter_regex(iter, options)
    SV *iter;
    SV *options;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        const char *options_ptr;
        RETVAL = bson_iter_regex(iter_ptr, &options_ptr);
        if (options) {
            SvPV_set(options, options_ptr);
        }
    OUTPUT:
        RETVAL

const char *
iter_symbol(iter, length)
    SV *iter;
    SV *length;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        uint32_t *length_ptr;
        RETVAL = bson_iter_symbol(iter_ptr, length_ptr);
        if (length) {
            SvIV_set(length, *length_ptr);
        }
    OUTPUT:
        RETVAL

time_t
iter_time_t(iter)
    SV *iter;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        RETVAL = bson_iter_time_t(iter_ptr);
    OUTPUT:
        RETVAL

void
iter_timestamp(iter, timestamp, increment)
    SV *iter;
    SV *timestamp;
    SV *increment;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        uint32_t ts, inc;
        bson_iter_timestamp(iter_ptr, &ts, &inc);
        if (timestamp) {
            SvIV_set(timestamp, ts);
        }
        if (increment) {
            SvIV_set(increment, inc);
        }

void
iter_timeval(iter, tv)
    SV *iter;
    SV *tv;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        struct timeval *tv_ptr = (struct timeval*)SvIV(tv);
        bson_iter_timeval(iter_ptr, tv_ptr);

bson_type_t
iter_type(iter)
    SV *iter;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        RETVAL = bson_iter_type(iter_ptr);
    OUTPUT:
        RETVAL

const char *
iter_utf8(iter, length)
    SV *iter;
    SV *length;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        uint32_t *length_ptr;
        RETVAL = bson_iter_utf8(iter_ptr, length_ptr);
        if (length) {
            SvIV_set(length, *length_ptr);
        }
    OUTPUT:
        RETVAL

const bson_value_t *
iter_value(iter)
    SV *iter;
    CODE:
        bson_iter_t *iter_ptr = (bson_iter_t*)SvIV(iter);
        RETVAL = bson_iter_value(iter_ptr);
    OUTPUT:
        RETVAL

bool
iter_visit_all(iter, visitor, data)
    SV *iter;
    SV *visitor;
    SV *data;
    CODE:
        const bson_iter_t *iter_ptr = (const bson_iter_t*)SvIV(iter);
        const bson_visitor_t *visitor_ptr = (const bson_visitor_t*)SvIV(visitor);
        void *data_ptr = (void*)SvIV(data);
        RETVAL = bson_iter_visit_all(iter_ptr, visitor_ptr, data_ptr);
    OUTPUT:
        RETVAL

void
json_data_reader_ingest(reader, data, len)
    SV *reader;
    SV *data;
    SV *len;
    CODE:
        bson_json_reader_t *reader_ptr = (bson_json_reader_t*)SvIV(reader);
        const uint8_t *data_ptr = (const uint8_t*)SvPV(data, PL_na);
        size_t len_val = (size_t)SvIV(len);
        bson_json_data_reader_ingest(reader_ptr, data_ptr, len_val);

bson_json_reader_t *
json_data_reader_new(allow_multiple, size)
    bool allow_multiple;
    size_t size;
    CODE:
        RETVAL = bson_json_data_reader_new(allow_multiple, size);
    OUTPUT:
        RETVAL

void
json_reader_destroy(reader)
    SV *reader;
    CODE:
        bson_json_reader_t *reader_ptr = (bson_json_reader_t*)SvIV(reader);
        bson_json_reader_destroy(reader_ptr);

bson_json_reader_t *
json_reader_new(data, cb, dcb, allow_multiple, buf_size)
    SV *data;
    SV *cb;
    SV *dcb;
    bool allow_multiple;
    size_t buf_size;
    CODE:
        void *data_ptr = (void*)SvIV(data);
        bson_json_reader_cb cb_ptr = (bson_json_reader_cb)SvIV(cb);
        bson_json_destroy_cb dcb_ptr = (bson_json_destroy_cb)SvIV(dcb);
        RETVAL = bson_json_reader_new(data_ptr, cb_ptr, dcb_ptr, allow_multiple, buf_size);
    OUTPUT:
        RETVAL

bson_json_reader_t *
json_reader_new_from_fd(fd, close_on_destroy)
    int fd;
    bool close_on_destroy;
    CODE:
        RETVAL = bson_json_reader_new_from_fd(fd, close_on_destroy);
    OUTPUT:
        RETVAL

bson_json_reader_t *
json_reader_new_from_file(filename, error)
    const char *filename;
    bson_error_t *error;
    CODE:
        RETVAL = bson_json_reader_new_from_file(filename, error);
    OUTPUT:
        RETVAL

int
json_reader_read(reader, bson, error)
    bson_json_reader_t *reader;
    bson_t *bson;
    bson_error_t *error;
    CODE:
        RETVAL = bson_json_reader_read(reader, bson, error);
    OUTPUT:
        RETVAL

int
oid_compare(oid1, oid2)
    const bson_oid_t *oid1;
    const bson_oid_t *oid2;
    CODE:
        RETVAL = bson_oid_compare(oid1, oid2);
    OUTPUT:
        RETVAL

static int
oid_compare_unsafe(oid1, oid2)
    const bson_oid_t *oid1;
    const bson_oid_t *oid2;
    CODE:
        RETVAL = bson_oid_compare_unsafe(oid1, oid2);
    OUTPUT:
        RETVAL

void
oid_copy(src, dst)
    const bson_oid_t *src;
    bson_oid_t *dst;
    CODE:
        bson_oid_copy(src, dst);

static void
oid_copy_unsafe(src, dst)
    const bson_oid_t *src;
    bson_oid_t *dst;
    CODE:
        bson_oid_copy_unsafe(src, dst);

bool
oid_equal(oid1, oid2)
    const bson_oid_t *oid1;
    const bson_oid_t *oid2;
    CODE:
        RETVAL = bson_oid_equal(oid1, oid2);
    OUTPUT:
        RETVAL

static bool
oid_equal_unsafe(oid1, oid2)
    const bson_oid_t *oid1;
    const bson_oid_t *oid2;
    CODE:
        RETVAL = bson_oid_equal_unsafe(oid1, oid2);
    OUTPUT:
        RETVAL

time_t
oid_get_time_t(oid)
    const bson_oid_t *oid;
    CODE:
        RETVAL = bson_oid_get_time_t(oid);
    OUTPUT:
        RETVAL

static time_t
oid_get_time_t_unsafe(oid)
    const bson_oid_t *oid;
    CODE:
        RETVAL = bson_oid_get_time_t_unsafe(oid);
    OUTPUT:
        RETVAL

uint32_t
oid_hash(oid)
    const bson_oid_t *oid;
    CODE:
        RETVAL = bson_oid_hash(oid);
    OUTPUT:
        RETVAL

static uint32_t
oid_hash_unsafe(oid)
    const bson_oid_t *oid;
    CODE:
        RETVAL = bson_oid_hash_unsafe(oid);
    OUTPUT:
        RETVAL

void
oid_init(oid, context)
    bson_oid_t *oid;
    bson_context_t *context;
    CODE:
        bson_oid_init(oid, context);

void
oid_init_from_data(oid, data)
    bson_oid_t *oid;
    const uint8_t *data;
    CODE:
        bson_oid_init_from_data(oid, data);

void
oid_init_from_string(oid, str)
    bson_oid_t *oid;
    const char *str;
    CODE:
        bson_oid_init_from_string(oid, str);

static void
oid_init_from_string_unsafe(oid, str)
    bson_oid_t *oid;
    const char *str;
    CODE:
        bson_oid_init_from_string_unsafe(oid, str);

void
oid_init_sequence(oid, context)
    bson_oid_t *oid;
    bson_context_t *context;
    CODE:
        bson_oid_init_sequence(oid, context);

bool
oid_is_valid(str, length)
    const char *str;
    size_t length;
    CODE:
        RETVAL = bson_oid_is_valid(str, length);
    OUTPUT:
        RETVAL

void
oid_to_string(oid, str)
    const bson_oid_t *oid;
    char * str;
    CODE:
        bson_oid_to_string(oid, str);

void
reader_destroy(reader)
    bson_reader_t *reader;
    CODE:
        bson_reader_destroy(reader);

bson_reader_t *
reader_new_from_data(data, length)
    const uint8_t *data;
    size_t length;
    CODE:
        RETVAL = bson_reader_new_from_data(data, length);
    OUTPUT:
        RETVAL

bson_reader_t *
reader_new_from_fd(fd, close_on_destroy)
    int fd;
    bool close_on_destroy;
    CODE:
        RETVAL = bson_reader_new_from_fd(fd, close_on_destroy);
    OUTPUT:
        RETVAL

bson_reader_t *
reader_new_from_file(path, error)
    const char *path;
    bson_error_t *error;
    CODE:
        RETVAL = bson_reader_new_from_file(path, error);
    OUTPUT:
        RETVAL

bson_reader_t *
reader_new_from_handle(handle, rf, df)
    void *handle;
    bson_reader_read_func_t rf;
    bson_reader_destroy_func_t df;
    CODE:
        RETVAL = bson_reader_new_from_handle(handle, rf, df);
    OUTPUT:
        RETVAL

const bson_t *
reader_read(reader, reached_eof)
    bson_reader_t *reader;
    bool *reached_eof;
    CODE:
        RETVAL = bson_reader_read(reader, reached_eof);
    OUTPUT:
        RETVAL

void
reader_reset(reader)
    bson_reader_t *reader;
    CODE:
        bson_reader_reset(reader);

void
reader_set_destroy_func(reader, func)
    bson_reader_t *reader;
    bson_reader_destroy_func_t func;
    CODE:
        bson_reader_set_destroy_func(reader, func);

void
reader_set_read_func(reader, func)
    bson_reader_t *reader;
    bson_reader_read_func_t func;
    CODE:
        bson_reader_set_read_func(reader, func);

off_t
reader_tell(reader)
    bson_reader_t *reader;
    CODE:
        RETVAL = bson_reader_tell(reader);
    OUTPUT:
        RETVAL

int64_t
ascii_strtoll(str, endptr, base)
    const char *str;
    char **endptr;
    int base;
    CODE:
        RETVAL = bson_ascii_strtoll(str, endptr, base);
    OUTPUT:
        RETVAL

bool
isspace(c)
    int c;
    CODE:
        RETVAL = bson_isspace(c);
    OUTPUT:
        RETVAL

int
snprintf(str, size, format, ...)
    char *str;
    size_t size;
    const char *format;
    CODE:
        RETVAL = bson_snprintf(str, size, format);
    OUTPUT:
        RETVAL

int
strcasecmp(s1, s2)
    const char *s1;
    const char *s2;
    CODE:
        RETVAL = bson_strcasecmp(s1, s2);
    OUTPUT:
        RETVAL

char *
strdup(str)
    const char *str;
    CODE:
        RETVAL = bson_strdup(str);
    OUTPUT:
        RETVAL

char *
strdup_printf(format, ...)
    const char *format;
    CODE:
        RETVAL = bson_strdup_printf(format);
    OUTPUT:
        RETVAL

void
strfreev(strv)
    char **strv;
    CODE:
        bson_strfreev(strv);

void
strncpy(dst, src, size)
    char *dst;
    const char *src;
    size_t size;
    CODE:
        bson_strncpy(dst, src, size);

char *
strndup(str, n_bytes)
    const char *str;
    size_t n_bytes;
    CODE:
        RETVAL = bson_strndup(str, n_bytes);
    OUTPUT:
        RETVAL

size_t
strnlen(s, maxlen)
    const char *s;
    size_t maxlen;
    CODE:
        RETVAL = bson_strnlen(s, maxlen);
    OUTPUT:
        RETVAL

size_t
uint32_to_string(value, strptr, str, size)
    uint32_t value;
    const char **strptr;
    char *str;
    size_t size;
    CODE:
        RETVAL = bson_uint32_to_string(value, strptr, str, size);
    OUTPUT:
        RETVAL

char *
utf8_escape_for_json(utf8, utf8_len)
    const char *utf8;
    ssize_t utf8_len;
    CODE:
        RETVAL = bson_utf8_escape_for_json(utf8, utf8_len);
    OUTPUT:
        RETVAL

void
utf8_from_unichar(unichar, utf8, len)
    bson_unichar_t unichar;
    char * utf8;
    uint32_t *len;
    CODE:
        bson_utf8_from_unichar(unichar, utf8, len);

bson_unichar_t
utf8_get_char(utf8)
    const char *utf8;
    CODE:
        RETVAL = bson_utf8_get_char(utf8);
    OUTPUT:
        RETVAL

const char *
utf8_next_char(utf8)
    const char *utf8;
    CODE:
        RETVAL = bson_utf8_next_char(utf8);
    OUTPUT:
        RETVAL

bool
utf8_validate(utf8, utf8_len, allow_null)
    const char *utf8;
    size_t utf8_len;
    bool allow_null;
    CODE:
        RETVAL = bson_utf8_validate(utf8, utf8_len, allow_null);
    OUTPUT:
        RETVAL

void
string_append(string, str)
    bson_string_t *string;
    const char *str;
    CODE:
        bson_string_append(string, str);

void
string_append_c(string, str)
    bson_string_t *string;
    char str;
    CODE:
        bson_string_append_c(string, str);

void
string_append_printf(string, format, ...)
    bson_string_t *string;
    const char *format;
    CODE:
        bson_string_append_printf(string, format);

void
string_append_unichar(string, unichar)
    bson_string_t *string;
    bson_unichar_t unichar;
    CODE:
        bson_string_append_unichar(string, unichar);

char *
string_free(string, free_segment)
    bson_string_t *string;
    bool free_segment;
    CODE:
        RETVAL = bson_string_free(string, free_segment);
    OUTPUT:
        RETVAL

bson_string_t *
string_new(str)
    const char *str;
    CODE:
        RETVAL = bson_string_new(str);
    OUTPUT:
        RETVAL

void
string_truncate(string, len)
    bson_string_t *string;
    uint32_t len;
    CODE:
        bson_string_truncate(string, len);

void
value_copy(src, dst)
    const bson_value_t *src;
    bson_value_t *dst;
    CODE:
        bson_value_copy(src, dst);

void
writer_begin(writer, bson)
    bson_writer_t *writer;
    bson_t **bson;
    CODE:
        bson_writer_begin(writer, bson);

void
writer_destroy(writer)
    bson_writer_t *writer;
    CODE:
        bson_writer_destroy(writer);

void
writer_end(writer)
    bson_writer_t *writer;
    CODE:
        bson_writer_end(writer);

size_t
writer_length(writer)
    bson_writer_t *writer;
    CODE:
        RETVAL = bson_writer_get_length(writer);
    OUTPUT:
        RETVAL

bson_writer_t *
writer_create(buf, buflen, offset, realloc_func, realloc_func_ctx)
    uint8_t **buf;
    size_t *buflen;
    size_t offset;
    bson_realloc_func realloc_func;
    void *realloc_func_ctx;
    CODE:
        RETVAL = bson_writer_new(buf, buflen, offset, realloc_func, realloc_func_ctx);
    OUTPUT:
        RETVAL

void
writer_rollback(writer)
    bson_writer_t *writer;
    CODE:
        bson_writer_rollback(writer);

int64_t
get_monotonic_time()
    CODE:
        RETVAL = bson_get_monotonic_time();
    OUTPUT:
        RETVAL

int
gettimeofday(tv)
    struct timeval *tv;
    CODE:
        RETVAL = bson_gettimeofday(tv);
    OUTPUT:
        RETVAL

bool
check_version(required_major, required_minor, required_micro)
    int required_major;
    int required_minor;
    int required_micro;
    CODE:
        RETVAL = bson_check_version(required_major, required_minor, required_micro);
    OUTPUT:
        RETVAL

int
get_major_version()
    CODE:
        RETVAL = bson_get_major_version();
    OUTPUT:
        RETVAL

int
get_micro_version()
    CODE:
        RETVAL = bson_get_micro_version();
    OUTPUT:
        RETVAL

int
get_minor_version()
    CODE:
        RETVAL = bson_get_minor_version();
    OUTPUT:
        RETVAL

const char *
get_version()
    CODE:
        RETVAL = bson_get_version();
    OUTPUT:
        RETVAL

void
bson_free(mem)
    void *mem;
    CODE:
        bson_free(mem);

void *
bson_malloc(num_bytes)
    size_t num_bytes;
    CODE:
        RETVAL = bson_malloc(num_bytes);
    OUTPUT:
        RETVAL

void *
bson_malloc0(num_bytes)
    size_t num_bytes;
    CODE:
        RETVAL = bson_malloc0(num_bytes);
    OUTPUT:
        RETVAL

void *
bson_aligned_alloc(alignment, num_bytes)
    size_t alignment;
    size_t num_bytes;
    CODE:
        RETVAL = bson_aligned_alloc(alignment, num_bytes);
    OUTPUT:
        RETVAL

void *
bson_aligned_alloc0(alignment, num_bytes)
    size_t alignment;
    size_t num_bytes;
    CODE:
        RETVAL = bson_aligned_alloc0(alignment, num_bytes);
    OUTPUT:
        RETVAL

void
bson_mem_restore_vtable()
    CODE:
        bson_mem_restore_vtable();

void
bson_mem_set_vtable(vtable)
    const bson_mem_vtable_t *vtable;
    CODE:
        bson_mem_set_vtable(vtable);

void *
bson_realloc(mem, num_bytes)
    void *mem;
    size_t num_bytes;
    CODE:
        RETVAL = bson_realloc(mem, num_bytes);
    OUTPUT:
        RETVAL

void *
bson_realloc_ctx(mem, num_bytes, ctx)
    void *mem;
    size_t num_bytes;
    void *ctx;
    CODE:
        RETVAL = bson_realloc_ctx(mem, num_bytes, ctx);
    OUTPUT:
        RETVAL

void
bson_zero_free(mem, size)
    void *mem;
    size_t size;
    CODE:
        bson_zero_free(mem, size);