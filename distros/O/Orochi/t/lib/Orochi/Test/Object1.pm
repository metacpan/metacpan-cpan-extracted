package Orochi::Test::Object1;
use Moose;
use namespace::clean -except => qw(meta);

has foo => (is => 'ro');
has bar => (is => 'ro');

1;