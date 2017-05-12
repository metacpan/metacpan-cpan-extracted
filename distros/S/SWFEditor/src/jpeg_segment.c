/*
  ref code) http://diary.awm.jp/~yoya/data/2008/02/03/jpegdump.phps
  
  gcc -W -Wall -D__JPEG_SEGMENT_DEBUG__ jpeg_segment.c  bitstream.c
*/

#include <stdio.h>
#include <stdlib.h>
#include "swf_define.h"
#include "bitstream.h"
#include "jpeg_segment.h"

typedef struct jpeg_marker_name_ {
    int marker;
    char *name;
} jpeg_marker_name_t;

jpeg_marker_name_t jpeg_marker_name_table[] = {
    {0xD8, "SOI"},
    {0xE0, "APP0"}, {0xE1, "APP1"}, {0xE2, "APP2"}, {0xE3, "APP3"},
    {0xE4, "APP4"}, {0xE5, "APP5"}, {0xE6, "APP6"}, {0xE7, "APP7"},
    {0xE8, "APP8"}, {0xE9, "APP9"}, {0xEA, "APP10"},{0xEB, "APP11"},
    {0xEC, "APP12"},{0xED, "APP13"},{0xEE, "APP14"},{0xEF, "APP15"},
    {0xFE, "COM"},
    {0xDB, "DQT"},
    {0xC0, "SOF0"}, {0xC1, "SOF1"}, {0xC2, "SOF2"}, {0xC3, "SOF3"},
                    {0xC5, "SOF5"}, {0xC6, "SOF6"}, {0xC7, "SOF7"},
    {0xC8, "JPG"},  {0xC9, "SOF9"}, {0xCA, "SOF10"},{0xCB, "SOF11"},
    {0xCC, "DAC"},  {0xCD, "SOF13"},{0xCE, "SOF14"},{0xCF, "SOF15"},
    {0xC4, "DHT"},
    {0xDA, "SOS"},
    {0xD0, "RST0"}, {0xD1, "RST1"}, {0xD2, "RST2"}, {0xD3, "RST3"},
    {0xD4, "RST4"}, {0xD5, "RST5"}, {0xD6, "RST6"}, {0xD7, "RST7"},
    {0xDD, "DRI"},
    {0xD9, "EOI"},
    {0xDC, "DNL"}, {0xDE, "DHP"},  {0xDF, "EXP"},
    {0xF0, "JPG0"}, {0xF1, "JPG1"}, {0xF2, "JPG2"}, {0xF3, "JPG3"},
    {0xF4, "JPG4"}, {0xF5, "JPG5"}, {0xF6, "JPG6"}, {0xF7, "JPG7"},
    {0xF8, "JPG8"}, {0xF9, "JPG9"}, {0xFA, "JPG10"},{0xFB, "JPG11"},
    {0xFC, "JPG12"},{0xFD, "JPG13"},
};

#define NumOfTable(t) (sizeof(t) / sizeof(*t))
     
char *jpeg_segment_get_marker_name(int marker) {
    int i, marker_name_num = NumOfTable(jpeg_marker_name_table);
    for (i=0 ; i < marker_name_num ; i++) {
        if (marker == jpeg_marker_name_table[i].marker) {
            return jpeg_marker_name_table[i].name;
        }
    }
    return "Unknown";
}

jpeg_segment_t *jpeg_segment_create(void) {
    jpeg_segment_t *jpeg_seg = calloc(sizeof(*jpeg_seg), 1);
    if (jpeg_seg == NULL) {
        fprintf(stderr, "jpeg_segment_create: Can't alloc memory\n");
        return NULL;
    }
    jpeg_seg->head = NULL;
    jpeg_seg->tail = NULL;
    return jpeg_seg;
}

void jpeg_segment_append(jpeg_segment_t *jpeg_seg,
                         int marker,
                         unsigned char *data_ref, unsigned long data_len) {
    jpeg_segment_node_t *node = jpeg_seg->head;
    jpeg_segment_node_t *new_node;
    new_node = calloc(sizeof(*node), 1);
    if (new_node == NULL) {
        fprintf(stderr, "jpeg_segment_append: jpeg_segment_create failed\n");
        return ;
    }
    if (jpeg_seg->head == NULL) {
        jpeg_seg->head = new_node;
    } else {
        jpeg_seg->tail->next = new_node;
    }
    jpeg_seg->tail = new_node;
    new_node->marker = marker;
    new_node->data_ref = data_ref;
    new_node->data_len = data_len;
    return ;
}

jpeg_segment_t *jpeg_segment_parse(unsigned char *data,	
                                   unsigned long data_len,
                                   int rst_scan) {
    bitstream_t *bs;
    jpeg_segment_t *jpeg_seg;
    int marker1;
    unsigned len;
    int eoi_found = 0;
    bs = bitstream_open();
    bitstream_input(bs, data, data_len);
    jpeg_seg = jpeg_segment_create();
    
    while((marker1 = bitstream_getbyte(bs)) >= 0) {
        int marker2;
        int next_marker2;
        if (marker1 != 0xFF) {
            if (eoi_found) {
                break;
            }
            fprintf(stderr, "jpeg_segment_parse: marker1=0x%02X\n", marker1);
            jpeg_segment_destroy(jpeg_seg);
            bitstream_close(bs);
            return NULL;
        }
        marker2 = bitstream_getbyte(bs);
        switch(marker2) {
            unsigned long sos_offset;
          case -1:
              /* removed segment */
              break;
          case 0xD8: // SOI (Start of Image)
            jpeg_segment_append(jpeg_seg, marker2, NULL, 0);
            break;
          case 0xD9: // EOI (End of Image)
            jpeg_segment_append(jpeg_seg, marker2, NULL, 0);
            eoi_found = 1;
            break;
          case 0xDA: // SOS
	    if ((! rst_scan) && (data[data_len - 2] == 0xFF) &&
		(data[data_len - 1] == 0xD9)) {
	      int sos_len;
              sos_offset = bitstream_getbytepos(bs);
	      sos_len = data_len - sos_offset - 2;
	      jpeg_segment_append(jpeg_seg, marker2, data + sos_offset,
				  sos_len);
	      bitstream_incrpos(bs, sos_len, 0);
	      marker1 = bitstream_getbyte(bs);
	      marker2 = bitstream_getbyte(bs);
	      jpeg_segment_append(jpeg_seg, marker2, NULL, 0); // EOI
	      break;
	    }
	    // no break;
          case 0xD0: case 0xD1: case 0xD2: case 0xD3: // RST
          case 0xD4: case 0xD5: case 0xD6: case 0xD7: // RST
              sos_offset = bitstream_getbytepos(bs);
              while((marker1 = bitstream_getbyte(bs)) >= 0) {
                  if (marker1 != 0xFF) {
                      continue;
                  }
                  next_marker2 = bitstream_getbyte(bs);
                  if (next_marker2 == 0x00) {
                      continue;
                  }
                  bitstream_incrpos(bs, -2, 0);
                  jpeg_segment_append(jpeg_seg, marker2, data + sos_offset,
                                      bitstream_getbytepos(bs) - sos_offset);
                  break;
              }
              break;
          default:
              len = bitstream_getbytesBE(bs, 2) - 2;
              jpeg_segment_append(jpeg_seg, marker2,
                                  data + bitstream_getbytepos(bs),
                                  len);
              bitstream_incrpos(bs, len, 0);
              break;
        }
    }
    bitstream_close(bs);
    return jpeg_seg;
}

int jpeg_segment_contain(jpeg_segment_t *jpeg_seg, int marker) {
    jpeg_segment_node_t *node;
    for (node=jpeg_seg->head ; node ; node=node->next) {
        if (node->marker == marker) {
            return 1;
        }            
    }
    return 0;
}

unsigned char *jpeg_segment_steal_node(jpeg_segment_t *jpeg_seg,
                                       int marker,
                                       unsigned long *length) {
    jpeg_segment_node_t *node;
    unsigned char *data;
    *length = 0;
    for (node=jpeg_seg->head ; node ; node=node->next) {
        if (node->marker == marker) {
            data = node->data_ref;
            *length = node->data_len;
            node->marker = -1; // remove mark;
            node->data_ref = NULL;
            node->data_len = 0;
            return data;
        }
    }
    return NULL;
}

int
jpeg_segment_delete_node(jpeg_segment_t *jpeg_seg, int marker) {
    jpeg_segment_node_t *node;
    int count = 0;
    for (node=jpeg_seg->head ; node ; node=node->next) {
        if (node->marker == marker) {
            node->marker = -1; // remove mark;
            node->data_ref = NULL;
            node->data_len = 0;
            count ++;
        }
    }
    return count;
}

int
jpeg_segment_peek_marker(jpeg_segment_t *jpeg_seg) {
    jpeg_segment_node_t *node;
    for (node=jpeg_seg->head ; node ; node=node->next) {
        if (node->marker != -1) {
            return node->marker;
        }     
    }
    return -1;
}

void
jpeg_segment_print(jpeg_segment_t *jpeg_seg) {
    int i;
    jpeg_segment_node_t *node;
    if (jpeg_seg == NULL) {
        fprintf(stderr, "jpeg_segment_print: jpeg_seg == NULL\n");
        return ;
    }
    node = jpeg_seg->head;
    for (i=0 ; node ; i++) {
        char *marker_name;
        if (node->marker >= 0) {
            marker_name = jpeg_segment_get_marker_name(node->marker);
            printf("(%d) marker=%s(FF%02X): length=%lu\n",
                   i, marker_name?marker_name:"Unknown",
                   node->marker, node->data_len);
        }
        node = node->next;
    }
}

unsigned char *
jpeg_segment_output(jpeg_segment_t *jpeg_seg, unsigned long *length) {
    bitstream_t *bs;
    unsigned char *data;
    jpeg_segment_node_t *node;
    *length = 0;
    node = jpeg_seg->head;
    bs = bitstream_open();
    for (; node ; node=node->next) {
        int marker2 = node->marker;
        if (marker2 == -1) {
            continue;
        }
        bitstream_putbyte(bs, 0xFF); // marker1
        bitstream_putbyte(bs, marker2); // marker2
        switch(marker2) {
          case 0xD8: // SOI (Start of Image)
          case 0xD9: // EOI (End of Image)
              /* nothing to do */
            break;
          default:
              bitstream_putbytesBE(bs, node->data_len + 2, 2);
              /* no break */
          case 0xDA: // SOS
          case 0xD0: case 0xD1: case 0xD2: case 0xD3: // RST
          case 0xD4: case 0xD5: case 0xD6: case 0xD7: // RST
              bitstream_putstring(bs, node->data_ref, node->data_len);
              break;
        }
    }
    data = bitstream_steal(bs, length);
    bitstream_close(bs);
    return data;
}

void jpeg_segment_destroy(jpeg_segment_t *jpeg_seg) {
    jpeg_segment_node_t *node, *next_node;
    if (jpeg_seg == NULL) {
        return ;
    }
    node = jpeg_seg->head;
    while(node) {
        next_node = node->next;
        /* node->data_ref  no free!! */
        free(node);
        node = next_node;
    }
    free(jpeg_seg);
}

#ifdef __JPEG_SEGMENT_DEBUG__  /* for component debug */

#include <sys/stat.h>

int main(int argc, char **argv) {
    char *filename;
    struct stat sbuf;
    FILE *fp, *fp_out = NULL;
    unsigned char *data, *output_data;
    unsigned long data_len, output_data_len;
    jpeg_segment_t *jpeg_seg;
    if ((argc != 2) && (argc != 3)) {
        fprintf(stderr, "Usage: %s <jpeg_infile> [<jpeg_outfile>]\n", argv[0]);
        return EXIT_FAILURE;
    }
    filename = argv[1];
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
    jpeg_seg = jpeg_segment_parse(data, data_len, 1);
    jpeg_segment_print(jpeg_seg);
    if (argc == 3) {
        fp_out = fopen(argv[2], "wb");
        if (fp_out == NULL) {
            fprintf(stderr, "Can't open outfile(%s)\n", argv[2]);
            return EXIT_FAILURE;
        }
        output_data = jpeg_segment_output(jpeg_seg, &output_data_len);
        fwrite(output_data, output_data_len, 1, fp_out);
        fclose(fp_out);
        free(output_data);
    }
    jpeg_segment_destroy(jpeg_seg);
    free(data);
    return EXIT_SUCCESS;
}

#endif /* __JPEG_SEGMENT_DEBUG__ */
