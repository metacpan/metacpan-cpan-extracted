#include <stdio.h>
#include "bitstream.h"
#include "swf_fill_style_bitmap.h"

int
swf_fill_style_bitmap_parse(bitstream_t *bs,
                            swf_fill_style_bitmap_t *fill_style_bitmap,
                            swf_tag_t *tag) {
    fill_style_bitmap->bitmap_ref = bitstream_getbytesLE(bs, 2);
    swf_matrix_parse(bs, &(fill_style_bitmap->bitmap_matrix));
    if (tag->code == 46 || tag->code == 84) { // DefineMorphShape, DefineMorphShape2
        swf_matrix_parse(bs, &(fill_style_bitmap->bitmap_matrix_morph));
    }
    return 0;
}

int
swf_fill_style_bitmap_build(bitstream_t *bs,
                            swf_fill_style_bitmap_t *fill_style_bitmap,
                            swf_tag_t *tag) {
    bitstream_putbytesLE(bs, fill_style_bitmap->bitmap_ref, 2);
    swf_matrix_build(bs, &(fill_style_bitmap->bitmap_matrix));
    if (tag->code == 46 || tag->code == 84) { // DefineMorphShape, DefineMorphShape2
        swf_matrix_build(bs, &(fill_style_bitmap->bitmap_matrix_morph));
    }
    return 0;
}

int
swf_fill_style_bitmap_print(swf_fill_style_bitmap_t *fill_style_bitmap,
                            int indent_depth, swf_tag_t *tag) {
    print_indent(indent_depth);
    printf("fill_style_bitmap\n");
    print_indent(indent_depth);
    printf("bitmap_ref=%u\n", fill_style_bitmap->bitmap_ref);
    swf_matrix_print(&(fill_style_bitmap->bitmap_matrix), indent_depth);
    if (tag->code == 46 || tag->code == 84) { // DefineMorphShape, DefineMorphShape2
        swf_matrix_print(&(fill_style_bitmap->bitmap_matrix_morph), indent_depth);
    }
    return 0;
}
