package Net::Payjp::Charge;

use strict;
use warnings;

use base 'Net::Payjp';

sub create{
  my $self = shift;
  my %p = @_;

  $self->_request(method => 'POST', url => $self->_class_url, param => \%p);
}

sub retrieve{
  my $self = shift;
  my $id = shift;
  $self->id($id) if $id;

  $self->_request(method => 'GET', url => $self->_instance_url);
}

sub save{
  my $self = shift;
  my %p = @_;

  $self->_request(method => 'POST', url => $self->_instance_url, param => \%p);
}

sub all{
  my $self = shift;
  my %p = @_;

  $self->_request(method => 'GET', url => $self->_class_url, param => \%p);
}

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

sub reauth{
  my $self = shift;
  my %p = @_;

  $self->_request(method => 'POST', url => $self->_instance_url.'/reauth', param => \%p);
}

sub tds_finish{
  my $self = shift;

  $self->_request(method => 'POST', url => $self->_instance_url.'/tds_finish');
}

1;
