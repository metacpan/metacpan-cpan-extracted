#!/usr/bin/perl 

use strict;
use warnings;

use Test::More tests => 4;

use Moose::Util qw' with_traits';

{
    package Bar;
    use Moose::Role;
    has y => ( is => 'ro', default => 2 );
}
{
    package Baz;
    use Moose::Role;
    has z => ( is => 'ro', default => 4 );
}

{
    package Foo;
    use Moose;
    use MooseX::Storage;

    with Storage( base => 'SerializedClass', traits => [ 'WithRoles' ] );

    has x => (
        is => 'ro',
        default => 3,
    );

}

my $x = with_traits( 'Foo', 'Bar' )->new;

my $packed = $x->pack;

is_deeply $packed => {
    '__CLASS__' => 'Foo',
    '__ROLES__' => [ qw/ Bar / ],
    x => 3,
    y => 2,
}, 'packed';

use MooseX::Storage::Base::SerializedClass qw/ moosex_unpack /;

unpacked_ok( Foo->unpack($packed), 'Foo->' );
unpacked_ok( moosex_unpack($packed), 'moosex_unpack' );

sub unpacked_ok {
    my( $obj, $name ) = @_;
    subtest $name => sub {
        isa_ok $obj, 'Foo';
        is $obj->x => 3;
        is $obj->y => 2;
    };
}

is_deeply with_traits(qw/ Foo Bar Baz /)->new->pack => {
    '__CLASS__' => 'Foo',
    '__ROLES__' => [ qw/ Bar Baz / ],
    x => 3,
    y => 2,
    z => 4
}, "Foo w/ Bar & Baz";




