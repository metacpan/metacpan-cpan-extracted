/*
 * pdfmake_pkcs12.c — PKCS#12/PFX parsing implementation
 *
 * Parse PKCS#12 containers to extract signing identities.
 * 
 * Note: Full PKCS#12 parsing requires complex password-based encryption.
 * This is a simplified implementation that handles common cases.
 * For production use, consider linking against OpenSSL or similar.
 */

#include "pdfmake_pkcs12.h"
#include "pdfmake_asn1.h"
#include "pdfmake_x509.h"
#include "pdfmake_arena.h"
#include "pdfmake_aes.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

/*============================================================================
 * PKCS#12 Key Derivation (simplified - SHA1 based)
 *==========================================================================*/

/* PKCS#12 uses a specific KDF based on SHA-1 (RFC 7292, Appendix B) */
/* This is a simplified implementation for the most common case */

/* Simple SHA-1 implementation for PKCS#12 KDF */
/* For production, use a proper crypto library */

typedef struct {
    uint32_t state[5];
    uint64_t count;
    uint8_t buffer[64];
} sha1_ctx_t;

static void sha1_init(sha1_ctx_t *ctx)
{
    ctx->state[0] = 0x67452301;
    ctx->state[1] = 0xEFCDAB89;
    ctx->state[2] = 0x98BADCFE;
    ctx->state[3] = 0x10325476;
    ctx->state[4] = 0xC3D2E1F0;
    ctx->count = 0;
}

#define ROL32(x, n) (((x) << (n)) | ((x) >> (32 - (n))))

static void sha1_transform(uint32_t state[5], const uint8_t block[64])
{
    uint32_t a, b, c, d, e;
    uint32_t f, k;
    uint32_t temp;
    uint32_t w[80];
    int i;
    
    /* Expand block */
    for (i = 0; i < 16; i++) {
        w[i] = ((uint32_t)block[i*4] << 24) |
               ((uint32_t)block[i*4+1] << 16) |
               ((uint32_t)block[i*4+2] << 8) |
               ((uint32_t)block[i*4+3]);
    }
    for (i = 16; i < 80; i++) {
        w[i] = ROL32(w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16], 1);
    }
    
    a = state[0]; b = state[1]; c = state[2]; d = state[3]; e = state[4];
    
    for (i = 0; i < 80; i++) {
        if (i < 20) {
            f = (b & c) | ((~b) & d);
            k = 0x5A827999;
        } else if (i < 40) {
            f = b ^ c ^ d;
            k = 0x6ED9EBA1;
        } else if (i < 60) {
            f = (b & c) | (b & d) | (c & d);
            k = 0x8F1BBCDC;
        } else {
            f = b ^ c ^ d;
            k = 0xCA62C1D6;
        }
        
        temp = ROL32(a, 5) + f + e + k + w[i];
        e = d; d = c; c = ROL32(b, 30); b = a; a = temp;
    }
    
    state[0] += a; state[1] += b; state[2] += c; state[3] += d; state[4] += e;
}

static void sha1_update(sha1_ctx_t *ctx, const uint8_t *data, size_t len)
{
    size_t i = (ctx->count >> 3) & 63;
    size_t part_len;
    size_t j = 0;
    ctx->count += (uint64_t)len << 3;
    
    part_len = 64 - i;
    
    if (len >= part_len) {
        memcpy(ctx->buffer + i, data, part_len);
        sha1_transform(ctx->state, ctx->buffer);
        
        for (j = part_len; j + 63 < len; j += 64) {
            sha1_transform(ctx->state, data + j);
        }
        i = 0;
    }
    
    memcpy(ctx->buffer + i, data + j, len - j);
}

static void sha1_final(sha1_ctx_t *ctx, uint8_t digest[20])
{
    uint8_t pad[64] = {0x80};
    uint64_t bits = ctx->count;
    size_t i;
    size_t pad_len;
    uint8_t len_bytes[8];
    int j;
    
    i = (ctx->count >> 3) & 63;
    pad_len = (i < 56) ? (56 - i) : (120 - i);
    
    sha1_update(ctx, pad, pad_len);
    
    for (j = 0; j < 8; j++) {
        len_bytes[j] = (bits >> (56 - j * 8)) & 0xFF;
    }
    sha1_update(ctx, len_bytes, 8);
    
    for (j = 0; j < 5; j++) {
        digest[j*4] = (ctx->state[j] >> 24) & 0xFF;
        digest[j*4+1] = (ctx->state[j] >> 16) & 0xFF;
        digest[j*4+2] = (ctx->state[j] >> 8) & 0xFF;
        digest[j*4+3] = ctx->state[j] & 0xFF;
    }
}

static void sha1(const uint8_t *data, size_t len, uint8_t digest[20])
{
    sha1_ctx_t ctx;
    sha1_init(&ctx);
    sha1_update(&ctx, data, len);
    sha1_final(&ctx, digest);
}

/*
 * PKCS#12 Password-Based Key Derivation (RFC 7292 Appendix B)
 * 
 * This derives key material from a password and salt.
 * ID values: 1 = key, 2 = IV, 3 = MAC key
 */
static void pkcs12_kdf(
    const char *password,
    const uint8_t *salt,
    size_t salt_len,
    int iterations,
    int id,
    uint8_t *output,
    size_t output_len)
{
    const int u = 20;  /* SHA-1 output size */
    const int v = 64;  /* SHA-1 block size */
    size_t S_len;
    uint8_t *S;
    size_t pwd_len;
    size_t P_raw_len;
    size_t P_len;
    uint8_t *P;
    size_t I_len;
    uint8_t *I;
    size_t produced;
    uint8_t *A;
    uint8_t *B;
    uint8_t *DI;
    size_t i;
    int j;
    size_t jj;
    int k;
    size_t to_copy;
    
    /* Construct D (diversifier) */
    uint8_t D[64];
    memset(D, id, v);
    
    /* Construct S (salt, padded to v bytes) */
    S_len = ((salt_len + v - 1) / v) * v;
    if (S_len == 0) S_len = v;
    S = calloc(S_len, 1);
    if (!S) return;
    for (i = 0; i < S_len; i++) {
        S[i] = salt_len > 0 ? salt[i % salt_len] : 0;
    }
    
    /* Construct P (password as BMPString, padded to v bytes) */
    pwd_len = password ? strlen(password) : 0;
    P_raw_len = (pwd_len + 1) * 2;  /* UTF-16BE with null */
    P_len = ((P_raw_len + v - 1) / v) * v;
    if (P_len == 0) P_len = v;
    P = calloc(P_len, 1);
    if (!P) { free(S); return; }
    
    for (i = 0; i < pwd_len; i++) {
        P[i*2] = 0;
        P[i*2+1] = (uint8_t)password[i];
    }
    /* Null terminator */
    P[pwd_len*2] = 0;
    P[pwd_len*2+1] = 0;
    
    /* Repeat P to fill P_len */
    for (i = P_raw_len; i < P_len; i++) {
        P[i] = P[i % P_raw_len];
    }
    
    /* Construct I = S || P */
    I_len = S_len + P_len;
    I = malloc(I_len);
    if (!I) { free(S); free(P); return; }
    memcpy(I, S, S_len);
    memcpy(I + S_len, P, P_len);
    
    /* Generate output */
    produced = 0;
    A = malloc(u);
    B = malloc(v);
    DI = malloc(v + I_len);
    
    if (!A || !B || !DI) {
        free(S); free(P); free(I);
        if (A) free(A);
        if (B) free(B);
        if (DI) free(DI);
        return;
    }
    
    while (produced < output_len) {
        /* A = Hash(D || I), iterated */
        memcpy(DI, D, v);
        memcpy(DI + v, I, I_len);
        sha1(DI, v + I_len, A);
        
        for (j = 1; j < iterations; j++) {
            sha1(A, u, A);
        }
        
        /* Copy to output */
        to_copy = output_len - produced;
        if (to_copy > (size_t)u) to_copy = u;
        memcpy(output + produced, A, to_copy);
        produced += to_copy;
        
        if (produced >= output_len) break;
        
        /* Construct B by repeating A */
        for (j = 0; j < v; j++) {
            B[j] = A[j % u];
        }
        
        /* I = I + B + 1 (treating I as concatenation of v-byte integers) */
        for (jj = 0; jj < I_len; jj += v) {
            uint16_t carry = 1;
            uint16_t sum;
            for (k = v - 1; k >= 0; k--) {
                sum = (uint16_t)I[jj + k] + B[k] + carry;
                I[jj + k] = sum & 0xFF;
                carry = sum >> 8;
            }
        }
    }
    
    free(S);
    free(P);
    free(I);
    free(A);
    free(B);
    free(DI);
}

/*============================================================================
 * 3DES-CBC Decryption (for PKCS#12)
 *==========================================================================*/

/* Simple 3DES implementation for PKCS#12 decryption */
/* For production, use a proper crypto library */

/* DES S-boxes */
static const uint8_t DES_SBOX[8][64] = {
    {14,4,13,1,2,15,11,8,3,10,6,12,5,9,0,7,0,15,7,4,14,2,13,1,10,6,12,11,9,5,3,8,
     4,1,14,8,13,6,2,11,15,12,9,7,3,10,5,0,15,12,8,2,4,9,1,7,5,11,3,14,10,0,6,13},
    {15,1,8,14,6,11,3,4,9,7,2,13,12,0,5,10,3,13,4,7,15,2,8,14,12,0,1,10,6,9,11,5,
     0,14,7,11,10,4,13,1,5,8,12,6,9,3,2,15,13,8,10,1,3,15,4,2,11,6,7,12,0,5,14,9},
    {10,0,9,14,6,3,15,5,1,13,12,7,11,4,2,8,13,7,0,9,3,4,6,10,2,8,5,14,12,11,15,1,
     13,6,4,9,8,15,3,0,11,1,2,12,5,10,14,7,1,10,13,0,6,9,8,7,4,15,14,3,11,5,2,12},
    {7,13,14,3,0,6,9,10,1,2,8,5,11,12,4,15,13,8,11,5,6,15,0,3,4,7,2,12,1,10,14,9,
     10,6,9,0,12,11,7,13,15,1,3,14,5,2,8,4,3,15,0,6,10,1,13,8,9,4,5,11,12,7,2,14},
    {2,12,4,1,7,10,11,6,8,5,3,15,13,0,14,9,14,11,2,12,4,7,13,1,5,0,15,10,3,9,8,6,
     4,2,1,11,10,13,7,8,15,9,12,5,6,3,0,14,11,8,12,7,1,14,2,13,6,15,0,9,10,4,5,3},
    {12,1,10,15,9,2,6,8,0,13,3,4,14,7,5,11,10,15,4,2,7,12,9,5,6,1,13,14,0,11,3,8,
     9,14,15,5,2,8,12,3,7,0,4,10,1,13,11,6,4,3,2,12,9,5,15,10,11,14,1,7,6,0,8,13},
    {4,11,2,14,15,0,8,13,3,12,9,7,5,10,6,1,13,0,11,7,4,9,1,10,14,3,5,12,2,15,8,6,
     1,4,11,13,12,3,7,14,10,15,6,8,0,5,9,2,6,11,13,8,1,4,10,7,9,5,0,15,14,2,3,12},
    {13,2,8,4,6,15,11,1,10,9,3,14,5,0,12,7,1,15,13,8,10,3,7,4,12,5,6,11,0,14,9,2,
     7,11,4,1,9,12,14,2,0,6,10,13,15,3,5,8,2,1,14,7,4,10,8,13,15,12,9,0,3,5,6,11}
};

/* DES permutation tables */
static const uint8_t DES_IP[64] = {
    58,50,42,34,26,18,10,2,60,52,44,36,28,20,12,4,
    62,54,46,38,30,22,14,6,64,56,48,40,32,24,16,8,
    57,49,41,33,25,17,9,1,59,51,43,35,27,19,11,3,
    61,53,45,37,29,21,13,5,63,55,47,39,31,23,15,7
};

static const uint8_t DES_FP[64] = {
    40,8,48,16,56,24,64,32,39,7,47,15,55,23,63,31,
    38,6,46,14,54,22,62,30,37,5,45,13,53,21,61,29,
    36,4,44,12,52,20,60,28,35,3,43,11,51,19,59,27,
    34,2,42,10,50,18,58,26,33,1,41,9,49,17,57,25
};

static const uint8_t DES_E[48] = {
    32,1,2,3,4,5,4,5,6,7,8,9,8,9,10,11,12,13,12,13,14,15,16,17,
    16,17,18,19,20,21,20,21,22,23,24,25,24,25,26,27,28,29,28,29,30,31,32,1
};

static const uint8_t DES_P[32] = {
    16,7,20,21,29,12,28,17,1,15,23,26,5,18,31,10,
    2,8,24,14,32,27,3,9,19,13,30,6,22,11,4,25
};

static const uint8_t DES_PC1[56] = {
    57,49,41,33,25,17,9,1,58,50,42,34,26,18,10,2,59,51,43,35,27,19,11,3,60,52,44,36,
    63,55,47,39,31,23,15,7,62,54,46,38,30,22,14,6,61,53,45,37,29,21,13,5,28,20,12,4
};

static const uint8_t DES_PC2[48] = {
    14,17,11,24,1,5,3,28,15,6,21,10,23,19,12,4,26,8,16,7,27,20,13,2,
    41,52,31,37,47,55,30,40,51,45,33,48,44,49,39,56,34,53,46,42,50,36,29,32
};

static const uint8_t DES_SHIFTS[16] = {1,1,2,2,2,2,2,2,1,2,2,2,2,2,2,1};

/* Single DES round */
static uint32_t des_f(uint32_t R, const uint8_t K[6])
{
    /* Expand R to 48 bits */
    uint8_t E[6] = {0};
    uint32_t S_out = 0;
    uint32_t P_out = 0;
    int i;
    int bit;
    int bits;
    int row;
    int col;
    for (i = 0; i < 48; i++) {
        bit = (R >> (32 - DES_E[i])) & 1;
        E[i/8] |= bit << (7 - i%8);
    }
    
    /* XOR with key */
    for (i = 0; i < 6; i++) E[i] ^= K[i];
    
    /* S-box substitution */
    for (i = 0; i < 8; i++) {
        bits = (E[i*6/8] << 8 | E[i*6/8+1]) >> (10 - i*6%8);
        row = ((bits >> 5) & 1) * 2 + (bits & 1);
        col = (bits >> 1) & 0xF;
        S_out = (S_out << 4) | DES_SBOX[i][row * 16 + col];
    }
    
    /* P permutation */
    for (i = 0; i < 32; i++) {
        P_out |= ((S_out >> (32 - DES_P[i])) & 1) << (31 - i);
    }
    
    return P_out;
}

/* Generate DES subkeys */
static void des_keysched(const uint8_t key[8], uint8_t subkeys[16][6])
{
    /* PC1 permutation */
    uint64_t pc1 = 0;
    uint32_t C;
    uint32_t D;
    int i;
    int round;
    int bit;
    uint64_t CD;
    for (i = 0; i < 56; i++) {
        bit = (key[(DES_PC1[i]-1)/8] >> (7 - (DES_PC1[i]-1)%8)) & 1;
        pc1 |= (uint64_t)bit << (55 - i);
    }
    
    C = pc1 >> 28;
    D = pc1 & 0xFFFFFFF;
    
    for (round = 0; round < 16; round++) {
        /* Left rotate */
        for (i = 0; i < DES_SHIFTS[round]; i++) {
            C = ((C << 1) | (C >> 27)) & 0xFFFFFFF;
            D = ((D << 1) | (D >> 27)) & 0xFFFFFFF;
        }
        
        /* PC2 permutation */
        CD = ((uint64_t)C << 28) | D;
        for (i = 0; i < 48; i++) {
            bit = (CD >> (56 - DES_PC2[i])) & 1;
            if (bit) {
                subkeys[round][i/8] |= 1 << (7 - i%8);
            } else {
                subkeys[round][i/8] &= ~(1 << (7 - i%8));
            }
        }
    }
}

/* DES block core (shared by encrypt and decrypt) */
static void des_block_core(const uint8_t in[8], const uint8_t subkeys[16][6],
                           int decrypt, uint8_t out[8])
{
    /* IP permutation */
    uint64_t ip = 0;
    uint32_t L;
    uint32_t R;
    uint64_t RL;
    int i;
    int bit;
    int round;
    uint32_t temp;
    for (i = 0; i < 64; i++) {
        bit = (in[(DES_IP[i]-1)/8] >> (7 - (DES_IP[i]-1)%8)) & 1;
        ip |= (uint64_t)bit << (63 - i);
    }

    L = ip >> 32;
    R = ip & 0xFFFFFFFF;

    /* 16 rounds */
    for (i = 0; i < 16; i++) {
        round = decrypt ? (15 - i) : i;
        temp = R;
        R = L ^ des_f(R, subkeys[round]);
        L = temp;
    }

    /* FP permutation (note: swap L/R) */
    RL = ((uint64_t)R << 32) | L;
    memset(out, 0, 8);
    for (i = 0; i < 64; i++) {
        bit = (RL >> (64 - DES_FP[i])) & 1;
        if (bit)
            out[i/8] |= 1 << (7 - i%8);
    }
}

/* Single DES block encrypt */
static void des_encrypt_block(const uint8_t in[8], const uint8_t subkeys[16][6], uint8_t out[8])
{
    des_block_core(in, subkeys, 0, out);
}

/* Single DES block decrypt */
static void des_decrypt_block(const uint8_t in[8], const uint8_t subkeys[16][6], uint8_t out[8])
{
    des_block_core(in, subkeys, 1, out);
}

/* 3DES-EDE3-CBC decrypt */
static void des3_cbc_decrypt(
    const uint8_t *in, size_t len,
    const uint8_t key[24],
    const uint8_t iv[8],
    uint8_t *out)
{
    uint8_t sk1[16][6], sk2[16][6], sk3[16][6];
    uint8_t prev[8];
    size_t i;
    int j;
    uint8_t t1[8], t2[8];
    memset(sk1, 0, sizeof(sk1));
    memset(sk2, 0, sizeof(sk2));
    memset(sk3, 0, sizeof(sk3));
    des_keysched(key, sk1);
    des_keysched(key + 8, sk2);
    des_keysched(key + 16, sk3);

    memcpy(prev, iv, 8);

    for (i = 0; i < len; i += 8) {

        /* 3DES-EDE3 decrypt: D(K1, E(K2, D(K3, block))) */
        des_decrypt_block(in + i, sk3, t1);
        des_encrypt_block(t1, sk2, t2);
        des_decrypt_block(t2, sk1, out + i);

        /* CBC: XOR with previous ciphertext */
        for (j = 0; j < 8; j++)
            out[i + j] ^= prev[j];

        memcpy(prev, in + i, 8);
    }
}

/*============================================================================
 * Base64 Decoding (for PEM)
 *==========================================================================*/

static const int8_t b64_table[256] = {
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,62,-1,-1,-1,63,
    52,53,54,55,56,57,58,59,60,61,-1,-1,-1,-2,-1,-1,
    -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,
    15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1,
    -1,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,
    41,42,43,44,45,46,47,48,49,50,51,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
};

static size_t base64_decode(const char *src, size_t src_len, uint8_t *dst, size_t dst_len)
{
    size_t out = 0;
    uint32_t accum = 0;
    int bits = 0;
    size_t i;
    int8_t val;
    
    for (i = 0; i < src_len && out < dst_len; i++) {
        val = b64_table[(uint8_t)src[i]];
        if (val == -1) continue;
        if (val == -2) break;
        
        accum = (accum << 6) | val;
        bits += 6;
        
        if (bits >= 8) {
            bits -= 8;
            dst[out++] = (accum >> bits) & 0xFF;
        }
    }
    
    return out;
}

/*============================================================================
 * PKCS#8 Private Key Parsing
 *==========================================================================*/

pdfmake_privkey_t *pdfmake_pkcs8_parse_der(
    pdfmake_arena_t *arena,
    const uint8_t *data,
    size_t len)
{
    pdfmake_asn1_node_t *root;
    pdfmake_asn1_node_t *version;
    pdfmake_asn1_node_t *alg;
    pdfmake_asn1_node_t *key_data;
    pdfmake_asn1_node_t *oid_node;
    char *oid;
    pdfmake_privkey_t *key;
    size_t pos;
    pdfmake_asn1_node_t *rsa_key;
    pdfmake_asn1_node_t *n;
    pdfmake_asn1_node_t *e;
    pdfmake_asn1_node_t *d;
    pdfmake_asn1_node_t *p;
    pdfmake_asn1_node_t *q;
    pdfmake_asn1_node_t *param;
    pdfmake_asn1_node_t *ec_key;
    pdfmake_asn1_node_t *priv;
    pdfmake_asn1_node_t *child;

    if (!arena || !data || len == 0) return NULL;
    
    /* Parse ASN.1 */
    root = pdfmake_asn1_parse(arena, data, len);
    if (!pdfmake_asn1_is_sequence(root)) {
        return NULL;
    }
    
    /* PrivateKeyInfo ::= SEQUENCE {
         version Version,
         privateKeyAlgorithm AlgorithmIdentifier,
         privateKey OCTET STRING,
         attributes [0] IMPLICIT Attributes OPTIONAL } */
    
    version = pdfmake_asn1_child_at(root, 0);
    alg = pdfmake_asn1_child_at(root, 1);
    key_data = pdfmake_asn1_child_at(root, 2);
    
    if (!version || !alg || !key_data) return NULL;
    
    /* Get algorithm OID */
    oid_node = pdfmake_asn1_child_at(alg, 0);
    if (!oid_node) return NULL;
    
    oid = pdfmake_asn1_get_oid_string(arena, oid_node);
    if (!oid) return NULL;
    
    /* Allocate private key structure */
    key = pdfmake_arena_alloc(arena, sizeof(pdfmake_privkey_t));
    if (!key) return NULL;
    memset(key, 0, sizeof(pdfmake_privkey_t));
    
    /* Store raw PKCS#8 */
    key->pkcs8_der = pdfmake_arena_alloc(arena, len);
    if (key->pkcs8_der) {
        memcpy(key->pkcs8_der, data, len);
        key->pkcs8_der_len = len;
    }
    
    if (strcmp(oid, OID_RSA_ENCRYPTION) == 0) {
        key->algorithm = PDFMAKE_PK_RSA;
        
        /* Parse RSA private key from OCTET STRING */
        if (key_data->tag == ASN1_TAG_OCTET_STRING) {
            pos = 0;
            rsa_key = pdfmake_asn1_parse_element(
                arena, key_data->data, key_data->length, &pos);
            
            if (pdfmake_asn1_is_sequence(rsa_key)) {
                /* RSAPrivateKey ::= SEQUENCE {
                     version, modulus, publicExponent, privateExponent,
                     prime1, prime2, exponent1, exponent2, coefficient } */
                
                n = pdfmake_asn1_child_at(rsa_key, 1);  /* modulus */
                e = pdfmake_asn1_child_at(rsa_key, 2);  /* publicExponent */
                d = pdfmake_asn1_child_at(rsa_key, 3);  /* privateExponent */
                p = pdfmake_asn1_child_at(rsa_key, 4);  /* prime1 */
                q = pdfmake_asn1_child_at(rsa_key, 5);  /* prime2 */
                
                if (n && e && d) {
                    key->rsa.modulus = pdfmake_arena_alloc(arena, n->length);
                    if (key->rsa.modulus) {
                        memcpy(key->rsa.modulus, n->data, n->length);
                        key->rsa.modulus_len = n->length;
                    }
                    
                    key->rsa.public_exponent = pdfmake_arena_alloc(arena, e->length);
                    if (key->rsa.public_exponent) {
                        memcpy(key->rsa.public_exponent, e->data, e->length);
                        key->rsa.public_exponent_len = e->length;
                    }
                    
                    key->rsa.private_exponent = pdfmake_arena_alloc(arena, d->length);
                    if (key->rsa.private_exponent) {
                        memcpy(key->rsa.private_exponent, d->data, d->length);
                        key->rsa.private_exponent_len = d->length;
                    }
                    
                    if (p) {
                        key->rsa.prime1 = pdfmake_arena_alloc(arena, p->length);
                        if (key->rsa.prime1) {
                            memcpy(key->rsa.prime1, p->data, p->length);
                            key->rsa.prime1_len = p->length;
                        }
                    }
                    
                    if (q) {
                        key->rsa.prime2 = pdfmake_arena_alloc(arena, q->length);
                        if (key->rsa.prime2) {
                            memcpy(key->rsa.prime2, q->data, q->length);
                            key->rsa.prime2_len = q->length;
                        }
                    }
                }
            }
        }
    } else if (strcmp(oid, OID_EC_PUBLIC_KEY) == 0) {
        key->algorithm = PDFMAKE_PK_ECDSA;
        
        /* Get curve OID from algorithm parameters */
        param = pdfmake_asn1_child_at(alg, 1);
        if (param && param->tag == ASN1_TAG_OID) {
            key->ecdsa.curve_oid = pdfmake_asn1_get_oid_string(arena, param);
            
            if (pdfmake_asn1_oid_equals(param, OID_SECP256R1)) {
                key->ecdsa.curve_bits = 256;
            } else if (pdfmake_asn1_oid_equals(param, OID_SECP384R1)) {
                key->ecdsa.curve_bits = 384;
            } else if (pdfmake_asn1_oid_equals(param, OID_SECP521R1)) {
                key->ecdsa.curve_bits = 521;
            }
        }
        
        /* Parse EC private key from OCTET STRING */
        if (key_data->tag == ASN1_TAG_OCTET_STRING) {
            pos = 0;
            ec_key = pdfmake_asn1_parse_element(
                arena, key_data->data, key_data->length, &pos);
            
            if (pdfmake_asn1_is_sequence(ec_key)) {
                /* ECPrivateKey ::= SEQUENCE {
                     version INTEGER,
                     privateKey OCTET STRING,
                     parameters [0] EXPLICIT ECParameters OPTIONAL,
                     publicKey [1] EXPLICIT BIT STRING OPTIONAL } */
                
                priv = pdfmake_asn1_child_at(ec_key, 1);
                if (priv && priv->tag == ASN1_TAG_OCTET_STRING) {
                    key->ecdsa.private_value = pdfmake_arena_alloc(arena, priv->length);
                    if (key->ecdsa.private_value) {
                        memcpy(key->ecdsa.private_value, priv->data, priv->length);
                        key->ecdsa.private_value_len = priv->length;
                    }
                }
                
                /* Look for public key in [1] */
                child = ec_key->children;
                while (child) {
                    if ((child->tag & ASN1_CLASS_MASK) == ASN1_CLASS_CONTEXT &&
                        (child->tag & 0x1F) == 1) {
                        /* [1] contains BIT STRING with public point */
                        pdfmake_asn1_node_t *pub = child->children;
                        if (pub && pub->tag == ASN1_TAG_BIT_STRING) {
                            const uint8_t *bits;
                            size_t bit_count;
                            if (pdfmake_asn1_get_bit_string(pub, &bits, &bit_count) == 0) {
                                key->ecdsa.public_point = pdfmake_arena_alloc(arena, bit_count / 8);
                                if (key->ecdsa.public_point) {
                                    memcpy(key->ecdsa.public_point, bits, bit_count / 8);
                                    key->ecdsa.public_point_len = bit_count / 8;
                                }
                            }
                        }
                        break;
                    }
                    child = child->next;
                }
            }
        }
    }
    
    return key;
}

pdfmake_privkey_t *pdfmake_privkey_parse_pem(
    pdfmake_arena_t *arena,
    const char *pem,
    size_t len,
    const char *password)
{
    const char *begin;
    const char *end;
    const char *content_start;
    int is_encrypted;
    size_t b64_len;
    size_t max_der_len;
    uint8_t *der;
    size_t der_len;

    if (!arena || !pem || len == 0) return NULL;
    
    /* Find BEGIN marker */
    begin = strstr(pem, "-----BEGIN");
    if (!begin) return NULL;
    
    /* Find END marker */
    end = strstr(begin, "-----END");
    if (!end) return NULL;
    
    /* Skip to content */
    content_start = strchr(begin, '\n');
    if (!content_start) return NULL;
    content_start++;
    
    /* Check for encryption headers */
    is_encrypted = 0;
    if (strstr(begin, "ENCRYPTED") != NULL) {
        is_encrypted = 1;
    }
    
    /* Find end of headers */
    while (content_start < end && *content_start != '\n' && 
           (content_start[0] == 'P' || content_start[0] == 'D')) {
        /* Skip header lines like "Proc-Type:" and "DEK-Info:" */
        content_start = strchr(content_start, '\n');
        if (content_start) content_start++;
    }
    
    /* Skip blank line */
    if (content_start && *content_start == '\n') content_start++;
    
    /* Decode base64 */
    b64_len = end - content_start;
    max_der_len = (b64_len * 3) / 4 + 4;
    der = pdfmake_arena_alloc(arena, max_der_len);
    if (!der) return NULL;
    
    der_len = base64_decode(content_start, b64_len, der, max_der_len);
    if (der_len == 0) return NULL;
    
    if (is_encrypted && password) {
        /* TODO: Implement PKCS#5/PKCS#8 decryption */
        /* For now, return NULL for encrypted keys */
        return NULL;
    }
    
    return pdfmake_pkcs8_parse_der(arena, der, der_len);
}

pdfmake_privkey_t *pdfmake_privkey_load_file(
    pdfmake_arena_t *arena,
    const char *path,
    const char *password)
{
    FILE *f;
    long size;
    uint8_t *data;

    if (!arena || !path) return NULL;
    
    f = fopen(path, "rb");
    if (!f) return NULL;
    
    fseek(f, 0, SEEK_END);
    size = ftell(f);
    fseek(f, 0, SEEK_SET);
    
    if (size <= 0 || size > 1024 * 1024) {
        fclose(f);
        return NULL;
    }
    
    data = pdfmake_arena_alloc(arena, size);
    if (!data) {
        fclose(f);
        return NULL;
    }
    
    if (fread(data, 1, size, f) != (size_t)size) {
        fclose(f);
        return NULL;
    }
    fclose(f);
    
    /* Check for PEM format */
    if (size > 10 && memcmp(data, "-----BEGIN", 10) == 0) {
        return pdfmake_privkey_parse_pem(arena, (const char *)data, size, password);
    }
    
    /* Assume DER */
    return pdfmake_pkcs8_parse_der(arena, data, size);
}

/*============================================================================
 * PKCS#12 Parsing (simplified)
 *==========================================================================*/

/*============================================================================
 * PBE Decryption Helpers
 *==========================================================================*/

/* Decrypt data encrypted with pbeWithSHAAnd3-KeyTripleDES-CBC (OID 1.2.840.113549.1.12.1.3)
 * AlgorithmIdentifier contains: SEQUENCE { OID, SEQUENCE { salt OCTET STRING, iterations INTEGER } }
 */
static uint8_t *pbe_sha1_3des_decrypt(
    pdfmake_arena_t *arena,
    const char *password,
    const pdfmake_asn1_node_t *alg_id,
    const uint8_t *ciphertext,
    size_t ct_len,
    size_t *out_len)
{
    pdfmake_asn1_node_t *params;
    pdfmake_asn1_node_t *salt_node;
    pdfmake_asn1_node_t *iter_node;
    /* Parse algorithm parameters: SEQUENCE { salt OCTET STRING, iterations INTEGER } */
    int64_t iterations;
    uint8_t key[24], iv[8];
    uint8_t *plain;
    uint8_t pad;
    size_t i;

    params = pdfmake_asn1_child_at(alg_id, 1);
    if (!pdfmake_asn1_is_sequence(params))
        return NULL;

    salt_node = pdfmake_asn1_child_at(params, 0);
    iter_node = pdfmake_asn1_child_at(params, 1);
    if (!salt_node || !iter_node) return NULL;

    if (pdfmake_asn1_get_int64(iter_node, &iterations) != 0 || iterations <= 0)
        return NULL;

    /* Derive 24-byte key + 8-byte IV using PKCS#12 KDF */
    pkcs12_kdf(password, salt_node->data, salt_node->length,
               (int)iterations, 1 /* key */, key, 24);
    pkcs12_kdf(password, salt_node->data, salt_node->length,
               (int)iterations, 2 /* IV */, iv, 8);

    /* Decrypt */
    if (ct_len == 0 || ct_len % 8 != 0) return NULL;

    plain = pdfmake_arena_alloc(arena, ct_len);
    if (!plain) return NULL;

    des3_cbc_decrypt(ciphertext, ct_len, key, iv, plain);

    /* Remove PKCS#7 padding */
    pad = plain[ct_len - 1];
    if (pad == 0 || pad > 8) return NULL;
    for (i = 0; i < pad; i++) {
        if (plain[ct_len - 1 - i] != pad) return NULL;
    }
    *out_len = ct_len - pad;
    return plain;
}

/* Decrypt data encrypted with PBES2 (PBKDF2 + AES-CBC) */
static uint8_t *pbes2_decrypt(
    pdfmake_arena_t *arena,
    const char *password,
    const pdfmake_asn1_node_t *alg_id,
    const uint8_t *ciphertext,
    size_t ct_len,
    size_t *out_len)
{
    pdfmake_asn1_node_t *params;
    pdfmake_asn1_node_t *kdf;
    pdfmake_asn1_node_t *enc;
    pdfmake_asn1_node_t *kdf_oid;
    pdfmake_asn1_node_t *kdf_params;
    pdfmake_asn1_node_t *salt_node;
    pdfmake_asn1_node_t *iter_node;
    int64_t iterations;
    pdfmake_asn1_node_t *enc_oid;
    char *enc_oid_str;
    size_t key_len;
    pdfmake_asn1_node_t *enc_params;
    size_t pwd_len;
    uint8_t dk[32];
    size_t dk_produced;
    uint32_t block_num;
    uint8_t U[20], T[20];
    uint8_t ipad[64], opad[64];
    size_t j;
    uint8_t pwd_hash[20];
    uint8_t be32[4];
    sha1_ctx_t ctx;
    int64_t jj;
    uint8_t prev[20];
    int k;
    size_t to_copy;
    uint8_t *plain;
    int plain_len;

    /* PBES2-params ::= SEQUENCE { keyDerivationFunc AlgorithmIdentifier, encryptionScheme AlgorithmIdentifier } */
    params = pdfmake_asn1_child_at(alg_id, 1);
    if (!pdfmake_asn1_is_sequence(params))
        return NULL;

    kdf = pdfmake_asn1_child_at(params, 0);
    enc = pdfmake_asn1_child_at(params, 1);
    if (!kdf || !enc) return NULL;
    if (!pdfmake_asn1_is_sequence(kdf)) return NULL;
    if (!pdfmake_asn1_is_sequence(enc)) return NULL;

    /* Check KDF is PBKDF2 */
    kdf_oid = pdfmake_asn1_child_at(kdf, 0);
    if (!kdf_oid || !pdfmake_asn1_oid_equals(kdf_oid, OID_PBKDF2))
        return NULL;

    /* PBKDF2-params ::= SEQUENCE { salt OCTET STRING, iterationCount INTEGER,
       keyLength INTEGER OPTIONAL, prf AlgorithmIdentifier DEFAULT hmacWithSHA1 } */
    kdf_params = pdfmake_asn1_child_at(kdf, 1);
    if (!kdf_params) return NULL;

    salt_node = pdfmake_asn1_child_at(kdf_params, 0);
    iter_node = pdfmake_asn1_child_at(kdf_params, 1);
    if (!salt_node || !iter_node) return NULL;

    if (pdfmake_asn1_get_int64(iter_node, &iterations) != 0) return NULL;

    /* Determine encryption scheme and key length */
    enc_oid = pdfmake_asn1_child_at(enc, 0);
    if (!enc_oid) return NULL;

    enc_oid_str = pdfmake_asn1_get_oid_string(arena, enc_oid);
    if (!enc_oid_str) return NULL;

    if (strcmp(enc_oid_str, OID_AES256_CBC) == 0) key_len = 32;
    else if (strcmp(enc_oid_str, OID_AES192_CBC) == 0) key_len = 24;
    else if (strcmp(enc_oid_str, OID_AES128_CBC) == 0) key_len = 16;
    else return NULL;  /* unsupported cipher */

    /* Get IV from encryption scheme params */
    enc_params = pdfmake_asn1_child_at(enc, 1);
    if (!enc_params || enc_params->tag != ASN1_TAG_OCTET_STRING || enc_params->length != 16)
        return NULL;

    /* PBKDF2: derive key using HMAC-SHA1 (default PRF)
     * For simplicity, use PKCS#12 KDF as a stand-in when PBKDF2 is needed.
     * True PBKDF2 = HMAC-SHA256 iterated — implement proper PBKDF2 here. */
    pwd_len = password ? strlen(password) : 0;

    /* PBKDF2 with HMAC-SHA1 */
    /* F(Password, Salt, c, i) = U1 ^ U2 ^ ... ^ Uc
       U1 = PRF(Password, Salt || INT(i))  where PRF = HMAC-SHA1 */
    {
        dk_produced = 0;
        block_num = 1;
        while (dk_produced < key_len) {
            /* U1 = HMAC-SHA1(password, salt || block_num_be32) */
            /* Build HMAC-SHA1 key pad */
            memset(ipad, 0x36, 64);
            memset(opad, 0x5C, 64);
            for (j = 0; j < pwd_len && j < 64; j++) {
                ipad[j] ^= (uint8_t)password[j];
                opad[j] ^= (uint8_t)password[j];
            }
            if (pwd_len > 64) {
                /* Hash the password first */
                sha1((const uint8_t *)password, pwd_len, pwd_hash);
                memset(ipad, 0x36, 64);
                memset(opad, 0x5C, 64);
                for (j = 0; j < 20; j++) {
                    ipad[j] ^= pwd_hash[j];
                    opad[j] ^= pwd_hash[j];
                }
            }

            /* U1 = HMAC(password, salt || be32(block_num)) */
            be32[0] = (block_num >> 24) & 0xFF;
            be32[1] = (block_num >> 16) & 0xFF;
            be32[2] = (block_num >> 8) & 0xFF;
            be32[3] = block_num & 0xFF;

            sha1_init(&ctx);
            sha1_update(&ctx, ipad, 64);
            sha1_update(&ctx, salt_node->data, salt_node->length);
            sha1_update(&ctx, be32, 4);
            sha1_final(&ctx, U);

            sha1_init(&ctx);
            sha1_update(&ctx, opad, 64);
            sha1_update(&ctx, U, 20);
            sha1_final(&ctx, U);

            memcpy(T, U, 20);

            /* Subsequent iterations */
            for (jj = 1; jj < iterations; jj++) {
                memcpy(prev, U, 20);

                sha1_init(&ctx);
                sha1_update(&ctx, ipad, 64);
                sha1_update(&ctx, prev, 20);
                sha1_final(&ctx, U);

                sha1_init(&ctx);
                sha1_update(&ctx, opad, 64);
                sha1_update(&ctx, U, 20);
                sha1_final(&ctx, U);

                for (k = 0; k < 20; k++)
                    T[k] ^= U[k];
            }

            to_copy = key_len - dk_produced;
            if (to_copy > 20) to_copy = 20;
            memcpy(dk + dk_produced, T, to_copy);
            dk_produced += to_copy;
            block_num++;
        }
    }

    /* AES-CBC decrypt */
    if (ct_len == 0 || ct_len % 16 != 0) return NULL;

    plain = pdfmake_arena_alloc(arena, ct_len);
    if (!plain) return NULL;

    plain_len = pdfmake_aes_cbc_decrypt(dk, key_len, enc_params->data,
                                        ciphertext, ct_len, plain);
    if (plain_len < 0) return NULL;

    *out_len = (size_t)plain_len;
    return plain;
}

/* Decrypt encrypted content using detected algorithm */
static uint8_t *pbe_decrypt(
    pdfmake_arena_t *arena,
    const char *password,
    const pdfmake_asn1_node_t *alg_id,
    const uint8_t *ciphertext,
    size_t ct_len,
    size_t *out_len)
{
    pdfmake_asn1_node_t *oid_node;
    char *oid;

    oid_node = pdfmake_asn1_child_at(alg_id, 0);
    if (!oid_node) return NULL;

    oid = pdfmake_asn1_get_oid_string(arena, oid_node);
    if (!oid) return NULL;

    if (strcmp(oid, OID_PBE_SHA1_3DES) == 0 ||
        strcmp(oid, OID_PBE_SHA1_2DES) == 0) {
        return pbe_sha1_3des_decrypt(arena, password, alg_id,
                                     ciphertext, ct_len, out_len);
    } else if (strcmp(oid, OID_PBES2) == 0) {
        return pbes2_decrypt(arena, password, alg_id,
                             ciphertext, ct_len, out_len);
    }

    return NULL;  /* unsupported PBE algorithm */
}

/*============================================================================
 * SafeBag Processing
 *==========================================================================*/

/* Process a single SafeBag and populate identity fields */
static void process_safe_bag(
    pdfmake_arena_t *arena,
    const char *password,
    pdfmake_asn1_node_t *bag,
    pdfmake_signing_identity_t *identity)
{
    pdfmake_asn1_node_t *bag_oid;
    pdfmake_asn1_node_t *bag_value_wrapper;
    char *oid;
    pdfmake_asn1_node_t *bag_value;
    pdfmake_asn1_node_t *enc_alg;
    pdfmake_asn1_node_t *enc_data;
    size_t plain_len;
    uint8_t *plain;
    pdfmake_asn1_node_t *cert_id;
    pdfmake_asn1_node_t *cert_val_wrapper;
    pdfmake_asn1_node_t *cert_octet;

    /* SafeBag ::= SEQUENCE { bagId OID, bagValue [0] EXPLICIT ANY, bagAttributes SET OF OPTIONAL } */
    if (!pdfmake_asn1_is_sequence(bag)) return;

    bag_oid = pdfmake_asn1_child_at(bag, 0);
    bag_value_wrapper = pdfmake_asn1_child_at(bag, 1);
    if (!bag_oid || !bag_value_wrapper) return;

    oid = pdfmake_asn1_get_oid_string(arena, bag_oid);
    if (!oid) return;

    /* The [0] EXPLICIT wrapper: get inner content */
    bag_value = bag_value_wrapper->children;
    if (!bag_value) return;

    if (strcmp(oid, OID_PKCS12_SHROUDEDKEYBAG) == 0 && !identity->privkey) {
        /* PKCS8ShroudedKeyBag — EncryptedPrivateKeyInfo ::= SEQUENCE {
             encryptionAlgorithm AlgorithmIdentifier,
             encryptedData OCTET STRING } */
        if (!pdfmake_asn1_is_sequence(bag_value)) return;

        enc_alg = pdfmake_asn1_child_at(bag_value, 0);
        enc_data = pdfmake_asn1_child_at(bag_value, 1);
        if (!enc_alg || !enc_data) return;
        if (enc_data->tag != ASN1_TAG_OCTET_STRING) return;

        plain_len = 0;
        plain = pbe_decrypt(arena, password, enc_alg,
                            enc_data->data, enc_data->length, &plain_len);
        if (plain && plain_len > 0) {
            identity->privkey = pdfmake_pkcs8_parse_der(arena, plain, plain_len);
        }
    }
    else if (strcmp(oid, OID_PKCS12_KEYBAG) == 0 && !identity->privkey) {
        /* Unencrypted PKCS#8 PrivateKeyInfo */
        if (pdfmake_asn1_is_sequence(bag_value)) {
            identity->privkey = pdfmake_pkcs8_parse_der(arena,
                                                        bag_value->data - 4, /* approx: include tag+len */
                                                        bag_value->length + 4);
            /* Better: re-serialize from raw data range */
            /* The bag_value node's data points to the content, but we need full DER.
               Use the original data pointer range from bag_value_wrapper. */
            identity->privkey = pdfmake_pkcs8_parse_der(arena,
                                                        bag_value->data,
                                                        bag_value->length);
        }
    }
    else if (strcmp(oid, OID_PKCS12_CERTBAG) == 0 && !identity->cert) {
        /* CertBag ::= SEQUENCE { certId OID, certValue [0] EXPLICIT ANY } */
        if (!pdfmake_asn1_is_sequence(bag_value)) return;

        cert_id = pdfmake_asn1_child_at(bag_value, 0);
        cert_val_wrapper = pdfmake_asn1_child_at(bag_value, 1);
        if (!cert_id || !cert_val_wrapper) return;

        /* Check it's an X.509 certificate */
        if (!pdfmake_asn1_oid_equals(cert_id, OID_CERT_X509)) return;

        /* The [0] wrapper contains an OCTET STRING with DER-encoded cert */
        cert_octet = cert_val_wrapper->children;
        if (!cert_octet || cert_octet->tag != ASN1_TAG_OCTET_STRING) return;

        identity->cert = pdfmake_x509_parse_der(arena,
                                                 cert_octet->data,
                                                 cert_octet->length);
    }
}

/* Process SafeContents (SEQUENCE OF SafeBag) from decrypted data */
static void process_safe_contents(
    pdfmake_arena_t *arena,
    const char *password,
    const uint8_t *data,
    size_t len,
    pdfmake_signing_identity_t *identity)
{
    size_t pos = 0;
    pdfmake_asn1_node_t *safe_contents = pdfmake_asn1_parse_element(
        arena, data, len, &pos);
    pdfmake_asn1_node_t *bag;

    if (!pdfmake_asn1_is_sequence(safe_contents))
        return;

    /* Iterate SafeBag items */
    for (bag = safe_contents->children; bag; bag = bag->next) {
        process_safe_bag(arena, password, bag, identity);
    }
}

/*============================================================================
 * Main PKCS#12 Parser
 *==========================================================================*/

pdfmake_signing_identity_t *pdfmake_pkcs12_parse(
    pdfmake_arena_t *arena,
    const uint8_t *data,
    size_t len,
    const char *password)
{
    pdfmake_asn1_node_t *pfx;
    pdfmake_asn1_node_t *version;
    pdfmake_asn1_node_t *auth_safe;
    int64_t ver;
    pdfmake_asn1_node_t *content_type;
    pdfmake_asn1_node_t *content;
    pdfmake_asn1_node_t *octet_string;
    size_t pos;
    pdfmake_asn1_node_t *auth_safe_seq;
    pdfmake_signing_identity_t *identity;
    pdfmake_asn1_node_t *ci;
    pdfmake_asn1_node_t *ci_type;
    pdfmake_asn1_node_t *ci_content;
    char *ci_oid;
    pdfmake_asn1_node_t *os;
    pdfmake_asn1_node_t *ed;
    pdfmake_asn1_node_t *ed_version;
    pdfmake_asn1_node_t *eci;
    pdfmake_asn1_node_t *eci_type;
    pdfmake_asn1_node_t *eci_alg;
    pdfmake_asn1_node_t *eci_data;
    size_t plain_len;
    uint8_t *plain;

    if (!arena || !data || len == 0) return NULL;

    /* Parse PFX structure */
    /* PFX ::= SEQUENCE {
         version INTEGER,
         authSafe ContentInfo,
         macData MacData OPTIONAL } */

    pfx = pdfmake_asn1_parse(arena, data, len);
    if (!pdfmake_asn1_is_sequence(pfx))
        return NULL;

    version = pdfmake_asn1_child_at(pfx, 0);
    auth_safe = pdfmake_asn1_child_at(pfx, 1);
    if (!version || !auth_safe) return NULL;

    if (pdfmake_asn1_get_int64(version, &ver) != 0 || ver != 3)
        return NULL;

    /* Parse outer ContentInfo: must be pkcs7-data */
    if (!pdfmake_asn1_is_sequence(auth_safe))
        return NULL;

    content_type = pdfmake_asn1_child_at(auth_safe, 0);
    content = pdfmake_asn1_child_at(auth_safe, 1);
    if (!content_type || !content) return NULL;

    if (!pdfmake_asn1_oid_equals(content_type, OID_PKCS7_DATA))
        return NULL;

    /* The [0] wrapper contains OCTET STRING */
    octet_string = content->children;
    if (!octet_string || octet_string->tag != ASN1_TAG_OCTET_STRING)
        return NULL;

    /* Parse AuthenticatedSafe (SEQUENCE OF ContentInfo) */
    pos = 0;
    auth_safe_seq = pdfmake_asn1_parse_element(
        arena, octet_string->data, octet_string->length, &pos);

    if (!pdfmake_asn1_is_sequence(auth_safe_seq))
        return NULL;

    /* Create identity to populate */
    identity = pdfmake_arena_alloc(
        arena, sizeof(pdfmake_signing_identity_t));
    if (!identity) return NULL;
    memset(identity, 0, sizeof(pdfmake_signing_identity_t));
    identity->arena = arena;

    /* Process each ContentInfo in the AuthenticatedSafe */
    for (ci = auth_safe_seq->children; ci; ci = ci->next) {
        if (!pdfmake_asn1_is_sequence(ci)) continue;

        ci_type = pdfmake_asn1_child_at(ci, 0);
        ci_content = pdfmake_asn1_child_at(ci, 1);
        if (!ci_type || !ci_content) continue;

        ci_oid = pdfmake_asn1_get_oid_string(arena, ci_type);
        if (!ci_oid) continue;

        if (strcmp(ci_oid, OID_PKCS7_DATA) == 0) {
            /* Unencrypted SafeContents — wrapped in [0] EXPLICIT { OCTET STRING } */
            os = ci_content->children;
            if (!os || os->tag != ASN1_TAG_OCTET_STRING) continue;

            process_safe_contents(arena, password,
                                  os->data, os->length, identity);
        }
        else if (strcmp(ci_oid, OID_PKCS7_ENCRYPTED) == 0) {
            /* EncryptedData ContentInfo:
               [0] EXPLICIT { EncryptedData ::= SEQUENCE {
                 version INTEGER,
                 encryptedContentInfo EncryptedContentInfo } }
               EncryptedContentInfo ::= SEQUENCE {
                 contentType OID,
                 contentEncryptionAlgorithm AlgorithmIdentifier,
                 encryptedContent [0] IMPLICIT OCTET STRING } */
            ed = ci_content->children;
            if (!pdfmake_asn1_is_sequence(ed))
                continue;

            ed_version = pdfmake_asn1_child_at(ed, 0);
            eci = pdfmake_asn1_child_at(ed, 1);
            (void)ed_version;
            if (!pdfmake_asn1_is_sequence(eci))
                continue;

            eci_type = pdfmake_asn1_child_at(eci, 0);
            eci_alg = pdfmake_asn1_child_at(eci, 1);
            eci_data = pdfmake_asn1_child_at(eci, 2);
            (void)eci_type;
            if (!eci_alg || !eci_data) continue;

            /* eci_data is [0] IMPLICIT OCTET STRING (tag 0x80 or 0xA0) */
            /* Its data/length contain the ciphertext */
            plain_len = 0;
            plain = pbe_decrypt(arena, password, eci_alg,
                                eci_data->data, eci_data->length,
                                &plain_len);
            if (plain && plain_len > 0) {
                process_safe_contents(arena, password,
                                      plain, plain_len, identity);
            }
        }
    }

    /* Return identity only if we got at least a key or cert */
    if (!identity->privkey && !identity->cert)
        return NULL;

    return identity;
}

pdfmake_signing_identity_t *pdfmake_pkcs12_load_file(
    pdfmake_arena_t *arena,
    const char *path,
    const char *password)
{
    FILE *f;
    long size;
    uint8_t *data;

    if (!arena || !path) return NULL;
    
    f = fopen(path, "rb");
    if (!f) return NULL;
    
    fseek(f, 0, SEEK_END);
    size = ftell(f);
    fseek(f, 0, SEEK_SET);
    
    if (size <= 0 || size > 10 * 1024 * 1024) {  /* Max 10MB */
        fclose(f);
        return NULL;
    }
    
    data = pdfmake_arena_alloc(arena, size);
    if (!data) {
        fclose(f);
        return NULL;
    }
    
    if (fread(data, 1, size, f) != (size_t)size) {
        fclose(f);
        return NULL;
    }
    fclose(f);
    
    return pdfmake_pkcs12_parse(arena, data, size, password);
}

pdfmake_signing_identity_t *pdfmake_signing_identity_create(
    pdfmake_arena_t *arena,
    pdfmake_privkey_t *key,
    pdfmake_x509_cert_t *cert,
    pdfmake_cert_chain_t *chain)
{
    pdfmake_signing_identity_t *identity;

    if (!arena || !key || !cert) return NULL;
    
    identity = pdfmake_arena_alloc(arena, sizeof(pdfmake_signing_identity_t));
    if (!identity) return NULL;
    
    identity->arena = arena;
    identity->privkey = key;
    identity->cert = cert;
    identity->chain = chain;
    
    return identity;
}

int pdfmake_privkey_bits(const pdfmake_privkey_t *key)
{
    if (!key) return 0;
    
    switch (key->algorithm) {
        case PDFMAKE_PK_RSA:
            /* RSA key size is modulus size in bits */
            if (key->rsa.modulus && key->rsa.modulus_len > 0) {
                /* Skip leading zero byte if present */
                size_t len = key->rsa.modulus_len;
                const uint8_t *mod = key->rsa.modulus;
                if (len > 0 && mod[0] == 0) {
                    mod++;
                    len--;
                }
                return len * 8;
            }
            break;
            
        case PDFMAKE_PK_ECDSA:
            return key->ecdsa.curve_bits;
            
        default:
            break;
    }
    
    return 0;
}

int pdfmake_privkey_matches_cert(
    const pdfmake_privkey_t *key,
    const pdfmake_x509_cert_t *cert)
{
    if (!key || !cert) return 0;
    
    /* Check algorithm match */
    if (key->algorithm != cert->pubkey.algorithm) return 0;
    
    switch (key->algorithm) {
        case PDFMAKE_PK_RSA:
            /* Compare modulus */
            if (key->rsa.modulus_len != cert->pubkey.rsa.modulus_len) return 0;
            if (memcmp(key->rsa.modulus, cert->pubkey.rsa.modulus, 
                       key->rsa.modulus_len) != 0) return 0;
            return 1;
            
        case PDFMAKE_PK_ECDSA:
            /* Compare curve and public point */
            if (key->ecdsa.curve_bits != cert->pubkey.ecdsa.curve_bits) return 0;
            /* Would need to derive public point from private key to fully verify */
            return 1;
            
        default:
            break;
    }
    
    return 0;
}

void pdfmake_privkey_free(pdfmake_privkey_t *key)
{
    if (!key) return;
    
    /* Securely wipe sensitive data */
    if (key->algorithm == PDFMAKE_PK_RSA) {
        if (key->rsa.private_exponent) {
            memset(key->rsa.private_exponent, 0, key->rsa.private_exponent_len);
        }
        if (key->rsa.prime1) {
            memset(key->rsa.prime1, 0, key->rsa.prime1_len);
        }
        if (key->rsa.prime2) {
            memset(key->rsa.prime2, 0, key->rsa.prime2_len);
        }
    } else if (key->algorithm == PDFMAKE_PK_ECDSA) {
        if (key->ecdsa.private_value) {
            memset(key->ecdsa.private_value, 0, key->ecdsa.private_value_len);
        }
    }
    
    if (key->pkcs8_der) {
        memset(key->pkcs8_der, 0, key->pkcs8_der_len);
    }
    
    /* If from arena, arena cleanup handles deallocation */
}

void pdfmake_signing_identity_free(pdfmake_signing_identity_t *id)
{
    if (!id) return;
    
    if (id->privkey) {
        pdfmake_privkey_free(id->privkey);
    }
    
    /* If from arena, arena cleanup handles deallocation */
}
