/*
 * pdfmake_pkcs12.h — PKCS#12/PFX container parsing
 *
 * Parse PKCS#12 (.p12, .pfx) files to extract private keys and certificates
 * for PDF digital signatures.
 */

#ifndef PDFMAKE_PKCS12_H
#define PDFMAKE_PKCS12_H

#include "pdfmake_types.h"
#include "pdfmake_arena.h"
#include "pdfmake_x509.h"

#ifdef __cplusplus
extern "C" {
#endif

/*============================================================================
 * Private Key Structures
 *==========================================================================*/

/* RSA private key */
typedef struct pdfmake_rsa_privkey_s {
    uint8_t *modulus;            /* n */
    size_t modulus_len;
    uint8_t *public_exponent;    /* e */
    size_t public_exponent_len;
    uint8_t *private_exponent;   /* d */
    size_t private_exponent_len;
    uint8_t *prime1;             /* p */
    size_t prime1_len;
    uint8_t *prime2;             /* q */
    size_t prime2_len;
    uint8_t *exponent1;          /* d mod (p-1) */
    size_t exponent1_len;
    uint8_t *exponent2;          /* d mod (q-1) */
    size_t exponent2_len;
    uint8_t *coefficient;        /* (inverse of q) mod p */
    size_t coefficient_len;
} pdfmake_rsa_privkey_t;

/* ECDSA private key */
typedef struct pdfmake_ecdsa_privkey_s {
    const char *curve_oid;       /* Named curve OID */
    int curve_bits;              /* 256, 384, 521 */
    uint8_t *private_value;      /* d (private scalar) */
    size_t private_value_len;
    uint8_t *public_point;       /* Q (public point, uncompressed) */
    size_t public_point_len;
} pdfmake_ecdsa_privkey_t;

/* Generic private key */
typedef struct pdfmake_privkey_s {
    pdfmake_pk_algorithm_t algorithm;
    union {
        pdfmake_rsa_privkey_t rsa;
        pdfmake_ecdsa_privkey_t ecdsa;
    };
    
    /* Raw PKCS#8 data (for some APIs) */
    uint8_t *pkcs8_der;
    size_t pkcs8_der_len;
} pdfmake_privkey_t;

/*============================================================================
 * Signing Identity
 *==========================================================================*/

/* Complete signing identity: private key + certificate chain */
typedef struct pdfmake_signing_identity_s {
    pdfmake_privkey_t *privkey;           /* Private key */
    pdfmake_x509_cert_t *cert;            /* End-entity certificate */
    pdfmake_cert_chain_t *chain;          /* Full certificate chain */
    
    pdfmake_arena_t *arena;               /* Memory arena */
} pdfmake_signing_identity_t;

/*============================================================================
 * PKCS#12 Parsing API
 *==========================================================================*/

/**
 * Parse a PKCS#12 file.
 *
 * @param arena     Memory arena for allocations
 * @param data      PKCS#12 file data
 * @param len       Length of data
 * @param password  Password for decryption (NULL for empty password)
 * @return          Signing identity, or NULL on error
 */
pdfmake_signing_identity_t *pdfmake_pkcs12_parse(
    pdfmake_arena_t *arena,
    const uint8_t *data,
    size_t len,
    const char *password);

/**
 * Load PKCS#12 from file.
 *
 * @param arena     Memory arena for allocations
 * @param path      Path to .p12/.pfx file
 * @param password  Password for decryption (NULL for empty password)
 * @return          Signing identity, or NULL on error
 */
pdfmake_signing_identity_t *pdfmake_pkcs12_load_file(
    pdfmake_arena_t *arena,
    const char *path,
    const char *password);

/*============================================================================
 * Separate Key/Certificate Loading
 *==========================================================================*/

/**
 * Parse a PKCS#8 private key (DER encoded).
 *
 * @param arena     Memory arena
 * @param data      DER-encoded PKCS#8 PrivateKeyInfo
 * @param len       Length of data
 * @return          Private key, or NULL on error
 */
pdfmake_privkey_t *pdfmake_pkcs8_parse_der(
    pdfmake_arena_t *arena,
    const uint8_t *data,
    size_t len);

/**
 * Parse a PEM private key.
 * Handles both unencrypted and encrypted PKCS#8 format.
 *
 * @param arena     Memory arena
 * @param pem       PEM-encoded private key
 * @param len       Length of PEM data
 * @param password  Password for encrypted keys (NULL for unencrypted)
 * @return          Private key, or NULL on error
 */
pdfmake_privkey_t *pdfmake_privkey_parse_pem(
    pdfmake_arena_t *arena,
    const char *pem,
    size_t len,
    const char *password);

/**
 * Load private key from file.
 *
 * @param arena     Memory arena
 * @param path      Path to key file
 * @param password  Password for encrypted keys (NULL for unencrypted)
 * @return          Private key, or NULL on error
 */
pdfmake_privkey_t *pdfmake_privkey_load_file(
    pdfmake_arena_t *arena,
    const char *path,
    const char *password);

/**
 * Create signing identity from separate key and certificate files.
 *
 * @param arena     Memory arena
 * @param key       Private key
 * @param cert      Certificate (must match private key)
 * @param chain     Optional certificate chain (can be NULL)
 * @return          Signing identity, or NULL on error
 */
pdfmake_signing_identity_t *pdfmake_signing_identity_create(
    pdfmake_arena_t *arena,
    pdfmake_privkey_t *key,
    pdfmake_x509_cert_t *cert,
    pdfmake_cert_chain_t *chain);

/*============================================================================
 * Key Information
 *==========================================================================*/

/**
 * Get key size in bits.
 */
int pdfmake_privkey_bits(const pdfmake_privkey_t *key);

/**
 * Check if private key matches certificate's public key.
 */
int pdfmake_privkey_matches_cert(
    const pdfmake_privkey_t *key,
    const pdfmake_x509_cert_t *cert);

/*============================================================================
 * Memory Management
 *==========================================================================*/

/**
 * Securely wipe and free private key.
 * Note: If allocated from arena, the arena must still be freed.
 */
void pdfmake_privkey_free(pdfmake_privkey_t *key);

/**
 * Free signing identity.
 */
void pdfmake_signing_identity_free(pdfmake_signing_identity_t *id);

/*============================================================================
 * PKCS#12 OIDs
 *==========================================================================*/

/* PKCS#12 */
#define OID_PKCS12                  "1.2.840.113549.1.12"
#define OID_PKCS12_BAGTYPES         "1.2.840.113549.1.12.10.1"
#define OID_PKCS12_KEYBAG           "1.2.840.113549.1.12.10.1.1"
#define OID_PKCS12_SHROUDEDKEYBAG   "1.2.840.113549.1.12.10.1.2"
#define OID_PKCS12_CERTBAG          "1.2.840.113549.1.12.10.1.3"
#define OID_PKCS12_CRLBAG           "1.2.840.113549.1.12.10.1.4"
#define OID_PKCS12_SECRETBAG        "1.2.840.113549.1.12.10.1.5"
#define OID_PKCS12_SAFECONTENTSBAG  "1.2.840.113549.1.12.10.1.6"

/* PKCS#12 PBE */
#define OID_PBE_SHA1_3DES           "1.2.840.113549.1.12.1.3"
#define OID_PBE_SHA1_2DES           "1.2.840.113549.1.12.1.4"
#define OID_PBE_SHA1_RC2_128        "1.2.840.113549.1.12.1.5"
#define OID_PBE_SHA1_RC2_40         "1.2.840.113549.1.12.1.6"

/* PKCS#5 PBES2 */
#define OID_PBES2                   "1.2.840.113549.1.5.13"
#define OID_PBKDF2                  "1.2.840.113549.1.5.12"

/* Symmetric encryption */
#define OID_AES128_CBC              "2.16.840.1.101.3.4.1.2"
#define OID_AES192_CBC              "2.16.840.1.101.3.4.1.22"
#define OID_AES256_CBC              "2.16.840.1.101.3.4.1.42"
#define OID_DES_CBC                 "1.3.14.3.2.7"
#define OID_3DES_CBC                "1.2.840.113549.3.7"

/* PKCS#7 */
#define OID_PKCS7_DATA              "1.2.840.113549.1.7.1"
#define OID_PKCS7_SIGNED            "1.2.840.113549.1.7.2"
#define OID_PKCS7_ENCRYPTED         "1.2.840.113549.1.7.6"

/* PKCS#8 */
#define OID_PKCS8_PRIVKEY           "1.2.840.113549.1.8"

/* X.509 certificate in PKCS#12 */
#define OID_CERT_X509               "1.2.840.113549.1.9.22.1"

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_PKCS12_H */
