/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_FILL_STYLE_H__
#define __SWF_FILL_STYLE_H__

#include "swf_tag.h"
#include "swf_fill_style_solid.h"
#include "swf_fill_style_gradient.h"
#include "swf_fill_style_bitmap.h"

typedef struct swf_fill_style_ { // FIX ME: union is better.
    unsigned char type;
    swf_fill_style_solid_t    solid;
    swf_fill_style_gradient_t gradient;
    swf_fill_style_bitmap_t   bitmap;
} swf_fill_style_t;

extern int swf_fill_style_parse(bitstream_t *bs, swf_fill_style_t *fill_style,
                                swf_tag_t *tag);
extern int swf_fill_style_build(bitstream_t *bs, swf_fill_style_t *fill_style,
                                swf_tag_t *tag);
extern int swf_fill_style_print(swf_fill_style_t *fill_style, int indent_depth,
                                swf_tag_t *tag);
extern int swf_fill_style_delete(swf_fill_style_t *fill_style);

#endif /* __SWF_FILL_STYLE_H__ */
