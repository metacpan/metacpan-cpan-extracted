package Net::Payjp::Transfer;

use strict;
use warnings;

use base 'Net::Payjp::Resource';

sub charges{
  my $self = shift;
  my %p = @_;

  $self->_request(method => 'GET', url => $self->_instance_url.'/charges', param => \%p);
}

1;
