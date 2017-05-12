use strict;
use Test::More tests => 25;

use Math::Complex;
use_ok('Python::Serialise::Marshal');



#testing python generated data
ok(my $ps = Python::Serialise::Marshal->new('t/int'));

is_deeply($ps->load(), 1, 'one');
is_deeply($ps->load(), -1, 'minus one');
is_deeply($ps->load(), 256, 'two-five-six');
is_deeply($ps->load(), -256, 'minus two-five-six');
is_deeply($ps->load(), 1024, 'one-oh-two-four');
is_deeply($ps->load(), -1024, 'minus one-oh-two-four');
ok($ps->close());


#testing generating the same data
ok(my $ps = Python::Serialise::Marshal->new('>t/tmp'));

ok($ps->dump(1), 'write one');
ok($ps->dump(-1), 'write minus one');
ok($ps->dump(256), 'write two-five-six');
ok($ps->dump(-256), 'write minus two-five-six');
ok($ps->dump(1024), 'write one-oh-two-four');
ok($ps->dump(-1024), 'write minus one-oh-two-four');
ok($ps->close());


#testing python generated data
ok(my $ps = Python::Serialise::Marshal->new('t/tmp'));
is_deeply($ps->load(), 1, 'dogfood one');
is_deeply($ps->load(), -1, 'dogfood minus one');
is_deeply($ps->load(), 256, 'dogfood two-five-six');
is_deeply($ps->load(), -256, 'dogfood minus two-five-six');
is_deeply($ps->load(), 1024, 'dogfood one-oh-two-four');
is_deeply($ps->load(), -1024, 'dogfood minus one-oh-two-four');
ok($ps->close());
