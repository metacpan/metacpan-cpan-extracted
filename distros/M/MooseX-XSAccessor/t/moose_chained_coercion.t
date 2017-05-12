use lib "t/lib";
use lib "moose/lib";
use lib "lib";

## skip Test::Tabs

use strict;
use warnings;

use Test::More;

{
    package Baz;
    use MyMoose;
    use Moose::Util::TypeConstraints;

    coerce 'Baz' => from 'HashRef' => via { Baz->new($_) };

    has 'hello' => (
        is      => 'ro',
        isa     => 'Str',
    );

    package Bar;
    use MyMoose;
    use Moose::Util::TypeConstraints;

    coerce 'Bar' => from 'HashRef' => via { Bar->new($_) };

    has 'baz' => (
        is      => 'ro',
        isa     => 'Baz',
        coerce  => 1
    );

    package Foo;
    use MyMoose;

    has 'bar' => (
        is      => 'ro',
        isa     => 'Bar',
        coerce  => 1,
    );
}

my $foo = Foo->new(bar => { baz => { hello => 'World' } });
isa_ok($foo, 'Foo');
isa_ok($foo->bar, 'Bar');
isa_ok($foo->bar->baz, 'Baz');
is($foo->bar->baz->hello, 'World', '... this all worked fine');

done_testing;
