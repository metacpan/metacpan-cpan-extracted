/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#ifndef __SWF_JPEG__H__
#define __SWF_JPEG__H__

/* for DefineBitsJPEG2,3*/
extern unsigned char *jpegconv_std2swf(unsigned char *data,
                                       unsigned long data_len,
                                       unsigned long *length);
/* for DefineBitsJPEG(1),2,3*/
extern unsigned char *jpegconv_swf2std(unsigned char *data,
                                       unsigned long data_len,
                                       unsigned long *length,
                                       unsigned char *table_data,
                                       unsigned long table_data_len);

#endif /* __SWF_JPEG__H__ */
