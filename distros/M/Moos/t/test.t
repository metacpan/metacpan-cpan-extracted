use Test::More;

package Foo;
use Moos;

has [qw/ foo bar /] => ( default => sub {42} );

package Bar;
use Moos;
extends 'Foo';

our $hash = {};
our $array = [];

has bar => ( default => sub {43} );
has baz => ( default => sub {43}, lazy => 1 );
has num => 22;
has str => 'hi';
has hash => $hash;
has array => $array;
has lol => [$array];


package main;

my $foo = Foo->new;
my $bar = Bar->new;

ok $foo->isa('Moos::Object');
ok $foo->isa('Foo');
is $foo->{foo}, 42;
is $foo->{bar}, 42;

ok $bar->isa('Bar');
ok $bar->isa('Foo');
ok $bar->isa('Moos::Object');
is $bar->{foo}, 42;
is $bar->{bar}, 43;
is $bar->foo, 42;
is $bar->{baz}, undef;
is $bar->baz, 43;
is $bar->{num}, 22;
is $bar->{str}, 'hi';
is ref($bar->{hash}), 'HASH';
is ref($bar->{array}), 'ARRAY';
isnt $bar->{hash}, $Bar::hash;
isnt $bar->{array}, $Bar::array;
is ref($bar->{lol}), 'ARRAY';
is $bar->{lol}[0], $Bar::array;

ok eval q{{
    package Fooble;
    use Moos;
    __PACKAGE__->can('confess') and __PACKAGE__->can('blessed');
    blessed(Fooble->new);
}};

ok not eval q{{
    package Boos1;
    use Moos;
    has 42;
}};

ok not eval q{{
    package Boos2;
    use Moos;
    has boo => (handles => [42]);
}};

ok not eval q{{
    package Boos3;
    use Moos;
    has boo => (predicate => '');
}};

done_testing;
