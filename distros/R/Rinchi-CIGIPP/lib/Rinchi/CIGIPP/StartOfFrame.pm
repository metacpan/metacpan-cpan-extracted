#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b1860-200e-11de-bdc6-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::StartOfFrame;

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

our $VERSION = '0.01';

# Preloaded methods go here.

=head1 NAME

Rinchi::CIGIPP::StartOfFrame - Perl extension for the Common Image Generator 
Interface - Start Of Frame data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::StartOfFrame;
  my $start_of_frame = Rinchi::CIGIPP::StartOfFrame->new();

  $packet_type = $start_of_frame->packet_type();
  $packet_size = $start_of_frame->packet_size();
  $major_version = $start_of_frame->major_version();
  $database_number = $start_of_frame->database_number(65);
  $ig_status = $start_of_frame->ig_status(190);
  $minor_version = $start_of_frame->minor_version();
  $earth_reference_model = $start_of_frame->earth_reference_model(Rinchi::CIGIPP->HostDefined);
  $timestamp_valid = $start_of_frame->timestamp_valid(Rinchi::CIGIPP->Invalid);
  $ig_mode = $start_of_frame->ig_mode(Rinchi::CIGIPP->Reset);
  $magic_number = $start_of_frame->magic_number();
  $ig_frame_number = $start_of_frame->ig_frame_number(44786);
  $timestamp = $start_of_frame->timestamp(37374);
  $last_host_frame_number = $start_of_frame->last_host_frame_number(55338);

=head1 DESCRIPTION

The Start of Frame packet is used to signal the beginning of a new frame. Every 
IG-to-Host message must contain exactly one Start of Frame packet. This packet 
must be the first packet in the message.

=head2 EXPORT

None by default.

#==============================================================================

=item new $start_of_frame = Rinchi::CIGIPP::StartOfFrame->new()

Constructor for Rinchi::StartOfFrame.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b1860-200e-11de-bdc6-001c25551abc',
    '_Pack'                                => 'CCCcCCSIIII',
    '_Swap1'                               => 'CCCcCCvVVVV',
    '_Swap2'                               => 'CCCcCCnNNNN',
    'packetType'                           => 101,
    'packetSize'                           => 24,
    'majorVersion'                         => 3,
    'databaseNumber'                       => 0,
    '_igStatus'                            => 0,
    '_bitfields1'                          => 48, # Includes bitfields minorVersion, earthReferenceModel, timestampValid, and igMode.
    'minorVersion'                         => 3,
    'earthReferenceModel'                  => 0,
    'timestampValid'                       => 0,
    'igMode'                               => 0,
    'magicNumber'                          => 32768,
    'igFrameNumber'                        => 0,
    'timestamp'                            => 0,
    'lastHostFrameNumber'                  => 0,
    '_unused65'                            => 0,
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

 $value = $start_of_frame->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Start of Frame packet. The 
value of this attribute must be 101.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $start_of_frame->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 24.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub major_version()

 $value = $start_of_frame->major_version();

Major Version.

This attribute indicates the major version of the CIGI interface that is 
currently being used by the IG. The Host can use this number to determine 
concurrency. The value of this attribute must be 3.

=cut

sub major_version() {
  my ($self) = @_;
  return $self->{'majorVersion'};
}

#==============================================================================

=item sub database_number([$newValue])

 $value = $start_of_frame->database_number($newValue);

Database Number.

This attribute is used to indicate to the Host which database is currently in 
use and if that database is being loaded into primary memory.

The Host will set the Database Number attribute of the IG Control packet to 
direct the IG to begin loading the corresponding database. The IG will indicate 
that the database is being loaded by negating the value and placing it in the 
Database Number attribute of the Start of Frame packet. The Host will then 
acknowledge this change by setting the Database Number attribute of the IG 
Control packet to zero (0).

When the database load is complete and after the Host has acknowledged the 
database change, the IG will set this attribute to the positive database 
number. The IG can now be considered mission-ready.

If the Host requests a database that does not exist or cannot be loaded, the IG 
will set this attribute to -128.

Zero (0) is used to indicate that the IG controls the database loading.

=cut

sub database_number() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'databaseNumber'} = $nv;
  }
  return $self->{'databaseNumber'};
}

#==============================================================================

=item sub ig_status([$newValue])

 $value = $start_of_frame->ig_status($newValue);

IG Status Code.

This attribute indicates the error status of the IG.

Error codes are IG-specific. Refer to the appropriate IG documentation for a 
list of error codes.

If more than one error is detected, the IG will report the one with the highest 
priority.
If additional error reporting must be performed, the IG should be placed in 
Debug mode via the IG Control packet's IG Mode attribute or the IG's user interface.

=cut

sub ig_status() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'_igStatus'} = $nv;
  }
  return $self->{'_igStatus'};
}

#==============================================================================

=item sub minor_version()

 $value = $start_of_frame->minor_version();

Minor Version.

This attribute indicates the minor version of the CIGI interface that is 
currently being used by the IG. The Host can use this number to determine concurrency.

=cut

sub minor_version() {
  my ($self) = @_;
  return (($self->{'_bitfields1'} & 0xF0) >> 4);
}

#==============================================================================

=item sub earth_reference_model([$newValue])

 $value = $start_of_frame->earth_reference_model($newValue);

Earth Reference Model.

This attribute indicates whether the IG is using a custom (Host-defined) Earth 
Reference Model (ERM) or the default WGS 84 reference ellipsoid for coordinate 
conversion calculations. Host-defined ERMs are defined with the Earth Reference 
Model Definition packet (see Section 4.1.19).

If the Host defines an ERM that the IG cannot support, this value is set to WGS 
84 (0). In such cases, the Host must redefine the ERM or use the WGS 84 
reference ellipsoid.

    WGS84         0
    HostDefined   1

=cut

sub earth_reference_model() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'earthReferenceModel'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 3) &0x08;
    } else {
      carp "earth_reference_model must be 0 (WGS84), or 1 (HostDefined).";
    }
  }
  return (($self->{'_bitfields1'} & 0x08) >> 3);
}

#==============================================================================

=item sub timestamp_valid([$newValue])

 $value = $start_of_frame->timestamp_valid($newValue);

Timestamp Valid.

This attribute indicates whether the Timestamp attribute contains a valid value.

    Invalid   0
    Valid     1

=cut

sub timestamp_valid() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'timestampValid'} = $nv; 
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "timestamp_valid must be 0 (Invalid), or 1 (Valid).";
    }
  }
  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub ig_mode([$newValue])

 $value = $start_of_frame->ig_mode($newValue);

IG Mode.

This attribute indicates the current IG mode. It may be one of the following 
values:
Reset/Standby – This is the IG's initial state upon start-up. When set to this 
mode, the IG will initialize/reinitialize the simulation. All entities that 
were instantiated during a previous mission will be destroyed. All 
environmental properties, views, components, and sensors will revert to their 
default settings. Any Host-defined rates, trajectories, and collision detection 
segments and volumes will be removed. The IG will only send the Start of Frame 
data packet to the Host and will ignore Host inputs except for the IG Mode 
attribute of the IG Control data packet. The IG will remain in this mode until 
directed otherwise by the Host or the IG's user interface.

Operate – This is the normal real-time operating mode for the IG. All packets 
issued by the Host will be processed by the IG. The IG should not perform 
diagnostics in this mode.

Debug – This mode is similar to the Operate mode but provides data and/or error 
logging and other debugging features to aid integration or troubleshooting of 
the Host and IG interface. Because of the overhead of these debugging features, 
the IG may not always operate in a hard real-time fashion.

Offline Maintenance – In this mode, the IG ignores all data from the Host and 
sends only Start of Frame packets. This mode can be activated only from the IG. 
Because the IG Control packets from the Host are ignored by the IG, the IG must 
be placed into Reset/Standby mode before the Host can initiate further mode changes.

    Reset                0
    Standby              1
    Operate              1
    Debug                2
    OfflineMaintenance   3

=cut

sub ig_mode() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==1) or ($nv==2) or ($nv==3)) {
      $self->{'igMode'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x03;
    } else {
      carp "ig_mode must be 0 (Reset), 1 (Standby), 1 (Operate), 2 (Debug), or 3 (OfflineMaintenance).";
    }
  }
  return ($self->{'_bitfields1'} & 0x03);
}

#==============================================================================

=item sub magic_number()

 $value = $start_of_frame->magic_number();

Byte Swap Magic Number.

This attribute is used by the Host to determine whether it needs to byte-swap 
incoming data. Refer to the CIGI ICD, Section 2.1.4 for details on this mechanism.

=cut

sub magic_number() {
  my ($self) = @_;
  return $self->{'magicNumber'};
}

#==============================================================================

=item sub ig_frame_number([$newValue])

 $value = $start_of_frame->ig_frame_number($newValue);

IG Frame Number.

This attribute uniquely identifies an IG data frame. The IG should increment 
this value by one (1) for each successive message.

=cut

sub ig_frame_number() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'igFrameNumber'} = $nv;
  }
  return $self->{'igFrameNumber'};
}

#==============================================================================

=item sub timestamp([$newValue])

 $value = $start_of_frame->timestamp($newValue);

Timestamp.

This attribute indicates the number of 10μs “ticks” since some initial 
reference time. This will enable the IG to correct for latencies as described 
in the CIGI ICD, Section 2.1.1.1.

The 10μs unit allows the simulation to run for approximately 12 hours before a 
timestamp rollover occurs. The Host software should contain logic to detect and 
correct for rollover.

The use of this attribute is required for asynchronous operation.

The use of this attribute is optional for synchronous operation. If this 
attribute does not contain a valid timestamp, the Timestamp Valid attribute 
should be  set to zero (0).

=cut

sub timestamp() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'timestamp'} = $nv;
  }
  return $self->{'timestamp'};
}

#==============================================================================

=item sub last_host_frame_number([$newValue])

 $value = $start_of_frame->last_host_frame_number($newValue);

Last Host Frame Number.

This attribute contains the value of the Host Frame Number attribute in the 
last IG Control packet received from the Host. This attribute serves as an 
acknowledgement that the IG received the last message.

=cut

sub last_host_frame_number() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'lastHostFrameNumber'} = $nv;
  }
  return $self->{'lastHostFrameNumber'};
}

#==========================================================================

=item sub pack()

 $value = $start_of_frame->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'majorVersion'},
        $self->{'databaseNumber'},
        $self->{'_igStatus'},
        $self->{'_bitfields1'},    # Includes bitfields minorVersion, earthReferenceModel, timestampValid, and igMode.
        $self->{'magicNumber'},
        $self->{'igFrameNumber'},
        $self->{'timestamp'},
        $self->{'lastHostFrameNumber'},
        $self->{'_unused65'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $start_of_frame->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;

  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'majorVersion'}                        = $c;
  $self->{'databaseNumber'}                      = $d;
  $self->{'_igStatus'}                           = $e;
  $self->{'_bitfields1'}                         = $f; # Includes bitfields minorVersion, earthReferenceModel, timestampValid, and igMode.
  $self->{'magicNumber'}                         = $g;
  $self->{'igFrameNumber'}                       = $h;
  $self->{'timestamp'}                           = $i;
  $self->{'lastHostFrameNumber'}                 = $j;
  $self->{'_unused65'}                           = $k;

  $self->{'minorVersion'}                        = $self->minor_version();
  $self->{'earthReferenceModel'}                 = $self->earth_reference_model();
  $self->{'timestampValid'}                      = $self->timestamp_valid();
  $self->{'igMode'}                              = $self->ig_mode();

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
     $self->unpack();
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k);
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
