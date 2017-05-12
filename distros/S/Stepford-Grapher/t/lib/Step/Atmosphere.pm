package Step::Atmosphere;

use namespace::autoclean;
use Moose;
with 'MockStep';

has [qw( the_air_that_i_breathe )] => (
    traits => ['StepProduction'],
    is     => 'ro',
);

has [qw( rainforest sunlight )] => (
    traits => ['StepDependency'],
    is     => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;
