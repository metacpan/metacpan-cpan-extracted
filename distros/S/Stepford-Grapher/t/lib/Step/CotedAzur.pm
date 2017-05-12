package Step::CotedAzur;

use namespace::autoclean;
use Moose;
with 'MockStep';

has [qw( all_things_nice )] => (
    traits => ['StepProduction'],
    is     => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;
