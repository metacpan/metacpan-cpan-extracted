use strict;
use warnings;
use Test::More;

use_ok(
    'PDL::IO::Arrow',
    qw(rarrow warrow rparquet wparquet arrow2pdl_type pdl2arrow_type)
);

is(arrow2pdl_type('float64'),    'double',    'float64 -> double');
is(arrow2pdl_type('float32'),    'float',     'float32 -> float');
is(arrow2pdl_type('int8'),       'sbyte',     'int8 -> sbyte');
is(arrow2pdl_type('uint8'),      'byte',      'uint8 -> byte');
is(arrow2pdl_type('int16'),      'short',     'int16 -> short');
is(arrow2pdl_type('uint16'),     'ushort',    'uint16 -> ushort');
is(arrow2pdl_type('int32'),      'long',      'int32 -> long');
is(arrow2pdl_type('uint32'),     'ulong',     'uint32 -> ulong');
is(arrow2pdl_type('int64'),      'longlong',  'int64 -> longlong');
is(arrow2pdl_type('uint64'),     'ulonglong', 'uint64 -> ulonglong');
is(arrow2pdl_type('bool'),       'byte',      'bool -> byte');
is(arrow2pdl_type('complex64'),  'cfloat',    'complex64 -> cfloat');
is(arrow2pdl_type('complex128'), 'cdouble',   'complex128 -> cdouble');

is(pdl2arrow_type('double'),  'float64',    'double -> float64');
is(pdl2arrow_type('float'),   'float32',    'float -> float32');
is(pdl2arrow_type('long'),    'int32',      'long -> int32');
is(pdl2arrow_type('cfloat'),  'complex64',  'cfloat -> complex64');
is(pdl2arrow_type('cdouble'), 'complex128', 'cdouble -> complex128');

done_testing();
