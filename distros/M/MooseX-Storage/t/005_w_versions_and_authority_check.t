use strict;
use warnings;

use Test::More tests => 7;
use Test::Deep;
use Test::Fatal;

=pod

This tests that the version and authority
checks are performed upon object expansion.

=cut

{
    package Bar;
    use Moose;
    use MooseX::Storage;

    our $VERSION   = '0.01';
    our $AUTHORITY = 'cpan:JRANDOM';

    with Storage;

    has 'number' => (is => 'ro', isa => 'Int');

    package Foo;
    use Moose;
    use MooseX::Storage;

    our $VERSION   = '0.01';
    our $AUTHORITY = 'cpan:JRANDOM';

    with Storage;

    has 'bar' => (
        is  => 'ro',
        isa => 'Bar'
    );
}

{
    my $foo = Foo->new(
        bar => Bar->new(number => 1)
    );
    isa_ok( $foo, 'Foo' );

    cmp_deeply(
        $foo->pack,
        {
            __CLASS__ => 'Foo-0.01-cpan:JRANDOM',
            bar => {
                __CLASS__ => 'Bar-0.01-cpan:JRANDOM',
                number    => 1,
            }
        },
        '... got the right frozen class'
    );
}

{
    my $foo = Foo->unpack(
        {
            __CLASS__ => 'Foo-0.01-cpan:JRANDOM',
            bar => {
                __CLASS__ => 'Bar-0.01-cpan:JRANDOM',
                number    => 1,
            }
        },
    );
    isa_ok( $foo, 'Foo' );
    isa_ok( $foo->bar, 'Bar' );
    is( $foo->bar->number, 1 , '... got the right number too' );

}

Moose::Meta::Class->create('Bar',
    version   => '0.02',
    authority => 'cpan:JRANDOM',
);

ok(exception {
    Foo->unpack(
        {
            __CLASS__ => 'Foo-0.01-cpan:JRANDOM',
            bar => {
                __CLASS__ => 'Bar-0.01-cpan:JRANDOM',
                number    => 1,
            }
        }
    );
}, '... could not unpack, versions are different ' . $@);

Moose::Meta::Class->create('Bar',
    version   => '0.01',
    authority => 'cpan:DSTATIC',
);

ok(exception {
    Foo->unpack(
        {
            __CLASS__ => 'Foo-0.01-cpan:JRANDOM',
            bar => {
                __CLASS__ => 'Bar-0.01-cpan:JRANDOM',
                number    => 1,
            }
        }
    );
}, '... could not unpack, authorities are different');
