/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_STYLES_H__
#define __SWF_STYLES_H__

#include "swf_tag.h"
#include "swf_fill_style_array.h"
#include "swf_line_style_array.h"
#include "swf_styles_count.h"

typedef struct swf_styles_ {
    swf_fill_style_array_t fill_styles;
    swf_line_style_array_t line_styles;
    swf_styles_count_t styles_count;
} swf_styles_t;

extern int swf_styles_parse(bitstream_t *bs, swf_styles_t *styles,
                            swf_tag_t *tag);
extern int swf_styles_build(bitstream_t *bs, swf_styles_t *styles,
                            swf_tag_t *tag);
extern int swf_styles_print(swf_styles_t *styles, int indent_depth,
                            swf_tag_t *tag);
extern int swf_styles_delete(swf_styles_t *styles);

#endif /* __SWF_STYLES_H__ */
