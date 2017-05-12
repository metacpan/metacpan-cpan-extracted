#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b3deb-200e-11de-bdd4-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::AnimationStopNotification;

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

Rinchi::CIGIPP::AnimationStopNotification - Perl extension for the Common Image 
Generator Interface - Animation Stop Notification data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::AnimationStopNotification;
  my $stop_ntc = Rinchi::CIGIPP::AnimationStopNotification->new();

  $packet_type = $stop_ntc->packet_type();
  $packet_size = $stop_ntc->packet_size();
  $entity_ident = $stop_ntc->entity_ident(44464);

=head1 DESCRIPTION

The Animation Stop Notification packet is used to indicate to the Host when an 
animation has played to the end of its animation sequence.

=head2 EXPORT

None by default.

#==============================================================================

=item new $stop_ntc = Rinchi::CIGIPP::AnimationStopNotification->new()

Constructor for Rinchi::AnimationStopNotification.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b3deb-200e-11de-bdd4-001c25551abc',
    '_Pack'                                => 'CCSI',
    '_Swap1'                               => 'CCvV',
    '_Swap2'                               => 'CCnN',
    'packetType'                          => 115,
    'packetSize'                          => 8,
    'entityIdent'                         => 0,
    '_unused88'                            => 0,
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

 $value = $stop_ntc->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Animation Stop Notification 
packet. The value of this attribute must be 115.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $stop_ntc->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 8.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub entity_ident([$newValue])

 $value = $stop_ntc->entity_ident($newValue);

Entity ID.

This attribute indicates the entity ID of the animation that has stopped.

=cut

sub entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'entityIdent'} = $nv;
  }
  return $self->{'entityIdent'};
}

#==========================================================================

=item sub pack()

 $value = $stop_ntc->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'entityIdent'},
        $self->{'_unused88'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $stop_ntc->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                         = $a;
  $self->{'packetSize'}                         = $b;
  $self->{'entityIdent'}                        = $c;
  $self->{'_unused88'}                           = $d;

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
  my ($a,$b,$c,$d) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d);
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
