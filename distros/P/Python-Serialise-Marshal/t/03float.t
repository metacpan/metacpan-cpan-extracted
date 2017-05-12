use strict;
use Test::More tests => 19;

use Math::Complex;
use_ok('Python::Serialise::Marshal');



#testing python generated data
ok(my $ps = Python::Serialise::Marshal->new('t/float'));

is_deeply($ps->load(), 1.234, 'float 1.234');
is_deeply($ps->load(), -1.234, 'minus float 1.234');
is_deeply($ps->load(), 0.1, 'float 0.1');
is_deeply($ps->load(), -0.1, 'minus float 0.1');
ok($ps->close());


#testing generating the same data
ok(my $ps = Python::Serialise::Marshal->new('>t/tmp'));

ok($ps->dump(1.234), 'write float 1.234');
ok($ps->dump(-1.234), 'write minus float 1.234');
ok($ps->dump(0.1), 'write float 0.1');
ok($ps->dump(-0.1), 'write minus float 0.1');
ok($ps->close());


#testing python generated data
ok(my $ps = Python::Serialise::Marshal->new('t/tmp'));
is_deeply($ps->load(), 1.234, 'dogfood float 1.234');
is_deeply($ps->load(), -1.234, 'dogfood minus float 1.234');
is_deeply($ps->load(), 0.1, 'dogfood float 0.1');
is_deeply($ps->load(), -0.1, 'dogfood minus float 0.1');
ok($ps->close());
