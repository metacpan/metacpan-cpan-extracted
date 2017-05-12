/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_STYLES_COUNT_H__
#define __SWF_STYLES_COUNT_H__

typedef struct swf_styles_count_ {
    unsigned char fill_bits_count:4;
    unsigned char line_bits_count:4;
} swf_styles_count_t;

extern int swf_styles_count_parse(bitstream_t *bs,
                                  swf_styles_count_t *styles_count);
extern int swf_styles_count_build(bitstream_t *bs,
                                  swf_styles_count_t *styles_count);
extern int swf_styles_count_print(swf_styles_count_t *styles_count,
                                  int indent_depth);

#endif /* __SWF_STYLES_COUNT_H__ */
