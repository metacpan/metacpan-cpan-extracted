/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_RGB_H__
#define __SWF_RGB_H__

typedef struct swf_rgb_ {
    unsigned char red;
    unsigned char green;
    unsigned char blue;
} swf_rgb_t;


extern int swf_rgb_parse(bitstream_t *bs, swf_rgb_t *color);
extern int swf_rgb_build(bitstream_t *bs, swf_rgb_t *color);
extern int swf_rgb_print(swf_rgb_t *color, int indent_depth);

#endif /* __SWF_RGB_H__ */
