/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_XRGB_H__
#define __SWF_XRGB_H__

typedef struct swf_xrgb_ {
//  unsigned char pad;
    unsigned char red;
    unsigned char green;
    unsigned char blue;
} swf_xrgb_t;

extern int swf_xrgb_parse(bitstream_t *bs, swf_xrgb_t *color);
extern int swf_xrgb_build(bitstream_t *bs, swf_xrgb_t *color);
extern int swf_xrgb_print(swf_xrgb_t *color);

#endif /* __SWF_XRGB_H__ */
