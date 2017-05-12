#include <stdio.h>
#include "bitstream.h"
#include "swf_line_style.h"

int
swf_line_style_parse(bitstream_t *bs, swf_line_style_t *line_style,
                     swf_tag_t *tag) {
    int result;
    if (tag->code == 46) { // DefineMorphShape
        result = bitstream_getbytesLE(bs, 2);
        if (result == -1) {
            return 1;
        }
        line_style->width = result;
        line_style->width_morph = bitstream_getbytesLE(bs, 2);
        swf_rgba_parse(bs, &(line_style->rgba));
        swf_rgba_parse(bs, &(line_style->rgba_morph));
    } else if (tag->code == 83 || tag->code == 84) {
        // DefineShape4 || DefineMorphShape2
        if (tag->code == 84) { // DefineMorphShape2
            line_style->width_morph = bitstream_getbytesLE(bs, 2);
        }
        result = bitstream_getbits(bs, 2);
        if (result == -1) {
            return 1;
        }
        line_style->start_cap_style = result;
        line_style->join_style = bitstream_getbits(bs, 2);
        line_style->has_fill = bitstream_getbits(bs, 1);
        line_style->no_hscale = bitstream_getbits(bs, 1);
        line_style->no_vscale = bitstream_getbits(bs, 1);
        line_style->pixel_hinting = bitstream_getbits(bs, 1);
        line_style->reserved = bitstream_getbits(bs, 5);
        line_style->no_close = bitstream_getbits(bs, 1);
        line_style->end_cap_style = bitstream_getbits(bs, 2);
        if (line_style->join_style == 2) {
            line_style->miter_limit_factor = bitstream_getbytesLE(bs, 2);
        }
        if (line_style->has_fill) {
            swf_fill_style_parse(bs, &(line_style->fill_style), tag);
        } else {
            swf_rgba_parse(bs, &(line_style->rgba));
            if (tag->code == 84) { // DefineMorphShape2
                swf_rgba_parse(bs, &(line_style->rgba_morph));
            }
        }
    } else if (tag->code == 32) { // DefineShape3
        result = bitstream_getbytesLE(bs, 2);
        if (result == -1) {
            return 1;
        }
        line_style->width = result;
        swf_rgba_parse(bs, &(line_style->rgba));
    } else {
        result = bitstream_getbytesLE(bs, 2);
        if (result == -1) {
            return 1;
        }
        line_style->width = result;
        swf_rgb_parse(bs, &(line_style->rgb));
    }
    return 0;
}

int
swf_line_style_build(bitstream_t *bs, swf_line_style_t *line_style,
                     swf_tag_t *tag) {
    if (tag->code == 46) { // DefineMorphShape
        bitstream_putbytesLE(bs, line_style->width, 2);
        bitstream_putbytesLE(bs, line_style->width_morph, 2);
        swf_rgba_build(bs, &(line_style->rgba));
        swf_rgba_build(bs, &(line_style->rgba_morph));
    } else if (tag->code == 83 || tag->code == 84) {
        // DefineShape4 || DefineMorphShape2
        if (tag->code == 84) { // DefineMorphShape2
            bitstream_putbytesLE(bs, line_style->width_morph, 2);
        }
        bitstream_putbits(bs, line_style->start_cap_style, 2);
        bitstream_putbits(bs, line_style->join_style, 2);
        bitstream_putbits(bs, line_style->has_fill, 1);
        bitstream_putbits(bs, line_style->no_hscale, 1);
        bitstream_putbits(bs, line_style->no_vscale, 1);
        bitstream_putbits(bs, line_style->pixel_hinting, 1);
        bitstream_putbits(bs, line_style->reserved , 5);
        bitstream_putbits(bs, line_style->no_close, 1);
        bitstream_putbits(bs, line_style->end_cap_style, 2);
        if (line_style->join_style == 2) {
            bitstream_putbytesLE(bs, line_style->miter_limit_factor, 2);
        }
        if (line_style->has_fill) {
            swf_fill_style_build(bs, &(line_style->fill_style), tag);
        } else {
            swf_rgba_build(bs, &(line_style->rgba));
            if (tag->code == 84) { // DefineMorphShape2
                swf_rgba_build(bs, &(line_style->rgba_morph));
            }
        }
    } else if (tag->code == 32) { // DefineShape3
        bitstream_putbytesLE(bs, line_style->width, 2);
        swf_rgba_build(bs, &(line_style->rgba));
    } else {
        bitstream_putbytesLE(bs, line_style->width, 2);
        swf_rgb_build(bs, &(line_style->rgb));
    }
    return 0;
}

int
swf_line_style_print(swf_line_style_t *line_style, int indent_depth,
                     swf_tag_t *tag) {
    if (line_style == NULL) {
        fprintf(stderr, "swf_line_style_print: line_style == NULL\n");
        return 1;
    }
    if (tag->code == 46) { // DefineMorphShape
        print_indent(indent_depth);
        printf("width=%.2f  width_morph=%.2f\n",
               (float) line_style->width / SWF_TWIPS,
	       (float) line_style->width_morph / SWF_TWIPS);
        swf_rgba_print(&(line_style->rgba), indent_depth);
        swf_rgba_print(&(line_style->rgba_morph), indent_depth);
    } else if (tag->code == 83 || tag->code == 84) {
        // DefineShape4 || DefineMorphShape2
        if (tag->code == 84) { // DefineMorphShape2
            print_indent(indent_depth);
            printf("width_morph=%d\n", line_style->width_morph);
        }
        print_indent(indent_depth);
        printf("start_cap_style=%u  join_style=%u  has_fill=%u\n",
               line_style->start_cap_style,
               line_style->join_style, line_style->has_fill);
        print_indent(indent_depth);
        printf("no_hscale=%u  no_vscale=%u  pixel_hinting=%u\n",
               line_style->no_hscale, line_style->no_vscale,
               line_style->pixel_hinting);
        print_indent(indent_depth);
        printf("(reserved=%u)  no_close=%u end_cap_style=%u\n",
               line_style->reserved, line_style->no_close,
               line_style->end_cap_style);
        if (line_style->join_style == 2) {
            print_indent(indent_depth);
            printf("miter_limit_factor=%u\n", line_style->miter_limit_factor);
        }
        if (line_style->has_fill) {
            swf_fill_style_print(&(line_style->fill_style), indent_depth + 1,
                tag);
        } else {
            swf_rgba_print(&(line_style->rgba), indent_depth);
            if (tag->code == 84) { // DefineMorphShape2
                swf_rgba_print(&(line_style->rgba_morph), indent_depth);
            }
        }
    } else if (tag->code == 32) { // DefineShape3
        print_indent(indent_depth);
        printf("width=%.2f ", (float) line_style->width / SWF_TWIPS);
        swf_rgba_print(&(line_style->rgba), 0);
    } else {
        print_indent(indent_depth);
        printf("width=%.2f ", (float) line_style->width / SWF_TWIPS);
        swf_rgb_print(&(line_style->rgb), 0);
    }
    return 0;
}

int
swf_line_style_delete(swf_line_style_t *line_style) {
    if (line_style->has_fill) {
        swf_fill_style_delete(&(line_style->fill_style));
    }
    return 0;
}
