package Step::Love;

use namespace::autoclean;
use Moose;
with 'MockStep';

has [qw( to_love_you )] => (
    traits => ['StepProduction'],
    is     => 'ro',
);

has [qw( oxytocin person )] => (
    traits => ['StepDependency'],
    is     => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;
