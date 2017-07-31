package Service1TestImpl;

use Moose;
with 'Service1';
use namespace::autoclean;

with 'MooseX::DIC::Injectable' => { 
  implements => 'Service1', 
  environment => 'test' };

sub do_something {}

__PACKAGE__->meta->make_immutable;

1;
