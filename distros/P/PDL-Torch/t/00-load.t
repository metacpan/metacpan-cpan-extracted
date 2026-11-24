use strict;
use warnings;
use Test::More;

use_ok('PDL::Torch', qw(pdl2torch_type torch2pdl_type cuda_available));

is(torch2pdl_type('float64'),    'double',   'float64 -> double');
is(torch2pdl_type('float32'),    'float',    'float32 -> float');
is(torch2pdl_type('int32'),      'long',     'int32 -> long');
is(torch2pdl_type('int64'),      'longlong', 'int64 -> longlong');
is(torch2pdl_type('complex64'),  'cfloat',   'complex64 -> cfloat');
is(torch2pdl_type('complex128'), 'cdouble',  'complex128 -> cdouble');

is(pdl2torch_type('double'),   'float64',    'double -> float64');
is(pdl2torch_type('cfloat'),   'complex64',  'cfloat -> complex64');
is(pdl2torch_type('cdouble'),  'complex128', 'cdouble -> complex128');

my $cuda = cuda_available();
ok($cuda == 0 || $cuda == 1, 'cuda_available returns boolean (' . $cuda . ')');

done_testing();
