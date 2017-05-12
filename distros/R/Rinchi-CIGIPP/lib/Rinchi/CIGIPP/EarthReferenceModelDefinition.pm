#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78ae570-200e-11de-bdb3-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::EarthReferenceModelDefinition;

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

Rinchi::CIGIPP::EarthReferenceModelDefinition - Perl extension for the Common 
Image Generator Interface - Earth Reference Model Definition data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::EarthReferenceModelDefinition;
  my $erm_def = Rinchi::CIGIPP::EarthReferenceModelDefinition->new();

  $packet_type = $erm_def->packet_type();
  $packet_size = $erm_def->packet_size();
  $custom_erm = $erm_def->custom_erm(Rinchi::CIGIPP->Enable);
  $equatorial_radius = $erm_def->equatorial_radius(6.458);
  $flattening = $erm_def->flattening(32.413);

=head1 DESCRIPTION

The default Earth Reference Model (ERM) used for geodetic positioning is WGS 
84. The Host may define another ERM by sending an Earth Reference Model 
Definition packet to the IG. This packet defines the equatorial radius and the 
flattening of the new reference ellipsoid.

When the IG receives an Earth Reference Model Definition packet, it should set 
the Earth Reference Model attribute of the Start of Frame packet to 
Host-Defined (1). If, for some reason, the IG cannot support the ERM defined by 
the Host, the attribute should be set to WGS 84 (0).

=head2 EXPORT

None by default.

#==============================================================================

=item new $erm_def = Rinchi::CIGIPP::EarthReferenceModelDefinition->new()

Constructor for Rinchi::EarthReferenceModelDefinition.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78ae570-200e-11de-bdb3-001c25551abc',
    '_Pack'                                => 'CCCCIdd',
    '_Swap1'                               => 'CCCCVVVVV',
    '_Swap2'                               => 'CCCCNNNNN',
    'packetType'                           => 19,
    'packetSize'                           => 24,
    '_bitfields1'                          => 0, # Includes bitfields unused31, and customERM.
    'customERM'                            => 0,
    '_unused32'                            => 0,
    '_unused33'                            => 0,
    'equatorialRadius'                     => 0,
    'flattening'                           => 0,
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

 $value = $erm_def->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Earth Reference Model 
Definition packet. The value of this attribute must be 19.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $erm_def->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 24.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub custom_erm([$newValue])

 $value = $erm_def->custom_erm($newValue);

Custom ERM Enable.

This attribute specifies whether the IG should use the Earth Reference Model 
(ERM) defined by this packet.

If this attribute is set to Disable (0), the IG will use the WGS 84 reference 
model and all other attributes in this packet will be ignored.

    Disable   0
    Enable    1

=cut

sub custom_erm() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'customERM'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "custom_erm must be 0 (Disable), or 1 (Enable).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub equatorial_radius([$newValue])

 $value = $erm_def->equatorial_radius($newValue);

Equatorial Radius.

This attribute specifies the semi-major axis of the ellipsoid.

=cut

sub equatorial_radius() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'equatorialRadius'} = $nv;
  }
  return $self->{'equatorialRadius'};
}

#==============================================================================

=item sub flattening([$newValue])

 $value = $erm_def->flattening($newValue);

Flattening.

This attribute specifies the flattening of the ellipsoid.

=cut

sub flattening() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'flattening'} = $nv;
  }
  return $self->{'flattening'};
}

#==========================================================================

=item sub pack()

 $value = $erm_def->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'_bitfields1'},    # Includes bitfields unused31, and customERM.
        $self->{'_unused32'},
        $self->{'_unused33'},
        $self->{'equatorialRadius'},
        $self->{'flattening'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $erm_def->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'_bitfields1'}                         = $c; # Includes bitfields unused31, and customERM.
  $self->{'_unused32'}                           = $d;
  $self->{'_unused33'}                           = $e;
  $self->{'equatorialRadius'}                    = $f;
  $self->{'flattening'}                          = $g;

  $self->{'customERM'}                           = $self->custom_erm();

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
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$g,$f,$i,$h);
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
