/*
 * pdfmake_signature.h — PDF Digital Signatures
 *
 * Implements PDF digital signatures per ISO 32000-2:2020 §12.8.
 * Supports RSA PKCS#1 v1.5 and ECDSA with SHA-256/384/512.
 */

#ifndef PDFMAKE_SIGNATURE_H
#define PDFMAKE_SIGNATURE_H

#include "pdfmake_types.h"
#include "pdfmake_arena.h"
#include "pdfmake_buf.h"
#include "pdfmake_doc.h"
#include "pdfmake_x509.h"
#include "pdfmake_pkcs12.h"

#ifdef __cplusplus
extern "C" {
#endif

/*============================================================================
 * Hash Algorithms
 *==========================================================================*/

typedef enum {
    PDFMAKE_HASH_SHA1 = 0,
    PDFMAKE_HASH_SHA256,
    PDFMAKE_HASH_SHA384,
    PDFMAKE_HASH_SHA512
} pdfmake_hash_algorithm_t;

/* Hash context */
typedef struct pdfmake_hash_ctx_s pdfmake_hash_ctx_t;

/**
 * Create a new hash context.
 */
pdfmake_hash_ctx_t *pdfmake_hash_new(pdfmake_hash_algorithm_t alg);

/**
 * Update hash with data.
 */
void pdfmake_hash_update(pdfmake_hash_ctx_t *ctx, const uint8_t *data, size_t len);

/**
 * Finalize and get digest.
 * Returns digest length, or 0 on error.
 */
size_t pdfmake_hash_final(pdfmake_hash_ctx_t *ctx, uint8_t *digest);

/**
 * Free hash context.
 */
void pdfmake_hash_free(pdfmake_hash_ctx_t *ctx);

/**
 * One-shot hash computation.
 */
size_t pdfmake_hash(
    pdfmake_hash_algorithm_t alg,
    const uint8_t *data,
    size_t len,
    uint8_t *digest);

/**
 * Get hash output size for algorithm.
 */
size_t pdfmake_hash_size(pdfmake_hash_algorithm_t alg);

/*============================================================================
 * Signature Types
 *==========================================================================*/

/* Signature sub-filter (per ISO 32000-2) */
typedef enum {
    PDFMAKE_SUBFILTER_PKCS7_DETACHED = 0,  /* adbe.pkcs7.detached - recommended */
    PDFMAKE_SUBFILTER_PKCS7_SHA1,          /* adbe.pkcs7.sha1 - deprecated */
    PDFMAKE_SUBFILTER_ETSI_CADES,          /* ETSI.CAdES.detached - for PAdES */
    PDFMAKE_SUBFILTER_ETSI_RFC3161         /* ETSI.RFC3161 - for timestamps */
} pdfmake_sig_subfilter_t;

/* MDP (Modification Detection and Prevention) permissions */
typedef enum {
    PDFMAKE_MDP_NONE = 0,        /* Not a certification signature */
    PDFMAKE_MDP_NO_CHANGES = 1,  /* No changes permitted */
    PDFMAKE_MDP_FORM_FILL = 2,   /* Form filling + signing allowed */
    PDFMAKE_MDP_ANNOTATE = 3     /* Annotations + form fill + signing allowed */
} pdfmake_mdp_t;

/*============================================================================
 * Signature Configuration
 *==========================================================================*/

typedef struct pdfmake_sig_config_s {
    /* Signing identity */
    pdfmake_signing_identity_t *identity;
    
    /* Signature parameters */
    pdfmake_hash_algorithm_t hash_algorithm;  /* Default: SHA256 */
    pdfmake_sig_subfilter_t subfilter;        /* Default: PKCS7_DETACHED */
    
    /* Signature metadata */
    const char *reason;           /* Reason for signing */
    const char *location;         /* Location of signing */
    const char *contact_info;     /* Signer's contact info */
    const char *name;             /* Signer's name (default: from cert) */
    
    /* Timestamp */
    const char *timestamp_url;    /* TSA URL for RFC 3161 timestamp */
    
    /* Certification (MDP) */
    pdfmake_mdp_t mdp;            /* Certification permissions */
    
    /* Visual appearance */
    int visible;                  /* Create visible signature */
    int page;                     /* Page for visible signature (1-based) */
    double rect[4];               /* Rectangle for visible signature [x1, y1, x2, y2] */
    
    /* Placeholder size (bytes) */
    size_t placeholder_size;      /* Default: 8192 */

    /* Optional fixed signing time (UNIX seconds). 0 = use time(NULL). */
    int64_t signing_time;

    /* Optional RFC 3161 timestamp token (DER bytes) pre-fetched by caller
     * and spliced into SignerInfo.unsignedAttrs.  0-length = no timestamp. */
    const uint8_t *tst_token;
    size_t         tst_token_len;

    /* ---- Visible signature appearance ---------------------------------
     * When `visible` is set the widget is drawn on `page`, 1-based, at
     * `rect` (page-space [x0 y0 x1 y1]).  Without further fields the C
     * builder emits a sensible default — a white filled box with a
     * black border and three lines of Helvetica text showing the
     * signer name, date and reason.  Callers wanting custom visuals
     * (scanned signature image, branded block, etc.) can supply a
     * pre-rendered content-stream in `appearance_stream` plus a list
     * of (resource_name, base_font) pairs for the Form XObject's
     * /Resources /Font dict. */
    const uint8_t *appearance_stream;      /* raw content ops (BT/Tj/re/... */
    size_t         appearance_stream_len;
    const char   **appearance_font_names;  /* resource names used in stream */
    const char   **appearance_font_bases;  /* matching std-14 BaseFont names */
    size_t         appearance_font_count;
    /* Image/Form XObjects referenced from the appearance stream.  These
     * are already-added-to-doc indirect object numbers; the Form XObject's
     * /Resources /XObject dict maps each name onto its ref.  Used e.g. for
     * embedding a scanned scribbled-signature PNG. */
    const char   **appearance_xobject_names;  /* resource names, e.g. "Im1" */
    const uint32_t *appearance_xobject_nums;   /* matching doc obj nums */
    size_t         appearance_xobject_count;
    /* Default-appearance tuning (used only when appearance_stream == NULL). */
    int            ap_show_name;
    int            ap_show_date;
    int            ap_show_reason;
} pdfmake_sig_config_t;

/**
 * Initialize signature config with defaults.
 */
void pdfmake_sig_config_init(pdfmake_sig_config_t *config);

/*============================================================================
 * PKCS#7/CMS Signature Structure
 *==========================================================================*/

/* PKCS#7 SignedData content */
typedef struct pdfmake_pkcs7_s {
    pdfmake_arena_t *arena;
    
    /* Certificates (DER) */
    pdfmake_cert_chain_t *certs;
    
    /* Digest algorithm */
    pdfmake_hash_algorithm_t hash_alg;
    
    /* Signer info */
    pdfmake_x509_cert_t *signer_cert;
    uint8_t *signature;
    size_t signature_len;
    
    /* Signed attributes */
    int64_t signing_time;
    uint8_t *message_digest;      /* Hash of signed data */
    size_t message_digest_len;
    
    /* Timestamp (if present) */
    uint8_t *timestamp_token;
    size_t timestamp_token_len;
    
    /* Raw DER (for parsing) */
    const uint8_t *der;
    size_t der_len;
} pdfmake_pkcs7_t;

/**
 * Build PKCS#7 SignedData structure for PDF signing.
 *
 * @param arena     Memory arena
 * @param config    Signature configuration
 * @param digest    Document digest (from ByteRange)
 * @param digest_len Length of digest
 * @param out       Output buffer for DER-encoded PKCS#7
 * @return          PDFMAKE_OK on success
 */
pdfmake_err_t pdfmake_pkcs7_build(
    pdfmake_arena_t *arena,
    const pdfmake_sig_config_t *config,
    const uint8_t *digest,
    size_t digest_len,
    pdfmake_buf_t *out);

/*============================================================================
 * RFC 3161 TimeStampProtocol helpers
 *==========================================================================*/

/*
 * Build a DER-encoded TimeStampReq (RFC 3161 §2.4.1):
 *   TimeStampReq ::= SEQUENCE {
 *     version        INTEGER (v1 = 1),
 *     messageImprint MessageImprint,
 *     certReq        BOOLEAN DEFAULT FALSE
 *   }
 *   MessageImprint ::= SEQUENCE {
 *     hashAlgorithm AlgorithmIdentifier,
 *     hashedMessage OCTET STRING
 *   }
 *
 * digest + digest_len is typically SHA-256 of the CMS SignerInfo.signature
 * OCTET STRING contents (per PAdES §5.4 timestamp of signature value).
 * `out` is written with the DER bytes to POST to the TSA.
 */
pdfmake_err_t pdfmake_tsa_build_request(
    pdfmake_arena_t *arena,
    pdfmake_hash_algorithm_t hash_alg,
    const uint8_t *digest, size_t digest_len,
    int cert_req,
    pdfmake_buf_t *out);

/*
 * Parse a TimeStampResp (RFC 3161 §2.4.2) and return a pointer inside the
 * input buffer to the embedded TimeStampToken (ContentInfo).  The token
 * may be empty if the response was a rejection — the caller should first
 * check the PKIStatusInfo status field.
 *
 * Returns 0 on success with the token pointer + length filled; -1 on parse error,
 * -2 on rejection (status != granted|grantedWithMods).
 */
int pdfmake_tsa_parse_response(
    pdfmake_arena_t *arena,
    const uint8_t *resp_der, size_t resp_len,
    const uint8_t **token, size_t *token_len);

/*
 * Extract the RSA signature OCTET STRING bytes from a CMS SignedData DER
 * blob (typically the /Contents value of a PDF signature).  The returned
 * pointer aliases bytes inside the input.  Used to compute the hash input
 * for an RFC 3161 timestamp over the signature value, per PAdES §5.4.
 *
 * Returns 0 on success; -1 on parse error.
 */
int pdfmake_cms_extract_signature(
    pdfmake_arena_t *arena,
    const uint8_t *cms_der, size_t cms_len,
    const uint8_t **sig_bytes, size_t *sig_len);

/**
 * Parse PKCS#7 SignedData structure.
 *
 * @param arena     Memory arena
 * @param der       DER-encoded PKCS#7
 * @param len       Length of DER data
 * @return          Parsed structure, or NULL on error
 */
pdfmake_pkcs7_t *pdfmake_pkcs7_parse(
    pdfmake_arena_t *arena,
    const uint8_t *der,
    size_t len);

/**
 * Verify PKCS#7 signature against digest.
 *
 * @param pkcs7     Parsed PKCS#7 structure
 * @param digest    Expected document digest
 * @param digest_len Length of digest
 * @return          PDFMAKE_OK if valid
 */
pdfmake_err_t pdfmake_pkcs7_verify(
    const pdfmake_pkcs7_t *pkcs7,
    const uint8_t *digest,
    size_t digest_len);

/*============================================================================
 * PDF Signature Operations
 *==========================================================================*/

/* Signature field and value */
typedef struct pdfmake_sig_field_s {
    /* Field name */
    char *name;
    
    /* Page and rectangle */
    int page;
    double rect[4];
    
    /* Signature dictionary object number */
    int sig_obj_num;
    
    /* ByteRange offsets (filled during signing) */
    size_t byte_range[4];  /* [offset1, len1, offset2, len2] */
    
    /* Signature value offset and length */
    size_t sig_offset;
    size_t sig_len;
    
    /* Configuration used */
    pdfmake_sig_config_t config;
} pdfmake_sig_field_t;

/**
 * Add a signature field to the document.
 * The document must have a form (AcroForm) or one will be created.
 *
 * @param doc       Document
 * @param config    Signature configuration
 * @param name      Field name (NULL for auto-generated)
 * @return          Signature field, or NULL on error
 */
pdfmake_sig_field_t *pdfmake_doc_add_signature_field(
    pdfmake_doc_t *doc,
    const pdfmake_sig_config_t *config,
    const char *name);

/**
 * Sign the document.
 * This serializes the document with signature placeholder,
 * computes the document digest, creates the PKCS#7 signature,
 * and inserts it into the placeholder.
 *
 * @param doc       Document (must have signature field)
 * @param config    Signature configuration
 * @param out       Output buffer for signed PDF
 * @return          PDFMAKE_OK on success
 */
pdfmake_err_t pdfmake_doc_sign(
    pdfmake_doc_t *doc,
    const pdfmake_sig_config_t *config,
    pdfmake_buf_t *out);

/*============================================================================
 * Signature Verification
 *==========================================================================*/

/* Verification result */
typedef struct pdfmake_sig_verify_result_s {
    int valid;                    /* Overall validity */
    int signature_valid;          /* Cryptographic signature valid */
    int digest_valid;             /* Document digest matches */
    int cert_valid;               /* Certificate chain valid */
    int timestamp_valid;          /* Timestamp valid (if present) */
    
    /* Signer information */
    char *signer_name;            /* From certificate */
    char *signer_email;
    int64_t signing_time;         /* From signed attributes */
    
    /* Modification detection */
    int document_modified;        /* Document modified after signing */
    
    /* Certificate details */
    pdfmake_x509_cert_t *signer_cert;
    pdfmake_cert_chain_t *cert_chain;
    
    /* Error message (if !valid) */
    char *error;
} pdfmake_sig_verify_result_t;

/**
 * Verify a PDF signature.
 *
 * @param arena     Memory arena for results
 * @param pdf       PDF file data
 * @param len       Length of PDF data
 * @param field_index Index of signature field to verify (0 for first)
 * @return          Verification result
 */
pdfmake_sig_verify_result_t *pdfmake_sig_verify(
    pdfmake_arena_t *arena,
    const uint8_t *pdf,
    size_t len,
    int field_index);

/**
 * Get number of signature fields in document.
 */
int pdfmake_sig_count(const uint8_t *pdf, size_t len);

/*============================================================================
 * Raw Signature Operations
 *==========================================================================*/

/**
 * Sign a digest using RSA PKCS#1 v1.5.
 *
 * @param arena     Memory arena
 * @param key       Private key
 * @param hash_alg  Hash algorithm used for digest
 * @param digest    Digest to sign
 * @param digest_len Length of digest
 * @param signature Output: signature bytes
 * @param sig_len   Output: signature length
 * @return          PDFMAKE_OK on success
 */
pdfmake_err_t pdfmake_rsa_sign(
    pdfmake_arena_t *arena,
    const pdfmake_privkey_t *key,
    pdfmake_hash_algorithm_t hash_alg,
    const uint8_t *digest,
    size_t digest_len,
    uint8_t **signature,
    size_t *sig_len);

/**
 * Verify an RSA PKCS#1 v1.5 signature.
 */
pdfmake_err_t pdfmake_rsa_verify(
    const pdfmake_pubkey_t *key,
    pdfmake_hash_algorithm_t hash_alg,
    const uint8_t *digest,
    size_t digest_len,
    const uint8_t *signature,
    size_t sig_len);

/**
 * Sign a digest using ECDSA.
 *
 * @param arena     Memory arena
 * @param key       Private key
 * @param hash_alg  Hash algorithm used for digest
 * @param digest    Digest to sign
 * @param digest_len Length of digest
 * @param signature Output: DER-encoded signature (r, s)
 * @param sig_len   Output: signature length
 * @return          PDFMAKE_OK on success
 */
pdfmake_err_t pdfmake_ecdsa_sign(
    pdfmake_arena_t *arena,
    const pdfmake_privkey_t *key,
    pdfmake_hash_algorithm_t hash_alg,
    const uint8_t *digest,
    size_t digest_len,
    uint8_t **signature,
    size_t *sig_len);

/**
 * Verify an ECDSA signature.
 */
pdfmake_err_t pdfmake_ecdsa_verify(
    const pdfmake_pubkey_t *key,
    pdfmake_hash_algorithm_t hash_alg,
    const uint8_t *digest,
    size_t digest_len,
    const uint8_t *signature,
    size_t sig_len);

/*============================================================================
 * OIDs for Signatures
 *==========================================================================*/

/* Signature algorithms */
#define OID_SHA1_WITH_RSA           "1.2.840.113549.1.1.5"
#define OID_SHA256_WITH_RSA         "1.2.840.113549.1.1.11"
#define OID_SHA384_WITH_RSA         "1.2.840.113549.1.1.12"
#define OID_SHA512_WITH_RSA         "1.2.840.113549.1.1.13"

#define OID_SHA256_WITH_ECDSA       "1.2.840.10045.4.3.2"
#define OID_SHA384_WITH_ECDSA       "1.2.840.10045.4.3.3"
#define OID_SHA512_WITH_ECDSA       "1.2.840.10045.4.3.4"

/* PKCS#7/CMS */
#define OID_CMS_SIGNED_DATA         "1.2.840.113549.1.7.2"
#define OID_CMS_DATA                "1.2.840.113549.1.7.1"

/* Signed attributes */
#define OID_CONTENT_TYPE            "1.2.840.113549.1.9.3"
#define OID_MESSAGE_DIGEST          "1.2.840.113549.1.9.4"
#define OID_SIGNING_TIME            "1.2.840.113549.1.9.5"
#define OID_SIGNING_CERTIFICATE_V2  "1.2.840.113549.1.9.16.2.47"

/* Timestamp */
#define OID_TIMESTAMP_TOKEN         "1.2.840.113549.1.9.16.2.14"
#define OID_TST_INFO                "1.2.840.113549.1.9.16.1.4"

/* PDF-specific */
#define OID_ADOBE_PPKLITE           "1.2.840.113583.1.1.10"
#define OID_ADOBE_REVOCATION        "1.2.840.113583.1.1.8"

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_SIGNATURE_H */
