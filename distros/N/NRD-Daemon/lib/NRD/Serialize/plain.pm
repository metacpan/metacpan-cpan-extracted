package NRD::Serialize::plain;

use strict;
use warnings;

use JSON;

use base 'NRD::Serialize';

sub new {
  my ($class, $options) = @_;
  $options = {} if (not defined $options);
  my $self = {
    %$options
  };

  bless($self, $class);
}

sub needs_helo { 0 }

sub helo {
   return undef;
}

sub unfreeze {
   my ($self, $recieved) = @_;
   return decode_json($recieved);
}

sub freeze {
   my ($self, $result) = @_;
   return encode_json($result);
}

1;
