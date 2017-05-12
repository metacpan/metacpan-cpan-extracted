use strict;
use Test::More tests => 10;

use Math::Complex;
use_ok('Python::Serialise::Marshal');



#testing python generated data
ok(my $ps = Python::Serialise::Marshal->new('t/complex'));

is_deeply("".$ps->load(), "2.0+4.0i", 'simple complex number');
ok($ps->close());


#testing generating the same data
ok(my $ps = Python::Serialise::Marshal->new('>t/tmp'));

ok($ps->dump(Math::Complex->new('2.0','4.0')), 'write simple complex number');
ok($ps->close());


#testing python generated data
ok(my $ps = Python::Serialise::Marshal->new('t/tmp'));
is_deeply("".$ps->load(), "2.0+4.0i", 'dogfood simple complex number');
ok($ps->close());
