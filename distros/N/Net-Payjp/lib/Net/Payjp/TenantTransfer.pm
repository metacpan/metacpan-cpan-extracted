package Net::Payjp::TenantTransfer;

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

sub _class_url{
  my $self = shift;
  return $self->api_base.'/v1/tenant_transfers';
}

1;
