/*
  gcc -W -Wall -D__BITMAP_UTIL_DEBUG__ bitmap_util.c jpeg_segment.c bitstream.c
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h> // strncmp
#include "jpeg_segment.h"
#include "bitmap_util.h"

#define isJPEG_DHT(c) ((c) == 0xC4)
#define isJPEG_JPG(c) ((c) == 0xC8)
#define isJPEG_DAC(c) ((c) == 0xCC)

#define isJPEG_SOFXX(c) ((0xC0 <= c) && (c <= 0xCF) && (!isJPEG_DHT(c)) && (!isJPEG_JPG(c)) && (!isJPEG_DAC(c)))

int jpeg_size_segment(jpeg_segment_t *jpeg_seg, int *width, int *height) {
    jpeg_segment_node_t *node;
    for (node = jpeg_seg->head ; node ; node = node->next) {
        register int marker = node->marker;
        if (isJPEG_SOFXX(marker)) {
            *width  = 0x100 * node->data_ref[3] + node->data_ref[4];
            *height = 0x100 * node->data_ref[1] + node->data_ref[2];
            return 0; // found
        }
    }
    return 1; // not found
}

int jpeg_size(unsigned char *data, unsigned long data_len,
              int *width, int *height) {
    unsigned int idx, chunk_length = 0;
    int marker1, marker2;
    for (idx = 0 ; ((idx + 8) < data_len) && ((marker1 = data[idx]) == 0xFF);
         idx += chunk_length) {
        marker2 = data[idx + 1];
        switch (marker2) {
          case 0xD8: // SOI (Start of Image)
          case 0xD9: // EOI (End of Image)
              chunk_length = 2;
              break;
          case 0xDA: // SOS
              return 1; // not found
          default:
            if (isJPEG_SOFXX(marker2)) {
                *width  = 0x100 * data[idx + 7] + data[idx + 8];
                *height = 0x100 * data[idx + 5] + data[idx + 6];
                return 0; // success
            }
            chunk_length = 0x100 * data[idx + 2] + data[idx + 3] + 2;
            break;
        }
        if (chunk_length == 0) { // fail safe;
            break;
        }
    }
    return 1; // ng
}

int
png_size(unsigned char *data, unsigned long data_len,
         int *width, int *height) {
    if (data_len < 24) {
        fprintf(stderr, "png_size: data_len(%lu) < 16\n", data_len);
        return 1;
    }
    *width = (((data[16]*0x100) + data[17])*0x100 + data[18])*0x100 + data[19];
    *height =(((data[20]*0x100) + data[21])*0x100 + data[22])*0x100 + data[23];
    return 0;
}

int
gif_size(unsigned char *data, unsigned long data_len,
                    int *width, int *height) {
    if (data_len < 10) {
        fprintf(stderr, "gif_size: data_len(%lu) < 10\n", data_len);
        return 1;
    }
    *width  = 0x100 * data[7] + data[6];
    *height = 0x100 * data[9] + data[8];
    return 0;
}

int
detect_bitmap_format(unsigned char *data, unsigned long data_len) {
    if (data_len < 4) {
        return BITMAP_UTIL_FORMAT_UNKNOWN; // too short
    }
    if (strncmp((const char*)data, "\xff\xd8\xff", 3) == 0) {
        return BITMAP_UTIL_FORMAT_JPEG;
    } else if (strncmp((const char*)data + 1, "PNG", 3) == 0) {
        return BITMAP_UTIL_FORMAT_PNG;
    } else if (strncmp((const char*)data, "GIF", 3) == 0) {
        return BITMAP_UTIL_FORMAT_GIF;
    }
    return BITMAP_UTIL_FORMAT_UNKNOWN;
}

int
bitmap_size(unsigned char *data, unsigned long data_len,
                    int *width, int *height) {
    int format = detect_bitmap_format(data, data_len);
    switch (format) {
    case BITMAP_UTIL_FORMAT_JPEG:
        return jpeg_size(data, data_len, width, height);
    case BITMAP_UTIL_FORMAT_PNG:
        return png_size(data, data_len, width, height);
    case BITMAP_UTIL_FORMAT_GIF:
        return gif_size(data, data_len, width, height);
    }
    fprintf(stderr, "bitmap_size: illegal format\n");
    return 1;
}


#ifdef __BITMAP_UTIL_DEBUG__  /* for component debug */

#include <sys/stat.h>

int main(int argc, char **argv) {
    char *filename;
    struct stat sbuf;
    FILE *fp = NULL;
    unsigned char *data;
    unsigned long data_len;
    int width = 0, height = 0;
    int ret;
    int i;
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <bitmap_file> [<bitmap_file2> [...]]\n", argv[0]);
        return EXIT_FAILURE;
    }
    for (i = 1 ; i < argc ; i++) {
        int bitmap_format;
        filename = argv[i];
        if (stat(filename, &sbuf)) {
            fprintf(stderr, "Can't stat file(%s)\n", filename);
            return EXIT_FAILURE;
        }
        data_len = sbuf.st_size;
        fp = fopen(filename, "rb");
        if (fp == NULL) {
            fprintf(stderr, "Can't open infile(%s)\n", filename);
            return EXIT_FAILURE;
        }
        data = malloc(data_len);
        if (fread(data, 1, data_len, fp) != data_len) {
            fclose(fp);
            return 1;
        }
        fclose(fp);
        bitmap_format = detect_bitmap_format(data, data_len);
        switch (bitmap_format) {
        case BITMAP_UTIL_FORMAT_JPEG:
            printf("JPEG\n");
            ret = jpeg_size(data, data_len, &width, &height);
            break;
        case BITMAP_UTIL_FORMAT_PNG:
            printf("PNG\n");
            ret = png_size(data, data_len, &width, &height);
            break;
        case BITMAP_UTIL_FORMAT_GIF:
            printf("GIF\n");
            ret = gif_size(data, data_len, &width, &height);
            break;
        default:
            fprintf(stderr, "unknown format (%s)\n", filename);
            exit(0);
        }
        free(data);
        if (ret) {
            fprintf(stderr, "Can't get bitmap size(%s)\n", filename);
            return EXIT_FAILURE;
        }
        printf("width=%d height=%d\n", width, height);
    }
    return EXIT_SUCCESS;
}

#endif /* __BITMAP_UTIL_DEBUG__ */
