/*
 * pdfmake_x509.h — X.509 certificate parsing
 *
 * Parse DER/PEM encoded X.509 certificates for PDF digital signatures.
 */

#ifndef PDFMAKE_X509_H
#define PDFMAKE_X509_H

#include "pdfmake_types.h"
#include "pdfmake_arena.h"
#include "pdfmake_asn1.h"

#ifdef __cplusplus
extern "C" {
#endif

/*============================================================================
 * Certificate Structures
 *==========================================================================*/

/* X.509 Name (subject/issuer) */
typedef struct pdfmake_x509_name_s {
    char *common_name;           /* CN */
    char *organization;          /* O */
    char *organizational_unit;   /* OU */
    char *country;               /* C */
    char *state;                 /* ST */
    char *locality;              /* L */
    char *email;                 /* emailAddress */
    char *serial_number;         /* serialNumber */
    
    /* Full distinguished name string */
    char *dn;
} pdfmake_x509_name_t;

/* Key usage flags (per RFC 5280) */
typedef enum {
    PDFMAKE_KU_DIGITAL_SIGNATURE  = 0x0001,
    PDFMAKE_KU_NON_REPUDIATION    = 0x0002,
    PDFMAKE_KU_KEY_ENCIPHERMENT   = 0x0004,
    PDFMAKE_KU_DATA_ENCIPHERMENT  = 0x0008,
    PDFMAKE_KU_KEY_AGREEMENT      = 0x0010,
    PDFMAKE_KU_KEY_CERT_SIGN      = 0x0020,
    PDFMAKE_KU_CRL_SIGN           = 0x0040,
    PDFMAKE_KU_ENCIPHER_ONLY      = 0x0080,
    PDFMAKE_KU_DECIPHER_ONLY      = 0x0100
} pdfmake_key_usage_t;

/* Extended key usage OIDs */
typedef enum {
    PDFMAKE_EKU_SERVER_AUTH       = 0x0001,
    PDFMAKE_EKU_CLIENT_AUTH       = 0x0002,
    PDFMAKE_EKU_CODE_SIGNING      = 0x0004,
    PDFMAKE_EKU_EMAIL_PROTECTION  = 0x0008,
    PDFMAKE_EKU_TIME_STAMPING     = 0x0010,
    PDFMAKE_EKU_OCSP_SIGNING      = 0x0020,
    PDFMAKE_EKU_PDF_SIGNING       = 0x0040,  /* Adobe-specific */
    PDFMAKE_EKU_DOCUMENT_SIGNING  = 0x0080   /* MS document signing */
} pdfmake_ext_key_usage_t;

/* Public key algorithm */
typedef enum {
    PDFMAKE_PK_UNKNOWN = 0,
    PDFMAKE_PK_RSA,
    PDFMAKE_PK_DSA,
    PDFMAKE_PK_ECDSA,
    PDFMAKE_PK_ED25519,
    PDFMAKE_PK_ED448
} pdfmake_pk_algorithm_t;

/* Signature algorithm */
typedef enum {
    PDFMAKE_SIG_UNKNOWN = 0,
    PDFMAKE_SIG_RSA_MD5,
    PDFMAKE_SIG_RSA_SHA1,
    PDFMAKE_SIG_RSA_SHA256,
    PDFMAKE_SIG_RSA_SHA384,
    PDFMAKE_SIG_RSA_SHA512,
    PDFMAKE_SIG_ECDSA_SHA256,
    PDFMAKE_SIG_ECDSA_SHA384,
    PDFMAKE_SIG_ECDSA_SHA512,
    PDFMAKE_SIG_ED25519,
    PDFMAKE_SIG_ED448
} pdfmake_sig_algorithm_t;

/* RSA public key */
typedef struct pdfmake_rsa_pubkey_s {
    uint8_t *modulus;        /* n */
    size_t modulus_len;
    uint8_t *exponent;       /* e */
    size_t exponent_len;
} pdfmake_rsa_pubkey_t;

/* ECDSA public key */
typedef struct pdfmake_ecdsa_pubkey_s {
    const char *curve_oid;   /* Named curve OID */
    int curve_bits;          /* 256, 384, 521 */
    uint8_t *point;          /* Uncompressed EC point */
    size_t point_len;
} pdfmake_ecdsa_pubkey_t;

/* Generic public key */
typedef struct pdfmake_pubkey_s {
    pdfmake_pk_algorithm_t algorithm;
    union {
        pdfmake_rsa_pubkey_t rsa;
        pdfmake_ecdsa_pubkey_t ecdsa;
    };
    
    /* Raw public key info (for signature verification) */
    const uint8_t *raw;
    size_t raw_len;
} pdfmake_pubkey_t;

/* X.509 Certificate */
typedef struct pdfmake_x509_cert_s {
    /* Version (0 = v1, 1 = v2, 2 = v3) */
    int version;
    
    /* Serial number (as big-endian bytes) */
    uint8_t *serial;
    size_t serial_len;
    char *serial_hex;        /* Hex string representation */
    
    /* Signature algorithm */
    pdfmake_sig_algorithm_t sig_algorithm;
    const char *sig_algorithm_oid;
    
    /* Issuer and subject */
    pdfmake_x509_name_t issuer;
    pdfmake_x509_name_t subject;
    
    /* Validity period (Unix timestamps) */
    int64_t not_before;
    int64_t not_after;
    
    /* Public key */
    pdfmake_pubkey_t pubkey;
    
    /* Extensions (v3) */
    int is_ca;                       /* Basic Constraints: CA */
    int path_len_constraint;         /* Basic Constraints: pathLenConstraint (-1 = none) */
    uint32_t key_usage;              /* Key Usage flags */
    uint32_t ext_key_usage;          /* Extended Key Usage flags */
    
    /* Subject Key Identifier */
    uint8_t *subject_key_id;
    size_t subject_key_id_len;
    
    /* Authority Key Identifier */
    uint8_t *authority_key_id;
    size_t authority_key_id_len;
    
    /* CRL Distribution Points (first URL only) */
    char *crl_distribution;
    
    /* OCSP responder URL */
    char *ocsp_responder;
    
    /* Self-signed flag */
    int is_self_signed;
    
    /* Raw DER data (for signature verification) */
    const uint8_t *der;
    size_t der_len;
    
    /* TBS Certificate (for signature verification) */
    const uint8_t *tbs_certificate;
    size_t tbs_certificate_len;
    
    /* Signature value */
    const uint8_t *signature;
    size_t signature_len;
    
    /* Chain linkage */
    struct pdfmake_x509_cert_s *next;   /* Next cert in chain */
    struct pdfmake_x509_cert_s *issuer_cert;  /* Issuing certificate */
    
    /* Arena for memory management */
    pdfmake_arena_t *arena;
} pdfmake_x509_cert_t;

/*============================================================================
 * Certificate Chain
 *==========================================================================*/

typedef struct pdfmake_cert_chain_s {
    pdfmake_x509_cert_t *certs;      /* Linked list of certificates */
    size_t count;
    pdfmake_arena_t *arena;
} pdfmake_cert_chain_t;

/*============================================================================
 * Parsing API
 *==========================================================================*/

/**
 * Parse a DER-encoded X.509 certificate.
 *
 * @param arena   Memory arena for allocations
 * @param der     DER-encoded certificate data
 * @param len     Length of DER data
 * @return        Parsed certificate, or NULL on error
 */
pdfmake_x509_cert_t *pdfmake_x509_parse_der(
    pdfmake_arena_t *arena,
    const uint8_t *der,
    size_t len);

/**
 * Parse a PEM-encoded certificate.
 * Handles -----BEGIN CERTIFICATE----- format.
 *
 * @param arena   Memory arena for allocations
 * @param pem     PEM-encoded certificate data
 * @param len     Length of PEM data
 * @return        Parsed certificate, or NULL on error
 */
pdfmake_x509_cert_t *pdfmake_x509_parse_pem(
    pdfmake_arena_t *arena,
    const char *pem,
    size_t len);

/**
 * Parse multiple PEM-encoded certificates (certificate chain).
 *
 * @param arena   Memory arena for allocations
 * @param pem     PEM data containing one or more certificates
 * @param len     Length of PEM data
 * @return        Certificate chain, or NULL on error
 */
pdfmake_cert_chain_t *pdfmake_x509_parse_pem_chain(
    pdfmake_arena_t *arena,
    const char *pem,
    size_t len);

/**
 * Load certificate from file (auto-detects DER/PEM).
 *
 * @param arena    Memory arena for allocations
 * @param path     Path to certificate file
 * @return         Parsed certificate, or NULL on error
 */
pdfmake_x509_cert_t *pdfmake_x509_load_file(
    pdfmake_arena_t *arena,
    const char *path);

/*============================================================================
 * Certificate Info
 *==========================================================================*/

/**
 * Check if certificate is valid at given time.
 *
 * @param cert    Certificate to check
 * @param time    Unix timestamp to check (0 = current time)
 * @return        1 if valid, 0 if expired/not yet valid
 */
int pdfmake_x509_is_valid(
    const pdfmake_x509_cert_t *cert,
    int64_t time);

/**
 * Check if certificate can be used for document signing.
 *
 * @param cert    Certificate to check
 * @return        1 if valid for signing, 0 otherwise
 */
int pdfmake_x509_can_sign_documents(const pdfmake_x509_cert_t *cert);

/**
 * Format certificate subject as one-line string.
 *
 * @param arena   Memory arena for allocations
 * @param name    Name structure to format
 * @return        Formatted string "CN=..., O=..., C=..."
 */
char *pdfmake_x509_format_name(
    pdfmake_arena_t *arena,
    const pdfmake_x509_name_t *name);

/**
 * Get human-readable signature algorithm name.
 */
const char *pdfmake_x509_sig_algorithm_name(pdfmake_sig_algorithm_t alg);

/**
 * Get human-readable public key algorithm name.
 */
const char *pdfmake_x509_pk_algorithm_name(pdfmake_pk_algorithm_t alg);

/*============================================================================
 * Signature Verification (certificate chain)
 *==========================================================================*/

/**
 * Verify certificate signature using issuer's public key.
 *
 * @param cert      Certificate to verify
 * @param issuer    Issuing certificate (NULL for self-signed check)
 * @return          PDFMAKE_OK if valid, error code otherwise
 */
pdfmake_err_t pdfmake_x509_verify_signature(
    const pdfmake_x509_cert_t *cert,
    const pdfmake_x509_cert_t *issuer);

/**
 * Build and verify certificate chain.
 *
 * @param chain         Certificate chain (end-entity first)
 * @param trust_anchors Trusted root certificates (optional)
 * @return              PDFMAKE_OK if chain is valid, error code otherwise
 */
pdfmake_err_t pdfmake_x509_verify_chain(
    const pdfmake_cert_chain_t *chain,
    const pdfmake_cert_chain_t *trust_anchors);

/*============================================================================
 * Memory Management
 *==========================================================================*/

/**
 * Free certificate (if using heap allocation).
 * Note: If allocated from arena, just free the arena.
 */
void pdfmake_x509_cert_free(pdfmake_x509_cert_t *cert);

/**
 * Free certificate chain.
 */
void pdfmake_cert_chain_free(pdfmake_cert_chain_t *chain);

/*============================================================================
 * Well-known OIDs
 *==========================================================================*/

/* Signature algorithms */
#define OID_RSA_ENCRYPTION          "1.2.840.113549.1.1.1"
#define OID_RSA_MD5                 "1.2.840.113549.1.1.4"
#define OID_RSA_SHA1                "1.2.840.113549.1.1.5"
#define OID_RSA_SHA256              "1.2.840.113549.1.1.11"
#define OID_RSA_SHA384              "1.2.840.113549.1.1.12"
#define OID_RSA_SHA512              "1.2.840.113549.1.1.13"

/* EC algorithms */
#define OID_EC_PUBLIC_KEY           "1.2.840.10045.2.1"
#define OID_ECDSA_SHA256            "1.2.840.10045.4.3.2"
#define OID_ECDSA_SHA384            "1.2.840.10045.4.3.3"
#define OID_ECDSA_SHA512            "1.2.840.10045.4.3.4"

/* Named curves */
#define OID_SECP256R1               "1.2.840.10045.3.1.7"   /* P-256 */
#define OID_SECP384R1               "1.3.132.0.34"          /* P-384 */
#define OID_SECP521R1               "1.3.132.0.35"          /* P-521 */

/* Hash algorithms */
#define OID_SHA1                    "1.3.14.3.2.26"
#define OID_SHA256                  "2.16.840.1.101.3.4.2.1"
#define OID_SHA384                  "2.16.840.1.101.3.4.2.2"
#define OID_SHA512                  "2.16.840.1.101.3.4.2.3"

/* X.500 attribute types */
#define OID_COMMON_NAME             "2.5.4.3"
#define OID_COUNTRY                 "2.5.4.6"
#define OID_LOCALITY                "2.5.4.7"
#define OID_STATE                   "2.5.4.8"
#define OID_ORGANIZATION            "2.5.4.10"
#define OID_ORGANIZATIONAL_UNIT     "2.5.4.11"
#define OID_EMAIL_ADDRESS           "1.2.840.113549.1.9.1"
#define OID_SERIAL_NUMBER           "2.5.4.5"

/* X.509 extensions */
#define OID_BASIC_CONSTRAINTS       "2.5.29.19"
#define OID_KEY_USAGE               "2.5.29.15"
#define OID_EXT_KEY_USAGE           "2.5.29.37"
#define OID_SUBJECT_KEY_ID          "2.5.29.14"
#define OID_AUTHORITY_KEY_ID        "2.5.29.35"
#define OID_CRL_DISTRIBUTION        "2.5.29.31"
#define OID_AUTHORITY_INFO_ACCESS   "1.3.6.1.5.5.7.1.1"

/* Extended key usage */
#define OID_EKU_SERVER_AUTH         "1.3.6.1.5.5.7.3.1"
#define OID_EKU_CLIENT_AUTH         "1.3.6.1.5.5.7.3.2"
#define OID_EKU_CODE_SIGNING        "1.3.6.1.5.5.7.3.3"
#define OID_EKU_EMAIL_PROTECTION    "1.3.6.1.5.5.7.3.4"
#define OID_EKU_TIME_STAMPING       "1.3.6.1.5.5.7.3.8"
#define OID_EKU_OCSP_SIGNING        "1.3.6.1.5.5.7.3.9"
#define OID_EKU_DOCUMENT_SIGNING    "1.3.6.1.4.1.311.10.3.12"   /* Microsoft */
#define OID_EKU_PDF_SIGNING         "1.2.840.113583.1.1.5"       /* Adobe */

/* Authority Info Access */
#define OID_OCSP                    "1.3.6.1.5.5.7.48.1"
#define OID_CA_ISSUERS              "1.3.6.1.5.5.7.48.2"

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_X509_H */
