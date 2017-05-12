package Net::XRC::Data::string;

use strict;
use vars qw(@ISA);
use Net::XRC::Data;

@ISA = qw(Net::XRC::Data);

sub encode {
  my $self = shift;
  my $string = $$self;
  $string =~ s/(["\\])/\\$1/g;
  qq("$string");
}

