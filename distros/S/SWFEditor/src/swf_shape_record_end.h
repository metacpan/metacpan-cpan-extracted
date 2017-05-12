/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_SHAPE_RECORD_END_H__
#define __SWF_SHAPE_RECORD_END_H__

typedef struct swf_shape_record_end_ {
    unsigned shape_record_type : 1;
    unsigned end_of_shape : 5;
} swf_shape_record_end_t;

extern int swf_shape_record_end_parse(bitstream_t *bs, swf_shape_record_end_t *color);
extern int swf_shape_record_end_build(bitstream_t *bs, swf_shape_record_end_t *color);
extern int swf_shape_record_end_print(int indent_deptha);

#endif /* __SWF_SHAPE_RECORD_END_H__ */
