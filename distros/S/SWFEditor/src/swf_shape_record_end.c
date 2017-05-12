#include <stdio.h>
#include "bitstream.h"
#include "swf_shape_record_end.h"

int
swf_shape_record_end_parse(bitstream_t *bs,
                           swf_shape_record_end_t *shape_record_end) {
    shape_record_end->shape_record_type = bitstream_getbit(bs);
    shape_record_end->end_of_shape = bitstream_getbits(bs, 5);
    return 0;
}

int
swf_shape_record_end_build(bitstream_t *bs,
                           swf_shape_record_end_t *shape_record_end) {
    bitstream_putbit(bs, shape_record_end->shape_record_type);
    bitstream_putbits(bs, shape_record_end->end_of_shape, 5);
    return 0;
}

int
swf_shape_record_end_print(int indent_depth) {
    print_indent(indent_depth);
    printf("end_of_shape\n");
    return 0;
}
