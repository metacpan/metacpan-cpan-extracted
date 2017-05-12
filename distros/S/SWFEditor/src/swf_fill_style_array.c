#include <stdio.h>
#include <stdlib.h> // calloc
#include "bitstream.h"
#include "swf_fill_style_array.h"
#include "swf_tag_shape.h"

int
swf_fill_style_array_parse(bitstream_t *bs,
                           swf_fill_style_array_t *fill_style_array,
                           swf_tag_t *tag) {
    int i;
    int result;
    swf_tag_shape_detail_t *swf_tag_shape = (swf_tag_shape_detail_t *) tag->detail;
    
    fill_style_array->count = bitstream_getbyte(bs);

    if (swf_tag_shape->_parse_condition == SWF_TAG_SHAPE_PARSE_CONDITION_BITMAP) {
        if (fill_style_array->count == 0) {
            return 1;
        }
    }
    
    if ((tag->code != 2) && // ! DefineShape
        (fill_style_array->count == 255)) {
        fill_style_array->count = bitstream_getbytesLE(bs, 2);
    }
    fill_style_array->fill_style = calloc(fill_style_array->count, sizeof(swf_fill_style_t));
    for (i = 0 ; i < fill_style_array->count ; i++) {
        result = swf_fill_style_parse(bs, &(fill_style_array->fill_style[i]), tag);
        if (result) {
            fprintf(stderr, "swf_fill_style_array_parse: swf_fill_style_parse failed i=%d\n", i);
            fill_style_array->count = i;
            return 1;
        }
    }
    return 0;
}

int
swf_fill_style_array_build(bitstream_t *bs,
                           swf_fill_style_array_t *fill_style_array,
                           swf_tag_t *tag) {
    int i;
    int ret;
    if ((tag->code == 2) || // DefineShape
        ((tag->code > 2) && (fill_style_array->count < 255))) {
        bitstream_putbyte(bs, fill_style_array->count);
    } else {
        bitstream_putbyte(bs, 255);
        bitstream_putbytesLE(bs, fill_style_array->count, 2);
    }
    for (i = 0 ; i < fill_style_array->count ; i++) {
        ret = swf_fill_style_build(bs, &(fill_style_array->fill_style[i]), tag);
        if (ret != 0) {
            fprintf(stderr, "swf_fill_style_array_build: swf_fill_style_build failed i=%d/count=%d\n", i, fill_style_array->count);
            return 1;
        }
    }
    return 0;
}

int
swf_fill_style_array_print(swf_fill_style_array_t *fill_style_array,
                           int indent_depth, swf_tag_t *tag) {
    int i;
    print_indent(indent_depth);
    printf("fill_style_array->count=%u\n", fill_style_array->count);
    for (i = 0 ; i < fill_style_array->count ; i++) {
        print_indent(indent_depth);
        printf("[%d] ", i+1);
        swf_fill_style_print(&(fill_style_array->fill_style[i]),
                             indent_depth + 1, tag);
    }
    return 0;
}

int
swf_fill_style_array_delete(swf_fill_style_array_t *fill_style_array) {
    int i;
    for (i = 0 ; i < fill_style_array->count ; i++) {
        swf_fill_style_delete(&(fill_style_array->fill_style[i]));
    }
    free(fill_style_array->fill_style);
    return 0;
}
