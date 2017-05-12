#include <stdio.h>
#include "bitstream.h"
#include "swf_shape_record_setup.h"
#include "swf_tag_shape.h"

int
swf_shape_record_setup_parse(bitstream_t *bs,
                             swf_shape_record_setup_t *shape_record_setup,
                             swf_tag_t *tag) {
    swf_tag_shape_detail_t *swf_tag_shape = (swf_tag_shape_detail_t *) tag->detail;
    swf_styles_count_t *count = &(swf_tag_shape->_current_styles_count);
    int ret;
    shape_record_setup->shape_record_type = bitstream_getbit(bs);
    shape_record_setup->shape_has_new_styles = bitstream_getbit(bs);
    shape_record_setup->shape_has_line_style = bitstream_getbit(bs);
    shape_record_setup->shape_has_fill_style1 = bitstream_getbit(bs);
    shape_record_setup->shape_has_fill_style0 = bitstream_getbit(bs);
    shape_record_setup->shape_has_move_to = bitstream_getbit(bs);
    if (shape_record_setup->shape_has_move_to) {
        int shape_move_size;
        shape_move_size = bitstream_getbits(bs, 5);
        shape_record_setup->shape_move_size = shape_move_size;
        shape_record_setup->shape_move_x = bitstream_getbits_signed(bs, shape_move_size);
        shape_record_setup->shape_move_y = bitstream_getbits_signed(bs, shape_move_size);
        swf_tag_shape->_current_x = shape_record_setup->shape_move_x;
        swf_tag_shape->_current_y = shape_record_setup->shape_move_y;
    }
    if (shape_record_setup->shape_has_fill_style0) {
        shape_record_setup->shape_fill_style0 = bitstream_getbits(bs, count->fill_bits_count);
    }
    if (shape_record_setup->shape_has_fill_style1) {
        shape_record_setup->shape_fill_style1 = bitstream_getbits(bs, count->fill_bits_count);
    }
    if (shape_record_setup->shape_has_line_style) {
        shape_record_setup->shape_line_style = bitstream_getbits(bs, count->line_bits_count);
    }
    if (shape_record_setup->shape_has_new_styles) {
        ret = swf_styles_parse(bs, &(shape_record_setup->styles), tag);
        if (ret) {
            fprintf(stderr, "swf_shape_record_setup_parse: swf_styles_parse failed\n");
            return ret;
        }
    }
    return 0;
}

int
swf_shape_record_setup_build(bitstream_t *bs,
                             swf_shape_record_setup_t *shape_record_setup,
                             swf_tag_t *tag) {
    swf_tag_shape_detail_t *swf_tag_shape = (swf_tag_shape_detail_t *) tag->detail;
    swf_styles_count_t *count = &(swf_tag_shape->_current_styles_count);
    bitstream_putbit(bs, shape_record_setup->shape_record_type);
    bitstream_putbit(bs, shape_record_setup->shape_has_new_styles);
    bitstream_putbit(bs, shape_record_setup->shape_has_line_style);
    bitstream_putbit(bs, shape_record_setup->shape_has_fill_style1);
    bitstream_putbit(bs, shape_record_setup->shape_has_fill_style0);
    bitstream_putbit(bs, shape_record_setup->shape_has_move_to);
    if (shape_record_setup->shape_has_move_to) {
        unsigned int size, shape_move_size = 0;
        size = bitstream_need_bits_signed(shape_record_setup->shape_move_x);
        shape_move_size =  (shape_move_size>size)?shape_move_size:size;
        size = bitstream_need_bits_signed(shape_record_setup->shape_move_y);
        shape_move_size =  (shape_move_size>size)?shape_move_size:size;
        shape_record_setup->shape_move_size = shape_move_size;
        bitstream_putbits(bs, shape_move_size, 5);
        bitstream_putbits_signed(bs, shape_record_setup->shape_move_x,
                                 shape_move_size);
        bitstream_putbits_signed(bs, shape_record_setup->shape_move_y,
                                 shape_move_size);
        swf_tag_shape->_current_x = shape_record_setup->shape_move_x;
        swf_tag_shape->_current_y = shape_record_setup->shape_move_y;
    }
    if (shape_record_setup->shape_has_fill_style0) {
        bitstream_putbits(bs, shape_record_setup->shape_fill_style0,
                          count->fill_bits_count);
    }
    if (shape_record_setup->shape_has_fill_style1) {
        bitstream_putbits(bs, shape_record_setup->shape_fill_style1,
                          count->fill_bits_count);

    }
    if (shape_record_setup->shape_has_line_style) {
        bitstream_putbits(bs, shape_record_setup->shape_line_style,
                  count->line_bits_count);
    }
    if (shape_record_setup->shape_has_new_styles) {
        swf_styles_build(bs, &(shape_record_setup->styles), tag);
    }
    return 0;
}

int
swf_shape_record_setup_print(swf_shape_record_setup_t *shape_record_setup,
                             int indent_depth, swf_tag_t *tag) {
    print_indent(indent_depth);
    printf("shape_has_{new_styles,line_styles, fill_style1, fill_style0, move_to}={%d,%d,%d,%d,%d}\n",
           shape_record_setup->shape_has_new_styles,
           shape_record_setup->shape_has_line_style,
           shape_record_setup->shape_has_fill_style1,
           shape_record_setup->shape_has_fill_style0,
           shape_record_setup->shape_has_move_to);
    if (shape_record_setup->shape_has_move_to) {
        print_indent(indent_depth);
        printf("shape_move_x=%.2f  shape_move_y=%.2f\n",
               (float) shape_record_setup->shape_move_x / SWF_TWIPS,
               (float) shape_record_setup->shape_move_y / SWF_TWIPS);
    }
    if (shape_record_setup->shape_has_fill_style0) {
        print_indent(indent_depth);
        printf("shape_fill_style0=%d\n",
               shape_record_setup->shape_fill_style0);
    }
    if (shape_record_setup->shape_has_fill_style1) {
        print_indent(indent_depth);
        printf("shape_fill_style1=%d\n",
               shape_record_setup->shape_fill_style1);
    }
    if (shape_record_setup->shape_has_line_style) {
        print_indent(indent_depth);
        printf("shape_line_style=%d\n",
               shape_record_setup->shape_line_style);
    }
    if (shape_record_setup->shape_has_new_styles) {
        swf_styles_print(&(shape_record_setup->styles), indent_depth + 1,
                         tag);
    }

    return 0;
}

int
swf_shape_record_setup_delete(swf_shape_record_setup_t *setup) {
    if (setup->shape_has_new_styles) {
        swf_styles_delete(&(setup->styles));
    }
    return 0;
}
