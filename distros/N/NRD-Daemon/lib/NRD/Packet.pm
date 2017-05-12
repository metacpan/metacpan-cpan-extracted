package NRD::Packet;

use strict;
use warnings;

use Carp;

#length needs to count bytes. not characters
use bytes;

sub new {
  my ($class, $options) = @_;
  my $self = {
    'max_packet_size' => 256*1024
  };
  bless ($self, $class);
  return $self;
}


sub pack {
   my ($self, $content) = @_;
   my $packet = length($content)."\n".$content;
   return $packet;
}

# Expect 1234 as a size of bytes to read next
# Needs a line terminator because of buffered input/output
sub unpack {
   my ($self, $fd) = @_;
   my $bytes = <$fd>;
   croak "No data received" unless defined $bytes;
   chomp $bytes;
   if ($bytes !~ /^\d+$/) {
     # Unknown
     croak "Can't read packet header";
   }
   croak "NRD packet bigger than expected ($bytes bytes). Are you getting trash?" if ($bytes > $self->{'max_packet_size'});
   croak "NRD packet with zero length. Are you getting trash?" if ($bytes <= 0);
   read($fd, my $buffer, $bytes) == $bytes or croak "Didn't receive whole packet";
   return $buffer;
}

#################### main pod documentation begin ###################

=head1 NAME

NRD::Packet - Interpret the requests and responses for NRD

=head1 DESCRIPTION

Project Home Page: http://code.google.com/p/nrd/

=head1 METHODS

=head2 pack($content)

Prepare a string to get transmitted over the net

=head2 unpack($fd)

Get a content from $fd that was transmitted with "pack" on the other end

=cut

1;
