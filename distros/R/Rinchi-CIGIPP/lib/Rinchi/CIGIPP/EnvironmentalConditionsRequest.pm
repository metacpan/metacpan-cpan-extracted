#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78afdd0-200e-11de-bdbc-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::EnvironmentalConditionsRequest;

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

Rinchi::CIGIPP::EnvironmentalConditionsRequest - Perl extension for the Common 
Image Generator Interface - Environmental Conditions Request data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::EnvironmentalConditionsRequest;
  my $ec_rqst = Rinchi::CIGIPP::EnvironmentalConditionsRequest->new();

  $packet_type = $ec_rqst->packet_type();
  $packet_size = $ec_rqst->packet_size();
  $request_type_ac = $ec_rqst->request_type_ac(0);
  $request_type_wc = $ec_rqst->request_type_wc(1);
  $request_type_tsc = $ec_rqst->request_type_tsc(0);
  $request_type_msc = $ec_rqst->request_type_msc(0);
  $request_ident = $ec_rqst->request_ident(167);
  $latitude = $ec_rqst->latitude(28.347);
  $longitude = $ec_rqst->longitude(82.085);
  $altitude = $ec_rqst->altitude(38.01);

=head1 DESCRIPTION

At any given location, it may be impossible for the Host to determine exactly 
the visibility range, air temperature, or other atmospheric or surface 
conditions. One factor is that various IG implementations may differ in how 
they calculate values across transition bands and within overlapping regions. 
Random phenomena such as winds aloft, scud, and wave activity may also make 
determining instantaneous conditions at a specific point impossible.

The Environmental Conditions Request packet is used by the Host to request the 
state of the environment at a specific location. The Request Type attribute 
determines what data are returned by the IG. Each request type is represented 
by a power of two (i.e., a unique bit), so request types may be combined by 
adding or bit-wise ORing the values together.

For a given test point, the IG may respond with no more than one of each of the 
Maritime Surface Conditions Response and Weather Conditions Response packets. 
For terrestrial surface conditions requests, the IG should respond with one 
Terrestrial Surface Conditions Response packet for each surface condition type 
or attribute present at the test point. If the Request Type attribute specifies 
that aerosol concentrations should be returned, the IG must send a Weather 
Conditions Aerosol Response packet for each weather layer that encompasses the 
test point.

=head2 EXPORT

None by default.

#==============================================================================

=item new $ec_rqst = Rinchi::CIGIPP::EnvironmentalConditionsRequest->new()

Constructor for Rinchi::EnvironmentalConditionsRequest.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78afdd0-200e-11de-bdbc-001c25551abc',
    '_Pack'                                => 'CCCCIddd',
    '_Swap1'                               => 'CCCCVVVVVVV',
    '_Swap2'                               => 'CCCCNNNNNNN',
    'packetType'                           => 28,
    'packetSize'                           => 32,
    '_bitfields1'                          => 0, # Includes bitfields unused49, requestTypeAC, requestTypeWC, requestTypeTSC, and requestTypeMSC.
    'requestTypeAC'                        => 0,
    'requestTypeWC'                        => 0,
    'requestTypeTSC'                       => 0,
    'requestTypeMSC'                       => 0,
    'requestIdent'                         => 0,
    '_unused50'                            => 0,
    'latitude'                             => 0,
    'longitude'                            => 0,
    'altitude'                             => 0,
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

 $value = $ec_rqst->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Environmental Conditions 
Request packet. The value of this attribute must be 28.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $ec_rqst->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 32.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub request_type_ac([$newValue])

 $value = $ec_rqst->request_type_ac($newValue);

Request Type.

This attribute specifies the desired response type for the request. The 
numerical values listed at left may be combined by addition or bit-wise OR. The 
resulting value may be any combination of the following:

Aerosol Concentrations – The IG will send exactly one Aerosol Concentration 
Response packet for each weather layer (regardless of scope) that encompasses 
that location.

=cut

sub request_type_ac() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'requestTypeAC'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 3) &0x08;
    } else {
      carp "request_type_ac must be 0 or 1.";
    }
  }
  return (($self->{'_bitfields1'} & 0x08) >> 3);
}

#==============================================================================

=item sub request_type_wc([$newValue])

 $value = $ec_rqst->request_type_wc($newValue);

Request Type.

This attribute specifies the desired response type for the request. The 
numerical values listed at left may be combined by addition or bit-wise OR. The 
resulting value may be any combination of the following:

Weather Conditions – The IG will respond with a Weather Conditions Response packet.

=cut

sub request_type_wc() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'requestTypeWC'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "request_type_wc must be 0 or 1.";
    }
  }
  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub request_type_tsc([$newValue])

 $value = $ec_rqst->request_type_tsc($newValue);

Request Type.

This attribute specifies the desired response type for the request. The 
numerical values listed at left may be combined by addition or bit-wise OR. The 
resulting value may be any combination of the following:

Terrestrial Surface Conditions – The IG will respond with a Terrestrial Surface 
Conditions Response packet.

=cut

sub request_type_tsc() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'requestTypeTSC'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 1) &0x02;
    } else {
      carp "request_type_tsc must be 0 or 1.";
    }
  }
  return (($self->{'_bitfields1'} & 0x02) >> 1);
}

#==============================================================================

=item sub request_type_msc([$newValue])

 $value = $ec_rqst->request_type_msc($newValue);

Request Type.

This attribute specifies the desired response type for the request. The 
numerical values listed at left may be combined by addition or bit-wise OR. The 
resulting value may be any combination of the following:

Maritime Surface Conditions – The IG will respond with a Maritime Surface 
Conditions Response packet.

=cut

sub request_type_msc() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'requestTypeMSC'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "request_type_msc must be 0 or 1.";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub request_ident([$newValue])

 $value = $ec_rqst->request_ident($newValue);

Request ID.

This attribute identifies the environmental conditions request. When the IG 
returns a responds to the request, each response packet(s) will contain this 
value in its Request ID attribute.

=cut

sub request_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'requestIdent'} = $nv;
  }
  return $self->{'requestIdent'};
}

#==============================================================================

=item sub latitude([$newValue])

 $value = $ec_rqst->latitude($newValue);

Latitude.

This attribute specifies the geodetic latitude at which the environmental state 
is requested.

=cut

sub latitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'latitude'} = $nv;
  }
  return $self->{'latitude'};
}

#==============================================================================

=item sub longitude([$newValue])

 $value = $ec_rqst->longitude($newValue);

Longitude.

This attribute specifies the geodetic longitude at which the environmental 
state is requested.

=cut

sub longitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'longitude'} = $nv;
  }
  return $self->{'longitude'};
}

#==============================================================================

=item sub altitude([$newValue])

 $value = $ec_rqst->altitude($newValue);

Altitude.

This attribute specifies the geodetic altitude in meters above mean sea level 
at which the environmental state is requested.

This attribute is used only for weather conditions and aerosol concentrations requests.

=cut

sub altitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'altitude'} = $nv;
  }
  return $self->{'altitude'};
}

#==========================================================================

=item sub pack()

 $value = $ec_rqst->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'_bitfields1'},    # Includes bitfields unused49, requestTypeAC, requestTypeWC, requestTypeTSC, and requestTypeMSC.
        $self->{'requestIdent'},
        $self->{'_unused50'},
        $self->{'latitude'},
        $self->{'longitude'},
        $self->{'altitude'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $ec_rqst->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'_bitfields1'}                         = $c; # Includes bitfields unused49, requestTypeAC, requestTypeWC, requestTypeTSC, and requestTypeMSC.
  $self->{'requestIdent'}                        = $d;
  $self->{'_unused50'}                           = $e;
  $self->{'latitude'}                            = $f;
  $self->{'longitude'}                           = $g;
  $self->{'altitude'}                            = $h;

  $self->{'requestTypeAC'}                       = $self->request_type_ac();
  $self->{'requestTypeWC'}                       = $self->request_type_wc();
  $self->{'requestTypeTSC'}                      = $self->request_type_tsc();
  $self->{'requestTypeMSC'}                      = $self->request_type_msc();

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

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$g,$f,$i,$h,$k,$j);
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
