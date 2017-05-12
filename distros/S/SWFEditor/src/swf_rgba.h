/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_RGBA_H__
#define __SWF_RGBA_H__

typedef struct swf_rgba_ {
    unsigned char red;
    unsigned char green;
    unsigned char blue;
    unsigned char alpha;
} swf_rgba_t;

extern int swf_rgba_parse(bitstream_t *bs, swf_rgba_t *color);
extern int swf_rgba_build(bitstream_t *bs, swf_rgba_t *color);
extern int swf_rgba_print(swf_rgba_t *color, int indent_depth);

#endif /* __SWF_RGBA_H__ */
