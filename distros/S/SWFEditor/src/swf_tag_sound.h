/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_TAG_SOUND__H__
#define __SWF_TAG_SOUND__H__

#include "swf_tag.h"

typedef struct swf_tag_sound_detail_ {
    int sound_id;
    int sound_format:4;
    int sound_rate:2;
    int sound_is_16bits:1;
    int sound_is_stereo:1;
    unsigned long sound_samples_count;
    unsigned char *sound_data;
    unsigned long sound_data_len;
} swf_tag_sound_detail_t;

extern swf_tag_detail_handler_t *swf_tag_sound_detail_handler(void);

extern void *swf_tag_sound_create_detail(void);
extern int swf_tag_sound_input_detail(swf_tag_t *tag, struct swf_object_ *swf);
extern int swf_tag_sound_get_cid_detail(swf_tag_t *tag);
extern int swf_tag_sound_replace_cid_detail(swf_tag_t *tag, int id);
extern unsigned char *swf_tag_sound_output_detail(swf_tag_t *tag,
                                                  unsigned long *length,
                                                  struct swf_object_ *swf);
extern void swf_tag_sound_print_detail(swf_tag_t *tag,
                                       struct swf_object_ *swf,
                                       int indent_depth);
extern void swf_tag_sound_destroy_detail(swf_tag_t *tag);

extern unsigned char *swf_tag_sound_get_sound_data(void *detail, unsigned long *length,
                                        int sound_id);
extern int swf_tag_sound_replace_mp3_data(void *detail, int sound_id,
                                          unsigned char *mp3_data,
                                          unsigned long mp3_data_len);

extern int swf_tag_sound_replace_melo_data(void *detail, int sound_id,
                                              unsigned char *sound_data,
                                              unsigned long sound_data_len);

#endif /* __SWF_TAG_SOUND__H__ */
