package Step::Villain;

use namespace::autoclean;
use Moose;
with 'MockStep';

# NOTE THAT THIS PACKAGE SHOULD NOT BE PART OF THE DIAGRAM

# It exists purely to check that the first dependency is the first one used

has [qw( person )] => (
    traits => ['StepProduction'],
    is     => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;
