package Service1DefaultImpl;

use Moose;
with 'Service1';
use namespace::autoclean;

with 'MooseX::DIC::Injectable' => { implements => 'Service1' };

sub do_something {}

__PACKAGE__->meta->make_immutable;

1;
