/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_TAG_JPEG__H__
#define __SWF_TAG_JPEG__H__

#include "swf_tag.h"

typedef struct swf_tag_jpeg_detail_ {
    int image_id;
    unsigned char *jpeg_data; // jpeg or png or gif
    unsigned long  jpeg_data_len;
    unsigned long  offset_to_alpha;
    unsigned char *alpha_data;
    unsigned long  alpha_data_len;
} swf_tag_jpeg_detail_t;

extern swf_tag_detail_handler_t *swf_tag_jpeg_detail_handler(void);
extern swf_tag_detail_handler_t *swf_tag_jpegt_detail_handler(void);
extern swf_tag_detail_handler_t *swf_tag_jpeg3_detail_handler(void);

extern void *swf_tag_jpeg_create_detail(void);

extern int swf_tag_jpeg_input_detail(swf_tag_t *tag, struct swf_object_ *swf);
extern int swf_tag_jpegt_input_detail(swf_tag_t *tag, struct swf_object_ *swf);
extern int swf_tag_jpeg3_input_detail(swf_tag_t *tag, struct swf_object_ *swf);
extern int swf_tag_jpeg_get_cid_detail(swf_tag_t *tag);
extern int swf_tag_jpeg_replace_cid_detail(swf_tag_t *tag, int id);
extern unsigned char *swf_tag_jpeg_output_detail(swf_tag_t *tag,
                                                 unsigned long *length,
                                                 struct swf_object_ *swf);
extern unsigned char *swf_tag_jpegt_output_detail(swf_tag_t *tag,
                                                  unsigned long *length,
                                                  struct swf_object_ *swf);
extern unsigned char *swf_tag_jpeg3_output_detail(swf_tag_t *tag,
                                                  unsigned long *length,
                                                  struct swf_object_ *swf);
extern void swf_tag_jpeg_print_detail(swf_tag_t *tag,
                                      struct swf_object_ *swf,
                                      int indent_depth);
extern void swf_tag_jpeg_destroy_detail(swf_tag_t *tag);

extern unsigned char *swf_tag_jpeg_get_jpeg_data(void *detail,
                                                 unsigned long *length,
                                                 int image_id,
                                                 unsigned char *jpeg_table_data,
                                                 unsigned long jpeg_table_data_len);
extern unsigned char *swf_tag_jpeg_get_alpha_data(void *detail, unsigned long *length, int image_id);
extern int swf_tag_jpeg_replace_jpeg_data(void *detail, int image_id,
                                          unsigned char *jpeg_data,
                                          unsigned long jpeg_data_len,
                                          unsigned char *alpha_data,
                                          unsigned long alpha_data_len,
                                          swf_tag_t *tag);
extern int swf_tag_jpeg_replace_bitmap_data(void *detail, int image_id,
                                            unsigned char *bitmapg_data,
                                            unsigned long bitmap_data_len,
                                            swf_tag_t *tag);

#endif /* __SWF_TAG_JPEG__H__ */
