#ifndef __BITSTREAM_H__
#define __BITSTREAM_H__

#include "swf_define.h" /* for malloc */

/*
 * bit stream routine
 *                     (C) 2008/03/09- yoya@awm.jp
 */

#ifndef BITOPERATION_OPTIMIZE
#define BITOPERATION_OPTIMIZE 0
#endif

typedef struct bitstream_ {
    /* raw data */
    unsigned char *data;
    unsigned long data_len;
    unsigned long data_alloc_len;
    /* seek position */
    unsigned long byte_offset;
    unsigned long bit_offset;
    /* error */
    int error;
    
} bitstream_t;

#define BITSTREAM_DATA_LEN_MIN 0x100

#define BITSTREAM_ERROR_NONE 0
#define BITSTREAM_ERROR_NOMORE_DATA 1

extern bitstream_t *bitstream_open(void);
extern void bitstream_close(bitstream_t * bs);

/* load/save */
extern int bitstream_input(bitstream_t *bs, unsigned char *data,
			  unsigned long data_len);
extern unsigned char *bitstream_steal(bitstream_t *bs, unsigned long *length);
extern unsigned char *bitstream_output_sub(bitstream_t *bs, unsigned long offset, unsigned long length);

/* put/get */
extern int bitstream_putbyte(bitstream_t *bs, int byte);
extern int bitstream_getbyte(bitstream_t *bs);
extern int bitstream_putstring(bitstream_t *bs,
                               unsigned char *data, signed long data_len);
extern int bitstream_getstring(bitstream_t *bs,
                               unsigned char *data, signed long data_len);
extern unsigned char *bitstream_outputstring(bitstream_t *bs);

extern int bitstream_putbytesLE(bitstream_t *bs, unsigned long bytes, int byte_width);
extern int bitstream_putbytesBE(bitstream_t *bs, unsigned long bytes, int byte_width);
extern unsigned long bitstream_getbytesLE(bitstream_t *bs, int byte_width);
extern unsigned long bitstream_getbytesBE(bitstream_t *bs, int byte_width);
extern int bitstream_putbit(bitstream_t *bs, int bit);
extern int bitstream_getbit(bitstream_t *bs);
extern int bitstream_putbits(bitstream_t *bs, unsigned long bits, int bit_width);
extern int bitstream_putbits_signed(bitstream_t *bs, signed long bits, int bit_width);
extern unsigned long bitstream_getbits(bitstream_t *bs, int bit_width);
extern signed long bitstream_getbits_signed(bitstream_t *bs, int bit_width);
extern void bitstream_align(bitstream_t *bs);

/* seeking */
extern int bitstream_incrpos(bitstream_t *bs, signed long byte_incr,
                             signed long bit_incr);
extern int bitstream_setpos(bitstream_t *bs, unsigned long byte_offset,
			    unsigned long bit_offset);
extern unsigned long bitstream_getbytepos(bitstream_t *bs);
extern unsigned long bitstream_getbitpos(bitstream_t *bs);

extern int bitstream_realloc(bitstream_t *bs);

/* direct access */
extern unsigned char *bitstream_buffer(bitstream_t *bs, unsigned long byte_offset);
extern unsigned long bitstream_length(bitstream_t *bs);
extern unsigned long bitstream_hasnext(bitstream_t *bs,
				       int byte_len, int bit_len);


/* utility */

extern signed long bitstream_unsigned2signed(unsigned long num, int size);
extern unsigned long bitstream_signed2unsigned(signed long num, int size);

extern int bitstream_need_bits_unsigned(unsigned long n);
extern int bitstream_need_bits_signed(signed long n);

/* error handling  */
extern int bitstream_iserror(bitstream_t *bs);
extern void bitstream_printerror(bitstream_t *bs);

/* for debug */
extern void bitstream_hexdump(bitstream_t *bs, int length);
extern void bitstream_print(bitstream_t *bs);


#ifdef BITSTREAM_DEBUG /* bitstream debug */

extern void bitstream_debug_start(void);
extern void bitstream_debug_end(void);

#define bitstream_open()  bitstream_open_debug(__FILE__, __LINE__)
#define bitstream_close(bs)  bitstream_close_debug(bs, __FILE__, __LINE__)
extern bitstream_t *bitstream_open_debug(char *filename, int linenum);
extern void bitstream_close_debug(bitstream_t *bs, char *filename, int linenum);

#else // BITSTREAM_DEBUG

#define bitstream_debug_start()
#define bitstream_debug_end()

#endif // BITSTREAM_DEBUG

#endif /* __BITSTREAM_H__ */
