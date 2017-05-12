/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_TAG_PLACE__H__
#define __SWF_TAG_PLACE__H__

#include "swf_matrix.h"
#include "swf_cxform.h"
#include "swf_cxformwithalpha.h"
#include "swf_tag.h"

typedef struct swf_tag_place_detail_ {
    int character_id; //  optional if PlaceObject2
    int flag_has_clip_action;
    int flag_has_clip_depth;
    int flag_has_name;
    int flag_has_ratio;
    int flag_has_color_transform;
    int flag_has_matrix;
    int flag_has_character;
    int flag_has_move;
    int depth;
    swf_matrix_t matrix;
    swf_cxform_t color_transform; // PlaceObject
    swf_cxformwithalpha_t color_transform_with_alpha; // PlaceObject2
    int ratio;  // PlaceObject2
    char *name; // PlaceObject2
    int clip_depth; // PlaceObject2
} swf_tag_place_detail_t;

extern swf_tag_detail_handler_t *swf_tag_place_detail_handler(void);

extern void *swf_tag_place_create_detail(void);
extern int swf_tag_place_input_detail(swf_tag_t *tag, struct swf_object_ *swf);
extern unsigned char *swf_tag_place_output_detail(swf_tag_t *tag,
                                                   unsigned long *length,
                                                   struct swf_object_ *swf);
extern void swf_tag_place_print_detail(swf_tag_t *tag,
                                       struct swf_object_ *swf,
                                       int indent_depth);
extern void swf_tag_place_destroy_detail(swf_tag_t *tag);

extern int swf_tag_place_get_cid_by_instance_name(swf_tag_t *tag, unsigned char *instance_name, int instance_name_len, struct swf_object_ *swf);

#endif /* __SWF_TAG_PLACE__H__ */

