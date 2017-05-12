/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_OBJECT_H__
#define __SWF_OBJECT_H__

#include "y_keyvalue.h"
#include "swf_header.h"
#include "swf_header.h"
#include "swf_tag.h"
#include "swf_tag_sprite.h"

typedef struct swf_object_ {
    swf_header_t header;
    swf_header_movie_t header_movie;
    swf_tag_t *tag_head, *tag_tail;
    unsigned shape_adjust_mode;
    unsigned compress_level;
} swf_object_t;

#define SWFED_SHAPE_BITMAP_NONE           0
#define SWFED_SHAPE_BITMAP_MATRIX_RESCALE 1
#define SWFED_SHAPE_BITMAP_RECT_RESIZE    2
#define SWFED_SHAPE_BITMAP_TYPE_TILLED    4

extern swf_object_t *swf_object_open(void);
extern void swf_object_close(swf_object_t *swf);
extern int swf_object_input(swf_object_t *swf, unsigned char *data, unsigned long data_len);
extern unsigned char *swf_object_output(swf_object_t *swf, unsigned long *length);
extern void swf_object_print(swf_object_t *swf);

/* --- */

extern int swf_object_rebuild(swf_object_t *swf);
extern void swf_object_purge_contents(swf_object_t *swf);

/* --- */

extern unsigned char *swf_object_get_tagdata(swf_object_t *swf, int tag_seqno,
                                             unsigned long *length);
extern int swf_object_replace_tagdata(swf_object_t *swf, int tag_seqno,
                                      unsigned char *data,
                                      unsigned long length);
extern unsigned char *swf_object_get_tagdata_bycid(swf_object_t *swf,
						   int cid,
						   unsigned long *length);
extern int swf_object_replace_tagdata_bycid(swf_object_t *swf,
					    int cid,
					    unsigned char *data,
					    unsigned long length);
extern unsigned char *swf_object_get_tagcontents_bycid(swf_object_t *swf,
                                                       int cid,
                                                       unsigned long *length);
extern int swf_object_replace_tagcontents_bycid(swf_object_t *swf, int cid,
                                                unsigned char *data,
                                                unsigned long length);
extern int swf_object_remove_tag(swf_object_t *swf, int tag_seqno,
                                 int tag_seqno_in_sprite);
extern int swf_object_print_tagdata(swf_object_t *swf, 
                                    unsigned char *data, unsigned long length);


/* --- */

extern swf_tag_t *swf_object_search_tag_byseqno(swf_object_t *swf,
						int tag_seqno);
extern swf_tag_t *swf_object_search_tag_in_sprite_byseqno(swf_tag_sprite_detail_t *sprite, int tag_seqno);

extern swf_tag_t *swf_object_search_tag_bycid(swf_object_t *swf,
						int cid);
extern swf_tag_t *swf_object_search_shape_tag(swf_object_t *swf,
                                               int shape_id);

extern swf_tag_t *swf_object_search_bitmap_tag(swf_object_t *swf,
                                               int bitmap_id);
extern int swf_object_search_cid_by_bitmap_condition(swf_object_t *swf,
                                                     int width, int height,
                                                     int red, int green, int blue);

/* --- */

extern unsigned char *swf_object_get_shapedata(swf_object_t *swf,
                                               int shape_id,
                                               unsigned long *length);
extern int swf_object_replace_shapedata(swf_object_t *swf, int shape_id,
                                        unsigned char *data,
                                        unsigned long length);
extern int swf_object_set_shape_adjust_mode(swf_object_t *swf, unsigned mode);
extern int swf_object_adjust_shapebitmap(swf_object_t *swf, int bitmap_id,
                                         int old_width, int old_height,
                                         int new_width, int new_height);

extern int swf_object_get_bitmap_size(swf_object_t *swf, int bitmap_id,
                                      int *width, int *height);

/* --- */

extern unsigned char *swf_object_get_jpegdata(swf_object_t *swf, unsigned long *length, int image_id);
extern unsigned char *swf_object_get_alphadata(swf_object_t *swf, unsigned long *length, int image_id);
extern int swf_object_replace_jpegdata(swf_object_t *swf, int image_id,
                                       unsigned char *jpeg_data,
                                       unsigned long jpeg_data_len,
                                       unsigned char *alpha_data,
                                       unsigned long alpha_data_len,
                                       int without_converting);
extern unsigned char *swf_object_get_pngdata(swf_object_t *swf, unsigned long *length, int image_id);
extern int swf_object_replace_pngdata(swf_object_t *swf, int image_id,
                                      unsigned char *png_data,
                                      unsigned long png_data_len, int rgb15);
extern int swf_object_replace_gifdata(swf_object_t *swf, int image_id,
                                      unsigned char *gif_data,
                                      unsigned long gif_data_len);
extern int swf_object_convert_bitmapdata_tojpegtag(swf_object_t *swf);

extern unsigned char *swf_object_get_sounddata(swf_object_t *swf, unsigned long *length, int sound_id);
extern int swf_object_replace_melodata(swf_object_t *swf, int sound_id,
                                       unsigned char *melo_data,
                                       unsigned long melo_data_len);
extern char *swf_object_get_editstring(swf_object_t *swf,
                                       char *variable_name,
                                       int variable_name_len,
                                       int *error);
extern int swf_object_replace_editstring(swf_object_t *swf,
                                         char *variable_name,
                                         int variable_name_len,
                                         char *initial_text,
                                         int initial_text_len);
extern unsigned char *swf_object_get_actiondata(swf_object_t *swf, unsigned long *length, int tag_seqno);
extern int swf_object_insert_action_setvariables(swf_object_t *swf,
                                                 y_keyvalue_t *kv);

extern int swf_object_replace_action_strings(swf_object_t *swf,
                                             y_keyvalue_t *kv);

extern int swf_object_replace_movieclip(swf_object_t *swf,
                                        unsigned char *instance_name,
                                        int instancee_name_len,
                                        unsigned char *swf_data,
                                        int swf_data_len);

extern int swf_object_apply_shapematrix_factor(swf_object_t *swf,int shape_id,
                                               int bitmap_id,
                                               double scale_x, double scale_y,
                                               double rotate_rad,
                                               signed int trans_x,
                                               signed int trans_y);
extern int swf_object_apply_shaperect_factor(swf_object_t *swf,int shape_id,
                                             int bitmap_id,
                                             double scale_x, double scale_y,
                                             signed int trans_x,
                                             signed int trans_y);
extern int swf_object_apply_shapetype_tilled(swf_object_t *swf,int shape_id,
                                             int bitmap_id);


/* --- */

extern int swf_object_is_shape_tagdata(unsigned char *data, int data_len);

extern int swf_object_is_bitmap_tagdata(unsigned char *data, int data_len);
extern int swf_object_replace_tag(struct swf_object_ *swf, 
				  swf_tag_t *old_tag, swf_tag_t *new_tag);


#endif /* __SWF_OBJECT_H__ */
