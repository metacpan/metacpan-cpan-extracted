package Step::Sol;

use namespace::autoclean;
use Moose;
with 'MockStep';

has [qw( sunlight )] => (
    traits => ['StepProduction'],
    is     => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;
