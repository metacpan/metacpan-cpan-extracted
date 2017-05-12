use strict;
use warnings FATAL => 'all';
use lib 't/lib';

use Std;

check_test(
    sub { cmp_deeply('Foo', isa('Foo')) },
    {
        actual_ok => 0,
        diag => <<EOM,
Checking class of \$data with isa()
   got : 'Foo'
expect : blessed into or ref of type 'Foo'
EOM
    },
    'isa on a string'
);



