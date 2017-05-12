/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_ARGB_H__
#define __SWF_ARGB_H__

typedef struct swf_argb_ {
    unsigned char alpha;
    unsigned char red;
    unsigned char green;
    unsigned char blue;
} swf_argb_t;

extern int swf_argb_parse(bitstream_t *bs, swf_argb_t *color);
extern int swf_argb_build(bitstream_t *bs, swf_argb_t *color);
extern int swf_argb_print(swf_argb_t *color, int indent_depth);

#endif /* __SWF_ARGB_H__ */
