use strict;
use warnings;

use Test::More tests => 6;
use Scalar::Util qw(blessed reftype looks_like_number);

BEGIN { use_ok('Shared::Simple') }

my $obj = Shared::Simple->new('testshm', Shared::Simple::EXCLUSIVE);

ok(defined $obj,                          'new() returns a value');
is(blessed($obj), 'Shared::Simple',       'object is blessed into Shared::Simple');
is(reftype($obj), 'SCALAR',               'object is a scalar ref (opaque pointer)');
ok(looks_like_number($$obj),              'inner value is a numeric pointer');
ok($$obj != 0,                            'pointer is non-null');
