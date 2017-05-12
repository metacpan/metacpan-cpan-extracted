#include <stdio.h>
#include "bitstream.h"
#include "swf_fill_style.h"
#include "swf_tag_shape.h"

int
swf_fill_style_parse(bitstream_t *bs, swf_fill_style_t *fill_style,
                     swf_tag_t * tag) {
    swf_tag_shape_detail_t *swf_tag_shape = (swf_tag_shape_detail_t *) tag->detail;
        
    fill_style->type = bitstream_getbyte(bs);

    if (swf_tag_shape->_parse_condition == SWF_TAG_SHAPE_PARSE_CONDITION_BITMAP) {
        if ((fill_style->type < 0x40) ||  (0x43 < fill_style->type)) {
            return 1;
        }
    }
    
    switch (fill_style->type) {
      case 0x00: // solid fill
        swf_fill_style_solid_parse(bs, &(fill_style->solid), tag);
        break;
      case 0x10: // linear gradient fill
      case 0x12: // radial gradient fill
      case 0x13: // focal  gradient fill
        swf_fill_style_gradient_parse(bs, &(fill_style->gradient), tag);
        break;
      case 0x40: // tilled  bitmap fill with smoothed edges
      case 0x41: // clipped bitmap fill with smoothed edges
      case 0x42: // tilled  bitmap fill with hard edges
      case 0x43: // clipped bitmap fill with hard edges
        swf_fill_style_bitmap_parse(bs, &(fill_style->bitmap), tag);
        break;
    default:
        fprintf(stderr, "swf_fill_style_parse: unknown fill_style->type=0x%02x\n", fill_style->type);
        return 1;
    }
    return 0;
}

int
swf_fill_style_build(bitstream_t *bs, swf_fill_style_t *fill_style,
                     swf_tag_t *tag) {
    if (fill_style == NULL) {
        fprintf(stderr, "swf_fill_style_build: fill_style == NULL\n");
        return 1;
    }
    bitstream_putbyte(bs, fill_style->type);
    switch (fill_style->type) {
      case 0x00: // solid fill
        swf_fill_style_solid_build(bs, &(fill_style->solid), tag);
        break;
      case 0x10: // linear gradient fill
      case 0x11: // radial gradient fill
      case 0x12: // focal  gradient fill
        swf_fill_style_gradient_build(bs, &(fill_style->gradient), tag);
        break;
      case 0x40: // tilled  bitmap fill with smoothed edges
      case 0x41: // clipped bitmap fill with smoothed edges
      case 0x42: // tilled  bitmap fill with hard edges
      case 0x43: // clipped bitmap fill with hard edges
        swf_fill_style_bitmap_build(bs, &(fill_style->bitmap), tag);
        break;
      default:
        fprintf(stderr, "swf_fill_style_build: unknown fill_style->type=%d\n", fill_style->type);
        return 1;
    }
    return 0;
}

int
swf_fill_style_print(swf_fill_style_t *fill_style, int indent_depth,
    swf_tag_t *tag) {
    if (fill_style == NULL) {
        fprintf(stderr, "swf_fill_style_print: fill_style == NULL\n");
        return 1;
    }
    printf("type=0x%02x\n", fill_style->type);
    switch (fill_style->type) {
      case 0x00: // solid fill
          swf_fill_style_solid_print(&(fill_style->solid),
                                     indent_depth + 1, tag);
          break;
      case 0x10: // linear gradient fill
      case 0x11: // radial gradient fill
      case 0x12: // focal  gradient fill
        swf_fill_style_gradient_print(&(fill_style->gradient),
                                      indent_depth + 1, tag);
        break;
      case 0x40: // tilled  bitmap fill with smoothed edges
      case 0x41: // clipped bitmap fill with smoothed edges
      case 0x42: // tilled  bitmap fill with hard edges
      case 0x43: // clipped bitmap fill with hard edges
        swf_fill_style_bitmap_print(&(fill_style->bitmap),
                                    indent_depth + 1, tag);
        break;
    }
    return 0;
}

int
swf_fill_style_delete(swf_fill_style_t *fill_style) {
    swf_fill_style_gradient_delete(&(fill_style->gradient));
    return 0;
}
