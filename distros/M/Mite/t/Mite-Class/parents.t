#!/usr/bin/perl

use lib 't/lib';
use Test::Mite with_recommends => 1;

tests "parents as objects" => sub {
    my $child  = sim_class( name => "C1" );

    # Test simple multiple inheritance
    my(@parents) = (
        sim_class( name => "P1" ),
        sim_class( name => "P2")
    );
    $child->extends([map { $_->name } @parents]);

    cmp_deeply $child->parents, \@parents;
    cmp_deeply [$child->get_isa],    [map { $_->name } @parents];
    cmp_deeply [$child->linear_isa], [$child->name, map { $_->name } @parents];
    cmp_deeply [$child->linear_parents], [$child, @parents];


    # Test parents is reset when extends is reset
    my(@new_parents) = (
        sim_class( name => "NP1" ),
        sim_class( name => "NP2")
    );
    $child->extends([map { $_->name } @new_parents]);
    cmp_deeply $child->parents, \@new_parents, "YOU'RE NOT MY REAL PARENTS!!";
    cmp_deeply [$child->get_isa],    [map { $_->name } @new_parents];
    cmp_deeply [$child->linear_isa], [$child->name, map { $_->name } @new_parents];
    cmp_deeply [$child->linear_parents], [$child, @new_parents];

    # Test diamond inheritance, ensure C3 style is in use
    my $grand_parent = sim_class( name => "GP1" );
    $new_parents[0]->extends([ $grand_parent->name ]);
    $new_parents[1]->extends([ $grand_parent->name ]);

    cmp_deeply [$child->linear_isa], [
        map { $_->name } $child, @new_parents, $grand_parent
    ], "diamond inheritance";
};


tests "c3 inheritance" => sub {
    # Set up diamond inheritance
    mite_load <<'CODE';
package GP;
use Mite::Shim;

package P1;
use Mite::Shim;
extends "GP";

package P2;
use Mite::Shim;
extends "GP";

package C1;
use Mite::Shim;
extends "P1", "P2";

1;
CODE

    require mro;
    cmp_deeply mro::get_linear_isa("C1"), [qw(C1 P1 P2 GP)];
};

done_testing;
