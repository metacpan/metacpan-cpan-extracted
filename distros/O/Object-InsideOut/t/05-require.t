use strict;
use warnings;

use Test::More 'tests' => 24;

eval {
    use lib 't';
    require '05-require.pm';
};
ok(! $@, 'require ' . $@);


package main;

MAIN:
{
    my $obj;
    eval { $obj = t::AA->new(); };
    ok(! $@, '->new() ' . $@);
    can_ok($obj, qw(new clone DESTROY CLONE aa));

    ok($$obj == 1,                  'Object ID: ' . $$obj);
    ok(! defined($obj->aa),         'No default');
    ok($obj->aa(42) == 42,          'Set ->aa()');
    ok($obj->aa == 42,              'Get ->aa() == ' . $obj->aa);

    eval { $obj = t::BB->new(); };
    can_ok($obj, qw(bb set_bb));
    ok(! $@, '->new() ' . $@);
    ok($$obj == 2,                  'Object ID: ' . $$obj);
    is($obj->bb, 'def',             'Default: ' . $obj->bb);
    is($obj->set_bb('foo'), 'foo',  'Set ->set_bb()');
    is($obj->bb, 'foo',             'Get ->bb() eq ' . $obj->bb);

    eval { $obj = t::BB->new('bB' => 'baz'); };
    ok(! $@, '->new() ' . $@);
    ok($$obj == 3,                  'Object ID: ' . $$obj);
    is($obj->bb, 'baz',             'Init: ' . $obj->bb);
    is($obj->set_bb('foo'), 'foo',  'Set ->set_bb()');
    is($obj->bb, 'foo',             'Get ->bb() eq ' . $obj->bb);

    eval { $obj = t::AB->new(); };
    can_ok($obj, qw(aa bb set_bb data info_get info_set));
    ok(! $@, '->new() ' . $@);
    ok($$obj == 4,                  'Object ID: ' . $$obj);
    is($obj->bb, 'def',             'Default: ' . $obj->bb);
    is($obj->set_bb('foo'), 'foo',  'Set ->set_bb()');
    is($obj->bb, 'foo',             'Get ->bb() eq ' . $obj->bb);
}

exit(0);

# EOF
