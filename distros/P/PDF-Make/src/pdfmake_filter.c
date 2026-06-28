/*
 * pdfmake_filter.c — Stream filter implementation
 *
 * Implements FlateDecode (DEFLATE + zlib) and predictor functions.
 * RFC 1950 (zlib), RFC 1951 (DEFLATE), PDF §7.4.4
 */

#include "pdfmake_filter.h"
#include <string.h>
#include <stdlib.h>

/*============================================================================
 * Adler-32 (RFC 1950)
 *==========================================================================*/

#define ADLER_MOD 65521

uint32_t pdfmake_adler32(const uint8_t *data, size_t len)
{
    return pdfmake_adler32_update(1, data, len);
}

uint32_t pdfmake_adler32_update(uint32_t adler, const uint8_t *data, size_t len)
{
    uint32_t a = adler & 0xFFFF;
    uint32_t b = (adler >> 16) & 0xFFFF;

    /* Process in chunks to avoid overflow */
    while (len > 0) {
        size_t chunk = len > 5552 ? 5552 : len;
        len -= chunk;

        while (chunk--) {
            a += *data++;
            b += a;
        }

        a %= ADLER_MOD;
        b %= ADLER_MOD;
    }

    return (b << 16) | a;
}

/*============================================================================
 * Flate params
 *==========================================================================*/

void pdfmake_flate_params_init(pdfmake_flate_params_t *params)
{
    if (!params) return;
    params->predictor = 1;
    params->colors = 1;
    params->bits_per_comp = 8;
    params->columns = 1;
    params->early_change = 1;
}

pdfmake_err_t pdfmake_flate_params_from_dict(pdfmake_flate_params_t *params,
                                             const pdfmake_obj_t *dict)
{
    pdfmake_flate_params_init(params);
    /* Dict-based params parsing deferred - requires arena for name interning.
     * For now we use default params. Full implementation in later phase. */
    (void)dict;
    return PDFMAKE_OK;
}

/*============================================================================
 * DEFLATE bit reader
 *==========================================================================*/

typedef struct {
    const uint8_t *data;
    size_t len;
    size_t pos;
    uint32_t bits;
    int nbits;
} bitreader_t;

static void bitreader_init(bitreader_t *br, const uint8_t *data, size_t len)
{
    br->data = data;
    br->len = len;
    br->pos = 0;
    br->bits = 0;
    br->nbits = 0;
}

static int bitreader_read(bitreader_t *br, int n)
{
    int val;
    while (br->nbits < n) {
        if (br->pos >= br->len) return -1;
        br->bits |= (uint32_t)br->data[br->pos++] << br->nbits;
        br->nbits += 8;
    }

    val = br->bits & ((1 << n) - 1);
    br->bits >>= n;
    br->nbits -= n;
    return val;
}

/* Reserved for dynamic Huffman tree decoding in future phases */
__attribute__((unused))
static int bitreader_read_rev(bitreader_t *br, int n)
{
    int val;
    int rev;
    int i;
    val = bitreader_read(br, n);
    if (val < 0) return -1;

    /* Reverse bits */
    rev = 0;
    for (i = 0; i < n; i++) {
        rev = (rev << 1) | (val & 1);
        val >>= 1;
    }
    return rev;
}

/*============================================================================
 * DEFLATE Huffman tables
 *==========================================================================*/

#define HUFFMAN_MAX_BITS 15
#define HUFFMAN_MAX_CODES 288

typedef struct {
    uint16_t counts[HUFFMAN_MAX_BITS + 1];
    uint16_t symbols[HUFFMAN_MAX_CODES];
} huffman_t;

/* Build Huffman table from code lengths */
static int huffman_build(huffman_t *h, const uint8_t *lengths, int n)
{
    int i;
    uint16_t offsets[HUFFMAN_MAX_BITS + 1];
    int total;
    memset(h->counts, 0, sizeof(h->counts));

    /* Count code lengths */
    for (i = 0; i < n; i++) {
        if (lengths[i] > HUFFMAN_MAX_BITS) return -1;
        h->counts[lengths[i]]++;
    }
    h->counts[0] = 0;

    /* Compute symbol table offsets (cumulative counts) */
    total = 0;
    for (i = 1; i <= HUFFMAN_MAX_BITS; i++) {
        offsets[i] = total;
        total += h->counts[i];
    }

    /* Build symbol table - symbols sorted by code length then symbol value */
    for (i = 0; i < n; i++) {
        if (lengths[i] > 0) {
            h->symbols[offsets[lengths[i]]++] = i;
        }
    }

    return 0;
}

/* Decode one symbol using Huffman table */
static int huffman_decode(huffman_t *h, bitreader_t *br)
{
    int code = 0;
    int first = 0;
    int index = 0;
    int len;

    for (len = 1; len <= HUFFMAN_MAX_BITS; len++) {
        int bit = bitreader_read(br, 1);
        int count;
        if (bit < 0) return -1;

        code = (code << 1) | bit;
        count = h->counts[len];

        if (code - first < count) {
            return h->symbols[index + (code - first)];
        }

        index += count;
        first = (first + count) << 1;
    }

    return -1; /* Invalid code */
}

/*============================================================================
 * DEFLATE fixed Huffman codes
 *==========================================================================*/

static huffman_t fixed_lit_len;
static huffman_t fixed_dist;
static int fixed_tables_built = 0;

static void build_fixed_tables(void)
{
    int i;
    uint8_t lit_lengths[288];
    uint8_t dist_lengths[32];
    if (fixed_tables_built) return;

    /* Literal/length codes: 0-143=8 bits, 144-255=9 bits, 256-279=7 bits, 280-287=8 bits */
    for (i = 0; i <= 143; i++) lit_lengths[i] = 8;
    for (i = 144; i <= 255; i++) lit_lengths[i] = 9;
    for (i = 256; i <= 279; i++) lit_lengths[i] = 7;
    for (i = 280; i <= 287; i++) lit_lengths[i] = 8;

    /* Distance codes: all 5 bits */
    for (i = 0; i < 32; i++) dist_lengths[i] = 5;

    huffman_build(&fixed_lit_len, lit_lengths, 288);
    huffman_build(&fixed_dist, dist_lengths, 32);

    fixed_tables_built = 1;
}

/*============================================================================
 * DEFLATE length/distance tables (RFC 1951)
 *==========================================================================*/

static const int length_base[29] = {
    3, 4, 5, 6, 7, 8, 9, 10, 11, 13,
    15, 17, 19, 23, 27, 31, 35, 43, 51, 59,
    67, 83, 99, 115, 131, 163, 195, 227, 258
};

static const int length_extra[29] = {
    0, 0, 0, 0, 0, 0, 0, 0, 1, 1,
    1, 1, 2, 2, 2, 2, 3, 3, 3, 3,
    4, 4, 4, 4, 5, 5, 5, 5, 0
};

static const int dist_base[30] = {
    1, 2, 3, 4, 5, 7, 9, 13, 17, 25,
    33, 49, 65, 97, 129, 193, 257, 385, 513, 769,
    1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577
};

static const int dist_extra[30] = {
    0, 0, 0, 0, 1, 1, 2, 2, 3, 3,
    4, 4, 5, 5, 6, 6, 7, 7, 8, 8,
    9, 9, 10, 10, 11, 11, 12, 12, 13, 13
};

/* Code length code order (for dynamic Huffman) */
static const int cl_order[19] = {
    16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15
};

/*============================================================================
 * DEFLATE decoder
 *==========================================================================*/

static pdfmake_err_t inflate_block(bitreader_t *br, huffman_t *hl, huffman_t *hd,
                                   pdfmake_buf_t *out)
{
    int sym;
    int len;
    int extra;
    int dist_sym;
    int dist;
    int i;
    uint8_t byte;
    for (;;) {
        sym = huffman_decode(hl, br);
        if (sym < 0) return PDFMAKE_ECORRUPT;

        if (sym < 256) {
            /* Literal byte */
            if (pdfmake_buf_append_byte(out, (uint8_t)sym) != PDFMAKE_OK)
                return PDFMAKE_ENOMEM;
        }
        else if (sym == 256) {
            /* End of block */
            return PDFMAKE_OK;
        }
        else {
            /* Length/distance pair */
            sym -= 257;
            if (sym >= 29) return PDFMAKE_ECORRUPT;

            len = length_base[sym];
            if (length_extra[sym] > 0) {
                extra = bitreader_read(br, length_extra[sym]);
                if (extra < 0) return PDFMAKE_ECORRUPT;
                len += extra;
            }

            dist_sym = huffman_decode(hd, br);
            if (dist_sym < 0 || dist_sym >= 30) return PDFMAKE_ECORRUPT;

            dist = dist_base[dist_sym];
            if (dist_extra[dist_sym] > 0) {
                extra = bitreader_read(br, dist_extra[dist_sym]);
                if (extra < 0) return PDFMAKE_ECORRUPT;
                dist += extra;
            }

            /* Copy from back-reference */
            if ((size_t)dist > out->len) return PDFMAKE_ECORRUPT;

            for (i = 0; i < len; i++) {
                byte = out->data[out->len - dist];
                if (pdfmake_buf_append_byte(out, byte) != PDFMAKE_OK)
                    return PDFMAKE_ENOMEM;
            }
        }
    }
}

/* Write `count` copies of `val` into lengths[n..target), saturating at target.
 * Shared by the three code-length repeat symbols (16/17/18) in the dynamic
 * Huffman block — each differs only in how `count` and `val` are derived. */
static PDFMAKE_INLINE int
deflate_fill_run(uint8_t *lengths, int n, int target, int count, uint8_t val)
{
    while (count-- > 0 && n < target) lengths[n++] = val;
    return n;
}

/* btype=0: uncompressed stored block. Aligns to the next byte boundary,
 * reads <len, ~len> and copies len bytes verbatim into the output. */
static pdfmake_err_t
inflate_stored_block(bitreader_t *br, pdfmake_buf_t *out)
{
    uint16_t len;
    uint16_t nlen;
    br->bits = 0;
    br->nbits = 0;  /* Align to byte boundary */

    if (br->pos + 4 > br->len) return PDFMAKE_ECORRUPT;
    len  = br->data[br->pos]     | ((uint16_t)br->data[br->pos + 1] << 8);
    nlen = br->data[br->pos + 2] | ((uint16_t)br->data[br->pos + 3] << 8);
    br->pos += 4;

    if (len != (uint16_t)~nlen) return PDFMAKE_ECORRUPT;
    if (br->pos + len > br->len) return PDFMAKE_ECORRUPT;

    if (pdfmake_buf_append(out, br->data + br->pos, len) != PDFMAKE_OK)
        return PDFMAKE_ENOMEM;
    br->pos += len;
    return PDFMAKE_OK;
}

/* btype=2: dynamic Huffman block. Decodes the code-length alphabet first,
 * then uses it to decode the literal/length and distance code tables,
 * then inflates the block body with those tables. */
static pdfmake_err_t
inflate_dynamic_block(bitreader_t *br, pdfmake_buf_t *out)
{
    int hlit;
    int hdist;
    int hclen;
    uint8_t cl_lengths[19];
    int i;
    huffman_t cl_huff;
    uint8_t lengths[288 + 32];
    int n;
    int sym;
    int extra;
    huffman_t dyn_lit_len, dyn_dist;
    hlit  = bitreader_read(br, 5);
    hdist = bitreader_read(br, 5);
    hclen = bitreader_read(br, 4);
    if (hlit < 0 || hdist < 0 || hclen < 0) return PDFMAKE_ECORRUPT;
    hlit  += 257;
    hdist += 1;
    hclen += 4;

    /* Code-length alphabet (19 symbols, stored in cl_order[]). */
    memset(cl_lengths, 0, sizeof(cl_lengths));
    for (i = 0; i < hclen; i++) {
        int code_len = bitreader_read(br, 3);
        if (code_len < 0) return PDFMAKE_ECORRUPT;
        cl_lengths[cl_order[i]] = (uint8_t)code_len;
    }

    if (huffman_build(&cl_huff, cl_lengths, 19) < 0) return PDFMAKE_ECORRUPT;

    /* Literal/length + distance code lengths. */
    n = 0;
    while (n < hlit + hdist) {
        sym = huffman_decode(&cl_huff, br);
        if (sym < 0) return PDFMAKE_ECORRUPT;

        if (sym < 16) {
            lengths[n++] = (uint8_t)sym;
        } else if (sym == 16) {
            extra = bitreader_read(br, 2);
            if (extra < 0 || n == 0) return PDFMAKE_ECORRUPT;
            n = deflate_fill_run(lengths, n, hlit + hdist,
                                 extra + 3, lengths[n - 1]);
        } else if (sym == 17) {
            extra = bitreader_read(br, 3);
            if (extra < 0) return PDFMAKE_ECORRUPT;
            n = deflate_fill_run(lengths, n, hlit + hdist, extra + 3, 0);
        } else if (sym == 18) {
            extra = bitreader_read(br, 7);
            if (extra < 0) return PDFMAKE_ECORRUPT;
            n = deflate_fill_run(lengths, n, hlit + hdist, extra + 11, 0);
        }
    }

    if (huffman_build(&dyn_lit_len, lengths, hlit) < 0) return PDFMAKE_ECORRUPT;
    if (huffman_build(&dyn_dist,   lengths + hlit, hdist) < 0) return PDFMAKE_ECORRUPT;

    return inflate_block(br, &dyn_lit_len, &dyn_dist, out);
}

pdfmake_err_t pdfmake_deflate_decode(const uint8_t *in, size_t in_len,
                                     pdfmake_buf_t *out)
{
    bitreader_t br;
    int bfinal;
    int btype;
    pdfmake_err_t err;
    if (!in || !out) return PDFMAKE_EINVAL;

    bitreader_init(&br, in, in_len);
    build_fixed_tables();

    do {
        bfinal = bitreader_read(&br, 1);
        btype = bitreader_read(&br, 2);
        if (bfinal < 0 || btype < 0) return PDFMAKE_ECORRUPT;

        switch (btype) {
            case 0: err = inflate_stored_block(&br, out); break;
            case 1: err = inflate_block(&br, &fixed_lit_len, &fixed_dist, out); break;
            case 2: err = inflate_dynamic_block(&br, out); break;
            default: return PDFMAKE_ECORRUPT;  /* btype == 3 is reserved */
        }
        if (err != PDFMAKE_OK) return err;
    } while (!bfinal);

    return PDFMAKE_OK;
}

/*============================================================================
 * DEFLATE encoder (store-only for now, then static Huffman)
 *==========================================================================*/

typedef struct {
    pdfmake_buf_t *out;
    uint32_t bits;
    int nbits;
} bitwriter_t;

static void bitwriter_init(bitwriter_t *bw, pdfmake_buf_t *out)
{
    bw->out = out;
    bw->bits = 0;
    bw->nbits = 0;
}

static pdfmake_err_t bitwriter_write(bitwriter_t *bw, int val, int n)
{
    bw->bits |= (uint32_t)val << bw->nbits;
    bw->nbits += n;

    while (bw->nbits >= 8) {
        if (pdfmake_buf_append_byte(bw->out, bw->bits & 0xFF) != PDFMAKE_OK)
            return PDFMAKE_ENOMEM;
        bw->bits >>= 8;
        bw->nbits -= 8;
    }

    return PDFMAKE_OK;
}

static pdfmake_err_t bitwriter_flush(bitwriter_t *bw)
{
    if (bw->nbits > 0) {
        if (pdfmake_buf_append_byte(bw->out, bw->bits & 0xFF) != PDFMAKE_OK)
            return PDFMAKE_ENOMEM;
        bw->bits = 0;
        bw->nbits = 0;
    }
    return PDFMAKE_OK;
}

/* Reverse bits for Huffman encoding */
static uint16_t reverse_bits(uint16_t val, int n)
{
    uint16_t rev = 0;
    int i;
    for (i = 0; i < n; i++) {
        rev = (rev << 1) | (val & 1);
        val >>= 1;
    }
    return rev;
}

/* Fixed Huffman code tables for encoding */
static uint16_t fixed_lit_codes[288];
static uint8_t fixed_lit_bits[288];
static uint16_t fixed_dist_codes[30];
static uint8_t fixed_dist_bits[30];
static int fixed_encode_tables_built = 0;

static void build_fixed_encode_tables(void)
{
    int i;
    uint16_t code;
    if (fixed_encode_tables_built) return;

    /* Literal/length codes */
    code = 0;

    /* 256-279: 7 bits starting at 0000000 */
    for (i = 256; i <= 279; i++) {
        fixed_lit_codes[i] = reverse_bits(code++, 7);
        fixed_lit_bits[i] = 7;
    }

    /* 0-143: 8 bits starting at 00110000 */
    code = 0x30;
    for (i = 0; i <= 143; i++) {
        fixed_lit_codes[i] = reverse_bits(code++, 8);
        fixed_lit_bits[i] = 8;
    }

    /* 280-287: 8 bits starting at 11000000 */
    code = 0xC0;
    for (i = 280; i <= 287; i++) {
        fixed_lit_codes[i] = reverse_bits(code++, 8);
        fixed_lit_bits[i] = 8;
    }

    /* 144-255: 9 bits starting at 110010000 */
    code = 0x190;
    for (i = 144; i <= 255; i++) {
        fixed_lit_codes[i] = reverse_bits(code++, 9);
        fixed_lit_bits[i] = 9;
    }

    /* Distance codes: all 5 bits starting at 00000 */
    for (i = 0; i < 30; i++) {
        fixed_dist_codes[i] = reverse_bits(i, 5);
        fixed_dist_bits[i] = 5;
    }

    fixed_encode_tables_built = 1;
}

/* Find length code for a given length (3-258) */
static int find_length_code(int length)
{
    int i;
    for (i = 0; i < 29; i++) {
        int max_len = length_base[i] + (1 << length_extra[i]) - 1;
        if (length <= max_len) return i;
    }
    return 28; /* Max length */
}

/* Find distance code for a given distance (1-32768) */
static int find_dist_code(int dist)
{
    int i;
    for (i = 0; i < 30; i++) {
        int max_dist = dist_base[i] + (1 << dist_extra[i]) - 1;
        if (dist <= max_dist) return i;
    }
    return 29; /* Max distance */
}

/*----------------------------------------------------------------------------
 * LZ77 hash chain implementation
 *--------------------------------------------------------------------------*/

#define HASH_BITS 15
#define HASH_SIZE (1 << HASH_BITS)
#define HASH_MASK (HASH_SIZE - 1)
#define WINDOW_SIZE 32768
#define MIN_MATCH 3
#define MAX_MATCH 258
#define MAX_CHAIN 128  /* Max hash chain length to search */

typedef struct {
    const uint8_t *data;
    size_t len;
    int head[HASH_SIZE];
    int prev[WINDOW_SIZE];
    size_t pos;
} lz77_t;

static void lz77_init(lz77_t *lz, const uint8_t *data, size_t len)
{
    lz->data = data;
    lz->len = len;
    lz->pos = 0;
    memset(lz->head, -1, sizeof(lz->head));
    memset(lz->prev, -1, sizeof(lz->prev));
}

static int lz77_hash(const uint8_t *data)
{
    return ((data[0] << 10) ^ (data[1] << 5) ^ data[2]) & HASH_MASK;
}

static void lz77_insert(lz77_t *lz, size_t pos)
{
    int h;
    if (pos + 2 >= lz->len) return;

    h = lz77_hash(lz->data + pos);
    lz->prev[pos & (WINDOW_SIZE - 1)] = lz->head[h];
    lz->head[h] = (int)pos;
}

static int lz77_find_match(lz77_t *lz, size_t pos, int *match_dist, int *match_len)
{
    int h;
    int chain_len;
    int match_pos;
    int dist;
    const uint8_t *a;
    const uint8_t *b;
    int len;
    size_t max_len;
    *match_len = 0;
    *match_dist = 0;

    if (pos + MIN_MATCH > lz->len) return 0;

    h = lz77_hash(lz->data + pos);
    chain_len = 0;
    match_pos = lz->head[h];

    while (match_pos >= 0 && chain_len < MAX_CHAIN) {
        dist = (int)pos - match_pos;
        if (dist > WINDOW_SIZE) break;
        if (dist <= 0) break;

        /* Check match */
        a = lz->data + pos;
        b = lz->data + match_pos;
        len = 0;

        max_len = lz->len - pos;
        if (max_len > MAX_MATCH) max_len = MAX_MATCH;

        while ((size_t)len < max_len && a[len] == b[len]) len++;

        if (len >= MIN_MATCH && len > *match_len) {
            *match_len = len;
            *match_dist = dist;
            if (len >= MAX_MATCH) break;
        }

        match_pos = lz->prev[match_pos & (WINDOW_SIZE - 1)];
        chain_len++;
    }

    return *match_len >= MIN_MATCH;
}

/*----------------------------------------------------------------------------
 * DEFLATE encoder with LZ77
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_deflate_encode(const uint8_t *in, size_t in_len,
                                     int level,
                                     pdfmake_buf_t *out)
{
    bitwriter_t bw;
    size_t pos;
    if (!out) return PDFMAKE_EINVAL;
    if (in_len == 0) {
        /* Empty input: single empty stored block */
        uint8_t empty[] = {0x01, 0x00, 0x00, 0xFF, 0xFF};
        return pdfmake_buf_append(out, empty, 5);
    }

    build_fixed_encode_tables();

    bitwriter_init(&bw, out);

    if (level == 0) {
        uint16_t len;
        uint16_t nlen;
        int bfinal;
        size_t block_len;
        /* Store-only: emit stored blocks */
        pos = 0;
        while (pos < in_len) {
            block_len = in_len - pos;
            if (block_len > 65535) block_len = 65535;

            bfinal = (pos + block_len >= in_len) ? 1 : 0;
            bitwriter_write(&bw, bfinal, 1);
            bitwriter_write(&bw, 0, 2);  /* btype = 0 (stored) */
            bitwriter_flush(&bw);

            len = (uint16_t)block_len;
            nlen = ~len;
            pdfmake_buf_append_byte(out, len & 0xFF);
            pdfmake_buf_append_byte(out, (len >> 8) & 0xFF);
            pdfmake_buf_append_byte(out, nlen & 0xFF);
            pdfmake_buf_append_byte(out, (nlen >> 8) & 0xFF);
            pdfmake_buf_append(out, in + pos, block_len);

            pos += block_len;
        }
    }
    else {
        lz77_t lz;
        /* LZ77 + fixed Huffman (level 1-9 all use this for now) */
        int match_dist, match_len;
        int len_code;
        int dist_code;
        int extra;
        int i;
        lz77_init(&lz, in, in_len);

        /* Single block with fixed Huffman */
        bitwriter_write(&bw, 1, 1);  /* bfinal = 1 */
        bitwriter_write(&bw, 1, 2);  /* btype = 1 (fixed Huffman) */

        pos = 0;
        while (pos < in_len) {
            if (lz77_find_match(&lz, pos, &match_dist, &match_len)) {
                /* Emit length/distance pair */
                len_code = find_length_code(match_len);
                bitwriter_write(&bw, fixed_lit_codes[257 + len_code],
                               fixed_lit_bits[257 + len_code]);
                if (length_extra[len_code] > 0) {
                    extra = match_len - length_base[len_code];
                    bitwriter_write(&bw, extra, length_extra[len_code]);
                }

                dist_code = find_dist_code(match_dist);
                bitwriter_write(&bw, fixed_dist_codes[dist_code],
                               fixed_dist_bits[dist_code]);
                if (dist_extra[dist_code] > 0) {
                    extra = match_dist - dist_base[dist_code];
                    bitwriter_write(&bw, extra, dist_extra[dist_code]);
                }

                /* Insert all positions in the match into hash */
                for (i = 0; i < match_len; i++) {
                    lz77_insert(&lz, pos + i);
                }
                pos += match_len;
            }
            else {
                /* Emit literal */
                bitwriter_write(&bw, fixed_lit_codes[in[pos]],
                               fixed_lit_bits[in[pos]]);
                lz77_insert(&lz, pos);
                pos++;
            }
        }

        /* End of block */
        bitwriter_write(&bw, fixed_lit_codes[256], fixed_lit_bits[256]);
        bitwriter_flush(&bw);
    }

    return PDFMAKE_OK;
}

/*============================================================================
 * zlib wrapper (RFC 1950)
 *==========================================================================*/

pdfmake_err_t pdfmake_flate_decode(const uint8_t *in, size_t in_len,
                                   const pdfmake_flate_params_t *params,
                                   pdfmake_buf_t *out)
{
    uint8_t cmf;
    uint8_t flg;
    size_t deflate_len;
    pdfmake_buf_t raw;
    pdfmake_err_t err;
    if (!in || !out) return PDFMAKE_EINVAL;
    if (in_len < 6) return PDFMAKE_ECORRUPT;  /* Min: 2 header + 4 Adler-32 */

    /* Parse zlib header (CMF + FLG) */
    cmf = in[0];
    flg = in[1];

    /* Check header checksum */
    if ((cmf * 256 + flg) % 31 != 0) return PDFMAKE_ECORRUPT;

    /* Check compression method (CM = 8 = deflate) */
    if ((cmf & 0x0F) != 8) return PDFMAKE_EUNSUPPORTED;

    /* Window size: CINFO = (cmf >> 4), window = 2^(CINFO+8) */
    /* We support all window sizes */

    /* FDICT bit (preset dictionary): not supported */
    if (flg & 0x20) return PDFMAKE_EUNSUPPORTED;

    /* Decompress DEFLATE data */
    deflate_len = in_len - 6;  /* Skip header (2) and trailer (4) */
    if (pdfmake_buf_init(&raw) != PDFMAKE_OK) return PDFMAKE_ENOMEM;

    err = pdfmake_deflate_decode(in + 2, deflate_len, &raw);
    if (err != PDFMAKE_OK) {
        pdfmake_buf_free(&raw);
        return err;
    }

    /* Note: Adler-32 checksum verification is skipped.
     * PDF stream /Length values don't always align with the zlib trailer
     * position, and many real-world PDFs have mismatched checksums.
     * The DEFLATE decoder's own consistency checks are sufficient. */

    /* Apply predictor if needed */
    if (params && params->predictor > 1) {
        pdfmake_buf_t pred_out;
        if (pdfmake_buf_init(&pred_out) != PDFMAKE_OK) {
            pdfmake_buf_free(&raw);
            return PDFMAKE_ENOMEM;
        }

        if (params->predictor == 2) {
            err = pdfmake_tiff_predictor_decode(params->colors,
                                                params->bits_per_comp,
                                                params->columns,
                                                raw.data, raw.len, &pred_out);
        } else if (params->predictor >= 10 && params->predictor <= 15) {
            err = pdfmake_predictor_decode(params->predictor,
                                          params->colors,
                                          params->bits_per_comp,
                                          params->columns,
                                          raw.data, raw.len, &pred_out);
        } else {
            err = PDFMAKE_EINVAL;
        }

        pdfmake_buf_free(&raw);
        if (err != PDFMAKE_OK) {
            pdfmake_buf_free(&pred_out);
            return err;
        }

        /* Move predictor output to main output */
        if (pdfmake_buf_append(out, pred_out.data, pred_out.len) != PDFMAKE_OK) {
            pdfmake_buf_free(&pred_out);
            return PDFMAKE_ENOMEM;
        }
        pdfmake_buf_free(&pred_out);
    }
    else {
        /* No predictor */
        if (pdfmake_buf_append(out, raw.data, raw.len) != PDFMAKE_OK) {
            pdfmake_buf_free(&raw);
            return PDFMAKE_ENOMEM;
        }
        pdfmake_buf_free(&raw);
    }

    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_flate_encode(const uint8_t *in, size_t in_len,
                                   const pdfmake_flate_params_t *params,
                                   pdfmake_buf_t *out)
{
    pdfmake_buf_t raw;
    pdfmake_err_t err;
    uint32_t adler;
    if (!out) return PDFMAKE_EINVAL;

    if (pdfmake_buf_init(&raw) != PDFMAKE_OK) return PDFMAKE_ENOMEM;

    /* Apply predictor if needed */
    if (params && params->predictor > 1) {
        if (params->predictor == 2) {
            err = pdfmake_tiff_predictor_encode(params->colors,
                                                params->bits_per_comp,
                                                params->columns,
                                                in, in_len, &raw);
        } else if (params->predictor >= 10 && params->predictor <= 15) {
            err = pdfmake_predictor_encode(params->predictor,
                                          params->colors,
                                          params->bits_per_comp,
                                          params->columns,
                                          in, in_len, &raw);
        } else {
            pdfmake_buf_free(&raw);
            return PDFMAKE_EINVAL;
        }

        if (err != PDFMAKE_OK) {
            pdfmake_buf_free(&raw);
            return err;
        }
    }
    else {
        /* No predictor - copy input */
        if (pdfmake_buf_append(&raw, in, in_len) != PDFMAKE_OK) {
            pdfmake_buf_free(&raw);
            return PDFMAKE_ENOMEM;
        }
    }

    /* zlib header: CMF=0x78 (deflate, 32K window), FLG=0x9C (level 6, no dict) */
    /* For checksum: (0x78 * 256 + 0x9C) % 31 = 0 */
    pdfmake_buf_append_byte(out, 0x78);
    pdfmake_buf_append_byte(out, 0x9C);

    /* DEFLATE compress */
    err = pdfmake_deflate_encode(raw.data, raw.len, 4, out);  /* Level 4 */
    if (err != PDFMAKE_OK) {
        pdfmake_buf_free(&raw);
        return err;
    }

    /* Adler-32 checksum (big-endian) */
    adler = pdfmake_adler32(raw.data, raw.len);
    pdfmake_buf_append_byte(out, (adler >> 24) & 0xFF);
    pdfmake_buf_append_byte(out, (adler >> 16) & 0xFF);
    pdfmake_buf_append_byte(out, (adler >> 8) & 0xFF);
    pdfmake_buf_append_byte(out, adler & 0xFF);

    pdfmake_buf_free(&raw);
    return PDFMAKE_OK;
}

/*============================================================================
 * PNG predictors (§7.4.4.4)
 *==========================================================================*/

/* Paeth predictor function */
static int paeth(int a, int b, int c)
{
    int p = a + b - c;
    int pa = abs(p - a);
    int pb = abs(p - b);
    int pc = abs(p - c);

    if (pa <= pb && pa <= pc) return a;
    if (pb <= pc) return b;
    return c;
}

pdfmake_err_t pdfmake_predictor_decode(int predictor,
                                       int colors, int bits_per_comp, int columns,
                                       const uint8_t *in, size_t in_len,
                                       pdfmake_buf_t *out)
{
    int bpp;
    int row_bytes;
    int in_row_size;
    size_t num_rows;
    uint8_t *prev_row;
    uint8_t *curr_row;
    size_t r;
    int i;
    if (!in || !out) return PDFMAKE_EINVAL;

    /* Calculate bytes per pixel (bpp) and row width */
    bpp = (colors * bits_per_comp + 7) / 8;
    row_bytes = (columns * colors * bits_per_comp + 7) / 8;

    /* For PNG predictors, each row has a filter type byte prefix */
    in_row_size = row_bytes + 1;

    if (in_len % in_row_size != 0) {
        /* If there's no filter byte, data might be raw (predictor=10, None) */
        if (predictor == 10) {
            return pdfmake_buf_append(out, in, in_len);
        }
        return PDFMAKE_ECORRUPT;
    }

    num_rows = in_len / in_row_size;

    /* Allocate previous row buffer */
    prev_row = calloc(row_bytes, 1);
    if (!prev_row) return PDFMAKE_ENOMEM;

    /* Allocate current row buffer */
    curr_row = malloc(row_bytes);
    if (!curr_row) {
        free(prev_row);
        return PDFMAKE_ENOMEM;
    }

    for (r = 0; r < num_rows; r++) {
        const uint8_t *row_in = in + r * in_row_size;
        int filter_type = row_in[0];
        const uint8_t *filtered = row_in + 1;

        /* Apply reverse filter */
        for (i = 0; i < row_bytes; i++) {
            uint8_t raw;
            uint8_t a = (i >= bpp) ? curr_row[i - bpp] : 0;
            uint8_t b = prev_row[i];
            uint8_t c = (i >= bpp) ? prev_row[i - bpp] : 0;

            switch (filter_type) {
                case 0:  /* None */
                    raw = filtered[i];
                    break;
                case 1:  /* Sub */
                    raw = filtered[i] + a;
                    break;
                case 2:  /* Up */
                    raw = filtered[i] + b;
                    break;
                case 3:  /* Average */
                    raw = filtered[i] + ((a + b) / 2);
                    break;
                case 4:  /* Paeth */
                    raw = filtered[i] + paeth(a, b, c);
                    break;
                default:
                    free(prev_row);
                    free(curr_row);
                    return PDFMAKE_ECORRUPT;
            }

            curr_row[i] = raw;
        }

        /* Output row */
        if (pdfmake_buf_append(out, curr_row, row_bytes) != PDFMAKE_OK) {
            free(prev_row);
            free(curr_row);
            return PDFMAKE_ENOMEM;
        }

        /* Current row becomes previous row */
        memcpy(prev_row, curr_row, row_bytes);
    }

    free(prev_row);
    free(curr_row);
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_predictor_encode(int predictor,
                                       int colors, int bits_per_comp, int columns,
                                       const uint8_t *in, size_t in_len,
                                       pdfmake_buf_t *out)
{
    int bpp;
    int row_bytes;
    size_t num_rows;
    uint8_t *prev_row;
    uint8_t *filtered;
    size_t r;
    int i;
    int f;
    if (!in || !out) return PDFMAKE_EINVAL;

    bpp = (colors * bits_per_comp + 7) / 8;
    row_bytes = (columns * colors * bits_per_comp + 7) / 8;

    if (in_len % row_bytes != 0) return PDFMAKE_EINVAL;

    num_rows = in_len / row_bytes;

    /* Allocate previous row buffer */
    prev_row = calloc(row_bytes, 1);
    if (!prev_row) return PDFMAKE_ENOMEM;

    /* Allocate filtered row buffer */
    filtered = malloc(row_bytes);
    if (!filtered) {
        free(prev_row);
        return PDFMAKE_ENOMEM;
    }

    for (r = 0; r < num_rows; r++) {
        const uint8_t *curr_row = in + r * row_bytes;

        int filter_type;
        if (predictor == 15) {
            /* Optimum: try all filters and pick best (simple heuristic: sum of abs values) */
            int best_filter = 0;
            int best_sum = INT32_MAX;

            for (f = 0; f <= 4; f++) {
                int sum = 0;
                for (i = 0; i < row_bytes; i++) {
                    uint8_t a = (i >= bpp) ? curr_row[i - bpp] : 0;
                    uint8_t b = prev_row[i];
                    uint8_t c = (i >= bpp) ? prev_row[i - bpp] : 0;
                    int val;

                    switch (f) {
                        case 0: val = curr_row[i]; break;
                        case 1: val = curr_row[i] - a; break;
                        case 2: val = curr_row[i] - b; break;
                        case 3: val = curr_row[i] - ((a + b) / 2); break;
                        case 4: val = curr_row[i] - paeth(a, b, c); break;
                        default: val = 0;
                    }
                    sum += abs((int8_t)val);
                }
                if (sum < best_sum) {
                    best_sum = sum;
                    best_filter = f;
                }
            }
            filter_type = best_filter;
        }
        else {
            filter_type = predictor - 10;  /* 10=None, 11=Sub, 12=Up, 13=Avg, 14=Paeth */
            if (filter_type < 0 || filter_type > 4) filter_type = 0;
        }

        /* Apply filter */
        for (i = 0; i < row_bytes; i++) {
            uint8_t a = (i >= bpp) ? curr_row[i - bpp] : 0;
            uint8_t b = prev_row[i];
            uint8_t c = (i >= bpp) ? prev_row[i - bpp] : 0;

            switch (filter_type) {
                case 0:  /* None */
                    filtered[i] = curr_row[i];
                    break;
                case 1:  /* Sub */
                    filtered[i] = curr_row[i] - a;
                    break;
                case 2:  /* Up */
                    filtered[i] = curr_row[i] - b;
                    break;
                case 3:  /* Average */
                    filtered[i] = curr_row[i] - ((a + b) / 2);
                    break;
                case 4:  /* Paeth */
                    filtered[i] = curr_row[i] - paeth(a, b, c);
                    break;
            }
        }

        /* Output filter type byte + filtered row */
        pdfmake_buf_append_byte(out, (uint8_t)filter_type);
        if (pdfmake_buf_append(out, filtered, row_bytes) != PDFMAKE_OK) {
            free(prev_row);
            free(filtered);
            return PDFMAKE_ENOMEM;
        }

        /* Current row becomes previous row */
        memcpy(prev_row, curr_row, row_bytes);
    }

    free(prev_row);
    free(filtered);
    return PDFMAKE_OK;
}

/*============================================================================
 * TIFF predictor 2 (horizontal differencing)
 *==========================================================================*/

pdfmake_err_t pdfmake_tiff_predictor_decode(int colors, int bits_per_comp, int columns,
                                            const uint8_t *in, size_t in_len,
                                            pdfmake_buf_t *out)
{
    int row_bytes;
    size_t num_rows;
    uint8_t *row;
    size_t r;
    int c;
    int i;
    if (!in || !out) return PDFMAKE_EINVAL;

    /* Only 8-bit samples supported for now */
    if (bits_per_comp != 8) return PDFMAKE_EUNSUPPORTED;

    row_bytes = columns * colors;
    if (in_len % row_bytes != 0) return PDFMAKE_EINVAL;

    num_rows = in_len / row_bytes;

    /* Allocate row buffer */
    row = malloc(row_bytes);
    if (!row) return PDFMAKE_ENOMEM;

    for (r = 0; r < num_rows; r++) {
        const uint8_t *row_in = in + r * row_bytes;

        /* First pixel is as-is */
        for (c = 0; c < colors; c++) {
            row[c] = row_in[c];
        }

        /* Remaining pixels: add previous pixel */
        for (i = colors; i < row_bytes; i++) {
            row[i] = row_in[i] + row[i - colors];
        }

        if (pdfmake_buf_append(out, row, row_bytes) != PDFMAKE_OK) {
            free(row);
            return PDFMAKE_ENOMEM;
        }
    }

    free(row);
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_tiff_predictor_encode(int colors, int bits_per_comp, int columns,
                                            const uint8_t *in, size_t in_len,
                                            pdfmake_buf_t *out)
{
    int row_bytes;
    size_t num_rows;
    uint8_t *row;
    size_t r;
    int c;
    int i;
    if (!in || !out) return PDFMAKE_EINVAL;

    /* Only 8-bit samples supported for now */
    if (bits_per_comp != 8) return PDFMAKE_EUNSUPPORTED;

    row_bytes = columns * colors;
    if (in_len % row_bytes != 0) return PDFMAKE_EINVAL;

    num_rows = in_len / row_bytes;

    /* Allocate row buffer */
    row = malloc(row_bytes);
    if (!row) return PDFMAKE_ENOMEM;

    for (r = 0; r < num_rows; r++) {
        const uint8_t *row_in = in + r * row_bytes;

        /* First pixel is as-is */
        for (c = 0; c < colors; c++) {
            row[c] = row_in[c];
        }

        /* Remaining pixels: subtract previous pixel */
        for (i = colors; i < row_bytes; i++) {
            row[i] = row_in[i] - row_in[i - colors];
        }

        if (pdfmake_buf_append(out, row, row_bytes) != PDFMAKE_OK) {
            free(row);
            return PDFMAKE_ENOMEM;
        }
    }

    free(row);
    return PDFMAKE_OK;
}

/*============================================================================
 * Filter dispatch
 *==========================================================================*/

pdfmake_err_t pdfmake_filter_encode(const char *name,
                                    const uint8_t *in, size_t in_len,
                                    const pdfmake_obj_t *params,
                                    pdfmake_buf_t *out)
{
    (void)params;  /* Unused by most encoders */

    if (!name || !out) return PDFMAKE_EINVAL;

    if (strcmp(name, "FlateDecode") == 0 || strcmp(name, "Fl") == 0) {
        pdfmake_flate_params_t fp;
        pdfmake_flate_params_from_dict(&fp, params);
        return pdfmake_flate_encode(in, in_len, &fp, out);
    }

    if (strcmp(name, "ASCIIHexDecode") == 0 || strcmp(name, "AHx") == 0) {
        return pdfmake_asciihex_encode(in, in_len, out);
    }

    if (strcmp(name, "ASCII85Decode") == 0 || strcmp(name, "A85") == 0) {
        return pdfmake_ascii85_encode(in, in_len, out);
    }

    if (strcmp(name, "RunLengthDecode") == 0 || strcmp(name, "RL") == 0) {
        return pdfmake_rle_encode(in, in_len, out);
    }

    /* LZWDecode encoding not supported (patent concerns, use FlateDecode) */

    return PDFMAKE_EUNSUPPORTED;
}

pdfmake_err_t pdfmake_filter_decode(const char *name,
                                    const uint8_t *in, size_t in_len,
                                    const pdfmake_obj_t *params,
                                    pdfmake_buf_t *out)
{
    if (!name || !out) return PDFMAKE_EINVAL;

    if (strcmp(name, "FlateDecode") == 0 || strcmp(name, "Fl") == 0) {
        pdfmake_flate_params_t fp;
        pdfmake_flate_params_from_dict(&fp, params);
        return pdfmake_flate_decode(in, in_len, &fp, out);
    }

    if (strcmp(name, "ASCIIHexDecode") == 0 || strcmp(name, "AHx") == 0) {
        return pdfmake_asciihex_decode(in, in_len, out);
    }

    if (strcmp(name, "ASCII85Decode") == 0 || strcmp(name, "A85") == 0) {
        return pdfmake_ascii85_decode(in, in_len, out);
    }

    if (strcmp(name, "LZWDecode") == 0 || strcmp(name, "LZW") == 0) {
        pdfmake_flate_params_t fp;
        pdfmake_flate_params_from_dict(&fp, params);  /* Reuses same params structure */
        return pdfmake_lzw_decode(in, in_len, &fp, out);
    }

    if (strcmp(name, "RunLengthDecode") == 0 || strcmp(name, "RL") == 0) {
        return pdfmake_rle_decode(in, in_len, out);
    }

    /* Stub filters */
    if (strcmp(name, "CCITTFaxDecode") == 0 || strcmp(name, "CCF") == 0) {
        return pdfmake_ccitt_decode(in, in_len, params, out);
    }
    if (strcmp(name, "JBIG2Decode") == 0) {
        return pdfmake_jbig2_decode(in, in_len, params, out);
    }
    if (strcmp(name, "JPXDecode") == 0) {
        return pdfmake_jpx_decode(in, in_len, params, out);
    }

    return PDFMAKE_EUNSUPPORTED;
}

pdfmake_err_t pdfmake_filter_chain_decode(pdfmake_arena_t *arena,
                                          const pdfmake_obj_t *filters,
                                          const pdfmake_obj_t *params,
                                          const uint8_t *in, size_t in_len,
                                          pdfmake_buf_t *out)
{
    size_t n;
    pdfmake_buf_t tmp1, tmp2;
    const uint8_t *current_in;
    size_t current_len;
    pdfmake_buf_t *current_out;
    size_t i;
    pdfmake_err_t err;
    if (!arena || !filters || !out) return PDFMAKE_EINVAL;

    /* Single filter (name) */
    if (filters->kind == PDFMAKE_NAME) {
        const char *name = (const char *)pdfmake_arena_name_bytes(
            arena, filters->as.name.id);
        return pdfmake_filter_decode(name, in, in_len, params, out);
    }

    /* Array of filters */
    if (filters->kind != PDFMAKE_ARRAY) return PDFMAKE_EINVAL;

    n = pdfmake_array_len((pdfmake_obj_t *)filters);
    if (n == 0) {
        return pdfmake_buf_append(out, in, in_len);
    }

    /* Apply filters in reverse order (last filter first for decoding) */
    if (pdfmake_buf_init(&tmp1) != PDFMAKE_OK) return PDFMAKE_ENOMEM;
    if (pdfmake_buf_init(&tmp2) != PDFMAKE_OK) {
        pdfmake_buf_free(&tmp1);
        return PDFMAKE_ENOMEM;
    }

    current_in = in;
    current_len = in_len;
    current_out = &tmp1;

    for (i = n; i > 0; i--) {
        const char *name;
        const pdfmake_obj_t *filter_params;
        pdfmake_obj_t *filter = pdfmake_array_get((pdfmake_obj_t *)filters, i - 1);
        if (!filter || filter->kind != PDFMAKE_NAME) {
            pdfmake_buf_free(&tmp1);
            pdfmake_buf_free(&tmp2);
            return PDFMAKE_EINVAL;
        }

        name = (const char *)pdfmake_arena_name_bytes(
            arena, filter->as.name.id);

        /* Get params for this filter if array */
        filter_params = NULL;
        if (params && params->kind == PDFMAKE_ARRAY) {
            filter_params = pdfmake_array_get((pdfmake_obj_t *)params, i - 1);
        } else if (params && n == 1) {
            filter_params = params;
        }

        pdfmake_buf_clear(current_out);
        err = pdfmake_filter_decode(name, current_in, current_len,
                                    filter_params, current_out);
        if (err != PDFMAKE_OK) {
            pdfmake_buf_free(&tmp1);
            pdfmake_buf_free(&tmp2);
            return err;
        }

        /* Swap buffers for next iteration */
        current_in = current_out->data;
        current_len = current_out->len;
        current_out = (current_out == &tmp1) ? &tmp2 : &tmp1;
    }

    /* Copy final result to output */
    err = pdfmake_buf_append(out, current_in, current_len);

    pdfmake_buf_free(&tmp1);
    pdfmake_buf_free(&tmp2);
    return err;
}

pdfmake_err_t pdfmake_filter_chain_encode(pdfmake_arena_t *arena,
                                          const pdfmake_obj_t *filters,
                                          const pdfmake_obj_t *params,
                                          const uint8_t *in, size_t in_len,
                                          pdfmake_buf_t *out)
{
    size_t n;
    pdfmake_buf_t tmp1, tmp2;
    const uint8_t *current_in;
    size_t current_len;
    pdfmake_buf_t *current_out;
    size_t i;
    pdfmake_err_t err;
    if (!arena || !filters || !out) return PDFMAKE_EINVAL;

    /* Single filter (name) */
    if (filters->kind == PDFMAKE_NAME) {
        const char *name = (const char *)pdfmake_arena_name_bytes(
            arena, filters->as.name.id);
        return pdfmake_filter_encode(name, in, in_len, params, out);
    }

    /* Array of filters */
    if (filters->kind != PDFMAKE_ARRAY) return PDFMAKE_EINVAL;

    n = pdfmake_array_len((pdfmake_obj_t *)filters);
    if (n == 0) {
        return pdfmake_buf_append(out, in, in_len);
    }

    /* Apply filters in order (first filter first for encoding) */
    if (pdfmake_buf_init(&tmp1) != PDFMAKE_OK) return PDFMAKE_ENOMEM;
    if (pdfmake_buf_init(&tmp2) != PDFMAKE_OK) {
        pdfmake_buf_free(&tmp1);
        return PDFMAKE_ENOMEM;
    }

    current_in = in;
    current_len = in_len;
    current_out = &tmp1;

    for (i = 0; i < n; i++) {
        const char *name;
        const pdfmake_obj_t *filter_params;
        pdfmake_obj_t *filter = pdfmake_array_get((pdfmake_obj_t *)filters, i);
        if (!filter || filter->kind != PDFMAKE_NAME) {
            pdfmake_buf_free(&tmp1);
            pdfmake_buf_free(&tmp2);
            return PDFMAKE_EINVAL;
        }

        name = (const char *)pdfmake_arena_name_bytes(
            arena, filter->as.name.id);

        /* Get params for this filter if array */
        filter_params = NULL;
        if (params && params->kind == PDFMAKE_ARRAY) {
            filter_params = pdfmake_array_get((pdfmake_obj_t *)params, i);
        } else if (params && n == 1) {
            filter_params = params;
        }

        pdfmake_buf_clear(current_out);
        err = pdfmake_filter_encode(name, current_in, current_len,
                                    filter_params, current_out);
        if (err != PDFMAKE_OK) {
            pdfmake_buf_free(&tmp1);
            pdfmake_buf_free(&tmp2);
            return err;
        }

        /* Swap buffers for next iteration */
        current_in = current_out->data;
        current_len = current_out->len;
        current_out = (current_out == &tmp1) ? &tmp2 : &tmp1;
    }

    /* Copy final result to output */
    err = pdfmake_buf_append(out, current_in, current_len);

    pdfmake_buf_free(&tmp1);
    pdfmake_buf_free(&tmp2);
    return err;
}

/*============================================================================
 * ASCIIHexDecode — §7.4.2
 *==========================================================================*/

static int hex_digit_value(uint8_t c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    return -1;
}

pdfmake_err_t pdfmake_asciihex_decode(const uint8_t *in, size_t in_len,
                                      pdfmake_buf_t *out)
{
    int high;
    size_t i;
    uint8_t c;
    int val;
    uint8_t byte;
    if (!out) return PDFMAKE_EINVAL;
    if (!in || in_len == 0) return PDFMAKE_OK;

    high = -1;  /* Pending high nibble, -1 = none */

    for (i = 0; i < in_len; i++) {
        c = in[i];

        /* End of data marker */
        if (c == '>') break;

        /* Skip whitespace */
        if (c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f') {
            continue;
        }

        val = hex_digit_value(c);
        if (val < 0) return PDFMAKE_ECORRUPT;  /* Invalid hex digit */

        if (high < 0) {
            high = val;
        } else {
            byte = (uint8_t)((high << 4) | val);
            if (pdfmake_buf_append_byte(out, byte) != PDFMAKE_OK) {
                return PDFMAKE_ENOMEM;
            }
            high = -1;
        }
    }

    /* Odd final digit → pad with 0 */
    if (high >= 0) {
        byte = (uint8_t)(high << 4);
        if (pdfmake_buf_append_byte(out, byte) != PDFMAKE_OK) {
            return PDFMAKE_ENOMEM;
        }
    }

    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_asciihex_encode(const uint8_t *in, size_t in_len,
                                      pdfmake_buf_t *out)
{
    static const char hex_chars[] = "0123456789ABCDEF";
    size_t i;
    uint8_t byte;

    if (!out) return PDFMAKE_EINVAL;

    for (i = 0; i < in_len; i++) {
        byte = in[i];
        if (pdfmake_buf_append_byte(out, hex_chars[byte >> 4]) != PDFMAKE_OK ||
            pdfmake_buf_append_byte(out, hex_chars[byte & 0x0F]) != PDFMAKE_OK) {
            return PDFMAKE_ENOMEM;
        }
    }

    /* End of data marker */
    return pdfmake_buf_append_byte(out, '>');
}

/*============================================================================
 * ASCII85Decode — §7.4.3
 *==========================================================================*/

/* Powers of 85 for decoding: 85^4, 85^3, 85^2, 85^1, 85^0 */
static const uint32_t pdfmake_pow85[5] = {52200625, 614125, 7225, 85, 1};

pdfmake_err_t pdfmake_ascii85_decode(const uint8_t *in, size_t in_len,
                                     pdfmake_buf_t *out)
{
    uint8_t group[5];
    int group_len;
    size_t i;
    uint8_t c;
    uint8_t zeros[4];
    uint32_t val;
    int j;
    uint8_t bytes[4];
    int out_bytes;
    if (!out) return PDFMAKE_EINVAL;
    if (!in || in_len == 0) return PDFMAKE_OK;

    group_len = 0;
    zeros[0] = 0; zeros[1] = 0; zeros[2] = 0; zeros[3] = 0;

    for (i = 0; i < in_len; i++) {
        c = in[i];

        /* End of data marker */
        if (c == '~') {
            if (i + 1 < in_len && in[i + 1] == '>') break;
            /* Lone ~ is an error, but be lenient */
            continue;
        }

        /* Skip whitespace */
        if (c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f') {
            continue;
        }

        /* 'z' shorthand = 4 zero bytes (only valid when group is empty) */
        if (c == 'z') {
            if (group_len != 0) return PDFMAKE_ECORRUPT;
            if (pdfmake_buf_append(out, zeros, 4) != PDFMAKE_OK) {
                return PDFMAKE_ENOMEM;
            }
            continue;
        }

        /* Valid ASCII85 chars are 33 ('!') to 117 ('u') */
        if (c < 33 || c > 117) return PDFMAKE_ECORRUPT;

        group[group_len++] = c - 33;

        if (group_len == 5) {
            /* Decode 5 chars → 4 bytes */
            val = 0;
            for (j = 0; j < 5; j++) {
                val += group[j] * pdfmake_pow85[j];
            }

            bytes[0] = (val >> 24) & 0xFF;
            bytes[1] = (val >> 16) & 0xFF;
            bytes[2] = (val >> 8) & 0xFF;
            bytes[3] = val & 0xFF;

            if (pdfmake_buf_append(out, bytes, 4) != PDFMAKE_OK) {
                return PDFMAKE_ENOMEM;
            }
            group_len = 0;
        }
    }

    /* Handle final short group (2-4 chars → 1-3 bytes) */
    if (group_len > 1) {
        /* Pad with 'u' (84) to make 5 chars */
        for (j = group_len; j < 5; j++) {
            group[j] = 84;  /* 'u' - 33 */
        }

        val = 0;
        for (j = 0; j < 5; j++) {
            val += group[j] * pdfmake_pow85[j];
        }

        out_bytes = group_len - 1;  /* 2 chars → 1 byte, etc. */
        bytes[0] = (val >> 24) & 0xFF;
        bytes[1] = (val >> 16) & 0xFF;
        bytes[2] = (val >> 8) & 0xFF;
        bytes[3] = val & 0xFF;

        if (pdfmake_buf_append(out, bytes, out_bytes) != PDFMAKE_OK) {
            return PDFMAKE_ENOMEM;
        }
    } else if (group_len == 1) {
        /* Single trailing char is invalid */
        return PDFMAKE_ECORRUPT;
    }

    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_ascii85_encode(const uint8_t *in, size_t in_len,
                                     pdfmake_buf_t *out)
{
    size_t i;
    uint32_t val;
    uint8_t chars[5];
    size_t remain;
    size_t j;
    if (!out) return PDFMAKE_EINVAL;

    i = 0;
    while (i + 4 <= in_len) {
        /* Encode 4 bytes → 5 chars */
        val = ((uint32_t)in[i] << 24) |
              ((uint32_t)in[i+1] << 16) |
              ((uint32_t)in[i+2] << 8) |
              (uint32_t)in[i+3];

        if (val == 0) {
            /* Use 'z' shorthand for 4 zero bytes */
            if (pdfmake_buf_append_byte(out, 'z') != PDFMAKE_OK) {
                return PDFMAKE_ENOMEM;
            }
        } else {
            chars[4] = (val % 85) + 33; val /= 85;
            chars[3] = (val % 85) + 33; val /= 85;
            chars[2] = (val % 85) + 33; val /= 85;
            chars[1] = (val % 85) + 33; val /= 85;
            chars[0] = (val % 85) + 33;

            if (pdfmake_buf_append(out, chars, 5) != PDFMAKE_OK) {
                return PDFMAKE_ENOMEM;
            }
        }
        i += 4;
    }

    /* Handle final short group (1-3 bytes → 2-4 chars) */
    remain = in_len - i;
    if (remain > 0) {
        val = 0;
        for (j = 0; j < remain; j++) {
            val |= (uint32_t)in[i + j] << (24 - j * 8);
        }

        chars[4] = (val % 85) + 33; val /= 85;
        chars[3] = (val % 85) + 33; val /= 85;
        chars[2] = (val % 85) + 33; val /= 85;
        chars[1] = (val % 85) + 33; val /= 85;
        chars[0] = (val % 85) + 33;

        /* Output remain+1 chars for remain bytes */
        if (pdfmake_buf_append(out, chars, remain + 1) != PDFMAKE_OK) {
            return PDFMAKE_ENOMEM;
        }
    }

    /* End of data marker */
    return pdfmake_buf_append(out, (const uint8_t *)"~>", 2);
}

/*============================================================================
 * LZWDecode — §7.4.4
 *==========================================================================*/

#define LZW_CLEAR_CODE 256
#define LZW_EOD_CODE   257
#define LZW_MAX_CODE   4095  /* 12-bit codes max */

typedef struct {
    int16_t prefix;   /* Index of prefix string, or -1 for single byte */
    uint8_t suffix;   /* Final byte */
    uint16_t length;  /* Total string length */
} lzw_entry_t;

pdfmake_err_t pdfmake_lzw_decode(const uint8_t *in, size_t in_len,
                                 const pdfmake_flate_params_t *params,
                                 pdfmake_buf_t *out)
{
    int early_change;
    int i;
    int next_code;
    int code_bits;
    int prev_code;
    size_t bit_pos;
    int b;
    size_t byte_idx;
    int bit_idx;
    uint8_t first_byte;
    int c;
    lzw_entry_t *table;
    uint8_t *stack;
    pdfmake_buf_t decoded_pred;
    pdfmake_err_t err;
    if (!out) return PDFMAKE_EINVAL;
    if (!in || in_len == 0) return PDFMAKE_OK;

    early_change = params ? params->early_change : 1;

    /* String table: each entry is (prefix_code, suffix_byte, length) */
    table = malloc(sizeof(lzw_entry_t) * (LZW_MAX_CODE + 1));
    if (!table) return PDFMAKE_ENOMEM;

    /* Stack for reversing strings during output */
    stack = malloc(LZW_MAX_CODE + 1);
    if (!stack) {
        free(table);
        return PDFMAKE_ENOMEM;
    }

    /* Initialize table with single-byte entries 0-255 */
    for (i = 0; i < 256; i++) {
        table[i].prefix = -1;
        table[i].suffix = (uint8_t)i;
        table[i].length = 1;
    }

    next_code = 258;  /* First available code after clear/eod */
    code_bits = 9;    /* Current code width */
    prev_code = -1;   /* Previous code, -1 = none */

    /* Bit reader state */
    bit_pos = 0;   /* Current bit position in input */

    /* Helper to read next code (MSB first, unlike DEFLATE) */
    #define READ_CODE(code) do { \
        if (bit_pos + code_bits > in_len * 8) { code = LZW_EOD_CODE; break; } \
        code = 0; \
        for (b = 0; b < code_bits; b++) { \
            byte_idx = (bit_pos + b) / 8; \
            bit_idx = 7 - ((bit_pos + b) % 8); \
            code = (code << 1) | ((in[byte_idx] >> bit_idx) & 1); \
        } \
        bit_pos += code_bits; \
    } while(0)

    /* Output string for a code (uses stack to reverse) */
    #define OUTPUT_STRING(code) do { \
        int stack_pos = 0; \
        int c = code; \
        while (c >= 0) { \
            stack[stack_pos++] = table[c].suffix; \
            c = table[c].prefix; \
        } \
        while (stack_pos > 0) { \
            if (pdfmake_buf_append_byte(out, stack[--stack_pos]) != PDFMAKE_OK) { \
                free(table); free(stack); return PDFMAKE_ENOMEM; \
            } \
        } \
    } while(0)

    for (;;) {
        int code;
        READ_CODE(code);

        if (code == LZW_EOD_CODE) break;

        if (code == LZW_CLEAR_CODE) {
            /* Reset table */
            next_code = 258;
            code_bits = 9;
            prev_code = -1;
            continue;
        }

        /* First code after clear must be < 256 */
        if (prev_code < 0) {
            if (code >= 256) {
                free(table);
                free(stack);
                return PDFMAKE_ECORRUPT;
            }
            OUTPUT_STRING(code);
            prev_code = code;
            continue;
        }

        if (code < next_code) {
            /* Code is in table */
            OUTPUT_STRING(code);
            /* Get first byte of current string */
            c = code;
            while (table[c].prefix >= 0) c = table[c].prefix;
            first_byte = table[c].suffix;
        } else if (code == next_code) {
            /* Special case: code not yet in table (KwKwK) */
            c = prev_code;
            while (table[c].prefix >= 0) c = table[c].prefix;
            first_byte = table[c].suffix;
            /* Output prev_string + first_byte */
            OUTPUT_STRING(prev_code);
            if (pdfmake_buf_append_byte(out, first_byte) != PDFMAKE_OK) {
                free(table);
                free(stack);
                return PDFMAKE_ENOMEM;
            }
        } else {
            /* Invalid code */
            free(table);
            free(stack);
            return PDFMAKE_ECORRUPT;
        }

        /* Add new entry: prev_string + first_byte */
        if (next_code <= LZW_MAX_CODE) {
            table[next_code].prefix = prev_code;
            table[next_code].suffix = first_byte;
            table[next_code].length = table[prev_code].length + 1;
            next_code++;

            /* Increase code size based on EarlyChange parameter */
            if (early_change) {
                /* Increase BEFORE next_code reaches limit */
                if (next_code == (1 << code_bits) && code_bits < 12) {
                    code_bits++;
                }
            } else {
                /* Increase AFTER next_code reaches limit */
                if (next_code == (1 << code_bits) + 1 && code_bits < 12) {
                    code_bits++;
                }
            }
        }

        prev_code = code;
    }

    #undef READ_CODE
    #undef OUTPUT_STRING

    free(table);
    free(stack);

    /* Apply predictor if specified */
    if (params && params->predictor > 1) {
        if (pdfmake_buf_init(&decoded_pred) != PDFMAKE_OK) {
            return PDFMAKE_ENOMEM;
        }

        if (params->predictor == 2) {
            err = pdfmake_tiff_predictor_decode(params->colors, params->bits_per_comp,
                                                 params->columns, out->data, out->len,
                                                 &decoded_pred);
        } else if (params->predictor >= 10 && params->predictor <= 15) {
            err = pdfmake_predictor_decode(params->predictor, params->colors,
                                           params->bits_per_comp, params->columns,
                                           out->data, out->len, &decoded_pred);
        } else {
            pdfmake_buf_free(&decoded_pred);
            return PDFMAKE_EINVAL;
        }

        if (err != PDFMAKE_OK) {
            pdfmake_buf_free(&decoded_pred);
            return err;
        }

        /* Swap buffers */
        pdfmake_buf_free(out);
        *out = decoded_pred;
    }

    return PDFMAKE_OK;
}

/*============================================================================
 * RunLengthDecode — §7.4.5
 *==========================================================================*/

pdfmake_err_t pdfmake_rle_decode(const uint8_t *in, size_t in_len,
                                 pdfmake_buf_t *out)
{
    size_t i;
    uint8_t len_byte;
    size_t count;
    uint8_t byte;
    size_t j;
    if (!out) return PDFMAKE_EINVAL;
    if (!in || in_len == 0) return PDFMAKE_OK;

    i = 0;
    while (i < in_len) {
        len_byte = in[i++];

        if (len_byte == 128) {
            /* EOD marker */
            break;
        } else if (len_byte <= 127) {
            /* Literal run: copy next len_byte+1 bytes */
            count = len_byte + 1;
            if (i + count > in_len) return PDFMAKE_ECORRUPT;
            if (pdfmake_buf_append(out, in + i, count) != PDFMAKE_OK) {
                return PDFMAKE_ENOMEM;
            }
            i += count;
        } else {
            /* Repeat run: repeat next byte 257-len_byte times */
            count = 257 - len_byte;
            if (i >= in_len) return PDFMAKE_ECORRUPT;
            byte = in[i++];
            for (j = 0; j < count; j++) {
                if (pdfmake_buf_append_byte(out, byte) != PDFMAKE_OK) {
                    return PDFMAKE_ENOMEM;
                }
            }
        }
    }

    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_rle_encode(const uint8_t *in, size_t in_len,
                                 pdfmake_buf_t *out)
{
    size_t i;
    size_t run_len;
    uint8_t len_byte;
    size_t lit_start;
    size_t lit_len;
    if (!out) return PDFMAKE_EINVAL;
    if (!in || in_len == 0) {
        /* Empty input: just EOD */
        return pdfmake_buf_append_byte(out, 128);
    }

    i = 0;
    while (i < in_len) {
        /* Look for repeat run (3+ consecutive identical bytes) */
        run_len = 1;
        while (i + run_len < in_len && in[i + run_len] == in[i] && run_len < 128) {
            run_len++;
        }

        if (run_len >= 3) {
            /* Emit repeat run */
            len_byte = (uint8_t)(257 - run_len);
            if (pdfmake_buf_append_byte(out, len_byte) != PDFMAKE_OK ||
                pdfmake_buf_append_byte(out, in[i]) != PDFMAKE_OK) {
                return PDFMAKE_ENOMEM;
            }
            i += run_len;
        } else {
            /* Collect literal run (non-repeating bytes) */
            lit_start = i;
            lit_len = 0;

            while (i < in_len && lit_len < 128) {
                /* Check if next 3+ bytes are identical (start repeat run) */
                if (i + 2 < in_len && in[i] == in[i+1] && in[i] == in[i+2]) {
                    break;
                }
                i++;
                lit_len++;
            }

            if (lit_len > 0) {
                len_byte = (uint8_t)(lit_len - 1);
                if (pdfmake_buf_append_byte(out, len_byte) != PDFMAKE_OK ||
                    pdfmake_buf_append(out, in + lit_start, lit_len) != PDFMAKE_OK) {
                    return PDFMAKE_ENOMEM;
                }
            }
        }
    }

    /* EOD marker */
    return pdfmake_buf_append_byte(out, 128);
}

/*============================================================================
 * Remaining stub filters (CCITTFaxDecode implemented in pdfmake_ccitt.c)
 *==========================================================================*/

/* JBIG2 is complex - stub for now, requires external library */
pdfmake_err_t pdfmake_jbig2_decode(const uint8_t *in, size_t in_len,
                                   const pdfmake_obj_t *params,
                                   pdfmake_buf_t *out)
{
    (void)in; (void)in_len; (void)params; (void)out;
    return PDFMAKE_EUNSUPPORTED;
}

pdfmake_err_t pdfmake_jpx_decode(const uint8_t *in, size_t in_len,
                                 const pdfmake_obj_t *params,
                                 pdfmake_buf_t *out)
{
    /* JPXDecode: passthrough (JPEG 2000 data used as-is by PDF readers) */
    (void)params;
    return pdfmake_buf_append(out, in, in_len);
}
