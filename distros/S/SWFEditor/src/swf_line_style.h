/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_LINE_STYLE_H__
#define __SWF_LINE_STYLE_H__

#include "swf_tag.h"
#include "swf_rgba.h"
#include "swf_fill_style.h"
#include "swf_rgb.h"

typedef struct swf_line_style_ {
    swf_rgba_t rgba;
    swf_rgba_t rgba_morph; // + DefineMorphShape2
    // DefineShape4, DefinePhophShape2
    unsigned short /* twips */ width;
    unsigned short /* twips */ width_morph; // DefineMorphShape2
    unsigned start_cap_style : 2;
    unsigned join_style : 2;
    unsigned has_fill : 1;
    unsigned no_hscale : 1;
    unsigned no_vscale : 1;
    unsigned pixel_hinting : 1;
    unsigned reserved : 5;
    unsigned no_close : 1;
    unsigned end_cap_style : 2;
    unsigned short /* fixed */ miter_limit_factor; // join_style == 2
    swf_fill_style_t fill_style; // has_fill == true
    swf_rgb_t rgb;
} swf_line_style_t;

extern int swf_line_style_parse(bitstream_t *bs,
                                swf_line_style_t *line_style, swf_tag_t *tag);
extern int swf_line_style_build(bitstream_t *bs,
                                swf_line_style_t *line_style, swf_tag_t *tag);
extern int swf_line_style_print(swf_line_style_t *line_style,
                                int indent_depth, swf_tag_t *tag);
extern int swf_line_style_delete(swf_line_style_t *line_style);

#endif /* __SWF_LINE_STYLE_H__ */
