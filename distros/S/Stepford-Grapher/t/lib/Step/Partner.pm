package Step::Partner;

use namespace::autoclean;
use Moose;
with 'MockStep';

has [qw( person )] => (
    traits => ['StepProduction'],
    is     => 'ro',
);

has [qw( sugar spice all_things_nice )] => (
    traits => ['StepDependency'],
    is     => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;
