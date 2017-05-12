#include <stdio.h>
#include "bitstream.h"
#include "swf_gradient.h"

int
swf_gradient_parse(bitstream_t *bs, swf_gradient_t *gradient,
                   swf_tag_t *tag, int type) {
    int i;
    bitstream_align(bs);
    if (tag->code == 83) { // DefineShape4
        gradient->spread_mode = bitstream_getbits(bs, 2);
        gradient->interpolation_mode = bitstream_getbits(bs, 2);
        gradient->count = bitstream_getbits(bs, 4);
    } else {
        gradient->pad = bitstream_getbits(bs, 4);
        gradient->count = bitstream_getbits(bs, 4);
    }
    if (gradient->count == 0) {
        gradient->gradient_record = NULL;
    } else {
        gradient->gradient_record = calloc(gradient->count, sizeof(*gradient->gradient_record));
	for (i = 0 ; i < gradient->count ; i++) {
	    swf_gradient_record_parse(bs, &(gradient->gradient_record[i]),
				      tag);
	}
    }
    if (type == 0x13) {
        gradient->focal_point = bitstream_getbytesLE(bs, 2);
    }
    return 0;
}

int
swf_gradient_build(bitstream_t *bs, swf_gradient_t *gradient,
                   swf_tag_t *tag, int type) {
    int i;
    bitstream_align(bs);
    if (tag->code == 83) { // DefineShape4
        bitstream_putbits(bs, gradient->spread_mode, 2);
        bitstream_putbits(bs, gradient->interpolation_mode, 2);
        bitstream_putbits(bs, gradient->count, 4);
    } else {
        bitstream_putbits(bs, gradient->pad, 4);
        bitstream_putbits(bs, gradient->count, 4);
    }
    for (i = 0 ; i < gradient->count ; i++) {
        swf_gradient_record_build(bs, &(gradient->gradient_record[i]), tag);
    }
    if (type == 0x13) {
        bitstream_putbytesLE(bs, gradient->focal_point, 2);
    }
    return 0;
}

int
swf_gradient_print(swf_gradient_t *gradient, int indent_depth,
                   swf_tag_t *tag, int type) {
    int i;
    if (tag->code == 83) { // DefineShape4
        print_indent(indent_depth);
        printf("spread_mode=%d  interpolation_mode=%d  count=%d\n",
               gradient->spread_mode, gradient->interpolation_mode,
               gradient->count);
    } else {
        print_indent(indent_depth);
        printf("gradient->count=%d\n", gradient->count);
    }
    for (i = 0 ; i < gradient->count ; i++) {
        swf_gradient_record_print(&(gradient->gradient_record[i]), indent_depth+1, tag);
    }
    if (type == 0x13) {
        print_indent(indent_depth);
        printf("focal_point=%d\n", gradient->focal_point);
    }
    return 0;
}

int
swf_gradient_delete(swf_gradient_t *gradient) {
    free(gradient->gradient_record);
    return 0;
}

