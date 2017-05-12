use strict;
use warnings;

use Test::More tests => 46;
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

{
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

    foreach my $i (1 .. scalar @{$foo->bars}) {
        isa_ok($foo->bars->[$i - 1], 'Bar');
        is($foo->bars->[$i - 1]->number, $i, "... got the right number ($i) in the Bar in Foo");
    }
}

{
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
}

{
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

    foreach my $k (keys %{$baz->bars}) {
        isa_ok($baz->bars->{$k}, 'Bar');
        is($baz->bars->{$k}->number, $k, "... got the right number ($k) in the Bar in Baz");
    }
}
