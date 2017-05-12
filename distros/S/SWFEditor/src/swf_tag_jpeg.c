/* 
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h> /* memcpy */
#include <zlib.h>
#include "bitstream.h"
#include "swf_define.h"
#include "swf_tag_jpeg.h"
#include "swf_object.h"
// #include "swf_tag.h"
#include "swf_jpeg.h"
#include "jpeg_segment.h"
#include "bitmap_util.h"

swf_tag_detail_handler_t jpeg_detail_handler;
swf_tag_detail_handler_t jpegt_detail_handler;
swf_tag_detail_handler_t jpeg3_detail_handler;

swf_tag_detail_handler_t *swf_tag_jpeg_detail_handler(void) {
    jpeg_detail_handler.create   = swf_tag_jpeg_create_detail;
    jpeg_detail_handler.input    = swf_tag_jpeg_input_detail;
    jpeg_detail_handler.get_cid  = swf_tag_jpeg_get_cid_detail;
    jpeg_detail_handler.replace_cid = swf_tag_jpeg_replace_cid_detail;
    jpeg_detail_handler.output   = swf_tag_jpeg_output_detail;
    jpeg_detail_handler.print    = swf_tag_jpeg_print_detail;
    jpeg_detail_handler.destroy  = swf_tag_jpeg_destroy_detail;
    return &jpeg_detail_handler;
}

swf_tag_detail_handler_t *swf_tag_jpegt_detail_handler(void) {
    jpegt_detail_handler.create   = swf_tag_jpeg_create_detail;
    jpegt_detail_handler.input    = swf_tag_jpegt_input_detail;
    jpegt_detail_handler.get_cid  = NULL;
    jpegt_detail_handler.replace_cid = NULL;
    jpegt_detail_handler.output   = swf_tag_jpegt_output_detail;
    jpegt_detail_handler.print    = swf_tag_jpeg_print_detail;
    jpegt_detail_handler.destroy  = swf_tag_jpeg_destroy_detail;
    return &jpegt_detail_handler;
}

swf_tag_detail_handler_t *swf_tag_jpeg3_detail_handler(void) {
    jpeg3_detail_handler.create   = swf_tag_jpeg_create_detail;
    jpeg3_detail_handler.input    = swf_tag_jpeg3_input_detail;
    jpeg3_detail_handler.get_cid  = swf_tag_jpeg_get_cid_detail;
    jpeg3_detail_handler.replace_cid = swf_tag_jpeg_replace_cid_detail;
    jpeg3_detail_handler.output   = swf_tag_jpeg3_output_detail;
    jpeg3_detail_handler.print    = swf_tag_jpeg_print_detail;
    jpeg3_detail_handler.destroy  = swf_tag_jpeg_destroy_detail;
    return &jpeg3_detail_handler;
}

void *
swf_tag_jpeg_create_detail(void) {
    swf_tag_jpeg_detail_t *swf_tag_jpeg;
    swf_tag_jpeg = calloc(sizeof(*swf_tag_jpeg), 1);
    if (swf_tag_jpeg == NULL) {
        fprintf(stderr, "ERROR: swf_tag_jpeg_create_detail: can't calloc\n");
        return NULL;
    }
    swf_tag_jpeg->image_id = 0;
    swf_tag_jpeg->jpeg_data = NULL;
    swf_tag_jpeg->jpeg_data_len = 0;
    swf_tag_jpeg->offset_to_alpha = 0;
    swf_tag_jpeg->alpha_data = NULL;
    swf_tag_jpeg->alpha_data_len = 0;
    return (void *) swf_tag_jpeg;
}

int
swf_tag_jpeg_input_detail(swf_tag_t *tag,
                          struct swf_object_ *swf) {
    swf_tag_jpeg_detail_t *swf_tag_jpeg = NULL;
    unsigned char *data = NULL;
    unsigned long length;
    bitstream_t *bs = NULL;
    (void) swf;
    if (tag == NULL) {
        fprintf(stderr, "ERROR: swf_tag_jpeg_input_detail: swf_tag_jpeg == NULL\n");
        return 1;
    }
    swf_tag_jpeg = tag->detail;
    data  = tag->data;
    length = tag->length;
    if (swf_tag_jpeg == NULL) {
        fprintf(stderr, "ERROR: swf_tag_jpeg_input_detail: swf_tag_jpeg == NULL\n");
        return 1;
    }
    bs = bitstream_open();
    bitstream_input(bs, data, length);
    swf_tag_jpeg->image_id = bitstream_getbytesLE(bs, 2);
    swf_tag_jpeg->jpeg_data = bitstream_output_sub(bs, 2, length - 2);
    swf_tag_jpeg->jpeg_data_len = length - 2;
    swf_tag_jpeg->alpha_data = NULL;
    swf_tag_jpeg->alpha_data_len = 0;
    bitstream_close(bs);
    return 0;
}

int
swf_tag_jpegt_input_detail(swf_tag_t *tag,
                          struct swf_object_ *swf) {
    swf_tag_jpeg_detail_t *swf_tag_jpeg = NULL;
    unsigned char *data  = NULL;
    unsigned long length;
    (void) swf;
    if (tag == NULL) {
        fprintf(stderr, "ERROR: swf_tag_jpegt_input_detail: tag == NULL\n");
        return 1;
    }
    swf_tag_jpeg = tag->detail;
    data  = tag->data;
    length = tag->length;
    if (swf_tag_jpeg == NULL) {
        fprintf(stderr, "ERROR: swf_tag_jpegt_input_detail: swf_tag_jpeg == NULL\n");
        return 1;
    }
    swf_tag_jpeg->image_id = -1; // no id
    swf_tag_jpeg->jpeg_data = (unsigned char *) malloc(length);
    memcpy(swf_tag_jpeg->jpeg_data, data, length);
    swf_tag_jpeg->jpeg_data_len = length;
    swf_tag_jpeg->alpha_data = NULL;
    swf_tag_jpeg->alpha_data_len = 0;
    return 0;
}

int
swf_tag_jpeg3_input_detail(swf_tag_t *tag,
                           struct swf_object_ *swf) {
    swf_tag_jpeg_detail_t *swf_tag_jpeg = NULL;
    unsigned char *data = NULL;
    unsigned long length;
    unsigned long offset_to_alpha;
    bitstream_t *bs = NULL;
    unsigned long  offset, alpha_data_len;
    unsigned char *old_buff_ref = NULL, *new_buff = NULL;
    unsigned long origsize;
    int result;
    (void) swf;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_jpeg3_input_detail: tag == NULL\n");
        return 1;
    }
    swf_tag_jpeg = tag->detail;
    data  = tag->data;
    length = tag->length;
    if (swf_tag_jpeg == NULL) {
        fprintf(stderr, "ERROR: swf_tag_jpeg3_input_detail: swf_tag_jpeg == NULL\n");
        return 1;
    }
    bs = bitstream_open();
    bitstream_input(bs, data, length);
    swf_tag_jpeg->image_id = bitstream_getbytesLE(bs, 2);
    offset_to_alpha = bitstream_getbytesLE(bs, 4);
    swf_tag_jpeg->offset_to_alpha = offset_to_alpha;
    swf_tag_jpeg->jpeg_data = bitstream_output_sub(bs, 2 + 4 , offset_to_alpha);
    if (swf_tag_jpeg->jpeg_data == NULL) {
        free(swf_tag_jpeg);
        bitstream_close(bs);
        fprintf(stderr, "swf_tag_jpeg3_create_detail: swf_tag_jpeg->jpeg_data\n");
        return 1;
    }
    
    swf_tag_jpeg->jpeg_data_len = offset_to_alpha;
    offset = 2 + 4 + offset_to_alpha;
    alpha_data_len = length - offset;
    // TODO: analyze jpeg and get width and height
    origsize = 512 * alpha_data_len; // XXX greater than jpeg1,2
    
    new_buff = malloc(origsize); // enough size?
    old_buff_ref = bitstream_buffer(bs, offset);
    result = uncompress(new_buff, &origsize, old_buff_ref, alpha_data_len);
    if (result == Z_BUF_ERROR) { // XXX
        origsize *= 2;
        new_buff = realloc(new_buff, origsize); // enough size?
        if (new_buff == NULL) {
            free(swf_tag_jpeg);
            bitstream_close(bs);
            fprintf(stderr, "swf_tag_jpeg3_create_detail: realloc(%p, %lu) failed\n", new_buff, origsize);
            return 1;
        }
        result = uncompress(new_buff, &origsize, old_buff_ref, alpha_data_len);
    }
    if (result == Z_OK) {
        swf_tag_jpeg->alpha_data = realloc(new_buff, origsize);
        swf_tag_jpeg->alpha_data_len = origsize;
    } else {
        if (result == Z_MEM_ERROR) {
            fprintf(stderr, "swf_tag_jpeg3_create_detail: uncompress: Z_MEM_ERROR: can't malloc\n");
        } else if (result == Z_BUF_ERROR) {
            fprintf(stderr, "swf_tag_jpeg3_create_detail: uncompress: Z_BUF_ERROR: not enough buff size\n");
        } else if (result == Z_DATA_ERROR) {
            fprintf(stderr, "swf_tag_jpeg3_create_detail: uncompress: Z_DATA_ERROR: corrupted or imcomplete data\n");
        } else {
            fprintf(stderr, "swf_tag_jpeg3_create_detail: uncompress: failed by unknown reason (%d)\n", result);
        }
        free(new_buff);
    }
    bitstream_close(bs);
    return 0;
}

int
swf_tag_jpeg_get_cid_detail(swf_tag_t *tag) {
    unsigned char *data = NULL;

    if (tag == NULL) {
        fprintf(stderr, "swf_tag_jpeg_get_cid_detail: tag == NULL\n");
        return -1;
    }
    data = tag->data;
    if (tag->detail) {
        swf_tag_jpeg_detail_t *swf_tag_jpeg = (swf_tag_jpeg_detail_t *) tag->detail;        
        return swf_tag_jpeg->image_id;
    }
    if (data == NULL) {
        fprintf(stderr, "swf_tag_jpeg_get_cid_detail: data==NULL\n");
        return -1;
    }
    return GetUShortLE(data); // image_id;
}

int
swf_tag_jpeg_replace_cid_detail(swf_tag_t *tag, int image_id) {
    unsigned char *data = NULL;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_jpeg_replace_cid_detail: tag == NULL\n");
        return 1;
    }
    data = tag->data;
    if (tag->detail) {
        swf_tag_jpeg_detail_t *swf_tag_jpeg = (swf_tag_jpeg_detail_t *) tag->detail;        
        swf_tag_jpeg->image_id = image_id;
    }
    if (data) {
        PutUShortLE(data, image_id);
    }
    return 0;
}

unsigned char *
swf_tag_jpeg_output_detail(swf_tag_t *tag, unsigned long *length,
                           struct swf_object_ *swf) {
    swf_tag_jpeg_detail_t *swf_tag_jpeg = NULL;
    bitstream_t *bs = NULL;
    unsigned char *data = NULL;
    (void) swf;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_jpeg_output_detail: tag == NULL\n");
        return NULL;
    }
    swf_tag_jpeg = (swf_tag_jpeg_detail_t *) tag->detail;
    *length = 0;
    bs = bitstream_open();
    bitstream_putbytesLE(bs, swf_tag_jpeg->image_id, 2);
    bitstream_putstring(bs, swf_tag_jpeg->jpeg_data, swf_tag_jpeg->jpeg_data_len);
    data = bitstream_steal(bs, length);
    bitstream_close(bs);
    return data;
}

unsigned char *
swf_tag_jpegt_output_detail(swf_tag_t *tag, unsigned long *length,
                            struct swf_object_ *swf) {
    swf_tag_jpeg_detail_t *swf_tag_jpeg = NULL;
    bitstream_t *bs = NULL;
    unsigned char *data = NULL;
    (void) swf;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_jpegt_output_detail: tag == NULL\n");
        return NULL;
    }
    if (length == NULL) {
        fprintf(stderr, "swf_tag_jpegt_output_detail: length == NULL\n");
        return NULL;
    }
    *length = 0;
    swf_tag_jpeg = (swf_tag_jpeg_detail_t *) tag->detail;
    bs = bitstream_open();
    bitstream_putstring(bs, swf_tag_jpeg->jpeg_data, swf_tag_jpeg->jpeg_data_len);
    data = bitstream_steal(bs, length);
    bitstream_close(bs);
    return data;
}

unsigned char *
swf_tag_jpeg3_output_detail(swf_tag_t *tag, unsigned long *length,
                            struct swf_object_ *swf) {
    swf_tag_jpeg_detail_t *swf_tag_jpeg = NULL;
    bitstream_t *bs = NULL;
    unsigned char *data = NULL, *new_buff = NULL;
    unsigned long offset_to_alpha;
    unsigned long compsize, old_size;
    int result;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_jpeg3_output_detail: tag == NULL\n");
    }
    if (swf == NULL) {
        fprintf(stderr, "swf_tag_jpeg3_output_detail: swf == NULL\n");
    }
    if (length == NULL) {
        fprintf(stderr, "swf_tag_jpeg3_output_detail: length == NULL\n");
    }
    swf_tag_jpeg = (swf_tag_jpeg_detail_t *) tag->detail;
    *length = 0;
    bs = bitstream_open();
    bitstream_putbytesLE(bs, swf_tag_jpeg->image_id, 2);
    bitstream_putbytesLE(bs, swf_tag_jpeg->jpeg_data_len, 4);
    bitstream_putstring(bs, swf_tag_jpeg->jpeg_data, swf_tag_jpeg->jpeg_data_len);
    offset_to_alpha = swf_tag_jpeg->jpeg_data_len;
    old_size = swf_tag_jpeg->alpha_data_len;
    compsize = old_size * 1.001 + 12; // increasing, rarely situation
    new_buff = malloc(compsize);
    //    result = compress2(new_buff, &compsize, swf_tag_jpeg->alpha_data, old_size, swf->compress_level);
    result = compress2(new_buff, &compsize, swf_tag_jpeg->alpha_data, old_size, swf->compress_level);
    if (result != Z_OK) {
        if (result == Z_MEM_ERROR) {
            fprintf(stderr, "swf_tag_jpeg_output_detail: compress Z_MEM_ERROR: can't malloc\n");
        } else if (result == Z_BUF_ERROR) {
            fprintf(stderr, "swf_tag_jpeg_output_detail: compress Z_BUF_ERROR: not enough buff size\n");
        } else {
            fprintf(stderr, "swf_tag_jpeg_output_detail: compress failed by unknown reason\n");
        }
        free(new_buff);
        bitstream_close(bs);
        return NULL; // FAILURE
    }
    bitstream_putstring(bs, new_buff, compsize);
    free(new_buff);
    data = bitstream_steal(bs, length);
    bitstream_close(bs);
    return data;
}

void
swf_tag_jpeg_print_detail(swf_tag_t *tag,
                          struct swf_object_ *swf, int indent_depth) {
    swf_tag_jpeg_detail_t *swf_tag_jpeg = NULL;
    jpeg_segment_t *jpeg_seg = NULL;
    jpeg_segment_node_t *node = NULL;
    (void) swf;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_jpeg_print_detail: tag == NULL\n");
        return ;
    }
    swf_tag_jpeg = (swf_tag_jpeg_detail_t *) tag->detail;
    if (swf_tag_jpeg == NULL) {
        fprintf(stderr, "swf_tag_jpeg_print_detail: swf_tag_jpeg == NULL\n");
        return ;
    }
        
    print_indent(indent_depth);
    if (swf_tag_jpeg->image_id == -1) {
        printf("jpeg_data_size=%lu\n", swf_tag_jpeg->jpeg_data_len);
    } else {
        printf("image_id=%d  jpeg_data_size=%lu\n",
               swf_tag_jpeg->image_id, swf_tag_jpeg->jpeg_data_len);
    }
    jpeg_seg = jpeg_segment_parse(swf_tag_jpeg->jpeg_data,
                                  swf_tag_jpeg->jpeg_data_len, SWFED_JPEG_RST_SCAN_SWFJPEG);
    if (jpeg_seg) {
        int ret, width = 0, height = 0;
        // bitmap size
        ret = jpeg_size_segment(jpeg_seg, &width, &height);
        if (ret == 0) {
            print_indent(indent_depth + 1);
            printf("(width, height)=(%d, %d)\n", width, height);
        }
        // dump chunk
        for (node=jpeg_seg->head ; node ; node=node->next) {
            char *name = jpeg_segment_get_marker_name(node->marker);
            print_indent(indent_depth + 1);
            printf("%s(0x%02X): len=%lu\n", name?name:"Unknwon",
                   node->marker, node->data_len);
        }
        jpeg_segment_destroy(jpeg_seg);
    } else {
        unsigned char *data = swf_tag_jpeg->jpeg_data;
        print_indent(indent_depth + 1);
        printf("(invalid jpeg data: %02x %02x %02x %02x ...)\n",
               data[0]&0xff, data[1]&0xff, data[2]&0xff, data[3]&0xff);
    }
    if (swf_tag_jpeg->alpha_data) {
        print_indent(indent_depth);
        printf("alpha_data_size=%lu\n",
               swf_tag_jpeg->alpha_data_len);
    }
}

void
swf_tag_jpeg_destroy_detail(swf_tag_t *tag) {
    swf_tag_jpeg_detail_t *swf_tag_jpeg = NULL;
    if (tag == NULL) {
        fprintf(stderr, "swf_tag_jpeg_destroy_detail: tag == NULL\n");
        return ;
    }
    swf_tag_jpeg = (swf_tag_jpeg_detail_t *) tag->detail;
    if (swf_tag_jpeg) {
        free(swf_tag_jpeg->jpeg_data);
        free(swf_tag_jpeg->alpha_data);
        swf_tag_jpeg->jpeg_data = NULL;
        swf_tag_jpeg->alpha_data = NULL;
        free(swf_tag_jpeg);
        tag->detail = NULL;
    }
    return ;
}
    
unsigned char *
swf_tag_jpeg_get_jpeg_data(void *detail,
                           unsigned long *length,
                           int image_id,
                           unsigned char *jpeg_table_data,
                           unsigned long jpeg_table_data_len) {
    swf_tag_jpeg_detail_t *swf_tag_jpeg = (swf_tag_jpeg_detail_t *) detail;
    unsigned char *data;
    if (detail == NULL) {
        fprintf(stderr, "swf_tag_jpeg_get_jpeg_data: detail == NULL\n");
    }
    if (length == NULL) {
        fprintf(stderr, "swf_tag_jpeg_get_jpeg_data: length == NULL\n");
    }
    *length = 0;
    if (swf_tag_jpeg->image_id != image_id) {
        return NULL;
    }
    if (swf_tag_jpeg->jpeg_data_len == 0) {
        fprintf(stderr, "swf_tag_jpeg_get_jpeg_data: swf_tag_jpeg->jpeg_data_len\n");
        return NULL;
    }
    data = jpegconv_swf2std(swf_tag_jpeg->jpeg_data,
                            swf_tag_jpeg->jpeg_data_len,
                            length, 
                            jpeg_table_data,
                            jpeg_table_data_len);
    return data;
}

unsigned char *swf_tag_jpeg_get_alpha_data(void *detail, unsigned long *length, int image_id) {
    swf_tag_jpeg_detail_t *swf_tag_jpeg = (swf_tag_jpeg_detail_t *) detail;
    unsigned char *data = NULL;
    if (detail == NULL) {
        fprintf(stderr, "swf_tag_jpeg_get_alpha_data: detail == NULL\n");
        return NULL;
    }
    if (length == NULL) {
        fprintf(stderr, "swf_tag_jpeg_get_alpha_data: length == NULL\n");
        return NULL;
    }

    *length = 0;
    if (swf_tag_jpeg->image_id != image_id) {
        return NULL;
    }
    *length = swf_tag_jpeg->alpha_data_len;
    if (*length == 0) {
        return NULL;
    }
    data = malloc(*length);
    memcpy(data, swf_tag_jpeg->alpha_data, *length);
    return data;
}

int
swf_tag_jpeg_replace_jpeg_data(void *detail, int image_id,
                               unsigned char *jpeg_data,
                               unsigned long jpeg_data_len,
                               unsigned char *alpha_data,
                               unsigned long alpha_data_len,
                               swf_tag_t *tag) {
    swf_tag_jpeg_detail_t *swf_tag_jpeg = (swf_tag_jpeg_detail_t *) detail;
    if (detail == NULL) {
        fprintf(stderr, "swf_tag_jpeg_replace_jpeg_data: detail == NULL\n");
        return 1;
    }
    swf_tag_jpeg->image_id = image_id;
    if (tag->code == 6) { // DefineBitsJPEG
        if (jpeg_data && jpeg_data_len) { // fail safe
            free(swf_tag_jpeg->jpeg_data);
            swf_tag_jpeg->jpeg_data = malloc(jpeg_data_len);
            memcpy(swf_tag_jpeg->jpeg_data, jpeg_data, jpeg_data_len);
            swf_tag_jpeg->jpeg_data_len = jpeg_data_len;
        }
    } else {
        if (jpeg_data && jpeg_data_len) {
            unsigned long length;
            free(swf_tag_jpeg->jpeg_data);
            swf_tag_jpeg->jpeg_data = jpegconv_std2swf(jpeg_data, jpeg_data_len,
                                                       &length);
            if (swf_tag_jpeg->jpeg_data == NULL) {
                fprintf(stderr, "swf_tag_jpeg_replace_jpeg_data: failed to jpegconv_std2swf\n");
                return 1;
            }
            swf_tag_jpeg->jpeg_data_len = length;
        }
        if (alpha_data && alpha_data_len) {
            free(swf_tag_jpeg->alpha_data);
            swf_tag_jpeg->alpha_data = malloc(alpha_data_len);
            memcpy(swf_tag_jpeg->alpha_data, alpha_data, alpha_data_len);
            swf_tag_jpeg->alpha_data_len = alpha_data_len;
        }
    }
    return 0;
}

int
swf_tag_jpeg_replace_bitmap_data(void *detail, int image_id,
                                 unsigned char *bitmap_data,
                                 unsigned long bitmap_data_len,
                                 swf_tag_t *tag) {
    swf_tag_jpeg_detail_t *swf_tag_jpeg = (swf_tag_jpeg_detail_t *) detail;
    if (detail == NULL) {
        fprintf(stderr, "swf_tag_jpeg_replace_jpeg_data: detail == NULL\n");
        return 1;
    }
    swf_tag_jpeg->image_id = image_id;
    tag->code = 21; // DefineBitsJPEG2
    if (bitmap_data && bitmap_data_len) { // fail safe
            free(swf_tag_jpeg->jpeg_data);
            swf_tag_jpeg->jpeg_data = malloc(bitmap_data_len);
            memcpy(swf_tag_jpeg->jpeg_data, bitmap_data, bitmap_data_len);
            swf_tag_jpeg->jpeg_data_len = bitmap_data_len;
    } else {
        fprintf(stderr, "swf_tag_jpeg_replace_bitmap_data: jpeg_data == NULL or jpeg_data_len == 0\n");
            return 1;
    }
    free(swf_tag_jpeg->alpha_data);
    swf_tag_jpeg->alpha_data = NULL;
    swf_tag_jpeg->alpha_data_len = 0;
    return 0;
}
