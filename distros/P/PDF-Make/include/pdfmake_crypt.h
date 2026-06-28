/*
 * pdfmake_crypt.h — PDF encryption/decryption header
 *
 * Standard security handler implementation for R2-R6.
 */

#ifndef PDFMAKE_CRYPT_H
#define PDFMAKE_CRYPT_H

#include <stdint.h>
#include <stddef.h>

/*============================================================================
 * Constants
 *==========================================================================*/

#define PDFMAKE_CRYPT_MAX_KEY_LEN    32    /* AES-256 */
#define PDFMAKE_CRYPT_OWNER_KEY_LEN  32
#define PDFMAKE_CRYPT_USER_KEY_LEN   32
#define PDFMAKE_CRYPT_PERMS_LEN      16    /* R6 only */

/* Permission flags per Table 22 */
#define PDFMAKE_PERM_PRINT           (1 << 2)   /* bit 3 */
#define PDFMAKE_PERM_MODIFY          (1 << 3)   /* bit 4 */
#define PDFMAKE_PERM_COPY            (1 << 4)   /* bit 5 */
#define PDFMAKE_PERM_ANNOT           (1 << 5)   /* bit 6 */
#define PDFMAKE_PERM_FILL_FORMS      (1 << 8)   /* bit 9 */
#define PDFMAKE_PERM_EXTRACT         (1 << 9)   /* bit 10 */
#define PDFMAKE_PERM_ASSEMBLE        (1 << 10)  /* bit 11 */
#define PDFMAKE_PERM_PRINT_HIGH      (1 << 11)  /* bit 12 */

/* All permissions enabled */
#define PDFMAKE_PERM_ALL             0xFFFFFFFC

/* Encryption algorithms */
typedef enum {
    PDFMAKE_CRYPT_RC4_40   = 1,   /* R2: V=1, 40-bit RC4 */
    PDFMAKE_CRYPT_RC4_128  = 2,   /* R3: V=2, 40-128 bit RC4 */
    PDFMAKE_CRYPT_AES_128  = 3,   /* R4: V=4, 128-bit AES */
    PDFMAKE_CRYPT_AES_256  = 4    /* R6: V=5, 256-bit AES */
} pdfmake_crypt_algo_t;

/*============================================================================
 * Encryption context
 *==========================================================================*/

typedef struct {
    /* Algorithm parameters */
    int V;                          /* Version (1, 2, 4, or 5) */
    int R;                          /* Revision (2, 3, 4, or 6) */
    int key_length;                 /* In bytes (5, 16, or 32) */
    pdfmake_crypt_algo_t algorithm;
    
    /* Encryption key */
    uint8_t file_key[32];           /* File encryption key */
    int file_key_len;
    
    /* Standard handler values */
    uint8_t O[48];                  /* Owner key (32 bytes R2-R4, 48 bytes R6) */
    uint8_t U[48];                  /* User key (32 bytes R2-R4, 48 bytes R6) */
    uint8_t OE[32];                 /* R6: encrypted owner key */
    uint8_t UE[32];                 /* R6: encrypted user key */
    uint8_t Perms[16];              /* R6: encrypted permissions */
    int32_t P;                      /* Permission flags */
    
    /* Document ID (first element of ID array) */
    uint8_t doc_id[16];
    int doc_id_len;
    
    /* Metadata encryption flag */
    int encrypt_metadata;
    
    /* State */
    int initialized;
    int authenticated;              /* User or owner authenticated */
    int is_owner;                   /* Owner password was used */
} pdfmake_crypt_ctx_t;

/*============================================================================
 * Initialization
 *==========================================================================*/

/**
 * Initialize encryption context.
 */
void pdfmake_crypt_init(pdfmake_crypt_ctx_t *ctx);

/**
 * Set up encryption for a new document.
 * 
 * @param ctx           Encryption context
 * @param algorithm     Encryption algorithm
 * @param user_passwd   User password (empty string for no password)
 * @param owner_passwd  Owner password (NULL to use user password)
 * @param permissions   Permission flags
 * @param doc_id        Document ID (first element of ID array)
 * @param doc_id_len    Document ID length
 * @return              0 on success, -1 on error
 */
int pdfmake_crypt_setup(pdfmake_crypt_ctx_t *ctx,
                        pdfmake_crypt_algo_t algorithm,
                        const char *user_passwd,
                        const char *owner_passwd,
                        int32_t permissions,
                        const uint8_t *doc_id,
                        size_t doc_id_len);

/**
 * Load encryption parameters from parsed /Encrypt dictionary.
 * Call pdfmake_crypt_authenticate() after this.
 */
int pdfmake_crypt_load(pdfmake_crypt_ctx_t *ctx,
                       int V, int R, int key_length,
                       const uint8_t *O, size_t O_len,
                       const uint8_t *U, size_t U_len,
                       const uint8_t *OE, size_t OE_len,
                       const uint8_t *UE, size_t UE_len,
                       const uint8_t *Perms, size_t Perms_len,
                       int32_t P,
                       const uint8_t *doc_id, size_t doc_id_len,
                       int encrypt_metadata);

/*============================================================================
 * Authentication
 *==========================================================================*/

/**
 * Authenticate with user or owner password.
 * 
 * @param ctx      Encryption context (must be loaded first)
 * @param passwd   Password to try
 * @return         1 if owner authenticated, 0 if user authenticated, -1 if failed
 */
int pdfmake_crypt_authenticate(pdfmake_crypt_ctx_t *ctx, const char *passwd);

/**
 * Check if context is authenticated.
 */
int pdfmake_crypt_is_authenticated(const pdfmake_crypt_ctx_t *ctx);

/**
 * Check if owner password was used.
 */
int pdfmake_crypt_is_owner(const pdfmake_crypt_ctx_t *ctx);

/*============================================================================
 * Per-object key derivation
 *==========================================================================*/

/**
 * Derive per-object key for string/stream encryption.
 * For R6 (AES-256), returns file key directly.
 * 
 * @param ctx       Encryption context
 * @param obj_num   Object number
 * @param gen_num   Generation number
 * @param key_out   Output key buffer (at least 16 bytes for RC4/AES-128, 32 for AES-256)
 * @return          Key length in bytes
 */
int pdfmake_crypt_object_key(const pdfmake_crypt_ctx_t *ctx,
                             int obj_num, int gen_num,
                             uint8_t *key_out);

/*============================================================================
 * String/Stream encryption
 *==========================================================================*/

/**
 * Encrypt a string.
 * 
 * @param ctx       Encryption context
 * @param obj_num   Object number
 * @param gen_num   Generation number
 * @param in        Input plaintext
 * @param in_len    Input length
 * @param out       Output buffer (must be large enough)
 * @return          Output length, or -1 on error
 */
int pdfmake_crypt_encrypt_string(const pdfmake_crypt_ctx_t *ctx,
                                 int obj_num, int gen_num,
                                 const uint8_t *in, size_t in_len,
                                 uint8_t *out);

/**
 * Decrypt a string.
 */
int pdfmake_crypt_decrypt_string(const pdfmake_crypt_ctx_t *ctx,
                                 int obj_num, int gen_num,
                                 const uint8_t *in, size_t in_len,
                                 uint8_t *out);

/**
 * Encrypt a stream.
 */
int pdfmake_crypt_encrypt_stream(const pdfmake_crypt_ctx_t *ctx,
                                 int obj_num, int gen_num,
                                 const uint8_t *in, size_t in_len,
                                 uint8_t **out, size_t *out_len);

/**
 * Decrypt a stream.
 */
int pdfmake_crypt_decrypt_stream(const pdfmake_crypt_ctx_t *ctx,
                                 int obj_num, int gen_num,
                                 const uint8_t *in, size_t in_len,
                                 uint8_t **out, size_t *out_len);

/*============================================================================
 * Permission checking
 *==========================================================================*/

/**
 * Check if a permission is granted.
 */
int pdfmake_crypt_has_permission(const pdfmake_crypt_ctx_t *ctx, int32_t perm);

/**
 * Get all permission flags.
 */
int32_t pdfmake_crypt_get_permissions(const pdfmake_crypt_ctx_t *ctx);

#endif /* PDFMAKE_CRYPT_H */
