/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/


#ifndef __BITMAP_UTIL_H__
#define __BITMAP_UTIL_H__

#include "jpeg_segment.h"

extern int jpeg_size_segment(jpeg_segment_t *jpeg_seg, int *width, int *height);
extern int jpeg_size(unsigned char *data, unsigned long data_len,
                     int *width, int *height);

extern int png_size(unsigned char *data, unsigned long data_len,
                    int *width, int *height);

extern int gif_size(unsigned char *data, unsigned long data_len,
                    int *width, int *height);

extern int detect_bitmap_format(unsigned char *data, unsigned long data_len);

extern int bitmap_size(unsigned char *data, unsigned long data_len,
                     int *width, int *height);

#define BITMAP_UTIL_FORMAT_UNKNOWN 0
#define BITMAP_UTIL_FORMAT_JPEG    1
#define BITMAP_UTIL_FORMAT_PNG     2
#define BITMAP_UTIL_FORMAT_GIF     4

#endif /* __BITMAP_UTIL_H__ */
