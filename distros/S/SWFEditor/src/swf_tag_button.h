/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_TAG_BUTTON__H__
#define __SWF_TAG_BUTTON__H__

#include "swf_tag.h"
#include "swf_button_record.h"
#include "swf_button_condaction.h"

typedef struct swf_tag_button_detail_ {
    int button_id;
    int track_as_menu;
    int action_offset;
    swf_button_record_list_t *characters;
    swf_action_list_t *actions;
    swf_button_condaction_list_t *condactions;
} swf_tag_button_detail_t;

extern swf_tag_detail_handler_t *swf_tag_button_detail_handler(void);

extern void *swf_tag_button_create_detail(void);
extern int swf_tag_button_input_detail(swf_tag_t *tag, struct swf_object_ *swf);
extern int swf_tag_button_get_cid_detail(swf_tag_t *tag);
extern int swf_tag_button_replace_cid_detail(swf_tag_t *tag, int id);
extern int *swf_tag_button_character_get_refcid_list(swf_tag_t *tag, int *cid_list_num);
extern int swf_tag_button_character_replace_refcid_list(swf_tag_t *tag, int from_cid, int to_cid);
extern unsigned char *swf_tag_button_output_detail(swf_tag_t *tag,
                                                   unsigned long *length,
                                                   struct swf_object_ *swf);
extern void swf_tag_button_print_detail(swf_tag_t *tag,
                                       struct swf_object_ *swf,
                                       int indent_depth);
extern void swf_tag_button_destroy_detail(swf_tag_t *tag);

#endif /* __SWF_TAG_BUTTON__H__ */
