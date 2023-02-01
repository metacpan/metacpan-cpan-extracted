package Net::Payjp::Subscription;

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

sub delete{
  my $self = shift;
  my %p = @_;

  $self->_request(method => 'DELETE', url => $self->_instance_url, param => \%p);
}

sub pause{
  my $self = shift;
  my $id = shift;
  $self->id($id) if $id;

  $self->_request(method => 'POST', url => $self->_instance_url.'/pause');
}

sub resume{
  my $self = shift;
  my $id = shift;
  $self->id($id) if $id;

  $self->_request(method => 'POST', url => $self->_instance_url.'/resume');
}

sub cancel{
  my $self = shift;
  my $id = shift;
  $self->id($id) if $id;

  $self->_request(method => 'POST', url => $self->_instance_url.'/cancel');
}

1;
