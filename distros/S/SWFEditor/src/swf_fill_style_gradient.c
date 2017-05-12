#include <stdio.h>
#include "bitstream.h"
#include "swf_fill_style_gradient.h"

int
swf_fill_style_gradient_parse(bitstream_t *bs,
                              swf_fill_style_gradient_t *fill_style_gradient,
                              swf_tag_t* tag) {
    swf_matrix_parse(bs, &(fill_style_gradient->gradient_matrix));
    // DefineMorphShape, DefineMorphShape2
    if (tag->code == 46 || tag->code == 84) {
        swf_matrix_parse(bs, &(fill_style_gradient->gradient_matrix_morph));
    }
    swf_gradient_parse(bs, &(fill_style_gradient->gradient), tag, fill_style_gradient->type);
    return 0;
}

int
swf_fill_style_gradient_build(bitstream_t *bs,
                              swf_fill_style_gradient_t *fill_style_gradient,
                              swf_tag_t *tag) {
    swf_matrix_build(bs, &(fill_style_gradient->gradient_matrix));
    // DefineMorphShape, DefineMorphShape2
    if (tag->code == 46 || tag->code == 84) {
        swf_matrix_build(bs, &(fill_style_gradient->gradient_matrix_morph));
    }
    swf_gradient_build(bs, &(fill_style_gradient->gradient), tag, fill_style_gradient->type);
    return 0;
}

int
swf_fill_style_gradient_print(swf_fill_style_gradient_t *fill_style_gradient,
                              int indent_depth, swf_tag_t* tag) {
    print_indent(indent_depth);
    printf("fill_style_gradient\n");
    swf_matrix_print(&(fill_style_gradient->gradient_matrix),
                     indent_depth + 1);
    // DefineMorphShape, DefineMorphShape2
    if (tag->code == 46 || tag->code == 84) {
        swf_matrix_print(&(fill_style_gradient->gradient_matrix_morph),
                         indent_depth + 1);
    }
    swf_gradient_print(&(fill_style_gradient->gradient), indent_depth + 1, tag, fill_style_gradient->type);
    return 0;
}


int
swf_fill_style_gradient_delete(swf_fill_style_gradient_t *fill_style_gradient) {
    swf_gradient_delete(&(fill_style_gradient->gradient));
    return 0;
}
