#include <stdio.h>
#include "bitstream.h"
#include "swf_shape_record_edge.h"
#include "swf_tag_shape.h"

int
swf_shape_record_edge_parse(bitstream_t *bs,
                            swf_shape_record_edge_t *shape_record_edge,
                            swf_tag_t *tag) {
    int result;
    unsigned int shape_coord_real_size;
    swf_tag_shape_detail_t *swf_tag_shape = (swf_tag_shape_detail_t *) tag->detail;

    result = bitstream_getbit(bs);
    if (result == -1) {
        return 1;
    }
    shape_record_edge->shape_record_type = result;
    shape_record_edge->shape_edge_type   = bitstream_getbit(bs);
    shape_record_edge->shape_coord_size  = bitstream_getbits(bs, 4);
    shape_coord_real_size = shape_record_edge->shape_coord_size + 2;
    if (shape_record_edge->shape_edge_type == 0) {
        signed control_delta_x, control_delta_y;
        signed anchor_delta_x, anchor_delta_y;
        control_delta_x = bitstream_getbits_signed(bs, shape_coord_real_size);
        control_delta_y = bitstream_getbits_signed(bs, shape_coord_real_size);
        anchor_delta_x = bitstream_getbits_signed(bs, shape_coord_real_size);
        anchor_delta_y = bitstream_getbits_signed(bs, shape_coord_real_size);

        swf_tag_shape->_current_x += control_delta_x;
        swf_tag_shape->_current_y += control_delta_y;
        shape_record_edge->shape_control_x = swf_tag_shape->_current_x;
        shape_record_edge->shape_control_y = swf_tag_shape->_current_y;
        swf_tag_shape->_current_x += anchor_delta_x;
        swf_tag_shape->_current_y += anchor_delta_y;
        shape_record_edge->shape_anchor_x = swf_tag_shape->_current_x;
        shape_record_edge->shape_anchor_y = swf_tag_shape->_current_y;
    } else {
        shape_record_edge->shape_line_has_x_and_y = bitstream_getbit(bs);
        if (shape_record_edge->shape_line_has_x_and_y == 1) {
            signed delta_x, delta_y;
            delta_x = bitstream_getbits_signed(bs, shape_coord_real_size);
            delta_y = bitstream_getbits_signed(bs, shape_coord_real_size);
            swf_tag_shape->_current_x += delta_x;
            swf_tag_shape->_current_y += delta_y;
        } else {
            shape_record_edge->shape_line_has_x_or_y = bitstream_getbit(bs);
            if (shape_record_edge->shape_line_has_x_or_y == 0) {
                signed delta_x;
                delta_x = bitstream_getbits_signed(bs, shape_coord_real_size);
                swf_tag_shape->_current_x += delta_x;
            } else {
                signed delta_y;
                delta_y = bitstream_getbits_signed(bs, shape_coord_real_size);
                swf_tag_shape->_current_y += delta_y;
            }
        }
	shape_record_edge->shape_x = swf_tag_shape->_current_x;
	shape_record_edge->shape_y = swf_tag_shape->_current_y;
    }
    return 0;
}

int
swf_shape_record_edge_build(bitstream_t *bs,
                            swf_shape_record_edge_t *shape_record_edge,
                            swf_tag_t *tag) {
//    int ret;
    unsigned int size, shape_coord_real_size = 2;
    swf_tag_shape_detail_t *swf_tag_shape = (swf_tag_shape_detail_t *) tag->detail;
    
    bitstream_putbit(bs, shape_record_edge->shape_record_type);
    bitstream_putbit(bs, shape_record_edge->shape_edge_type);

    if (shape_record_edge->shape_edge_type == 0) {
        size = bitstream_need_bits_signed(shape_record_edge->shape_control_x - swf_tag_shape->_current_x);
        shape_coord_real_size =  (shape_coord_real_size>size)?shape_coord_real_size:size;
        size = bitstream_need_bits_signed(shape_record_edge->shape_control_y - swf_tag_shape->_current_y);
        shape_coord_real_size =  (shape_coord_real_size>size)?shape_coord_real_size:size;
        size = bitstream_need_bits_signed(shape_record_edge->shape_anchor_x - shape_record_edge->shape_control_x);
        shape_coord_real_size =  (shape_coord_real_size>size)?shape_coord_real_size:size;
        size = bitstream_need_bits_signed(shape_record_edge->shape_anchor_y - shape_record_edge->shape_control_y);
        shape_coord_real_size =  (shape_coord_real_size>size)?shape_coord_real_size:size;
    } else {
        size = bitstream_need_bits_signed(shape_record_edge->shape_x - swf_tag_shape->_current_x);
	shape_coord_real_size =  (shape_coord_real_size>size)?shape_coord_real_size:size;
	size = bitstream_need_bits_signed(shape_record_edge->shape_y - swf_tag_shape->_current_y);
	shape_coord_real_size =  (shape_coord_real_size>size)?shape_coord_real_size:size;
    }
    shape_record_edge->shape_coord_size = shape_coord_real_size - 2;
    bitstream_putbits(bs, shape_record_edge->shape_coord_size, 4);

    if (shape_record_edge->shape_edge_type == 0) {
        signed control_delta_x = shape_record_edge->shape_control_x - swf_tag_shape->_current_x;
        signed control_delta_y = shape_record_edge->shape_control_y - swf_tag_shape->_current_y;
        signed anchor_delta_x = shape_record_edge->shape_anchor_x - shape_record_edge->shape_control_x;
        signed anchor_delta_y = shape_record_edge->shape_anchor_y - shape_record_edge->shape_control_y;
        bitstream_putbits_signed(bs, control_delta_x, shape_coord_real_size);
        bitstream_putbits_signed(bs, control_delta_y, shape_coord_real_size);
        bitstream_putbits_signed(bs, anchor_delta_x, shape_coord_real_size);
        bitstream_putbits_signed(bs, anchor_delta_y, shape_coord_real_size);
	swf_tag_shape->_current_x = shape_record_edge->shape_anchor_x;
	swf_tag_shape->_current_y = shape_record_edge->shape_anchor_y;
    } else {
        signed delta_x = shape_record_edge->shape_x - swf_tag_shape->_current_x;
        signed delta_y = shape_record_edge->shape_y - swf_tag_shape->_current_y;
        if (delta_x && delta_y) {
            shape_record_edge->shape_line_has_x_and_y = 1;
        } else {
            shape_record_edge->shape_line_has_x_and_y = 0;
        }
        bitstream_putbit(bs, shape_record_edge->shape_line_has_x_and_y);
        if (shape_record_edge->shape_line_has_x_and_y == 1) {
            bitstream_putbits_signed(bs, delta_x, shape_coord_real_size);
            bitstream_putbits_signed(bs, delta_y, shape_coord_real_size);
        } else {
            if (delta_x) {
                shape_record_edge->shape_line_has_x_or_y = 0;
            } else {
                shape_record_edge->shape_line_has_x_or_y = 1;
            }
            bitstream_putbit(bs, shape_record_edge->shape_line_has_x_or_y);
            if (shape_record_edge->shape_line_has_x_or_y == 0) {
                bitstream_putbits_signed(bs, delta_x, shape_coord_real_size);
            } else {
                bitstream_putbits_signed(bs, delta_y, shape_coord_real_size);
            }
        }
	swf_tag_shape->_current_x = shape_record_edge->shape_x;
	swf_tag_shape->_current_y = shape_record_edge->shape_y;
    }
    return 0;
}

int
swf_shape_record_edge_print(swf_shape_record_edge_t *shape_record_edge,
                            int indent_depth) {
    print_indent(indent_depth);
    printf("shape_edge_type=%d  (shape_coord_size=%d+2)\n",
           shape_record_edge->shape_edge_type ,
           shape_record_edge->shape_coord_size);
    if (shape_record_edge->shape_edge_type == 0) {
        print_indent(indent_depth);
        printf("shape_control_(x,y)=(%.2f,%.2f)  shape_anchor_(x,y)=(%.2f,%.2f)\n",
               (float) shape_record_edge->shape_control_x / SWF_TWIPS,
               (float) shape_record_edge->shape_control_y / SWF_TWIPS,
               (float) shape_record_edge->shape_anchor_x / SWF_TWIPS,
               (float) shape_record_edge->shape_anchor_y / SWF_TWIPS);
    } else {
        print_indent(indent_depth);
/*
  printf("shape_line_has_(x_and_y, x_or_y)=(%d, %d)  ",
               shape_record_edge->shape_line_has_x_and_y,
               shape_record_edge->shape_line_has_x_or_y);
*/
        printf("shape_(x,y)=(%.2f,%.2f)\n",
               (float) shape_record_edge->shape_x / SWF_TWIPS,
               (float) shape_record_edge->shape_y / SWF_TWIPS);
    }
    return 0;
}
