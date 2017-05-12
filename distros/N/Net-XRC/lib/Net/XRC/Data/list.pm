package Net::XRC::Data::list;

use strict;
use vars qw(@ISA);
use Net::XRC::Data;

@ISA = qw(Net::XRC::Data);

sub encode {
  my $self = shift;
  '('. join(' ', map {
                       ref($_) =~ /^Net::XRC::Data/
                         ? $_->encode
                         : Net::XRC::Data->new($_)->encode
                     }
                     @$self
           ).
  ')';
}

