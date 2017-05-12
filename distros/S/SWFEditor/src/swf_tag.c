/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#include <stdio.h>
#include <stdlib.h>
#include "bitstream.h"
#include "swf_define.h"
#include "swf_tag.h"
#include "swf_tag_jpeg.h"
#include "swf_tag_lossless.h"
#include "swf_tag_edit.h"
#include "swf_tag_action.h"
#include "swf_tag_sound.h"
#include "swf_tag_sprite.h"
#include "swf_tag_shape.h"
#include "swf_tag_place.h"
#include "swf_tag_button.h"
#include "bitmap_util.h"

swf_tag_info_t swf_tag_info_table[] = {
    { 0, "End", NULL },
    { 1, "ShowFrame", NULL },
    { 2, "DefineShape", swf_tag_shape_detail_handler },
    { 3, "FreeCharacter", NULL},
    { 4, "PlaceObject", swf_tag_place_detail_handler },
    { 5, "RemoveObject", NULL},
    { 6, "DefineBitsJPEG", swf_tag_jpeg_detail_handler },
    { 7, "DefineButton", swf_tag_button_detail_handler},
    { 8, "JPEGTables", swf_tag_jpegt_detail_handler },
    { 9, "SetBackgroundColor", NULL },
    { 10, "DefineFont", NULL},
    { 11, "DefineText", NULL },
    { 12, "DoAction", swf_tag_action_detail_handler },
    { 13, "DefineFontInfo", NULL },
    { 14, "DefineSound", swf_tag_sound_detail_handler },
    { 15, "StartSound", NULL },
    // 16 missing
    { 17, "DefineButtonSound", NULL },
    { 18, "SoundStreamHead", NULL },
    { 19, "SoundStreamBlock", NULL },
    { 20, "DefineBitsLossless", swf_tag_lossless_detail_handler },
    { 21, "DefineBitsJPEG2", swf_tag_jpeg_detail_handler },
    { 22, "DefineShape2", swf_tag_shape_detail_handler },
    { 24, "Protect", NULL },
    { 26, "PlaceObject2", swf_tag_place_detail_handler },
    { 28, "RemoveObject2", NULL },
    { 32, "DefineShape3", swf_tag_shape_detail_handler },
    { 33, "DefineText2", NULL },
    { 34, "DefineButton2", swf_tag_button_detail_handler },
    { 35, "DefineBitsJPEG3", swf_tag_jpeg3_detail_handler },
    { 36, "DefineBitsLossless2", swf_tag_lossless_detail_handler },
    { 37, "DefineEditText", swf_tag_edit_detail_handler },
    { 39, "DefineSprite", swf_tag_sprite_detail_handler },
    { 43, "FrameLabel", NULL } ,
    { 46, "DefineMorphShape", swf_tag_shape_detail_handler },
    { 48, "DefineFont2", NULL } ,
    { 56, "Export", NULL } ,
    { 59, "DoInitAction", swf_tag_action_detail_handler },
    { 69, "FileAttributes", NULL },
    { 73, "DefineFontAlignZones", NULL },
    { 74, "CSMTextSettings", NULL },
    { 75, "DefineFont3", NULL } ,
    { 83, "DefineShape4",  swf_tag_shape_cid_handler },
    { 84, "DefineMorphShape2", swf_tag_shape_cid_handler },
    { 88, "DefineFontName", NULL } ,
    { 777,"Reflex", NULL } ,
};

swf_tag_info_t *get_swf_tag_info(int tag_id) {
    int i, tag_info_num = NumOfTable(swf_tag_info_table);
    for (i=0 ; i < tag_info_num ; i++) {
        if (tag_id == swf_tag_info_table[i].id) {
            return &(swf_tag_info_table[i]);
        }
    }
    return NULL;
}

swf_tag_t *swf_tag_create(bitstream_t *bs) {
    swf_tag_t *tag = NULL;
    unsigned short tag_and_length;
    if (bs == NULL) {
        fprintf(stderr, "swf_tag_create: bs == NULL\n");
        return NULL;
    }
    tag_and_length = bitstream_getbytesLE(bs, 2);
    if (tag_and_length == (unsigned short) -1) {
        fprintf(stderr, "swf_tag_create: tag_and_length(short) == -1\n");
        return NULL;
    }
    tag = calloc(sizeof(*tag), 1);
    tag->code = tag_and_length >> 6;
    tag->length = tag_and_length & 0x3f;
    tag->length_longformat = 0;
    if (tag->length == 0x3f) {
        tag->length = bitstream_getbytesLE(bs, 4);
        if (tag_and_length == (unsigned short) -1) {
	    fprintf(stderr, "swf_tag_create: tag_and_length(long) == -1\n");
            free(tag);
            return NULL;
        }
        tag->length_longformat = 1;
    }
//    printf("XXX: malloc length=%d\n", tag->length);
    tag->data = malloc(tag->length);
    bitstream_getstring(bs, tag->data, tag->length);
    tag->detail = NULL;
    return tag;
}

void swf_tag_destroy(swf_tag_t *tag) {
    if (tag == NULL) {
        return;
    }
    if (tag->data) {
        free(tag->data);
        tag->data = NULL;
    }
    if (tag->detail) {
        swf_tag_destroy_detail(tag);
	tag->detail = NULL;
    }
    free(tag);
}

static int swf_tag_and_length_build(bitstream_t *bs, swf_tag_t *tag) {
    signed short tag_and_length;
    if (bs == NULL) {
        fprintf(stderr, "swf_tag_and_length_build: bs == NULL\n");
        return 1;
    }
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_and_length_build: tag == NULL\n");
        return 1;
    }
    if (tag->length >= 0x3f) {
        tag->length_longformat = 1;
    } else {
        switch (tag->code) {
          case 6:  // DefineBitsJPEG
          case 21: // DefineBitsJPEG2
          case 35: // DefineBitsJPEG3
          case 20: // DefineBitsLossless
          case 36: // DefineBitsLossless2
          case 19: // SoundStreamBlock
            tag->length_longformat = 1;
            break;
          default:
            tag->length_longformat = 0;
            break;
        }
    }
    if (tag->length_longformat) {
        tag_and_length = (tag->code << 6) | 0x3f;
        bitstream_putbytesLE(bs, tag_and_length, 2);
        bitstream_putbytesLE(bs, tag->length, 4);
    } else {
        tag_and_length = (tag->code << 6) | tag->length;
        bitstream_putbytesLE(bs, tag_and_length, 2);
    }
    return 0;
}

int swf_tag_build(bitstream_t *bs, swf_tag_t *tag, struct swf_object_ *swf) {
    swf_tag_info_t *tag_info = NULL;
    unsigned char *data = NULL;
    unsigned long data_len = 0;
    swf_tag_detail_handler_t *detail_handler = NULL;
    if (bs == NULL) {
        fprintf(stderr, "swf_tag_build: bs == NULL\n");
        return 1;
    }
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_build: tag == NULL\n");
        return 1;
    }
//    fprintf(stderr, "XXX: swf_tag_build: tag->code=%d\n",tag->code);
    if (tag->data) {
        swf_tag_and_length_build(bs, tag);
        bitstream_putstring(bs, tag->data, tag->length);
    } else if (tag->detail) {
        tag_info = get_swf_tag_info(tag->code);
        if ((tag_info == NULL) || (tag_info->detail_handler == NULL)) {
            fprintf(stderr, "swf_tag_build: not implemented yet. detail build tag->code=%d\n",
                tag->code);
            return 1;
        }
        detail_handler = tag_info->detail_handler();
        if (detail_handler->output == NULL) {
            fprintf(stderr, "swf_tag_build: detail_handler->output == NULL: tag->code=%d\n",
                    tag->code);
            return 1;
        }
        data = detail_handler->output(tag, &data_len, swf);
        if (data == NULL) {
            fprintf(stderr, "swf_tag_build: Can't output: data=%p data_len=%lu\n",
                    data, data_len);
        }
        tag->length = data_len;
        swf_tag_and_length_build(bs, tag);
        bitstream_putstring(bs, data, data_len);
        free(data);
    } else {
        fprintf(stderr, "ERROR: not found tag data and detail\n");
        return 1;
    }
    return 0;
}

int
swf_tag_rebuild(swf_tag_t *tag, struct swf_object_ *swf) {
    swf_tag_info_t *tag_info = NULL;
    swf_tag_detail_handler_t * detail_handler = NULL;
    void *detail;
    tag_info = get_swf_tag_info(tag->code);
    if ((tag_info == NULL) || (tag_info->detail_handler == NULL)) {
        return 0; // no info
    }
    detail_handler = tag_info->detail_handler();
    if (detail_handler == NULL) {
        return 0; // no detail handler
    }
    if ((detail_handler->input == NULL) || (detail_handler->output == NULL)) {
        return 0; // no input or output handler
    }
    detail = swf_tag_create_input_detail(tag, swf);
    if (detail == NULL) {
        fprintf(stderr, "swf_tag_rebuild: swf_tag_create_input_detail failed tag->code=%d\n", tag->code);
        return 1;
    }
    free(tag->data);
    tag->data = NULL;
    return 0;
}


void
swf_tag_print(swf_tag_t *tag, struct swf_object_ *swf, int indent_depth) {
    swf_tag_info_t *tag_info = NULL;
    const char *tag_name = NULL;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_print: tag == NULL\n");
        return ;
    }
    tag_info = get_swf_tag_info(tag->code);
    tag_name = (tag_info)?tag_info->name:"Unknown";
//  print_indent(indent_depth);
    printf("tag=%s(%d)", tag_name, tag->code);
    if (tag->length > 0) {
        printf("  length=%lu",  tag->length);
    }
    printf("\n");
    if (tag_info && tag_info->detail_handler) {
        swf_tag_detail_handler_t * detail_handler;
        if (swf_tag_create_input_detail(tag, swf) == NULL) {
            fprintf(stderr, "swf_tag_print: swf_tag_create_input_detail failed\n");
            return ;
        }
        detail_handler = tag_info->detail_handler();
        if (detail_handler->print) {
            detail_handler->print(tag, swf, indent_depth + 1);
        }
    }
}

void *swf_tag_create_input_detail(swf_tag_t *tag, struct swf_object_ *swf) {
    swf_tag_info_t *tag_info = NULL;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_create_input_detail: tag == NULL\n");
        return NULL;
    }
    if (tag->detail) {
        return tag->detail;
    }
    tag_info = get_swf_tag_info(tag->code);
    if (tag_info && tag_info->detail_handler) {
        int result;
        swf_tag_detail_handler_t * detail_handler = tag_info->detail_handler();
        if (detail_handler->create == NULL) {
            fprintf(stderr, "swf_tag_create_input_detail: detail_handler->create == NULL (tag=%d)\n",
                    tag->code);
            return NULL;
        }
        tag->detail = detail_handler->create();
        if (tag->detail == NULL) {
            fprintf(stderr, "swf_tag_create_input_detail: can't create tag detail (tag=%d)\n", tag->code);
            return NULL;
        }
        result = detail_handler->input(tag, swf);
        if (result) {
            fprintf(stderr, "swf_tag_create_input_detail: can't input tag detail (result=%d)\n", result);
            return NULL;
        }
    } else {
        fprintf(stderr, "swf_tag_create_input_detail: tag_info or detail_handler  == NULL\n");
    }
    if (tag->detail == NULL) {
        fprintf(stderr, "swf_tag_create_input_detail: function tail but tag->detail == NULL (tag->code=%d)\n", tag->code);
    }
    return tag->detail;
}

void swf_tag_destroy_detail(swf_tag_t *tag) {
    if (tag == NULL) {
        return;
    }
    if (tag->detail) {
        swf_tag_info_t *tag_info = get_swf_tag_info(tag->code);
        if (tag_info && tag_info->detail_handler) {
            swf_tag_detail_handler_t * detail_handler = tag_info->detail_handler();
            if (detail_handler->destroy) {
                detail_handler->destroy(tag);
            } else {
	        fprintf(stderr, "detail_handler->destroy == NULL (tag=%d)\n",
                        tag->code);
            }
        } else {
	    fprintf(stderr, "not impremented yet. destroy tag detail\n");
        }
	tag->detail = NULL;
    }
}


int
swf_tag_get_cid(swf_tag_t *tag) {
    swf_tag_info_t *tag_info = NULL;
    int tag_no;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_get_cid: tag == NULL\n");
        return 1;
    }
    tag_no = tag->code;
    if (tag->data) {
        switch (tag_no) {
          case 7:  // DefineButton
          case 10: // DefineFont
          case 11: // DefineText
          case 13: // DefineFontInfo
          case 14: // DefineSound
          case 17: // DefineButtonSound
          case 33: // DefineText2
          case 34: // DefineButton2
          case 39: // DefineSprite
          case 46: // DefineMorphShape
          case 48: // DefineFont2
          case 88: // DefineFontName
              return GetUShortLE(tag->data);
              break;
        }
    }
    tag_info = get_swf_tag_info(tag_no);
    if (tag_info && tag_info->detail_handler) {
        swf_tag_detail_handler_t * detail_handler = tag_info->detail_handler();
        if (detail_handler->get_cid) {
            return detail_handler->get_cid(tag);
        }
    }
    return -1; // no cid tag
}

int
swf_tag_replace_cid(swf_tag_t *tag, int cid) {
    swf_tag_info_t *tag_info;
    int tag_no;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_replace_cid: tag == NULL\n");
        return 1; // failure
    }
    tag_no = tag->code;
    tag_info = get_swf_tag_info(tag_no);
    if (tag_info && tag_info->detail_handler) {
        swf_tag_detail_handler_t * detail_handler = tag_info->detail_handler();
        if (detail_handler->replace_cid) {
            return detail_handler->replace_cid(tag, cid);
        }
    } else {
        switch (tag_no) {
          case 7:  // DefineButton
          case 10: // DefineFont
          case 11: // DefineText
          case 13: // DefineFontInfo
          case 14: // DefineSound
          case 17: // DefineButtonSound
          case 33: // DefineText2
          case 34: // DefineButton2
          case 39: // DefineSprite
          case 46: // DefineMorphShape
          case 48: // DefineFont2
          case 88: // DefineFontName
            if (tag->data) {
                PutUShortLE(tag->data, cid);
                return 0;
            }
            break;
          default:
              ;
        }
    }
    return 1; // no cid tag
}

int
swf_tag_get_refcid(swf_tag_t *tag) {
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_get_refcid: tag == NULL\n");
        return -1;
    }
    if (isPlaceTag(tag->code)) { // PlaceObject, PlaceObject2
        swf_tag_place_detail_t *swf_tag_place;
        swf_tag_place = swf_tag_create_input_detail(tag, NULL);
        if (swf_tag_place == NULL) {
            fprintf(stderr, "swf_tag_get_refcid: swf_tag_place swf_tag_create_input_detail failed\n");
            return -1;
        }
        return swf_tag_place->character_id;
    } else if (tag->code == 37) { // DefineEditText
        swf_tag_edit_detail_t *swf_tag_edit;
        swf_tag_edit = swf_tag_create_input_detail(tag, NULL);
        if (swf_tag_edit == NULL) {
            fprintf(stderr, "swf_tag_get_refcid: swf_tag_edit swf_tag_create_input_detail failed\n");
            return -1;
        }
        return swf_tag_edit->edit_font_id_ref;
    }
    return -1; // no cid tag
}

int
swf_tag_replace_refcid(swf_tag_t *tag, int cid) {
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_replace_refcid: tag == NULL\n");
        return 1; // failure
    }
    if (isPlaceTag(tag->code)) { // PlaceObject, PlaceObject2
        swf_tag_place_detail_t *swf_tag_place;
        swf_tag_place = swf_tag_create_input_detail(tag, NULL);
        if (swf_tag_place == NULL) {
            fprintf(stderr, "swf_tag_replace_refcid: swf_tag_place swf_tag_create_input_detail failed\n");
            return 1; // failure
        }
        swf_tag_place->character_id = cid;
    } else if (tag->code == 37) { // DefineEditText
        swf_tag_edit_detail_t *swf_tag_edit;
        swf_tag_edit = swf_tag_create_input_detail(tag, NULL);
        if (swf_tag_edit == NULL) {
            fprintf(stderr, "swf_tag_get_refcid: swf_tag_edit swf_tag_create_input_detail failed\n");
            return -1;
        }
        swf_tag_edit->edit_font_id_ref = cid;
    }
    if (tag->data) {
        free(tag->data);
        tag->data = NULL;
    }
    return 0; // success
}

/*
 * bitmap tag
 */

int
swf_tag_get_bitmap_size(swf_tag_t *tag,
                        int *width, int *height) {
    int ret = 0;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_get_bitmap_size: tag == NULL\n");
        return 1;
    }
    if ((width == NULL ) || (height == NULL)) {
        fprintf(stderr, "swf_tag_get_bitmap_size: width == NULL or height == NULL\n");
        return 1;
    }
    if (isBitsJPEGTag(tag->code)) {
        swf_tag_jpeg_detail_t *swf_tag_jpeg;
        if (swf_tag_create_input_detail(tag, NULL) == NULL) {
            fprintf(stderr, "swf_tag_get_bitmap_size: swf_tag_create_input_detail failed\n");
            return 1;
        }
        swf_tag_jpeg = (swf_tag_jpeg_detail_t *) tag->detail;
        ret = jpeg_size(swf_tag_jpeg->jpeg_data, swf_tag_jpeg->jpeg_data_len,
                        width, height);
    } else if (isBitsLosslessTag(tag->code)) {
        if (tag->detail) {
            swf_tag_lossless_detail_t *swf_tag_lossless = (swf_tag_lossless_detail_t *) tag->detail;
            *width  = swf_tag_lossless->width;
            *height = swf_tag_lossless->height;
        } else {
            *width  = GetUShortLE((tag->data + 3));
            *height = GetUShortLE((tag->data + 5));
        }
    } else { // no Bitmap Tag
        return 1;
    }
    return ret;
}

int
swf_tag_get_bitmap_color1stpixel(swf_tag_t *tag,
                                 int *red, int *green, int *blue) {
    swf_tag_lossless_detail_t *swf_tag_lossless = NULL;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_get_bitmap_color1stpixel: tag == NULL\n");
        return 1;
    }
    if ((red == NULL ) || (green == NULL) || (blue == NULL)) {
        fprintf(stderr, "swf_tag_get_bitmap_color1stpixel: width == NULL or height == NULL\n");
        return 1;
    }
    if (swf_tag_create_input_detail(tag, NULL) == NULL) {
        fprintf(stderr, "swf_tag_get_bitmap_color1stpixel: swf_tag_create_input_detail failed\n");
        return 1;
    }
    if (isBitsLosslessTag(tag->code) == 0) {
        return 1; // No Lossless Tag;
    }
    swf_tag_lossless = (swf_tag_lossless_detail_t *) tag->detail;

    // get first 1 pixel RGB value. by format and tag_code.
    switch (swf_tag_lossless->format) {
        int color_index;
    case 3:
        color_index = swf_tag_lossless->indices[0];
        if (tag->code == 20) { // Lossless => RGB
            *red   = swf_tag_lossless->colormap[color_index].red;
            *green = swf_tag_lossless->colormap[color_index].green;
            *blue  = swf_tag_lossless->colormap[color_index].blue;
        } else { // Lossless2 => RGBA
            int alpha = swf_tag_lossless->colormap2[color_index].alpha;
            if (alpha == 0) {
                *red   = swf_tag_lossless->colormap2[color_index].red;
                *green = swf_tag_lossless->colormap2[color_index].green;
                *blue  = swf_tag_lossless->colormap2[color_index].blue;
            }
            else {
                *red   = swf_tag_lossless->colormap2[color_index].red * 255 / alpha;
                *green = swf_tag_lossless->colormap2[color_index].green * 255 / alpha;
                *blue  = swf_tag_lossless->colormap2[color_index].blue * 255 / alpha;
            }
        }
        break;
    case 5:
        if (tag->code == 20) { // Lossless => RGB
            *red   = swf_tag_lossless->bitmap[0].red;
            *green = swf_tag_lossless->bitmap[0].green;
            *blue  = swf_tag_lossless->bitmap[0].blue;
        } else { // Lossless2 => ARGB
            int alpha = swf_tag_lossless->bitmap2[0].alpha;
            if (alpha == 0) {
                *red   = swf_tag_lossless->bitmap2[0].red;
                *green = swf_tag_lossless->bitmap2[0].green;
                *blue  = swf_tag_lossless->bitmap2[0].blue;
            }
            else {
                *red   = swf_tag_lossless->bitmap2[0].red * 255 / alpha;
                *green = swf_tag_lossless->bitmap2[0].green * 255 / alpha;
                *blue  = swf_tag_lossless->bitmap2[0].blue * 255 / alpha;
            }
        }
        break;
    default: // include 4 (15bit color)
        fprintf(stderr, "swf_tag_get_bitmap_color1stpixel: unacceptable format=(%d)\n", swf_tag_lossless->format);
        return 1;
    }
    return 0; // SUCCESS
}

unsigned char *
swf_tag_get_jpeg_data(swf_tag_t *tag, unsigned long *length, int image_id, swf_tag_t *tag_jpegtables) {
    swf_tag_info_t *tag_info = NULL;
    *length = 0;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_get_jpeg_data: tag == NULL\n");
        return NULL;
    }
    if (length == NULL) {
        fprintf(stderr, "swf_tag_get_jpeg_data: length == NULL\n");
        return NULL;
    }
    tag_info = get_swf_tag_info(tag->code);
    if ((tag->code != 6) && (tag->code != 21) && (tag->code != 35)) {
        return NULL;
    }
    if (swf_tag_create_input_detail(tag, NULL) == NULL) {
        fprintf(stderr, "swf_tag_get_jpeg_data: swf_tag_create_input_detail failed\n");
        return NULL;
    }
    if (tag_jpegtables) {
        return swf_tag_jpeg_get_jpeg_data(tag->detail, length, image_id,
                                          tag_jpegtables->data,
                                          tag_jpegtables->length);
    } else {
        return swf_tag_jpeg_get_jpeg_data(tag->detail, length, image_id,
                                          NULL, 0);
    }
}

unsigned char *
swf_tag_get_alpha_data(swf_tag_t *tag, unsigned long *length, int image_id) {
    *length = 0;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_get_alpha_data: tag == NULL\n");
        return NULL;
    }
    if (length == NULL) {
        fprintf(stderr, "swf_tag_get_alpha_data: length == NULL\n");
        return NULL;
    }
    if (tag->code != 35) { // ! DefineBitsJPEG3
        return NULL;
    }
    if (swf_tag_get_cid(tag) != image_id) {
        return NULL;
    }
    if (swf_tag_create_input_detail(tag, NULL) == NULL) {
        fprintf(stderr, "swf_tag_get_alpha_data: swf_tag_create_input_detail failed\n");
        return NULL;
    }
    return swf_tag_jpeg_get_alpha_data(tag->detail, length, image_id);
}

int
swf_tag_replace_jpeg_data(swf_tag_t *tag, int image_id,
                          unsigned char *jpeg_data,
                          unsigned long jpeg_data_len,
                          unsigned char *alpha_data,
                          unsigned long alpha_data_len,
                          int without_converting) {
    swf_tag_info_t *tag_info = NULL;
    swf_tag_detail_handler_t * detail_handler = NULL;
    int result;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_replace_jpeg_data: tag == NULL\n");
        return 1;
    }
    if (jpeg_data == NULL) {
        fprintf(stderr, "swf_tag_replace_jpeg_data: jpeg_data == NULL\n");
        return 1;
    }
    if (! isBitmapTag(tag->code)) {
        return 1;
    }
    tag_info = get_swf_tag_info(tag->code); // Bitmap Tag
    detail_handler = tag_info->detail_handler();
    if (detail_handler->get_cid(tag) !=  image_id) {
        return 1;
    }

    if (tag->detail && (! isBitsJPEGTag(tag->code))) {
        detail_handler->destroy(tag);
        tag->detail = NULL;
    }
    if (alpha_data && (alpha_data_len > 0)) {
        tag->code = 35; // DefineBitsJPEG3
    } else {
        tag->code = 21; // DefineBitsJPEG2
    }
    
    tag_info = get_swf_tag_info(tag->code); // JPEG Tag
    detail_handler = tag_info->detail_handler();
    if (tag->detail == NULL) {
        tag->detail = detail_handler->create();
    }

    if (without_converting) {
        result= swf_tag_jpeg_replace_bitmap_data(tag->detail, image_id,
                                                 jpeg_data, jpeg_data_len,
                                                 tag);
    } else {
        result= swf_tag_jpeg_replace_jpeg_data(tag->detail, image_id,
                                               jpeg_data, jpeg_data_len,
                                               alpha_data, alpha_data_len, tag);
    }
    if (result == 0) {
        free(tag->data);
        tag->data = NULL;
        tag->length = 0;
    } else {
        detail_handler->destroy(tag);
        tag->detail = NULL;
    } 
    return result;
}


#ifdef HAVE_PNG

unsigned char *
swf_tag_get_png_data(swf_tag_t *tag, unsigned long *length, int image_id) {
    swf_tag_info_t *tag_info = NULL;
    *length = 0;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_get_png_data: tag == NULL\n");
        return NULL;
    }
    if (length == NULL) {
        fprintf(stderr, "swf_tag_get_png_data: length == NULL\n");
        return NULL;
    }
    tag_info = get_swf_tag_info(tag->code);
    if ((tag->code != 20) && (tag->code != 36)) {
        return NULL;
    }
    if (swf_tag_create_input_detail(tag, NULL) == NULL) {
        fprintf(stderr, "swf_tag_get_png_data: swf_tag_create_input_detail failed\n");
        return NULL;
    }
    return swf_tag_lossless_get_png_data(tag->detail, length, image_id, tag);
}

int
swf_tag_replace_png_data(swf_tag_t *tag, int image_id,
                         unsigned char *png_data,
                         unsigned long png_data_len, int rgb15) {
    swf_tag_info_t *tag_info = NULL;
    swf_tag_detail_handler_t *detail_handler = NULL;
    int result;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_replace_png_data: tag == NULL\n");
        return 1;
    }
    if (png_data == NULL) {
        fprintf(stderr, "swf_tag_replace_png_data: png_data == NULL\n");
        return 1;
    }
    if (! isBitmapTag(tag->code)) {
        return 1;
    }
    tag_info = get_swf_tag_info(tag->code); // Bitmap Tag
    detail_handler = tag_info->detail_handler();
    if (detail_handler->get_cid(tag) != image_id) {
        return 1;
    }
    
    if (tag->detail && (! isBitsLosslessTag(tag->code))) {
        detail_handler->destroy(tag);
        tag->detail = NULL;
    }
    if (tag->code == 20) {
        tag->code = 20; // DefineBitsLossless
    } else {
        tag->code = 36; // DefineBitsLossless2
    }
    
    tag_info = get_swf_tag_info(tag->code); // Lossless Tag
    detail_handler = tag_info->detail_handler();
    if (tag->detail == NULL) {
        tag->detail = detail_handler->create();
    }
    
    result= swf_tag_lossless_replace_png_data(tag->detail, image_id,
                                              png_data, png_data_len,
                                              rgb15, tag);
    if (result == 0) {
        free(tag->data);
        tag->data = NULL;
        tag->length = 0;
    } else {
        detail_handler->destroy(tag);
        tag->detail = NULL;
    }
    return result;
}

#endif /* HAVE_PNG */

#ifdef HAVE_GIF

int
swf_tag_replace_gif_data(swf_tag_t *tag, int image_id,
                         unsigned char *gif_data,
                         unsigned long gif_data_len) {
    swf_tag_info_t *tag_info = NULL;
    swf_tag_detail_handler_t *detail_handler = NULL;
    int result;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_replace_gif_data: tag == NULL\n");
        return 1;
    }
    if (gif_data == NULL) {
        fprintf(stderr, "swf_tag_replace_gif_data: gif_data == NULL\n");
        return 1;
    }
    if (! isBitmapTag(tag->code)) {
        return 1;
    }
    tag_info = get_swf_tag_info(tag->code); // Bitmap Tag
    detail_handler = tag_info->detail_handler();
    if (detail_handler->get_cid(tag) != image_id) {
        return 1;
    }
    
    if (tag->detail && (! isBitsLosslessTag(tag->code))) {
        detail_handler->destroy(tag);
        tag->detail = NULL;
    }
    if (tag->code == 20) {
        tag->code = 20; // DefineBitsLossless
    } else {
        tag->code = 36; // DefineBitsLossless2
    }
    
    tag_info = get_swf_tag_info(tag->code); // Lossless Tag
    detail_handler = tag_info->detail_handler();
    if (tag->detail == NULL) {
        tag->detail = detail_handler->create();
    }
    
    result= swf_tag_lossless_replace_gif_data(tag->detail, image_id,
                                              gif_data, gif_data_len, tag);
    if (result == 0) {
        free(tag->data);
        tag->data = NULL;
        tag->length = 0;
    } else {
        detail_handler->destroy(tag);
        tag->detail = NULL;
    }
    return result;
}

#endif /* HAVE_GIF */

int
swf_tag_convert_bitmap_data_tojpegtag(swf_tag_t *tag) {
    int tag_code;
    int image_id;
    unsigned char *bitmap_data;
    unsigned long bitmap_data_len;
    swf_tag_lossless_detail_t *swf_tag_lossless;
    int ret;
    if (tag == NULL) {
        fprintf(stderr, "swf_object_convert_bitmap_data_tojpegtag: tag == NULL\n");
        return 1;
    }
    tag_code = tag->code;
    if ((tag_code != 20) && (tag_code != 36)) {
        return 1;
    }
    if (tag->detail == NULL) {
        swf_tag_lossless = (swf_tag_lossless_detail_t *) swf_tag_create_input_detail(tag, NULL);
    } else {
        swf_tag_lossless = (swf_tag_lossless_detail_t *) tag->detail;
    }
    image_id= swf_tag_lossless->image_id;
    bitmap_data = swf_tag_lossless_get_png_data(swf_tag_lossless, &bitmap_data_len, image_id, tag);
    if (bitmap_data == NULL) {
        fprintf(stderr, "swf_object_convert_bitmap_data_tojpegtag: failed to swf_tag_get_png_data image_id=%d\n", image_id);
        return 1;
    }
    ret = swf_tag_replace_jpeg_data(tag, image_id,
                                    bitmap_data, bitmap_data_len, NULL, 0, 1);
    free(bitmap_data);
    if (ret) {
        fprintf(stderr, "swf_object_convert_bitmap_data_tojpegtag: failed to swf_tag_replace_jpeg_data image_id=%d\n", image_id);
        return ret;
    }
    return 0;
}

/*
 * DefineSound
 */

unsigned char *
swf_tag_get_sound_data(swf_tag_t *tag, unsigned long *length, int sound_id) {
    swf_tag_info_t *tag_info = NULL;
    *length = 0;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_get_sound_data: tag == NULL\n");
        return NULL;
    }
    if (length == NULL) {
        fprintf(stderr, "swf_tag_get_sound_data: length == NULL\n");
        return NULL;
    }
    tag_info = get_swf_tag_info(tag->code);
    if (tag->code != 14) { // DefineSound
        return NULL;
    }
    if (! tag->detail) {
        
    }
    if (swf_tag_create_input_detail(tag, NULL) == NULL) {
        fprintf(stderr, "swf_tag_get_sound_data: swf_tag_create_input_detail failed\n");
        return NULL;
    }
    return swf_tag_sound_get_sound_data(tag->detail, length, sound_id);
}

int
swf_tag_replace_melo_data(swf_tag_t *tag, int sound_id,
                          unsigned char *melo_data,
                          unsigned long melo_data_len) {
    int result;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_replace_melo_data: tag == NULL\n");
        return 1;
    }
    if (melo_data == NULL) {
        fprintf(stderr, "swf_tag_replace_melo_data: melo_data == NULL\n");
        return 1;
    }
    if (tag->code != 14) { // DefineSound
        return 1;
    }
    if (swf_tag_get_cid(tag) != sound_id) {
        return 1;
    }
    if (swf_tag_create_input_detail(tag, NULL) == NULL) {
        fprintf(stderr, "swf_tag_replace_melog_data: swf_tag_create_input_detail failed\n");
        return 1;
    }
    result= swf_tag_sound_replace_melo_data(tag->detail, sound_id,
                                            melo_data, melo_data_len);
    if (result == 0) {
        free(tag->data);
        tag->data = NULL;
        tag->length = 0;
    }
    return result;
}

char *
swf_tag_get_edit_string(swf_tag_t *tag,
                        char *variable_name, int variable_name_len,
                        int *error, struct swf_object_ *swf) {
    *error = 1;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_get_edit_string: tag == NULL\n");
        return NULL;
    }
    if (variable_name == NULL) {
        fprintf(stderr, "swf_tag_get_edit_string: variable_name == NULL\n");
        return NULL;
    }
    if (tag->code != 37) { // DefineEditText
        return NULL;
    }
    if (swf_tag_create_input_detail(tag, swf) == NULL) {
        fprintf(stderr, "swf_tag_get_edit_string: swf_tag_create_input_detail failed\n");
        return NULL;
    }
    return swf_tag_edit_get_string(tag->detail,
                                   variable_name, variable_name_len, error);
}

int
swf_tag_replace_edit_string(swf_tag_t *tag,
                            char *variable_name, int variable_name_len,
                            char *initial_text, int initial_text_len,
                            struct swf_object_ *swf) {
    int result;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_replace_edit_string: tag == NULL\n");
        return 1;
    }
    if (variable_name == NULL) {
        fprintf(stderr, "swf_tag_replace_edit_string: variable_name == NULL\n");
        return 1;
    }
    if (tag->code != 37) { // DefineEditText
        return 1;
    }
    if (swf_tag_create_input_detail(tag, swf) == NULL) {
        fprintf(stderr, "swf_tag_replace_edit_string: swf_tag_create_input_detail failed\n");
        return 1;
    }
    result = swf_tag_edit_replace_string(tag->detail,
                                       variable_name, variable_name_len,
                                       initial_text, initial_text_len);
    if (result == 0) {
        free(tag->data);
        tag->data = NULL;
        tag->length = 0;
    }
    return result;
}

int
swf_tag_apply_shape_matrix_factor(swf_tag_t *tag, int shape_id, int bitmap_id,
                                  double scale_x, double scale_y,
                                  double rotate_rad,
                                  signed int trans_x, signed int trans_y,
                                  struct swf_object_ *swf) {
    int result;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_apply_shape_matrix_factor: tag == NULL\n");
        return 1;
    }
    if ((tag->code != 2) && (tag->code != 22) && (tag->code !=32 )
        && (tag->code != 46)) {
        // ! DefineShape1,2,3, DefineMorphShape
        return 1;
    }
    if (swf_tag_get_cid(tag) != shape_id) {
        return 1;
    }
    if (swf_tag_create_input_detail(tag, swf) == NULL) {
        fprintf(stderr, "swf_tag_apply_shape_matrix_factor: swf_tag_create_input_detail failed\n");
        return 1;
    }
    result = swf_tag_shape_apply_matrix_factor(tag->detail, shape_id,
                                               bitmap_id,
                                               scale_x, scale_y,
                                               rotate_rad,
                                               trans_x, trans_y);
    if (result == 0) {
        free(tag->data);
        tag->data = NULL;
        tag->length = 0;
    }
    return result;
}

int
swf_tag_apply_shape_rect_factor(swf_tag_t *tag, int shape_id, int bitmap_id,
                                  double scale_x, double scale_y,
                                  signed int trans_x, signed int trans_y,
                                  struct swf_object_ *swf) {
    int result;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_apply_shape_rect_factor: tag == NULL\n");
        return 1;
    }
    if ((tag->code != 2) && (tag->code != 22) && (tag->code !=32 )
        && (tag->code != 46)) {
        // ! DefineShape1,2,3, DefineMorphShape
        return 1;
    }
    if (swf_tag_get_cid(tag) != shape_id) {
        return 1;
    }
    if (swf_tag_create_input_detail(tag, swf) == NULL) {
        fprintf(stderr, "swf_tag_apply_shape_rect_factor: swf_tag_create_input_detail failed\n");
        return 1;
    }
    result = swf_tag_shape_apply_rect_factor(tag->detail, shape_id, bitmap_id,
                                             scale_x, scale_y,
                                             trans_x, trans_y);
    if (result == 0) {
        free(tag->data);
        tag->data = NULL;
        tag->length = 0;
    }
    return result;
}

int
swf_tag_apply_shape_type_tilled(swf_tag_t *tag, int shape_id, int bitmap_id,
                                struct swf_object_ *swf) {
    int result;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_apply_shape_type_tylled: tag == NULL\n");
        return 1;
    }
    if ((tag->code != 2) && (tag->code != 22) && (tag->code !=32 )
        && (tag->code != 46)) {
        // ! DefineShape1,2,3, DefineMorphShape
        return 1;
    }
    if (swf_tag_get_cid(tag) != shape_id) {
        return 1;
    }
    if (swf_tag_create_input_detail(tag, swf) == NULL) {
        fprintf(stderr, "swf_tag_apply_shape_rect_factor: swf_tag_create_input_detail failed\n");
        return 1;
    }
    result = swf_tag_shape_apply_type_tilled(tag->detail, shape_id, bitmap_id);
    if (result == 0) {
        free(tag->data);
        tag->data = NULL;
        tag->length = 0;
    }
    return result;
}

swf_tag_t *
swf_tag_create_action_setvariables(y_keyvalue_t *kv) {
    int ret;
    swf_tag_t *tag = NULL;
    swf_tag_action_detail_t *swf_tag_action;
    swf_tag_info_t *tag_info;
    swf_tag_detail_handler_t *detail_handler;
    if (kv == NULL) {
        fprintf(stderr, "swf_tag_create_action_setvariables: kv == NULL\n");
        return NULL;
    }
    tag = calloc(sizeof(*tag), 1);
    tag->code = 12; // DoAction
    tag_info = get_swf_tag_info(tag->code);
    detail_handler = tag_info->detail_handler();
    tag->detail = detail_handler->create();
    swf_tag_action = (swf_tag_action_detail_t*) tag->detail;
    swf_tag_action->action_list = swf_action_list_create();
    if (swf_tag_action->action_list == NULL) {
        fprintf(stderr, "swf_tag_create_action_setvariables: swf_action_list_create failed\n");
        swf_tag_destroy(tag);
        return NULL;
    }
    swf_action_list_append_top(swf_tag_action->action_list, 0, NULL, 0); // End Action
    ret = swf_tag_action_top_append_varibles(tag, kv);
    if (ret) {
        swf_tag_destroy(tag);
        return NULL;
    }
    return tag;
}

int
swf_tag_put_action_setvariables(swf_tag_t *tag, y_keyvalue_t *kv,
                                struct swf_object_ *swf) {
    int ret;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_put_action_setvariables: tag == NULL\n");
        return 1;
    }
    if (kv == NULL) {
        fprintf(stderr, "swf_tag_put_action_setvariables: kv == NULL\n");
        return 1;
    }
    if (swf_tag_create_input_detail(tag, swf) == NULL) {
        fprintf(stderr, "swf_tag_put_action_setvariables: swf_tag_create_input_detail failed\n");
        return 1;
    }
    ret = swf_tag_action_top_append_varibles(tag, kv);
    if (ret) {
        swf_tag_destroy(tag);
        return 1; // NG
    }
    if (tag->data) {
        free(tag->data);
        tag->data = NULL;
    }
    return 0;
}

int
swf_tag_replace_action_strings(swf_tag_t *tag, y_keyvalue_t *kv,
                               int *modified, struct swf_object_ *swf) {
    int ret;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_replace_action_string: tag == NULL\n");
        return 1; // NG
    }
    if (kv == NULL) {
        fprintf(stderr, "swf_tag_replace_action_string: kv == NULL\n");
        return 1; // NG
    }
    if (swf == NULL) {
        fprintf(stderr, "swf_tag_replace_action_string: swf == NULL\n");
        return 1; // NG
    }
    if (swf_tag_create_input_detail(tag, swf) == NULL) {
        fprintf(stderr, "swf_tag_replace_action_string: swf_tag_create_input_detail failed\n");
        return 1; // NG
    }
    ret = swf_tag_action_replace_strings(tag, kv, modified);
    if (ret) {
      fprintf(stderr, "swf_tag_replace_action_string: swf_tag_action_replace_strings failed\n");
    }
    return ret;
}


// move tag contents.
swf_tag_t *
swf_tag_move(swf_tag_t *from_tag) {
    swf_tag_t *to_tag = NULL;
    if (from_tag == NULL) {
        fprintf(stderr, "swf_tag_move: from_tag == NULL\n");
        return NULL;
    }
    to_tag = calloc(sizeof(*to_tag), 1);
    to_tag->code = from_tag->code;
    to_tag->length = from_tag->length;
    to_tag->length_longformat = from_tag->length_longformat;
    to_tag->data = from_tag->data;
    from_tag->data = NULL;
    from_tag->length = 0;
    to_tag->detail = from_tag->detail;
    from_tag->detail = NULL;
    return to_tag;
}

/*
 * return tag CID that all condition match
 */

int
swf_tag_search_cid_by_bitmap_condition(swf_tag_t *tag,
                                       int width, int height,
                                       int red, int green, int blue) {
    int cid = -1;
    if ((width > 0) || (height > 0)) {
        int w, h;
        if (swf_tag_get_bitmap_size(tag, &w, &h)) {
            return -1; // out
        }
        if ((width > 0) && (width != w)) {
            return -1; // out
        }
        if ((height > 0) && (height != h)) {
            return -1; // out
        }
        cid = swf_tag_get_cid(tag);
    }
    if (isBitsLosslessTag(tag->code) &&
        ( (red >= 0) || (green >= 0) || (blue >= 0) ))  {
        int r, g, b;
        swf_tag_get_bitmap_color1stpixel(tag, &r, &g, &b);
        if (red >= 0) {
            int red_diff = red - r;
            if ((red_diff < -10) || (10 < red_diff)) {
                return -1; // out
            }
        }
        if (green >= 0) {
            int green_diff = green - g;
            if ((green_diff < -10) || (10 < green_diff)) {
                return -1; // out
            }
        }
        if (blue >= 0) {
            int blue_diff = blue - b;
            if ((blue_diff < -10) || (10 < blue_diff)) {
                return -1; // out
            }
        }
        cid = swf_tag_get_cid(tag);
    }
    return cid;
}
