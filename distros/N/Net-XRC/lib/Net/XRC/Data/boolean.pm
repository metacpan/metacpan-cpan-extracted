package Net::XRC::Data::boolean;

use strict;
use vars qw(@ISA);
use Net::XRC::Data;

@ISA = qw(Net::XRC::Data);

sub encode {
  my $self = shift;
  $$self ? '/T' : '/F';
}

