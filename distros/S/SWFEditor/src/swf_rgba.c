#include <stdio.h>
#include "bitstream.h"
#include "swf_rgba.h"

int
swf_rgba_parse(bitstream_t *bs, swf_rgba_t *color) {
    int ret;
    color->red   = bitstream_getbyte(bs);
    color->green = bitstream_getbyte(bs);
    color->blue  = bitstream_getbyte(bs);
    ret = bitstream_getbyte(bs);
    if (ret < 0) {
      return 1;
    }
    color->alpha = ret;
    return 0;
}

int
swf_rgba_build(bitstream_t *bs, swf_rgba_t *color) {
    bitstream_putbyte(bs, color->red);
    bitstream_putbyte(bs, color->green);
    bitstream_putbyte(bs, color->blue);
    bitstream_putbyte(bs, color->alpha);
    return 0;
}

int
swf_rgba_print(swf_rgba_t *color, int indent_depth) {
    print_indent(indent_depth);
    printf("RGB(A)=#%02x%02x%02x(%02x)\n",
           color->red, color->green, color->blue, color->alpha);
    return 0;
}
