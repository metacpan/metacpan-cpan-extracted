#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Object::Proto;

# === Extends error cases ===

# Extending undefined class should croak
eval {
    Object::Proto::define('OrphanChild',
        extends => 'NonExistentParent',
        'x:Int',
    );
};
like($@, qr/has not been defined/i, 'extends undefined class croaks');

# === Extends + methods ===

Object::Proto::define('Vehicle',
    'speed:Int:default(0)',
);

package Vehicle;
sub accelerate {
    my ($self, $amount) = @_;
    $self->speed($self->speed + $amount);
    return $self->speed;
}
package main;

Object::Proto::define('Car',
    extends => 'Vehicle',
    'doors:Int:default(4)',
);

package Car;
sub describe {
    my $self = shift;
    return $self->doors . "-door car at speed " . $self->speed;
}
package main;

my $car = new Car speed => 0, doors => 2;
is($car->accelerate(50), 50, 'inherited method modifies inherited property');
is($car->speed, 50, 'property updated by inherited method');
is($car->describe, '2-door car at speed 50', 'own method uses both own and inherited props');

done_testing;
