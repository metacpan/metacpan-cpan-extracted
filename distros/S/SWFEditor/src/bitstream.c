/*
 * bit stream routine
 *                     (C) 2008/03/09- yoya@awm.jp
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "bitstream.h"

static void bitstream_clear(bitstream_t *bs);


#ifdef BITSTREAM_DEBUG /* bitstream debug */

#undef bitstream_open
#undef bitstream_close

#define BITSTREAM_DEBUG_TABLE_NUM 0x40000

static struct bitstream_debug_ {
    void *ptr;
    char *filename;
    int  linenum;
} bitstream_debug_table[BITSTREAM_DEBUG_TABLE_NUM];

static int bitstream_debug_stack = 0;

void
bitstream_debug_start(void) {
    int i;
    bitstream_debug_stack ++;
    if (bitstream_debug_stack > 1) {
        fprintf(stderr, "bitstream_debug_start: bitstream_debug_stack=%d\n", bitstream_debug_stack);
        return ;
    }
    for (i=0 ; i < BITSTREAM_DEBUG_TABLE_NUM ; i++) {
        bitstream_debug_table[i].ptr = NULL;
    }
    fprintf(stderr, "bitstream_debug_start: 0/n=0/%d\n", BITSTREAM_DEBUG_TABLE_NUM);
}

void
bitstream_debug_end(void) {
    int i, j = 0;
    bitstream_debug_stack --;
    if (bitstream_debug_stack > 0) {
        fprintf(stderr, "bitstream_debug_end: bitstream_debug_stack=%d\n", bitstream_debug_stack);
        return ;
    }
    for (i=0 ; i < BITSTREAM_DEBUG_TABLE_NUM ; i++) {
        if (bitstream_debug_table[i].ptr) {
            fprintf(stderr, "XXX (%d) ptr=%p (%s, %d)\n",
                    i, bitstream_debug_table[i].ptr,
                    bitstream_debug_table[i].filename,
                    bitstream_debug_table[i].linenum);
            j = i + 1;
        }
    }
    fprintf(stderr, "bitstream_debug_end: j/n=%d/%d\n", j, BITSTREAM_DEBUG_TABLE_NUM);
}

bitstream_t *
bitstream_open_debug(char *filename, int linenum) {
    int i;
    void *ptr;
    ptr = bitstream_open();
    for (i=0 ; i < BITSTREAM_DEBUG_TABLE_NUM ; i++) {
        if (bitstream_debug_table[i].ptr == NULL) {
            bitstream_debug_table[i].ptr = ptr;
            bitstream_debug_table[i].filename = filename;
            bitstream_debug_table[i].linenum = linenum;
            break;
        }
    }
    return ptr;
}

void
bitstream_close_debug(bitstream_t * bs,  char *filename, int linenum) {
    int i;
    void *ptr = bs;
//    fprintf(stderr, "free_debug: ptr=%p (%s,%d)\n", ptr, filename, linenum);
    for (i=0 ; i < BITSTREAM_DEBUG_TABLE_NUM ; i++) {
        if (bitstream_debug_table[i].ptr == ptr) {
            bitstream_debug_table[i].ptr = NULL;
            break;
        }
    }
    if (i == BITSTREAM_DEBUG_TABLE_NUM) {
        char *p;
        fprintf(stderr, "free non-allocated memory: ptr=%p (%s,%d)\n", ptr,
                filename, linenum);
        bitstream_debug_end();
        p = ptr;
        p = 0;
    }
    bitstream_close(bs);
}

#endif // BITSTREAM_DEBUG

bitstream_t *
bitstream_open(void) {
    bitstream_t *bs = (bitstream_t *) calloc(sizeof(*bs), 1);

    bs->data = NULL;
    bs->data_len = 0;
    bs->data_alloc_len = 0;
    bs->byte_offset = 0;
    bs->bit_offset = 0;
    return bs;
}

void
bitstream_close(bitstream_t * bs) {
    if (bs->data) {
        free(bs->data);
        bs->data = NULL;
    }
    free(bs);
    return ;
}

static void
bitstream_clear(bitstream_t *bs) {
    if (bs->data) {
        free(bs->data);
        bs->data = NULL;
    }
    bs->data_len = 0;
    bs->data_alloc_len = 0;
    bs->byte_offset = 0;
    bs->bit_offset = 0;
    return ;
}

int
bitstream_realloc(bitstream_t *bs) {
    unsigned char *data;
    bs->data_alloc_len *= 2;
    if (bs->data_alloc_len < BITSTREAM_DATA_LEN_MIN) {
        bs->data_alloc_len = BITSTREAM_DATA_LEN_MIN;
    }
    data = (unsigned char *) realloc(bs->data, bs->data_alloc_len);
    if (! data) {
        fprintf(stderr, "bitstream_realloc: Can't realloc memory (%p, %lu)\n",
                bs->data, bs->data_alloc_len);
        return 1;
    }
    bs->data = data;
    return 0;
}

int
bitstream_input(bitstream_t *bs, unsigned char *data,
                   unsigned long data_len) {
    bitstream_clear(bs);
    bs->data_alloc_len = data_len;
    if (bs->data) {
        free(bs->data);
    }
    bs->data = malloc(bs->data_alloc_len);
    if (bs->data == NULL) {
        fprintf(stderr, "bitstream_input: malloc failed\n");
        bs->data_alloc_len = 0;
        bs->data_len = 0;
        return 1;
    }
    memcpy(bs->data, data, data_len);
    bs->data_len = data_len;
    return 0;
}

unsigned char *
bitstream_steal(bitstream_t *bs, unsigned long *length) {
    unsigned char *data, *tmp;
    *length = 0;
    if (bs == NULL) {
        fprintf(stderr, "bitstream_steal: bs == NULL\n");
        return NULL;
    }
    data = bs->data;
    *length = bs->data_len;
    if ((tmp = realloc(data, *length)) == NULL) {
        fprintf(stderr, "bitstream_steal: Can't realloc\n");
        return NULL;
    }
    bs->data = NULL;
    bs->data_len = 0;
    bs->data_alloc_len = 0;
    return tmp;
}

unsigned char *
bitstream_output_sub(bitstream_t *bs, unsigned long offset, unsigned long length) {
    unsigned char *data;
    if (bs == NULL) {
        fprintf(stderr, "bitstream_output_sub: bs == NULL\n");
        return NULL;
    }
    if (bs->data_len < offset + length ) {
        fprintf(stderr, "bitstream_output_sub: bs->data_len(%lu) < offset(%lu)+length(%lu)\n",
                bs->data_len, offset, length);
        return NULL;
    }
    data = malloc(length);
    if (data == NULL) {
        fprintf(stderr, "bitstream_output_sub: Can't malloc\n");
        return NULL;
    }
    memcpy(data, bs->data + offset, length);
    return data;
}

/*
 * byte stream
 */

int
bitstream_putbyte(bitstream_t *bs, int byte) {
    bitstream_align(bs);
    if (bs->data_len < bs->byte_offset ) {
        return 1;
    }
    if (bs->data_len == bs->byte_offset ) {
        if (bs->data_alloc_len <= bs->byte_offset ) {
            bitstream_realloc(bs);
        }
        bs->data_len ++;
    }
    byte &= 0xff;
    bs->data[bs->byte_offset++] = (unsigned char) byte ;
    return 0;
}

int
bitstream_getbyte(bitstream_t *bs) {
    bitstream_align(bs);
    if (bs->data_len <= bs->byte_offset) {
        return -1; /* End of Stream */
    }
    return bs->data[bs->byte_offset++] & 0xff;
}

int
bitstream_putstring(bitstream_t *bs,
                               unsigned char *data, signed long data_len) {
    bitstream_align(bs);
    if (bs->data_len < bs->byte_offset ) {
        return 1;
    }
    while(bs->data_alloc_len < bs->byte_offset + data_len) {
        bitstream_realloc(bs);
    }
    bs->data_len = bs->byte_offset + data_len;
    memcpy(bs->data + bs->byte_offset, data, data_len);
    bs->byte_offset += data_len;
    return 0;
}

int
bitstream_getstring(bitstream_t *bs,
                               unsigned char *data, signed long data_len) {
    bitstream_align(bs);
    if (bs->data_len < bs->byte_offset + data_len) {
        return -1; /* End of Stream */
    }
    memcpy(data, bs->data + bs->byte_offset, data_len);
    bs->byte_offset += data_len;
    return 0;
}

unsigned char *
bitstream_outputstring(bitstream_t *bs) {
    unsigned char *data;
    register unsigned long data_len;
    bitstream_align(bs);
    data_len = strlen((char *) bs->data + bs->byte_offset);
    data_len += 1; // + '\0'
    if (bs->data_len < bs->byte_offset + data_len) {
        return NULL; /* End of Stream */
    }
    data = malloc(data_len);
    if (data == NULL) {
        fprintf(stderr, "bitstream_outputstring: can't malloc\n");
        return NULL;
    }
    memcpy(data, bs->data + bs->byte_offset, data_len);
    bs->byte_offset += data_len;
    return data;
}

int
bitstream_putbytesLE(bitstream_t *bs, unsigned long bytes, int byte_width) {
    register int i;
    register unsigned long tmp_bytes = bytes;
    for (i=0 ; i < byte_width ; i++) {
        bitstream_putbyte(bs, tmp_bytes & 0xff);
        tmp_bytes >>= 8;
    }
    return 0;
}

int
bitstream_putbytesBE(bitstream_t *bs, unsigned long bytes, int byte_width) {
    register int i;
    register unsigned long tmp_bytes = bytes;
    for (i=0 ; i < byte_width ; i++) {
        bitstream_putbyte(bs, (tmp_bytes >> ( 8 * (byte_width - 1 - i))) & 0xff);
    }
    return 0;
}

unsigned long
bitstream_getbytesLE(bitstream_t *bs, int byte_width) {
    register int i;
    register int byte;
    register unsigned long bytes = 0;
    for (i=0 ; i < byte_width ; i++) {
        byte = bitstream_getbyte(bs);
        if (byte == -1) {
            return -1; // End of Stream;
        }
        byte <<= 8 * i;
        bytes |= byte;
    }
    return bytes;
}

unsigned long
bitstream_getbytesBE(bitstream_t *bs, int byte_width) {
    register int i;
    register int byte;
    register unsigned long bytes = 0;
    for (i=0 ; i < byte_width ; i++) {
        bytes <<= 8;
        byte = bitstream_getbyte(bs);
        if (byte == -1) {
            return -1; // End of Stream;
        }
        bytes |= byte;
    }
    return bytes;
}

/*
 * bit stream
 */

int
bitstream_putbit(bitstream_t *bs, int bit) {
    if (bs->data_len <= bs->byte_offset) {
        if (bs->data_alloc_len <= bs->byte_offset) {
//            fprintf(stderr, "bitstream_putbit: alloc_len=%lu\n", bs->data_alloc_len);
            bitstream_realloc(bs);
        }
        bs->data[bs->byte_offset] = 0;
        bs->data_len ++;
    }
    bs->data[bs->byte_offset] |= (bit & 1) << (7 - bs->bit_offset);
    bitstream_incrpos(bs, 0, 1);
    return 0;
}
int
bitstream_getbit(bitstream_t *bs) {
    register int bit;
    if (bs->data_len <= bs->byte_offset) {
        fprintf(stderr, "bitstream_getbit: bs->data_len(%lu) <= bs->byte_offset(%lu)\n",
                bs->data_len, bs->byte_offset);
        return -1; /* End of Stream */
    }
    bit = bs->data[bs->byte_offset] >> (7 - bs->bit_offset);
    bitstream_incrpos(bs, 0, 1);
    return bit & 1;
}

int
bitstream_putbits(bitstream_t *bs, unsigned long bits, int bit_width) {
    register int i = bit_width;
    while (i--) {
        bitstream_putbit(bs, (bits >> i) & 1);
    }
    return 0;
}

int
bitstream_putbits_signed(bitstream_t *bs, signed long bits, int bit_width) {
    if (bits < 0) {
        register signed long msb = 1 << (bit_width - 1);
        register signed long bitmask = (msb << 1) - 1;
        bits = (-bits  - 1) ^ bitmask;
    }
    return bitstream_putbits(bs, bits, bit_width);
}

#if BITOPERATION_OPTIMIZE == 1
unsigned long
bitstream_getbits(bitstream_t *bs, int bit_width) {
    register unsigned long bits;
    register int byte_offset = bs->byte_offset;
    register int bit_offset  = bs->bit_offset;
    if (bs->data_len <= byte_offset + (bit_offset + bit_width) >> 3) {
        fprintf(stderr, "bitstream_getbits: bs->data_len(%lu) <= byte_offset(%lu) + (bit_offset(%lu) + bit_width(%d)) >> 3\n",
                bs->data_len, bs->byte_offset, bs->bit_offset , bit_width);
        return -1; /* End of Stream */
    }
    if ((bit_offset + bit_width) < 9) {
        bits = (bs->data[byte_offset] >> (8 - bit_offset - bit_width)) & bitstream_bitmask_list[bit_width];
        bit_offset += bit_width;
    } else {
        register int len = 8 - bit_offset;
        bits = bs->data[byte_offset] & bitstream_bitmask_list[len];
        bit_offset += len;
        bit_width -= len;
        bits <<= bit_width;
        while (1) {
            if (bit_width < 9) {
                bits |= ((bs->data[++byte_offset] >> (8 - bit_width))) & bitstream_bitmask_list[bit_width];
                bit_offset += bit_width - 8;
                break;
            } else {
                bits |= bs->data[++byte_offset];
                bit_width -= 8;
                bits <<= 8;
            }
        }
    }
    bitstream_setpos(bs, byte_offset, bit_offset);
    return bits;
}
#else // BITOPERATION_OPTIMIZE
unsigned long
bitstream_getbits(bitstream_t *bs, int bit_width) {
    register int i, bit;
    register unsigned long bits = 0;
    for (i=0 ; i < bit_width ; i++) {
        bit = bitstream_getbit(bs);
        if (bit == -1) {
            return -1;
        }
        bits |= bit << (bit_width - 1 - i);
    }
    return bits;
}
#endif // BITOPERATION_OPTIMIZE

signed long
bitstream_getbits_signed(bitstream_t *bs, int bit_width) {
    register signed long bits = bitstream_getbits(bs, bit_width);
    register signed long msb =  bits & (1 << (bit_width - 1));
    if (msb) {
        register signed long bitmask = (msb << 1) - 1;
        bits = - (bits ^ bitmask) - 1;
    }
    return bits;
}

void
bitstream_align(bitstream_t *bs) {
    if (bs->bit_offset > 0) {
        bs->byte_offset++;
        bs->bit_offset = 0;
    }
}

/*
 * stream seek
 */

int
bitstream_incrpos(bitstream_t *bs, signed long byte_incr,
                  signed long bit_incr) {
    register signed long byte_offset, bit_offset;
    if (bit_incr < 0) {
        byte_offset = bs->byte_offset - ((-bit_incr + 7) >> 3);
        bit_offset = bs->bit_offset + (bit_incr % 8) + 8;
    } else {
        byte_offset = bs->byte_offset + byte_incr;
        bit_offset = bs->bit_offset + bit_incr;
    }
    if (bit_offset < 8) {
        bs->byte_offset = byte_offset;
        bs->bit_offset = bit_offset;
    } else {
        bs->byte_offset = byte_offset + (bit_offset >> 3);
        bs->bit_offset = bit_offset & 7;
    }
    return 0;
}

int
bitstream_setpos(bitstream_t *bs, unsigned long byte_offset,
		     unsigned long bit_offset) {
    if (bs->data_len < byte_offset ) {
        fprintf(stderr, "bitstream_setpos: bs->data_len(%lu) <= byte_offset(%lu)\n",
                bs->data_len, byte_offset);
    }
    bs->byte_offset = byte_offset;
    bs->bit_offset = bit_offset;
    return 0;
}

unsigned long
bitstream_getbytepos(bitstream_t *bs) {
    return bs->byte_offset;
}

unsigned long
bitstream_getbitpos(bitstream_t *bs) {
    return bs->bit_offset;
}

/*
 * stream info
 */

unsigned char *
bitstream_buffer(bitstream_t *bs, unsigned long byte_offset) {
    return bs->data + byte_offset;
}

unsigned long
bitstream_length(bitstream_t *bs) {
    return bs->data_len;
}

unsigned long
bitstream_hasnext(bitstream_t *bs, int byte_len, int bit_len) {
    int byte_offset = bs->byte_offset + byte_len;
    int bit_offset  = bs->bit_offset  + bit_len;
    if (bs->data_len < (byte_offset + (bit_offset + 7) / 8)) {
        return 0; // false
    }
    return 1; // true
}

/*
 * utility
 */

signed long
bitstream_unsigned2signed(unsigned long num, int size) {
    register unsigned long sig_bit = 1 << (size - 1);
    if ((sig_bit & num) == 0) {
        return (signed long) num;
    } else {
        unsigned long mask = sig_bit - 1;
        return - ((num^mask) & mask) - 1;
    }
}

unsigned long
bitstream_signed2unsigned(signed long num, int size) { // XXX check me!
    if (0 <= num){
        return (unsigned long) num;
    } else {
        unsigned long sig_bit = 1 << (size - 1);
        unsigned long mask = sig_bit - 1;
        return - ((num^mask) & mask) - 1;
    }
}

int
bitstream_need_bits_unsigned(unsigned long n) {
    register int i;
    for (i = 0 ; n ; i++) {
        n >>= 1;
    }
    return i;
}

int
bitstream_need_bits_signed(signed long n) {
    register int ret;
    if (n < -1) {
        n = -1 - n;
    }
    if (n >= 0) {
        register int i;
        for (i = 0 ; n ; i++) {
            n >>= 1;
        }
        ret = 1 + i;
        ;
    } else { // n == -1
        ret = 1;
    }
    return ret;
}

/*
 * error handling
 */

int
bitstream_iserror(bitstream_t *bs) {
    (void) bs;
    return 0;
}

void
bitstream_printerror(bitstream_t *bs) {
    (void) bs;
}

/*
 * for debug
 */

void
bitstream_hexdump(bitstream_t *bs, int length) {
    register unsigned long i, j;
    for ( i = bs->byte_offset ; i < bs->byte_offset + length ; i++) {
        if ((i == bs->byte_offset) || (i%16) == 0) {
            printf("%08lu: ", i);
            if ((i%16) != 0) {
                for( j = 0 ; j < (i%16) ; j++) {
                    printf("   ");
                }
            }
        }
        printf("%02x ", bs->data[i] & 0xff);
        if ((i%16) == 7) {
            printf(" ");
        }
        if ((i%16) == 15) {
            printf("\n");
        }
    }
    if ((i%16) != 0) {
        printf("\n");
    }
}

void
bitstream_print(bitstream_t *bs) {
    printf("data=%p  data_len=%lu data_alloc_len=%lu\n",
           bs->data, bs->data_len, bs->data_alloc_len);
    printf("byte_offset=%lu  bit_offset=%lu\n",
           bs->byte_offset, bs->bit_offset);
}
