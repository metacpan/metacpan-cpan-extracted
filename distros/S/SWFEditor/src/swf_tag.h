/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_TAG_H__
#define __SWF_TAG_H__

#include "bitstream.h"
#include "y_keyvalue.h"

struct swf_object_; // swf_object.h

typedef struct swf_tag_ {
    int code;
    unsigned long length;
    int length_longformat;
    //
    unsigned char *data;
    void *detail;
    //
    struct swf_tag_ *prev, *next;
} swf_tag_t;

typedef struct swf_tag_detail_handler_ {
    void          * (*create)   (void);
    int             (*input)    (swf_tag_t *tag, struct swf_object_ *swf);
    int             (*get_cid)  (swf_tag_t *tag);
    int             (*replace_cid) (swf_tag_t *tag, int cid);
    unsigned char * (*output)   (swf_tag_t *tag, unsigned long *length,
                                 struct swf_object_ *swf);
    void            (*print)    (swf_tag_t *tag, struct swf_object_ *swf,
                                 int indent_depth);
    void            (*destroy)  (swf_tag_t *tag);
} swf_tag_detail_handler_t;

typedef struct swf_tag_info_ {
    int id;
    const char *name;
    swf_tag_detail_handler_t *(*detail_handler)(void);
} swf_tag_info_t;

extern swf_tag_info_t *get_swf_tag_info(int tag_id);

extern swf_tag_t *swf_tag_create(bitstream_t *bs);
extern void swf_tag_destroy(swf_tag_t *tag);
extern int swf_tag_build(bitstream_t *bs, swf_tag_t *tag, struct swf_object_ *swf);
extern int swf_tag_rebuild(swf_tag_t *tag, struct swf_object_ *swf);
extern void swf_tag_print(swf_tag_t *tag, struct swf_object_ *swf, int indent_depth);
extern void *swf_tag_create_input_detail(swf_tag_t *tag, struct swf_object_ *swf);
extern void swf_tag_destroy_detail(swf_tag_t *tag);

extern int swf_tag_get_cid(swf_tag_t *tag);
extern int swf_tag_replace_cid(swf_tag_t *tag, int cid);

extern int swf_tag_get_refcid(swf_tag_t *tag);
extern int swf_tag_replace_refcid(swf_tag_t *tag, int cid);

/* image */

extern int swf_tag_get_bitmap_size(swf_tag_t *tag,
                                   int *width, int *height);
extern int swf_tag_get_bitmap_color1stpixel(swf_tag_t *tag,
                                            int *red, int *green, int *blue);

extern unsigned char *swf_tag_get_jpeg_data(swf_tag_t *tag, unsigned long *length, int image_id, swf_tag_t *tag_jpegtables);
extern unsigned char *swf_tag_get_alpha_data(swf_tag_t *tag, unsigned long *length, int image_id);
extern int swf_tag_replace_jpeg_data(swf_tag_t *tag, int image_id,
                                     unsigned char *jpeg_data,
                                     unsigned long jpeg_data_len,
                                     unsigned char *alpha_data,
                                     unsigned long alpha_data_len,
                                     int without_converting);

extern unsigned char *swf_tag_get_png_data(swf_tag_t *tag, unsigned long *length, int image_id);
extern int swf_tag_replace_png_data(swf_tag_t *tag, int image_id,
                                    unsigned char *png_data,
                                    unsigned long png_data_len, int rgb15);
extern int swf_tag_replace_gif_data(swf_tag_t *tag, int image_id,
                                    unsigned char *gif_data,
                                    unsigned long gif_data_len);
extern int swf_tag_convert_bitmap_data_tojpegtag(swf_tag_t *tag);

/* sound */
extern unsigned char *swf_tag_get_sound_data(swf_tag_t *tag,
                                             unsigned long *length,
                                             int sound_id);
extern int swf_tag_replace_melo_data(swf_tag_t *tag, int sound_id,
                                     unsigned char *melo_data,
                                     unsigned long melo_data_len);
/* edit text */

extern char *swf_tag_get_edit_string(swf_tag_t *tag,
                                     char *variable_name,
                                     int variable_name_len,
                                     int *error,
                                     struct swf_object_ *swf);
extern int swf_tag_replace_edit_string(swf_tag_t *tag,
                                       char *variable_name,
                                       int variable_name_len,
                                       char *initial_text,
                                       int initial_text_len,
                                       struct swf_object_ *swf);

extern int swf_tag_apply_shape_matrix_factor(swf_tag_t *tag, int shape_id,
                                             int bitmap_id,
                                             double scale_x, double scale_y,
                                             double rotate_rad,
                                             signed int trans_x,
                                             signed int trans_y,
                                             struct swf_object_ *swf);
extern int swf_tag_apply_shape_rect_factor(swf_tag_t *tag, int shape_id,
                                           int bitmap_id,
                                           double scale_x, double scale_y,
                                           signed int trans_x,
                                           signed int trans_y,
                                           struct swf_object_ *swf);
extern int swf_tag_apply_shape_type_tilled(swf_tag_t *tag, int shape_id,
                                           int bitmap_id,
                                           struct swf_object_ *swf);

extern swf_tag_t *swf_tag_create_action_setvariables(y_keyvalue_t *kv);
extern int swf_tag_put_action_setvariables(swf_tag_t *tag,
                                           y_keyvalue_t *kv,
                                           struct swf_object_ *swf);

extern int swf_tag_replace_action_strings(swf_tag_t *tag,
                                          y_keyvalue_t *kv,
                                          int *modified,
                                          struct swf_object_ *swf);

extern swf_tag_t * swf_tag_move(swf_tag_t *tag);

extern int swf_tag_search_cid_by_bitmap_condition(swf_tag_t *tag,
                                                  int width, int height,
                                                  int red, int green, int blue);


#endif /* __SWF_TAG_H__ */
