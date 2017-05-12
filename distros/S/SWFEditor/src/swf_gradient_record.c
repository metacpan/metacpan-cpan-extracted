#include <stdio.h>
#include "bitstream.h"
#include "swf_gradient_record.h"

int
swf_gradient_record_parse(bitstream_t
                          *bs, swf_gradient_record_t *gradient_record,
                          swf_tag_t *tag) {
    int ret = 0;
    if (tag->code == 46 || tag->code == 84) { // DefineMorph || DefineMorphShape2
        gradient_record->position = bitstream_getbyte(bs);
        swf_rgba_parse(bs, &(gradient_record->rgba));
        gradient_record->position_morph = bitstream_getbyte(bs);
        ret = swf_rgba_parse(bs, &(gradient_record->rgba_morph));
    } else if (tag->code == 32 || tag->code == 83) {
        // DefineShape3 || DefineShape4
        gradient_record->position = bitstream_getbyte(bs);
        ret = swf_rgba_parse(bs, &(gradient_record->rgba));
    } else {
        gradient_record->position = bitstream_getbyte(bs);
        ret = swf_rgb_parse(bs, &(gradient_record->rgb));
    }
    return ret;
}

int
swf_gradient_record_build(bitstream_t *bs,
                          swf_gradient_record_t *gradient_record,
                          swf_tag_t *tag) {
    if (tag->code == 46 || tag->code == 84) { // DefineMorph || DefineMorphShape2
        bitstream_putbyte(bs, gradient_record->position);
        swf_rgba_build(bs, &(gradient_record->rgba));
        bitstream_putbyte(bs, gradient_record->position_morph);
        swf_rgba_build(bs, &(gradient_record->rgba_morph));
    } else if (tag->code == 32 || tag->code == 83) {
        // DefineShape3 || DefineShape4
        bitstream_putbyte(bs, gradient_record->position);
        swf_rgba_build(bs, &(gradient_record->rgba));
    } else {
        bitstream_putbyte(bs, gradient_record->position);
        swf_rgb_build(bs, &(gradient_record->rgb));
    }
    return 0;
}

int
swf_gradient_record_print(swf_gradient_record_t *gradient_record,
                          int indent_depth, swf_tag_t *tag) {
    if (gradient_record == NULL) {
        fprintf(stderr, "swf_gradient_record_print: gradient_record == NULL\n");
        return 1;
    }
    if (tag->code == 46 || tag->code == 84) { // DefineMorph || DefineMorphShape2
        print_indent(indent_depth);
        printf("position=%d\n", gradient_record->position);
        swf_rgba_print(&(gradient_record->rgba), indent_depth);
        print_indent(indent_depth);
        printf("position_morph=%d\n", gradient_record->position_morph);
        swf_rgba_print(&(gradient_record->rgba_morph), indent_depth);
    } else if (tag->code == 32 || tag->code == 83) {
        // DefineShape3 || DefineShape4
        print_indent(indent_depth);
        printf("position=%d\n", gradient_record->position);
        swf_rgba_print(&(gradient_record->rgba), indent_depth);
    } else {
        print_indent(indent_depth);
        printf("position=%d\n", gradient_record->position);
        swf_rgb_print(&(gradient_record->rgb), indent_depth);
    }
    return 0;
}
