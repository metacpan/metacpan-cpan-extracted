package Net::Payjp::Object;

use strict;
use warnings;

sub new{
  my $self = shift;
  my %p = @_;
  
  bless{%p}, $self;
}

our $AUTOLOAD; 
sub AUTOLOAD {
  my $self = shift;

  my ($key) = $AUTOLOAD =~ /([^:]*$)/; 
  return $self->{$key};
}


1;
