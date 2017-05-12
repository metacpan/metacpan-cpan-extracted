use Test::More qw/no_plan/;
use strict;
use_ok('Python::Serialise::Pickle');


ok(my $ps = Python::Serialise::Pickle->new('t/empty'));

is_deeply($ps->load(),{},"empty dict");
is_deeply($ps->load(),[],"empty list");
is_deeply($ps->load(),[],"empty tuple");
is_deeply($ps->load(),'',"empty string");

ok(my $pw = Python::Serialise::Pickle->new('>t/tmp'));


ok ($pw->dump({}), "dump empty dict");
ok ($pw->dump([]), "dump empty list");
ok ($pw->dump([]), "dump empty list");
ok ($pw->dump(''), "dump empty string");

ok($pw->close());



ok(my $pr = Python::Serialise::Pickle->new('t/tmp'));
is_deeply($pr->load(),{},"dogfood empty dict");
is_deeply($pr->load(),[],"dogfood empty list");
is_deeply($pr->load(),[],"dogfood empty tuple");
is_deeply($pr->load(),'',"dogfood empty string");
