/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_GRADIENT_RECORD_H__
#define __SWF_GRADIENT_RECORD_H__

#include "swf_tag.h"
#include "swf_rgba.h"
#include "swf_rgb.h"

typedef struct swf_gradient_record_ {
    unsigned char position;
    swf_rgba_t rgba; // DefineMorphShape, DefineMorphShape2, DefineShape3, DefineShape4
    unsigned char position_morph; // DefineMorphShape, DefineMorphShape2
    swf_rgba_t rgba_morph; // DefineMorphShape, DefineMorphShape2
    swf_rgb_t rgb; // other 
} swf_gradient_record_t;

extern int swf_gradient_record_parse(bitstream_t *bs,
                                     swf_gradient_record_t *gradient_record,
                                     swf_tag_t *tag);
extern int swf_gradient_record_build(bitstream_t *bs,
                                     swf_gradient_record_t *gradient_record,
                                     swf_tag_t *tag);
extern int swf_gradient_record_print(swf_gradient_record_t *gradient_record,
                                     int indent_depth, swf_tag_t *tag);

#endif /* __SWF_GRADIENT_RECORD_H__ */
