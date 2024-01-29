use strict;
use warnings;

package Foo;

use Moo::Role;
use MooX::Role::Parameterized;

parameter mandatory_attribute => (
    is       => "ro",
    required => 1,
);

parameter optional_attribute => (
    is        => "ro",
    predicate => 1,
);

role {
    my ( $params, $mop ) = @_;

    my $mandatory_attribute = $params->mandatory_attribute;

    $mop->has( $mandatory_attribute => ( is => "rw" ) );

    if ( $params->has_optional_attribute ) {
        my $optional_attribute = $params->optional_attribute;

        $mop->has( $optional_attribute => ( is => "rw" ) );
    }
};

1;

package Bar;

use Moo;
use MooX::Role::Parameterized::With;

with Foo => {
    mandatory_attribute => "foo",
};

1;

package Baz;

use Moo;
use MooX::Role::Parameterized::With;

with Foo => {
    mandatory_attribute => "foo",
    optional_attribute  => "bar",
};

1;

package main;
use feature 'say';

my $bar = Bar->new( foo => 1 );

say( '$bar->foo is: ', $bar->foo );

my $baz = Baz->new( foo => 2, bar => 3 );

say( '$baz->foo is: ', $baz->foo );
say( '$baz->bar is: ', $baz->bar );
