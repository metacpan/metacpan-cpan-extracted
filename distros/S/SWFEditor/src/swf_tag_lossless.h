/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_TAG_LOSSLESS__H__
#define __SWF_TAG_LOSSLESS__H__

#include "swf_rgb.h"
#include "swf_rgba.h"
#include "swf_xrgb.h"
#include "swf_argb.h"
#include "swf_tag.h"

typedef struct swf_tag_lossless_detail_ {
    int image_id;
    unsigned char format;
    unsigned short width, height;
    // format: 3
    unsigned short colormap_count;
    swf_rgb_t *colormap;   // Lossless
    swf_rgba_t *colormap2; // Lossless2
    unsigned char *indices;
    // format: 4,5
    swf_xrgb_t *bitmap;  // Lossless
    swf_argb_t *bitmap2; // Lossless2
} swf_tag_lossless_detail_t;

extern swf_tag_detail_handler_t *swf_tag_lossless_detail_handler(void);

extern void *swf_tag_lossless_create_detail(void);
extern int swf_tag_lossless_input_detail(swf_tag_t *tag,
                                         struct swf_object_ *swf);
extern int swf_tag_lossless_get_cid_detail(swf_tag_t *tag);
extern int swf_tag_lossless_replace_cid_detail(swf_tag_t *tag, int id);
extern unsigned char *swf_tag_lossless_output_detail(swf_tag_t *tag,
                                                     unsigned long *length,
                                                     struct swf_object_ *swf);
extern void swf_tag_lossless_print_detail(swf_tag_t *tag,
                                          struct swf_object_ *swf,
                                          int indent_depth);
extern void swf_tag_lossless2_print_detail(swf_tag_t *tag,
                                           struct swf_object_ *swf);
extern void swf_tag_lossless_destroy_detail(swf_tag_t *tag);

extern unsigned char *swf_tag_lossless_get_png_data(void *detail,
                                                    unsigned long *length,
                                                    int image_id,
                                                    swf_tag_t *tag);
extern int swf_tag_lossless_replace_png_data(void *detail, int image_id,
                                             unsigned char *png_data,
                                             unsigned long png_data_len,
                                             int rgb15,
                                             swf_tag_t *tag);
extern int swf_tag_lossless_replace_gif_data(void *detail, int image_id,
                                             unsigned char *gif_data,
                                             unsigned long gif_data_len,
                                             swf_tag_t *tag);

#endif /* __SWF_TAG_LOSSLESS__H__ */
