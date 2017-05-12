#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b3ded-200e-11de-bdd4-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::ImageGeneratorMessage;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Rinchi::CIGI::AtmosphereControl ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

# Preloaded methods go here.

=head1 NAME

Rinchi::CIGIPP::ImageGeneratorMessage - Perl extension for the Common Image 
Generator Interface - Image Generator Message data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::ImageGeneratorMessage;
  my $ig_msg = Rinchi::CIGIPP::ImageGeneratorMessage->new();

  $packet_type = $ig_msg->packet_type();
  $packet_size = $ig_msg->packet_size();
  $message_ident = $ig_msg->message_ident(32020);
  $message = $ig_msg->message('Error 1234');

=head1 DESCRIPTION

The Image Generator Message packet is used to pass error, debugging, and other 
text messages to the Host.

These messages may be saved to a log file and/or written to the console or 
other user interface. Because file and console I/O are not typically real-time 
in nature, it is recommended that the IG only send Image Generator Message 
packets while in Debug mode.

Each message is composed of multiple eight-bit character data. The text message 
must be terminated by NULL, or zero (0). If the terminating byte is not the 
last byte of the eight-byte double-word, then the remainder of the double-word 
must be padded with zeroes. Zero-length messages must be terminated with four 
bytes containing NULL (to maintain 64-bit alignment). The maximum text length 
is 100 characters, including a terminating NULL.

=head2 EXPORT

None by default.

#==============================================================================

=item new $ig_msg = Rinchi::CIGIPP::ImageGeneratorMessage->new()

Constructor for Rinchi::ImageGeneratorMessage.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b3ded-200e-11de-bdd4-001c25551abc',
    '_Pack'                                => 'CCS',
    '_Swap1'                               => 'CCv',
    '_Swap2'                               => 'CCn',
    'packetType'                           => 117,
    'packetSize'                           => 8,
    'messageIdent'                         => 0,
    'message'                              => '',
    '_pad'                                 => "\0\0\0\0",
  };

  if (@_) {
    if (ref($_[0]) eq 'ARRAY') {
      $self->{'_Buffer'} = $_[0][0];
    } elsif (ref($_[0]) eq 'HASH') {
      foreach my $attr (keys %{$_[0]}) {
        $self->{"_$attr"} = $_[0]->{$attr} unless ($attr =~ /^_/);
      }
    }        
  }

  bless($self,$class);
  return $self;
}

#==============================================================================

=item sub packet_type()

 $value = $ig_msg->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Image Generation Message 
packet. The value of this attribute must be 117.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size([$newValue])

 $value = $ig_msg->packet_size($newValue);

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 4 plus the length of the message text, including NULL 
characters. The value of this attribute must be at least 8 and no more than 104 
bytes. This allows for a message length of up to 100 characters, including the 
terminating NULL.

Note: Because all packets must begin and end on a 64-bit boundary, the value of 
this attribute must be an even multiple of eight (8).

=cut

sub packet_size() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'packetSize'} = $nv;
  }
  return $self->{'packetSize'};
}

#==============================================================================

=item sub message_ident([$newValue])

 $value = $ig_msg->message_ident($newValue);

Message ID.

This attribute specifies a numerical identifier for the message.

=cut

sub message_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'messageIdent'} = $nv;
  }
  return $self->{'messageIdent'};
}

#==============================================================================

=item sub message([$newValue])

 $value = $ig_msg->message($newValue);

Message string.

These 8-bit data are used to store the ANSI codes for each character in the 
message string.

Note: The maximum number of characters, including a terminating NULL, is 100.

=cut

sub message() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    my $len = length($nv);
    if ($len < 100) {
      $self->{'message'} = $nv; 
      $self->{'_pad'} = substr("\0\0\0\0\0\0\0\0",(($len+4)%8));
      $self->{'packetSize'} = $len + 4 + length($self->{'_pad'});
    } else {
      carp "New value exceeds 99 bytes";
    }
  }

  if (defined($nv)) {
    $self->{'message'} = $nv;
  }
  return $self->{'message'};
}

#==========================================================================

=item sub pack()

 $value = $ig_msg->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'messageIdent'}
      ) . $self->{'message'} . $self->{'_pad'};

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $ig_msg->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  my $d = substr($self->{'_Buffer'},4);
  $d =~ s/(\0+)$//;
  my $e = $1;
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'messageIdent'}                        = $c;
  $self->{'message'}                             = $d;
  $self->{'_pad'}                                = $e;

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub byte_swap()

 $obj_name->byte_swap();

Byte swaps the packed data packet.

=cut

sub byte_swap($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  } else {
     $self->pack();
  }
  my ($a,$b,$c) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});
  my $padded_message = substr($self->{'_Buffer'},4);

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c) . $padded_message;
  $self->unpack();

  return $self->{'_Buffer'};
}

1;
__END__

=head1 SEE ALSO

Refer the the Common Image Generator Interface ICD which may be had at this URL:
L<http://cigi.sourceforge.net/specification.php>

=head1 AUTHOR

Brian M. Ames, E<lt>bmames@apk.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Brian M. Ames

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
