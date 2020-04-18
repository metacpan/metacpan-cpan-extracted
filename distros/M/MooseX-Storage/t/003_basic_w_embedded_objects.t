use strict;
use warnings;

use Test::More tests => 5;
use Test::Deep;

=pod

This test checks the single level
expansion and collapsing of the
ArrayRef and HashRef type handlers.

=cut

{
    package Bar;
    use Moose;
    use MooseX::Storage;

    with Storage;

    has 'number' => (is => 'ro', isa => 'Int');

    package Foo;
    use Moose;
    use MooseX::Storage;

    with Storage;

    has 'bars' => (
        is  => 'ro',
        isa => 'ArrayRef[Bar]'
    );

    package Baz;
    use Moose;
    use MooseX::Storage;

    with Storage;

    has 'bars' => (
        is  => 'ro',
        isa => 'HashRef[Bar]'
    );
}

{
    my $foo = Foo->new(
        bars => [ map { Bar->new(number => $_) } (1 .. 10) ]
    );
    isa_ok( $foo, 'Foo' );

    cmp_deeply(
        $foo->pack,
        {
            __CLASS__ => 'Foo',
            bars      => [
                map {
                  {
                      __CLASS__ => 'Bar',
                      number    => $_,
                  }
                } (1 .. 10)
            ],
        },
        '... got the right frozen class'
    );
}

subtest 'Foo' => sub {
    my $foo = Foo->unpack(
        {
            __CLASS__ => 'Foo',
            bars      => [
                map {
                  {
                      __CLASS__ => 'Bar',
                      number    => $_,
                  }
                } (1 .. 10)
            ],
        }
    );
    isa_ok( $foo, 'Foo' );

    subtest 'bars', \&test_bars, @{ $foo->bars };
};

subtest 'Baz', sub {
    my $baz = Baz->new(
        bars => { map { ($_ => Bar->new(number => $_)) } (1 .. 10) }
    );
    isa_ok( $baz, 'Baz' );

    cmp_deeply(
        $baz->pack,
        {
            __CLASS__ => 'Baz',
            bars      => {
                map {
                  ($_ => {
                      __CLASS__ => 'Bar',
                      number    => $_,
                  })
                } (1 .. 10)
            },
        },
        '... got the right frozen class'
    );
};

subtest 'Baz unpack', sub {
    my $baz = Baz->unpack(
        {
            __CLASS__ => 'Baz',
            bars      => {
                map {
                  ($_ => {
                      __CLASS__ => 'Bar',
                      number    => $_,
                  })
                } (1 .. 10)
            },
        }
    );
    isa_ok( $baz, 'Baz' );

    subtest 'bars' => \&test_bars, map { $baz->bars->{$_ } } 1..10;
};

sub test_bars {
    my @bars = @_;

    is scalar @bars => 10, 'we have 10 bars';

    my $i = 0;
    subtest "bar.".$i, sub {
        is $_->number => ++$i, 'right value';
    } for @bars;
}

