/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "swf_define.h"

#ifdef HAVE_GIF

#include <gif_lib.h>
#include "bitstream.h"
#include "swf_rgb.h"  // Lossless  format=3
#include "swf_rgba.h" // Lossless2 format=3
#include "swf_xrgb.h" // Lossless  format=5
#include "swf_argb.h" // Lossless2 format=5
#include "swf_gif.h"

typedef struct my_gif_buffer_ {
    unsigned char *data;
    unsigned long data_len;
    unsigned long data_offset;
} my_gif_buffer;

typedef unsigned char gif_byte;
typedef gif_byte *    gif_bytep;
typedef gif_bytep *   gif_bytepp;
typedef unsigned long gif_uint_32;
typedef struct {
    unsigned char red, green, blue;
    unsigned char alpha;
} gif_color;
typedef gif_color *   gif_colorp;

/*
 * gif read
 */

int
gif_data_read_func(GifFileType* GifFile, GifByteType* buf, int count) {
    my_gif_buffer *gif_buff = (my_gif_buffer *) GifFile->UserData;
    if (gif_buff->data_offset + count <= gif_buff->data_len) {
        memcpy(buf, gif_buff->data + gif_buff->data_offset, count);
        gif_buff->data_offset += count;
    } else {
        fprintf(stderr, "! gif_buff->data_offset(%lu) + count(%d) <= gif_buff->data_len(%lu)\n",
                gif_buff->data_offset, count, gif_buff->data_len);
        return 0;
    }
    return count;
}

/*
 * gif write
 */

int
gif_data_write_func(GifFileType* GifFile, const GifByteType* buf, int count)
{
    my_gif_buffer *gif_buff = (my_gif_buffer *) GifFile->UserData;
    unsigned long new_data_len;
    unsigned char *tmp;
    if (gif_buff->data_offset + count > gif_buff->data_len) {
        new_data_len = 2 * gif_buff->data_len;
        if (gif_buff->data_offset + count > new_data_len) {
            new_data_len = gif_buff->data_offset + count;
        }
        tmp = realloc(gif_buff->data, new_data_len);
        if (tmp == NULL) {
            fprintf(stderr, "gif_data_write_func: can't realloc: new_data_len(%lu), data_len(%lu)\n",
                    new_data_len, gif_buff->data_len);
            return 0;
        }
        gif_buff->data = tmp;
        gif_buff->data_len = new_data_len;
    }
    memcpy(gif_buff->data + gif_buff->data_offset, buf, count);
    gif_buff->data_offset += count;
    return count;
}

/*
 * getTransparentIndex
 */
int
getTransparentIndex(SavedImage Image) {
    int i;
    int transparent_index = -1;
    if ((Image.ExtensionBlockCount == 0) || (Image.ExtensionBlocks == NULL)) {
        return -1;
    }
    for (i = 0 ; i < Image.ExtensionBlockCount ; i++ ) {
        ExtensionBlock Block = Image.ExtensionBlocks[i];
        if (Block.Function == GRAPHICS_EXT_FUNC_CODE){
            int gcntl_flag = Block.Bytes[0];
            if (gcntl_flag & 0x01) {
                transparent_index = Block.Bytes[3] & 0xff;
                return transparent_index;
            }
        }
    }
    return transparent_index;
}

/*
 *
 */

void *
gifconv_gif2lossless(unsigned char *gif_data, unsigned long gif_data_len,
                     int *tag_no, int *format,
                     unsigned short *width, unsigned short *height,
                     void **colormap, int *colormap_count) {
    GifFileType *GifFile = NULL;
    ColorMapObject *ColorMap = NULL;
    my_gif_buffer gif_buff;
    int bpp;
    gif_uint_32 gif_width = 0, gif_height = 0;
    gif_bytep gif_image_data_ref = NULL;
    gif_uint_32 x, y;
    
    void *image_data = NULL;
    int palette_num = 0;
    int trans_index = -1;
    SavedImage Image;
    int i, j;
    unsigned char *indices_data;

    gif_buff.data = gif_data;
    gif_buff.data_len = gif_data_len;
    gif_buff.data_offset = 0;
    GifFile = DGifOpen(& gif_buff, gif_data_read_func);
    if (GifFile == NULL) {
        fprintf(stderr, "gifconv_gif2lossless: can't open GIFFile\n");
        return NULL;
    }
    if (DGifSlurp(GifFile) == GIF_ERROR) {
        fprintf(stderr, "gifconv_gif2lossless: DGifSlurp failed\n");
        DGifCloseFile(GifFile);
        return NULL;
    }
    Image = GifFile->SavedImages[0];
    ColorMap = GifFile->SColorMap;
    if (ColorMap == NULL) {
        ColorMap = Image.ImageDesc.ColorMap;
    }
    gif_width  = GifFile->SWidth;
    gif_height = GifFile->SHeight;
    bpp = ColorMap->BitsPerPixel;
    if (bpp > 8) {
        fprintf(stderr, "gifconv_gif2lossless: bpp=%d not implemented. accept only bpp <= 8\n", bpp);
        DGifCloseFile(GifFile);
        return NULL;
    }
    palette_num = ColorMap->ColorCount;

    trans_index = getTransparentIndex(Image);

    *width  = (unsigned short) gif_width;
    *height = (unsigned short) gif_height;
    *format = 3;

    if (trans_index != -1) {
        *tag_no = 36; // DefineBitsLossless2
    } else {
        *tag_no = 20; // DefineBitsLossless
    }
    
    /*
     * image copy
     */
    *colormap_count = palette_num;
    if (trans_index == -1) {  // Lossless
        swf_rgb_t *result_colormap = malloc(sizeof(swf_rgb_t) * palette_num);
        for (i=0 ; i < palette_num ; i++) {
            result_colormap[i].red   = ColorMap->Colors[i].Red;
            result_colormap[i].green = ColorMap->Colors[i].Green;
            result_colormap[i].blue  = ColorMap->Colors[i].Blue;
        }
        *colormap = result_colormap;
    } else {  // Lossless2
        swf_rgba_t *result_colormap = malloc(sizeof(swf_rgba_t) * palette_num);
        for (i=0 ; i < palette_num ; i++) {
            if (i == trans_index) {
                result_colormap[i].red   = 0x0;
                result_colormap[i].green = 0x0;
                result_colormap[i].blue  = 0x0;
                result_colormap[i].alpha = 0x0;
            } else {
                result_colormap[i].red   = ColorMap->Colors[i].Red;
                result_colormap[i].green = ColorMap->Colors[i].Green;
                result_colormap[i].blue  = ColorMap->Colors[i].Blue;
                result_colormap[i].alpha = 0xff;
            }
        }
        *colormap = result_colormap;
    }
    indices_data = malloc(((gif_width+ 3) & -4) * gif_height);
    gif_image_data_ref = Image.RasterBits;

    i = 0;
    j = 0;
    for (y=0 ; y < gif_height ; y++) {
        for (x=0 ; x < gif_width ; x++) {
            indices_data[i] = gif_image_data_ref[j];
            i++;
	    j++;
        }
        while (i % 4) { i++; } // 4byte alignment
    }
    image_data = indices_data;
    /*
     * destruct
     */
    if (GifFile) {
        DGifCloseFile(GifFile);
    }
    return image_data;
}

unsigned char *
gifconv_lossless2gif(void *image_data,
                     unsigned short width, unsigned short height,
                     void *index_data,
                     unsigned short index_data_count,
                     int tag_no, int format,
                     unsigned long *length) {
    GifFileType *GifFile = NULL;
    GifColorType *Colors = NULL;
    int ColorCount;
    my_gif_buffer gif_buff;
    gif_uint_32 gif_width = 0, gif_height = 0;
    int bpp;
    gif_bytep gif_image_data = NULL;
    gif_uint_32 x, y;
    gif_colorp gif_palette = NULL;
//    int trans_index = -1;
    int i;
    if (format != 3) {
        fprintf(stderr, "jpegconv_lossless2gif: format=%d not implemented yes.\n", format);
        return NULL;
    }
    bpp = 8;
    gif_width = width;
    gif_height = height;
    ColorCount = 256;
    Colors = calloc(sizeof(GifColorType), ColorCount);
    
    gif_buff.data = NULL;
    gif_buff.data_len = 0;
    gif_buff.data_offset = 0;
    GifFile = EGifOpen(& gif_buff, gif_data_write_func);
    if (GifFile == NULL) {
        fprintf(stderr, "gifconv_lossless2gif: can't open GIFFile\n");
        return NULL;
    }
    GifFile->SWidth  = gif_width;
    GifFile->SHeight = gif_height;
    GifFile->SColorResolution = bpp;

    gif_palette = (gif_colorp) malloc(sizeof(gif_color)*index_data_count);
    
    if (tag_no == 20) {
        swf_rgb_t *rgb_list  = index_data;
        for (i=0 ; i < index_data_count ; i++) {
            Colors[i].Red   = rgb_list[i].red;
            Colors[i].Green = rgb_list[i].green;
            Colors[i].Blue  = rgb_list[i].blue;
        }
    } else {
        swf_rgba_t *rgba_list  = index_data;
        for (i=0 ; i < index_data_count ; i++) {
//            if (rgba_list[i].alpha)
            Colors[i].Red   = rgba_list[i].red;
            Colors[i].Green = rgba_list[i].green;
            Colors[i].Blue  = rgba_list[i].blue;
//                gif_palette[i].alpha = ;
        }
    }
    GifFile->SBackGroundColor = 0; // XXX
    gif_image_data = (gif_bytep) calloc(sizeof(unsigned char), gif_width * gif_height);
    i = 0;
    for (y=0 ; y < gif_height ; y++) {
        for (x=0 ; x < gif_width ; x++) {
            unsigned char *data = image_data;
            gif_image_data[i] = data[x + y*((gif_width +3) & -4)];
            i++;
        }
    }

    GifFile->SavedImages[0].RasterBits = gif_image_data;
    GifFile->SColorMap = MakeMapObject(ColorCount, Colors);
    EGifSpew(GifFile); // XXX

    free(gif_image_data);

    if (GifFile) {
        EGifCloseFile(GifFile);
    }
    *length = gif_buff.data_offset;
    return gif_buff.data;
}

#endif /* HAVE_GIF */
