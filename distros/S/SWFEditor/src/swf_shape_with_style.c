#include <stdio.h>
#include "bitstream.h"
#include "swf_shape_with_style.h"
#include "swf_tag_shape.h"

int
swf_shape_with_style_parse(bitstream_t *bs,
                           swf_shape_with_style_t *shape_with_style,
                           swf_tag_t *tag) {
    int result;
    swf_tag_shape_detail_t *swf_tag_shape = (swf_tag_shape_detail_t *) tag->detail;
    result = swf_styles_parse(bs, &(shape_with_style->styles), tag);
    if (result) {
        fprintf(stderr, "swf_shape_with_style_parse: swf_styles_parse failed\n");
        return result;
    }
    swf_tag_shape->_current_styles_count = shape_with_style->styles.styles_count; // XXX
    result = swf_shape_record_parse(bs, &(shape_with_style->shape_records),
                                    tag);
    if (result) {
        fprintf(stderr, "swf_shape_with_style_parse: swf_shape_record_parse failed\n");
        return result;
    }
    return result;
}

int
swf_shape_with_style_build(bitstream_t *bs, swf_shape_with_style_t *shape_with_style, swf_tag_t *tag) {
    int ret;
    ret = swf_styles_build(bs, &(shape_with_style->styles), tag);
    if (ret) {
        fprintf(stderr, "swf_shape_with_style_build: swf_styles_build failed\n");
        return ret;
    }
    ret = swf_shape_record_build(bs, &(shape_with_style->shape_records), tag);
    if (ret) {
        fprintf(stderr, "swf_shape_with_style_build: swf_shape_record_build failed\n");
        return ret;
    }
    return 0;
}

int
swf_shape_with_style_print(swf_shape_with_style_t *shape_with_style, int indent_depth, swf_tag_t *tag) {
    swf_styles_print(&(shape_with_style->styles), indent_depth, tag);
    swf_shape_record_print(&(shape_with_style->shape_records), indent_depth,
                           tag);
    return 0;
}

int
swf_shape_with_style_delete(swf_shape_with_style_t *shape_with_style) {
  swf_styles_delete(&(shape_with_style->styles));
  swf_shape_record_delete(&(shape_with_style->shape_records));
  return 0;
}
