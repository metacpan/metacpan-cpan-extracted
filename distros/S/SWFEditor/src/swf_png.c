/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/

#include <stdio.h>
#include <stdlib.h>
#include "swf_define.h"

#ifdef HAVE_PNG

#include <png.h>
#include "bitstream.h"
#include "swf_rgb.h"  // Lossless  format=3
#include "swf_rgba.h" // Lossless2 format=3
#include "swf_xrgb.h" // Lossless  format=5
#include "swf_argb.h" // Lossless2 format=5
#include "swf_png.h"

typedef struct my_png_buffer_ {
    unsigned char *data;
    unsigned long data_len;
    unsigned long data_offset;
} my_png_buffer;

/*
 * png read
 */

static void
png_data_read_func(png_structp png_ptr, png_bytep buf, png_size_t size) {
    my_png_buffer *png_buff = (my_png_buffer *)png_get_io_ptr(png_ptr);
    if (png_buff->data_offset + size <= png_buff->data_len) {
        memcpy(buf, png_buff->data + png_buff->data_offset, size);
        png_buff->data_offset += size;
    } else {
        fprintf(stderr, "png_data_read_func: ! png_buff->data_offset(%lu) + size(%zd) <= png_buff->data_len(%lu)\n",
                png_buff->data_offset, size, png_buff->data_len);
        png_error(png_ptr,"png_read_read_func failed");
    }
}

static void png_data_read(png_structp png_ptr, my_png_buffer *png_buff) {
    png_set_read_fn(png_ptr, (png_voidp) png_buff,
                    (png_rw_ptr)png_data_read_func);
}

/*
 * png write
 */

void
png_data_write_func(png_structp png_ptr, png_bytep buf, png_size_t size) {
    my_png_buffer *png_buff = (my_png_buffer *)png_get_io_ptr(png_ptr);
    unsigned long new_data_len;
    unsigned char *tmp;
    if (png_buff->data_offset + size > png_buff->data_len) {
        new_data_len = 2 * png_buff->data_len;
        if (png_buff->data_offset + size > new_data_len) {
            new_data_len = png_buff->data_offset + size;
        }
        tmp = realloc(png_buff->data, new_data_len);
        if (tmp == NULL) {
            fprintf(stderr, "png_data_write_func: can't realloc: new_data_len(%lu), data_len(%lu)\n",
                    new_data_len, png_buff->data_len);
            png_error(png_ptr,"png_data_write_func failed");
        }
        png_buff->data = tmp;
        png_buff->data_len = new_data_len;
    }
    memcpy(png_buff->data + png_buff->data_offset, buf, size);
    png_buff->data_offset += size;
}

void
png_data_write(png_structp png_ptr, my_png_buffer *png_buff) {
    png_set_write_fn(png_ptr, (png_voidp) png_buff,
                     (png_rw_ptr)png_data_write_func, NULL);
}

/*
 *
 */

void *
pngconv_png2lossless(unsigned char *png_data, unsigned long png_data_len,
                     int *tag_no, int *format,
                     unsigned short *width, unsigned short *height,
                     void **colormap, int *colormap_count, int rgb15) {
    volatile png_structp png_ptr = NULL;
    volatile png_infop png_info_ptr = NULL;
    my_png_buffer png_buff;
    int bpp, color_type;
    png_uint_32 png_width = 0, png_height = 0;
    volatile png_bytepp png_image_data = NULL;
    register png_uint_32 x, y;
    void *image_data = NULL;
    png_color *palette = NULL;
    int palette_num = 0;
    png_bytep trans = NULL;
    int num_trans = 0;
    png_color_16p trans_values = NULL;

    if (png_data == NULL) {
        fprintf(stderr, "pngconv_png2lossless: png_data == NULL\n");
        return NULL;
    }
    if (png_sig_cmp((png_bytep)png_data, 0, 8)) { // bad signature
        fprintf(stderr, "pngconv_png2lossless: is not PNG!\n");
        return NULL;
    }
    png_ptr = png_create_read_struct
        (PNG_LIBPNG_VER_STRING, NULL,NULL,NULL);
    if (! png_ptr) {
        fprintf(stderr, "pngconv_png2lossless: can't create read_struct\n");
        return NULL;
    }
    if (setjmp(png_jmpbuf(png_ptr))) {
        fprintf(stderr, "pngconv_png2lossless: libpng error jump occured\n");
        png_destroy_read_struct((png_structpp) &png_ptr,
                                (png_infopp) &png_info_ptr, NULL);
        if (png_image_data) {
            for (y=0 ; y < png_height ; y++) {
                free(png_image_data[y]);
            }
            free(png_image_data);
        }
        return NULL;
    }
    png_info_ptr = png_create_info_struct(png_ptr);
    if (! png_info_ptr) {
        fprintf(stderr, "pngconv_png2lossless: can't create info_struct\n");
        png_destroy_read_struct ((png_structpp)&png_ptr, NULL, NULL);
        return NULL;
    }
    png_buff.data = png_data;
    png_buff.data_len = png_data_len;
    png_buff.data_offset = 0;

    png_data_read(png_ptr, &png_buff);
    png_read_info(png_ptr, png_info_ptr);
    png_get_IHDR(png_ptr, png_info_ptr,
                 &png_width, &png_height, &bpp, &color_type,
                 NULL, NULL, NULL);
    *width = (unsigned short) png_width;
    *height = (unsigned short) png_height;

    if ((rgb15 > 0) && (color_type !=  PNG_COLOR_TYPE_RGB)) { // warning
        fprintf(stderr, "rgb15 is %d but color_type is not PNG24\n", rgb15);
    }

    switch(color_type) {
    case PNG_COLOR_TYPE_PALETTE:
        *format = 3;
        png_get_PLTE(png_ptr, png_info_ptr, &palette, &palette_num);
        if (png_get_tRNS(png_ptr, png_info_ptr, &trans, &num_trans,
                         &trans_values) && (num_trans > 0)) {
            *tag_no = 36; // DefineBitsLossless2
        } else {
            *tag_no = 20; // DefineBitsLossless
        }
        break;
    case PNG_COLOR_TYPE_RGB:
        if (rgb15 > 0) {
            *format = 4;
        } else {
            *format = 5;
        }
        *tag_no = 20; /* DefineBitsLossless */
        break;
    case PNG_COLOR_TYPE_RGB_ALPHA:
        *format = 5;
        *tag_no = 36; /* DefineBitsLossless2 */
        if (png_get_valid(png_ptr, png_info_ptr, PNG_INFO_tRNS))
            png_set_tRNS_to_alpha(png_ptr);
        break;
    default:
        fprintf(stderr, "pngconv_png2lossless: color_type=%d not implemented yet.\n", color_type);
        png_destroy_read_struct((png_structpp)&png_ptr,
                                (png_infopp)&png_info_ptr, NULL);
        return NULL;
    }
    if (bpp > 8) {
        fprintf(stderr, "pngconv_png2lossless: bpp=%d not implemented yet. accept only bpp <= 8\n", bpp);
        png_destroy_read_struct((png_structpp)&png_ptr,
                                (png_infopp)&png_info_ptr, NULL);
        return NULL;
    }
    
    png_image_data = (png_bytepp) malloc(png_height * sizeof(png_bytep));
    for (y=0 ; y < png_height ; y++) {
        png_image_data[y] = (png_bytep) malloc(png_get_rowbytes(png_ptr, png_info_ptr));
    }
    png_read_image(png_ptr, png_image_data);
    /*
     * image copy
     */
    if (color_type == PNG_COLOR_TYPE_PALETTE) {
        register int i;
        unsigned char *indices_data;
        *colormap_count = palette_num;
        if (num_trans == 0) {
            swf_rgb_t *result_colormap = malloc(sizeof(swf_rgb_t) * palette_num);   // Lossless
            for (i=0 ; i < palette_num ; i++) {
                result_colormap[i].red   = palette[i].red;
                result_colormap[i].green = palette[i].green;
                result_colormap[i].blue  = palette[i].blue;
            }
            *colormap = result_colormap;
        } else {
              swf_rgba_t *result_colormap = malloc(sizeof(swf_rgba_t) * palette_num);   // Lossless2
            for (i=0 ; i < palette_num ; i++) {
                if (i < num_trans) {
                    int alpha_value = trans[i];
                    result_colormap[i].red   = palette[i].red   * alpha_value / 0xff;
                    result_colormap[i].green = palette[i].green * alpha_value / 0xff;
                    result_colormap[i].blue  = palette[i].blue  * alpha_value / 0xff;
                    result_colormap[i].alpha = alpha_value;
                } else {
                    result_colormap[i].red   = palette[i].red;
                    result_colormap[i].green = palette[i].green;
                    result_colormap[i].blue  = palette[i].blue;
                    result_colormap[i].alpha = 0xff; // opaque
                }
            }
            *colormap = result_colormap;
        }
        indices_data = malloc(((png_width+ 3) & -4) * png_height);
        i = 0;
        for (y=0 ; y < png_height ; y++) {
            bitstream_t *bs = bitstream_open();
            if (bs == NULL) {
                free(*colormap);
                *colormap = NULL;
                free(indices_data);
                for (y=0 ; y < png_height ; y++) {
                    free(png_image_data[y]);
                }
                free(png_image_data);
                return NULL;
            }
            bitstream_input(bs, png_image_data[y], png_width);
            for (x=0 ; x < png_width ; x++) {
                indices_data[i] = bitstream_getbits(bs, bpp);
                i++;
            }
            while (i % 4) { i++; } // 4byte alignment
            bitstream_close(bs);
        }
        image_data = indices_data;
    } else if (color_type == PNG_COLOR_TYPE_RGB) {
        swf_xrgb_t *xrgb_list;
        xrgb_list = malloc(sizeof(swf_xrgb_t) * png_width * png_height);
        for (y=0 ; y < png_height ; y++) {
            for (x=0 ; x < png_width ; x++) {
                xrgb_list[x+y*png_width].red   = png_image_data[y][3*x + 0];
                xrgb_list[x+y*png_width].green = png_image_data[y][3*x + 1];
                xrgb_list[x+y*png_width].blue  = png_image_data[y][3*x + 2];
            }
        }
        image_data = xrgb_list;
    } else { // PNG_COLOR_TYPE_RGB_ALPHA
        swf_argb_t *argb_list;
        argb_list = malloc(sizeof(swf_argb_t) * png_width * png_height);
        for (y=0 ; y < png_height ; y++) {
            for (x=0 ; x < png_width ; x++) {
                int alpha_value = png_image_data[y][4*x + 3];
                argb_list[x+y*png_width].red   = png_image_data[y][4*x + 0] * alpha_value / 0xff;
                argb_list[x+y*png_width].green = png_image_data[y][4*x + 1] * alpha_value / 0xff;
                argb_list[x+y*png_width].blue  = png_image_data[y][4*x + 2] * alpha_value / 0xff;
                argb_list[x+y*png_width].alpha = alpha_value;
            }
        }
        image_data = argb_list;
    }
    for (y=0 ; y < png_height ; y++) {
        free(png_image_data[y]);
    }
    free(png_image_data);
    /*
     * destruct
     */
    png_destroy_read_struct((png_structpp) &png_ptr,
                            (png_infopp) &png_info_ptr, NULL);
    return image_data;
}

unsigned char *
pngconv_lossless2png(void *image_data,
                     unsigned short width, unsigned short height,
                     void *index_data,
                     unsigned short index_data_count,
                     int tag_no, int format,
                     unsigned long *length) {
    volatile png_structp png_ptr = NULL;
    volatile png_infop png_info_ptr = NULL;
    volatile my_png_buffer png_buff;
    png_uint_32 png_width = 0, png_height = 0;
    int bpp, color_type;
    volatile png_bytepp png_image_data = NULL;
    png_uint_32 x, y;
    volatile png_colorp png_palette = NULL;
    if (image_data == NULL) {
        fprintf(stderr, "pngconv_lossless2png: image_data == NULL\n");
        return NULL;
    }
    if ((format != 3) && (format != 5)) {
        fprintf(stderr, "jpegconv_lossless2png: format=%d not implemented yes.\n", format);
        return NULL;
    }
    png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL,NULL,NULL);
    if (! png_ptr) {
        fprintf(stderr, "jpegconv_lossless2png: can't create write_struct\n");
        return NULL;
    }
    if (setjmp(png_jmpbuf(png_ptr))) {
        fprintf(stderr, "pngconv_lossless2png: libpng error jump occured\n");
        free(png_palette);
        if (png_image_data) {
            for (y=0 ; y < png_height ; y++) {
                free(png_image_data[y]);
            }
            free(png_image_data);
        }
        free(png_buff.data);
        png_destroy_write_struct((png_structpp) &png_ptr,
                                 (png_infopp) &png_info_ptr);
        return NULL;
    }
    png_info_ptr = png_create_info_struct(png_ptr);
    if (! png_info_ptr) {
        fprintf(stderr, "jpegconv_lossless2png: can't create info_struct\n");
        png_destroy_write_struct((png_structpp) &png_ptr, NULL);
        return NULL;
    }
    //
    png_width = width;
    png_height = height;
    bpp = 8;
    if (format == 3) {
        color_type =  PNG_COLOR_TYPE_PALETTE;
    } else if (tag_no == 20) { /* DefineBitsLossless */
        color_type = PNG_COLOR_TYPE_RGB;
    } else if (tag_no == 36) { /* DefineBitsLossless2 */
        color_type = PNG_COLOR_TYPE_RGB_ALPHA;
    } else {
        fprintf(stderr, "jpegconv_lossless2png: format!=3 and tag_no=%d not implemented.\n",
                tag_no);
        png_destroy_write_struct((png_structpp) &png_ptr,
                                 (png_infopp) &png_info_ptr);
        return NULL;
    }
    png_set_filter(png_ptr, 0, PNG_ALL_FILTERS);
    png_set_IHDR(png_ptr, png_info_ptr,
                 png_width, png_height, bpp, color_type,
                 PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT,
                 PNG_FILTER_TYPE_DEFAULT);
    if (format == 3) {
        register int i;
        if (index_data_count == 0) {
            fprintf(stderr, "jpegconv_lossless2png: index_data_count == 0 at line(%d)\n", __LINE__);
            png_destroy_write_struct((png_structpp) &png_ptr,
                                     (png_infopp) &png_info_ptr);
            return NULL;
        }
        png_palette = (png_colorp) malloc(sizeof(png_color)*index_data_count);
        png_set_packing(png_ptr);
        if (tag_no == 20) {
            swf_rgb_t *rgb_list  = index_data;
            for (i=0 ; i < index_data_count ; i++) {
                png_palette[i].red   = rgb_list[i].red;
                png_palette[i].green = rgb_list[i].green;
                png_palette[i].blue  = rgb_list[i].blue;
            }
        } else {
            swf_rgba_t *rgba_list  = index_data;
            png_bytep trans = NULL;
            int num_trans = 0;
            png_color_16p trans_values = NULL;
            for (i=0 ; i < index_data_count ; i++) {
                png_palette[i].red   = rgba_list[i].red;
                png_palette[i].green = rgba_list[i].green;
                png_palette[i].blue  = rgba_list[i].blue;
            }
            // scanning to end of transparent pixel
            for (i = index_data_count - 1 ; 0 <= i ; i--) {
                if (rgba_list[i].alpha < 254) { // 254 XXX
                    break;
                }
            }
            num_trans = i + 1;
            if (num_trans > 0) {
                trans = malloc(num_trans);
                for (i = 0 ; i < num_trans ; i++) {
                    trans[i] = rgba_list[i].alpha;
                }
                png_set_tRNS(png_ptr, png_info_ptr, trans, num_trans,
                             trans_values);
                free(trans);
            }

        }
        png_set_PLTE( png_ptr, png_info_ptr, png_palette, index_data_count);
        free(png_palette);
    }
    png_image_data = (png_bytepp) malloc(png_height * sizeof(png_bytep));
    if (color_type == PNG_COLOR_TYPE_PALETTE) {
        for (y=0 ; y < png_height ; y++) {
            png_image_data[y] = (png_bytep) malloc(png_get_rowbytes(png_ptr, png_info_ptr));
            for (x=0 ; x < png_width ; x++) {
                unsigned char *data = image_data;
                png_image_data[y][x] = data[x + y*((png_width +3) & -4)];
            }
        }
        
    } else if (color_type == PNG_COLOR_TYPE_RGB) {
        swf_xrgb_t *xrgb_list = image_data;
        for (y=0 ; y < png_height ; y++) {
            png_image_data[y] = (png_bytep) malloc(png_get_rowbytes(png_ptr, png_info_ptr));
            for (x=0 ; x < png_width ; x++) {
                png_image_data[y][3*x]   =  xrgb_list[x+y*png_width].red;
                png_image_data[y][3*x+1] =  xrgb_list[x+y*png_width].green;
                png_image_data[y][3*x+2] =  xrgb_list[x+y*png_width].blue;
            }
        }
    } else {
        swf_argb_t *argb_list = image_data;
        for (y=0 ; y < png_height ; y++) {
            png_image_data[y] = (png_bytep) malloc(png_get_rowbytes(png_ptr, png_info_ptr));
            for (x=0 ; x < png_width ; x++) {
                png_image_data[y][4*x]   = argb_list[x+y*png_width].red;
                png_image_data[y][4*x+1] = argb_list[x+y*png_width].green;
                png_image_data[y][4*x+2] = argb_list[x+y*png_width].blue;
                png_image_data[y][4*x+3] = argb_list[x+y*png_width].alpha;
            }
        }
        
    }
    png_buff.data = NULL;
    png_buff.data_len = 0;
    png_buff.data_offset = 0;
    png_data_write((png_structp) png_ptr, (my_png_buffer*) &png_buff);

    png_write_info(png_ptr, png_info_ptr);
    png_write_image(png_ptr, png_image_data);
    png_write_end(png_ptr, png_info_ptr);
    //
    for (y=0 ; y < png_height ; y++) {
        free(png_image_data[y]);
    }
    free(png_image_data);
    png_destroy_write_struct((png_structpp) &png_ptr,
                             (png_infopp) &png_info_ptr);
    *length = png_buff.data_offset;
    return png_buff.data;
}

#endif /* HAVE_PNG */
