/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_TAG_SPRITE__H__
#define __SWF_TAG_SPRITE__H__

#include "swf_tag.h"

typedef struct swf_tag_sprite_detail_ {
    int sprite_id;
    unsigned short frame_count;
    swf_tag_t *tag;
} swf_tag_sprite_detail_t;

extern swf_tag_detail_handler_t *swf_tag_sprite_detail_handler(void);

extern void *swf_tag_sprite_create_detail(void);
extern int swf_tag_sprite_input_detail(swf_tag_t *tag, struct swf_object_ *swf);
extern int swf_tag_sprite_get_cid_detail(swf_tag_t *tag);
extern int swf_tag_sprite_replace_cid_detail(swf_tag_t *tag, int id);
extern unsigned char *swf_tag_sprite_output_detail(swf_tag_t *tag,
                                                   unsigned long *length,
                                                   struct swf_object_ *swf);
extern void swf_tag_sprite_print_detail(swf_tag_t *tag,
                                        struct swf_object_ *swf,
                                        int indent_depth);
extern void swf_tag_sprite_destroy_detail(swf_tag_t *tag);

#endif /* __SWF_TAG_SPRITE__H__ */
