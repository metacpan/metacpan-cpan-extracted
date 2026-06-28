/*
 * pdfmake_asn1.c — ASN.1 DER encoding/decoding implementation
 *
 * Minimal ASN.1 DER codec for X.509, PKCS#7, PKCS#12 parsing and building.
 */

#include "pdfmake_asn1.h"
#include "pdfmake_arena.h"
#include "pdfmake_buf.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

/*============================================================================
 * Internal helpers
 *==========================================================================*/

/* Parse DER length field */
static int parse_length(const uint8_t *data, size_t len, size_t *pos, size_t *out_len)
{
    uint8_t first;
    size_t num_bytes;
    size_t length;
    size_t i;

    if (*pos >= len) return -1;
    
    first = data[(*pos)++];
    
    if (first < 0x80) {
        /* Short form: length in single byte */
        *out_len = first;
        return 0;
    }
    
    if (first == 0x80) {
        /* Indefinite length - not valid in DER */
        return -1;
    }
    
    /* Long form: first byte indicates number of length bytes */
    num_bytes = first & 0x7F;
    if (num_bytes > sizeof(size_t) || *pos + num_bytes > len) {
        return -1;
    }
    
    length = 0;
    for (i = 0; i < num_bytes; i++) {
        length = (length << 8) | data[(*pos)++];
    }
    
    *out_len = length;
    return 0;
}

/* Encode DER length field */
static pdfmake_err_t write_length(pdfmake_buf_t *buf, size_t length)
{
    size_t temp;
    int num_bytes;
    pdfmake_err_t err;
    int i;

    if (length < 0x80) {
        return pdfmake_buf_append_byte(buf, (uint8_t)length);
    }
    
    /* Count bytes needed */
    temp = length;
    num_bytes = 0;
    while (temp > 0) {
        num_bytes++;
        temp >>= 8;
    }
    
    /* Write length-of-length byte */
    err = pdfmake_buf_append_byte(buf, 0x80 | num_bytes);
    if (err != PDFMAKE_OK) return err;
    
    /* Write length bytes (big-endian) */
    for (i = num_bytes - 1; i >= 0; i--) {
        err = pdfmake_buf_append_byte(buf, (length >> (i * 8)) & 0xFF);
        if (err != PDFMAKE_OK) return err;
    }
    
    return PDFMAKE_OK;
}

/*============================================================================
 * Parsing API
 *==========================================================================*/

pdfmake_asn1_node_t *pdfmake_asn1_parse_element(
    pdfmake_arena_t *arena,
    const uint8_t *data,
    size_t len,
    size_t *pos)
{
    pdfmake_asn1_node_t *node;

    if (*pos >= len) return NULL;
    
    node = pdfmake_arena_alloc(arena, sizeof(pdfmake_asn1_node_t));
    if (!node) return NULL;
    
    memset(node, 0, sizeof(pdfmake_asn1_node_t));
    
    /* Parse tag */
    node->tag = data[(*pos)++];
    
    /* Handle multi-byte tags (tag number >= 31) */
    if ((node->tag & 0x1F) == 0x1F) {
        /* Multi-byte tag - skip additional tag bytes for now */
        while (*pos < len && (data[*pos] & 0x80)) {
            (*pos)++;
        }
        if (*pos < len) (*pos)++;  /* Skip final tag byte */
    }
    
    /* Parse length */
    if (parse_length(data, len, pos, &node->length) != 0) {
        return NULL;
    }
    
    /* Check bounds */
    if (*pos + node->length > len) {
        return NULL;
    }
    
    /* Set data pointer */
    node->data = data + *pos;
    
    /* Parse children for constructed types */
    if (node->tag & ASN1_CONSTRUCTED) {
        size_t content_end = *pos + node->length;
        pdfmake_asn1_node_t *last_child = NULL;
        
        while (*pos < content_end) {
            pdfmake_asn1_node_t *child = pdfmake_asn1_parse_element(arena, data, content_end, pos);
            if (!child) return NULL;
            
            child->parent = node;
            
            if (last_child) {
                last_child->next = child;
            } else {
                node->children = child;
            }
            last_child = child;
        }
    } else {
        /* Primitive type - skip content */
        *pos += node->length;
    }
    
    return node;
}

pdfmake_asn1_node_t *pdfmake_asn1_parse(
    pdfmake_arena_t *arena,
    const uint8_t *data,
    size_t len)
{
    size_t pos = 0;
    return pdfmake_asn1_parse_element(arena, data, len, &pos);
}

size_t pdfmake_asn1_child_count(const pdfmake_asn1_node_t *node)
{
    size_t count = 0;
    pdfmake_asn1_node_t *child;

    if (!node) return 0;
    
    child = node->children;
    while (child) {
        count++;
        child = child->next;
    }
    return count;
}

pdfmake_asn1_node_t *pdfmake_asn1_child_at(
    const pdfmake_asn1_node_t *node,
    size_t index)
{
    pdfmake_asn1_node_t *child;
    size_t i;

    if (!node) return NULL;
    
    child = node->children;
    for (i = 0; i < index && child; i++) {
        child = child->next;
    }
    return child;
}

pdfmake_asn1_node_t *pdfmake_asn1_find_tag(
    const pdfmake_asn1_node_t *node,
    uint8_t tag)
{
    pdfmake_asn1_node_t *child;

    if (!node) return NULL;
    
    child = node->children;
    while (child) {
        if (child->tag == tag) return child;
        child = child->next;
    }
    return NULL;
}

/*============================================================================
 * Value Extraction
 *==========================================================================*/

int pdfmake_asn1_get_int64(const pdfmake_asn1_node_t *node, int64_t *out)
{
    int negative;
    int64_t value;
    size_t i;

    if (!node || !out) return -1;
    if (node->tag != ASN1_TAG_INTEGER && node->tag != ASN1_TAG_ENUMERATED) return -1;
    if (node->length == 0 || node->length > 8) return -1;
    
    /* Check if negative (high bit set) */
    negative = (node->data[0] & 0x80) != 0;
    
    value = negative ? -1 : 0;  /* Sign extend */
    for (i = 0; i < node->length; i++) {
        value = (value << 8) | node->data[i];
    }
    
    *out = value;
    return 0;
}

int pdfmake_asn1_get_uint64(const pdfmake_asn1_node_t *node, uint64_t *out)
{
    const uint8_t *data;
    size_t len;
    uint64_t value;
    size_t i;

    if (!node || !out) return -1;
    if (node->tag != ASN1_TAG_INTEGER) return -1;
    if (node->length == 0) return -1;
    
    /* Skip leading zero byte if present (for positive numbers with high bit set) */
    data = node->data;
    len = node->length;
    
    if (len > 1 && data[0] == 0x00) {
        data++;
        len--;
    }
    
    if (len > 8) return -1;  /* Too large */
    
    value = 0;
    for (i = 0; i < len; i++) {
        value = (value << 8) | data[i];
    }
    
    *out = value;
    return 0;
}

int pdfmake_asn1_get_bool(const pdfmake_asn1_node_t *node, int *out)
{
    if (!node || !out) return -1;
    if (node->tag != ASN1_TAG_BOOLEAN) return -1;
    if (node->length != 1) return -1;
    
    *out = (node->data[0] != 0);
    return 0;
}

char *pdfmake_asn1_get_oid_string(
    pdfmake_arena_t *arena,
    const pdfmake_asn1_node_t *node)
{
    char buf[256];
    char *p;
    char *end;
    int first;
    int second;
    size_t i;
    size_t len;
    char *result;

    if (!node || !arena) return NULL;
    if (node->tag != ASN1_TAG_OID) return NULL;
    if (node->length == 0) return NULL;
    
    /* Build string representation */
    p = buf;
    end = buf + sizeof(buf) - 1;
    
    /* First byte encodes first two components: first * 40 + second */
    first = node->data[0] / 40;
    second = node->data[0] % 40;
    
    /* Special case for first component >= 2 */
    if (first >= 2) {
        first = 2;
        second = node->data[0] - 80;
    }
    
    p += snprintf(p, end - p, "%d.%d", first, second);
    
    /* Remaining components are base-128 encoded */
    i = 1;
    while (i < node->length && p < end) {
        uint32_t value = 0;
        while (i < node->length) {
            uint8_t byte = node->data[i++];
            value = (value << 7) | (byte & 0x7F);
            if (!(byte & 0x80)) break;
        }
        p += snprintf(p, end - p, ".%u", value);
    }
    
    len = p - buf;
    result = pdfmake_arena_alloc(arena, len + 1);
    if (result) {
        memcpy(result, buf, len + 1);
    }
    return result;
}

int pdfmake_asn1_oid_equals(
    const pdfmake_asn1_node_t *node,
    const char *oid_str)
{
    uint8_t encoded[64];
    size_t encoded_len = 0;
    const char *p;
    int first = -1, second = -1;

    if (!node || !oid_str) return 0;
    if (node->tag != ASN1_TAG_OID) return 0;
    
    /* Encode expected OID and compare bytes */
    p = oid_str;
    
    while (*p && encoded_len < sizeof(encoded)) {
        /* Parse next component */
        int value = 0;
        while (*p >= '0' && *p <= '9') {
            value = value * 10 + (*p - '0');
            p++;
        }
        if (*p == '.') p++;
        
        if (first < 0) {
            first = value;
        } else if (second < 0) {
            second = value;
            /* Encode first two components */
            encoded[encoded_len++] = first * 40 + second;
        } else {
            /* Encode as base-128 */
            uint8_t temp[5];
            int temp_len = 0;
            int i;
            do {
                temp[temp_len++] = value & 0x7F;
                value >>= 7;
            } while (value > 0);
            
            for (i = temp_len - 1; i >= 0; i--) {
                encoded[encoded_len++] = temp[i] | (i > 0 ? 0x80 : 0);
            }
        }
    }
    
    if (encoded_len != node->length) return 0;
    return memcmp(encoded, node->data, encoded_len) == 0;
}

char *pdfmake_asn1_get_string(
    pdfmake_arena_t *arena,
    const pdfmake_asn1_node_t *node)
{
    char *result;

    if (!node || !arena) return NULL;
    
    /* Accept various string types */
    switch (node->tag) {
        case ASN1_TAG_UTF8STRING:
        case ASN1_TAG_PRINTABLESTRING:
        case ASN1_TAG_IA5STRING:
        case ASN1_TAG_T61STRING:
        case ASN1_TAG_VISIBLESTRING:
        case ASN1_TAG_NUMERICSTRING:
        case ASN1_TAG_BMPSTRING:
        case ASN1_TAG_UNIVERSALSTRING:
            break;
        default:
            return NULL;
    }
    
    /* For BMPString, convert from UCS-2 to UTF-8 */
    if (node->tag == ASN1_TAG_BMPSTRING) {
        /* Simple conversion assuming ASCII subset */
        size_t out_len = node->length / 2;
        size_t i;
        result = pdfmake_arena_alloc(arena, out_len + 1);
        if (result) {
            for (i = 0; i < out_len; i++) {
                uint16_t ch = (node->data[i*2] << 8) | node->data[i*2 + 1];
                result[i] = (ch < 128) ? ch : '?';
            }
            result[out_len] = '\0';
        }
        return result;
    }
    
    /* Copy as-is for other string types */
    result = pdfmake_arena_alloc(arena, node->length + 1);
    if (result) {
        memcpy(result, node->data, node->length);
        result[node->length] = '\0';
    }
    return result;
}

int pdfmake_asn1_get_time(const pdfmake_asn1_node_t *node, int64_t *out)
{
    struct tm tm;
    const char *s;
    size_t len;

    if (!node || !out) return -1;
    if (node->tag != ASN1_TAG_UTCTIME && node->tag != ASN1_TAG_GENERALIZEDTIME) {
        return -1;
    }
    
    memset(&tm, 0, sizeof(tm));
    s = (const char *)node->data;
    len = node->length;
    
    if (node->tag == ASN1_TAG_UTCTIME) {
        /* YYMMDDhhmmssZ or YYMMDDhhmmss+hhmm */
        if (len < 12) return -1;
        
        tm.tm_year = (s[0] - '0') * 10 + (s[1] - '0');
        if (tm.tm_year < 50) tm.tm_year += 100;  /* 2000-2049 */
        tm.tm_mon = (s[2] - '0') * 10 + (s[3] - '0') - 1;
        tm.tm_mday = (s[4] - '0') * 10 + (s[5] - '0');
        tm.tm_hour = (s[6] - '0') * 10 + (s[7] - '0');
        tm.tm_min = (s[8] - '0') * 10 + (s[9] - '0');
        tm.tm_sec = (s[10] - '0') * 10 + (s[11] - '0');
    } else {
        /* GeneralizedTime: YYYYMMDDhhmmssZ */
        if (len < 14) return -1;
        
        tm.tm_year = (s[0] - '0') * 1000 + (s[1] - '0') * 100 +
                     (s[2] - '0') * 10 + (s[3] - '0') - 1900;
        tm.tm_mon = (s[4] - '0') * 10 + (s[5] - '0') - 1;
        tm.tm_mday = (s[6] - '0') * 10 + (s[7] - '0');
        tm.tm_hour = (s[8] - '0') * 10 + (s[9] - '0');
        tm.tm_min = (s[10] - '0') * 10 + (s[11] - '0');
        tm.tm_sec = (s[12] - '0') * 10 + (s[13] - '0');
    }
    
    /* Convert to Unix timestamp (assume UTC) */
    tm.tm_isdst = 0;
    
#ifdef _WIN32
    *out = _mkgmtime(&tm);
#else
    *out = timegm(&tm);
#endif
    
    return 0;
}

int pdfmake_asn1_get_bit_string(
    const pdfmake_asn1_node_t *node,
    const uint8_t **bits,
    size_t *bit_count)
{
    uint8_t unused;

    if (!node || !bits || !bit_count) return -1;
    if (node->tag != ASN1_TAG_BIT_STRING) return -1;
    if (node->length < 1) return -1;
    
    /* First byte is number of unused bits in last byte */
    unused = node->data[0];
    if (unused > 7) return -1;
    
    *bits = node->data + 1;
    *bit_count = (node->length - 1) * 8 - unused;
    
    return 0;
}

/*============================================================================
 * Encoding API
 *==========================================================================*/

pdfmake_err_t pdfmake_asn1_encoder_init(
    pdfmake_asn1_encoder_t *enc,
    pdfmake_arena_t *arena,
    pdfmake_buf_t *buf)
{
    if (!enc || !arena || !buf) return PDFMAKE_EINVAL;
    
    enc->arena = arena;
    enc->buf = buf;
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_asn1_write_header(
    pdfmake_asn1_encoder_t *enc,
    uint8_t tag,
    size_t length)
{
    pdfmake_err_t err = pdfmake_buf_append_byte(enc->buf, tag);
    if (err != PDFMAKE_OK) return err;
    return write_length(enc->buf, length);
}

pdfmake_err_t pdfmake_asn1_write_null(pdfmake_asn1_encoder_t *enc)
{
    pdfmake_err_t err = pdfmake_buf_append_byte(enc->buf, ASN1_TAG_NULL);
    if (err != PDFMAKE_OK) return err;
    return pdfmake_buf_append_byte(enc->buf, 0x00);
}

pdfmake_err_t pdfmake_asn1_write_bool(pdfmake_asn1_encoder_t *enc, int value)
{
    pdfmake_err_t err = pdfmake_buf_append_byte(enc->buf, ASN1_TAG_BOOLEAN);
    if (err != PDFMAKE_OK) return err;
    err = pdfmake_buf_append_byte(enc->buf, 0x01);
    if (err != PDFMAKE_OK) return err;
    return pdfmake_buf_append_byte(enc->buf, value ? 0xFF : 0x00);
}

pdfmake_err_t pdfmake_asn1_write_int64(pdfmake_asn1_encoder_t *enc, int64_t value)
{
    uint8_t bytes[9];
    int len = 0;
    pdfmake_err_t err;
    
    if (value == 0) {
        bytes[0] = 0;
        len = 1;
    } else if (value > 0) {
        /* Positive: encode as minimal big-endian, add leading 0 if high bit set */
        uint64_t v = value;
        while (v > 0) {
            bytes[8 - len++] = v & 0xFF;
            v >>= 8;
        }
        memmove(bytes, bytes + 9 - len, len);
        
        if (bytes[0] & 0x80) {
            memmove(bytes + 1, bytes, len);
            bytes[0] = 0;
            len++;
        }
    } else {
        /* Negative: encode as two's complement */
        uint64_t v = (uint64_t)value;
        int all_ff = 1;
        int i;
        for (i = 0; i < 8; i++) {
            uint8_t b = (v >> (56 - i * 8)) & 0xFF;
            if (all_ff && b == 0xFF && i < 7) {
                uint8_t next = (v >> (48 - i * 8)) & 0xFF;
                if (next & 0x80) continue;  /* Can skip this 0xFF */
            }
            all_ff = 0;
            bytes[len++] = b;
        }
    }
    
    err = pdfmake_buf_append_byte(enc->buf, ASN1_TAG_INTEGER);
    if (err != PDFMAKE_OK) return err;
    err = write_length(enc->buf, len);
    if (err != PDFMAKE_OK) return err;
    return pdfmake_buf_append(enc->buf, bytes, len);
}

pdfmake_err_t pdfmake_asn1_write_uint64(pdfmake_asn1_encoder_t *enc, uint64_t value)
{
    uint8_t bytes[9];
    int len = 0;
    pdfmake_err_t err;
    
    if (value == 0) {
        bytes[0] = 0;
        len = 1;
    } else {
        /* Encode as minimal big-endian */
        uint64_t v = value;
        while (v > 0) {
            bytes[8 - len++] = v & 0xFF;
            v >>= 8;
        }
        memmove(bytes, bytes + 9 - len, len);
        
        /* Add leading 0 if high bit set (to indicate positive) */
        if (bytes[0] & 0x80) {
            memmove(bytes + 1, bytes, len);
            bytes[0] = 0;
            len++;
        }
    }
    
    err = pdfmake_buf_append_byte(enc->buf, ASN1_TAG_INTEGER);
    if (err != PDFMAKE_OK) return err;
    err = write_length(enc->buf, len);
    if (err != PDFMAKE_OK) return err;
    return pdfmake_buf_append(enc->buf, bytes, len);
}

pdfmake_err_t pdfmake_asn1_write_integer(
    pdfmake_asn1_encoder_t *enc,
    const uint8_t *bytes,
    size_t len)
{
    int need_zero;
    pdfmake_err_t err;

    if (!enc || !bytes) return PDFMAKE_EINVAL;
    
    /* Skip leading zeros but keep at least one byte */
    while (len > 1 && bytes[0] == 0 && !(bytes[1] & 0x80)) {
        bytes++;
        len--;
    }
    
    /* Add leading zero if high bit set (to indicate positive) */
    need_zero = (bytes[0] & 0x80) != 0;
    
    err = pdfmake_buf_append_byte(enc->buf, ASN1_TAG_INTEGER);
    if (err != PDFMAKE_OK) return err;
    err = write_length(enc->buf, len + (need_zero ? 1 : 0));
    if (err != PDFMAKE_OK) return err;
    
    if (need_zero) {
        err = pdfmake_buf_append_byte(enc->buf, 0x00);
        if (err != PDFMAKE_OK) return err;
    }
    
    return pdfmake_buf_append(enc->buf, bytes, len);
}

pdfmake_err_t pdfmake_asn1_write_oid(
    pdfmake_asn1_encoder_t *enc,
    const char *oid_str)
{
    uint8_t encoded[64];
    size_t encoded_len = 0;
    const char *p;
    int first = -1, second = -1;
    pdfmake_err_t err;

    if (!enc || !oid_str) return PDFMAKE_EINVAL;
    
    p = oid_str;
    
    while (*p && encoded_len < sizeof(encoded)) {
        int value = 0;
        while (*p >= '0' && *p <= '9') {
            value = value * 10 + (*p - '0');
            p++;
        }
        if (*p == '.') p++;
        
        if (first < 0) {
            first = value;
        } else if (second < 0) {
            second = value;
            encoded[encoded_len++] = first * 40 + second;
        } else {
            /* Encode as base-128 */
            uint8_t temp[5];
            int temp_len = 0;
            int i;
            do {
                temp[temp_len++] = value & 0x7F;
                value >>= 7;
            } while (value > 0);
            
            for (i = temp_len - 1; i >= 0; i--) {
                if (encoded_len >= sizeof(encoded)) return PDFMAKE_EINVAL;
                encoded[encoded_len++] = temp[i] | (i > 0 ? 0x80 : 0);
            }
        }
    }
    
    err = pdfmake_buf_append_byte(enc->buf, ASN1_TAG_OID);
    if (err != PDFMAKE_OK) return err;
    err = write_length(enc->buf, encoded_len);
    if (err != PDFMAKE_OK) return err;
    return pdfmake_buf_append(enc->buf, encoded, encoded_len);
}

pdfmake_err_t pdfmake_asn1_write_octet_string(
    pdfmake_asn1_encoder_t *enc,
    const uint8_t *data,
    size_t len)
{
    pdfmake_err_t err = pdfmake_buf_append_byte(enc->buf, ASN1_TAG_OCTET_STRING);
    if (err != PDFMAKE_OK) return err;
    err = write_length(enc->buf, len);
    if (err != PDFMAKE_OK) return err;
    return pdfmake_buf_append(enc->buf, data, len);
}

pdfmake_err_t pdfmake_asn1_write_bit_string(
    pdfmake_asn1_encoder_t *enc,
    const uint8_t *bits,
    size_t bit_count)
{
    size_t byte_count = (bit_count + 7) / 8;
    uint8_t unused = (byte_count * 8 - bit_count) % 8;
    
    pdfmake_err_t err = pdfmake_buf_append_byte(enc->buf, ASN1_TAG_BIT_STRING);
    if (err != PDFMAKE_OK) return err;
    err = write_length(enc->buf, byte_count + 1);
    if (err != PDFMAKE_OK) return err;
    err = pdfmake_buf_append_byte(enc->buf, unused);
    if (err != PDFMAKE_OK) return err;
    return pdfmake_buf_append(enc->buf, bits, byte_count);
}

pdfmake_err_t pdfmake_asn1_write_utf8_string(
    pdfmake_asn1_encoder_t *enc,
    const char *str)
{
    size_t len = strlen(str);
    pdfmake_err_t err = pdfmake_buf_append_byte(enc->buf, ASN1_TAG_UTF8STRING);
    if (err != PDFMAKE_OK) return err;
    err = write_length(enc->buf, len);
    if (err != PDFMAKE_OK) return err;
    return pdfmake_buf_append(enc->buf, (const uint8_t *)str, len);
}

pdfmake_err_t pdfmake_asn1_write_printable_string(
    pdfmake_asn1_encoder_t *enc,
    const char *str)
{
    size_t len = strlen(str);
    pdfmake_err_t err = pdfmake_buf_append_byte(enc->buf, ASN1_TAG_PRINTABLESTRING);
    if (err != PDFMAKE_OK) return err;
    err = write_length(enc->buf, len);
    if (err != PDFMAKE_OK) return err;
    return pdfmake_buf_append(enc->buf, (const uint8_t *)str, len);
}

pdfmake_err_t pdfmake_asn1_write_ia5_string(
    pdfmake_asn1_encoder_t *enc,
    const char *str)
{
    size_t len = strlen(str);
    pdfmake_err_t err = pdfmake_buf_append_byte(enc->buf, ASN1_TAG_IA5STRING);
    if (err != PDFMAKE_OK) return err;
    err = write_length(enc->buf, len);
    if (err != PDFMAKE_OK) return err;
    return pdfmake_buf_append(enc->buf, (const uint8_t *)str, len);
}

pdfmake_err_t pdfmake_asn1_write_utc_time(
    pdfmake_asn1_encoder_t *enc,
    int64_t timestamp)
{
    time_t t = (time_t)timestamp;
    struct tm *tm = gmtime(&t);
    char buf[16];
    int year;
    pdfmake_err_t err;

    if (!tm) return PDFMAKE_EINVAL;
    
    year = tm->tm_year % 100;  /* Two-digit year */
    snprintf(buf, sizeof(buf), "%02d%02d%02d%02d%02d%02dZ",
             year, tm->tm_mon + 1, tm->tm_mday,
             tm->tm_hour, tm->tm_min, tm->tm_sec);
    
    err = pdfmake_buf_append_byte(enc->buf, ASN1_TAG_UTCTIME);
    if (err != PDFMAKE_OK) return err;
    err = write_length(enc->buf, 13);
    if (err != PDFMAKE_OK) return err;
    return pdfmake_buf_append(enc->buf, (const uint8_t *)buf, 13);
}

pdfmake_err_t pdfmake_asn1_write_generalized_time(
    pdfmake_asn1_encoder_t *enc,
    int64_t timestamp)
{
    time_t t = (time_t)timestamp;
    struct tm *tm = gmtime(&t);
    char buf[20];
    pdfmake_err_t err;

    if (!tm) return PDFMAKE_EINVAL;
    
    snprintf(buf, sizeof(buf), "%04d%02d%02d%02d%02d%02dZ",
             tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday,
             tm->tm_hour, tm->tm_min, tm->tm_sec);
    
    err = pdfmake_buf_append_byte(enc->buf, ASN1_TAG_GENERALIZEDTIME);
    if (err != PDFMAKE_OK) return err;
    err = write_length(enc->buf, 15);
    if (err != PDFMAKE_OK) return err;
    return pdfmake_buf_append(enc->buf, (const uint8_t *)buf, 15);
}

size_t pdfmake_asn1_begin_sequence(pdfmake_asn1_encoder_t *enc)
{
    size_t pos = enc->buf->len;
    pdfmake_buf_append_byte(enc->buf, ASN1_TAG_SEQUENCE | ASN1_CONSTRUCTED);
    /* Reserve 4 bytes for length (will be fixed up later) */
    pdfmake_buf_append_byte(enc->buf, 0x84);
    pdfmake_buf_append_byte(enc->buf, 0x00);
    pdfmake_buf_append_byte(enc->buf, 0x00);
    pdfmake_buf_append_byte(enc->buf, 0x00);
    pdfmake_buf_append_byte(enc->buf, 0x00);
    return pos;
}

size_t pdfmake_asn1_begin_set(pdfmake_asn1_encoder_t *enc)
{
    size_t pos = enc->buf->len;
    pdfmake_buf_append_byte(enc->buf, ASN1_TAG_SET | ASN1_CONSTRUCTED);
    /* Reserve 4 bytes for length */
    pdfmake_buf_append_byte(enc->buf, 0x84);
    pdfmake_buf_append_byte(enc->buf, 0x00);
    pdfmake_buf_append_byte(enc->buf, 0x00);
    pdfmake_buf_append_byte(enc->buf, 0x00);
    pdfmake_buf_append_byte(enc->buf, 0x00);
    return pos;
}

size_t pdfmake_asn1_begin_context(
    pdfmake_asn1_encoder_t *enc,
    uint8_t tag_number,
    int constructed)
{
    size_t pos = enc->buf->len;
    uint8_t tag = ASN1_CLASS_CONTEXT | tag_number;
    if (constructed) tag |= ASN1_CONSTRUCTED;
    pdfmake_buf_append_byte(enc->buf, tag);
    /* Reserve 4 bytes for length */
    pdfmake_buf_append_byte(enc->buf, 0x84);
    pdfmake_buf_append_byte(enc->buf, 0x00);
    pdfmake_buf_append_byte(enc->buf, 0x00);
    pdfmake_buf_append_byte(enc->buf, 0x00);
    pdfmake_buf_append_byte(enc->buf, 0x00);
    return pos;
}

pdfmake_err_t pdfmake_asn1_end_constructed(
    pdfmake_asn1_encoder_t *enc,
    size_t start_pos)
{
    /* The begin_* helpers reserved 5 bytes for the length prefix
     * (0x84 + 4 length bytes).  For strict DER (required by CMS
     * verifiers) the prefix must use the shortest form:
     *   length < 128   → 1 byte
     *   length <= 0xFF → 2 bytes (0x81 + 1)
     *   length <= 0xFFFF → 3 bytes (0x82 + 2)
     *   length <= 0xFFFFFF → 4 bytes (0x83 + 3)
     *   otherwise      → 5 bytes (0x84 + 4)
     * After computing the content length we rewrite the header and, if
     * the new header is shorter, shift content left to close the gap. */

    size_t content_start = start_pos + 6;  /* tag + 5 reserved length bytes */
    size_t content_len = enc->buf->len - content_start;

    /* Determine minimum length encoding. */
    int header_len_bytes;   /* bytes following the tag (len-of-len + len) */
    int reserved = 5;
    int shift;
    uint8_t *base;
    uint8_t *len_start;

    if (content_len < 0x80)               header_len_bytes = 1;
    else if (content_len <= 0xFF)         header_len_bytes = 2;
    else if (content_len <= 0xFFFF)       header_len_bytes = 3;
    else if (content_len <= 0xFFFFFF)     header_len_bytes = 4;
    else                                   header_len_bytes = 5;

    shift = reserved - header_len_bytes;

    base = enc->buf->data + start_pos;
    len_start = base + 1;

    /* If the minimum encoding is shorter, slide the content bytes left
     * by `shift` bytes and decrement the buffer length. */
    if (shift > 0 && content_len > 0) {
        memmove(base + 1 + header_len_bytes,
                base + 1 + reserved,
                content_len);
        enc->buf->len -= (size_t)shift;
    } else if (shift > 0) {
        enc->buf->len -= (size_t)shift;
    }

    /* Write the new length header. */
    if (header_len_bytes == 1) {
        len_start[0] = (uint8_t)content_len;
    } else {
        int i;
        len_start[0] = (uint8_t)(0x80 | (header_len_bytes - 1));
        for (i = 1; i < header_len_bytes; i++) {
            int shift_bits = (header_len_bytes - 1 - i) * 8;
            len_start[i] = (uint8_t)((content_len >> shift_bits) & 0xFF);
        }
    }

    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_asn1_write_raw(
    pdfmake_asn1_encoder_t *enc,
    const uint8_t *data,
    size_t len)
{
    return pdfmake_buf_append(enc->buf, data, len);
}
