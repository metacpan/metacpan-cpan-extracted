/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#include <stdio.h>
#include "bitstream.h"
#include "swf_button_record.h"

int
swf_button_record_parse(bitstream_t *bs, swf_button_record_t *button_record,
    swf_tag_t *tag) {
    int ret;
    ret = bitstream_getbits(bs, 2); // reserved bits, always 0
    if (ret) {
        fprintf(stderr, "swf_button_record_parse: bitstream_getbis(bs, 2)\n");
        return ret;
    }
    button_record->button_has_blend_mode  = bitstream_getbit(bs);
    button_record->button_has_filter_list = bitstream_getbit(bs);
    button_record->button_state_hittest = bitstream_getbit(bs);
    button_record->button_state_down = bitstream_getbit(bs);
    button_record->button_state_over = bitstream_getbit(bs);
    button_record->button_state_up = bitstream_getbit(bs);
    //
    button_record->character_id = bitstream_getbytesLE(bs, 2);
    button_record->place_depth = bitstream_getbytesLE(bs, 2);
    ret = swf_matrix_parse(bs, &(button_record->place_matrix));
    if (ret) {
        fprintf(stderr, "swf_button_record_parse: swf_matrix_parse failed\n");
        return ret;
    }
    if (tag->code == 34) { // DefineButton2
        ret = swf_cxformwithalpha_parse(bs, &(button_record->color_transform));
        if (ret) {
            fprintf(stderr, "swf_button_record_parse: swf_matrix_parse failed\n");
            return ret;
        }
    }
    //
    // FilterList, BlendMode
    //
    return 0;
}

void
swf_button_record_destroy(swf_button_record_t *button_record) {
    (void) button_record;
    if (button_record) {
        //
        // FilterList free
        //
        free(button_record);
    }
    return ;
}

int
swf_button_record_build(bitstream_t *bs, swf_button_record_t *button_record,
    swf_tag_t *tag) {
    int ret;
    bitstream_putbits(bs, 0, 2);
    bitstream_putbit(bs, button_record->button_has_blend_mode);
    bitstream_putbit(bs, button_record->button_has_filter_list);
    bitstream_putbit(bs, button_record->button_state_hittest);
    bitstream_putbit(bs, button_record->button_state_down);
    bitstream_putbit(bs, button_record->button_state_over);
    bitstream_putbit(bs, button_record->button_state_up);
    //
    bitstream_putbytesLE(bs, button_record->character_id, 2);
    bitstream_putbytesLE(bs, button_record->place_depth, 2);
    ret = swf_matrix_build(bs, &(button_record->place_matrix));
    if (ret) {
        fprintf(stderr, "swf_button_record_build: swf_matrix_build failed\n");
        return ret;
    }
    if (tag->code == 34) { // DefineButton2
        ret = swf_cxformwithalpha_build(bs, &(button_record->color_transform));
        if (ret) {
            fprintf(stderr, "swf_button_record_build: swf_matrix_build failed\n");
            return ret;
        }
    }
    //
    // FilterList, BlendMode
    //
    return 0;
}

int
swf_button_record_print(swf_button_record_t *button_record, int indent_depth,
    swf_tag_t *tag) {
    print_indent(indent_depth);
    printf("has_blend_mode=%d has_filter_list=%u\n",
           button_record->button_has_blend_mode,
           button_record->button_has_filter_list);
    print_indent(indent_depth);
    printf("state_hittest=%u state_down=%u state_over=%u state_up=%u\n",
           button_record->button_state_hittest,
           button_record->button_state_down,
           button_record->button_state_over,
           button_record->button_state_up);
    print_indent(indent_depth);
    printf("character_id=%d place_depth=%d\n",
           button_record->character_id, button_record->place_depth);
    swf_matrix_print(&(button_record->place_matrix), indent_depth);
    if (tag->code == 34) { // DefineButton2
        swf_cxformwithalpha_print(&(button_record->color_transform), indent_depth);
    }
    //
    // FilterList, BlendMode
    //
    return 0;
}

/*
 * swf_button_record_list
 */


swf_button_record_list_t *
swf_button_record_list_create(void) {
    swf_button_record_list_t *button_record_list;
    button_record_list = calloc(sizeof(*button_record_list), 1);
    if (button_record_list == NULL) {
        fprintf(stderr, "Can't alloc memory for button_record_list\n");
        return NULL;
    }
    button_record_list->head = NULL;
    button_record_list->tail = NULL;
    return button_record_list;
}

int
swf_button_record_list_parse(bitstream_t *bs, swf_button_record_list_t *button_record_list, swf_tag_t *tag) {
    swf_button_record_t *prev_button_record = NULL;
    while (bitstream_getbyte(bs)) { // endflag is 0
        swf_button_record_t *button_record = malloc(sizeof(*button_record));
        button_record->next = NULL;
        bitstream_incrpos(bs, -1, 0); // 1 byte back
        if (swf_button_record_parse(bs, button_record, tag)) {
            fprintf(stderr, "swf_button_record_list_parse: swf_button_record_parse failed\n");
            free(button_record);
            break;
        }
        if (prev_button_record) {
            prev_button_record->next = button_record;
        } else {
            button_record_list->head = button_record;
        }
        prev_button_record = button_record;
    }
    return 0;
}

int
swf_button_record_list_build(bitstream_t *bs, swf_button_record_list_t *button_record_list, swf_tag_t *tag) {
    swf_button_record_t *button_record = NULL;
    for (button_record = button_record_list->head ; button_record ; button_record = button_record->next) {
        swf_button_record_build(bs, button_record, tag);
    }
    bitstream_putbyte(bs, 0); //endflag
    return 0;
}

void
swf_button_record_list_destroy(swf_button_record_list_t *button_record_list) {
    swf_button_record_t *button_record = NULL, *next_button_record = NULL;
    if (button_record_list) {
        for (button_record = button_record_list->head ; button_record ; button_record = next_button_record) {
            next_button_record = button_record->next;
            button_record->next = NULL; // fail safe
            swf_button_record_destroy(button_record);
        }
        free(button_record_list);
    }
}

int
swf_button_record_list_print(swf_button_record_list_t *button_record_list, int indent_depth, swf_tag_t *tag) {
    swf_button_record_t *button_record = NULL;
    for (button_record = button_record_list->head ; button_record ; button_record = button_record->next) {
        swf_button_record_print(button_record, indent_depth, tag);
    }
    return 0;
}

