/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#include <stdio.h>
#include <string.h>
#include "bitstream.h"
#include "swf_tag_sprite.h"
#include "swf_object.h"

swf_tag_detail_handler_t sprite_detail_handler;

swf_tag_detail_handler_t *
swf_tag_sprite_detail_handler(void) {
    sprite_detail_handler.create   = swf_tag_sprite_create_detail;
    sprite_detail_handler.input    = swf_tag_sprite_input_detail;
    sprite_detail_handler.get_cid  = swf_tag_sprite_get_cid_detail;
    sprite_detail_handler.replace_cid = swf_tag_sprite_replace_cid_detail;
    sprite_detail_handler.output   = swf_tag_sprite_output_detail;
    sprite_detail_handler.print    = swf_tag_sprite_print_detail;
    sprite_detail_handler.destroy  = swf_tag_sprite_destroy_detail;
    return &sprite_detail_handler;
}

void *
swf_tag_sprite_create_detail(void) {
    swf_tag_sprite_detail_t *swf_tag_sprite;
    swf_tag_sprite = calloc(sizeof(*swf_tag_sprite), 1);
    if (swf_tag_sprite == NULL) {
        fprintf(stderr, "ERROR: swf_tag_sprite_create_detail: can't calloc\n");
        return NULL;
    }
    return swf_tag_sprite;
}

int
swf_tag_sprite_input_detail(swf_tag_t *tag, struct swf_object_ *swf) {
    swf_tag_sprite_detail_t *swf_tag_sprite = tag->detail;
    unsigned char *data  = tag->data;
    unsigned long length = tag->length;
    bitstream_t *bs;
    swf_tag_t *tag_in_sprite, *prev_tag;
    (void) swf;
    if (swf_tag_sprite == NULL) {
        fprintf(stderr, "ERROR: swf_tag_sprite_input_detail: swf_tag_sprite == NULL\n");
        return 1;
    }
    bs = bitstream_open();
    bitstream_input(bs, data, length);
    swf_tag_sprite->sprite_id = bitstream_getbytesLE(bs, 2);
    swf_tag_sprite->frame_count = bitstream_getbytesLE(bs, 2);
    //

    prev_tag = NULL;
    while(1) {
        long pos;
        pos = bitstream_getbytepos(bs);
        if ((pos == -1) || ((long) length <= pos)) {
            break;
        }
        tag_in_sprite = swf_tag_create(bs);
        if (tag_in_sprite == NULL) {
            fprintf(stderr, "swf_object_input: swf_tag_create failed\n");
            break;
        }
        if (prev_tag == NULL) {
            swf_tag_sprite->tag = tag_in_sprite;
            tag_in_sprite->prev = NULL;
        } else {
            prev_tag->next = tag_in_sprite;
            tag_in_sprite->prev = prev_tag;
        }
        tag_in_sprite->next = NULL;
        prev_tag = tag_in_sprite;
    }
    bitstream_close(bs);
    return 0;
}

int swf_tag_sprite_get_cid_detail(swf_tag_t *tag) {
    unsigned char *data = tag->data;
    if (tag->detail) {
        swf_tag_sprite_detail_t *swf_tag_sprite = (swf_tag_sprite_detail_t *) tag->detail;
        return swf_tag_sprite->sprite_id;
    }
    if (data == NULL) {
        fprintf(stderr, "swf_tag_sprite_get_cid_detail: data == NULL\n");
        return -1;
    }
    return GetUShortLE(data); // sprite_id;
}

int swf_tag_sprite_replace_cid_detail(swf_tag_t *tag, int id) {
    unsigned char *data = tag->data;
    if (tag->detail) {
        swf_tag_sprite_detail_t *swf_tag_sprite = (swf_tag_sprite_detail_t *) tag->detail;
        swf_tag_sprite->sprite_id = id;
    }
    if (data) {
        PutUShortLE(data, id);
    }        
    return 0; // always 0
}

unsigned char *
swf_tag_sprite_output_detail(swf_tag_t *tag, unsigned long *length,
                           struct swf_object_ *swf) {
    swf_tag_sprite_detail_t *swf_tag_sprite = (swf_tag_sprite_detail_t *) tag->detail;
    bitstream_t *bs;
    unsigned char *data;
    swf_tag_t *_tag;
    *length = 0;
    bs = bitstream_open();
    bitstream_putbytesLE(bs, swf_tag_sprite->sprite_id, 2);
    bitstream_putbytesLE(bs, swf_tag_sprite->frame_count, 2);
    for (_tag=swf_tag_sprite->tag ; _tag ; _tag=_tag->next) {
        swf_tag_build(bs, _tag, swf);
    }
    data = bitstream_steal(bs, length);
    bitstream_close(bs);
    return data;
}

void
swf_tag_sprite_print_detail(swf_tag_t *tag,
                            struct swf_object_ *swf,
                            int indent_depth) {
    swf_tag_sprite_detail_t *swf_tag_sprite = (swf_tag_sprite_detail_t *) tag->detail;
    int i;
    swf_tag_t *_tag;
    print_indent(indent_depth);
    printf("sprite_id=%d\n", swf_tag_sprite->sprite_id);
    print_indent(indent_depth);
    printf("frame_count=%d\n", swf_tag_sprite->frame_count);
    _tag = swf_tag_sprite->tag;
    for (i=0 ; _tag ; i++) {
        print_indent(indent_depth);
        printf("  [%d] ", i);
        swf_tag_print(_tag, swf, indent_depth + 1);
        if (_tag->code == 0) { // END Tag
            break;
        }
        _tag = _tag->next;
    }
    return ;
}

void
swf_tag_sprite_destroy_detail(swf_tag_t *tag) {
    swf_tag_sprite_detail_t *swf_tag_sprite = (swf_tag_sprite_detail_t *) tag->detail;
    if (swf_tag_sprite) {
        swf_tag_t *t, *next_tag;
        for (t = swf_tag_sprite->tag ; t ; t = next_tag) {
            next_tag = t->next;
            swf_tag_destroy(t);
        }
        free(swf_tag_sprite);
        tag->detail = NULL;
    }
    return ;
}
