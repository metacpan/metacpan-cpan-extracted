/*
 * libpdfmake — object serializer implementation.
 *
 * Emits PDF objects per §7.3. Locale-independent number formatting.
 */

#include "pdfmake_writer.h"
#include "pdfmake_filter.h"
#include "pdfmake_crypt.h"
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <float.h>

/*----------------------------------------------------------------------------
 * Escape tables
 *--------------------------------------------------------------------------*/

/* Name escape table: 1 = must escape as #XX.
 * Per §7.3.5: escape NUL, whitespace, delimiters (()<>[]{}/%#), and
 * any byte outside 0x21-0x7E (printable non-space ASCII). */
static const uint8_t name_escape_table[256] = {
    /* 0x00-0x0F: control chars - escape all */
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    /* 0x10-0x1F: control chars - escape all */
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    /* 0x20: space - escape */
    1,
    /* 0x21-0x22: !" - safe */
    0,0,
    /* 0x23: # - escape (escape char) */
    1,
    /* 0x24: $ - safe */
    0,
    /* 0x25: % - escape (comment) */
    1,
    /* 0x26-0x27: &' - safe */
    0,0,
    /* 0x28-0x29: () - escape (delimiters) */
    1,1,
    /* 0x2A-0x2E: *+,-. - safe */
    0,0,0,0,0,
    /* 0x2F: / - escape (name prefix) */
    1,
    /* 0x30-0x39: 0-9 - safe */
    0,0,0,0,0,0,0,0,0,0,
    /* 0x3A-0x3B: :; - safe */
    0,0,
    /* 0x3C-0x3E: <>= - escape < and > (delimiters), = is safe */
    1,0,1,
    /* 0x3F-0x5A: ?@A-Z - safe */
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    /* 0x5B: [ - escape (delimiter) */
    1,
    /* 0x5C: \ - safe in names (only special in strings) */
    0,
    /* 0x5D: ] - escape (delimiter) */
    1,
    /* 0x5E-0x60: ^_` - safe */
    0,0,0,
    /* 0x61-0x7A: a-z - safe */
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    /* 0x7B: { - escape (delimiter) */
    1,
    /* 0x7C: | - safe */
    0,
    /* 0x7D: } - escape (delimiter) */
    1,
    /* 0x7E: ~ - safe */
    0,
    /* 0x7F: DEL - escape */
    1,
    /* 0x80-0xFF: high bytes - escape all */
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
};

/* Hex digits for encoding. */
static const char hex_upper[16] = "0123456789ABCDEF";

/*----------------------------------------------------------------------------
 * Number formatting (locale-independent)
 *--------------------------------------------------------------------------*/

int pdfmake_format_int(char *buf, int64_t value) {
    char tmp[24];
    int pos = 0;
    int neg = 0;
    uint64_t v;
    int len;

    if (value < 0) {
        neg = 1;
        v = (uint64_t)(-(value + 1)) + 1;  /* Handle INT64_MIN safely */
    } else {
        v = (uint64_t)value;
    }

    /* Generate digits in reverse order. */
    do {
        tmp[pos++] = '0' + (v % 10);
        v /= 10;
    } while (v > 0);

    len = 0;
    if (neg) buf[len++] = '-';

    /* Reverse the digits. */
    while (pos > 0) {
        buf[len++] = tmp[--pos];
    }
    buf[len] = '\0';
    return len;
}

int pdfmake_format_real(char *buf, double value) {
    int len;
    double int_part;
    double frac_part;
    char tmp[24];
    int ipos;
    uint64_t iv;
    int frac_digits;
    double scaled;
    char frac_buf[16];
    int i;
    int digit;
    int j;

    /* Handle special cases. */
    if (isnan(value)) {
        memcpy(buf, "0", 2);
        return 1;
    }
    if (isinf(value)) {
        if (value > 0) {
            memcpy(buf, "999999999", 10);
            return 9;
        } else {
            memcpy(buf, "-999999999", 11);
            return 10;
        }
    }

    /* If it's an integer, format as integer (no decimal point). */
    if (value == floor(value) && value >= -9007199254740992.0 && value <= 9007199254740992.0) {
        return pdfmake_format_int(buf, (int64_t)value);
    }

    /* Handle negative numbers. */
    len = 0;
    if (value < 0) {
        buf[len++] = '-';
        value = -value;
    }

    /* Format with sufficient precision for round-trip.
     * PDF allows a lot of flexibility, but we aim for minimal representation.
     * We try progressively more digits until round-trip succeeds. */

    /* Split into integer and fractional parts. */
    frac_part = modf(value, &int_part);

    /* Write integer part. */
    if (int_part == 0) {
        buf[len++] = '0';
    } else {
        ipos = 0;
        iv = (uint64_t)int_part;
        do {
            tmp[ipos++] = '0' + (iv % 10);
            iv /= 10;
        } while (iv > 0);
        while (ipos > 0) {
            buf[len++] = tmp[--ipos];
        }
    }

    /* Write fractional part with minimal digits for round-trip. */
    if (frac_part > 0) {
        buf[len++] = '.';

        /* Generate up to 15 fractional digits. */
        frac_digits = 0;
        scaled = frac_part;

        for (i = 0; i < 15; i++) {
            scaled *= 10.0;
            digit = (int)scaled;
            if (digit > 9) digit = 9;  /* Clamp rounding errors */
            frac_buf[frac_digits++] = '0' + digit;
            scaled -= digit;

            /* Check if we've captured enough precision. */
            if (scaled < 1e-14) break;
        }

        /* Trim trailing zeros. */
        while (frac_digits > 1 && frac_buf[frac_digits - 1] == '0') {
            frac_digits--;
        }

        /* Copy fractional digits. */
        for (j = 0; j < frac_digits; j++) {
            buf[len++] = frac_buf[j];
        }
    }

    buf[len] = '\0';
    return len;
}

/*----------------------------------------------------------------------------
 * Per-kind writers
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_write_null(pdfmake_buf_t *buf) {
    return pdfmake_buf_append(buf, "null", 4);
}

pdfmake_err_t pdfmake_write_bool(pdfmake_buf_t *buf, int value) {
    if (value) {
        return pdfmake_buf_append(buf, "true", 4);
    } else {
        return pdfmake_buf_append(buf, "false", 5);
    }
}

pdfmake_err_t pdfmake_write_int(pdfmake_buf_t *buf, int64_t value) {
    char tmp[24];
    int len = pdfmake_format_int(tmp, value);
    return pdfmake_buf_append(buf, tmp, (size_t)len);
}

pdfmake_err_t pdfmake_write_real(pdfmake_buf_t *buf, double value) {
    char tmp[32];
    int len = pdfmake_format_real(tmp, value);
    return pdfmake_buf_append(buf, tmp, (size_t)len);
}

pdfmake_err_t pdfmake_write_name(pdfmake_buf_t *buf, const char *bytes, size_t len) {
    pdfmake_err_t err;
    size_t i;
    uint8_t c;

    /* Names start with /. */
    err = pdfmake_buf_append_byte(buf, '/');
    if (err != PDFMAKE_OK) return err;

    /* Emit each byte, escaping as needed. */
    for (i = 0; i < len; i++) {
        c = (uint8_t)bytes[i];
        if (name_escape_table[c]) {
            char esc[3];
            esc[0] = '#';
            esc[1] = hex_upper[c >> 4];
            esc[2] = hex_upper[c & 0x0F];
            err = pdfmake_buf_append(buf, esc, 3);
        } else {
            err = pdfmake_buf_append_byte(buf, c);
        }
        if (err != PDFMAKE_OK) return err;
    }

    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_write_name_id(pdfmake_buf_t *buf, pdfmake_arena_t *arena,
                                    uint32_t name_id) {
    const char *bytes = pdfmake_arena_name_bytes(arena, name_id);
    size_t len = pdfmake_arena_name_len(arena, name_id);
    if (!bytes) return PDFMAKE_EINVAL;
    return pdfmake_write_name(buf, bytes, len);
}

pdfmake_err_t pdfmake_write_string(pdfmake_buf_t *buf, const uint8_t *bytes, size_t len) {
    pdfmake_err_t err;
    size_t i;
    uint8_t c;

    err = pdfmake_buf_append_byte(buf, '(');
    if (err != PDFMAKE_OK) return err;

    for (i = 0; i < len; i++) {
        c = bytes[i];
        switch (c) {
            case '\n':
                err = pdfmake_buf_append(buf, "\\n", 2);
                break;
            case '\r':
                err = pdfmake_buf_append(buf, "\\r", 2);
                break;
            case '\t':
                err = pdfmake_buf_append(buf, "\\t", 2);
                break;
            case '\b':
                err = pdfmake_buf_append(buf, "\\b", 2);
                break;
            case '\f':
                err = pdfmake_buf_append(buf, "\\f", 2);
                break;
            case '(':
                err = pdfmake_buf_append(buf, "\\(", 2);
                break;
            case ')':
                err = pdfmake_buf_append(buf, "\\)", 2);
                break;
            case '\\':
                err = pdfmake_buf_append(buf, "\\\\", 2);
                break;
            default:
                /* Emit as-is (including high bytes). PDF strings are 8-bit clean. */
                err = pdfmake_buf_append_byte(buf, c);
                break;
        }
        if (err != PDFMAKE_OK) return err;
    }

    return pdfmake_buf_append_byte(buf, ')');
}

pdfmake_err_t pdfmake_write_hexstring(pdfmake_buf_t *buf, const uint8_t *bytes, size_t len) {
    pdfmake_err_t err;
    size_t i;
    uint8_t c;
    char hex[2];

    err = pdfmake_buf_append_byte(buf, '<');
    if (err != PDFMAKE_OK) return err;

    for (i = 0; i < len; i++) {
        c = bytes[i];
        hex[0] = hex_upper[c >> 4];
        hex[1] = hex_upper[c & 0x0F];
        err = pdfmake_buf_append(buf, hex, 2);
        if (err != PDFMAKE_OK) return err;
    }

    return pdfmake_buf_append_byte(buf, '>');
}

pdfmake_err_t pdfmake_write_array(pdfmake_buf_t *buf, pdfmake_arena_t *arena,
                                  const pdfmake_array_t *arr) {
    pdfmake_err_t err;
    uint32_t i;

    if (!arr) return PDFMAKE_EINVAL;

    err = pdfmake_buf_append_byte(buf, '[');
    if (err != PDFMAKE_OK) return err;

    for (i = 0; i < arr->len; i++) {
        if (i > 0) {
            err = pdfmake_buf_append_byte(buf, ' ');
            if (err != PDFMAKE_OK) return err;
        }
        err = pdfmake_write_obj(buf, arena, &arr->items[i]);
        if (err != PDFMAKE_OK) return err;
    }

    return pdfmake_buf_append_byte(buf, ']');
}

pdfmake_err_t pdfmake_write_dict(pdfmake_buf_t *buf, pdfmake_arena_t *arena,
                                 const pdfmake_dict_t *dict) {
    pdfmake_err_t err;
    uint32_t order;
    uint32_t i;
    pdfmake_dict_entry_t *e;

    if (!dict) return PDFMAKE_EINVAL;

    err = pdfmake_buf_append(buf, "<<", 2);
    if (err != PDFMAKE_OK) return err;

    /* Iterate in insertion order. This is O(n²) but maintains PDF convention. */
    for (order = 0; order < dict->next_order; order++) {
        /* Find entry with this order. */
        for (i = 0; i < dict->cap; i++) {
            e = &dict->entries[i];
            if (e->key != 0 && !e->deleted && e->order == order) {
                /* Write key. */
                err = pdfmake_write_name_id(buf, arena, e->key);
                if (err != PDFMAKE_OK) return err;

                /* Space between key and value. */
                err = pdfmake_buf_append_byte(buf, ' ');
                if (err != PDFMAKE_OK) return err;

                /* Write value. */
                err = pdfmake_write_obj(buf, arena, &e->value);
                if (err != PDFMAKE_OK) return err;

                break;
            }
        }
    }

    return pdfmake_buf_append(buf, ">>", 2);
}

pdfmake_err_t pdfmake_write_ref(pdfmake_buf_t *buf, uint32_t num, uint16_t gen) {
    char tmp[32];
    int len = pdfmake_format_int(tmp, num);
    tmp[len++] = ' ';
    len += pdfmake_format_int(tmp + len, gen);
    tmp[len++] = ' ';
    tmp[len++] = 'R';
    return pdfmake_buf_append(buf, tmp, (size_t)len);
}

pdfmake_err_t pdfmake_write_stream(pdfmake_buf_t *buf, pdfmake_arena_t *arena,
                                   const pdfmake_stream_t *stream) {
    pdfmake_err_t err;
    uint32_t filter_key;
    pdfmake_obj_t dict_obj;
    pdfmake_obj_t *filter_val;
    const uint8_t *output_data;
    size_t output_len;
    pdfmake_buf_t compressed = {0};
    int needs_free = 0;
    const char *filter_name;
    uint32_t length_key;
    pdfmake_obj_t length_obj;

    if (!stream || !stream->dict) return PDFMAKE_EINVAL;

    /* Check if /Filter is set for compression */
    filter_key = pdfmake_arena_intern_name(arena, "Filter", 6);
    dict_obj.kind = PDFMAKE_DICT;
    dict_obj.as.dict = stream->dict;
    filter_val = filter_key ? pdfmake_dict_get(&dict_obj, filter_key) : NULL;

    output_data = stream->raw;
    output_len = stream->raw_len;

    /* Apply compression if /Filter is set and stream is not already filtered */
    if (filter_val && filter_val->kind == PDFMAKE_NAME && !stream->filtered) {
        filter_name = pdfmake_arena_name_bytes(arena, filter_val->as.name.id);

        if (filter_name && strcmp(filter_name, "FlateDecode") == 0 && stream->raw && stream->raw_len > 0) {
            /* Compress with FlateDecode */
            if (pdfmake_buf_init(&compressed) == PDFMAKE_OK) {
                err = pdfmake_flate_encode(stream->raw, stream->raw_len, NULL, &compressed);
                if (err == PDFMAKE_OK) {
                    output_data = compressed.data;
                    output_len = compressed.len;
                    needs_free = 1;
                }
            }
        }
    }

    /* Set /Length in dictionary */
    length_key = pdfmake_arena_intern_name(arena, "Length", 6);
    if (length_key) {
        length_obj = pdfmake_int((int64_t)output_len);
        pdfmake_dict_set(arena, &dict_obj, length_key, length_obj);
    }

    /* Write the dictionary */
    err = pdfmake_write_dict(buf, arena, stream->dict);
    if (err != PDFMAKE_OK) {
        if (needs_free) pdfmake_buf_free(&compressed);
        return err;
    }

    /* Stream framing */
    err = pdfmake_buf_append(buf, "\nstream\n", 8);
    if (err != PDFMAKE_OK) {
        if (needs_free) pdfmake_buf_free(&compressed);
        return err;
    }

    /* Stream data */
    if (output_data && output_len > 0) {
        err = pdfmake_buf_append(buf, output_data, output_len);
        if (err != PDFMAKE_OK) {
            if (needs_free) pdfmake_buf_free(&compressed);
            return err;
        }
    }

    if (needs_free) pdfmake_buf_free(&compressed);

    return pdfmake_buf_append(buf, "\nendstream", 10);
}

/*----------------------------------------------------------------------------
 * Object dispatcher
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_write_obj(pdfmake_buf_t *buf, pdfmake_arena_t *arena,
                                const pdfmake_obj_t *obj) {
    if (!buf || !obj) return PDFMAKE_EINVAL;

    switch (obj->kind) {
        case PDFMAKE_NULL:
            return pdfmake_write_null(buf);

        case PDFMAKE_BOOL:
            return pdfmake_write_bool(buf, (int)obj->as.i);

        case PDFMAKE_INT:
            return pdfmake_write_int(buf, obj->as.i);

        case PDFMAKE_REAL:
            return pdfmake_write_real(buf, obj->as.r);

        case PDFMAKE_NAME:
            return pdfmake_write_name_id(buf, arena, obj->as.name.id);

        case PDFMAKE_STR:
            if (obj->as.str.hex) {
                return pdfmake_write_hexstring(buf, obj->as.str.bytes, obj->as.str.len);
            } else {
                return pdfmake_write_string(buf, obj->as.str.bytes, obj->as.str.len);
            }

        case PDFMAKE_ARRAY:
            return pdfmake_write_array(buf, arena, obj->as.arr);

        case PDFMAKE_DICT:
            return pdfmake_write_dict(buf, arena, obj->as.dict);

        case PDFMAKE_STREAM:
            return pdfmake_write_stream(buf, arena, obj->as.stream);

        case PDFMAKE_REF:
            return pdfmake_write_ref(buf, obj->as.ref.num, obj->as.ref.gen);

        default:
            return PDFMAKE_EINVAL;
    }
}

/*----------------------------------------------------------------------------
 * Encrypted emission path — mirrors the non-encrypted helpers above but
 * threads a crypt ctx + obj_num through recursion so every string/stream
 * encountered inside an indirect object can be encrypted with the correct
 * per-object key.  The `skip_encrypt` flag is raised for objects that the
 * PDF spec says must remain plaintext (the /Encrypt dict itself and its
 * string children).
 *--------------------------------------------------------------------------*/

static pdfmake_err_t write_obj_enc(pdfmake_buf_t *buf, pdfmake_arena_t *arena,
                                   const pdfmake_crypt_ctx_t *crypt,
                                   uint32_t obj_num, int skip_encrypt,
                                   const pdfmake_obj_t *obj);

static pdfmake_err_t write_literal_string_bytes(pdfmake_buf_t *buf,
                                                 const uint8_t *bytes,
                                                 size_t len) {
    pdfmake_err_t err = pdfmake_buf_append_byte(buf, '(');
    size_t i;
    uint8_t c;
    if (err != PDFMAKE_OK) return err;
    for (i = 0; i < len; i++) {
        c = bytes[i];
        switch (c) {
            case '\n': err = pdfmake_buf_append(buf, "\\n", 2); break;
            case '\r': err = pdfmake_buf_append(buf, "\\r", 2); break;
            case '\t': err = pdfmake_buf_append(buf, "\\t", 2); break;
            case '\b': err = pdfmake_buf_append(buf, "\\b", 2); break;
            case '\f': err = pdfmake_buf_append(buf, "\\f", 2); break;
            case '(':  err = pdfmake_buf_append(buf, "\\(", 2); break;
            case ')':  err = pdfmake_buf_append(buf, "\\)", 2); break;
            case '\\': err = pdfmake_buf_append(buf, "\\\\", 2); break;
            default:   err = pdfmake_buf_append_byte(buf, c); break;
        }
        if (err != PDFMAKE_OK) return err;
    }
    return pdfmake_buf_append_byte(buf, ')');
}

static pdfmake_err_t write_string_enc(pdfmake_buf_t *buf,
                                      const pdfmake_crypt_ctx_t *crypt,
                                      uint32_t obj_num, int skip_encrypt,
                                      const pdfmake_string_t *s) {
    const uint8_t *bytes = s->bytes;
    size_t len = s->len;
    uint8_t *enc = NULL;
    size_t enc_len = 0;
    size_t cap;
    int n;
    pdfmake_err_t err;

    if (crypt && !skip_encrypt) {
        cap = (crypt->R >= 4) ? (len + 32 + 16) : (len + 1);
        enc = (uint8_t *)malloc(cap);
        if (!enc) return PDFMAKE_ENOMEM;
        n = pdfmake_crypt_encrypt_string(crypt, (int)obj_num, 0,
                                         bytes, len, enc);
        if (n < 0) { free(enc); return PDFMAKE_EINVAL; }
        bytes = enc;
        enc_len = (size_t)n;
        len = enc_len;
    }

    if (s->hex) {
        err = pdfmake_write_hexstring(buf, bytes, len);
    } else {
        err = write_literal_string_bytes(buf, bytes, len);
    }
    free(enc);
    return err;
}

static pdfmake_err_t write_array_enc(pdfmake_buf_t *buf, pdfmake_arena_t *arena,
                                     const pdfmake_crypt_ctx_t *crypt,
                                     uint32_t obj_num, int skip_encrypt,
                                     const pdfmake_array_t *arr) {
    pdfmake_err_t err;
    uint32_t i;
    if (!arr) return PDFMAKE_EINVAL;
    err = pdfmake_buf_append_byte(buf, '[');
    if (err != PDFMAKE_OK) return err;
    for (i = 0; i < arr->len; i++) {
        if (i > 0) {
            err = pdfmake_buf_append_byte(buf, ' ');
            if (err != PDFMAKE_OK) return err;
        }
        err = write_obj_enc(buf, arena, crypt, obj_num, skip_encrypt,
                             &arr->items[i]);
        if (err != PDFMAKE_OK) return err;
    }
    return pdfmake_buf_append_byte(buf, ']');
}

static pdfmake_err_t write_dict_enc(pdfmake_buf_t *buf, pdfmake_arena_t *arena,
                                    const pdfmake_crypt_ctx_t *crypt,
                                    uint32_t obj_num, int skip_encrypt,
                                    const pdfmake_dict_t *dict) {
    pdfmake_err_t err;
    uint32_t order;
    uint32_t i;
    pdfmake_dict_entry_t *e;
    if (!dict) return PDFMAKE_EINVAL;
    err = pdfmake_buf_append(buf, "<<", 2);
    if (err != PDFMAKE_OK) return err;

    for (order = 0; order < dict->next_order; order++) {
        for (i = 0; i < dict->cap; i++) {
            e = &dict->entries[i];
            if (e->key != 0 && !e->deleted && e->order == order) {
                err = pdfmake_write_name_id(buf, arena, e->key);
                if (err != PDFMAKE_OK) return err;
                err = pdfmake_buf_append_byte(buf, ' ');
                if (err != PDFMAKE_OK) return err;
                err = write_obj_enc(buf, arena, crypt, obj_num, skip_encrypt,
                                     &e->value);
                if (err != PDFMAKE_OK) return err;
                break;
            }
        }
    }
    return pdfmake_buf_append(buf, ">>", 2);
}

static pdfmake_err_t write_stream_enc(pdfmake_buf_t *buf,
                                       pdfmake_arena_t *arena,
                                       const pdfmake_crypt_ctx_t *crypt,
                                       uint32_t obj_num, int skip_encrypt,
                                       const pdfmake_stream_t *stream) {
    pdfmake_err_t err;
    uint32_t filter_key;
    pdfmake_obj_t dict_obj;
    pdfmake_obj_t *filter_val;
    const uint8_t *output_data;
    size_t output_len;
    pdfmake_buf_t compressed;
    int needs_free;
    uint8_t *enc;
    size_t enc_len;
    uint32_t length_key;
    pdfmake_obj_t len_obj;

    if (!stream || !stream->dict) return PDFMAKE_EINVAL;

    /* Stage 1: apply /Filter compression if requested (mirrors
     * pdfmake_write_stream's logic). */
    filter_key = pdfmake_arena_intern_name(arena, "Filter", 6);
    dict_obj.kind = PDFMAKE_DICT;
    dict_obj.as.dict = stream->dict;
    filter_val = filter_key
        ? pdfmake_dict_get(&dict_obj, filter_key) : NULL;

    output_data = stream->raw;
    output_len = stream->raw_len;
    memset(&compressed, 0, sizeof(compressed));
    needs_free = 0;

    if (filter_val && filter_val->kind == PDFMAKE_NAME && !stream->filtered) {
        const char *filter_name =
            pdfmake_arena_name_bytes(arena, filter_val->as.name.id);
        if (filter_name && strcmp(filter_name, "FlateDecode") == 0 &&
            stream->raw && stream->raw_len > 0) {
            if (pdfmake_buf_init(&compressed) == PDFMAKE_OK) {
                err = pdfmake_flate_encode(stream->raw, stream->raw_len,
                                           NULL, &compressed);
                if (err == PDFMAKE_OK) {
                    output_data = compressed.data;
                    output_len = compressed.len;
                    needs_free = 1;
                }
            }
        }
    }

    /* Stage 2: apply stream encryption if a crypt ctx is active. */
    enc = NULL;
    enc_len = 0;
    if (crypt && !skip_encrypt && output_data && output_len > 0) {
        if (pdfmake_crypt_encrypt_stream(crypt, (int)obj_num, 0,
                                         output_data, output_len,
                                         &enc, &enc_len) != 0) {
            if (needs_free) pdfmake_buf_free(&compressed);
            return PDFMAKE_EINVAL;
        }
        output_data = enc;
        output_len = enc_len;
    }

    /* /Length must reflect the final on-wire size */
    length_key = pdfmake_arena_intern_name(arena, "Length", 6);
    if (length_key) {
        len_obj = pdfmake_int((int64_t)output_len);
        pdfmake_dict_set(arena, &dict_obj, length_key, len_obj);
    }

    /* Emit dict with strings encrypted too (if applicable) */
    err = write_dict_enc(buf, arena, crypt, obj_num, skip_encrypt, stream->dict);
    if (err != PDFMAKE_OK) goto cleanup;

    err = pdfmake_buf_append(buf, "\nstream\n", 8);
    if (err != PDFMAKE_OK) goto cleanup;

    if (output_data && output_len > 0) {
        err = pdfmake_buf_append(buf, output_data, output_len);
        if (err != PDFMAKE_OK) goto cleanup;
    }

    err = pdfmake_buf_append(buf, "\nendstream", 10);

cleanup:
    if (needs_free) pdfmake_buf_free(&compressed);
    free(enc);
    return err;
}

static pdfmake_err_t write_obj_enc(pdfmake_buf_t *buf, pdfmake_arena_t *arena,
                                   const pdfmake_crypt_ctx_t *crypt,
                                   uint32_t obj_num, int skip_encrypt,
                                   const pdfmake_obj_t *obj) {
    if (!buf || !obj) return PDFMAKE_EINVAL;
    switch (obj->kind) {
        case PDFMAKE_NULL:   return pdfmake_write_null(buf);
        case PDFMAKE_BOOL:   return pdfmake_write_bool(buf, (int)obj->as.i);
        case PDFMAKE_INT:    return pdfmake_write_int(buf, obj->as.i);
        case PDFMAKE_REAL:   return pdfmake_write_real(buf, obj->as.r);
        case PDFMAKE_NAME:   return pdfmake_write_name_id(buf, arena,
                                                          obj->as.name.id);
        case PDFMAKE_STR:    return write_string_enc(buf, crypt, obj_num,
                                                     skip_encrypt, &obj->as.str);
        case PDFMAKE_ARRAY:  return write_array_enc(buf, arena, crypt, obj_num,
                                                    skip_encrypt, obj->as.arr);
        case PDFMAKE_DICT:   return write_dict_enc(buf, arena, crypt, obj_num,
                                                   skip_encrypt, obj->as.dict);
        case PDFMAKE_STREAM: return write_stream_enc(buf, arena, crypt, obj_num,
                                                     skip_encrypt, obj->as.stream);
        case PDFMAKE_REF:    return pdfmake_write_ref(buf, obj->as.ref.num,
                                                      obj->as.ref.gen);
    }
    return PDFMAKE_EINVAL;
}

pdfmake_err_t pdfmake_write_obj_encrypted(pdfmake_buf_t *buf,
                                          pdfmake_arena_t *arena,
                                          const pdfmake_crypt_ctx_t *crypt,
                                          uint32_t obj_num,
                                          int skip_encrypt,
                                          const pdfmake_obj_t *obj) {
    return write_obj_enc(buf, arena, crypt, obj_num, skip_encrypt, obj);
}
