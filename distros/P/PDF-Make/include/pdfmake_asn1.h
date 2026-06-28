/*
 * pdfmake_asn1.h — ASN.1 DER encoding/decoding
 *
 * Minimal ASN.1 DER codec for X.509, PKCS#7, PKCS#12 parsing and building.
 * ISO 32000-2:2020 §12.8 (Digital Signatures)
 */

#ifndef PDFMAKE_ASN1_H
#define PDFMAKE_ASN1_H

#include "pdfmake.h"
#include "pdfmake_buf.h"
#include <stdint.h>
#include <stddef.h>

/*============================================================================
 * ASN.1 Tag Classes and Types
 *==========================================================================*/

/* Tag class (bits 7-6) */
#define ASN1_CLASS_UNIVERSAL    0x00
#define ASN1_CLASS_APPLICATION  0x40
#define ASN1_CLASS_CONTEXT      0x80
#define ASN1_CLASS_PRIVATE      0xC0
#define ASN1_CLASS_MASK         0xC0

/* Constructed flag (bit 5) */
#define ASN1_CONSTRUCTED        0x20

/* Universal tags */
#define ASN1_TAG_EOC            0x00
#define ASN1_TAG_BOOLEAN        0x01
#define ASN1_TAG_INTEGER        0x02
#define ASN1_TAG_BIT_STRING     0x03
#define ASN1_TAG_OCTET_STRING   0x04
#define ASN1_TAG_NULL           0x05
#define ASN1_TAG_OID            0x06
#define ASN1_TAG_OBJECT_DESC    0x07
#define ASN1_TAG_EXTERNAL       0x08
#define ASN1_TAG_REAL           0x09
#define ASN1_TAG_ENUMERATED     0x0A
#define ASN1_TAG_EMBEDDED_PDV   0x0B
#define ASN1_TAG_UTF8STRING     0x0C
#define ASN1_TAG_RELATIVE_OID   0x0D
#define ASN1_TAG_SEQUENCE       0x10
#define ASN1_TAG_SET            0x11
#define ASN1_TAG_NUMERICSTRING  0x12
#define ASN1_TAG_PRINTABLESTRING 0x13
#define ASN1_TAG_T61STRING      0x14
#define ASN1_TAG_VIDEOTEXSTRING 0x15
#define ASN1_TAG_IA5STRING      0x16
#define ASN1_TAG_UTCTIME        0x17
#define ASN1_TAG_GENERALIZEDTIME 0x18
#define ASN1_TAG_GRAPHICSTRING  0x19
#define ASN1_TAG_VISIBLESTRING  0x1A
#define ASN1_TAG_GENERALSTRING  0x1B
#define ASN1_TAG_UNIVERSALSTRING 0x1C
#define ASN1_TAG_BMPSTRING      0x1E

/*============================================================================
 * ASN.1 Node Structure
 *==========================================================================*/

typedef struct pdfmake_asn1_node pdfmake_asn1_node_t;

struct pdfmake_asn1_node {
    uint8_t             tag;        /* Full tag byte (class + constructed + number) */
    size_t              length;     /* Content length */
    const uint8_t      *data;       /* Pointer to content (within original buffer) */
    
    /* For constructed types */
    pdfmake_asn1_node_t *children;  /* Linked list of children */
    pdfmake_asn1_node_t *next;      /* Next sibling */
    
    /* Parent reference (for navigation) */
    pdfmake_asn1_node_t *parent;
};

/*============================================================================
 * Tag predicates (inline)
 *==========================================================================*/

/* True iff `node` is a constructed SEQUENCE (0x30). Safe on NULL. */
static PDFMAKE_INLINE int pdfmake_asn1_is_sequence(const pdfmake_asn1_node_t *node) {
    return node && node->tag == (ASN1_TAG_SEQUENCE | ASN1_CONSTRUCTED);
}

/* True iff `node` is a constructed SET (0x31). Safe on NULL. */
static PDFMAKE_INLINE int pdfmake_asn1_is_set(const pdfmake_asn1_node_t *node) {
    return node && node->tag == (ASN1_TAG_SET | ASN1_CONSTRUCTED);
}

/*============================================================================
 * Parsing API
 *==========================================================================*/

/*
 * Parse DER-encoded data into an ASN.1 tree.
 * Returns root node allocated from arena, or NULL on error.
 */
pdfmake_asn1_node_t *pdfmake_asn1_parse(
    pdfmake_arena_t *arena,
    const uint8_t *data,
    size_t len
);

/*
 * Parse a single ASN.1 element (tag + length + content).
 * Updates *pos to point past the element.
 * Returns node or NULL on error.
 */
pdfmake_asn1_node_t *pdfmake_asn1_parse_element(
    pdfmake_arena_t *arena,
    const uint8_t *data,
    size_t len,
    size_t *pos
);

/*
 * Get number of children for a constructed node.
 */
size_t pdfmake_asn1_child_count(const pdfmake_asn1_node_t *node);

/*
 * Get child at index (0-based).
 */
pdfmake_asn1_node_t *pdfmake_asn1_child_at(
    const pdfmake_asn1_node_t *node,
    size_t index
);

/*
 * Find child by tag.
 */
pdfmake_asn1_node_t *pdfmake_asn1_find_tag(
    const pdfmake_asn1_node_t *node,
    uint8_t tag
);

/*============================================================================
 * Value Extraction
 *==========================================================================*/

/*
 * Extract integer value (for small integers that fit in int64_t).
 * Returns 0 on success, -1 on error.
 */
int pdfmake_asn1_get_int64(const pdfmake_asn1_node_t *node, int64_t *out);

/*
 * Extract unsigned integer value.
 */
int pdfmake_asn1_get_uint64(const pdfmake_asn1_node_t *node, uint64_t *out);

/*
 * Extract boolean value.
 */
int pdfmake_asn1_get_bool(const pdfmake_asn1_node_t *node, int *out);

/*
 * Extract OID as dot-separated string (e.g., "1.2.840.113549.1.7.2").
 * Caller must free returned string.
 */
char *pdfmake_asn1_get_oid_string(
    pdfmake_arena_t *arena,
    const pdfmake_asn1_node_t *node
);

/*
 * Compare OID with expected value.
 */
int pdfmake_asn1_oid_equals(
    const pdfmake_asn1_node_t *node,
    const char *oid_str
);

/*
 * Extract string (works for various string types).
 * Returns arena-allocated null-terminated string.
 */
char *pdfmake_asn1_get_string(
    pdfmake_arena_t *arena,
    const pdfmake_asn1_node_t *node
);

/*
 * Extract UTCTime or GeneralizedTime as Unix timestamp.
 */
int pdfmake_asn1_get_time(const pdfmake_asn1_node_t *node, int64_t *out);

/*
 * Extract bit string (returns pointer to bits and bit count).
 */
int pdfmake_asn1_get_bit_string(
    const pdfmake_asn1_node_t *node,
    const uint8_t **bits,
    size_t *bit_count
);

/*============================================================================
 * Encoding API
 *==========================================================================*/

/*
 * ASN.1 DER encoder context.
 */
typedef struct pdfmake_asn1_encoder pdfmake_asn1_encoder_t;

struct pdfmake_asn1_encoder {
    pdfmake_buf_t *buf;
    pdfmake_arena_t *arena;
};

/*
 * Initialize encoder.
 */
pdfmake_err_t pdfmake_asn1_encoder_init(
    pdfmake_asn1_encoder_t *enc,
    pdfmake_arena_t *arena,
    pdfmake_buf_t *buf
);

/*
 * Write tag and length header.
 */
pdfmake_err_t pdfmake_asn1_write_header(
    pdfmake_asn1_encoder_t *enc,
    uint8_t tag,
    size_t length
);

/*
 * Write complete TLV for various types.
 */
pdfmake_err_t pdfmake_asn1_write_null(pdfmake_asn1_encoder_t *enc);
pdfmake_err_t pdfmake_asn1_write_bool(pdfmake_asn1_encoder_t *enc, int value);
pdfmake_err_t pdfmake_asn1_write_int64(pdfmake_asn1_encoder_t *enc, int64_t value);
pdfmake_err_t pdfmake_asn1_write_uint64(pdfmake_asn1_encoder_t *enc, uint64_t value);

/*
 * Write integer from big-endian byte array.
 */
pdfmake_err_t pdfmake_asn1_write_integer(
    pdfmake_asn1_encoder_t *enc,
    const uint8_t *bytes,
    size_t len
);

/*
 * Write OID from dot-separated string.
 */
pdfmake_err_t pdfmake_asn1_write_oid(
    pdfmake_asn1_encoder_t *enc,
    const char *oid_str
);

/*
 * Write octet string.
 */
pdfmake_err_t pdfmake_asn1_write_octet_string(
    pdfmake_asn1_encoder_t *enc,
    const uint8_t *data,
    size_t len
);

/*
 * Write bit string.
 */
pdfmake_err_t pdfmake_asn1_write_bit_string(
    pdfmake_asn1_encoder_t *enc,
    const uint8_t *bits,
    size_t bit_count
);

/*
 * Write UTF-8 string.
 */
pdfmake_err_t pdfmake_asn1_write_utf8_string(
    pdfmake_asn1_encoder_t *enc,
    const char *str
);

/*
 * Write printable string.
 */
pdfmake_err_t pdfmake_asn1_write_printable_string(
    pdfmake_asn1_encoder_t *enc,
    const char *str
);

/*
 * Write IA5 string.
 */
pdfmake_err_t pdfmake_asn1_write_ia5_string(
    pdfmake_asn1_encoder_t *enc,
    const char *str
);

/*
 * Write UTCTime.
 */
pdfmake_err_t pdfmake_asn1_write_utc_time(
    pdfmake_asn1_encoder_t *enc,
    int64_t timestamp
);

/*
 * Write GeneralizedTime.
 */
pdfmake_err_t pdfmake_asn1_write_generalized_time(
    pdfmake_asn1_encoder_t *enc,
    int64_t timestamp
);

/*
 * Begin a SEQUENCE or SET (returns position for length fixup).
 */
size_t pdfmake_asn1_begin_sequence(pdfmake_asn1_encoder_t *enc);
size_t pdfmake_asn1_begin_set(pdfmake_asn1_encoder_t *enc);

/*
 * Begin context-tagged element.
 */
size_t pdfmake_asn1_begin_context(
    pdfmake_asn1_encoder_t *enc,
    uint8_t tag_number,
    int constructed
);

/*
 * End constructed element and fix up length.
 */
pdfmake_err_t pdfmake_asn1_end_constructed(
    pdfmake_asn1_encoder_t *enc,
    size_t start_pos
);

/*
 * Write raw bytes (for embedding pre-encoded content).
 */
pdfmake_err_t pdfmake_asn1_write_raw(
    pdfmake_asn1_encoder_t *enc,
    const uint8_t *data,
    size_t len
);

/*============================================================================
 * Common OIDs
 *==========================================================================*/

/* PKCS#7 / CMS */
#define OID_PKCS7_DATA              "1.2.840.113549.1.7.1"
#define OID_PKCS7_SIGNED_DATA       "1.2.840.113549.1.7.2"
#define OID_PKCS7_ENVELOPED_DATA    "1.2.840.113549.1.7.3"
#define OID_PKCS7_DIGESTED_DATA     "1.2.840.113549.1.7.5"
#define OID_PKCS7_ENCRYPTED_DATA    "1.2.840.113549.1.7.6"

/* Hash algorithms */
#define OID_SHA1                    "1.3.14.3.2.26"
#define OID_SHA256                  "2.16.840.1.101.3.4.2.1"
#define OID_SHA384                  "2.16.840.1.101.3.4.2.2"
#define OID_SHA512                  "2.16.840.1.101.3.4.2.3"

/* Signature algorithms */
#define OID_RSA_ENCRYPTION          "1.2.840.113549.1.1.1"
#define OID_SHA1_WITH_RSA           "1.2.840.113549.1.1.5"
#define OID_SHA256_WITH_RSA         "1.2.840.113549.1.1.11"
#define OID_SHA384_WITH_RSA         "1.2.840.113549.1.1.12"
#define OID_SHA512_WITH_RSA         "1.2.840.113549.1.1.13"
#define OID_RSA_PSS                 "1.2.840.113549.1.1.10"

/* ECDSA */
#define OID_EC_PUBLIC_KEY           "1.2.840.10045.2.1"
#define OID_ECDSA_WITH_SHA256       "1.2.840.10045.4.3.2"
#define OID_ECDSA_WITH_SHA384       "1.2.840.10045.4.3.3"
#define OID_ECDSA_WITH_SHA512       "1.2.840.10045.4.3.4"

/* Named curves */
#define OID_PRIME256V1              "1.2.840.10045.3.1.7"
#define OID_SECP384R1               "1.3.132.0.34"
#define OID_SECP521R1               "1.3.132.0.35"

/* X.509 attribute types */
#define OID_COMMON_NAME             "2.5.4.3"
#define OID_COUNTRY                 "2.5.4.6"
#define OID_LOCALITY                "2.5.4.7"
#define OID_STATE                   "2.5.4.8"
#define OID_ORGANIZATION            "2.5.4.10"
#define OID_ORG_UNIT                "2.5.4.11"
#define OID_EMAIL                   "1.2.840.113549.1.9.1"

/* X.509 extensions */
#define OID_BASIC_CONSTRAINTS       "2.5.29.19"
#define OID_KEY_USAGE               "2.5.29.15"
#define OID_EXT_KEY_USAGE           "2.5.29.37"
#define OID_SUBJECT_KEY_ID          "2.5.29.14"
#define OID_AUTHORITY_KEY_ID        "2.5.29.35"
#define OID_SUBJECT_ALT_NAME        "2.5.29.17"

/* PKCS#9 attributes */
#define OID_CONTENT_TYPE            "1.2.840.113549.1.9.3"
#define OID_MESSAGE_DIGEST          "1.2.840.113549.1.9.4"
#define OID_SIGNING_TIME            "1.2.840.113549.1.9.5"

/* PKCS#12 */
#define OID_PKCS12_KEY_BAG          "1.2.840.113549.1.12.10.1.1"
#define OID_PKCS12_PKCS8_KEY_BAG    "1.2.840.113549.1.12.10.1.2"
#define OID_PKCS12_CERT_BAG         "1.2.840.113549.1.12.10.1.3"
#define OID_PKCS12_CRL_BAG          "1.2.840.113549.1.12.10.1.4"
#define OID_PKCS12_SECRET_BAG       "1.2.840.113549.1.12.10.1.5"
#define OID_PKCS12_SAFE_CONTENTS    "1.2.840.113549.1.12.10.1.6"

/* PBE algorithms */
#define OID_PBE_SHA1_3DES           "1.2.840.113549.1.12.1.3"
#define OID_PBE_SHA1_RC2_40         "1.2.840.113549.1.12.1.6"
#define OID_PBES2                   "1.2.840.113549.1.5.13"
#define OID_PBKDF2                  "1.2.840.113549.1.5.12"

#endif /* PDFMAKE_ASN1_H */
