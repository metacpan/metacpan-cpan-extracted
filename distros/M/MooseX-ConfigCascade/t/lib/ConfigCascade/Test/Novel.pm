package ConfigCascade::Test::Novel;

use Moose;
with 'MooseX::ConfigCascade';
extends 'ConfigCascade::Test::Book';

has author => (is => 'ro', isa => 'Str', default => 'author from package');

1;
