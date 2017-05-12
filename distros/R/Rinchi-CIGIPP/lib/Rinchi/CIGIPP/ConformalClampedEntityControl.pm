#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78aba5a-200e-11de-bda3-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::ConformalClampedEntityControl;

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

Rinchi::CIGIPP::ConformalClampedEntityControl - Perl extension for the Common 
Image Generator Interface - Conformal Clamped Entity Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::ConformalClampedEntityControl;
  my $ccent_ctl = Rinchi::CIGIPP::ConformalClampedEntityControl->new();

  $packet_type = $ccent_ctl->packet_type();
  $packet_size = $ccent_ctl->packet_size();
  $entity_ident = $ccent_ctl->entity_ident(57935);
  $yaw = $ccent_ctl->yaw(39.75);
  $latitude = $ccent_ctl->latitude(57.645);
  $longitude = $ccent_ctl->longitude(70.599);

=head1 DESCRIPTION

The Conformal Clamped Entity Control packet is used to set spatial data for 
conformal, ground- or ocean-clamped entities. This packet is offered as a 
lightweight alternative to the Entity Control packet.

Because the entity type and other necessary attributes are not specified in 
this packet, it may not be used to instantiate (create) an entity. Before using 
this packet to manipulate an entity, the Host must first instantiate that 
entity by sending an Entity Control packet and should set the Ground/Ocean 
Clamp attribute to Conformal (2). If a non-existent entity is referenced by a 
Conformal Clamped Entity Control packet, the packet will be ignored.

An entity's current roll, pitch, and altitude offsets (specified in the last 
Entity Control packet referencing the entity) will be maintained when the IG 
receives a Conformal Clamped Entity Control packet describing that entity. If 
this packet is applied to an unclamped or non-conformal clamped entity, its 
current absolute roll, pitch, and altitude will be maintained.

=head2 EXPORT

None by default.

#==============================================================================

=item new $ccent_ctl = Rinchi::CIGIPP::ConformalClampedEntityControl->new()

Constructor for Rinchi::ConformalClampedEntityControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78aba5a-200e-11de-bda3-001c25551abc',
    '_Pack'                                => 'CCSfdd',
    '_Swap1'                               => 'CCvVVVVV',
    '_Swap2'                               => 'CCnNNNNN',
    'packetType'                           => 3,
    'packetSize'                           => 24,
    'entityIdent'                          => 0,
    'yaw'                                  => 0,
    'latitude'                             => 0,
    'longitude'                            => 0,
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

 $value = $ccent_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Conformal Clamped Entity 
Control packet. The value of this attribute must be 3.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $ccent_ctl->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this  data packet. Thevalue of 
this attribute must be 24.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub entity_ident([$newValue])

 $value = $ccent_ctl->entity_ident($newValue);

Entity ID.

This attribute epresents the entity to which this packet will be applied. A 
value of zero (0) corresponds to the Ownship.

=cut

sub entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'entityIdent'} = $nv;
  }
  return $self->{'entityIdent'};
}

#==============================================================================

=item sub yaw([$newValue])

 $value = $ccent_ctl->yaw($newValue);

Yaw.

This attribute specifies the instantaneous heading of the entity as measured 
from True North.

=cut

sub yaw() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv>=0) and ($nv<=360.0)) {
      $self->{'yaw'} = $nv;
    } else {
      carp "yaw must be from 0.0 to +360.0.";
    }
  }
  return $self->{'yaw'};
}

#==============================================================================

=item sub latitude([$newValue])

 $value = $ccent_ctl->latitude($newValue);

Latitude.

This attribute specifies the entity's geodetic latitude.

=cut

sub latitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv>=-90) and ($nv<=90.0)) {
      $self->{'latitude'} = $nv;
    } else {
      carp "latitude must be from -90.0 to +90.0.";
    }
  }
  return $self->{'latitude'};
}

#==============================================================================

=item sub longitude([$newValue])

 $value = $ccent_ctl->longitude($newValue);

Longitude.

This attribute specifies the entity's geodetic longitude.

=cut

sub longitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv>=-180.0) and ($nv<=180.0)) {
      $self->{'longitude'} = $nv;
    } else {
      carp "longitude must be from -180.0 to +180.0.";
    }
  }
  return $self->{'longitude'};
}

#==========================================================================

=item sub pack()

 $value = $ccent_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'entityIdent'},
        $self->{'yaw'},
        $self->{'latitude'},
        $self->{'longitude'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $ccent_ctl->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'entityIdent'}                         = $c;
  $self->{'yaw'}                                 = $d;
  $self->{'latitude'}                            = $e;
  $self->{'longitude'}                           = $f;

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
  my ($a,$b,$c,$d,$e,$f,$g,$h) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$f,$e,$h,$g);
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
