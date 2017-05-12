/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_GIF_H__
#define __SWF_GIF_H__

extern void *
gifconv_gif2lossless(unsigned char *gif_data, unsigned long gif_data_len,
                     int *tag, int *format,
                     unsigned short *width, unsigned short *height,
                     void **colormap, int *colormap_count);

extern unsigned char *
gifconv_lossless2gif(void *image_data,
                     unsigned short width, unsigned short height,
                     void *index_data,
                     unsigned short index_data_count,
                     int tag, int format,
                     unsigned long *length);

#endif /* __SWF_GIF_H__ */
