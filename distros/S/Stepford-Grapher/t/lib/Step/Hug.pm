package Step::Hug;

use namespace::autoclean;
use Moose;
with 'MockStep';

has [qw( oxytocin )] => (
    traits => ['StepProduction'],
    is     => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;
