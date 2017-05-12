use strict;
use warnings;

{
    package Bar;
    use MooseX::Role::Parameterized;

    parameter thing => ();

    role {
        has "x_" . $_[0]->thing => is => 'ro', default => 'hi there!';
    };
}

{
    package Foo; 
    use Moose;
    use MooseX::Storage;

    with Storage( base => 'SerializedClass', traits => [ 'WithRoles' ] );

}

use Test::More tests => 3;
use Test::Deep;

use Moose::Util qw/ with_traits /;
use MooseX::Storage::Base::SerializedClass qw/ moosex_unpack /;

my $bar = Bar->meta->generate_role( parameters => { thing => 'y' } );

my $foo = Foo->new;

my $f = $bar->apply($foo);

ok $f->can('x_y'), "role applied";

my $packed = $f->pack;

cmp_deeply $packed => {
    '__CLASS__' => 'Foo',
    '__ROLES__' => [ { Bar => { thing => 'y' } } ],
    'x_y' => 'hi there!',
}, "packed stucture is as expected";

my $g = moosex_unpack( $packed );

ok $g->can('x_y'), "role applied to unpacked clone";
