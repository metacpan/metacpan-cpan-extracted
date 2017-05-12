#include <stdio.h>
#include <stdlib.h> // calloc
#include "bitstream.h"
#include "swf_line_style_array.h"

int
swf_line_style_array_parse(bitstream_t *bs,
                           swf_line_style_array_t *line_style_array,
                           swf_tag_t *tag) {
    int i;
    int result;
    result = bitstream_getbyte(bs);
    if (result == -1) {
        fprintf(stderr, "swf_line_style_array_parse: bitstream_getbyte failed at (L%d)\n", __LINE__);
        return 1;
    }
    line_style_array->count = result;
    if ((tag->code != 2) && // ! DefineShape
         (line_style_array->count == 255)) {
        result = bitstream_getbytesLE(bs, 2);
        if (result == -1) {
            fprintf(stderr, "swf_line_style_array_parse: bitstream_getbyte failed at (L%d)\n", __LINE__);
            return 1;
        }
        line_style_array->count = result;
    }
    if (10000 < line_style_array->count) { // XXX
        fprintf(stderr, "swf_line_style_array_parse: too many count(%d)\n",
                line_style_array->count);
        line_style_array->count = 0;
        return 1;
    }
    line_style_array->line_style = calloc(line_style_array->count, sizeof(swf_line_style_t));
    for (i = 0 ; i < line_style_array->count ; i++) {
        result = swf_line_style_parse(bs, &(line_style_array->line_style[i]), tag);
        if (result) {
            fprintf(stderr, "swf_line_style_array_parse: swf_line_style_parse failed, change line_style->count %d => %d\n",
                    line_style_array->count, i);
            line_style_array->count = i; // XXX
            return result;
        }
    }
    return 0;
}

int
swf_line_style_array_build(bitstream_t *bs, swf_line_style_array_t *line_style_array, swf_tag_t *tag) {
    int i;
    if ((tag->code == 2) || // DefineShape
        ((tag->code > 2) && (line_style_array->count < 255))) {
        bitstream_putbyte(bs, line_style_array->count);
    } else {
        bitstream_putbyte(bs, 255);
        bitstream_putbytesLE(bs, line_style_array->count, 2);
    }
    for (i = 0 ; i < line_style_array->count ; i++) {
        swf_line_style_build(bs, &(line_style_array->line_style[i]), tag);
    }
    return 0;
}

int
swf_line_style_array_print(swf_line_style_array_t *line_style_array, int indent_depth, swf_tag_t *tag) {
    int i;
    print_indent(indent_depth);
    printf("line_style_array->count=%u\n", line_style_array->count);
    for (i = 0 ; i < line_style_array->count ; i++) {
        swf_line_style_print(&(line_style_array->line_style[i]),
                             indent_depth + 2, tag);
    }
    return 0;
}

int
swf_line_style_array_delete(swf_line_style_array_t *line_style_array) {
    int i;
    for (i = 0 ; i < line_style_array->count ; i++) {
        swf_line_style_delete(&(line_style_array->line_style[i]));
    }
    free(line_style_array->line_style);
    return 0;
}
