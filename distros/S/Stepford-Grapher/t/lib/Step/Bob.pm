package Step::Bob;

use namespace::autoclean;
use Moose;
with 'MockStep';

has [qw( the_air_that_i_breathe to_love_you )] => (
    traits   => ['StepDependency'],
    is       => 'ro',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
1;
