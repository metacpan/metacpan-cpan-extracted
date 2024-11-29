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
    const char *key;
    int key_length;
    const bson_t *array;
    CODE:
        RETVAL = bson_append_array(bson, key, key_length, array);
    OUTPUT:
        RETVAL

bool
append_array_begin(bson, key, key_length, child)
    bson_t *bson;
    const char *key;
    int key_length;
    bson_t *child;
    CODE:
        RETVAL = bson_append_array_begin(bson, key, key_length, child);
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
    const char *key;
    int key_length;
    bson_subtype_t subtype;
    const uint8_t *binary;
    uint32_t length;
    CODE:
        RETVAL = bson_append_binary(bson, key, key_length, subtype, binary, length);
    OUTPUT:
        RETVAL

bool
append_bool(bson, key, key_length, value)
    bson_t *bson;
    const char *key;
    int key_length;
    bool value;
    CODE:
        RETVAL = bson_append_bool(bson, key, key_length, value);
    OUTPUT:
        RETVAL

bool
append_code(bson, key, key_length, javascript)
    bson_t *bson;
    const char *key;
    int key_length;
    const char *javascript;
    CODE:
        RETVAL = bson_append_code(bson, key, key_length, javascript);
    OUTPUT:
        RETVAL

bool
append_code_with_scope(bson, key, key_length, javascript, scope)
    bson_t *bson;
    const char *key;
    int key_length;
    const char *javascript;
    const bson_t *scope;
    CODE:
        RETVAL = bson_append_code_with_scope(bson, key, key_length, javascript, scope);
    OUTPUT:
        RETVAL

bool
append_date_time(bson, key, key_length, value)
    bson_t *bson;
    const char *key;
    int key_length;
    int64_t value;
    CODE:
        RETVAL = bson_append_date_time(bson, key, key_length, value);
    OUTPUT:
        RETVAL

bool
append_dbpointer(bson, key, key_length, collection, oid)
    bson_t *bson;
    const char *key;
    int key_length;
    const char *collection;
    const bson_oid_t *oid;
    CODE:
        RETVAL = bson_append_dbpointer(bson, key, key_length, collection, oid);
    OUTPUT:
        RETVAL

bool
append_decimal128(bson, key, key_length, value)
    bson_t *bson;
    const char *key;
    int key_length;
    const bson_decimal128_t *value;
    CODE:
        RETVAL = bson_append_decimal128(bson, key, key_length, value);
    OUTPUT:
        RETVAL

bool
append_document(bson, key, key_length, value)
    bson_t *bson;
    const char *key;
    int key_length;
    const bson_t *value;
    CODE:
        RETVAL = bson_append_document(bson, key, key_length, value);
    OUTPUT:
        RETVAL

bool
append_document_begin(bson, key, key_length, child)
    bson_t *bson;
    const char *key;
    int key_length;
    bson_t *child;
    CODE:
        RETVAL = bson_append_document_begin(bson, key, key_length, child);
    OUTPUT:
        RETVAL

bool
append_document_end(bson, child)
    bson_t *bson;
    bson_t *child;
    CODE:
        RETVAL = bson_append_document_end(bson, child);
    OUTPUT:
        RETVAL

bool
append_double(bson, key, key_length, value)
    bson_t *bson;
    const char *key;
    int key_length;
    double value;
    CODE:
        RETVAL = bson_append_double(bson, key, key_length, value);
    OUTPUT:
        RETVAL

bool
append_int32(bson, key, key_length, value)
    bson_t *bson;
    const char *key;
    int key_length;
    int32_t value;
    CODE:
        RETVAL = bson_append_int32(bson, key, key_length, value);
    OUTPUT:
        RETVAL

bool
append_int64(bson, key, key_length, value)
    bson_t *bson;
    const char *key;
    int key_length;
    int64_t value;
    CODE:
        RETVAL = bson_append_int64(bson, key, key_length, value);
    OUTPUT:
        RETVAL

bool
append_iter(bson, key, key_length, iter)
    bson_t *bson;
    const char *key;
    int key_length;
    const bson_iter_t *iter;
    CODE:
        RETVAL = bson_append_iter(bson, key, key_length, iter);
    OUTPUT:
        RETVAL

bool
append_maxkey(bson, key, key_length)
    bson_t *bson;
    const char *key;
    int key_length;
    CODE:
        RETVAL = bson_append_maxkey(bson, key, key_length);
    OUTPUT:
        RETVAL

bool
append_minkey(bson, key, key_length)
    bson_t *bson;
    const char *key;
    int key_length;
    CODE:
        RETVAL = bson_append_minkey(bson, key, key_length);
    OUTPUT:
        RETVAL

bool
append_now_utc(bson, key, key_length)
    bson_t *bson;
    const char *key;
    int key_length;
    CODE:
        RETVAL = bson_append_now_utc(bson, key, key_length);
    OUTPUT:
        RETVAL

bool
append_null(bson, key, key_length)
    bson_t *bson;
    const char *key;
    int key_length;
    CODE:
        RETVAL = bson_append_null(bson, key, key_length);
    OUTPUT:
        RETVAL

bool
append_oid(bson, key, key_length, oid)
    bson_t *bson;
    const char *key;
    int key_length;
    const bson_oid_t *oid;
    CODE:
        RETVAL = bson_append_oid(bson, key, key_length, oid);
    OUTPUT:
        RETVAL

bool
append_regex(bson, key, key_length, regex, options)
    bson_t *bson;
    const char *key;
    int key_length;
    const char *regex;
    const char *options;
    CODE:
        RETVAL = bson_append_regex(bson, key, key_length, regex, options);
    OUTPUT:
        RETVAL

bool
append_regex_w_len(bson, key, key_length, regex, regex_length, options)
    bson_t *bson;
    const char *key;
    int key_length;
    const char *regex;
    int regex_length;
    const char *options;
    CODE:
        RETVAL = bson_append_regex_w_len(bson, key, key_length, regex, regex_length, options);
    OUTPUT:
        RETVAL

bool
append_symbol(bson, key, key_length, value, length)
    bson_t *bson;
    const char *key;
    int key_length;
    const char *value;
    int length;
    CODE:
        RETVAL = bson_append_symbol(bson, key, key_length, value, length);
    OUTPUT:
        RETVAL

bool
append_time_t(bson, key, key_length, value)
    bson_t *bson;
    const char *key;
    int key_length;
    time_t value;
    CODE:
        RETVAL = bson_append_time_t(bson, key, key_length, value);
    OUTPUT:
        RETVAL

bool
append_timestamp(bson, key, key_length, timestamp, increment)
    bson_t *bson;
    const char *key;
    int key_length;
    uint32_t timestamp;
    uint32_t increment;
    CODE:
        RETVAL = bson_append_timestamp(bson, key, key_length, timestamp, increment);
    OUTPUT:
        RETVAL

bool
append_timeval(bson, key, key_length, value)
    bson_t *bson;
    const char *key;
    int key_length;
    struct timeval *value;
    CODE:
        RETVAL = bson_append_timeval(bson, key, key_length, value);
    OUTPUT:
        RETVAL

bool
append_undefined(bson, key, key_length)
    bson_t *bson;
    const char *key;
    int key_length;
    CODE:
        RETVAL = bson_append_undefined(bson, key, key_length);
    OUTPUT:
        RETVAL

bool
append_utf8(bson, key, key_length, value, length)
    bson_t *bson;
    const char *key;
    int key_length;
    const char *value;
    int length;
    CODE:
        RETVAL = bson_append_utf8(bson, key, key_length, value, length);
    OUTPUT:
        RETVAL

bool
append_value(bson, key, key_length, value)
    bson_t *bson;
    const char *key;
    int key_length;
    const bson_value_t *value;
    CODE:
        RETVAL = bson_append_value(bson, key, key_length, value);
    OUTPUT:
        RETVAL

char *
array_as_canonical_extended_json(bson, length)
    const bson_t *bson;
    size_t *length;
    CODE:
        RETVAL = bson_as_canonical_extended_json(bson, length);
    OUTPUT:
        RETVAL

char *
array_as_json(bson, length)
    const bson_t *bson;
    size_t *length;
    CODE:
        RETVAL = bson_as_json(bson, length);
    OUTPUT:
        RETVAL

char *
array_as_legacy_extended_json(bson, length)
    const bson_t *bson;
    size_t *length;
    CODE:
        RETVAL = bson_as_legacy_extended_json(bson, length);
    OUTPUT:
        RETVAL

char *
array_as_relaxed_extended_json(bson, length)
    const bson_t *bson;
    size_t *length;
    CODE:
        RETVAL = bson_as_relaxed_extended_json(bson, length);
    OUTPUT:
        RETVAL

char *
as_canonical_extended_json(bson, length)
    const bson_t *bson;
    size_t *length;
    CODE:
        RETVAL = bson_as_canonical_extended_json(bson, length);
    OUTPUT:
        RETVAL

char *
as_json(bson, length)
    const bson_t *bson;
    size_t *length;
    CODE:
        RETVAL = bson_as_json(bson, length);
    OUTPUT:
        RETVAL

char *
as_json_with_opts(bson, length, opts)
    const bson_t *bson;
    size_t *length;
    const bson_json_opts_t *opts;
    CODE:
        RETVAL = bson_as_json_with_opts(bson, length, opts);
    OUTPUT:
        RETVAL

char *
as_legacy_extended_json(bson, length)
    const bson_t *bson;
    size_t *length;
    CODE:
        RETVAL = bson_as_legacy_extended_json(bson, length);
    OUTPUT:
        RETVAL

char *
as_relaxed_extended_json(bson, length)
    const bson_t *bson;
    size_t *length;
    CODE:
        RETVAL = bson_as_relaxed_extended_json(bson, length);
    OUTPUT:
        RETVAL

int
compare(bson, other)
    const bson_t *bson;
    const bson_t *other;
    CODE:
        RETVAL = bson_compare(bson, other);
    OUTPUT:
        RETVAL

bool
concat(dst, src)
    bson_t *dst;
    const bson_t *src;
    CODE:
        RETVAL = bson_concat(dst, src);
    OUTPUT:
        RETVAL

bson_t *
copy(bson)
    const bson_t *bson;
    CODE:
        RETVAL = bson_copy(bson);
    OUTPUT:
        RETVAL

void
copy_to(src, dst)
    const bson_t *src;
    bson_t *dst;
    CODE:
        bson_copy_to(src, dst);

void
copy_to_excluding_noinit(src, dst, first_exclude)
    const bson_t *src;
    bson_t *dst;
    const char *first_exclude;
    CODE:
        bson_copy_to_excluding_noinit(src, dst, first_exclude, NULL);

uint32_t
count_keys(bson)
    const bson_t *bson;
    CODE:
        RETVAL = bson_count_keys(bson);
    OUTPUT:
        RETVAL

void
destroy(bson)
    bson_t *bson;
    CODE:
        bson_destroy(bson);

uint8_t *
destroy_with_steal(bson, steal, length)
    bson_t *bson;
    bool steal;
    uint32_t *length;
    CODE:
        RETVAL = bson_destroy_with_steal(bson, steal, length);
    OUTPUT:
        RETVAL

bool
equal(bson, other)
    const bson_t *bson;
    const bson_t *other;
    CODE:
        RETVAL = bson_equal(bson, other);
    OUTPUT:
        RETVAL

const uint8_t *
get_data(bson)
    const bson_t *bson;
    CODE:
        RETVAL = bson_get_data(bson);
    OUTPUT:
        RETVAL

bool
has_field(bson, key)
    const bson_t *bson;
    const char *key;
    CODE:
        RETVAL = bson_has_field(bson, key);
    OUTPUT:
        RETVAL

void
init(b)
    bson_t *b;
    CODE:
        bson_init(b);

bool
init_from_json(b, data, len, error)
    bson_t *b;
    const char *data;
    ssize_t len;
    bson_error_t *error;
    CODE:
        RETVAL = bson_init_from_json(b, data, len, error);
    OUTPUT:
        RETVAL

bool
init_static(b, data, length)
    bson_t *b;
    const uint8_t *data;
    size_t length;
    CODE:
        RETVAL = bson_init_static(b, data, length);
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
    bson_json_opts_t *opts;
    CODE:
        bson_json_opts_destroy(opts);

bson_t *
new()
    CODE:
        RETVAL = bson_new();
    OUTPUT:
        RETVAL

bson_t *
new_from_buffer(buf, buf_len, realloc_func, realloc_func_ctx)
    uint8_t **buf;
    size_t *buf_len;
    bson_realloc_func realloc_func;
    void *realloc_func_ctx;
    CODE:
        RETVAL = bson_new_from_buffer(buf, buf_len, realloc_func, realloc_func_ctx);
    OUTPUT:
        RETVAL

bson_t *
new_from_data(data, length)
    const uint8_t *data;
    size_t length;
    CODE:
        RETVAL = bson_new_from_data(data, length);
    OUTPUT:
        RETVAL

bson_t *
new_from_json(data, len, error)
    const uint8_t *data;
    ssize_t len;
    bson_error_t *error;
    CODE:
        RETVAL = bson_new_from_json(data, len, error);
    OUTPUT:
        RETVAL

void
reinit(b)
    bson_t *b;
    CODE:
        bson_reinit(b);

uint8_t *
reserve_buffer(bson, size)
    bson_t *bson;
    uint32_t size;
    CODE:
        RETVAL = bson_reserve_buffer(bson, size);
    OUTPUT:
        RETVAL

bson_t *
sized_new(size)
    size_t size;
    CODE:
        RETVAL = bson_sized_new(size);
    OUTPUT:
        RETVAL

bool
steal(dst, src)
    bson_t *dst;
    bson_t *src;
    CODE:
        RETVAL = bson_steal(dst, src);
    OUTPUT:
        RETVAL

bool
validate(bson, flags, offset)
    const bson_t *bson;
    bson_validate_flags_t flags;
    size_t *offset;
    CODE:
        RETVAL = bson_validate(bson, flags, offset);
    OUTPUT:
        RETVAL

bool
validate_with_error(bson, flags, error)
    const bson_t *bson;
    bson_validate_flags_t flags;
    bson_error_t *error;
    CODE:
        RETVAL = bson_validate_with_error(bson, flags, error);
    OUTPUT:
        RETVAL

bool
validate_with_error_and_offset(bson, flags, offset, error)
    const bson_t *bson;
    bson_validate_flags_t flags;
    size_t *offset;
    bson_error_t *error;
    CODE:
        RETVAL = bson_validate_with_error_and_offset(bson, flags, offset, error);
    OUTPUT:
        RETVAL

bool
append_array_builder_begin(bson, key, key_length, child)
    bson_t *bson;
    const char *key;
    int key_length;
    bson_array_builder_t **child;
    CODE:
        RETVAL = bson_append_array_builder_begin(bson, key, key_length, child);
    OUTPUT:
        RETVAL

bool
append_array_builder_end(bson, child)
    bson_t *bson;
    bson_array_builder_t *child;
    CODE:
        RETVAL = bson_append_array_builder_end(bson, child);
    OUTPUT:
        RETVAL

bool
array_builder_append_value(bab, value)
    bson_array_builder_t *bab;
    const bson_value_t *value;
    CODE:
        RETVAL = bson_array_builder_append_value(bab, value);
    OUTPUT:
        RETVAL

bool
array_builder_append_array(bab, array)
    bson_array_builder_t *bab;
    const bson_t *array;
    CODE:
        RETVAL = bson_array_builder_append_array(bab, array);
    OUTPUT:
        RETVAL

bool
array_builder_append_binary(bab, subtype, binary, length)
    bson_array_builder_t *bab;
    bson_subtype_t subtype;
    const uint8_t *binary;
    uint32_t length;
    CODE:
        RETVAL = bson_array_builder_append_binary(bab, subtype, binary, length);
    OUTPUT:
        RETVAL

bool
array_builder_append_bool(bab, value)
    bson_array_builder_t *bab;
    bool value;
    CODE:
        RETVAL = bson_array_builder_append_bool(bab, value);
    OUTPUT:
        RETVAL

bool
array_builder_append_code(bab, javascript)
    bson_array_builder_t *bab;
    const char *javascript;
    CODE:
        RETVAL = bson_array_builder_append_code(bab, javascript);
    OUTPUT:
        RETVAL

bool
array_builder_append_code_with_scope(bab, javascript, scope)
    bson_array_builder_t *bab;
    const char *javascript;
    const bson_t *scope;
    CODE:
        RETVAL = bson_array_builder_append_code_with_scope(bab, javascript, scope);
    OUTPUT:
        RETVAL

bool
array_builder_append_dbpointer(bab, collection, oid)
    bson_array_builder_t *bab;
    const char *collection;
    const bson_oid_t *oid;
    CODE:
        RETVAL = bson_array_builder_append_dbpointer(bab, collection, oid);
    OUTPUT:
        RETVAL

bool
array_builder_append_double(bab, value)
    bson_array_builder_t *bab;
    double value;
    CODE:
        RETVAL = bson_array_builder_append_double(bab, value);
    OUTPUT:
        RETVAL

bool
array_builder_append_document(bab, value)
    bson_array_builder_t *bab;
    const bson_t *value;
    CODE:
        RETVAL = bson_array_builder_append_document(bab, value);
    OUTPUT:
        RETVAL

bool
array_builder_append_document_begin(bab, child)
    bson_array_builder_t *bab;
    bson_t *child;
    CODE:
        RETVAL = bson_array_builder_append_document_begin(bab, child);
    OUTPUT:
        RETVAL

bool
array_builder_append_document_end(bab, child)
    bson_array_builder_t *bab;
    bson_t *child;
    CODE:
        RETVAL = bson_array_builder_append_document_end(bab, child);
    OUTPUT:
        RETVAL

bool
array_builder_append_int32(bab, value)
    bson_array_builder_t *bab;
    int32_t value;
    CODE:
        RETVAL = bson_array_builder_append_int32(bab, value);
    OUTPUT:
        RETVAL

bool
array_builder_append_int64(bab, value)
    bson_array_builder_t *bab;
    int64_t value;
    CODE:
        RETVAL = bson_array_builder_append_int64(bab, value);
    OUTPUT:
        RETVAL

bool
array_builder_append_decimal128(bab, value)
    bson_array_builder_t *bab;
    const bson_decimal128_t *value;
    CODE:
        RETVAL = bson_array_builder_append_decimal128(bab, value);
    OUTPUT:
        RETVAL

bool
array_builder_append_iter(bab, iter)
    bson_array_builder_t *bab;
    const bson_iter_t *iter;
    CODE:
        RETVAL = bson_array_builder_append_iter(bab, iter);
    OUTPUT:
        RETVAL

bool
array_builder_append_minkey(bab)
    bson_array_builder_t *bab;
    CODE:
        RETVAL = bson_array_builder_append_minkey(bab);
    OUTPUT:
        RETVAL

bool
array_builder_append_maxkey(bab)
    bson_array_builder_t *bab;
    CODE:
        RETVAL = bson_array_builder_append_maxkey(bab);
    OUTPUT:
        RETVAL

bool
array_builder_append_null(bab)
    bson_array_builder_t *bab;
    CODE:
        RETVAL = bson_array_builder_append_null(bab);
    OUTPUT:
        RETVAL

bool
array_builder_append_oid(bab, oid)
    bson_array_builder_t *bab;
    const bson_oid_t *oid;
    CODE:
        RETVAL = bson_array_builder_append_oid(bab, oid);
    OUTPUT:
        RETVAL

bool
array_builder_append_regex(bab, regex, options)
    bson_array_builder_t *bab;
    const char *regex;
    const char *options;
    CODE:
        RETVAL = bson_array_builder_append_regex(bab, regex, options);
    OUTPUT:
        RETVAL

bool
array_builder_append_regex_w_len(bab, regex, regex_length, options)
    bson_array_builder_t *bab;
    const char *regex;
    int regex_length;
    const char *options;
    CODE:
        RETVAL = bson_array_builder_append_regex_w_len(bab, regex, regex_length, options);
    OUTPUT:
        RETVAL

bool
array_builder_append_utf8(bab, value, length)
    bson_array_builder_t *bab;
    const char *value;
    int length;
    CODE:
        RETVAL = bson_array_builder_append_utf8(bab, value, length);
    OUTPUT:
        RETVAL

bool
array_builder_append_symbol(bab, value, length)
    bson_array_builder_t *bab;
    const char *value;
    int length;
    CODE:
        RETVAL = bson_array_builder_append_symbol(bab, value, length);
    OUTPUT:
        RETVAL

bool
array_builder_append_time_t(bab, value)
    bson_array_builder_t *bab;
    time_t value;
    CODE:
        RETVAL = bson_array_builder_append_time_t(bab, value);
    OUTPUT:
        RETVAL

bool
array_builder_append_timeval(bab, value)
    bson_array_builder_t *bab;
    struct timeval *value;
    CODE:
        RETVAL = bson_array_builder_append_timeval(bab, value);
    OUTPUT:
        RETVAL

bool
array_builder_append_date_time(bab, value)
    bson_array_builder_t *bab;
    int64_t value;
    CODE:
        RETVAL = bson_array_builder_append_date_time(bab, value);
    OUTPUT:
        RETVAL

bool
array_builder_append_now_utc(bab)
    bson_array_builder_t *bab;
    CODE:
        RETVAL = bson_array_builder_append_now_utc(bab);
    OUTPUT:
        RETVAL

bool
array_builder_append_timestamp(bab, timestamp, increment)
    bson_array_builder_t *bab;
    uint32_t timestamp;
    uint32_t increment;
    CODE:
        RETVAL = bson_array_builder_append_timestamp(bab, timestamp, increment);
    OUTPUT:
        RETVAL

bool
array_builder_append_undefined(bab)
    bson_array_builder_t *bab;
    CODE:
        RETVAL = bson_array_builder_append_undefined(bab);
    OUTPUT:
        RETVAL

bool
array_builder_append_array_builder_begin(bab, child)
    bson_array_builder_t *bab;
    bson_array_builder_t **child;
    CODE:
        RETVAL = bson_array_builder_append_array_builder_begin(bab, child);
    OUTPUT:
        RETVAL

bool
array_builder_append_array_builder_end(bab, child)
    bson_array_builder_t *bab;
    bson_array_builder_t **child;
    CODE:
        RETVAL = bson_array_builder_append_array_builder_end(bab, child);
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
    bson_context_t *context;
    CODE:
        bson_context_destroy(context);

bool
decimal128_from_string(string, dec)
    const char *string;
    bson_decimal128_t *dec;
    CODE:
        RETVAL = bson_decimal128_from_string(string, dec);
    OUTPUT:
        RETVAL

bool
decimal128_from_string_w_len(string, len, dec)
    const char *string;
    int len;
    bson_decimal128_t *dec;
    CODE:
        RETVAL = bson_decimal128_from_string_w_len(string, len, dec);
    OUTPUT:
        RETVAL

void
decimal128_to_string(dec, str)
    const bson_decimal128_t *dec;
    char *str;
    CODE:
        bson_decimal128_to_string(dec, str);

void
set_error(error, domain, code, format, ...)
    bson_error_t *error;
    uint32_t domain;
    uint32_t code;
    const char *format;
    CODE:
        bson_set_error(error, domain, code, format);

char *
strerror_r(err_code, buf, buflen)
    int err_code;
    char *buf;
    size_t buflen;
    CODE:
        RETVAL = bson_strerror_r(err_code, buf, buflen);
    OUTPUT:
        RETVAL

void
iter_array(iter, array_len, array)
    const bson_iter_t *iter;
    uint32_t *array_len;
    const uint8_t **array;
    CODE:
        bson_iter_array(iter, array_len, array);

bool
iter_as_bool(iter)
    const bson_iter_t *iter;
    CODE:
        RETVAL = bson_iter_as_bool(iter);
    OUTPUT:
        RETVAL

double
iter_as_double(iter)
    const bson_iter_t *iter;
    CODE:
        RETVAL = bson_iter_as_double(iter);
    OUTPUT:
        RETVAL

int64_t
iter_as_int64(iter)
    const bson_iter_t *iter;
    CODE:
        RETVAL = bson_iter_as_int64(iter);
    OUTPUT:
        RETVAL

void
iter_binary(iter, subtype, binary_len, binary)
    const bson_iter_t *iter;
    bson_subtype_t *subtype;
    uint32_t *binary_len;
    const uint8_t **binary;
    CODE:
        bson_iter_binary(iter, subtype, binary_len, binary);

bool
iter_bool(iter)
    const bson_iter_t *iter;
    CODE:
        RETVAL = bson_iter_bool(iter);
    OUTPUT:
        RETVAL

const char *
iter_code(iter, length)
    const bson_iter_t *iter;
    uint32_t *length;
    CODE:
        RETVAL = bson_iter_code(iter, length);
    OUTPUT:
        RETVAL

const char *
iter_codewscope(iter, length, scope_len, scope)
    const bson_iter_t *iter;
    uint32_t *length;
    uint32_t *scope_len;
    const uint8_t **scope;
    CODE:
        RETVAL = bson_iter_codewscope(iter, length, scope_len, scope);
    OUTPUT:
        RETVAL

int64_t
iter_date_time(iter)
    const bson_iter_t *iter;
    CODE:
        RETVAL = bson_iter_date_time(iter);
    OUTPUT:
        RETVAL

void
iter_dbpointer(iter, collection_len, collection, oid)
    const bson_iter_t *iter;
    uint32_t *collection_len;
    const char **collection;
    const bson_oid_t **oid;
    CODE:
        bson_iter_dbpointer(iter, collection_len, collection, oid);

bool
iter_decimal128(iter, dec)
    const bson_iter_t *iter;
    bson_decimal128_t *dec;
    CODE:
        RETVAL = bson_iter_decimal128(iter, dec);
    OUTPUT:
        RETVAL

void
iter_document(iter, document_len, document)
    const bson_iter_t *iter;
    uint32_t *document_len;
    const uint8_t **document;
    CODE:
        bson_iter_document(iter, document_len, document);

double
iter_double(iter)
    const bson_iter_t *iter;
    CODE:
        RETVAL = bson_iter_double(iter);
    OUTPUT:
        RETVAL

char *
iter_dup_utf8(iter, length)
    const bson_iter_t *iter;
    uint32_t *length;
    CODE:
        RETVAL = bson_iter_dup_utf8(iter, length);
    OUTPUT:
        RETVAL

bool
iter_find(iter, key)
    bson_iter_t *iter;
    const char *key;
    CODE:
        RETVAL = bson_iter_find(iter, key);
    OUTPUT:
        RETVAL

bool
iter_find_case(iter, key)
    bson_iter_t *iter;
    const char *key;
    CODE:
        RETVAL = bson_iter_find_case(iter, key);
    OUTPUT:
        RETVAL

bool
iter_find_descendant(iter, dotkey, descendant)
    bson_iter_t *iter;
    const char *dotkey;
    bson_iter_t *descendant;
    CODE:
        RETVAL = bson_iter_find_descendant(iter, dotkey, descendant);
    OUTPUT:
        RETVAL

bool
iter_find_w_len(iter, key, keylen)
    bson_iter_t *iter;
    const char *key;
    int keylen;
    CODE:
        RETVAL = bson_iter_find_w_len(iter, key, keylen);
    OUTPUT:
        RETVAL

bool
iter_init(iter, bson)
    bson_iter_t *iter;
    const bson_t *bson;
    CODE:
        RETVAL = bson_iter_init(iter, bson);
    OUTPUT:
        RETVAL


bool
iter_init_find(iter, bson, key)
    bson_iter_t *iter;
    const bson_t *bson;
    const char *key;
    CODE:
        RETVAL = bson_iter_init_find(iter, bson, key);
    OUTPUT:
        RETVAL

bool
iter_init_find_case(iter, bson, key)
    bson_iter_t *iter;
    const bson_t *bson;
    const char *key;
    CODE:
        RETVAL = bson_iter_init_find_case(iter, bson, key);
    OUTPUT:
        RETVAL

bool
iter_init_find_w_len(iter, bson, key, keylen)
    bson_iter_t *iter;
    const bson_t *bson;
    const char *key;
    int keylen;
    CODE:
        RETVAL = bson_iter_init_find_w_len(iter, bson, key, keylen);
    OUTPUT:
        RETVAL

bool
iter_init_from_data(iter, data, length)
    bson_iter_t *iter;
    const uint8_t *data;
    size_t length;
    CODE:
        RETVAL = bson_iter_init_from_data(iter, data, length);
    OUTPUT:
        RETVAL

bool
iter_init_from_data_at_offset(iter, data, length, offset, keylen)
    bson_iter_t *iter;
    const uint8_t *data;
    size_t length;
    uint32_t offset;
    uint32_t keylen;
    CODE:
        RETVAL = bson_iter_init_from_data_at_offset(iter, data, length, offset, keylen);
    OUTPUT:
        RETVAL

int32_t
iter_int32(iter)
    const bson_iter_t *iter;
    CODE:
        RETVAL = bson_iter_int32(iter);
    OUTPUT:
        RETVAL

int64_t
iter_int64(iter)
    const bson_iter_t *iter;
    CODE:
        RETVAL = bson_iter_int64(iter);
    OUTPUT:
        RETVAL

const char *
iter_key(iter)
    const bson_iter_t *iter;
    CODE:
        RETVAL = bson_iter_key(iter);
    OUTPUT:
        RETVAL

uint32_t
iter_key_len(iter)
    const bson_iter_t *iter;
    CODE:
        RETVAL = bson_iter_key_len(iter);
    OUTPUT:
        RETVAL

bool
iter_next(iter)
    bson_iter_t *iter;
    CODE:
        RETVAL = bson_iter_next(iter);
    OUTPUT:
        RETVAL

uint32_t
iter_offset(iter)
    const bson_iter_t *iter;
    CODE:
        RETVAL = bson_iter_offset(iter);
    OUTPUT:
        RETVAL

const bson_oid_t *
iter_oid(iter)
    const bson_iter_t *iter;
    CODE:
        RETVAL = bson_iter_oid(iter);
    OUTPUT:
        RETVAL

void
iter_overwrite_bool(iter, value)
    bson_iter_t *iter;
    bool value;
    CODE:
        bson_iter_overwrite_bool(iter, value);

void
iter_overwrite_date_time(iter, value)
    bson_iter_t *iter;
    int64_t value;
    CODE:
        bson_iter_overwrite_date_time(iter, value);

void
iter_overwrite_decimal128(iter, value)
    bson_iter_t *iter;
    const bson_decimal128_t *value;
    CODE:
        bson_iter_overwrite_decimal128(iter, value);

void
iter_overwrite_double(iter, value)
    bson_iter_t *iter;
    double value;
    CODE:
        bson_iter_overwrite_double(iter, value);

void
iter_overwrite_int32(iter, value)
    bson_iter_t *iter;
    int32_t value;
    CODE:
        bson_iter_overwrite_int32(iter, value);

void
iter_overwrite_int64(iter, value)
    bson_iter_t *iter;
    int64_t value;
    CODE:
        bson_iter_overwrite_int64(iter, value);

void
iter_overwrite_oid(iter, value)
    bson_iter_t *iter;
    const bson_oid_t *value;
    CODE:
        bson_iter_overwrite_oid(iter, value);

void
iter_overwrite_timestamp(iter, timestamp, increment)
    bson_iter_t *iter;
    uint32_t timestamp;
    uint32_t increment;
    CODE:
        bson_iter_overwrite_timestamp(iter, timestamp, increment);

bool
iter_recurse(iter, child)
    const bson_iter_t *iter;
    bson_iter_t *child;
    CODE:
        RETVAL = bson_iter_recurse(iter, child);
    OUTPUT:
        RETVAL

const char *
iter_regex(iter, options)
    const bson_iter_t *iter;
    const char **options;
    CODE:
        RETVAL = bson_iter_regex(iter, options);
    OUTPUT:
        RETVAL

const char *
iter_symbol(iter, length)
    const bson_iter_t *iter;
    uint32_t *length;
    CODE:
        RETVAL = bson_iter_symbol(iter, length);
    OUTPUT:
        RETVAL

time_t
iter_time_t(iter)
    const bson_iter_t *iter;
    CODE:
        RETVAL = bson_iter_time_t(iter);
    OUTPUT:
        RETVAL

void
iter_timestamp(iter, timestamp, increment)
    const bson_iter_t *iter;
    uint32_t *timestamp;
    uint32_t *increment;
    CODE:
        bson_iter_timestamp(iter, timestamp, increment);

void
iter_timeval(iter, tv)
    const bson_iter_t *iter;
    struct timeval *tv;
    CODE:
        bson_iter_timeval(iter, tv);

bson_type_t
iter_type(iter)
    const bson_iter_t *iter;
    CODE:
        RETVAL = bson_iter_type(iter);
    OUTPUT:
        RETVAL

const char *
iter_utf8(iter, length)
    const bson_iter_t *iter;
    uint32_t *length;
    CODE:
        RETVAL = bson_iter_utf8(iter, length);
    OUTPUT:
        RETVAL

const bson_value_t *
iter_value(iter)
    bson_iter_t *iter;
    CODE:
        RETVAL = bson_iter_value(iter);
    OUTPUT:
        RETVAL

bool
iter_visit_all(iter, visitor, data)
    bson_iter_t *iter;
    const bson_visitor_t *visitor;
    void *data;
    CODE:
        RETVAL = bson_iter_visit_all(iter, visitor, data);
    OUTPUT:
        RETVAL

void
json_data_reader_ingest(reader, data, len)
    bson_json_reader_t *reader;
    const uint8_t *data;
    size_t len;
    CODE:
        bson_json_data_reader_ingest(reader, data, len);

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
    bson_json_reader_t *reader;
    CODE:
        bson_json_reader_destroy(reader);

bson_json_reader_t *
json_reader_new(data, cb, dcb, allow_multiple, buf_size)
    void *data;
    bson_json_reader_cb cb;
    bson_json_destroy_cb dcb;
    bool allow_multiple;
    size_t buf_size;
    CODE:
        RETVAL = bson_json_reader_new(data, cb, dcb, allow_multiple, buf_size);
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