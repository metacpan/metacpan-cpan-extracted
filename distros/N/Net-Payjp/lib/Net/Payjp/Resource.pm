package Net::Payjp::Resource;

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

  $self->_request(method => 'DELETE', url => $self->_instance_url);
}

sub _instance_url{
  my $self = shift;

  if(ref($self) =~ /Net::Payjp::Customer::Card/){
    return $self->api_base.'/v1/'.'customers/'.$self->cus_id.'/cards'; 
  }
  elsif(ref($self) =~ /Net::Payjp::Customer::Subscription/){
    return $self->api_base.'/v1/'.'customers/'.$self->cus_id.'/subscriptions'; 
  }
  else{
    return $self->_class_url.'/'.$self->id; 
  }
}

sub _class_url{
  my $self = shift;
  my ($class) = lc(ref($self)) =~ /([^:]*$)/; 
  return $self->api_base.'/v1/'.$class.'s';
}

1;
