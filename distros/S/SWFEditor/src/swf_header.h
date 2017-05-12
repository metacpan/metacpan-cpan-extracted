/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_HEADER_H__
#define __SWF_HEADER_H__

#include "bitstream.h"
#include "swf_rect.h"

typedef struct swf_header_ {
    unsigned char magic[4]; // 'FWS' or 'CWS' + '\0';
    unsigned char version;
    unsigned long file_length;
} swf_header_t;


typedef struct swf_header_movie_ {
    swf_rect_t frame_size;
    unsigned short frame_rate_integral;
    unsigned short frame_rate_decimal;
    unsigned short frame_count;
} swf_header_movie_t;

extern int swf_header_parse(bitstream_t *bs, swf_header_t *header);
extern int swf_header_build(bitstream_t *bs, swf_header_t *header);
extern int swf_header_print(swf_header_t *header);

extern int swf_header_movie_parse(bitstream_t *bs, swf_header_movie_t *header_movie);
extern int swf_header_movie_build(bitstream_t *bs, swf_header_movie_t *header_movie);
extern int swf_header_movie_print(swf_header_movie_t *header_movie);

#endif /* __SWF_HEADER_H__ */

