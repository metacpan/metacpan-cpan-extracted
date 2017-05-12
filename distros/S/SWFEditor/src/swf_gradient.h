/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_GRADIENT_H__
#define __SWF_GRADIENT_H__

#include "swf_tag.h"
#include "swf_gradient_record.h"

typedef struct swf_gradient_ {
    unsigned char spread_mode : 2; // DefineShape4
    unsigned char interpolation_mode : 2; // DefineShape4
    unsigned char pad : 4;    // other tag
    unsigned char count : 4;
    swf_gradient_record_t *gradient_record; // count
    signed short focal_point; // type == 0x13
    
} swf_gradient_t;

extern int swf_gradient_parse(bitstream_t *bs, swf_gradient_t *gradient,
                              swf_tag_t *tag, int type);
extern int swf_gradient_build(bitstream_t *bs, swf_gradient_t *gradient,
                              swf_tag_t *tag, int type);
extern int swf_gradient_print(swf_gradient_t *gradient, int indent_depth,
                              swf_tag_t *tag, int type);

extern int swf_gradient_delete(swf_gradient_t *gradient);

#endif /* __SWF_GRADIENT_H__ */
