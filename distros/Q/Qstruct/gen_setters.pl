#!/usr/bin/perl

use strict;

gen_setter('uint64', 'uint64_t', 'uint64', 'uint64_t');
gen_setter('int64', 'int64_t', 'uint64', 'uint64_t');
gen_setter('double', 'double', 'uint64', 'uint64_t');

gen_setter('uint32', 'uint32_t', 'uint32', 'uint32_t');
gen_setter('int32', 'int32_t', 'uint32', 'uint32_t');
gen_setter('float', 'float', 'uint32', 'uint32_t');

gen_setter('uint16', 'uint16_t', 'uint16', 'uint16_t');
gen_setter('int16', 'int16_t', 'uint16', 'uint16_t');

gen_setter('uint8', 'uint8_t', 'uint8', 'uint8_t');
gen_setter('int8', 'int8_t', 'uint8', 'uint8_t');


sub gen_setter {
  my ($real_type, $real_c_type, $storage_type, $storage_c_type) = @_;

  print <<END;

void
set_$real_type(self, body_index, byte_offset, value)
        Qstruct_Builder self
        uint32_t body_index
        uint32_t byte_offset
        $real_c_type value
    CODE:
        if (qstruct_builder_set_$storage_type(self, body_index, byte_offset, *(($storage_c_type *)&value))) croak("out of memory");

END

}
