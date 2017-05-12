/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#include <stdio.h>
#include <string.h>
#include "bitstream.h"
#include "swf_tag_edit.h"
#include "swf_object.h"
#include "swf_rgba.h"

swf_tag_detail_handler_t edit_detail_handler;

swf_tag_detail_handler_t *
swf_tag_edit_detail_handler(void) {
    edit_detail_handler.create   = swf_tag_edit_create_detail;
    edit_detail_handler.input    = swf_tag_edit_input_detail;
    edit_detail_handler.get_cid  = swf_tag_edit_get_cid_detail;
    edit_detail_handler.replace_cid = swf_tag_edit_replace_cid_detail;
    edit_detail_handler.output   = swf_tag_edit_output_detail;
    edit_detail_handler.print    = swf_tag_edit_print_detail;
    edit_detail_handler.destroy  = swf_tag_edit_destroy_detail;
    return &edit_detail_handler;
}

void *
swf_tag_edit_create_detail(void) {
    swf_tag_edit_detail_t *swf_tag_edit;
    swf_tag_edit = calloc(sizeof(*swf_tag_edit), 1);
    if (swf_tag_edit == NULL) {
        fprintf(stderr, "ERROR: swf_tag_edit_create_detail: can't calloc\n");
        return NULL;
    }
    return swf_tag_edit;
}

int
swf_tag_edit_input_detail(swf_tag_t *tag, struct swf_object_ *swf) {
    swf_tag_edit_detail_t *swf_tag_edit = tag->detail;
    unsigned char *data  = tag->data;
    unsigned long length = tag->length;
    bitstream_t *bs;
    if (swf_tag_edit == NULL) {
        fprintf(stderr, "ERROR: swf_tag_edit_input_detail: swf_tag_edit == NULL\n");
        return 1;
    }
    bs = bitstream_open();
    bitstream_input(bs, data, length);
    swf_tag_edit->edit_id = bitstream_getbytesLE(bs, 2);
    swf_rect_parse(bs, &swf_tag_edit->rect);
    bitstream_align(bs);
    swf_tag_edit->edit_has_text       = bitstream_getbit(bs);
    swf_tag_edit->edit_word_wrap      = bitstream_getbit(bs);
    swf_tag_edit->edit_multiline      = bitstream_getbit(bs);
    swf_tag_edit->edit_password       = bitstream_getbit(bs);
    swf_tag_edit->edit_readonly       = bitstream_getbit(bs);
    swf_tag_edit->edit_has_color      = bitstream_getbit(bs);
    swf_tag_edit->edit_has_max_length = bitstream_getbit(bs);
    swf_tag_edit->edit_has_font       = bitstream_getbit(bs);
    if (swf && (swf->header.version >= 6)) {
        (void) bitstream_getbit(bs); // reserved;
        swf_tag_edit->edit_auto_size = bitstream_getbit(bs);
    } else {
        (void) bitstream_getbit(bs); // reserved;
        (void) bitstream_getbit(bs); // reserved;
    }
    swf_tag_edit->edit_has_layout   = bitstream_getbit(bs);
    swf_tag_edit->edit_no_select    = bitstream_getbit(bs);
    swf_tag_edit->edit_border       = bitstream_getbit(bs);
    (void) bitstream_getbit(bs); // reserved;
    swf_tag_edit->edit_html         = bitstream_getbit(bs);
    swf_tag_edit->edit_use_outlines = bitstream_getbit(bs);
    if (swf_tag_edit->edit_has_font) {
        swf_tag_edit->edit_font_id_ref = bitstream_getbytesLE(bs, 2);
        swf_tag_edit->edit_font_height = bitstream_getbytesLE(bs, 2);
    }
    if (swf_tag_edit->edit_has_color) {
        swf_rgba_parse(bs, &swf_tag_edit->edit_color);
    }
    if (swf_tag_edit->edit_has_max_length) {
        swf_tag_edit->edit_max_length = bitstream_getbytesLE(bs, 2);
    }
    if (swf_tag_edit->edit_has_layout) {
        swf_tag_edit->edit_align = bitstream_getbyte(bs);
        swf_tag_edit->edit_left_margine = bitstream_getbytesLE(bs, 2);
        swf_tag_edit->edit_right_margine = bitstream_getbytesLE(bs, 2);
        swf_tag_edit->edit_indent = (signed) bitstream_getbytesLE(bs, 2);
        swf_tag_edit->edit_leading = (signed) bitstream_getbytesLE(bs, 2);
    }
    swf_tag_edit->edit_variable_name = (char *) bitstream_outputstring(bs);
    if (swf_tag_edit->edit_has_text) {
        swf_tag_edit->edit_initial_text = (char *) bitstream_outputstring(bs);
    } else {
        swf_tag_edit->edit_initial_text = NULL;
    }
    
    bitstream_close(bs);
    return 0;
}

int swf_tag_edit_get_cid_detail(swf_tag_t *tag) {
    unsigned char *data = tag->data;
    if (tag->detail) {
        swf_tag_edit_detail_t *swf_tag_edit = (swf_tag_edit_detail_t *) tag->detail;
        return swf_tag_edit->edit_id;
    }
    if (data == NULL) {
        fprintf(stderr, "swf_tag_edit_get_cid_detail: data == NULL\n");
        return -1;
    }
    return GetUShortLE(data); // edit_id;
}

int swf_tag_edit_replace_cid_detail(swf_tag_t *tag, int id) {
    unsigned char *data = tag->data;
    if (tag->detail) {
        swf_tag_edit_detail_t *swf_tag_edit = (swf_tag_edit_detail_t *) tag->detail;
        swf_tag_edit->edit_id = id;
    }
    if (data) {
        PutUShortLE(data, id);
    }
    return 0; // always 0
}

unsigned char *
swf_tag_edit_output_detail(swf_tag_t *tag, unsigned long *length,
                           struct swf_object_ *swf) {
    swf_tag_edit_detail_t *swf_tag_edit = (swf_tag_edit_detail_t *) tag->detail;
    bitstream_t *bs;
    unsigned char *data;
    (void) tag;
    *length = 0;
    bs = bitstream_open();
    bitstream_putbytesLE(bs, swf_tag_edit->edit_id, 2);
    swf_rect_build(bs, &swf_tag_edit->rect);
    bitstream_align(bs);
    bitstream_putbit(bs, swf_tag_edit->edit_has_text);
    bitstream_putbit(bs, swf_tag_edit->edit_word_wrap);
    bitstream_putbit(bs, swf_tag_edit->edit_multiline);
    bitstream_putbit(bs, swf_tag_edit->edit_password );
    bitstream_putbit(bs, swf_tag_edit->edit_readonly);
    bitstream_putbit(bs, swf_tag_edit->edit_has_color );
    bitstream_putbit(bs, swf_tag_edit->edit_has_max_length);
    bitstream_putbit(bs, swf_tag_edit->edit_has_font);
    if (swf && (swf->header.version >= 6)) {
        bitstream_putbit(bs, 0); // reserved;
        bitstream_putbit(bs, swf_tag_edit->edit_auto_size);
    } else {
        bitstream_putbit(bs, 0); // reserved;
        bitstream_putbit(bs, 0); // reserved;
    }
    bitstream_putbit(bs, swf_tag_edit->edit_has_layout);
    bitstream_putbit(bs, swf_tag_edit->edit_no_select);
    bitstream_putbit(bs, swf_tag_edit->edit_border);
    bitstream_putbit(bs, 0); // reserved;
    bitstream_putbit(bs, swf_tag_edit->edit_html);
    bitstream_putbit(bs, swf_tag_edit->edit_use_outlines);
    if (swf_tag_edit->edit_has_font) {
        bitstream_putbytesLE(bs, swf_tag_edit->edit_font_id_ref, 2);
        bitstream_putbytesLE(bs, swf_tag_edit->edit_font_height, 2);
    }
    if (swf_tag_edit->edit_has_color) {
        swf_rgba_build(bs, &swf_tag_edit->edit_color);
    }
    if (swf_tag_edit->edit_has_max_length) {
        bitstream_putbytesLE(bs, swf_tag_edit->edit_max_length, 2);
    }
    if (swf_tag_edit->edit_has_layout) {
        bitstream_putbyte(bs, swf_tag_edit->edit_align);
        bitstream_putbytesLE(bs, swf_tag_edit->edit_left_margine, 2);
        bitstream_putbytesLE(bs, swf_tag_edit->edit_right_margine, 2);
        bitstream_putbytesLE(bs, swf_tag_edit->edit_indent, 2);
        bitstream_putbytesLE(bs, swf_tag_edit->edit_leading, 2);
    }
    bitstream_putstring(bs,
                        (unsigned char *) swf_tag_edit->edit_variable_name,
                        strlen(swf_tag_edit->edit_variable_name) + 1);
    if (swf_tag_edit->edit_has_text) {
        bitstream_putstring(bs,
                            (unsigned char *)swf_tag_edit->edit_initial_text,
                            strlen(swf_tag_edit->edit_initial_text) + 1);
    }
    data = bitstream_steal(bs, length);
    bitstream_close(bs);
    return data;
}

void
swf_tag_edit_print_detail(swf_tag_t *tag,
                          struct swf_object_ *swf, int indent_depth) {
    swf_tag_edit_detail_t *swf_tag_edit = (swf_tag_edit_detail_t *) tag->detail;
    (void) tag;
    print_indent(indent_depth);
    printf("edit_id=%d\n", swf_tag_edit->edit_id);
    swf_rect_print(&swf_tag_edit->rect, indent_depth + 1);
    print_indent(indent_depth);
    printf("text=%d wwrap=%d multi=%d pass=%d ro=%d col=%d maxlen=%d font=%d\n",
           swf_tag_edit->edit_has_text?1:0,
           swf_tag_edit->edit_word_wrap?1:0,
           swf_tag_edit->edit_multiline?1:0,
           swf_tag_edit->edit_password?1:0,
           swf_tag_edit->edit_readonly?1:0,
           swf_tag_edit->edit_has_color?1:0,
           swf_tag_edit->edit_has_max_length?1:0,
           swf_tag_edit->edit_has_font?1:0);
    if (swf->header.version >= 6) {
            print_indent(indent_depth);
            printf("auto_size=%d\n", swf_tag_edit->edit_auto_size);
    }
    print_indent(indent_depth);
    printf("layout=%d no_sel=%d border=%d\n",
           swf_tag_edit->edit_has_layout?1:0,
           swf_tag_edit->edit_no_select?1:0,
           swf_tag_edit->edit_border?1:0);
    if (swf_tag_edit->edit_has_font) {
        print_indent(indent_depth);
        printf("font_id=%d font_height=%d",
               swf_tag_edit->edit_font_id_ref,
               swf_tag_edit->edit_font_height / SWF_TWIPS);
    }
    if (swf_tag_edit->edit_has_color) {
        printf("  color=#%02x%02x%02x(%02x)",
               swf_tag_edit->edit_color.red,
               swf_tag_edit->edit_color.green,
               swf_tag_edit->edit_color.blue,
               swf_tag_edit->edit_color.alpha);
    }
    printf("\n");
    if (swf_tag_edit->edit_has_max_length) {
        print_indent(indent_depth);
        printf("max_length=%d\n",
               swf_tag_edit->edit_max_length);
    }
    if (swf_tag_edit->edit_has_layout) {
        print_indent(indent_depth);
        printf("align=%d (left,right)_margine=(%d,%d) indent=%d leading=%d\n",
               swf_tag_edit->edit_align,
               swf_tag_edit->edit_left_margine,
               swf_tag_edit->edit_right_margine,
               swf_tag_edit->edit_indent,
               swf_tag_edit->edit_leading);
    }
    if (swf_tag_edit->edit_variable_name) {
        print_indent(indent_depth);
        printf("variable_name=%s\n",
               swf_tag_edit->edit_variable_name);
    }
    if (swf_tag_edit->edit_initial_text) {
        print_indent(indent_depth);
        printf("initial_text=%s\n",
               swf_tag_edit->edit_initial_text);
    }
    return ;
}

void
swf_tag_edit_destroy_detail(swf_tag_t *tag) {
    swf_tag_edit_detail_t *swf_tag_edit = (swf_tag_edit_detail_t *) tag->detail;
    if (swf_tag_edit) {
        free(swf_tag_edit->edit_variable_name);
        free(swf_tag_edit->edit_initial_text);
        swf_tag_edit->edit_variable_name = NULL;
        swf_tag_edit->edit_initial_text = NULL;
        free(swf_tag_edit);
        tag->detail = NULL;
    }
    return ;
}

char *
swf_tag_edit_get_string(void *detail,
                        char *variable_name, int variable_name_len,
                        int *error) {
    swf_tag_edit_detail_t *swf_tag_edit = (swf_tag_edit_detail_t *) detail;
    char *data, *initial_text;
    int initial_text_len = 0;
    *error = 0;

    if ((strlen(swf_tag_edit->edit_variable_name) != (unsigned)variable_name_len) || strncmp(swf_tag_edit->edit_variable_name, variable_name, variable_name_len)) {
        if (atoi(variable_name) != swf_tag_edit->edit_id) {
            *error = 1;
            return NULL;
        }
    }
    initial_text = swf_tag_edit->edit_initial_text;
    if (initial_text == NULL) {
        return NULL;
    }
    initial_text_len = strlen(initial_text);
    data = malloc(initial_text_len + 1);
    if (data == NULL) {
        *error = 1;
        fprintf(stderr, "swf_tag_edit_get_string: Can't malloc\n");
        return NULL;
    }
    memcpy(data, initial_text, initial_text_len + 1);
    return data;
}

int
swf_tag_edit_replace_string(void *detail,
                            char *variable_name, int variable_name_len,
                            char *initial_text, int initial_text_len) {
    char *new_str;
    swf_tag_edit_detail_t *swf_tag_edit = (swf_tag_edit_detail_t *) detail;
    if (((int) strlen(swf_tag_edit->edit_variable_name) != variable_name_len)
        || memcmp(swf_tag_edit->edit_variable_name, variable_name,
                  variable_name_len)) {
        if (atoi(variable_name) != swf_tag_edit->edit_id) {
            return 1;
        }
    }
    if (initial_text_len == 0) {
	swf_tag_edit->edit_has_text = 0;
        if (swf_tag_edit->edit_initial_text) {
	    free(swf_tag_edit->edit_initial_text);
	    swf_tag_edit->edit_initial_text = NULL;
        }
	return 0;
    } 
    swf_tag_edit->edit_has_text = 1;
    new_str = malloc(initial_text_len + 1);
    if (new_str == NULL) {
        fprintf(stderr, "swf_tag_edit_replace_string: Can't malloc\n");
        return 1;
    }
    memcpy(new_str, initial_text, initial_text_len);
    new_str[initial_text_len] = '\0';
    if (swf_tag_edit->edit_initial_text) {
        free(swf_tag_edit->edit_initial_text);
    }
    swf_tag_edit->edit_initial_text = new_str;
    return 0;
}
