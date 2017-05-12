use strict;
use warnings;

use Test::More 'tests' => 36;

package AA; {
    use Object::InsideOut;

    my %aa : Field({'acc'=>'aa', 'type' => 'num'});

    my $id = 1;

    sub id : ID {
        return ($id++);
    }
}


package BB; {
    use Object::InsideOut;

    my %bb : Field( { 'get' => 'bb', 'Set' => 'set_bb' } );

    my %init_args : InitArgs = (
        'BB' => {
            'Field'     => \%bb,
            'Default'   => 'def',
            'Regex'     => qr/bb/i,
        },
    );
}


package AB; {
    use Object::InsideOut qw(AA BB);

    my %data : Field({'acc'=>'data'});
    my %info : Field('gET'=>'info_get', 'SET'=>'info_set');

    my %init_args : InitArgs = (
        'data' => {
            'Field' => \%data,
        },
        'info' => {
            'FIELD' => \%info,
            'DEF'   => ''
        },
    );
}


package foo; {
    use Object::InsideOut;
}


package main;

MAIN:
{
    my $obj;
    eval { $obj = AA->new(); };
    ok(! $@, '->new() ' . $@);
    can_ok($obj, qw(new clone DESTROY CLONE aa));

    ok($$obj == 1,                  'Object ID: ' . $$obj);
    ok(! defined($obj->aa),         'No default');
    ok($obj->aa(42) == 42,          'Set ->aa()');
    ok($obj->aa == 42,              'Get ->aa() == ' . $obj->aa);

    eval { $obj = BB->new(); };
    can_ok($obj, qw(bb set_bb));
    ok(! $@, '->new() ' . $@);
    ok($$obj == 2,                  'Object ID: ' . $$obj);
    is($obj->bb, 'def',             'Default: ' . $obj->bb);
    is($obj->set_bb('foo'), 'foo',  'Set ->set_bb()');
    is($obj->bb, 'foo',             'Get ->bb() eq ' . $obj->bb);

    eval { $obj = BB->new('bB' => 'baz'); };
    ok(! $@, '->new() ' . $@);
    ok($$obj == 3,                  'Object ID: ' . $$obj);
    is($obj->bb, 'baz',             'Init: ' . $obj->bb);
    is($obj->set_bb('foo'), 'foo',  'Set ->set_bb()');
    is($obj->bb, 'foo',             'Get ->bb() eq ' . $obj->bb);

    eval { $obj = AB->new(); };
    can_ok($obj, qw(aa bb set_bb data info_get info_set));
    ok(! $@, '->new() ' . $@);
    ok($$obj == 4,                  'Object ID: ' . $$obj);
    is($obj->bb, 'def',             'Default: ' . $obj->bb);
    is($obj->set_bb('foo'), 'foo',  'Set ->set_bb()');
    is($obj->bb, 'foo',             'Get ->bb() eq ' . $obj->bb);
    is($obj->bb, 'foo',             'Get ->bb() eq ' . $obj->bb);
    is($obj->info_get(), '',        '->info_get() eq ' . $obj->info_get());
    $obj->info_set('test');
    is($obj->info_get(), 'test',    'Set: ->info_get() eq ' . $obj->info_get());

    # Test that IDs are being reclaimed
    my $id;
    {
        my $x = foo->new();
        $id = $$x;
    }
    for (1..10) {
        my $x = foo->new();
        is($$x, $id, 'ID reclaimed');
    }
}

exit(0);

# EOF
