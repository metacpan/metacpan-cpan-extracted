#include <stdio.h>
#include "bitstream.h"
#include "swf_rgb.h"

int
swf_rgb_parse(bitstream_t *bs, swf_rgb_t *color) {
    int ret;
    color->red = bitstream_getbyte(bs);
    color->green = bitstream_getbyte(bs);
    ret = bitstream_getbyte(bs);
    if (ret < 0) {
      return 1;
    }
    color->blue = ret;
    return 0;
}

int
swf_rgb_build(bitstream_t *bs, swf_rgb_t *color) {
    bitstream_putbyte(bs, color->red);
    bitstream_putbyte(bs, color->green);
    bitstream_putbyte(bs, color->blue);
    return 0;
}

int
swf_rgb_print(swf_rgb_t *color, int indent_depth) {
    print_indent(indent_depth);
    printf("RGB=#%02x%02x%02x\n",
           color->red, color->green, color->blue);
    return 0;
}
