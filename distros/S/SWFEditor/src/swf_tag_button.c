
/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#include <stdio.h>
#include <string.h>
#include "bitstream.h"
#include "swf_button_record.h"
#include "swf_button_condaction.h"
#include "swf_tag.h"
#include "swf_tag_button.h"
#include "swf_object.h"

swf_tag_detail_handler_t button_detail_handler;

swf_tag_detail_handler_t *
swf_tag_button_detail_handler(void) {
    button_detail_handler.create   = swf_tag_button_create_detail;
    button_detail_handler.input    = swf_tag_button_input_detail;
    button_detail_handler.get_cid  = swf_tag_button_get_cid_detail;
    button_detail_handler.replace_cid = swf_tag_button_replace_cid_detail;
    button_detail_handler.output   = swf_tag_button_output_detail;
    button_detail_handler.print    = swf_tag_button_print_detail;
    button_detail_handler.destroy  = swf_tag_button_destroy_detail;
    return &button_detail_handler;
}

void *
swf_tag_button_create_detail(void) {
    swf_tag_button_detail_t *swf_tag_button;
    swf_tag_button = calloc(sizeof(*swf_tag_button), 1);
    if (swf_tag_button == NULL) {
        fprintf(stderr, "ERROR: swf_tag_button_create_detail: can't calloc\n");
        return NULL;
    }
    return swf_tag_button;
}

int
swf_tag_button_input_detail(swf_tag_t *tag, struct swf_object_ *swf) {
    swf_tag_button_detail_t *swf_tag_button = tag->detail;
    unsigned char *data  = tag->data;
    unsigned long length = tag->length;
    bitstream_t *bs = NULL;
    int offset_of_action_offset = 0;
    (void) swf;
    if (swf_tag_button == NULL) {
        fprintf(stderr, "ERROR: swf_tag_button_input_detail: swf_tag_place == NULL\n");
        return 1;
    }
    bs = bitstream_open();
    bitstream_input(bs, data, length);

    swf_tag_button->button_id = bitstream_getbytesLE(bs, 2);
    if (tag->code == 34) { // DefineButton2
        bitstream_getbits(bs, 7); // reserved flags : always 0
        swf_tag_button->track_as_menu = bitstream_getbit(bs);
        offset_of_action_offset = bitstream_getbytepos(bs);
        swf_tag_button->action_offset = bitstream_getbytesLE(bs, 2);
    }
    // Characters
    swf_tag_button->characters = swf_button_record_list_create();
    swf_button_record_list_parse(bs, swf_tag_button->characters, tag);
    // Actions
    if (tag->code == 7) { // DefineButton
        swf_tag_button->actions = swf_action_list_create();
        swf_action_list_parse(bs, swf_tag_button->actions);
    } else {
        if (swf_tag_button->action_offset) {
            bitstream_setpos(bs, offset_of_action_offset + swf_tag_button->action_offset, 0);
            swf_tag_button->condactions = swf_button_condaction_list_create();
            swf_button_condaction_list_parse(bs, swf_tag_button->condactions);
        }
    }
    bitstream_close(bs);
    return 0;
}

int
swf_tag_button_get_cid_detail(swf_tag_t *tag) {
    unsigned char *data = tag->data;
    if (tag->detail) {
        swf_tag_button_detail_t *swf_tag_button = (swf_tag_button_detail_t *) tag->detail;
        return swf_tag_button->button_id;
    }
    if (data == NULL) {
        fprintf(stderr, "swf_tag_button_get_cid_detail: data == NULL\n");
        return -1;
    }
    return GetUShortLE(data); // button_id;
}

int swf_tag_button_replace_cid_detail(swf_tag_t *tag, int id) {
    unsigned char *data = tag->data;
    if (tag->detail) {
        swf_tag_button_detail_t *swf_tag_button = (swf_tag_button_detail_t *) tag->detail;
        swf_tag_button->button_id = id;
    }
    if (data) {
        PutUShortLE(data, id);
    }
    return 0; // always 0
}

int *
swf_tag_button_character_get_refcid_list(swf_tag_t *tag, int *cid_list_num) {
    swf_tag_button_detail_t *swf_tag_button;
    int *cid_list, cid_list_alloc;
    swf_button_record_t *button_record = NULL;
    int ret;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_button_character_get_refcid: tag == NULL\n");
        return NULL;
    }
    if (! isButtonTag(tag->code)) {
        fprintf(stderr, "swf_tag_button_character_get_refcid: ! isButtonTag(%d)\n",
                tag->code);
        return NULL;
    }
    if (tag->detail) {
        swf_tag_button = (swf_tag_button_detail_t *) tag->detail;
    } else {
        tag->detail = swf_tag_button_create_detail();
        swf_tag_button = (swf_tag_button_detail_t *) tag->detail;
        ret = swf_tag_button_input_detail(tag, NULL);
        if (ret) {
            swf_tag_button_destroy_detail(tag);
            return NULL; // no button character
        }
    }
    *cid_list_num = 0;
    cid_list_alloc = 10;
    cid_list = malloc(sizeof(int) * cid_list_alloc);

    for (button_record = swf_tag_button->characters->head ; button_record ; button_record = button_record->next) {
        if (button_record->character_id > 0) {
            if (cid_list_alloc <= *cid_list_num) {
                int *tmp;
                cid_list_alloc *= 2;
                tmp = realloc(cid_list, sizeof(int) * cid_list_alloc);
                if (tmp == NULL) {
                    fprintf(stderr, "swf_tag_shape_bitmap_get_refcid_list: Can't realloc memory (%p, %d)\n", cid_list, cid_list_alloc);
                    free(cid_list);
                    return NULL;
                }
                cid_list = tmp;
            }
            cid_list[*cid_list_num] = button_record->character_id;
            *cid_list_num = (*cid_list_num) + 1;
        }
    }
    if (*cid_list_num == 0) {
        free(cid_list);
        return NULL; // not found
    }
    return cid_list;
}

int
swf_tag_button_character_replace_refcid_list(swf_tag_t *tag, int from_cid, int to_cid) {
    fprintf(stderr, "swf_tag_button_character_replace_refcid_list: not implemented yet.\n");
    return 1;
}

unsigned char *
swf_tag_button_output_detail(swf_tag_t *tag, unsigned long *length,
                             struct swf_object_ *swf) {
    swf_tag_button_detail_t *swf_tag_button = (swf_tag_button_detail_t *) tag->detail;
    bitstream_t *bs;
    unsigned char *data;
    int offset_of_action_offset = 0;
    int offset_of_actions = 0;
    (void) swf;
    //
    bs = bitstream_open();
    bitstream_putbytesLE(bs, swf_tag_button->button_id, 2);
    if (tag->code == 34) { // DefineButton2
        bitstream_putbits(bs, 0, 7); // reserved flags : always 0
        bitstream_putbit(bs, swf_tag_button->track_as_menu);
        offset_of_action_offset = bitstream_getbytepos(bs);
        bitstream_putbytesLE(bs, 0, 2); // action_offset dummy;
    }
    // Characters
    swf_button_record_list_build(bs, swf_tag_button->characters, tag);
    // Actions
    if (tag->code == 7) { // DefineButton
        swf_action_list_build(bs, swf_tag_button->actions);
    } else {
        if (swf_tag_button->condactions) {
            offset_of_actions = bitstream_getbytepos(bs);
            swf_tag_button->action_offset = offset_of_actions - offset_of_action_offset;
            bitstream_setpos(bs, offset_of_action_offset, 0);
            bitstream_putbytesLE(bs, swf_tag_button->action_offset, 2);
            bitstream_setpos(bs, offset_of_actions, 0);
            swf_button_condaction_list_build(bs, swf_tag_button->condactions);
        }
    }
    data = bitstream_steal(bs, length);
    bitstream_close(bs);
    return data;
}

void
swf_tag_button_print_detail(swf_tag_t *tag,
                           struct swf_object_ *swf, int indent_depth) {
    swf_tag_button_detail_t *swf_tag_button = (swf_tag_button_detail_t *) tag->detail;
    (void) swf;
    print_indent(indent_depth);
    printf("button_id=%d track_as_menu=%d (action_offset=%d)\n",
           swf_tag_button->button_id, swf_tag_button->track_as_menu,
           swf_tag_button->action_offset);
    print_indent(indent_depth);
    printf("characters:\n");
    swf_button_record_list_print(swf_tag_button->characters, indent_depth+1, tag);
    if (tag->code == 7) { // DefineButton
        print_indent(indent_depth);
        printf("actions:\n");
        if (swf_tag_button->actions) {
            swf_action_list_print(swf_tag_button->actions, indent_depth+1);
        } else {
            print_indent(indent_depth + 1);
            printf("(no actions)\n");
        }
    } else { // DefineButton2
        print_indent(indent_depth);
        printf("condactions:\n");
        if (swf_tag_button->condactions) {
            swf_button_condaction_list_print(swf_tag_button->condactions, indent_depth+1);
        } else {
            print_indent(indent_depth + 1);
            printf("(no condactions)\n");
        }
    }
}

void
swf_tag_button_destroy_detail(swf_tag_t *tag) {
    swf_tag_button_detail_t *swf_tag_button = (swf_tag_button_detail_t *) tag->detail;
    if (swf_tag_button) {
        if (swf_tag_button->characters) {
            swf_button_record_list_destroy(swf_tag_button->characters);
            swf_tag_button->characters = NULL;
        }
        if (swf_tag_button->actions) { // DefineButton
            swf_action_list_destroy(swf_tag_button->actions);
            swf_tag_button->actions = NULL;
        }
        if (swf_tag_button->condactions) { // DefineButton2
            swf_button_condaction_list_destroy(swf_tag_button->condactions);
            swf_tag_button->condactions = NULL;
        }
        free(swf_tag_button);
        tag->detail = NULL;
    }
    return ;
}
