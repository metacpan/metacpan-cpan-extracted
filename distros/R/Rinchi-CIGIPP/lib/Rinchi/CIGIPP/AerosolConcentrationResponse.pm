#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b3354-200e-11de-bdd0-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::AerosolConcentrationResponse;

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

Rinchi::CIGIPP::AerosolConcentrationResponse - Perl extension for the Common 
Image Generator Interface - Aerosol Concentration Response data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::AerosolConcentrationResponse;
  my $ac_resp = Rinchi::CIGIPP::AerosolConcentrationResponse->new();

  $packet_type = $ac_resp->packet_type();
  $packet_size = $ac_resp->packet_size();
  $request_ident = $ac_resp->request_ident(38);
  $layer_ident = $ac_resp->layer_ident(78);
  $aerosol_concentration = $ac_resp->aerosol_concentration(59.538);

=head1 DESCRIPTION

The Aerosol Concentration Response packet is sent in response to an 
Environmental Conditions Request packet whose Request Type attribute specifies 
Aerosol Concentrations. The packet describes the concentration of airborne 
particles associated with a specific weather layer.

The aerosol type is determined by the weather layer ID. If two or more global 
or regional weather layers overlap and have the same layer ID, the 
concentration of that aerosol is the average of the concentrations due to each layer.

=head2 EXPORT

None by default.

#==============================================================================

=item new $ac_resp = Rinchi::CIGIPP::AerosolConcentrationResponse->new()

Constructor for Rinchi::AerosolConcentrationResponse.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b3354-200e-11de-bdd0-001c25551abc',
    '_Pack'                                => 'CCCCf',
    '_Swap1'                               => 'CCCCV',
    '_Swap2'                               => 'CCCCN',
    'packetType'                           => 110,
    'packetSize'                           => 8,
    'requestIdent'                         => 0,
    'layerIdent'                           => 0,
    'aerosolConcentration'                 => 0,
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

 $value = $ac_resp->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Aerosol Concentration 
Response packet. The value of this attribute must be 110.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $ac_resp->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 8.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub request_ident([$newValue])

 $value = $ac_resp->request_ident($newValue);

Request ID.

This attribute identifies the environmental conditions request to which this 
response packet corresponds.

=cut

sub request_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'requestIdent'} = $nv;
  }
  return $self->{'requestIdent'};
}

#==============================================================================

=item sub layer_ident([$newValue])

 $value = $ac_resp->layer_ident($newValue);

Layer ID.

This attribute identifies the weather layer whose aerosol concentration is 
being described. Thus, this attribute indicates the aerosol type to which this 
packet corresponds.

=cut

sub layer_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'layerIdent'} = $nv;
  }
  return $self->{'layerIdent'};
}

#==============================================================================

=item sub aerosol_concentration([$newValue])

 $value = $ac_resp->aerosol_concentration($newValue);

Aerosol Concentration.

This attribute identifies the concentration of airborne particlesmeasured in 
grams/cubic meter. The type of particle is identified by the Layer ID attribute.

=cut

sub aerosol_concentration() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'aerosolConcentration'} = $nv;
  }
  return $self->{'aerosolConcentration'};
}

#==========================================================================

=item sub pack()

 $value = $ac_resp->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'requestIdent'},
        $self->{'layerIdent'},
        $self->{'aerosolConcentration'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $ac_resp->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                         = $a;
  $self->{'packetSize'}                         = $b;
  $self->{'requestIdent'}                       = $c;
  $self->{'layerIdent'}                         = $d;
  $self->{'aerosolConcentration'}               = $e;

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
  my ($a,$b,$c,$d,$e) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e);
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
