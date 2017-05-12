#!/usr/bin/perl

use lib 't/lib';
use Test::Mite with_recommends => 1;

tests "single inheritance and defaults" => sub {
    mite_load <<'CODE';
package GP1;
use Mite::Shim;
has foo =>
    is      => 'rw',
    default => 23;

package P1;
use Mite::Shim;
extends 'GP1';
has foo =>
    is      => 'rw',
    default => 42;

package C1;
use Mite::Shim;
extends 'P1';
has "bar" =>
    is      => 'rw';

1;
CODE

    my $gparent = new_ok "GP1";
    is $gparent->foo, 23;

    my $parent = new_ok "P1";
    is $parent->foo, 42;

    my $child = new_ok "C1";
    is $child->foo, 42;
};


tests "multiple inheritance and defaults" => sub {
    mite_load <<'CODE';
package GP1;
use Mite::Shim;
has foo =>
    is      => 'rw',
    default => "gp1 foo default";

package P1;
use Mite::Shim;
extends 'GP1';
has bar =>
    is      => 'rw',
    default => "p1 bar default";

package P2;
use Mite::Shim;
extends 'GP1';
has foo =>
    is      => 'rw',
    default => "p2 foo default";

package C1;
use Mite::Shim;
extends 'P1', 'P2';
has bar =>
    is      => 'rw';

1;
CODE

    my $gparent = new_ok "GP1";
    is $gparent->foo, 'gp1 foo default';
    ok !$gparent->can("bar");

    my $parent1 = new_ok "P1";
    is $parent1->foo, 'gp1 foo default';
    is $parent1->bar, 'p1 bar default';

    my $parent2 = new_ok "P2";
    is $parent2->foo, 'p2 foo default';
    ok !$parent2->can("bar");

    my $child = new_ok "C1";
    is $child->foo, "p2 foo default";
    is $child->bar, undef;
};


done_testing;
