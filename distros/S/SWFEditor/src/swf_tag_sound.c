/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#include <stdio.h>
#include <string.h>
#include "bitstream.h"
#include "swf_tag_sound.h"
#include "swf_object.h"

swf_tag_detail_handler_t sound_detail_handler;

swf_tag_detail_handler_t *
swf_tag_sound_detail_handler(void) {
    sound_detail_handler.create   = swf_tag_sound_create_detail;
    sound_detail_handler.input    = swf_tag_sound_input_detail;
    sound_detail_handler.get_cid  = swf_tag_sound_get_cid_detail;
    sound_detail_handler.replace_cid = swf_tag_sound_replace_cid_detail;
    sound_detail_handler.output   = swf_tag_sound_output_detail;
    sound_detail_handler.print    = swf_tag_sound_print_detail;
    sound_detail_handler.destroy  = swf_tag_sound_destroy_detail;
    return &sound_detail_handler;
}

void *
swf_tag_sound_create_detail(void) {
    swf_tag_sound_detail_t *swf_tag_sound;
    swf_tag_sound = calloc(sizeof(*swf_tag_sound), 1);
    if (swf_tag_sound == NULL) {
        fprintf(stderr, "ERROR: swf_tag_sound_create_detail: can't calloc\n");
        return NULL;
    }
    return swf_tag_sound;
}

int
swf_tag_sound_input_detail(swf_tag_t *tag,
                            struct swf_object_ *swf) {
    swf_tag_sound_detail_t *swf_tag_sound = tag->detail;
    unsigned char *data  = tag->data;
    unsigned long length = tag->length;
    bitstream_t *bs;
    unsigned long sound_data_len;
    unsigned char *sound_data_ref;
    (void) swf;
    if (swf_tag_sound == NULL) {
        fprintf(stderr, "ERROR: swf_tag_sound_input_detail: swf_tag_sound == NULL\n");
        return 1;
    }
    bs = bitstream_open();
    bitstream_input(bs, data, length);
    swf_tag_sound->sound_id = bitstream_getbytesLE(bs, 2);
    swf_tag_sound->sound_format    = bitstream_getbits(bs, 4);
    swf_tag_sound->sound_rate      = bitstream_getbits(bs, 2);
    swf_tag_sound->sound_is_16bits = bitstream_getbit(bs);
    swf_tag_sound->sound_is_stereo = bitstream_getbit(bs);
    swf_tag_sound->sound_samples_count = bitstream_getbytesLE(bs, 4);
    sound_data_len = bitstream_length(bs) - bitstream_getbytepos(bs);
    swf_tag_sound->sound_data = malloc(sound_data_len);
    if (swf_tag_sound->sound_data == NULL) {
        fprintf(stderr, "swf_tag_sound_create_detail: swf_tag_sound->sound_data == NULL at line(%d): sound_data_len=%lu\n",
                __LINE__, sound_data_len);
        bitstream_close(bs);
        return 1;
    }
    sound_data_ref = bitstream_buffer(bs, bitstream_getbytepos(bs));
    memcpy(swf_tag_sound->sound_data, sound_data_ref, sound_data_len);
    swf_tag_sound->sound_data_len = sound_data_len;
    bitstream_close(bs);
    return 0;
}

int
swf_tag_sound_get_cid_detail(swf_tag_t *tag) {
    int sound_id;
    unsigned char *data = tag->data;
    if (tag->detail) {
        swf_tag_sound_detail_t *swf_tag_sound = (swf_tag_sound_detail_t *) tag->detail;
        return swf_tag_sound->sound_id;
    }
    if (data == NULL) {
        fprintf(stderr, "swf_tag_sound_get_cid_detail: data==NULL\n");
        return -1;
    }
    sound_id = GetUShortLE(data);
    return sound_id;
}

int
swf_tag_sound_replace_cid_detail(swf_tag_t *tag, int id) {
    unsigned char *data = tag->data;
    if (tag->detail) {
        swf_tag_sound_detail_t *swf_tag_sound = (swf_tag_sound_detail_t *) tag->detail;
        swf_tag_sound->sound_id = id;
    }
    if (data == NULL) {
        PutUShortLE(data, id);
    }        
    return 0; // always 0
}

unsigned char *
swf_tag_sound_output_detail(swf_tag_t *tag, unsigned long *length,
                            struct swf_object_ *swf) {
    swf_tag_sound_detail_t *swf_tag_sound = (swf_tag_sound_detail_t *) tag->detail;
    bitstream_t *bs;
    unsigned char *data;
    (void) tag;
    (void) swf;
    *length = 0;
    bs = bitstream_open();
    bitstream_putbytesLE(bs, swf_tag_sound->sound_id, 2);
    bitstream_putbits(bs, swf_tag_sound->sound_format, 4);
    bitstream_putbits(bs, swf_tag_sound->sound_rate, 2);
    bitstream_putbit(bs, swf_tag_sound->sound_is_16bits);
    bitstream_putbit(bs, swf_tag_sound->sound_is_stereo);
    bitstream_putbytesLE(bs, swf_tag_sound->sound_samples_count, 4);
    bitstream_putstring(bs, swf_tag_sound->sound_data,
                        swf_tag_sound->sound_data_len);
    data = bitstream_steal(bs, length);
    bitstream_close(bs);
    return data;
}

void
swf_tag_sound_print_detail(swf_tag_t *tag,
                           struct swf_object_ *swf, int indent_depth) {
    swf_tag_sound_detail_t *swf_tag_sound = (swf_tag_sound_detail_t *) tag->detail;
    char *format_name = "Unknown";
    (void) swf;
    switch(swf_tag_sound->sound_format & 0x0f) {
    case 0:
        format_name = "Raw";
        break;
    case 1:
        format_name = "ADPCM";
        break;
    case 2:
        format_name = "MP3";
        break;
    case 3:
        format_name = "Uncompressed";
        break;
    case 6:
        format_name = "Nellymoser";
        break;
        
    }
    print_indent(indent_depth);
    printf("sound_id=%d\n", swf_tag_sound->sound_id);
    print_indent(indent_depth);    
    printf("format=%u(%s) rate=%u is_16bits=%u is_stereo=%u samples_count=%lu\n",
           swf_tag_sound->sound_format & 0x0f, format_name,
           swf_tag_sound->sound_rate  & 0x03,
           swf_tag_sound->sound_is_16bits?1:0,
           swf_tag_sound->sound_is_stereo?1:0,
           swf_tag_sound->sound_samples_count);
    print_indent(indent_depth);    
    printf("sound_data(length=%lu)\n",
           swf_tag_sound->sound_data_len);
    return ;
}

void
swf_tag_sound_destroy_detail(swf_tag_t *tag) {
    swf_tag_sound_detail_t *swf_tag_sound = (swf_tag_sound_detail_t *) tag->detail;
    if (swf_tag_sound) {
        free(swf_tag_sound->sound_data);
        swf_tag_sound->sound_data = NULL;
        free(swf_tag_sound);
        tag->detail = NULL;
    }
    return ;
}

unsigned char *
swf_tag_sound_get_sound_data(void *detail, unsigned long *length,
                           int sound_id) {
    swf_tag_sound_detail_t *swf_tag_sound = (swf_tag_sound_detail_t *) detail;
    unsigned char *data;
    *length = 0;
    if (detail == NULL) {
        fprintf(stderr, "swf_tag_sound_get_sound_data: detail == NULL\n");
        return NULL;
    }
    if (swf_tag_sound->sound_id != sound_id) {
        return NULL;
    }
    *length = swf_tag_sound->sound_data_len;
    data = malloc(*length);
    memcpy(data, swf_tag_sound->sound_data, *length);
    return data;
}

int
swf_tag_sound_replace_mp3_data(void *detail, int sound_id,
                               unsigned char *mp3_data,
                               unsigned long mp3_data_len) {
    (void) detail;
    (void) sound_id;
    (void) mp3_data;
    (void) mp3_data_len;
        // dummy
    return -1;
}

int
swf_tag_sound_replace_melo_data(void *detail, int sound_id,
                                unsigned char *melo_data,
                                unsigned long melo_data_len) {
    swf_tag_sound_detail_t *swf_tag_sound = (swf_tag_sound_detail_t *) detail;
    (void) melo_data;
    (void) melo_data_len;
    swf_tag_sound->sound_id = sound_id;
    swf_tag_sound->sound_format = 15;
    swf_tag_sound->sound_rate          = 0;
    swf_tag_sound->sound_is_16bits     = 0;
    swf_tag_sound->sound_is_stereo     = 0;
    swf_tag_sound->sound_samples_count = 0;
    free(swf_tag_sound->sound_data);
    swf_tag_sound->sound_data = malloc(melo_data_len);
    if (swf_tag_sound->sound_data == NULL) {
        fprintf(stderr, "swf_tag_sound_replace_melo_data: swf_tag_sound->sound_data == NULL\n");
        return 1;
    }
    memcpy(swf_tag_sound->sound_data, melo_data, melo_data_len);
    swf_tag_sound->sound_data_len = melo_data_len;
    return 0;
}
