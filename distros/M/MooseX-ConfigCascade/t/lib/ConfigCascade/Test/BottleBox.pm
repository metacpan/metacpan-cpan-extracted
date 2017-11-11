package ConfigCascade::Test::BottleBox;

use Moose;
use ConfigCascade::Test::BottleTop;
with 'MooseX::ConfigCascade';

has bottle => (is => 'rw', isa => 'ConfigCascade::Test::Bottle', default => sub{
    ConfigCascade::Test::Bottle->new;
});
has material => (is => 'rw', isa => 'Str');


# these should be unaffected
has width => (is => 'ro', isa => 'Num', default => 22.5);
has packing => (is => 'rw', isa => 'Str', default => 'packing from package');

1;
