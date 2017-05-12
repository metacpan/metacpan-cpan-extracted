/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#include <stdio.h>
#include <string.h>
#include "bitstream.h"
#include "swf_tag_action.h"
#include "swf_object.h"

swf_tag_detail_handler_t action_detail_handler;

swf_tag_detail_handler_t *
swf_tag_action_detail_handler(void) {
    action_detail_handler.create   = swf_tag_action_create_detail;
    action_detail_handler.input    = swf_tag_action_input_detail;
    action_detail_handler.get_cid  = NULL;
    action_detail_handler.replace_cid  = NULL;
    action_detail_handler.output   = swf_tag_action_output_detail;
    action_detail_handler.print    = swf_tag_action_print_detail;
    action_detail_handler.destroy  = swf_tag_action_destroy_detail;
    return &action_detail_handler;
}

void *
swf_tag_action_create_detail(void) {
    swf_tag_action_detail_t *swf_tag_action;
    swf_tag_action = calloc(sizeof(*swf_tag_action), 1);
    if (swf_tag_action == NULL) {
        fprintf(stderr, "ERROR: swf_tag_action_create_detail: can't calloc\n");
        return NULL;
    }
    swf_tag_action->action_sprite = 0;
    swf_tag_action->action_list = NULL;
    return swf_tag_action;
}

int
swf_tag_action_input_detail(swf_tag_t *tag, struct swf_object_ *swf) {
    swf_tag_action_detail_t *swf_tag_action = tag->detail;
    unsigned char *data  = tag->data;
    unsigned long length = tag->length;
    bitstream_t *bs;
    (void) swf;
    if (tag == NULL) {
        fprintf(stderr, "ERROR: swf_tag_action_input_detail: tag == NULL\n");
        return 1;
    }
    swf_tag_action = tag->detail;
    data  = tag->data;
    length = tag->length;
    if (swf_tag_action == NULL) {
        fprintf(stderr, "ERROR: swf_tag_action_input_detail: swf_tag_action == NULL\n");
        return 1;
    }

    bs = bitstream_open();
    bitstream_input(bs, data, length);

    if (tag->code == 59) { // DoInitAction
        swf_tag_action->action_sprite = bitstream_getbytesLE(bs, 2);
    } else {              // DoAction
        swf_tag_action->action_sprite = 0; // fail safe
    }
    swf_tag_action->action_list = swf_action_list_create();
    if (swf_tag_action->action_list == NULL) {
        fprintf(stderr, "swf_tag_action_input_detail: swf_action_list_create failed\n");
        bitstream_close(bs);
        return 1;
    }
    if (swf_action_list_parse(bs, swf_tag_action->action_list)) {
        fprintf(stderr, "swf_tag_action_input_detail: swf_action_list_parse failed\n");
        bitstream_close(bs);
        return 1;
    }
    bitstream_close(bs);
    return 0;
}

unsigned char *
swf_tag_action_output_detail(swf_tag_t *tag, unsigned long *length,
                             struct swf_object_ *swf) {
    swf_tag_action_detail_t *swf_tag_action = (swf_tag_action_detail_t *) tag->detail;
    bitstream_t *bs;
    unsigned char *data;
    *length = 0;

    (void) swf;
    bs = bitstream_open();
    if (tag->code == 59) { // DoInitAction
        bitstream_putbytesLE(bs, swf_tag_action->action_sprite, 2);
    } else {              // DoAction
        ; // nothing
    }
    swf_action_list_build(bs,swf_tag_action->action_list);
    data = bitstream_steal(bs, length);
    bitstream_close(bs);
    return data;
}

void
swf_tag_action_print_detail(swf_tag_t *tag,
                            struct swf_object_ *swf, int indent_depth) {
    swf_tag_action_detail_t *swf_tag_action = (swf_tag_action_detail_t *) tag->detail;
    (void) swf;
    print_indent(indent_depth);
    if (tag->code == 59) { // DoInitAction
        printf("action_sprite=%d  ", swf_tag_action->action_sprite);
    }
    printf("action_record =\n");
    swf_action_list_print(swf_tag_action->action_list, indent_depth + 1);
    return ;
}

void
swf_tag_action_destroy_detail(swf_tag_t *tag) {
    swf_tag_action_detail_t *swf_tag_action = (swf_tag_action_detail_t *) tag->detail;
    if (swf_tag_action) {
        if (swf_tag_action->action_list) {
	    swf_action_list_destroy(swf_tag_action->action_list);
	    swf_tag_action->action_list = NULL;
	}
        free(swf_tag_action);
        tag->detail = NULL;
    }
    return ;
}

int
swf_tag_action_top_append_varibles(swf_tag_t *tag, y_keyvalue_t *kv) {
    char *key, *value;
    int key_len, value_len;
    int key_maxlen, value_maxlen, maxlen;
    swf_tag_action_detail_t *swf_tag_action = (swf_tag_action_detail_t *) tag->detail;
    unsigned char *action_data = NULL;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_action_top_append_varibles: tag == NULL\n");
        return 1; // NG
    }
    if (! isActionTag(tag->code)) {
        fprintf(stderr, "swf_tag_action_top_append_varibles: isnot ActionTag code=%d\n", tag->code);
        return 1; // NG
    }
    key_maxlen = y_keyvalue_get_maxkeylength(kv);
    value_maxlen = y_keyvalue_get_maxvaluelength(kv);
    maxlen = (key_maxlen>value_maxlen)?key_maxlen:value_maxlen;
    action_data = malloc(1 + maxlen + 1);
    swf_tag_action->action_sprite = 0;
    // Reversible itelator for append top method.
    y_keyvalue_seeklast(kv);
    while (1) {
        key = y_keyvalue_get_currentkey(kv, &key_len);
        if (key == NULL) {
            break;
        }
        value = y_keyvalue_get_currentvalue(kv, &value_len);

        // Push Data(key), Push Data(value), Set Variable.
        // But reversible order for append top method.
        //
        // Set Variable
        swf_action_list_append_top(swf_tag_action->action_list, 0x1d, NULL, 0);
        // Push Data (value);
        action_data[0] = 0; // type string;
        memcpy(action_data + 1, value, value_len);
        action_data[value_len + 1] = '\0';
        swf_action_list_append_top(swf_tag_action->action_list, 0x96,
                                   action_data, 1 + value_len + 1);
        // Push Data (key);
        action_data[0] = 0; // type string;
        memcpy(action_data + 1, key, key_len);
        action_data[key_len + 1] = '\0';
        swf_action_list_append_top(swf_tag_action->action_list, 0x96,
                                   action_data, 1 + key_len + 1);
        if (y_keyvalue_prev(kv) == 0) {
            break;
        }
    }
    free(action_data);
    return 0;
}


int
swf_tag_action_replace_strings(swf_tag_t *tag, y_keyvalue_t *kv,
                               int *modified) {
    int ret;
    swf_tag_action_detail_t *swf_tag_action = (swf_tag_action_detail_t *) tag->detail;
    ret = swf_action_list_replace_strings(swf_tag_action->action_list,
                                          modified, kv);
    if (ret) {
        fprintf(stderr, "swf_tag_action_replace_strings: swf_action_list_replace_string failed\n");
    }
    return ret;
}
