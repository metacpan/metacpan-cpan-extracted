/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_ACTION_H__
#define __SWF_ACTION_H__

#include "bitstream.h"
#include "y_keyvalue.h"

typedef struct swf_action_ {
    unsigned char  action_id;
    unsigned short action_length;
    unsigned char *action_data;
    struct swf_action_ *next; // self reference structure
} swf_action_t;

typedef struct swf_action_list_ {
    swf_action_t *head, *tail;
} swf_action_list_t;

typedef struct swf_action_info_ {
    int id;
    char *name;
} swf_action_info_t;

extern swf_action_info_t *get_swf_action_info(int action_id);

extern int swf_action_parse(bitstream_t *bs, swf_action_t *act);
extern int swf_action_build(bitstream_t *bs, swf_action_t *act);
extern int swf_action_print(swf_action_t *act, int indent_depth);

extern swf_action_list_t *swf_action_list_create(void);
extern int swf_action_list_parse(bitstream_t *bs, swf_action_list_t *list);
extern int swf_action_list_build(bitstream_t *bs, swf_action_list_t *list);
extern void swf_action_list_destroy(swf_action_list_t *act_list);
extern void swf_action_list_print(swf_action_list_t *act_list,
                                  int indent_depth);

extern int swf_action_data_print(unsigned char *action_data,
                                 unsigned short action_data_len);
extern int swf_action_list_replace_strings(swf_action_list_t *action_list,
                                           int *modified, y_keyvalue_t *kv);

extern int swf_action_list_append_top(swf_action_list_t *list,
                                      int action_id,
                                      unsigned char *action_data,
                                      int action_data_length);

#endif /* __SWF_ACTION_H__ */
