/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_SHAPE_WITH_STYLE_H__
#define __SWF_SHAPE_WITH_STYLE_H__

#include "swf_tag.h"
#include "swf_styles.h"
#include "swf_shape_record.h"

typedef struct swf_shape_with_style_ {
    swf_styles_t       styles;
    swf_shape_record_t shape_records;
} swf_shape_with_style_t;

extern int swf_shape_with_style_parse(bitstream_t *bs,
                                      swf_shape_with_style_t *shape_with_style,
                                      swf_tag_t *tag);
extern int swf_shape_with_style_build(bitstream_t *bs,
                                      swf_shape_with_style_t *shape_with_style,
                                      swf_tag_t *tag);
extern int swf_shape_with_style_print(swf_shape_with_style_t *shape_with_style,
                                      int indent_depth,
                                      swf_tag_t *tag);
extern int swf_shape_with_style_delete(swf_shape_with_style_t *shape_with_style);

#endif /* __SWF_SHAPE_WITH_STYLE_H__ */
