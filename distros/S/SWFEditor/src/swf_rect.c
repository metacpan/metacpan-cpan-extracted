#include <stdio.h>
#include "bitstream.h"
#include "swf_rect.h"

int
swf_rect_parse(bitstream_t *bs, swf_rect_t *rect) {
    int size;
    bitstream_align(bs);
    size = bitstream_getbits(bs, 5);
    if (size == -1) {
        return 1;
    }
    rect->size = size;
    rect->x_min = bitstream_getbits_signed(bs, size);
    rect->x_max = bitstream_getbits_signed(bs, size);
    rect->y_min = bitstream_getbits_signed(bs, size);
    rect->y_max = bitstream_getbits_signed(bs, size);
    return 0;
}

int
swf_rect_build(bitstream_t *bs, swf_rect_t *rect) {
    register unsigned char size;
    unsigned char x_min_bits = bitstream_need_bits_signed(rect->x_min);
    unsigned char x_max_bits = bitstream_need_bits_signed(rect->x_max);
    unsigned char y_min_bits = bitstream_need_bits_signed(rect->y_min);
    unsigned char y_max_bits = bitstream_need_bits_signed(rect->y_max);
    size = (x_min_bits>x_max_bits)?x_min_bits:x_max_bits;
    size = (size>y_min_bits)?size:y_min_bits;
    size = (size>y_max_bits)?size:y_max_bits;
    
    bitstream_align(bs);
    bitstream_putbits(bs, size, 5);
    bitstream_putbits_signed(bs, rect->x_min, size);
    bitstream_putbits_signed(bs, rect->x_max, size);
    bitstream_putbits_signed(bs, rect->y_min, size);
    bitstream_putbits_signed(bs, rect->y_max, size);
    return 0;
}

int
swf_rect_print(swf_rect_t *rect, int indent_depth) {
    print_indent(indent_depth);
    printf("rect=(%d, %d)-(%d, %d) (f_size=%d)\n",
           rect->x_min / SWF_TWIPS,
           rect->y_min / SWF_TWIPS,
           rect->x_max / SWF_TWIPS,
           rect->y_max / SWF_TWIPS,
           rect->size);
    return 0;
}

int swf_rect_apply_factor(swf_rect_t *rect,
                          double scale_x, double scale_y,
                          signed int trans_x, signed int trans_y) {
    int size_x = rect->x_max - rect->x_min;
    int size_y = rect->y_max - rect->y_min;
    rect->x_max = rect->x_min + size_x * scale_x;
    rect->y_max = rect->y_min + size_y * scale_y;
    rect->x_min += trans_x * SWF_TWIPS;
    rect->x_max += trans_x * SWF_TWIPS;
    rect->y_min += trans_y * SWF_TWIPS;
    rect->y_max += trans_y * SWF_TWIPS;
    return 0;
}
