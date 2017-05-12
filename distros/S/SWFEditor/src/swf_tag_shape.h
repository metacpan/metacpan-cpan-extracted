/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_TAG_SHAPE__H__
#define __SWF_TAG_SHAPE__H__

#include "swf_rect.h"
#include "swf_morph_shape_with_style.h"
#include "swf_shape_with_style.h"
#include "swf_tag.h"

typedef struct swf_tag_shape_detail_ {
    int shape_id;
    swf_rect_t rect;
    //
    unsigned char is_morph:1;    // DefineMorphShape, DefineMorphShape2
    unsigned char has_strokes:1; // Defineshape4, DefineMorphShape2
    // is_morph
    swf_rect_t rect_morph;   // MorphShape(1) or 2
    //has_strokes
    swf_rect_t stroke_rect;  // Shape4 or MorphShape4
    //// is_morph
    swf_rect_t stroke_rect_morph;   // & MorphShape(1) or 2
    //
    unsigned char define_shape_reserved : 6;    // 6bit reserved area
    unsigned char define_shape_non_scaling_strokes : 1;
    unsigned char define_shape_scaling_strokes : 1;
    // is_morph
    unsigned long offset_morph;
    swf_morph_shape_with_style_t  morph_shape_with_style;
    // else
    swf_shape_with_style_t  shape_with_style;
  /*
   * parse context
   */ 
    swf_styles_count_t _current_styles_count;
    int _current_fill_style_num;
    int _current_line_style_num;
    signed /* twips */ _current_x, _current_y;
    int _parse_condition;
#define SWF_TAG_SHAPE_PARSE_CONDITION_BITMAP 1
} swf_tag_shape_detail_t;

extern swf_tag_detail_handler_t *swf_tag_shape_detail_handler(void);
extern swf_tag_detail_handler_t *swf_tag_shape_cid_handler(void);

extern void *swf_tag_shape_create_detail(void);
extern int swf_tag_shape_input_detail(swf_tag_t *tag, struct swf_object_ *swf);
extern int swf_tag_shape_get_cid_detail(swf_tag_t *tag);
extern int swf_tag_shape_replace_cid_detail(swf_tag_t *tag, int id);
extern int *swf_tag_shape_bitmap_get_refcid_list(swf_tag_t *tag, int *cid_list_num);
extern int swf_tag_shape_bitmap_replace_refcid_list(swf_tag_t *tag, int from_cid, int to_cid);
// dummy start
extern int swf_tag_shape_bitmap_get_refcid(int x);
extern int swf_tag_shape_bitmap_replace_refcid(int y);
// dummy end
extern unsigned char *swf_tag_shape_output_detail(swf_tag_t *tag,
                                                   unsigned long *length,
                                                   struct swf_object_ *swf);
extern void swf_tag_shape_print_detail(swf_tag_t *tag,
                                       struct swf_object_ *swf,
                                       int indent_depth);
extern void swf_tag_shape_destroy_detail(swf_tag_t *tag);

extern int swf_tag_shape_apply_matrix_factor(void *detail, int shape_id,
                                             int bitmap_id,
                                             double scale_x, double scale_y,
                                             double rotate_rad,
                                             signed int trans_x, signed int trans_y);
extern int swf_tag_shape_apply_rect_factor(void *detail, int shape_id,
                                           int bitmap_id,
                                           double scale_x, double scale_y,
                                           signed int trans_x, signed int trans_y);
extern int swf_tag_shape_apply_type_tilled(void *detail, int shape_id, int bitmap_id);

#endif /* __SWF_TAG_SHAPE__H__ */

