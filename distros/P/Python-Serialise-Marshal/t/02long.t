use strict;
use Test::More tests => 7;

use Math::Complex;
use_ok('Python::Serialise::Marshal');



#testing python generated data
ok(my $ps = Python::Serialise::Marshal->new('t/long'));

ok($ps->close());


#testing generating the same data
ok(my $ps = Python::Serialise::Marshal->new('>t/tmp'));

ok($ps->close());


#testing python generated data
ok(my $ps = Python::Serialise::Marshal->new('t/tmp'));
ok($ps->close());
