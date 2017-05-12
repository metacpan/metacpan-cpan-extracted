#!perl -T

use Test::More tests => 4;

use Scalar::IfDefined qw/lifdef/;

is((scalar lifdef { $_ + 1 } 1) , 2);
is((scalar lifdef { $_ + 1 } undef) , undef);
is_deeply([ lifdef { $_ } 1 ], [ 1 ]);
is_deeply([ lifdef { $_ } undef ], []);
