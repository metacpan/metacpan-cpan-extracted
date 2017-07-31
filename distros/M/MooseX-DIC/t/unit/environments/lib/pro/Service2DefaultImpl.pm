package Service2DefaultImpl;

use Moose;
with 'Service2';
use namespace::autoclean;

with 'MooseX::DIC::Injectable' => { implements => 'Service2' };

sub do_something {}

__PACKAGE__->meta->make_immutable;

1;
