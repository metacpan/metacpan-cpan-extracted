use T2::B 'Extended';
use T2;

t2->ok(!T2->isa('Tx'), "T2 isa() does not give false positives");

t2->isa_ok('T2', ['T2'], "T2 isa() still works");
t2->isa_ok('T2', ['Import::Box'], "T2 isa() looks at parent classes too");

t2->isa_ok(t2(), [qw/Import::Box T2 T2::B/], "isa does not defer to the stash");

t2->done_testing;
