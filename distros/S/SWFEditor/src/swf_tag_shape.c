/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#include <stdio.h>
#include <string.h>
#include "bitstream.h"
#include "swf_shape_record.h"
#include "swf_tag_shape.h"
#include "swf_object.h"

swf_tag_detail_handler_t shape_detail_handler;

swf_tag_detail_handler_t *
swf_tag_shape_detail_handler(void) {
    shape_detail_handler.create   = swf_tag_shape_create_detail;
    shape_detail_handler.input    = swf_tag_shape_input_detail;
    shape_detail_handler.get_cid  = swf_tag_shape_get_cid_detail;
    shape_detail_handler.replace_cid = swf_tag_shape_replace_cid_detail;
    shape_detail_handler.output   = swf_tag_shape_output_detail;
    shape_detail_handler.print    = swf_tag_shape_print_detail;
    shape_detail_handler.destroy  = swf_tag_shape_destroy_detail;
    return &shape_detail_handler;
}

swf_tag_detail_handler_t *
swf_tag_shape_cid_handler(void) {
    shape_detail_handler.create   = NULL;
    shape_detail_handler.input    = NULL;
    shape_detail_handler.get_cid     = swf_tag_shape_get_cid_detail;
    shape_detail_handler.replace_cid = swf_tag_shape_replace_cid_detail;
    shape_detail_handler.output   = NULL;
    shape_detail_handler.print    = NULL;
    shape_detail_handler.destroy  = NULL;
    return &shape_detail_handler;
}

void *
swf_tag_shape_create_detail(void) {
    swf_tag_shape_detail_t *swf_tag_shape;
    swf_tag_shape = calloc(sizeof(*swf_tag_shape), 1);
    if (swf_tag_shape == NULL) {
        fprintf(stderr, "ERROR: swf_tag_shape_create_detail: can't calloc\n");
        return NULL;
    }
    return swf_tag_shape;
}

int
swf_tag_shape_input_detail(swf_tag_t *tag, struct swf_object_ *swf) {
    swf_tag_shape_detail_t *swf_tag_shape = tag->detail;
    unsigned char *data  = tag->data;
    unsigned long length = tag->length;
    bitstream_t *bs;
    int ret;
    (void) swf;
    if (swf_tag_shape == NULL) {
        fprintf(stderr, "ERROR: swf_tag_shape_input_detail: swf_tag_shape == NULL\n");
        return 1;
    }
    // parse context
    swf_tag_shape->_current_x = 0;
    swf_tag_shape->_current_y = 0;
    swf_tag_shape->_parse_condition = 0;

    bs = bitstream_open();
    bitstream_input(bs, data, length);
    
    swf_tag_shape->shape_id = bitstream_getbytesLE(bs, 2);
    ret = swf_rect_parse(bs, &(swf_tag_shape->rect));
    if (ret) {
        fprintf(stderr, "ERROR: swf_tag_shape_input_detail: swf_tag_shape->rect parse failed. shape_id=%d\n", swf_tag_shape->shape_id);
        bitstream_close(bs);
        return ret;
    }

    // DefineMorphShape, DefineMorphShape2
    swf_tag_shape->is_morph = (tag->code == 46) || (tag->code == 84);
    // DefineShape4, DefineMorphShape2
    swf_tag_shape->has_strokes = (tag->code == 83) || (tag->code == 84);

    if (swf_tag_shape->is_morph) {
        ret = swf_rect_parse(bs, &(swf_tag_shape->rect_morph));
        if (ret) {
            fprintf(stderr, "ERROR: swf_tag_shape_input_detail: swf_tag_shape->rect_morph parse failed. shape_id=%d\n", swf_tag_shape->shape_id);
            bitstream_close(bs);
            return ret;
        }
    }
    if (swf_tag_shape->has_strokes) {
        ret = swf_rect_parse(bs, &(swf_tag_shape->stroke_rect));
        if (ret) {
            fprintf(stderr, "ERROR: swf_tag_shape_input_detail: swf_tag_shape->stroke_rect parse failed. shape_id=%d\n", swf_tag_shape->shape_id);
            bitstream_close(bs);
            return ret;
        }
        if (swf_tag_shape->is_morph) {
            ret = swf_rect_parse(bs, &(swf_tag_shape->stroke_rect_morph));
            if (ret) {
                fprintf(stderr, "ERROR: swf_tag_shape_input_detail: swf_tag_shape->stroke_rect_morph parse failed. shape_id=%d\n", swf_tag_shape->shape_id);
                bitstream_close(bs);
                return ret;
            }
        }
        swf_tag_shape->define_shape_reserved = bitstream_getbits(bs, 6);
        swf_tag_shape->define_shape_non_scaling_strokes = bitstream_getbits(bs, 1);
        swf_tag_shape->define_shape_scaling_strokes = bitstream_getbits(bs, 1);
    }
    if (swf_tag_shape->is_morph) {
        bitstream_align(bs);
        swf_tag_shape->offset_morph = bitstream_getbytesLE(bs, 4);
        ret = swf_morph_shape_with_style_parse(bs, &swf_tag_shape->morph_shape_with_style, tag);
        if (ret) {
            fprintf(stderr, "ERROR: swf_tag_shape_input_detail: swf_shape_with_style_parse swf_tag_shape->morph_shape_with_style failed. shape_id=%d\n", swf_tag_shape->shape_id);
	        bitstream_close(bs);
            return ret;
        }
    } else {
        ret = swf_shape_with_style_parse(bs, &swf_tag_shape->shape_with_style, tag);
        if (ret) {
            fprintf(stderr, "ERROR: swf_tag_shape_input_detail: swf_shape_with_style_parse swf_tag_shape->shape_with_style failed. shape_id=%d\n", swf_tag_shape->shape_id);
	        bitstream_close(bs);
            return ret;
        }
    }
    
    bitstream_close(bs);
    return 0;
}

int swf_tag_shape_get_cid_detail(swf_tag_t *tag) {
    unsigned char *data = tag->data;
    if (tag->detail) {
        swf_tag_shape_detail_t *swf_tag_shape = (swf_tag_shape_detail_t *) tag->detail;
        return swf_tag_shape->shape_id;
    }
    if (data == NULL) {
        fprintf(stderr, "swf_tag_shape_get_cid_detail: data == NULL\n");
        return -1;
    }
    return GetUShortLE(data); // shape_id;
}

int swf_tag_shape_replace_cid_detail(swf_tag_t *tag, int id) {
    unsigned char *data = tag->data;
    if (tag->detail) {
        swf_tag_shape_detail_t *swf_tag_shape = (swf_tag_shape_detail_t *) tag->detail;
        swf_tag_shape->shape_id = id;
    }
    if (data) {
        PutUShortLE(data, id);
    }
    return 0; // always 0
}

static swf_shape_record_t *
_swf_tag_shape_search_new_style_in_shape_records(swf_shape_record_t *shape_records) {
    for ( ; shape_records ; shape_records = shape_records->next) {
        if ((shape_records->first_6bits) && 
            ((shape_records->first_6bits & 0x20) == 0)) {
            if (shape_records->shape.shape_setup.shape_has_new_styles) {
                break;
            }
        }
    }
    return shape_records;
}

int *
swf_tag_shape_bitmap_get_refcid_list(swf_tag_t *tag, int *cid_list_num) {
    swf_tag_shape_detail_t *swf_tag_shape;
    int i, ret;
    int *cid_list, cid_list_alloc;
    swf_styles_t *styles = NULL;
    swf_shape_record_t *shape_records = NULL;

    if (tag == NULL) {
        fprintf(stderr, "swf_tag_shape_bitmap_get_refcid: tag == NULL\n");
        return NULL;
    }
    if (! isShapeTag(tag->code)) {
        fprintf(stderr, "swf_tag_shape_bitmap_get_refcid: ! isShapeTag(%d)\n",
                tag->code);
        return NULL;
    }
    if (tag->detail == NULL) {
        tag->detail = swf_tag_shape_create_detail();
        swf_tag_shape = (swf_tag_shape_detail_t *) tag->detail;
	//        swf_tag_shape->_parse_condition = SWF_TAG_SHAPE_PARSE_CONDITION_BITMAP;
        ret = swf_tag_shape_input_detail(tag, NULL);
        if (ret) {
            swf_tag_shape_destroy_detail(tag);
            return NULL; // no shape bitmap
        }
    } else {
        swf_tag_shape = (swf_tag_shape_detail_t *) tag->detail;
    }
    //
    *cid_list_num = 0;
    cid_list_alloc = 10;
    cid_list = malloc(sizeof(int) * cid_list_alloc);

    if (tag->code == 46) { // DefineMorphShape
        styles = &(swf_tag_shape->morph_shape_with_style.styles);
        shape_records = &(swf_tag_shape->morph_shape_with_style.shape_records);
    } else {
        styles = &(swf_tag_shape->shape_with_style.styles);
        shape_records = &(swf_tag_shape->shape_with_style.shape_records);
    }
    while (1) {
        for (i = 0 ; i < styles->fill_styles.count ; i++) {
            swf_fill_style_t *fill_style;
            fill_style = &(styles->fill_styles.fill_style[i]);
            if (fill_style == NULL) {
                fprintf(stderr, "swf_tag_shape_bitmap_get_refcid: fill_style == NULL i=%d\n", i);
                free(cid_list);
                return NULL; // Illegal!!!
            }
            switch (fill_style->type) {
                void *tmp;
              case 0x40: // tilled  bitmap fill with smoothed edges
              case 0x41: // clipped bitmap fill with smoothed edges
              case 0x42: // tilled  bitmap fill with hard edges
              case 0x43: // clipped bitmap fill with hard edges
                if (fill_style->bitmap.bitmap_ref != 0xffff) {
                    if (cid_list_alloc <= *cid_list_num) {
                        cid_list_alloc *= 2;
                        tmp = realloc(cid_list, sizeof(int) * cid_list_alloc);
                        if (tmp == NULL) {
                            fprintf(stderr, "swf_tag_shape_bitmap_get_refcid_list: Can't realloc memory (%p, %d)\n", cid_list, cid_list_alloc);
                            free(cid_list);
                            return NULL;
                        }
                        cid_list = tmp;
                    }
                    cid_list[*cid_list_num] = fill_style->bitmap.bitmap_ref;
                    *cid_list_num  = (*cid_list_num) + 1;
                }
                break;
              default:
                break;
            }
        }
        shape_records = _swf_tag_shape_search_new_style_in_shape_records(shape_records);
        
        if (shape_records) {
            styles = &(shape_records->shape.shape_setup.styles);
            shape_records = shape_records->next; // next
        } else {
            break; // finish
        }
    }
    
    if (*cid_list_num == 0) {
        free(cid_list);
        return NULL;
    }
    return cid_list; // not found
}

int swf_tag_shape_bitmap_replace_refcid_list(swf_tag_t *tag, int from_cid, int to_cid) {
    swf_tag_shape_detail_t *swf_tag_shape;
    int i, ret;
    swf_styles_t *styles = NULL;
    swf_shape_record_t *shape_records = NULL;
    int morph_shape_check = 0;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_shape_bitmap_replace_refcid: tag == NULL\n");
        return 1;
    }
    if (! isShapeTag(tag->code)) {
        fprintf(stderr, "swf_tag_shape_bitmap_replace_refcid: ! isShapeTag(%d)\n",
                tag->code);
        return 1;
    }
    if (tag->detail == NULL) {
        tag->detail = swf_tag_shape_create_detail();
        swf_tag_shape = (swf_tag_shape_detail_t *) tag->detail;
//        swf_tag_shape->_parse_condition = SWF_TAG_SHAPE_PARSE_CONDITION_BITMAP;
        ret = swf_tag_shape_input_detail(tag, NULL);
        if (ret) {
            swf_tag_shape_destroy_detail(tag);
            return 1; // no shape bitmap
        }
    } else {
        swf_tag_shape = (swf_tag_shape_detail_t *) tag->detail;
    }
    
    if (tag->code == 46) { // DefineMorphShape
        morph_shape_check = 1;
        styles = &(swf_tag_shape->morph_shape_with_style.styles);
        shape_records = &(swf_tag_shape->morph_shape_with_style.shape_records);
//        shape_records = &(swf_tag_shape->morph_shape_with_style.shape_records_morph);
    } else {
        styles = &(swf_tag_shape->shape_with_style.styles);
        shape_records = &(swf_tag_shape->shape_with_style.shape_records);
    }
    while (1) {
        for (i = 0 ; i < styles->fill_styles.count ; i++) {
            swf_fill_style_t *fill_style;
            fill_style = &(styles->fill_styles.fill_style[i]);
            if (fill_style == NULL) {
                fprintf(stderr, "swf_tag_shape_bitmap_replace_refcid: fill_style == NULL i=%d\n", i);
                return 1; // Illegal!!!
            }
            switch (fill_style->type) {
              case 0x40: // tilled  bitmap fill with smoothed edges
              case 0x41: // clipped bitmap fill with smoothed edges
              case 0x42: // tilled  bitmap fill with hard edges
              case 0x43: // clipped bitmap fill with hard edges
                if (fill_style->bitmap.bitmap_ref == from_cid) {
                    fill_style->bitmap.bitmap_ref = to_cid;
                    if (tag->data) {
                        // content modified so delete original data
                        free(tag->data);
                        tag->data = NULL;
                    }
                    return 0; // success!
                }
                break;
              default:
                break;
            }
        }
        // search new style
        for ( ; shape_records ; shape_records = shape_records->next) {
            if ((shape_records->first_6bits) && 
                ((shape_records->first_6bits & 0x20) == 0)) {
                if (shape_records->shape.shape_setup.shape_has_new_styles) {
                    styles = &(shape_records->shape.shape_setup.styles);
                    break;
                }
            }
        }
        shape_records = _swf_tag_shape_search_new_style_in_shape_records(shape_records);

        if (shape_records) {
            styles = &(shape_records->shape.shape_setup.styles);
            shape_records = shape_records->next; // next
        } else {
            morph_shape_check = 0;
            if (morph_shape_check) {        
                shape_records = &(swf_tag_shape->morph_shape_with_style.shape_records);
                shape_records = _swf_tag_shape_search_new_style_in_shape_records(shape_records);
                if (shape_records) {
                    styles = &(shape_records->shape.shape_setup.styles);
                    morph_shape_check = 0;
                } else {
                    break; // finish
                }
            } else {
                break; // finish
            }
        }
    }
    return 1; // not found
}

unsigned char *
swf_tag_shape_output_detail(swf_tag_t *tag, unsigned long *length,
                           struct swf_object_ *swf) {
    swf_tag_shape_detail_t *swf_tag_shape = (swf_tag_shape_detail_t *) tag->detail;
    bitstream_t *bs;
    unsigned char *data;
    int ret;
    long offset_of_offset_morph = 0;
    long tmp_offset_byte = 0;
    long tmp_offset_bit = 0;
    (void) swf;
    *length = 0;
    // build context
    swf_tag_shape->_current_fill_style_num = 0;
    swf_tag_shape->_current_line_style_num = 0;
    swf_tag_shape->_current_x = 0;
    swf_tag_shape->_current_y = 0;

    //
    bs = bitstream_open();
    bitstream_putbytesLE(bs, swf_tag_shape->shape_id, 2);
    swf_rect_build(bs, &(swf_tag_shape->rect));
    
    // DefineMorphShape, DefineMorphShape2
    swf_tag_shape->is_morph = (tag->code == 46) || (tag->code == 84);
    // DefineShape4, DefineMorphShape2
    swf_tag_shape->has_strokes = (tag->code == 83) || (tag->code == 84);
    
    if (swf_tag_shape->is_morph) {
        ret = swf_rect_build(bs, &(swf_tag_shape->rect_morph));
        if (ret) {
            fprintf(stderr, "ERROR: swf_tag_shape_output_detail: swf_tag_shape->rect_morph build failed\n");
            bitstream_close(bs);
            return NULL;
        }
    }
    if (swf_tag_shape->has_strokes) {
        ret = swf_rect_build(bs, &(swf_tag_shape->stroke_rect));
        if (ret) {
            fprintf(stderr, "ERROR: swf_tag_shape_input_detail: swf_tag_shape->stroke_rect build failed\n");
            bitstream_close(bs);
            return NULL;
        }
        if (swf_tag_shape->is_morph) {
            ret = swf_rect_build(bs, &(swf_tag_shape->stroke_rect_morph));
            if (ret) {
                fprintf(stderr, "ERROR: swf_tag_shape_input_detail: swf_tag_shape->stroke_rect_morph build failed\n");
                bitstream_close(bs);
                return NULL;
            }
        }
        bitstream_putbits(bs, 6, swf_tag_shape->define_shape_reserved );
        bitstream_putbits(bs, 1, swf_tag_shape->define_shape_non_scaling_strokes );
        bitstream_putbits(bs, 1, swf_tag_shape->define_shape_scaling_strokes);
    }
    if (swf_tag_shape->is_morph) {
        bitstream_align(bs);
        // memory offset for overwrite this value after.
        offset_of_offset_morph = bitstream_getbytepos(bs);
        bitstream_putbytesLE(bs, swf_tag_shape->offset_morph, 4);
        swf_morph_shape_with_style_build(bs, &swf_tag_shape->morph_shape_with_style, tag);
        // rewind to overwrite offset_morph field and overwrite it.
        // offset distance from offset_morph so -4 operation
        swf_tag_shape->offset_morph = swf_tag_shape->morph_shape_with_style.offset_of_end_edges - offset_of_offset_morph - 4;
        tmp_offset_byte = bitstream_getbytepos(bs); // save offset
        tmp_offset_bit = bitstream_getbitpos(bs);
        bitstream_setpos(bs, offset_of_offset_morph, 0);
        bitstream_putbytesLE(bs, swf_tag_shape->offset_morph , 4);
        bitstream_setpos(bs, tmp_offset_byte, tmp_offset_bit); // restore offset
    } else {
        ret = swf_shape_with_style_build(bs, &swf_tag_shape->shape_with_style, tag);
        if (ret) {
            fprintf(stderr, "swf_tag_shape_output_detail: swf_shape_with_style_build failed\n");
            bitstream_close(bs);
            return NULL;
        }
    }
    
    data = bitstream_steal(bs, length);
    bitstream_close(bs);
    return data;
}

void
swf_tag_shape_print_detail(swf_tag_t *tag,
                           struct swf_object_ *swf, int indent_depth) {
    swf_tag_shape_detail_t *swf_tag_shape = (swf_tag_shape_detail_t *) tag->detail;
    (void) swf;
    print_indent(indent_depth);
    printf("shape_id=%d\n", swf_tag_shape->shape_id);
    swf_rect_print(&(swf_tag_shape->rect), indent_depth);
//    print_indent(indent_depth);
//    printf("is_morph=%d has_strokes=%d\n",
//           swf_tag_shape->is_morph, swf_tag_shape->has_strokes);
    if (swf_tag_shape->is_morph) {
        swf_rect_print(&(swf_tag_shape->rect_morph), indent_depth);
    }
    if (swf_tag_shape->has_strokes) {
        swf_rect_print(&(swf_tag_shape->stroke_rect), indent_depth);
        if (swf_tag_shape->is_morph) {
            swf_rect_print(&(swf_tag_shape->stroke_rect_morph), indent_depth);
        }
        print_indent(indent_depth);
        printf("define_shape_non_scaling_strokes=%d define_shape_scaling_strokes=%d\n",
               swf_tag_shape->define_shape_non_scaling_strokes,
               swf_tag_shape->define_shape_scaling_strokes);
    }
    if (swf_tag_shape->is_morph) {
        print_indent(indent_depth);
        printf("offset_morph=%lu\n", swf_tag_shape->offset_morph);
        swf_morph_shape_with_style_print(&swf_tag_shape->morph_shape_with_style,
                                         indent_depth, tag);
    } else {
        swf_shape_with_style_print(&swf_tag_shape->shape_with_style,
                                   indent_depth, tag);
    }
    return ;
}

void
swf_tag_shape_destroy_detail(swf_tag_t *tag) {
    swf_tag_shape_detail_t *swf_tag_shape = (swf_tag_shape_detail_t *) tag->detail;
    if (swf_tag_shape) {
        swf_morph_shape_with_style_delete(&(swf_tag_shape->morph_shape_with_style));
        swf_shape_with_style_delete(&(swf_tag_shape->shape_with_style));
        free(swf_tag_shape);
        tag->detail = NULL;
    }
    return ;
}

int
swf_tag_shape_apply_matrix_factor(void *detail, int shape_id, int bitmap_id,
                                  double scale_x, double scale_y,
                                  double rotate_rad,
                                  signed int trans_x,
                                  signed int trans_y) {
    int i;
    swf_tag_shape_detail_t *swf_tag_shape = (swf_tag_shape_detail_t *) detail;
    swf_fill_style_array_t *fill_styles;
    swf_fill_style_t *fill_style;
    swf_shape_record_t *shape_record = NULL;

    if (detail == NULL) {
        fprintf(stderr, "swf_tag_shape_apply_matrix_factor: detail == NULL\n");
        return 1;
    }
    if (shape_id != swf_tag_shape->shape_id) {
        return 1;
    }
    fill_styles = &(swf_tag_shape->shape_with_style.styles.fill_styles);

    if (! swf_tag_shape->is_morph) {
        shape_record = &(swf_tag_shape->shape_with_style.shape_records);
    }

    while (fill_styles) {
        for (i = 0 ; i < fill_styles->count ; i++) {
            fill_style = &(fill_styles->fill_style[i]);
            switch (fill_style->type) {
            case 0x10: // linear gradient fill
            case 0x12: // radial gradient fill
            case 0x13: // focal  gradient fill
                if (bitmap_id < 0) {
                    swf_matrix_apply_factor(&(fill_style->gradient.gradient_matrix), scale_x, scale_y,
                                            rotate_rad, trans_x, trans_y);
                }
                break;
            case 0x40: // tilled  bitmap fill with smoothed edges
            case 0x41: // clipped bitmap fill with smoothed edges
            case 0x42: // tilled  bitmap fill with hard edges
            case 0x43: // clipped bitmap fill with hard edges
                if ((bitmap_id < 0) ||
                    (bitmap_id == fill_style->bitmap.bitmap_ref)) {
                    swf_matrix_apply_factor(&(fill_style->bitmap.bitmap_matrix),
                                            scale_x, scale_y, rotate_rad,
                                            trans_x, trans_y);
                }
                break;
            case 0x00: // solid
                // nothing to do
                break;
            default:
                fprintf(stderr, "swf_tag_shape_apply_matrix_factor: unknown fill_style->type=%d\n",
                        fill_style->type);
                return 1;
            }
        }
        fill_styles = NULL;
        while (shape_record) {
            int first_bit = (shape_record->first_6bits >> 5) & 1;
            int next_5bits = shape_record->first_6bits & 0x1f;
            if (first_bit == 0) {
                if ((next_5bits == 0)) { // end record
                    shape_record = NULL;
                    break; // end
                } else { // setup record
                    if (shape_record->shape.shape_setup.shape_has_new_styles) {
                        fill_styles = &(shape_record->shape.shape_setup.styles.fill_styles);
                        shape_record = shape_record->next;
                        break; // next loop
                    }
                    shape_record = shape_record->next;
                }
            } else { // edge record
                shape_record = shape_record->next;
            }
        }
    }
    return 0;
}

int
swf_tag_shape_apply_rect_factor(void *detail, int shape_id, int bitmap_id,
                                double scale_x, double scale_y,
                                signed int trans_x,
                                signed int trans_y) {
//    int i;
    swf_tag_shape_detail_t *swf_tag_shape = (swf_tag_shape_detail_t *) detail;
    if (detail == NULL) {
        fprintf(stderr, "swf_tag_shape_apply_rect_factor: detail == NULL\n");
        return 1;
    }
    if (shape_id != swf_tag_shape->shape_id) {
        return 1;
    }
    // XXX: fix me.
    swf_rect_apply_factor(&(swf_tag_shape->rect),
                          scale_x, scale_y, trans_x, trans_y);
    // TODO: bitmap_ref check
    swf_shape_record_edge_apply_factor(&(swf_tag_shape->shape_with_style.shape_records),
                                       scale_x, scale_y, trans_x, trans_y);
    return 0;
}

int
swf_tag_shape_apply_type_tilled(void *detail, int shape_id, int bitmap_id) {
    int i;
    swf_tag_shape_detail_t *swf_tag_shape = (swf_tag_shape_detail_t *) detail;
    swf_fill_style_array_t *fill_styles;
    swf_shape_record_t *shape_record = NULL;

    if (detail == NULL) {
        fprintf(stderr, "swf_tag_shape_apply_type_tilled: detail == NULL\n");
        return 1;
    }
    if (shape_id != swf_tag_shape->shape_id) {
        fprintf(stderr, "swf_tag_shape_apply_type_tilled: shape_id(%d) != shape->shape_id(%d)\n",
	      shape_id, swf_tag_shape->shape_id);
        return 1;
    }

    fill_styles = &(swf_tag_shape->shape_with_style.styles.fill_styles);

    if (! swf_tag_shape->is_morph) {
        shape_record = &(swf_tag_shape->shape_with_style.shape_records);
    }

    while (fill_styles) {
        for (i = 0 ; i < fill_styles->count; i++) {
            swf_fill_style_t *fill_style = &(fill_styles->fill_style[i]);
            switch (fill_style->type) {
            case 0x41: // clipped bitmap fill with smoothed edges
                if ((bitmap_id < 0) || (bitmap_id == fill_style->bitmap.bitmap_ref)) {
                    fill_style->type = 0x40; // tilled  bitmap fill with smoothed edges
                }
                break;
            case 0x43: // clipped bitmap fill with hard edges
                if ((bitmap_id < 0) || (bitmap_id == fill_style->bitmap.bitmap_ref)) {
                    fill_style->type = 0x42; // tilled  bitmap fill with hard edges
                }
                break;
            }
        }
        fill_styles = NULL;
        while (shape_record) {
            int first_bit = (shape_record->first_6bits >> 5) & 1;
            int next_5bits = shape_record->first_6bits & 0x1f;
            if (first_bit == 0) {
                if ((next_5bits == 0)) { // end record
                    shape_record = NULL;
                    break; // end
                } else { // setup record
                    if (shape_record->shape.shape_setup.shape_has_new_styles) {
                        fill_styles = &(shape_record->shape.shape_setup.styles.fill_styles);
                        shape_record = shape_record->next;
                        break; // next loop
                    }
                    shape_record = shape_record->next;
                }
            } else { // edge record
                shape_record = shape_record->next;
            }
        }
    }
    return 0;
}

