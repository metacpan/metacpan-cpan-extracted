use strict;
use Test::More tests => 13;

use Math::Complex;
use_ok('Python::Serialise::Marshal');



#testing python generated data
ok(my $ps = Python::Serialise::Marshal->new('t/mixed'));

is_deeply($ps->load(), {"a"=>["some","stuff","in here"]}, 'some mixed dicts');
is_deeply($ps->load(), ["a", "list", "with", {1=>2,3=>4,5=>6}], 'some mixed list');
ok($ps->close());


#testing generating the same data
ok(my $ps = Python::Serialise::Marshal->new('>t/tmp'));

ok($ps->dump({"a"=>["some","stuff","in here"]}), 'write some mixed dicts');
ok($ps->dump(["a", "list", "with", {1=>2,3=>4,5=>6}]), 'write some mixed list');
ok($ps->close());


#testing python generated data
ok(my $ps = Python::Serialise::Marshal->new('t/tmp'));
is_deeply($ps->load(), {"a"=>["some","stuff","in here"]}, 'dogfood some mixed dicts');
is_deeply($ps->load(), ["a", "list", "with", {1=>2,3=>4,5=>6}], 'dogfood some mixed list');
ok($ps->close());
