use strict;
use warnings;
use Test::More;

use_ok('PDL::IO::Protobuf', qw(rprotobuf wprotobuf from_protobuf to_protobuf pdl_type_for_proto_type));

is(pdl_type_for_proto_type('float'),    'float',     'float maps to PDL float');
is(pdl_type_for_proto_type('double'),   'double',    'double maps to PDL double');
is(pdl_type_for_proto_type('int32'),    'long',      'int32 maps to PDL long');
is(pdl_type_for_proto_type('uint32'),   'ulong',     'uint32 maps to PDL ulong');
is(pdl_type_for_proto_type('int64'),    'longlong',  'int64 maps to PDL longlong');
is(pdl_type_for_proto_type('uint64'),   'ulonglong', 'uint64 maps to PDL ulonglong');
is(pdl_type_for_proto_type('bool'),     'byte',      'bool maps to PDL byte');
is(pdl_type_for_proto_type('unknown'),  undef,       'unknown type returns undef');

done_testing();
