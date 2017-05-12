/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_LINE_STYLE_ARRAY_H__
#define __SWF_LINE_STYLE_ARRAY_H__

#include "swf_line_style.h"

typedef struct swf_line_style_array_ {
    unsigned short count;
    swf_line_style_t *line_style;
} swf_line_style_array_t;

extern int swf_line_style_array_parse(bitstream_t *bs,
                                      swf_line_style_array_t *line_style_array,
                                      swf_tag_t *tag);
extern int swf_line_style_array_build(bitstream_t *bs,
                                      swf_line_style_array_t *line_style_array,
                                      swf_tag_t *tag);
extern int swf_line_style_array_print(swf_line_style_array_t *line_style_array,
                                      int indent_depth, swf_tag_t *tag);
extern int swf_line_style_array_delete(swf_line_style_array_t *line_style_array);

#endif /* __SWF_LINE_STYLE_ARRAY_H__ */
