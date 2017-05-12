#!perl -T

use Test::Most tests => 3;

use Scalar::IfDefined qw/$ifdef/;

my $undef_obj;

my $def_obj = TestPackage->new;

is($undef_obj->$ifdef('foo')->$ifdef('bar'), undef);

subtest 'defined objects' => sub {
    is($def_obj->$ifdef('foo'), 'foo');
    is(
        (
            $def_obj->$ifdef(sub { shift->bar })
                ->$ifdef('foo')
                ->$ifdef(sub { lc(shift) })
        ),
        'bar'
    );
    is({key => 'x'}->$ifdef('key'), 'x');
    is([qw/hello world/]->$ifdef(1), 'world');
    is({key => {x => 'y'}}->$ifdef(sub { shift->{key} })->$ifdef('x'), 'y');
};

subtest 'bug 8'  => sub {
    warnings_are(
        sub {
            $def_obj->$ifdef(sub { shift->bar })->$ifdef('foo')
        },
        [],
        '$def_obj->$ifdef(sub {...})->$ifdef("hashkey") form must not raise any warnings'
    );
};


package TestPackage;

sub new {
    return bless {}, shift;
}

sub foo {
    return 'foo';
}

sub bar {
    return {
        foo => 'BAR',
    }
}
