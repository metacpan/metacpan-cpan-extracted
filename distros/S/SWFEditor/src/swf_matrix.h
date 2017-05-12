/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_MATRIX_H__
#define __SWF_MATRIX_H__

typedef struct swf_matrix_ {
    // char align;
    unsigned char has_scale:1;
    unsigned char scale_bits; //  : 5;
    signed long scale_x; // : scale_bits; n.16 fixed point
    signed long scale_y; // : scale_bits; n.16 fixed point

    unsigned has_rotate : 1;
    unsigned rotate_bits; // : 5;
    signed long rotate_skew0; // : rotate_bits; n.16 fixed point
    signed long rotate_skew1; // : rotate_bits; n.16 fixed point

    unsigned translate_bits; // : f_rotate_bits;
    signed translate_x;      // : f_rotate_bits;
    signed translate_y;      // : f_rotate_bits;
} swf_matrix_t;

extern int swf_matrix_parse(bitstream_t *bs, swf_matrix_t *matrix);
extern int swf_matrix_build(bitstream_t *bs, swf_matrix_t *matrix);
extern int swf_matrix_print(swf_matrix_t *matrix, int indent_depth);

extern int swf_matrix_apply_factor(swf_matrix_t *matrix,
                                   double scale_x, double scale_y,
                                   double rotate_rad,
                                   signed int trans_x, signed int trans_y);

#endif /* __SWF_MATRIX_H__ */
