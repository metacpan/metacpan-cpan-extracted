#include <stdio.h>
#include <math.h>
#include "bitstream.h"
#include "swf_matrix.h"

int
swf_matrix_parse(bitstream_t *bs, swf_matrix_t *matrix) {
    int translate_bits;
    int ret;
    bitstream_align(bs); // The MATRIX record must be byte aligned.
    ret = bitstream_getbit(bs);
    if (ret == -1) {
        return 1;
    }
    matrix->has_scale = ret;
    if (matrix->has_scale) {
        int scale_bits = bitstream_getbits(bs, 5);
        matrix->scale_bits = scale_bits;
        matrix->scale_x = bitstream_getbits_signed(bs, scale_bits);
        matrix->scale_y = bitstream_getbits_signed(bs, scale_bits);
    } else {
        matrix->scale_x = SWF_TWIPS; // XXX
        matrix->scale_y = SWF_TWIPS; // XXX
    }
    ret = bitstream_getbit(bs);
    if (ret == -1) {
        return 1;
    }
    matrix->has_rotate = ret;
    if (matrix->has_rotate) {
        int rotate_bits = bitstream_getbits(bs, 5);
        matrix->rotate_bits = rotate_bits;
        matrix->rotate_skew0 = bitstream_getbits_signed(bs, rotate_bits);
        matrix->rotate_skew1 = bitstream_getbits_signed(bs, rotate_bits);
    } else {
        matrix->rotate_skew0 = 0;
        matrix->rotate_skew1 = 0;
    }
    translate_bits = bitstream_getbits(bs, 5);
    matrix->translate_bits = translate_bits;
    matrix->translate_x = bitstream_getbits_signed(bs, translate_bits);
    matrix->translate_y = bitstream_getbits_signed(bs, translate_bits);
    return 0;
}

int
swf_matrix_build(bitstream_t *bs, swf_matrix_t *matrix) {
    int translate_bits;
    float log2_x, log2_y;
    bitstream_align(bs); // The MATRIX record must be byte aligned.
    bitstream_putbit(bs, matrix->has_scale);
    if (matrix->has_scale) {
        int scale_bits;
        log2_x = bitstream_need_bits_signed(matrix->scale_x);
        log2_y = bitstream_need_bits_signed(matrix->scale_y);
        scale_bits = (log2_x > log2_y)? log2_x: log2_y;
        bitstream_putbits(bs, scale_bits, 5);
        bitstream_putbits_signed(bs, matrix->scale_x, scale_bits);
        bitstream_putbits_signed(bs, matrix->scale_y, scale_bits);
    }
    if ((matrix->rotate_skew0 == 0) && (matrix->rotate_skew1 == 0)) {
        matrix->has_rotate = 0;
    }
    bitstream_putbit(bs, matrix->has_rotate);
    if (matrix->has_rotate) {
        int rotate_bits;
        float log2_skew0, log2_skew1;
        log2_skew0 = bitstream_need_bits_signed(matrix->rotate_skew0);
        log2_skew1 = bitstream_need_bits_signed(matrix->rotate_skew1);
        rotate_bits = (log2_skew0 > log2_skew1)? log2_skew0: log2_skew1;
        bitstream_putbits(bs, rotate_bits, 5);
        bitstream_putbits_signed(bs, matrix->rotate_skew0, rotate_bits);
        bitstream_putbits_signed(bs, matrix->rotate_skew1, rotate_bits);
    }
    if ((matrix->translate_x == 0) && (matrix->translate_y == 0)) {
        translate_bits = 0;
        bitstream_putbits(bs, translate_bits, 5);
    } else {
        log2_x = bitstream_need_bits_signed(matrix->translate_x);
        log2_y = bitstream_need_bits_signed(matrix->translate_y);
        translate_bits = (log2_x > log2_y)? log2_x: log2_y;
        bitstream_putbits(bs, translate_bits, 5);
        bitstream_putbits_signed(bs, matrix->translate_x, translate_bits);
        bitstream_putbits_signed(bs, matrix->translate_y, translate_bits);
    }
    return 0;
}

int
swf_matrix_print(swf_matrix_t *matrix, int indent_depth) {
    print_indent(indent_depth);
    if (matrix->has_scale) {
        printf("scale=(%.3f,%.3f):bits=%u  ",
               matrix->scale_x / 65536.0 / SWF_TWIPS,
	       matrix->scale_y / 65536.0 / SWF_TWIPS,
               matrix->scale_bits);
    } else {
        printf("(has_scale=no)  ");
    }
    if (matrix->has_rotate) {
        printf("rotate=(%.3f,%.3f)bits=%u\n",
               matrix->rotate_skew0 / 65536.0 / SWF_TWIPS,
	       matrix->rotate_skew1 / 65536.0 / SWF_TWIPS,
               matrix->rotate_bits);
    } else {
        printf("(has_rotate=no)\n");
    }
    print_indent(indent_depth);
    printf("translate=(%.2f,%.2f):bits=%u\n",
           (float) matrix->translate_x / SWF_TWIPS,
	   (float) matrix->translate_y / SWF_TWIPS,
           matrix->translate_bits);
    return 0;
}

int
swf_matrix_apply_factor(swf_matrix_t *matrix,
                        double scale_x, double scale_y,
                        double rotate_rad,
                        signed int trans_x, signed int trans_y) {
    if (matrix->has_scale == 0) {
        matrix->has_scale = 1;
        matrix->scale_x = 20 * 65536;
        matrix->scale_y = 20 * 65536;
    }
    matrix->scale_x *= scale_x;
    matrix->scale_y *= scale_y;
    if ((rotate_rad != 0)) {
        double rot_sin, rot_cos;
        long sx, sy, s0, s1;
        if (matrix->has_rotate == 0) {
            matrix->has_rotate = 1;
            matrix->rotate_skew0 = 0;
            matrix->rotate_skew1 = 0;
        }
        rot_cos = cos(rotate_rad);
        rot_sin = sin(rotate_rad);
        sx = rot_cos * matrix->scale_x - rot_sin * matrix->rotate_skew0;
        s0 = rot_sin * matrix->scale_x + rot_cos * matrix->rotate_skew0;
        s1 = rot_cos * matrix->rotate_skew1 - rot_sin * matrix->scale_y;
        sy = rot_sin * matrix->rotate_skew1 + rot_cos * matrix->scale_y;
        matrix->scale_x = sx;
        matrix->scale_y = sy;
        matrix->rotate_skew0 = s0;
        matrix->rotate_skew1 = s1;
    }
    matrix->translate_x += 20 * trans_x;
    matrix->translate_y += 20 * trans_y;
    return 0;
}
