/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_CXFORM_H__
#define __SWF_CXFORM_H__

typedef struct swf_cxform_ {
    unsigned char has_add_terms;
    unsigned char has_mult_terms;
    unsigned char nbits;
    // multiply value
    unsigned int red_mult_term;
    unsigned int green_mult_term;
    unsigned int blue_mult_term;
    // addition value
    unsigned int red_add_term;
    unsigned int green_add_term;
    unsigned int blue_add_term;
} swf_cxform_t;


extern int swf_cxform_parse(bitstream_t *bs, swf_cxform_t *color);
extern int swf_cxform_build(bitstream_t *bs, swf_cxform_t *color);
extern int swf_cxform_print(swf_cxform_t *color, int indent_depth);

#endif /* __SWF_CXFORM_H__ */
