/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_TAG_EDIT__H__
#define __SWF_TAG_EDIT__H__

#include "swf_tag.h"
#include "swf_rect.h"
#include "swf_rgba.h"

typedef struct swf_tag_edit_detail_ {
    int edit_id;
    swf_rect_t rect;
    int edit_has_text:1;
    int edit_word_wrap:1;
    int edit_multiline:1;
    int edit_password:1;
    int edit_readonly:1;
    int edit_has_color:1;
    int edit_has_max_length:1;
    int edit_has_font:1;
/*    unsigned char edit_reserved; */
    unsigned char edit_auto_size; // version >= 6
    int edit_has_layout:1;
    int edit_no_select:1;
    int edit_border:1;
/*    int edit_researved:1; */
    int edit_html:1;
    int edit_use_outlines:1;
    // edit has font -- begin
    unsigned short edit_font_id_ref;
    unsigned short edit_font_height;
    // edit has font -- end
    swf_rgba_t edit_color;          // edit has color
    unsigned short edit_max_length; // edit has max length
    // edit has layout -- begin
    unsigned char edit_align;
    unsigned short edit_left_margine;
    unsigned short edit_right_margine;
    signed short edit_indent;
    signed short edit_leading;
    // edit has layout -- end
    char *edit_variable_name;
    char *edit_initial_text; // edit_has text
} swf_tag_edit_detail_t;

extern swf_tag_detail_handler_t *swf_tag_edit_detail_handler(void);

extern void *swf_tag_edit_create_detail(void);
extern int swf_tag_edit_input_detail(swf_tag_t *tag, struct swf_object_ *swf);
extern int swf_tag_edit_get_cid_detail(swf_tag_t *tag);
extern int swf_tag_edit_replace_cid_detail(swf_tag_t *tag, int id);
extern unsigned char *swf_tag_edit_output_detail(swf_tag_t *tag,
                                                 unsigned long *length,
                                                 struct swf_object_ *swf);
extern void swf_tag_edit_print_detail(swf_tag_t *tag,
                                      struct swf_object_ *swf,
                                      int indent_depth);
extern void swf_tag_edit_destroy_detail(swf_tag_t *tag);

extern char *swf_tag_edit_get_string(void *detail,
                                     char *variable_name,
                                     int variable_name_len,
                                     int *error);
extern int swf_tag_edit_replace_string(void *detail,
                                       char *variable_name,
                                       int variable_name_len,
                                       char *initial_text,
                                       int initial_text_len);

#endif /* __SWF_TAG_EDIT__H__ */
