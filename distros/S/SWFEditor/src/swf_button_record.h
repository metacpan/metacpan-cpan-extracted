/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_BUTTON_RECORD_H__
#define __SWF_BUTTON_RECORD_H__

#include "swf_matrix.h"
#include "swf_cxformwithalpha.h"
#include "swf_tag.h"

typedef struct swf_button_record_ {
    // char align;
    int button_has_blend_mode ;
    unsigned char button_has_filter_list : 1;
    unsigned char button_state_hittest : 1;
    unsigned char button_state_down : 1;
    unsigned char button_state_over : 1;
    unsigned char button_state_up : 1;
    int character_id;
    int place_depth;
    swf_matrix_t place_matrix;
    swf_cxformwithalpha_t color_transform;
// not implemented yet. (swf 8 later only)
//    swf_filterlist_t *filter_list;
//    int blend_mode;
    struct swf_button_record_ *next;
} swf_button_record_t;

typedef struct swf_button_record_list_ {
    swf_button_record_t *head, *tail;
} swf_button_record_list_t;

extern int swf_button_record_parse(bitstream_t *bs, swf_button_record_t *button_record, swf_tag_t *tag);
extern int swf_button_record_build(bitstream_t *bs, swf_button_record_t *button_record, swf_tag_t *tag);
extern void swf_button_record_destroy(swf_button_record_t *button_record);
extern int swf_button_record_print(swf_button_record_t *button_record, int indent_depth, swf_tag_t *tag);

extern swf_button_record_list_t *swf_button_record_list_create(void);
extern int swf_button_record_list_parse(bitstream_t *bs, swf_button_record_list_t *button_record_list, swf_tag_t *tag);
extern int swf_button_record_list_build(bitstream_t *bs, swf_button_record_list_t *button_record_list, swf_tag_t *tag);
extern void swf_button_record_list_destroy(swf_button_record_list_t *button_record_list);
extern int swf_button_record_list_print(swf_button_record_list_t *button_record_list, int indent_depth_list, swf_tag_t *tag);

#endif /* __SWF_BUTTON_RECORD_H__ */

