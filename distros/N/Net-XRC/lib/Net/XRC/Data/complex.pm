package Net::XRC::Data::complex;

use strict;
use vars qw(@ISA);
use Net::XRC::Data;

@ISA = qw(Net::XRC::Data);

sub encode {
  my $self = shift;
  my %hash = %$self;
  my $typename = delete $hash{_type};
  ":$typename(". join("\n", map {
                                  "$_ ".
                                  isa( $hash{$_}, 'Net::XRC::Data' )
                                    ? $hash{$_}->encode
                                    : Net::XRC::Data->new($hash{$_})->encode
                                }
                                keys %hash
                     ).
            ")";
}
