#include <stdio.h>
#include "bitstream.h"
#include "swf_fill_style_solid.h"

int
swf_fill_style_solid_parse(bitstream_t *bs,
                           swf_fill_style_solid_t *fill_style_solid,
                           swf_tag_t *tag) {
    if (tag->code == 46 || tag->code == 84) { // DefineMorphShape, DefineMorphShape2
        swf_rgba_parse(bs, &(fill_style_solid->rgba));
        swf_rgba_parse(bs, &(fill_style_solid->rgba_morph));
    } else if (tag->code == 32) { // DefineShape3
        swf_rgba_parse(bs, &(fill_style_solid->rgba));
    } else {
        swf_rgb_parse(bs, &(fill_style_solid->rgb));
    }
    return 0;
}

int
swf_fill_style_solid_build(bitstream_t *bs,
                           swf_fill_style_solid_t *fill_style_solid,
                           swf_tag_t *tag) {
    if (tag->code == 46 || tag->code == 84) { // DefineMorphShape, DefineMorphShape2
        swf_rgba_build(bs, &(fill_style_solid->rgba));
        swf_rgba_build(bs, &(fill_style_solid->rgba_morph));
    } else if (tag->code == 32) { // DefineShape3
        swf_rgba_build(bs, &(fill_style_solid->rgba));
    } else {
        swf_rgb_build(bs, &(fill_style_solid->rgb));
    }
    return 0;
}

int
swf_fill_style_solid_print(swf_fill_style_solid_t *fill_style_solid,
                           int indent_depth, swf_tag_t *tag
) {
    print_indent(indent_depth);
    printf("fill_style_solid");
    if (tag->code == 46 || tag->code == 84) { // DefineMorphShape, DefineMorphShape2
        printf("  #%02x%02x%02x(%02x)  morph:#%02x%02x%02x(%02x)",
               fill_style_solid->rgba.red,
               fill_style_solid->rgba.green,
               fill_style_solid->rgba.blue,
               fill_style_solid->rgba.alpha,
               fill_style_solid->rgba_morph.red,
               fill_style_solid->rgba_morph.green,
               fill_style_solid->rgba_morph.blue,
               fill_style_solid->rgba_morph.alpha);
    } else if (tag->code == 32) { // DefineShape3
        printf("  #%02x%02x%02x(%02x)",
               fill_style_solid->rgba.red,
               fill_style_solid->rgba.green,
               fill_style_solid->rgba.blue,
               fill_style_solid->rgba.alpha);
    } else {
        printf("  #%02x%02x%02x",
               fill_style_solid->rgb.red,
               fill_style_solid->rgb.green,
               fill_style_solid->rgb.blue);
    }
    printf("\n");
    return 0;
}
