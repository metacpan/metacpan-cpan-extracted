/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#include <stdio.h>
#include "swf_button_condaction.h"


swf_button_condaction_t *
swf_button_condaction_create(void) {
    swf_button_condaction_t *button_condaction;
    button_condaction = calloc(sizeof(*button_condaction), 1);
    if (button_condaction == NULL) {
        fprintf(stderr, "Can't alloc memory for button_condaction\n");
        return NULL;
    }
    return button_condaction;
}

int
swf_button_condaction_parse(bitstream_t *bs, swf_button_condaction_t *button_condaction) {
    button_condaction->cond_action_size = bitstream_getbytesLE(bs, 2);
    //
    button_condaction->cond_idle_to_overdown    = bitstream_getbit(bs);
    button_condaction->cond_outdown_to_idle     = bitstream_getbit(bs);
    button_condaction->cond_outdown_to_overdown = bitstream_getbit(bs);
    button_condaction->cond_overdown_to_outdown = bitstream_getbit(bs);
    button_condaction->cond_overdown_to_overup  = bitstream_getbit(bs);
    button_condaction->cond_overup_to_overown   = bitstream_getbit(bs);
    button_condaction->cond_overup_to_idle      = bitstream_getbit(bs);
    button_condaction->cond_idle_to_overup      = bitstream_getbit(bs);
    //
    button_condaction->cond_keypress = bitstream_getbits(bs, 7);
    button_condaction->cond_overdown_to_idle    = bitstream_getbit(bs);
    //
    button_condaction->actions = swf_action_list_create();
    swf_action_list_parse(bs, button_condaction->actions);
    return 0;
}

int
swf_button_condaction_build(bitstream_t *bs, swf_button_condaction_t *button_condaction) {
    bitstream_putbytesLE(bs, 0, 2); // dummy;
    //
    bitstream_putbit(bs, button_condaction->cond_idle_to_overdown);
    bitstream_putbit(bs, button_condaction->cond_outdown_to_idle);
    bitstream_putbit(bs, button_condaction->cond_outdown_to_overdown);
    bitstream_putbit(bs, button_condaction->cond_overdown_to_outdown);
    bitstream_putbit(bs, button_condaction->cond_overdown_to_overup);
    bitstream_putbit(bs, button_condaction->cond_overup_to_overown);
    bitstream_putbit(bs, button_condaction->cond_overup_to_idle);
    bitstream_putbit(bs, button_condaction->cond_idle_to_overup);
    //
    bitstream_putbits(bs, button_condaction->cond_keypress, 7);
    bitstream_putbit(bs, button_condaction->cond_overdown_to_idle);
    //
    swf_action_list_build(bs, button_condaction->actions);
    return 0;
}

int
swf_button_condaction_print(swf_button_condaction_t *button_condaction, int indent_depth) {
    print_indent(indent_depth);
    printf("(action_size=%d)\n", button_condaction->cond_action_size);
    print_indent(indent_depth);
    printf("idle_to_overdown=%u outdown_to_idle=%u outdown_to_overdown=%u overdown_to_outdown=%u\n",
           button_condaction->cond_idle_to_overdown,
           button_condaction->cond_outdown_to_idle,
           button_condaction->cond_outdown_to_overdown,
           button_condaction->cond_overdown_to_outdown);
    print_indent(indent_depth);
    printf("overdown_to_overup=%u overup_to_overown=%u cond_overup_to_idle=%u cond_idle_to_overup=%u\n",
           button_condaction->cond_overdown_to_overup,
           button_condaction->cond_overup_to_overown,
           button_condaction->cond_overup_to_idle,
           button_condaction->cond_idle_to_overup);
    print_indent(indent_depth);
    printf("keypress=%d overdown_to_idle=%u\n",
           button_condaction->cond_keypress,
           button_condaction->cond_overdown_to_idle);
    swf_action_list_print(button_condaction->actions, indent_depth+1);
    return 0;
}

void
swf_button_condaction_destroy(swf_button_condaction_t *button_condaction) {
    if (button_condaction) {
        if (button_condaction->actions) {
            swf_action_list_destroy(button_condaction->actions);
            button_condaction->actions = NULL;
        }
        free(button_condaction);
    }
}

swf_button_condaction_list_t *
swf_button_condaction_list_create(void) {
    swf_button_condaction_list_t *button_condaction_list;
    button_condaction_list = calloc(sizeof(*button_condaction_list), 1);
    if (button_condaction_list == NULL) {
        fprintf(stderr, "Can't alloc memory for button_condaction_list\n");
        return NULL;
    }
    return button_condaction_list; 
}

int
swf_button_condaction_list_parse(bitstream_t *bs, swf_button_condaction_list_t *button_condaction_list) {
    int ret;
    swf_button_condaction_t *prev_button_condaction = NULL;    
    int offset_of_action;
    while (1) { // endflag is 0
        swf_button_condaction_t *button_condaction = malloc(sizeof(*button_condaction));
        button_condaction->next = NULL;
        offset_of_action = bitstream_getbytepos(bs);
        ret = swf_button_condaction_parse(bs, button_condaction);
        if (ret) {
            return ret;
        }
        if (prev_button_condaction) {
            prev_button_condaction->next = button_condaction;
        } else {
            button_condaction_list->head = button_condaction;
        }
        if (button_condaction->cond_action_size == 0) { // last action
            break; // OK
        }
        bitstream_setpos(bs, offset_of_action + button_condaction->cond_action_size, 0);
        prev_button_condaction = button_condaction;
    }
    return 0;
}

int
swf_button_condaction_list_build(bitstream_t *bs, swf_button_condaction_list_t *button_condaction_list) {
    swf_button_condaction_t *button_condaction;
    int offset_of_action, offset_of_next_action;
    if (button_condaction_list == NULL) {
        return 1;
    }
    for (button_condaction = button_condaction_list->head ; button_condaction ; button_condaction = button_condaction->next) {
        offset_of_action = bitstream_getbytepos(bs);
        swf_button_condaction_build(bs, button_condaction);
        if (button_condaction->next) {
            offset_of_next_action = bitstream_getbytepos(bs);
            bitstream_setpos(bs, offset_of_action, 0);
            bitstream_putbytesLE(bs, offset_of_next_action - offset_of_action, 2);
            bitstream_setpos(bs, offset_of_next_action, 0);
        }
    }
    return 0;
}

void
swf_button_condaction_list_destroy(swf_button_condaction_list_t *button_condaction_list) {
    swf_button_condaction_t *button_condaction = NULL, *next_button_condaction = NULL;    
    if (button_condaction_list) {
        for (button_condaction = button_condaction_list->head ; button_condaction ; button_condaction = next_button_condaction) {
            next_button_condaction = button_condaction->next;
            swf_button_condaction_destroy(button_condaction);
        }
        free(button_condaction_list);
    }
}

int
swf_button_condaction_list_print(swf_button_condaction_list_t *button_condaction_list, int indent_depth) {
    swf_button_condaction_t *button_condaction;
    if (button_condaction_list == NULL) {
        return 1;
    }
    for (button_condaction = button_condaction_list->head ; button_condaction ; button_condaction = button_condaction->next) {
        swf_button_condaction_print(button_condaction, indent_depth);
    }
    return 0;
}
