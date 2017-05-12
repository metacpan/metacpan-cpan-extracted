package Step::Brazil;

use namespace::autoclean;
use Moose;
with 'MockStep';

has [qw( rainforest )] => (
    traits => ['StepProduction'],
    is     => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;
