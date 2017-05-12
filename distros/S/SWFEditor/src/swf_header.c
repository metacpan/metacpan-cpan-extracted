/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#include <stdio.h>
#include "swf_define.h"
#include "swf_header.h"

int
swf_header_parse(bitstream_t *bs, swf_header_t *header) {
    bitstream_getstring(bs, header->magic, 3);
    header->version = bitstream_getbyte(bs);
    header->file_length = bitstream_getbytesLE(bs, 4);
    return 0;
}

int
swf_header_build(bitstream_t *bs, swf_header_t *header) {
    if (bitstream_putstring(bs, header->magic, 3)) {
        return 1;
    }
    if (bitstream_putbyte(bs, header->version)) {
        return 1;
    }
    if (bitstream_putbytesLE(bs, header->file_length, 4)) {
        return 1;
    }
    return 0;
}

int
swf_header_movie_parse(bitstream_t *bs,
                           swf_header_movie_t *header_movie) {
    swf_rect_parse(bs, &header_movie->frame_size);
    header_movie->frame_rate_decimal = bitstream_getbyte(bs);
    header_movie->frame_rate_integral = bitstream_getbyte(bs);
    header_movie->frame_count = bitstream_getbytesLE(bs, 2);
    return 0;
}

int
swf_header_movie_build(bitstream_t *bs,
                           swf_header_movie_t *header_movie) {
    swf_rect_build(bs, &header_movie->frame_size);
    bitstream_putbyte(bs, header_movie->frame_rate_decimal);
    bitstream_putbyte(bs, header_movie->frame_rate_integral);
    bitstream_putbytesLE(bs, header_movie->frame_count, 2);
    return 0;
}

int swf_header_print(swf_header_t *header) {
    printf("magic=%s  version=%d  file_length=%lu\n",
           header->magic, header->version, header->file_length);
    return 0;
}

int swf_header_movie_print(swf_header_movie_t *header_movie) {
    swf_rect_print(&header_movie->frame_size, 0);
    printf("frame_rate=%d.%d  frame_count=%d\n",
           header_movie->frame_rate_integral,
           header_movie->frame_rate_decimal,
           header_movie->frame_count);
    return 0;
}
