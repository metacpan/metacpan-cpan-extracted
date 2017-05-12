#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78aaaf6-200e-11de-bda1-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::IGControl;

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

Rinchi::CIGIPP::IGControl - Perl extension for the Common Image Generator 
Interface - IGControl data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::IGControl;
  my $ig_ctl = Rinchi::CIGIPP::IGControl->new();

  $packet_type = $ig_ctl->packet_type();
  $packet_size = $ig_ctl->packet_size();
  $major_version = $ig_ctl->major_version();
  $database_number = $ig_ctl->database_number(65);
  $minor_version = $ig_ctl->minor_version();
  $extrapolation_enable = $ig_ctl->extrapolation_enable(Rinchi::CIGIPP->Disable);
  $timestamp_valid = $ig_ctl->timestamp_valid(Rinchi::CIGIPP->Invalid);
  $ig_mode = $ig_ctl->ig_mode(Rinchi::CIGIPP->Standby);
  $magic_number = $ig_ctl->magic_number();
  $host_frame_number = $ig_ctl->host_frame_number(38591);
  $timestamp = $ig_ctl->timestamp(52141);
  $last_igframe_number = $ig_ctl->last_igframe_number(47470);

=head1 DESCRIPTION

The IG Control packet is used to control the IG's operational mode, database 
loading, and timing correction. This must be the first packet in each 
Host-to-IG message, and every Host-to-IG message must contain exactly one IG 
Control packet. If more than one is encountered during a given frame, the 
resulting IG behavior is undefined. The IG Control packet allows the Host to 
control the loading of terrain. Each database is associated with a number from 
1 to 127. The Host will set the Database Number attribute to the appropriate 
value to direct the IG to begin reading the corresponding database into memory.

The IG will indicate that the database is being loaded by negating the value 
and placing it in the Database Number attribute of the Start of Frame packet. 
The Host will then acknowledge this change by setting the Database Number 
attribute of the IG Control packet to zero (0). Because the IG's resources may 
be devoted to disk I/O and other functions, the Host should ideally send only 
IG Control packets at this time.

After the IG receives the acknowledgement, it will signal the completion of the 
database load by setting the Database Number attribute of the Start of Frame 
packet to the positive database number. The IG is now considered mission-ready 
and can receive mission data from the Host.

Note that the IG will ignore the Database Number attribute while in 
Reset/Standby mode.

When using a global database, the IG will set the Database Number of the Start 
of Frame packet to zero (0). When the Host detects a zero in this attribute, it 
should in turn set the Database Number attribute of the IG Control packet to 
zero (0).

=head2 EXPORT

None by default.

#==============================================================================

=item new $ig_ctl = Rinchi::CIGIPP::IGControl->new()

Constructor for Rinchi::IGControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78aaaf6-200e-11de-bda1-001c25551abc',
    '_Pack'                                => 'CCCcCCSIIII',
    '_Swap1'                               => 'CCCcCCvVVVV',
    '_Swap2'                               => 'CCCcCCnNNNN',
    'packetType'                           => 1,
    'packetSize'                           => 24,
    'majorVersion'                         => 3,
    'databaseNumber'                       => 0,
    '_bitfields1'                          => 48, # Includes bitfields minorVersion, extrapolationEnable, timestampValid, and igMode.
    '_unused1'                             => 0,
    'minorVersion'                         => 3,
    'extrapolationEnable'                  => 0,
    'timestampValid'                       => 0,
    'igMode'                               => 0,
    'magicNumber'                          => 32768,
    'hostFrameNumber'                      => 0,
    'timestamp'                            => 0,
    'lastIGFrameNumber'                    => 0,
    '_unused2'                             => 0,
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

 $value = $ig_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the IG Control packet. The value 
of this attribute must be 1.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $ig_ctl->packet_size();

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

 $value = $ig_ctl->major_version();

Major Version.

This attribute indicates the major version of the CIGI interface that is 
currently being used by the Host. The IG can use this number to determine 
concurrency. The Host must set the value of this attribute to 3.

=cut

sub major_version() {
  my ($self) = @_;
  return $self->{'majorVersion'};
}

#==============================================================================

=item sub database_number([$newValue])

 $value = $ig_ctl->database_number($newValue);

Database Number.

This attribute is used to initiate a database load on the IG. Setting this 
attribute to a non-zero value will cause the IG to begin loading the database 
that corresponds to that value. If the number corresponds to the current 
database, the database will be reloaded. The IG will indicate that the database 
is being loaded by negating the value and placing it in the Database Number 
attribute of the Start of Frame packet. When the Host receives this 
notification, it should set the Database Number attribute of the IG Control 
packet to zero (0) to prevent continuous reloading of the database on the IG. 
The IG will ignore this attribute while in Reset/Standby mode.

=cut

sub database_number() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'databaseNumber'} = $nv;
  }
  return $self->{'databaseNumber'};
}

#==============================================================================

=item sub minor_version()

 $value = $ig_ctl->minor_version();

Minor Version.

This attribute indicates the minor version of the CIGI interface that is 
currently being used by the Host. The IG can use this number to determine concurrency.

=cut

sub minor_version() {
  my ($self) = @_;
  return (($self->{'_bitfields1'} & 0xF0) >> 4);
}

#==============================================================================

=item sub extrapolation_enable([$newValue])

 $value = $ig_ctl->extrapolation_enable($newValue);

Extrapolation/Interpolation Enable.

This attribute specifies whether any "dead reckoning" or other entity 
extrapolation or interpolation algorithms are enabled.

If this attribute is set to Disable (0), then extrapolation or interpolation is 
disabled for all entities.

If this attribute is set to Enable (1), then extrapolation or interpolation is 
determined on a per-entity basis by the Linear Extrapolation/Interpolation 
Enable flag in the Entity Control packet.

    Disable   0
    Enable    1

=cut

sub extrapolation_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'extrapolationEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 3) &0x08;
    } else {
      carp "extrapolation_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x08) >> 3);
}

#==============================================================================

=item sub timestamp_valid([$newValue])

 $value = $ig_ctl->timestamp_valid($newValue);

Timestamp Valid.

This attribute indicates whether the Timestamp attribute contains a valid 
value. Because the Timestamp attribute is required for asynchronous operation, 
Timestamp Valid must be set to Valid (1) in this mode.

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

 $value = $ig_ctl->ig_mode($newValue);

IG Mode.

This attribute dictates the IG's operational mode. The Host can initiate a mode 
change by setting this attribute to the desired mode. When the IG completes the 
mode change, it will set the IG Mode attribute in the Start of Frame packet accordingly.

    Reset                0
    Standby              1
    Operate              1
    Debug                2

=cut

sub ig_mode() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==1) or ($nv==2)) {
      $self->{'igMode'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x03;
    } else {
      carp "ig_mode must be 0 (Reset), 1 (Standby), 1 (Operate), or 2 (Debug).";
    }
  }
  return ($self->{'_bitfields1'} & 0x03);
}

#==============================================================================

=item sub magic_number()

 $value = $ig_ctl->magic_number();

Byte Swap Magic Number.

This attribute is used by the IG to determine whether it needs to byte-swap 
incoming data. The Host must set this value to 8000h, or 32768.

=cut

sub magic_number() {
  my ($self) = @_;
  return $self->{'magicNumber'};
}

#==============================================================================

=item sub host_frame_number([$newValue])

 $value = $ig_ctl->host_frame_number($newValue);

Host Frame Number.

This attribute uniquely identifies a data frame on the Host. The Host should 
increment this value by one (1) for each successive message.

=cut

sub host_frame_number() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'hostFrameNumber'} = $nv;
  }
  return $self->{'hostFrameNumber'};
}

#==============================================================================

=item sub timestamp([$newValue])

 $value = $ig_ctl->timestamp($newValue);

Timestamp.

This attribute indicates the number of 10μs "ticks" since some initial 
reference time. This will enable the IG to correct for latencies. The 10μs unit 
allows the simulation to run for approximately 12 hours before a timestamp 
rollover occurs. The IG software should contain logic to detect and correct for 
rollover. The use of this attribute is required for asynchronous operation. The 
use of this attribute is optional for synchronous operation. If this attribute 
does not contain a valid timestamp, the Timestamp Valid attribute should be set 
to zero (0).

=cut

sub timestamp() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'timestamp'} = $nv;
  }
  return $self->{'timestamp'};
}

#==============================================================================

=item sub last_igframe_number([$newValue])

 $value = $ig_ctl->last_igframe_number($newValue);

Last IG Frame Number.

This attribute contains the value of the IG Frame Number attribute in the last 
Start of Frame packet received from the IG. This attribute serves as an 
acknowledgement that the Host received the last message.

=cut

sub last_igframe_number() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'lastIGFrameNumber'} = $nv;
  }
  return $self->{'lastIGFrameNumber'};
}

#==========================================================================

=item sub pack()

 $value = $ig_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'majorVersion'},
        $self->{'databaseNumber'},
        $self->{'_bitfields1'},    # Includes bitfields minorVersion, extrapolationEnable, timestampValid, and igMode.
        $self->{'_unused1'},
        $self->{'magicNumber'},
        $self->{'hostFrameNumber'},
        $self->{'timestamp'},
        $self->{'lastIGFrameNumber'},
        $self->{'_unused2'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $ig_ctl->unpack();

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
  $self->{'_bitfields1'}                         = $e; # Includes bitfields minorVersion, extrapolationEnable, timestampValid, and igMode.
  $self->{'_unused1'}                            = $f;
  $self->{'magicNumber'}                         = $g;
  $self->{'hostFrameNumber'}                     = $h;
  $self->{'timestamp'}                           = $i;
  $self->{'lastIGFrameNumber'}                   = $j;
  $self->{'_unused2'}                            = $k;

  $self->{'minorVersion'}                        = $self->minor_version();
  $self->{'extrapolationEnable'}                 = $self->extrapolation_enable();
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
     $self->pack();
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
