#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78ae818-200e-11de-bdb4-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::TrajectoryDefinition;

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

Rinchi::CIGIPP::TrajectoryDefinition - Perl extension for the Common Image 
Generator Interface - Trajectory Definition data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::TrajectoryDefinition;
  my $traj_def = Rinchi::CIGIPP::TrajectoryDefinition->new();

  $packet_type = $traj_def->packet_type();
  $packet_size = $traj_def->packet_size();
  $entity_ident = $traj_def->entity_ident(55021);
  $x_acceleration = $traj_def->x_acceleration(60.29);
  $y_acceleration = $traj_def->y_acceleration(33.53);
  $z_acceleration = $traj_def->z_acceleration(3.749);
  $retardation_rate = $traj_def->retardation_rate(5.483);
  $terminal_velocity = $traj_def->terminal_velocity(84.799);

=head1 DESCRIPTION

The Trajectory Definition packet enables the Host to describe a trajectory 
along which an IG-driven entity, such as a tracer round or particulate debris, 
travels. This is useful for simulating gravity and other static forces acting 
upon the entity. This packet is commonly used in conjunction with the Rate 
Control packet.

=head2 EXPORT

None by default.

#==============================================================================

=item new $traj_def = Rinchi::CIGIPP::TrajectoryDefinition->new()

Constructor for Rinchi::TrajectoryDefinition.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78ae818-200e-11de-bdb4-001c25551abc',
    '_Pack'                                => 'CCSfffff',
    '_Swap1'                               => 'CCvVVVVV',
    '_Swap2'                               => 'CCnNNNNN',
    'packetType'                           => 20,
    'packetSize'                           => 24,
    'entityIdent'                          => 0,
    'xAcceleration'                       => 0,
    'yAcceleration'                       => 0,
    'zAcceleration'                       => 0,
    'retardationRate'                     => 0,
    'terminalVelocity'                    => 0,
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

 $value = $traj_def->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Trajectory Definition packet. 
The value of this attribute must be 20.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $traj_def->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 24.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub entity_ident([$newValue])

 $value = $traj_def->entity_ident($newValue);

Entity ID.

This attribute identifies the entity for which the trajectory is defined.

=cut

sub entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'entityIdent'} = $nv;
  }
  return $self->{'entityIdent'};
}

#==============================================================================

=item sub x_acceleration([$newValue])

 $value = $traj_def->x_acceleration($newValue);

Acceleration X.

This attribute specifies the X component of the acceleration vector.

=cut

sub x_acceleration() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'xAcceleration'} = $nv;
  }
  return $self->{'xAcceleration'};
}

#==============================================================================

=item sub y_acceleration([$newValue])

 $value = $traj_def->y_acceleration($newValue);

Acceleration Y.

This attribute specifies the Y component of the acceleration vector.

=cut

sub y_acceleration() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'yAcceleration'} = $nv;
  }
  return $self->{'yAcceleration'};
}

#==============================================================================

=item sub z_acceleration([$newValue])

 $value = $traj_def->z_acceleration($newValue);

Acceleration Z.

This attribute specifies the Z component of the acceleration vector.

=cut

sub z_acceleration() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'zAcceleration'} = $nv;
  }
  return $self->{'zAcceleration'};
}

#==============================================================================

=item sub retardation_rate([$newValue])

 $value = $traj_def->retardation_rate($newValue);

Retardation Rate.

This attribute specifies the magnitude of an acceleration applied against the 
entity's instantaneous linear velocity vector. This is used to simulate drag 
and other frictional forces acting upon the entity.

=cut

sub retardation_rate() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'retardationRate'} = $nv;
  }
  return $self->{'retardationRate'};
}

#==============================================================================

=item sub terminal_velocity([$newValue])

 $value = $traj_def->terminal_velocity($newValue);

Terminal Velocity.

This attribute specifies the maximum velocity the entity can sustain.

=cut

sub terminal_velocity() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'terminalVelocity'} = $nv;
  }
  return $self->{'terminalVelocity'};
}

#==========================================================================

=item sub pack()

 $value = $traj_def->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'entityIdent'},
        $self->{'xAcceleration'},
        $self->{'yAcceleration'},
        $self->{'zAcceleration'},
        $self->{'retardationRate'},
        $self->{'terminalVelocity'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $traj_def->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                         = $a;
  $self->{'packetSize'}                         = $b;
  $self->{'entityIdent'}                        = $c;
  $self->{'xAcceleration'}                      = $d;
  $self->{'yAcceleration'}                      = $e;
  $self->{'zAcceleration'}                      = $f;
  $self->{'retardationRate'}                    = $g;
  $self->{'terminalVelocity'}                   = $h;

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

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h);
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
