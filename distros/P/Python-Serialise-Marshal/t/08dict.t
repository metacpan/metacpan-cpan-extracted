use strict;
use Test::More tests => 16;

use Math::Complex;
use_ok('Python::Serialise::Marshal');



#testing python generated data
ok(my $ps = Python::Serialise::Marshal->new('t/dict'));

is_deeply($ps->load(), {1=>2,3=>4}, 'a simple dict');
is_deeply($ps->load(), {"a"=>"b","c"=>"d"}, 'a not so simple dict');
is_deeply($ps->load(), {"go"=>"to","from"=>"here"}, 'a long dict');
ok($ps->close());


#testing generating the same data
ok(my $ps = Python::Serialise::Marshal->new('>t/tmp'));

ok($ps->dump({1=>2,3=>4}), 'write a simple dict');
ok($ps->dump({"a"=>"b","c"=>"d"}), 'write a not so simple dict');
ok($ps->dump({"go"=>"to","from"=>"here"}), 'write a long dict');
ok($ps->close());


#testing python generated data
ok(my $ps = Python::Serialise::Marshal->new('t/tmp'));
is_deeply($ps->load(), {1=>2,3=>4}, 'dogfood a simple dict');
is_deeply($ps->load(), {"a"=>"b","c"=>"d"}, 'dogfood a not so simple dict');
is_deeply($ps->load(), {"go"=>"to","from"=>"here"}, 'dogfood a long dict');
ok($ps->close());
