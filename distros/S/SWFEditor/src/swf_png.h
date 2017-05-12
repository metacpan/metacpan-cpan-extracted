/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_PNG_H__
#define __SWF_PNG_H__

extern void *
pngconv_png2lossless(unsigned char *png_data, unsigned long png_data_len,
                     int *tag, int *format,
                     unsigned short *width, unsigned short *height,
                     void **colormap, int *colormap_count, int rgb15);

extern unsigned char *
pngconv_lossless2png(void *image_data,
                     unsigned short width, unsigned short height,
                     void *index_data,
                     unsigned short index_data_count,
                     int tag, int format,
                     unsigned long *length);

#endif /* __SWF_PNG_H__ */
