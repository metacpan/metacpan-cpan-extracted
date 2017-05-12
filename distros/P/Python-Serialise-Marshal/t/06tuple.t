use strict;
use Test::More tests => 19;

use Math::Complex;
use_ok('Python::Serialise::Marshal');



#testing python generated data
ok(my $ps = Python::Serialise::Marshal->new('t/tuple'));

is_deeply($ps->load(), [1,2,3,4], 'a simple tuple');
is_deeply($ps->load(), ["a","b","c"], 'a not so simple tuple');
is_deeply($ps->load(), [1,2,3,"a","b"], 'a mixed tuple');
is_deeply($ps->load(), [1,2,3,["a","b","c"]], 'a nested tuple');
ok($ps->close());


#testing generating the same data
ok(my $ps = Python::Serialise::Marshal->new('>t/tmp'));

ok($ps->dump([1,2,3,4]), 'write a simple tuple');
ok($ps->dump(["a","b","c"]), 'write a not so simple tuple');
ok($ps->dump([1,2,3,"a","b"]), 'write a mixed tuple');
ok($ps->dump([1,2,3,["a","b","c"]]), 'write a nested tuple');
ok($ps->close());


#testing python generated data
ok(my $ps = Python::Serialise::Marshal->new('t/tmp'));
is_deeply($ps->load(), [1,2,3,4], 'dogfood a simple tuple');
is_deeply($ps->load(), ["a","b","c"], 'dogfood a not so simple tuple');
is_deeply($ps->load(), [1,2,3,"a","b"], 'dogfood a mixed tuple');
is_deeply($ps->load(), [1,2,3,["a","b","c"]], 'dogfood a nested tuple');
ok($ps->close());
