#include <stdio.h>
#include "bitstream.h"
#include "swf_styles_count.h"

int
swf_styles_count_parse(bitstream_t *bs, swf_styles_count_t *styles_count) {
    int result;
    bitstream_align(bs);
    styles_count->fill_bits_count = bitstream_getbits(bs, 4);
    result = bitstream_getbits(bs, 4);
    if (result == -1) {
        return 1;
    }
    styles_count->line_bits_count = result;
    return 0;
}

int
swf_styles_count_build(bitstream_t *bs, swf_styles_count_t *styles_count) {
    bitstream_align(bs);
    bitstream_putbits(bs, styles_count->fill_bits_count, 4);
    bitstream_putbits(bs, styles_count->line_bits_count, 4);
    return 0;
}

int
swf_styles_count_print(swf_styles_count_t *styles_count, int indent_depth) {
    print_indent(indent_depth);
    printf("fill_bits_count=%d  line_bits_count=%d\n",
           styles_count->fill_bits_count, styles_count->line_bits_count);
    return 0;
}
