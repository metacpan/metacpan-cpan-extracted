package ConfigCascade::Test::BottleTop;

use Moose;
with 'MooseX::ConfigCascade';


has radius => (is => 'rw', isa => 'Num');
has material => (is => 'ro', isa => 'Str', default => 'bottle top material from package');

1;
