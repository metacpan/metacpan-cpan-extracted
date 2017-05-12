/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_SHAPE_RECORD_SETUP_H__
#define __SWF_SHAPE_RECORD_SETUP_H__

#include "swf_styles.h"

typedef struct swf_shape_record_setup_ {
    unsigned shape_record_type : 1;
    unsigned shape_reserved : 1; // always zero,  DefineShape 
    unsigned shape_has_new_styles : 1;
    unsigned shape_has_line_style : 1;
    unsigned shape_has_fill_style1 : 1;
    unsigned shape_has_fill_style0 : 1;
    unsigned shape_has_move_to : 1;
    unsigned shape_move_size : 5; // shape_has_move_to == true
    signed /* twips */ shape_move_x; // : shape_move_size;
    signed /* twips */ shape_move_y; // : shape_move_size;
    unsigned shape_fill_style0; // : fill_bits_count; shape_has_fill_style0
    unsigned shape_fill_style1 ; // : fill_bits_count;  shape_has_fill_style1
    unsigned shape_line_style; // : line_bits_count; shape_has_line_style
    swf_styles_t styles;
} swf_shape_record_setup_t;

extern int swf_shape_record_setup_parse(bitstream_t *bs,
                                        swf_shape_record_setup_t *setup,
                                        swf_tag_t *tag);
extern int swf_shape_record_setup_build(bitstream_t *bs,
                                        swf_shape_record_setup_t *setup,
                                        swf_tag_t *tag);
extern int swf_shape_record_setup_print(swf_shape_record_setup_t *setup,
                                        int indent_depth, swf_tag_t *tag);
extern int swf_shape_record_setup_delete(swf_shape_record_setup_t *setup);

#endif /* __SWF_SHAPE_RECORD_SETUP_H__ */
