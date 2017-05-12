package Net::Payjp::Charge;

use strict;
use warnings;

use base 'Net::Payjp::Resource';

sub refund{
  my $self = shift;
  my %p = @_;

  $self->_request(method => 'POST', url => $self->_instance_url.'/refund', param => \%p);
}

sub capture{
  my $self = shift;
  my %p = @_;

  $self->_request(method => 'POST', url => $self->_instance_url.'/capture', param => \%p);
}
1;
