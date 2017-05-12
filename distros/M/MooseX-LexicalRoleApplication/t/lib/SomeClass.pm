package SomeClass;
our $VERSION = '0.03';

use Moose;
use namespace::autoclean;

has moo  => (is => 'ro');
has kooh => (is => 'rw');

__PACKAGE__->meta->make_immutable;

1;
