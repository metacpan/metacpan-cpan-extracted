/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_SHAPE_RECORD_EDGE_H__
#define __SWF_SHAPE_RECORD_EDGE_H__

#include "swf_styles.h"

typedef struct swf_shape_record_edge_ {
    unsigned shape_record_type : 1;
    unsigned shape_edge_type : 1;
    unsigned shape_coord_size : 4;
    //  shape_coord_real_size =  shape_coord_size + 2;
    signed /* twips */ shape_control_x; // :  shape_coord_real_size;
    signed /* twips */ shape_control_y; // :  shape_coord_real_size;
    signed /* twips */ shape_anchor_x; // :  shape_coord_real_size;
    signed /* twips */ shape_anchor_y; // :  shape_coord_real_size;
    unsigned shape_line_has_x_and_y : 1;
    unsigned shape_line_has_x_or_y : 1;
    signed /* twips */ shape_x; // :  shape_coord_real_size;
    signed /* twips */ shape_y; // :  shape_coord_real_size;
} swf_shape_record_edge_t;

extern int swf_shape_record_edge_parse(bitstream_t *bs, swf_shape_record_edge_t *color, swf_tag_t *tag);
extern int swf_shape_record_edge_build(bitstream_t *bs, swf_shape_record_edge_t *color, swf_tag_t *tag);
extern int swf_shape_record_edge_print(swf_shape_record_edge_t *color, int indent_depth);

#endif /* __SWF_SHAPE_RECORD_EDGE_H__ */
