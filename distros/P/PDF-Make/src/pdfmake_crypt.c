/*
 * pdfmake_crypt.c — PDF encryption/decryption implementation
 *
 * Standard security handler for R2-R6 per ISO 32000-2:2020 §7.6.
 */

#include "pdfmake_crypt.h"
#include "pdfmake_md5.h"
#include "pdfmake_sha2.h"
#include "pdfmake_rc4.h"
#include "pdfmake_aes.h"
#include <string.h>
#include <stdlib.h>
#include <time.h>

/*============================================================================
 * Constants
 *==========================================================================*/

/* Padding string per §7.6.4.3.2 */
static const uint8_t PADDING[32] = {
    0x28, 0xBF, 0x4E, 0x5E, 0x4E, 0x75, 0x8A, 0x41,
    0x64, 0x00, 0x4E, 0x56, 0xFF, 0xFA, 0x01, 0x08,
    0x2E, 0x2E, 0x00, 0xB6, 0xD0, 0x68, 0x3E, 0x80,
    0x2F, 0x0C, 0xA9, 0xFE, 0x64, 0x53, 0x69, 0x7A
};

/* Salt for AES in crypt filter */
static const uint8_t AES_SALT[] = { 0x73, 0x41, 0x6C, 0x54 };  /* "sAlT" */

/*============================================================================
 * Helper functions
 *==========================================================================*/

/* Pad password to 32 bytes */
static void pad_password(const char *passwd, uint8_t padded[32])
{
    size_t len = passwd ? strlen(passwd) : 0;
    if (len > 32) len = 32;
    
    if (len > 0) {
        memcpy(padded, passwd, len);
    }
    memcpy(padded + len, PADDING, 32 - len);
}

/* Simple random bytes generator */
static void random_bytes(uint8_t *buf, size_t len)
{
    static uint32_t state = 0;
    size_t i;

    if (state == 0) {
        state = (uint32_t)time(NULL) ^ 0x5A5A5A5A;
    }
    
    for (i = 0; i < len; i++) {
        state ^= state << 13;
        state ^= state >> 17;
        state ^= state << 5;
        buf[i] = (uint8_t)(state & 0xFF);
    }
}

/*============================================================================
 * R2-R4 key derivation (Algorithm 2)
 *==========================================================================*/

static void compute_file_key_r2_r4(pdfmake_crypt_ctx_t *ctx,
                                   const uint8_t *passwd_padded,
                                   const uint8_t *O,
                                   int32_t P,
                                   const uint8_t *doc_id,
                                   size_t doc_id_len,
                                   int key_length,
                                   int encrypt_metadata)
{
    pdfmake_md5_ctx_t md5;
    uint8_t digest[16];
    uint8_t p_bytes[4];
    int i;
    
    /* Step 1-4: MD5(passwd || O || P || ID || metadata_flag) */
    pdfmake_md5_init(&md5);
    pdfmake_md5_update(&md5, passwd_padded, 32);
    pdfmake_md5_update(&md5, O, 32);
    
    p_bytes[0] = (uint8_t)(P & 0xFF);
    p_bytes[1] = (uint8_t)((P >> 8) & 0xFF);
    p_bytes[2] = (uint8_t)((P >> 16) & 0xFF);
    p_bytes[3] = (uint8_t)((P >> 24) & 0xFF);
    pdfmake_md5_update(&md5, p_bytes, 4);
    
    pdfmake_md5_update(&md5, doc_id, doc_id_len);
    
    /* R4 only: if not encrypting metadata, add 0xFFFFFFFF */
    if (ctx->R >= 4 && !encrypt_metadata) {
        uint8_t meta_flag[4];
        meta_flag[0] = 0xFF;
        meta_flag[1] = 0xFF;
        meta_flag[2] = 0xFF;
        meta_flag[3] = 0xFF;
        pdfmake_md5_update(&md5, meta_flag, 4);
    }
    
    pdfmake_md5_final(&md5, digest);
    
    /* R3+: iterate MD5 50 times */
    if (ctx->R >= 3) {
        for (i = 0; i < 50; i++) {
            pdfmake_md5(digest, key_length, digest);
        }
    }
    
    memcpy(ctx->file_key, digest, key_length);
    ctx->file_key_len = key_length;
}

/*============================================================================
 * R2-R4 O value computation (Algorithm 3)
 *==========================================================================*/

static void compute_O_value_r2_r4(pdfmake_crypt_ctx_t *ctx,
                                  const char *owner_passwd,
                                  const char *user_passwd,
                                  int key_length)
{
    uint8_t owner_padded[32], user_padded[32];
    const char *pw;
    uint8_t digest[16];
    uint8_t temp_key[16];
    int i;
    int j;
    
    /* Use owner password or fall back to user password */
    pw = (owner_passwd && *owner_passwd) ? owner_passwd : user_passwd;
    pad_password(pw, owner_padded);
    pad_password(user_passwd, user_padded);
    
    /* Step 1: MD5(owner_passwd) */
    pdfmake_md5(owner_padded, 32, digest);
    
    /* R3+: iterate MD5 50 times */
    if (ctx->R >= 3) {
        for (i = 0; i < 50; i++) {
            pdfmake_md5(digest, key_length, digest);
        }
    }
    
    /* Step 4: RC4 encrypt user password */
    memcpy(ctx->O, user_padded, 32);
    pdfmake_rc4(digest, key_length, ctx->O, 32);
    
    /* R3+: iterate with modified keys */
    if (ctx->R >= 3) {
        for (i = 1; i <= 19; i++) {
            for (j = 0; j < key_length; j++) {
                temp_key[j] = digest[j] ^ (uint8_t)i;
            }
            pdfmake_rc4(temp_key, key_length, ctx->O, 32);
        }
    }
}

/*============================================================================
 * R2-R4 U value computation (Algorithm 4/5)
 *==========================================================================*/

static void compute_U_value_r2(pdfmake_crypt_ctx_t *ctx)
{
    /* Algorithm 4: RC4 encrypt padding string */
    memcpy(ctx->U, PADDING, 32);
    pdfmake_rc4(ctx->file_key, ctx->file_key_len, ctx->U, 32);
}

static void compute_U_value_r3_r4(pdfmake_crypt_ctx_t *ctx)
{
    /* Algorithm 5: MD5(padding || ID), then RC4 */
    uint8_t digest[16];
    pdfmake_md5_ctx_t md5;
    uint8_t temp_key[16];
    int i;
    int j;
    
    pdfmake_md5_init(&md5);
    pdfmake_md5_update(&md5, PADDING, 32);
    pdfmake_md5_update(&md5, ctx->doc_id, ctx->doc_id_len);
    pdfmake_md5_final(&md5, digest);
    
    pdfmake_rc4(ctx->file_key, ctx->file_key_len, digest, 16);
    
    /* Iterate with modified keys */
    for (i = 1; i <= 19; i++) {
        for (j = 0; j < ctx->file_key_len; j++) {
            temp_key[j] = ctx->file_key[j] ^ (uint8_t)i;
        }
        pdfmake_rc4(temp_key, ctx->file_key_len, digest, 16);
    }
    
    memcpy(ctx->U, digest, 16);
    /* Arbitrary padding for remaining 16 bytes */
    memset(ctx->U + 16, 0, 16);
}

/*============================================================================
 * R6 key derivation (ISO 32000-2 Algorithm 2.A/2.B)
 *==========================================================================*/

/* Intermediate hash function for R6 */
static void r6_intermediate_hash(const uint8_t *passwd, size_t passwd_len,
                                 const uint8_t *data, size_t data_len,
                                 const uint8_t *user_key,  /* NULL for user validation */
                                 uint8_t result[32])
{
    /* K = SHA-256(passwd || data || user_key?) */
    pdfmake_sha256_ctx_t sha;
    uint8_t K[64];
    int hash_len;
    int round;
    uint8_t last_e_byte;
    size_t k1_single;
    size_t k1_len;
    uint8_t *K1;
    pdfmake_aes_ctx_t aes;
    uint8_t *E;
    uint8_t iv[16];
    uint8_t block[16];
    int i;
    int j;
    size_t pos;
    uint32_t sum;
    int hash_type;

    pdfmake_sha256_init(&sha);
    pdfmake_sha256_update(&sha, passwd, passwd_len);
    pdfmake_sha256_update(&sha, data, data_len);
    if (user_key) {
        pdfmake_sha256_update(&sha, user_key, 48);
    }
    pdfmake_sha256_final(&sha, K);
    
    hash_len = 32;  /* SHA-256 */

    /* Algorithm 2.B: at least 64 rounds, then keep going until
     * (round - 32) >= E[last_byte], where round is 1-based.  The loop
     * body is identical each round; only the termination differs. */
    round = 0;
    last_e_byte = 0;
    while (round < 64 || (round - 32) < last_e_byte) {
        /* Build K1: passwd || K || user_key? repeated 64 times */
        k1_single = passwd_len + hash_len + (user_key ? 48 : 0);
        k1_len = k1_single * 64;
        K1 = malloc(k1_len);
        if (!K1) return;

        for (i = 0; i < 64; i++) {
            size_t off = i * k1_single;
            memcpy(K1 + off, passwd, passwd_len);
            memcpy(K1 + off + passwd_len, K, hash_len);
            if (user_key) {
                memcpy(K1 + off + passwd_len + hash_len, user_key, 48);
            }
        }

        /* E = AES-128-CBC(K[:16], K[16:32], K1) - no padding */
        pdfmake_aes_init(&aes, K, 16);

        E = malloc(k1_len);
        if (!E) { free(K1); return; }

        memcpy(iv, K + 16, 16);

        /* CBC encrypt without padding */
        for (pos = 0; pos < k1_len; pos += 16) {
            for (j = 0; j < 16; j++) {
                block[j] = K1[pos + j] ^ iv[j];
            }
            pdfmake_aes_encrypt_block(&aes, block, E + pos);
            memcpy(iv, E + pos, 16);
        }

        /* Take first 16 bytes of E as a big-endian unsigned int, mod 3.
         * Because 256 ≡ 1 (mod 3), this reduces to (sum of bytes) mod 3. */
        sum = 0;
        for (i = 0; i < 16; i++) sum += E[i];
        hash_type = sum % 3;

        if (hash_type == 0) {
            pdfmake_sha256(E, k1_len, K);
            hash_len = 32;
        } else if (hash_type == 1) {
            pdfmake_sha384(E, k1_len, K);
            hash_len = 48;
        } else {
            pdfmake_sha512(E, k1_len, K);
            hash_len = 64;
        }

        last_e_byte = E[k1_len - 1];
        free(K1);
        free(E);
        round++;
    }

    /* Return first 32 bytes of final K */
    memcpy(result, K, 32);
}

/* Generate random 8-byte salt */
static void r6_generate_salt(uint8_t salt[8])
{
    random_bytes(salt, 8);
}

/* Compute U and UE for R6 */
static void compute_U_UE_r6(pdfmake_crypt_ctx_t *ctx, const char *user_passwd)
{
    size_t passwd_len;
    uint8_t validation_salt[8], key_salt[8];
    uint8_t hash[32];
    uint8_t iv[16];
    pdfmake_aes_ctx_t aes;
    uint8_t padded_key[32];
    uint8_t block[16];
    int i;
    int j;

    passwd_len = user_passwd ? strlen(user_passwd) : 0;
    if (passwd_len > 127) passwd_len = 127;
    
    r6_generate_salt(validation_salt);
    r6_generate_salt(key_salt);
    
    /* U = hash(passwd || validation_salt) || validation_salt || key_salt */
    r6_intermediate_hash((const uint8_t *)user_passwd, passwd_len,
                         validation_salt, 8, NULL, hash);
    
    memcpy(ctx->U, hash, 32);
    memcpy(ctx->U + 32, validation_salt, 8);
    memcpy(ctx->U + 40, key_salt, 8);
    
    /* UE = AES-256-CBC(hash(passwd || key_salt), zeros, file_key) */
    r6_intermediate_hash((const uint8_t *)user_passwd, passwd_len,
                         key_salt, 8, NULL, hash);
    
    memset(iv, 0, 16);
    pdfmake_aes_init(&aes, hash, 32);
    
    /* Encrypt file key (pad to 32 bytes) */
    memcpy(padded_key, ctx->file_key, 32);
    for (i = 0; i < 32; i += 16) {
        for (j = 0; j < 16; j++) {
            block[j] = padded_key[i + j] ^ iv[j];
        }
        pdfmake_aes_encrypt_block(&aes, block, ctx->UE + i);
        memcpy(iv, ctx->UE + i, 16);
    }
}

/* Compute O and OE for R6 */
static void compute_O_OE_r6(pdfmake_crypt_ctx_t *ctx, const char *owner_passwd)
{
    size_t passwd_len;
    uint8_t validation_salt[8], key_salt[8];
    uint8_t hash[32];
    uint8_t iv[16];
    pdfmake_aes_ctx_t aes;
    uint8_t padded_key[32];
    uint8_t block[16];
    int i;
    int j;

    passwd_len = owner_passwd ? strlen(owner_passwd) : 0;
    if (passwd_len > 127) passwd_len = 127;
    
    r6_generate_salt(validation_salt);
    r6_generate_salt(key_salt);
    
    /* O = hash(passwd || validation_salt || U) || validation_salt || key_salt */
    r6_intermediate_hash((const uint8_t *)owner_passwd, passwd_len,
                         validation_salt, 8, ctx->U, hash);
    
    memcpy(ctx->O, hash, 32);
    memcpy(ctx->O + 32, validation_salt, 8);
    memcpy(ctx->O + 40, key_salt, 8);
    
    /* OE = AES-256-CBC(hash(passwd || key_salt || U), zeros, file_key) */
    r6_intermediate_hash((const uint8_t *)owner_passwd, passwd_len,
                         key_salt, 8, ctx->U, hash);
    
    memset(iv, 0, 16);
    pdfmake_aes_init(&aes, hash, 32);
    
    /* Encrypt file key */
    memcpy(padded_key, ctx->file_key, 32);
    for (i = 0; i < 32; i += 16) {
        for (j = 0; j < 16; j++) {
            block[j] = padded_key[i + j] ^ iv[j];
        }
        pdfmake_aes_encrypt_block(&aes, block, ctx->OE + i);
        memcpy(iv, ctx->OE + i, 16);
    }
}

/* Compute Perms for R6 */
static void compute_Perms_r6(pdfmake_crypt_ctx_t *ctx)
{
    uint8_t perms_data[16];
    pdfmake_aes_ctx_t aes;
    
    /* Bytes 0-3: P (little-endian) */
    perms_data[0] = (uint8_t)(ctx->P & 0xFF);
    perms_data[1] = (uint8_t)((ctx->P >> 8) & 0xFF);
    perms_data[2] = (uint8_t)((ctx->P >> 16) & 0xFF);
    perms_data[3] = (uint8_t)((ctx->P >> 24) & 0xFF);
    
    /* Bytes 4-7: 0xFFFFFFFF */
    perms_data[4] = 0xFF;
    perms_data[5] = 0xFF;
    perms_data[6] = 0xFF;
    perms_data[7] = 0xFF;
    
    /* Byte 8: 'T' if encrypting metadata, 'F' otherwise */
    perms_data[8] = ctx->encrypt_metadata ? 'T' : 'F';
    
    /* Byte 9: 'a' */
    perms_data[9] = 'a';
    
    /* Byte 10: 'd' */
    perms_data[10] = 'd';
    
    /* Byte 11: 'b' */
    perms_data[11] = 'b';
    
    /* Bytes 12-15: random */
    random_bytes(perms_data + 12, 4);
    
    /* Encrypt with file key (ECB mode, single block) */
    pdfmake_aes_init(&aes, ctx->file_key, 32);
    pdfmake_aes_encrypt_block(&aes, perms_data, ctx->Perms);
}

/*============================================================================
 * Public API: Initialization
 *==========================================================================*/

void pdfmake_crypt_init(pdfmake_crypt_ctx_t *ctx)
{
    memset(ctx, 0, sizeof(*ctx));
    ctx->encrypt_metadata = 1;  /* Default: encrypt metadata */
}

int pdfmake_crypt_setup(pdfmake_crypt_ctx_t *ctx,
                        pdfmake_crypt_algo_t algorithm,
                        const char *user_passwd,
                        const char *owner_passwd,
                        int32_t permissions,
                        const uint8_t *doc_id,
                        size_t doc_id_len)
{
    pdfmake_crypt_init(ctx);
    
    ctx->algorithm = algorithm;
    ctx->P = permissions | 0xFFFFF000;  /* Set required high bits */
    
    /* Copy document ID */
    if (doc_id_len > 16) doc_id_len = 16;
    memcpy(ctx->doc_id, doc_id, doc_id_len);
    ctx->doc_id_len = (int)doc_id_len;
    
    /* Set parameters based on algorithm */
    switch (algorithm) {
        case PDFMAKE_CRYPT_RC4_40:
            ctx->V = 1;
            ctx->R = 2;
            ctx->key_length = 5;  /* 40 bits */
            break;
        case PDFMAKE_CRYPT_RC4_128:
            ctx->V = 2;
            ctx->R = 3;
            ctx->key_length = 16;  /* 128 bits */
            break;
        case PDFMAKE_CRYPT_AES_128:
            ctx->V = 4;
            ctx->R = 4;
            ctx->key_length = 16;  /* 128 bits */
            break;
        case PDFMAKE_CRYPT_AES_256:
            ctx->V = 5;
            ctx->R = 6;
            ctx->key_length = 32;  /* 256 bits */
            break;
        default:
            return -1;
    }
    
    if (ctx->R <= 4) {
        uint8_t passwd_padded[32];
        /* R2-R4: Compute O, then file key, then U */
        compute_O_value_r2_r4(ctx, owner_passwd, user_passwd, ctx->key_length);
        
        pad_password(user_passwd, passwd_padded);
        compute_file_key_r2_r4(ctx, passwd_padded, ctx->O, ctx->P,
                               ctx->doc_id, ctx->doc_id_len,
                               ctx->key_length, ctx->encrypt_metadata);
        
        if (ctx->R == 2) {
            compute_U_value_r2(ctx);
        } else {
            compute_U_value_r3_r4(ctx);
        }
    } else {
        const char *op;
        /* R6: Generate random file key, then compute U/UE/O/OE/Perms */
        random_bytes(ctx->file_key, 32);
        ctx->file_key_len = 32;
        
        /* Use owner password or fall back to user password */
        op = (owner_passwd && *owner_passwd) ? owner_passwd : user_passwd;
        
        compute_U_UE_r6(ctx, user_passwd);
        compute_O_OE_r6(ctx, op);
        compute_Perms_r6(ctx);
    }
    
    ctx->initialized = 1;
    ctx->authenticated = 1;
    ctx->is_owner = 1;
    
    return 0;
}

int pdfmake_crypt_load(pdfmake_crypt_ctx_t *ctx,
                       int V, int R, int key_length,
                       const uint8_t *O, size_t O_len,
                       const uint8_t *U, size_t U_len,
                       const uint8_t *OE, size_t OE_len,
                       const uint8_t *UE, size_t UE_len,
                       const uint8_t *Perms, size_t Perms_len,
                       int32_t P,
                       const uint8_t *doc_id, size_t doc_id_len,
                       int encrypt_metadata)
{
    pdfmake_crypt_init(ctx);
    
    ctx->V = V;
    ctx->R = R;
    ctx->key_length = key_length / 8;  /* Convert bits to bytes */
    ctx->P = P;
    ctx->encrypt_metadata = encrypt_metadata;
    
    /* Determine algorithm from V/R */
    if (V == 1) {
        ctx->algorithm = PDFMAKE_CRYPT_RC4_40;
        ctx->key_length = 5;
    } else if (V == 2) {
        ctx->algorithm = PDFMAKE_CRYPT_RC4_128;
    } else if (V == 4) {
        ctx->algorithm = PDFMAKE_CRYPT_AES_128;
        ctx->key_length = 16;
    } else if (V == 5) {
        ctx->algorithm = PDFMAKE_CRYPT_AES_256;
        ctx->key_length = 32;
    } else {
        return -1;  /* Unsupported */
    }
    
    /* Copy values */
    if (O && O_len > 0) {
        size_t copy_len = O_len > 48 ? 48 : O_len;
        memcpy(ctx->O, O, copy_len);
    }
    if (U && U_len > 0) {
        size_t copy_len = U_len > 48 ? 48 : U_len;
        memcpy(ctx->U, U, copy_len);
    }
    if (OE && OE_len == 32) {
        memcpy(ctx->OE, OE, 32);
    }
    if (UE && UE_len == 32) {
        memcpy(ctx->UE, UE, 32);
    }
    if (Perms && Perms_len == 16) {
        memcpy(ctx->Perms, Perms, 16);
    }
    
    if (doc_id && doc_id_len > 0) {
        size_t copy_len = doc_id_len > 16 ? 16 : doc_id_len;
        memcpy(ctx->doc_id, doc_id, copy_len);
        ctx->doc_id_len = (int)copy_len;
    }
    
    ctx->initialized = 1;
    
    return 0;
}

/*============================================================================
 * Public API: Authentication
 *==========================================================================*/

static int authenticate_user_r2_r4(pdfmake_crypt_ctx_t *ctx, const char *passwd)
{
    uint8_t passwd_padded[32];
    uint8_t computed_U[32];
    uint8_t digest[16];
    pdfmake_md5_ctx_t md5;
    uint8_t temp_key[16];
    int i;
    int j;

    pad_password(passwd, passwd_padded);
    
    /* Compute file key */
    compute_file_key_r2_r4(ctx, passwd_padded, ctx->O, ctx->P,
                           ctx->doc_id, ctx->doc_id_len,
                           ctx->key_length, ctx->encrypt_metadata);
    
    /* Compute U and compare */
    if (ctx->R == 2) {
        memcpy(computed_U, PADDING, 32);
        pdfmake_rc4(ctx->file_key, ctx->file_key_len, computed_U, 32);
        
        return memcmp(computed_U, ctx->U, 32) == 0;
    } else {
        /* R3/R4: Only compare first 16 bytes */
        pdfmake_md5_init(&md5);
        pdfmake_md5_update(&md5, PADDING, 32);
        pdfmake_md5_update(&md5, ctx->doc_id, ctx->doc_id_len);
        pdfmake_md5_final(&md5, digest);
        
        pdfmake_rc4(ctx->file_key, ctx->file_key_len, digest, 16);
        
        for (i = 1; i <= 19; i++) {
            for (j = 0; j < ctx->file_key_len; j++) {
                temp_key[j] = ctx->file_key[j] ^ (uint8_t)i;
            }
            pdfmake_rc4(temp_key, ctx->file_key_len, digest, 16);
        }
        
        return memcmp(digest, ctx->U, 16) == 0;
    }
}

static int authenticate_owner_r2_r4(pdfmake_crypt_ctx_t *ctx, const char *passwd)
{
    uint8_t passwd_padded[32];
    uint8_t digest[16];
    uint8_t user_passwd[32];
    uint8_t temp_key[16];
    char user_str[33];
    int i;
    int j;

    pad_password(passwd, passwd_padded);
    
    /* Compute owner key from password */
    pdfmake_md5(passwd_padded, 32, digest);
    
    if (ctx->R >= 3) {
        for (i = 0; i < 50; i++) {
            pdfmake_md5(digest, ctx->key_length, digest);
        }
    }
    
    /* Decrypt O to get user password */
    memcpy(user_passwd, ctx->O, 32);
    
    if (ctx->R == 2) {
        pdfmake_rc4(digest, ctx->key_length, user_passwd, 32);
    } else {
        /* R3+: decrypt in reverse order */
        for (i = 19; i >= 0; i--) {
            for (j = 0; j < ctx->key_length; j++) {
                temp_key[j] = digest[j] ^ (uint8_t)i;
            }
            pdfmake_rc4(temp_key, ctx->key_length, user_passwd, 32);
        }
    }
    
    /* Now authenticate with derived user password */
    memcpy(user_str, user_passwd, 32);
    user_str[32] = '\0';
    
    return authenticate_user_r2_r4(ctx, user_str);
}

static int authenticate_user_r6(pdfmake_crypt_ctx_t *ctx, const char *passwd)
{
    size_t passwd_len;
    uint8_t hash[32];
    uint8_t iv[16];
    pdfmake_aes_ctx_t aes;
    uint8_t decrypted[16];
    int i;
    int j;

    passwd_len = passwd ? strlen(passwd) : 0;
    if (passwd_len > 127) passwd_len = 127;
    
    /* Validate: hash(passwd || U[32:40]) should equal U[0:32] */
    r6_intermediate_hash((const uint8_t *)passwd, passwd_len,
                         ctx->U + 32, 8, NULL, hash);
    
    if (memcmp(hash, ctx->U, 32) != 0) {
        return 0;  /* Validation failed */
    }
    
    /* Derive file key from UE */
    r6_intermediate_hash((const uint8_t *)passwd, passwd_len,
                         ctx->U + 40, 8, NULL, hash);
    
    /* Decrypt UE to get file key */
    memset(iv, 0, 16);
    pdfmake_aes_init(&aes, hash, 32);
    
    for (i = 0; i < 32; i += 16) {
        pdfmake_aes_decrypt_block(&aes, ctx->UE + i, decrypted);
        for (j = 0; j < 16; j++) {
            ctx->file_key[i + j] = decrypted[j] ^ iv[j];
        }
        memcpy(iv, ctx->UE + i, 16);
    }
    ctx->file_key_len = 32;
    
    return 1;
}

static int authenticate_owner_r6(pdfmake_crypt_ctx_t *ctx, const char *passwd)
{
    size_t passwd_len;
    uint8_t hash[32];
    uint8_t iv[16];
    pdfmake_aes_ctx_t aes;
    uint8_t decrypted[16];
    int i;
    int j;

    passwd_len = passwd ? strlen(passwd) : 0;
    if (passwd_len > 127) passwd_len = 127;
    
    /* Validate: hash(passwd || O[32:40] || U) should equal O[0:32] */
    r6_intermediate_hash((const uint8_t *)passwd, passwd_len,
                         ctx->O + 32, 8, ctx->U, hash);
    
    if (memcmp(hash, ctx->O, 32) != 0) {
        return 0;  /* Validation failed */
    }
    
    /* Derive file key from OE */
    r6_intermediate_hash((const uint8_t *)passwd, passwd_len,
                         ctx->O + 40, 8, ctx->U, hash);
    
    /* Decrypt OE to get file key */
    memset(iv, 0, 16);
    pdfmake_aes_init(&aes, hash, 32);
    
    for (i = 0; i < 32; i += 16) {
        pdfmake_aes_decrypt_block(&aes, ctx->OE + i, decrypted);
        for (j = 0; j < 16; j++) {
            ctx->file_key[i + j] = decrypted[j] ^ iv[j];
        }
        memcpy(iv, ctx->OE + i, 16);
    }
    ctx->file_key_len = 32;
    
    return 1;
}

int pdfmake_crypt_authenticate(pdfmake_crypt_ctx_t *ctx, const char *passwd)
{
    if (!ctx->initialized) {
        return -1;
    }
    
    if (ctx->R <= 4) {
        /* Try owner password first */
        if (authenticate_owner_r2_r4(ctx, passwd)) {
            ctx->authenticated = 1;
            ctx->is_owner = 1;
            return 1;
        }
        
        /* Try user password */
        if (authenticate_user_r2_r4(ctx, passwd)) {
            ctx->authenticated = 1;
            ctx->is_owner = 0;
            return 0;
        }
    } else {
        /* R6: Try owner password first */
        if (authenticate_owner_r6(ctx, passwd)) {
            ctx->authenticated = 1;
            ctx->is_owner = 1;
            return 1;
        }
        
        /* Try user password */
        if (authenticate_user_r6(ctx, passwd)) {
            ctx->authenticated = 1;
            ctx->is_owner = 0;
            return 0;
        }
    }
    
    return -1;  /* Authentication failed */
}

int pdfmake_crypt_is_authenticated(const pdfmake_crypt_ctx_t *ctx)
{
    return ctx->authenticated;
}

int pdfmake_crypt_is_owner(const pdfmake_crypt_ctx_t *ctx)
{
    return ctx->is_owner;
}

/*============================================================================
 * Public API: Per-object key derivation
 *==========================================================================*/

int pdfmake_crypt_object_key(const pdfmake_crypt_ctx_t *ctx,
                             int obj_num, int gen_num,
                             uint8_t *key_out)
{
    pdfmake_md5_ctx_t md5;
    uint8_t obj_bytes[5];
    uint8_t digest[16];
    int key_len;

    if (ctx->R >= 6) {
        /* R6: Use file key directly */
        memcpy(key_out, ctx->file_key, 32);
        return 32;
    }
    
    /* R2-R4: MD5(file_key || obj_num || gen_num || "sAlT") */
    pdfmake_md5_init(&md5);
    
    pdfmake_md5_update(&md5, ctx->file_key, ctx->file_key_len);
    
    obj_bytes[0] = (uint8_t)(obj_num & 0xFF);
    obj_bytes[1] = (uint8_t)((obj_num >> 8) & 0xFF);
    obj_bytes[2] = (uint8_t)((obj_num >> 16) & 0xFF);
    obj_bytes[3] = (uint8_t)(gen_num & 0xFF);
    obj_bytes[4] = (uint8_t)((gen_num >> 8) & 0xFF);
    pdfmake_md5_update(&md5, obj_bytes, 5);
    
    /* R4 AES: add "sAlT" */
    if (ctx->R >= 4) {
        pdfmake_md5_update(&md5, AES_SALT, 4);
    }
    
    pdfmake_md5_final(&md5, digest);
    
    /* Key length is min(file_key_len + 5, 16) */
    key_len = ctx->file_key_len + 5;
    if (key_len > 16) key_len = 16;
    
    memcpy(key_out, digest, key_len);
    return key_len;
}

/*============================================================================
 * Public API: String/Stream encryption
 *==========================================================================*/

int pdfmake_crypt_encrypt_string(const pdfmake_crypt_ctx_t *ctx,
                                 int obj_num, int gen_num,
                                 const uint8_t *in, size_t in_len,
                                 uint8_t *out)
{
    uint8_t key[32];
    int key_len = pdfmake_crypt_object_key(ctx, obj_num, gen_num, key);
    
    if (ctx->R >= 4) {
        /* AES: prepend IV, apply PKCS#7 */
        return (int)pdfmake_aes_pdf_encrypt(key, key_len, in, in_len, out);
    } else {
        /* RC4 */
        memcpy(out, in, in_len);
        pdfmake_rc4(key, key_len, out, in_len);
        return (int)in_len;
    }
}

int pdfmake_crypt_decrypt_string(const pdfmake_crypt_ctx_t *ctx,
                                 int obj_num, int gen_num,
                                 const uint8_t *in, size_t in_len,
                                 uint8_t *out)
{
    uint8_t key[32];
    int key_len = pdfmake_crypt_object_key(ctx, obj_num, gen_num, key);
    
    if (ctx->R >= 4) {
        /* AES: IV is first 16 bytes */
        return pdfmake_aes_pdf_decrypt(key, key_len, in, in_len, out);
    } else {
        /* RC4 */
        memcpy(out, in, in_len);
        pdfmake_rc4(key, key_len, out, in_len);
        return (int)in_len;
    }
}

int pdfmake_crypt_encrypt_stream(const pdfmake_crypt_ctx_t *ctx,
                                 int obj_num, int gen_num,
                                 const uint8_t *in, size_t in_len,
                                 uint8_t **out, size_t *out_len)
{
    /* Calculate output size */
    size_t max_out;
    int result;

    if (ctx->R >= 4) {
        /* AES: IV + padded data */
        max_out = 16 + in_len + 16;
    } else {
        max_out = in_len;
    }
    
    *out = malloc(max_out);
    if (!*out) return -1;
    
    result = pdfmake_crypt_encrypt_string(ctx, obj_num, gen_num,
                                          in, in_len, *out);
    if (result < 0) {
        free(*out);
        *out = NULL;
        return -1;
    }
    
    *out_len = (size_t)result;
    return 0;
}

int pdfmake_crypt_decrypt_stream(const pdfmake_crypt_ctx_t *ctx,
                                 int obj_num, int gen_num,
                                 const uint8_t *in, size_t in_len,
                                 uint8_t **out, size_t *out_len)
{
    int result;

    *out = malloc(in_len);
    if (!*out) return -1;
    
    result = pdfmake_crypt_decrypt_string(ctx, obj_num, gen_num,
                                          in, in_len, *out);
    if (result < 0) {
        free(*out);
        *out = NULL;
        return -1;
    }
    
    *out_len = (size_t)result;
    return 0;
}

/*============================================================================
 * Public API: Permission checking
 *==========================================================================*/

int pdfmake_crypt_has_permission(const pdfmake_crypt_ctx_t *ctx, int32_t perm)
{
    /* Owner always has all permissions */
    if (ctx->is_owner) {
        return 1;
    }
    
    return (ctx->P & perm) != 0;
}

int32_t pdfmake_crypt_get_permissions(const pdfmake_crypt_ctx_t *ctx)
{
    return ctx->P;
}
