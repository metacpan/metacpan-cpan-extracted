use Test::More qw(no_plan);

use Data::Dumper;
use_ok('Python::Serialise::Pickle');

ok(my $ps = Python::Serialise::Pickle->new('t/lists'));


eq_array($ps->load,[1, 2, 4]);
eq_array($ps->load,['spam', 'eggs', 100, 1234]);
is_deeply($ps->load, [1, 2, ['a','b','c']]);


ok(my $pw = Python::Serialise::Pickle->new('>t/tmp'));


ok($pw->dump([1, 2, 4]));
ok($pw->dump(['spam', 'eggs', 100, 1234]));
ok($pw->dump([1, 2, ['a','b','c']]));

ok($pw->close());

ok(my $pr = Python::Serialise::Pickle->new('t/tmp'));


eq_array($pr->load,[1, 2, 4]);
eq_array($pr->load,['spam', 'eggs', 100, 1234]);
is_deeply($pr->load, [1, 2, ['a','b','c']]);

