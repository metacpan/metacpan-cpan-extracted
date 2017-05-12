#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b38a4-200e-11de-bdd2-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::TerrestrialSurfaceConditionsResponse;

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

Rinchi::CIGIPP::TerrestrialSurfaceConditionsResponse - Perl extension for the 
Common Image Generator Interface - Terrestrial Surface Conditions Response data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::TerrestrialSurfaceConditionsResponse;
  my $tsc_resp = Rinchi::CIGIPP::TerrestrialSurfaceConditionsResponse->new();

  $packet_type = $tsc_resp->packet_type();
  $packet_size = $tsc_resp->packet_size();
  $request_ident = $tsc_resp->request_ident(208);
  $surface_condition_ident = $tsc_resp->surface_condition_ident(53038);

=head1 DESCRIPTION

The Terrestrial Surface Conditions Response packet is sent in response to an 
Environmental Conditions Request packet whose Request Type attribute specifies 
Terrestrial Surface Conditions. The packet describes the terrain surface 
conditions at the requested geodetic latitude and longitude.

=head2 EXPORT

None by default.

#==============================================================================

=item new $tsc_resp = Rinchi::CIGIPP::TerrestrialSurfaceConditionsResponse->new()

Constructor for Rinchi::TerrestrialSurfaceConditionsResponse.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b38a4-200e-11de-bdd2-001c25551abc',
    '_Pack'                                => 'CCCCI',
    '_Swap1'                               => 'CCCCV',
    '_Swap2'                               => 'CCCCN',
    'packetType'                           => 112,
    'packetSize'                           => 8,
    'requestIdent'                         => 0,
    '_unused82'                            => 0,
    'surfaceConditionIdent'                => 0,
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

 $value = $tsc_resp->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Terrestrial Surface 
Conditions Response packet. The value of this attribute must be 112.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $tsc_resp->packet_size();

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

 $value = $tsc_resp->request_ident($newValue);

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

=item sub surface_condition_ident([$newValue])

 $value = $tsc_resp->surface_condition_ident($newValue);

Surface Condition ID.

This attribute indicates the presence of a specific surface condition or 
contaminant at the test point. Surface condition codes are IG-dependent.

=cut

sub surface_condition_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'surfaceConditionIdent'} = $nv;
  }
  return $self->{'surfaceConditionIdent'};
}

#==========================================================================

=item sub pack()

 $value = $tsc_resp->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'requestIdent'},
        $self->{'_unused82'},
        $self->{'surfaceConditionIdent'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $tsc_resp->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'requestIdent'}                        = $c;
  $self->{'_unused82'}                           = $d;
  $self->{'surfaceConditionIdent'}               = $e;

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
