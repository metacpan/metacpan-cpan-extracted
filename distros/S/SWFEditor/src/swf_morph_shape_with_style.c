#include <stdio.h>
#include "bitstream.h"
#include "swf_morph_shape_with_style.h"

int
swf_morph_shape_with_style_parse(bitstream_t *bs,
                                 swf_morph_shape_with_style_t *morph_shape_with_style,
                                 swf_tag_t *tag) {
    int ret;
    swf_styles_parse(bs, &(morph_shape_with_style->styles), tag);
    ret = swf_shape_record_parse(bs, &(morph_shape_with_style->shape_records), tag);
    if (ret) {
        fprintf(stderr, "swf_morph_shape_with_style_parse: swf_shape_record_parse shape_records failed\n");
        return ret;
    }

    bitstream_align(bs);
    swf_styles_count_parse(bs, &(morph_shape_with_style->styles_count));
    ret = swf_shape_record_parse(bs, &(morph_shape_with_style->shape_records_morph),
                                 tag);
    if (ret) {
        fprintf(stderr, "swf_morph_shape_with_style_parse: swf_shape_record_parse shape_records_morph failed\n");
        return ret;
    }
    return ret;
}

int
swf_morph_shape_with_style_build(bitstream_t *bs,
                                 swf_morph_shape_with_style_t *morph_shape_with_style,
                                 swf_tag_t *tag) {
    swf_styles_build(bs, &(morph_shape_with_style->styles), tag);
    swf_shape_record_build(bs, &(morph_shape_with_style->shape_records), tag);

    bitstream_align(bs);
    morph_shape_with_style->offset_of_end_edges = bitstream_getbytepos(bs);

    swf_styles_count_build(bs, &(morph_shape_with_style->styles_count));
    swf_shape_record_build(bs, &(morph_shape_with_style->shape_records_morph),
                           tag);
    return 0;
}

int
swf_morph_shape_with_style_print(swf_morph_shape_with_style_t *morph_shape_with_style,
                                 int indent_depth,
                                 swf_tag_t *tag) {
    swf_styles_print(&(morph_shape_with_style->styles), indent_depth + 1, tag);
    print_indent(indent_depth);
    printf("shape_records:\n");
    swf_shape_record_print(&(morph_shape_with_style->shape_records),
                           indent_depth + 1, tag);
    swf_styles_count_print(&(morph_shape_with_style->styles_count),
                           indent_depth + 1);
    print_indent(indent_depth);
    printf("shape_records_morph:\n");
    
    swf_shape_record_print(&(morph_shape_with_style->shape_records_morph),
                           indent_depth + 1, tag);
    return 0;
}

int
swf_morph_shape_with_style_delete(swf_morph_shape_with_style_t *morph_shape_with_style) {
    swf_styles_delete(&(morph_shape_with_style->styles));
    swf_shape_record_delete(&(morph_shape_with_style->shape_records));
    swf_shape_record_delete(&(morph_shape_with_style->shape_records_morph));
    return 0;
}
