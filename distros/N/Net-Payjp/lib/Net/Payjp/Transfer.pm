package Net::Payjp::Transfer;

use strict;
use warnings;

use base 'Net::Payjp';

sub retrieve{
  my $self = shift;
  my $id = shift;
  $self->id($id) if $id;

  $self->_request(method => 'GET', url => $self->_instance_url);
}

sub all{
  my $self = shift;
  my %p = @_;

  $self->_request(method => 'GET', url => $self->_class_url, param => \%p);
}

sub charges{
  my $self = shift;
  my %p = @_;

  $self->_request(method => 'GET', url => $self->_instance_url.'/charges', param => \%p);
}

1;
