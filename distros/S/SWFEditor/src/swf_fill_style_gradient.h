/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_FILL_STYLE_GRADIENT_H__
#define __SWF_FILL_STYLE_GRADIENT_H__

#include "swf_tag.h"
#include "swf_matrix.h"
#include "swf_gradient.h"

typedef struct swf_fill_style_gradient_ {
    unsigned char type;
    swf_matrix_t gradient_matrix;
    swf_matrix_t gradient_matrix_morph; // DefineMorphShape, DefineMorphShape2
    swf_gradient_t gradient;
} swf_fill_style_gradient_t;

extern int swf_fill_style_gradient_parse(bitstream_t *bs,
                                         swf_fill_style_gradient_t *gradient,
                                         swf_tag_t *tag);
extern int swf_fill_style_gradient_build(bitstream_t *bs,
                                         swf_fill_style_gradient_t *gradient,
                                         swf_tag_t *tag);
extern int swf_fill_style_gradient_print(swf_fill_style_gradient_t *gradient,
                                         int indent_depth, swf_tag_t *tag);
extern int swf_fill_style_gradient_delete(swf_fill_style_gradient_t *gradient);

#endif /* __SWF_FILL_STYLE_GRADIENT_H__ */
