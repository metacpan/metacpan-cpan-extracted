package Net::Payjp::Account;

use strict;
use warnings;

use base 'Net::Payjp';

sub retrieve{
  my $self = shift;

  $self->_request(method => 'GET', url => $self->_class_url);
}

1;
