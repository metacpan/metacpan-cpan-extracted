/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_TAG_ACTION__H__
#define __SWF_TAG_ACTION__H__

#include "swf_tag.h"
#include "swf_action.h"

typedef struct swf_tag_action_detail_ {
    unsigned short  action_sprite;
    swf_action_list_t *action_list;
} swf_tag_action_detail_t;

extern swf_tag_detail_handler_t *swf_tag_action_detail_handler(void);

extern void *swf_tag_action_create_detail(void);
extern int swf_tag_action_input_detail(swf_tag_t *tag,
                                       struct swf_object_ *swf);
extern int swf_tag_action_get_cid_detail(swf_tag_t *tag);
extern int swf_tag_action_replace_cid_detail(swf_tag_t *tag, int id);
extern unsigned char *swf_tag_action_output_detail(swf_tag_t *tag,
                                                   unsigned long *length,
                                                   struct swf_object_ *swf);
extern void swf_tag_action_print_detail(swf_tag_t *tag,
                                        struct swf_object_ *swf,
                                        int indent_depth);
extern void swf_tag_action_destroy_detail(swf_tag_t *tag);

extern int swf_tag_action_top_append_varibles(swf_tag_t *tag, y_keyvalue_t *kv);
extern int swf_tag_action_replace_strings(swf_tag_t *tag, y_keyvalue_t *kv,
                                          int *modified);

#endif /* __SWF_TAG_ACTION__H__ */
