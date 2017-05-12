/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_BUTTON_CONDACTION_H__
#define __SWF_BUTTON_CONDACTION_H__

#include "bitstream.h"
#include "swf_action.h"

typedef struct swf_button_condaction_ {
    // char align;
    int cond_action_size;
    unsigned char cond_idle_to_overdown    :1;
    unsigned char cond_outdown_to_idle     :1;
    unsigned char cond_outdown_to_overdown :1;
    unsigned char cond_overdown_to_outdown :1;
    unsigned char cond_overdown_to_overup  :1;
    unsigned char cond_overup_to_overown   :1;
    unsigned char cond_overup_to_idle      :1;
    unsigned char cond_idle_to_overup      :1;
    //
    int cond_keypress;
    unsigned char cond_overdown_to_idle;
    //
    swf_action_list_t *actions;
    //
    struct swf_button_condaction_ *next;
} swf_button_condaction_t ;

typedef struct swf_button_condaction_list_ {
    swf_button_condaction_t *head;
} swf_button_condaction_list_t;

extern swf_button_condaction_t *swf_button_condaction_create(void);
extern int swf_button_condaction_parse(bitstream_t *bs, swf_button_condaction_t *button_condaction);
extern int swf_button_condaction_build(bitstream_t *bs, swf_button_condaction_t *button_condaction);
extern int swf_button_condaction_print(swf_button_condaction_t *button_condaction, int indent_depth);
extern void swf_button_condaction_destroy(swf_button_condaction_t *button_condaction);

extern swf_button_condaction_list_t *swf_button_condaction_list_create(void);
extern int swf_button_condaction_list_parse(bitstream_t *bs, swf_button_condaction_list_t *button_condaction_list);
extern int swf_button_condaction_list_build(bitstream_t *bs, swf_button_condaction_list_t *button_condaction_list);
extern int swf_button_condaction_list_print(swf_button_condaction_list_t *button_condaction_list, int indent_depth);
extern void swf_button_condaction_list_destroy(swf_button_condaction_list_t *button_condaction_list);

#endif /* __SWF_BUTTON_CONDACTION_H__ */
