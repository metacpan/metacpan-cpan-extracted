#!/usr/bin/perl

use strict;

gen_getter('uint64', 'uint64_t', 'uint64', 'uint64_t');
gen_getter('int64', 'int64_t', 'uint64', 'uint64_t');
gen_getter('double', 'double', 'uint64', 'uint64_t');

gen_getter('uint32', 'uint32_t', 'uint32', 'uint32_t');
gen_getter('int32', 'int32_t', 'uint32', 'uint32_t');
gen_getter('float', 'float', 'uint32', 'uint32_t');

gen_getter('uint16', 'uint16_t', 'uint16', 'uint16_t');
gen_getter('int16', 'int16_t', 'uint16', 'uint16_t');

gen_getter('uint8', 'uint8_t', 'uint8', 'uint8_t');
gen_getter('int8', 'int8_t', 'uint8', 'uint8_t');


sub gen_getter {
  my ($real_type, $real_c_type, $storage_type, $storage_c_type) = @_;

  print <<END;

$real_c_type
get_$real_type(buf_sv, body_index, byte_offset)
        SV *buf_sv
        uint32_t body_index
        uint32_t byte_offset
    CODE:
        char *buf;
        size_t buf_size;
        $real_c_type output;
        int ret;

        if (!SvPOK(buf_sv)) croak("buf is not a string");
        buf_size = SvCUR(buf_sv);
        buf = SvPV(buf_sv, buf_size);

        ret = qstruct_get_$storage_type(buf, buf_size, body_index, byte_offset, ($storage_c_type *) &output);

        if (ret) croak("malformed qstruct");

        RETVAL = output;
    OUTPUT:
        RETVAL

END

}
