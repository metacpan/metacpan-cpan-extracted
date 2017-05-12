/*
  +----------------------------------------------------------------------+
  | Author: yoya@awm.jp                                                  |
  +----------------------------------------------------------------------+
*/


#ifndef __JPEG_SEGMENT_H__
#define __JPEG_SEGMENT_H__

typedef struct jpeg_segment_node_ {
    int marker;
    unsigned char *data_ref; /* do NOT free! */
    unsigned long data_len;
    struct jpeg_segment_node_ *next;
} jpeg_segment_node_t;

typedef struct jpeg_segment_ {
    jpeg_segment_node_t *head, *tail;
} jpeg_segment_t;

extern jpeg_segment_t *jpeg_segment_create(void);

extern void jpeg_segment_append(jpeg_segment_t *jpeg_seg_head,
                                int marker,
                                unsigned char *data,
                                unsigned long data_len);

extern jpeg_segment_t *jpeg_segment_parse(unsigned char *data,
                                          unsigned long data_len,
                                          int rst_scan);

extern int jpeg_segment_contain(jpeg_segment_t *jpeg_seg, int marker);
extern unsigned char *jpeg_segment_steal_node(jpeg_segment_t *jpeg_seg,
                                              int marker,
                                              unsigned long *length);
extern int jpeg_segment_delete_node(jpeg_segment_t *jpeg_seg, int marker);
extern int jpeg_segment_peek_marker(jpeg_segment_t *jpeg_seg);

extern void jpeg_segment_print(jpeg_segment_t *jpeg_seg);
extern unsigned char *jpeg_segment_output(jpeg_segment_t *jpeg_seg,
                                          unsigned long *length);
extern void jpeg_segment_destroy(jpeg_segment_t *jpeg_seg);

extern char *jpeg_segment_get_marker_name(int marker);

#endif /* __JPEG_SEGMENT_H__ */
