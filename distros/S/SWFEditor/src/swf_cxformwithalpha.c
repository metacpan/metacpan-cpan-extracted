#include <stdio.h>
#include "bitstream.h"
#include "swf_cxformwithalpha.h"

int
swf_cxformwithalpha_parse(bitstream_t *bs, swf_cxformwithalpha_t *cx) {
    int ret, nbits;
    bitstream_align(bs);
    cx->has_add_terms  = bitstream_getbit(bs);
    cx->has_mult_terms = bitstream_getbit(bs);
    nbits = bitstream_getbits(bs, 4);
    cx->nbits = nbits;
    if (cx->has_mult_terms) {
        cx->red_mult_term   = bitstream_getbits(bs, nbits);
        cx->green_mult_term = bitstream_getbits(bs, nbits);
        cx->blue_mult_term  = bitstream_getbits(bs, nbits);
        ret                 = bitstream_getbits(bs, nbits);
        if (ret == -1) {
            return 1;
        }
        cx->alpha_mult_term  = ret;
    }
    if (cx->has_add_terms) {
        cx->red_add_term   = bitstream_getbits(bs, nbits);
        cx->green_add_term = bitstream_getbits(bs, nbits);
        cx->blue_add_term  = bitstream_getbits(bs, nbits);
        ret                = bitstream_getbits(bs, nbits);
        if (ret == -1) {
            return 1;
        }
        cx->alpha_add_term  = ret;
    }
    return 0;
}

int
swf_cxformwithalpha_build(bitstream_t *bs, swf_cxformwithalpha_t *cx) {
    int nbits;
    bitstream_align(bs);
    bitstream_putbit(bs, cx->has_add_terms);
    bitstream_putbit(bs, cx->has_mult_terms);
    nbits = cx->nbits;
    bitstream_putbits(bs, nbits, 4);
    if (cx->has_mult_terms) {
        bitstream_putbits(bs, cx->red_mult_term,   nbits);
        bitstream_putbits(bs, cx->green_mult_term, nbits);
        bitstream_putbits(bs, cx->blue_mult_term,  nbits);
        bitstream_putbits(bs, cx->alpha_mult_term, nbits);
    }
    if (cx->has_add_terms) {
        bitstream_putbits(bs, cx->red_add_term,   nbits);
        bitstream_putbits(bs, cx->green_add_term, nbits);
        bitstream_putbits(bs, cx->blue_add_term,  nbits);
        bitstream_putbits(bs, cx->alpha_add_term, nbits);
    }
    return 0;
}

int
swf_cxformwithalpha_print(swf_cxformwithalpha_t *cx, int indent_depth) {
    print_indent(indent_depth);
    printf("CXFORMWITHALPHA:");
    if (cx->has_mult_terms) {
        printf("  MultTerm:%02x%02x%02x(%02x)",
               cx->red_mult_term, cx->green_mult_term, cx->blue_mult_term,
               cx->alpha_mult_term);
    }
    if (cx->has_add_terms) {
        printf("  AddTerm:%02x%02x%02x(%02x)",
               cx->red_add_term, cx->green_add_term, cx->blue_add_term,
               cx->alpha_add_term);
    }
    if ((cx->has_add_terms == 0) && (cx->has_mult_terms == 0)) {
        printf("  (no add_terms or mult_terms)");
    }
    printf("\n");
    return 0;
}
