use Test::More qw(no_plan);

use_ok('Python::Serialise::Pickle');

ok(my $ps = Python::Serialise::Pickle->new('t/strings'));


is($ps->load(),"'simple'");
is($ps->load(),'"simple"');
is($ps->load(),"simple");
is($ps->load(),'"simple"');
is($ps->load(),"simple space");
is($ps->load(),"simple\nnew line");
is($ps->load(),"simple\nnew line");

# TODO multiline and raw strings


ok($pw = Python::Serialise::Pickle->new('>t/tmp'));


ok($pw->dump("'simple'"));
ok($pw->dump('"simple"'));
ok($pw->dump("simple"));
ok($pw->dump('"simple"'));
ok($pw->dump("simple space"));
ok($pw->dump("simple\nnew line"));
ok($pw->dump("simple\nnew line"));

ok($pw->close());

ok(my $pr = Python::Serialise::Pickle->new('t/tmp'));

is($pr->load(),"'simple'");
is($pr->load(),'"simple"');
is($pr->load(),"simple");
is($pr->load(),'"simple"');
is($pr->load(),"simple space");
is($pr->load(),"simple\nnew line");
is($pr->load(),"simple\nnew line");

