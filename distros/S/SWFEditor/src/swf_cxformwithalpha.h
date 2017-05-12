/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_CXFORMWITHALPHA_H__
#define __SWF_CXFORMWITHALPHA_H__

typedef struct swf_cxformwithalpha_ {
    unsigned char has_add_terms;
    unsigned char has_mult_terms;
    unsigned char nbits;
    // multiply value
    unsigned int red_mult_term;
    unsigned int green_mult_term;
    unsigned int blue_mult_term;
    unsigned int alpha_mult_term;
    // addition value
    unsigned int red_add_term;
    unsigned int green_add_term;
    unsigned int blue_add_term;
    unsigned int alpha_add_term;
} swf_cxformwithalpha_t;


extern int swf_cxformwithalpha_parse(bitstream_t *bs, swf_cxformwithalpha_t *color);
extern int swf_cxformwithalpha_build(bitstream_t *bs, swf_cxformwithalpha_t *color);
extern int swf_cxformwithalpha_print(swf_cxformwithalpha_t *color, int indent_depth);

#endif /* __SWF_CXFORMWITHALPHA_H__ */
