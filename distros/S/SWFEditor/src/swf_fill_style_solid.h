/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_FILL_STYLE_SOLID_H__
#define __SWF_FILL_STYLE_SOLID_H__

#include "swf_rgba.h"
#include "swf_rgb.h"
#include "swf_tag.h"

typedef struct swf_fill_style_solid_ {
    unsigned char type;
    swf_rgba_t rgba;       // DefineMorphShape, DefineMorphShape2, DefineShape3
    swf_rgba_t rgba_morph; // DefineMorphShape, DefineMorphShape2
    swf_rgb_t  rgb;        // other tag
} swf_fill_style_solid_t;

extern int swf_fill_style_solid_parse(bitstream_t *bs,
                                      swf_fill_style_solid_t *solid,
                                      swf_tag_t *tag);
extern int swf_fill_style_solid_build(bitstream_t *bs,
                                      swf_fill_style_solid_t *solid,
                                      swf_tag_t *tag);
extern int swf_fill_style_solid_print(swf_fill_style_solid_t *solid,
                                      int indent_depth, swf_tag_t *tag);

#endif /* __SWF_FILL_STYLE_SOLID_H__ */
