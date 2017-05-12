package Step::Supermarket;

use namespace::autoclean;
use Moose;
with 'MockStep';

has [qw( sugar spice salt bananas oranges milk )] => (
    traits => ['StepProduction'],
    is     => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;
