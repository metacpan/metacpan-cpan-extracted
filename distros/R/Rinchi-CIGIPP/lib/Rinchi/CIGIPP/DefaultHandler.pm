package Rinchi::CIGIPP::DefaultHandler;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Rinchi::CIGIPP ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Rinchi::CIGIPP - Perl extension for the Common Image Generator Interface.

=head1 SYNOPSIS

  use Rinchi::CIGIPP;
  blah blah blah

=head1 DESCRIPTION

This module provides an interface between an image generator and host computer 
that is compliant with the CIGI ICD version 3.3. 

=head2 EXPORT

None by default.

=head1 METHODS

=over 4

=cut

#==============================================================================

=item new

Constructor for Rinchi::CIGIPP::DefaultHandler.

=cut

sub new {
  my ($class, %args) = @_;
  my $self = bless \%args, $class;
  $args{'_Handlers'} = {
    'StartOfMessage'                        => \&start_of_message_handler,
    'EndOfMessage'                          => \&end_of_message_handler,
    'IGControl'                             => \&IGControl_packet_handler,
    'EntityControl'                         => \&EntityControl_packet_handler,
    'ConformalClampedEntityControl'         => \&ConformalClampedEntityControl_packet_handler,
    'ComponentControl'                      => \&ComponentControl_packet_handler,
    'ShortComponentControl'                 => \&ShortComponentControl_packet_handler,
    'ArticulatedPartControl'                => \&ArticulatedPartControl_packet_handler,
    'ShortArticulatedPartControl'           => \&ShortArticulatedPartControl_packet_handler,
    'RateControl'                           => \&RateControl_packet_handler,
    'CelestialSphereControl'                => \&CelestialSphereControl_packet_handler,
    'AtmosphereControl'                     => \&AtmosphereControl_packet_handler,
    'EnvironmentalRegionControl'            => \&EnvironmentalRegionControl_packet_handler,
    'WeatherControl'                        => \&WeatherControl_packet_handler,
    'MaritimeSurfaceConditionsControl'      => \&MaritimeSurfaceConditionsControl_packet_handler,
    'WaveControl'                           => \&WaveControl_packet_handler,
    'TerrestrialSurfaceConditionsControl'   => \&TerrestrialSurfaceConditionsControl_packet_handler,
    'ViewControl'                           => \&ViewControl_packet_handler,
    'SensorControl'                         => \&SensorControl_packet_handler,
    'MotionTrackerControl'                  => \&MotionTrackerControl_packet_handler,
    'EarthReferenceModelDefinition'         => \&EarthReferenceModelDefinition_packet_handler,
    'TrajectoryDefinition'                  => \&TrajectoryDefinition_packet_handler,
    'ViewDefinition'                        => \&ViewDefinition_packet_handler,
    'CollisionDetectionSegmentDefinition'   => \&CollisionDetectionSegmentDefinition_packet_handler,
    'CollisionDetectionVolumeDefinition'    => \&CollisionDetectionVolumeDefinition_packet_handler,
    'HAT_HOTRequest'                        => \&HAT_HOTRequest_packet_handler,
    'LineOfSightSegmentRequest'             => \&LineOfSightSegmentRequest_packet_handler,
    'LineOfSightVectorRequest'              => \&LineOfSightVectorRequest_packet_handler,
    'PositionRequest'                       => \&PositionRequest_packet_handler,
    'EnvironmentalConditionsRequest'        => \&EnvironmentalConditionsRequest_packet_handler,
    'SymbolSurfaceDefinition'               => \&SymbolSurfaceDefinition_packet_handler,
    'SymbolTextDefinition'                  => \&SymbolTextDefinition_packet_handler,
    'SymbolCircleDefinition'                => \&SymbolCircleDefinition_packet_handler,
    'SymbolCircle'                          => \&SymbolCircle_packet_handler,
    'SymbolLineDefinition'                  => \&SymbolLineDefinition_packet_handler,
    'SymbolLineVertex'                      => \&SymbolLineVertex_packet_handler,
    'SymbolClone'                           => \&SymbolClone_packet_handler,
    'SymbolControl'                         => \&SymbolControl_packet_handler,
    'ShortSymbolControl'                    => \&ShortSymbolControl_packet_handler,
    'StartOfFrame'                          => \&StartOfFrame_packet_handler,
    'HAT_HOTResponse'                       => \&HAT_HOTResponse_packet_handler,
    'HAT_HOTExtendedResponse'               => \&HAT_HOTExtendedResponse_packet_handler,
    'LineOfSightResponse'                   => \&LineOfSightResponse_packet_handler,
    'LineOfSightExtendedResponse'           => \&LineOfSightExtendedResponse_packet_handler,
    'SensorResponse'                        => \&SensorResponse_packet_handler,
    'SensorExtendedResponse'                => \&SensorExtendedResponse_packet_handler,
    'PositionResponse'                      => \&PositionResponse_packet_handler,
    'WeatherConditionsResponse'             => \&WeatherConditionsResponse_packet_handler,
    'AerosolConcentrationResponse'          => \&AerosolConcentrationResponse_packet_handler,
    'MaritimeSurfaceConditionsResponse'     => \&MaritimeSurfaceConditionsResponse_packet_handler,
    'TerrestrialSurfaceConditionsResponse'  => \&TerrestrialSurfaceConditionsResponse_packet_handler,
    'CollisionDetectionSegmentNotification' => \&CollisionDetectionSegmentNotification_packet_handler,
    'CollisionDetectionVolumeNotification'  => \&CollisionDetectionVolumeNotification_packet_handler,
    'AnimationStopNotification'             => \&AnimationStopNotification_packet_handler,
    'EventNotification'                     => \&EventNotification_packet_handler,
    'ImageGeneratorMessage'                 => \&ImageGeneratorMessage_packet_handler,
  };

  return $self;
}

#==============================================================================

=item get_handlers()

Get the handlers for message and packet events.

=cut

sub get_handlers() {
  my ($self) = @_;
  return $self->{'_Handlers'};
}

#==============================================================================

=item start_of_message_handler($message_number)

Handler for start of message events.

=cut

sub start_of_message_handler() {
  my ($message_number) = @_;
  print "  <message number=\"$message_number\">\n";
}

#==============================================================================

=item end_of_message_handler($message_number)

Handler for end of message events.

=cut

sub end_of_message_handler() {
  my ($message_number) = @_;
  print "  </message>\n";
}

#==============================================================================

=item IGControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for IGControl data packets.

=cut

sub IGControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item EntityControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for EntityControl data packets.

=cut

sub EntityControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item ConformalClampedEntityControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for ConformalClampedEntityControl data packets.

=cut

sub ConformalClampedEntityControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item ComponentControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for ComponentControl data packets.

=cut

sub ComponentControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item ShortComponentControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for ShortComponentControl data packets.

=cut

sub ShortComponentControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item ArticulatedPartControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for ArticulatedPartControl data packets.

=cut

sub ArticulatedPartControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item ShortArticulatedPartControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for ShortArticulatedPartControl data packets.

=cut

sub ShortArticulatedPartControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item RateControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for RateControl data packets.

=cut

sub RateControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item CelestialSphereControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for CelestialSphereControl data packets.

=cut

sub CelestialSphereControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item AtmosphereControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for AtmosphereControl data packets.

=cut

sub AtmosphereControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item EnvironmentalRegionControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for EnvironmentalRegionControl data packets.

=cut

sub EnvironmentalRegionControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item WeatherControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for WeatherControl data packets.

=cut

sub WeatherControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item MaritimeSurfaceConditionsControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for MaritimeSurfaceConditionsControl data packets.

=cut

sub MaritimeSurfaceConditionsControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item WaveControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for WaveControl data packets.

=cut

sub WaveControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item TerrestrialSurfaceConditionsControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for TerrestrialSurfaceConditionsControl data packets.

=cut

sub TerrestrialSurfaceConditionsControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item ViewControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for ViewControl data packets.

=cut

sub ViewControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item SensorControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for SensorControl data packets.

=cut

sub SensorControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item MotionTrackerControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for MotionTrackerControl data packets.

=cut

sub MotionTrackerControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item EarthReferenceModelDefinition_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for EarthReferenceModelDefinition data packets.

=cut

sub EarthReferenceModelDefinition_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item TrajectoryDefinition_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for TrajectoryDefinition data packets.

=cut

sub TrajectoryDefinition_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item ViewDefinition_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for ViewDefinition data packets.

=cut

sub ViewDefinition_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item CollisionDetectionSegmentDefinition_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for CollisionDetectionSegmentDefinition data packets.

=cut

sub CollisionDetectionSegmentDefinition_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item CollisionDetectionVolumeDefinition_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for CollisionDetectionVolumeDefinition data packets.

=cut

sub CollisionDetectionVolumeDefinition_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item HAT_HOTRequest_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for HAT_HOTRequest data packets.

=cut

sub HAT_HOTRequest_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item LineOfSightSegmentRequest_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for LineOfSightSegmentRequest data packets.

=cut

sub LineOfSightSegmentRequest_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item LineOfSightVectorRequest_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for LineOfSightVectorRequest data packets.

=cut

sub LineOfSightVectorRequest_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item PositionRequest_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for PositionRequest data packets.

=cut

sub PositionRequest_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item EnvironmentalConditionsRequest_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for EnvironmentalConditionsRequest data packets.

=cut

sub EnvironmentalConditionsRequest_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item SymbolSurfaceDefinition_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for SymbolSurfaceDefinition data packets.

=cut

sub SymbolSurfaceDefinition_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item SymbolTextDefinition_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for SymbolTextDefinition data packets.

=cut

sub SymbolTextDefinition_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item SymbolCircleDefinition_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for SymbolCircleDefinition data packets.

=cut

sub SymbolCircleDefinition_packet_handler() {
  my ($tag, $circles, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
#    $val =~ s/&/&amp;/g;
#    $val =~ s/</&lt;/g;
#    $val =~ s/>/&gt;/g;
#    $val =~ s/\"/&quot;/g;
#    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print ">\n";
  foreach my $circle (@{$circles}) {
    my ($ctag, %cattrs) = @{$circle};
    print "      <$ctag";
    foreach my $cattr (sort keys %cattrs) {
      my $cval = $cattrs{$cattr};
#      $cval =~ s/&/&amp;/g;s
#      $cval =~ s/</&lt;/g;
#      $cval =~ s/>/&gt;/g;
#      $cval =~ s/\"/&quot;/g;
#      $cval =~ s/\'/&apos;/g;
      print " $cattr=\"$cval\"";
    }
    print " />\n";
  }
  print "    </$tag>\n";
}
#==============================================================================

=item SymbolCircle_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for SymbolCircle data packets.

=cut

sub SymbolCircle_packet_handler() {
  my ($tag, %attrs) = @_;
#  print "    <$tag";
#  foreach my $attr (sort keys %attrs) {
#    my $val = $attrs{$attr};
#    $val =~ s/&/&amp;/g;
#    $val =~ s/</&lt;/g;
#    $val =~ s/>/&gt;/g;
#    $val =~ s/\"/&quot;/g;
#    $val =~ s/\'/&apos;/g;
#    print " $attr=\"$val\"";
#  }
#  print " />\n";
}
#==============================================================================

=item SymbolLineDefinition_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for SymbolLineDefinition data packets.

=cut

sub SymbolLineDefinition_packet_handler() {
  my ($tag, $vertices, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
#    $val =~ s/&/&amp;/g;
#    $val =~ s/</&lt;/g;
#    $val =~ s/>/&gt;/g;
#    $val =~ s/\"/&quot;/g;
#    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print ">\n";
  foreach my $vertex (@{$vertices}) {
    my ($vtag, %vattrs) = @{$vertex};
    print "      <$vtag";
    foreach my $vattr (sort keys %vattrs) {
      my $vval = $vattrs{$vattr};
#      $vval =~ s/&/&amp;/g;s
#      $vval =~ s/</&lt;/g;
#      $vval =~ s/>/&gt;/g;
#      $vval =~ s/\"/&quot;/g;
#      $vval =~ s/\'/&apos;/g;
      print " $vattr=\"$vval\"";
    }
    print " />\n";
  }
  print "    </$tag>\n";
}
#==============================================================================

=item SymbolLineVertex_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for SymbolLineVertex data packets.

=cut

sub SymbolLineVertex_packet_handler() {
  my ($tag, %attrs) = @_;
#  print "    <$tag";
#  foreach my $attr (sort keys %attrs) {
#    my $val = $attrs{$attr};
#    $val =~ s/&/&amp;/g;
#    $val =~ s/</&lt;/g;
#    $val =~ s/>/&gt;/g;
#    $val =~ s/\"/&quot;/g;
#    $val =~ s/\'/&apos;/g;
#    print " $attr=\"$val\"";
#  }
#  print " />\n";
}
#==============================================================================

=item SymbolClone_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for SymbolClone data packets.

=cut

sub SymbolClone_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item SymbolControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for SymbolControl data packets.

=cut

sub SymbolControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item ShortSymbolControl_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for ShortSymbolControl data packets.

=cut

sub ShortSymbolControl_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item StartOfFrame_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for StartOfFrame data packets.

=cut

sub StartOfFrame_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item HAT_HOTResponse_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for HAT_HOTResponse data packets.

=cut

sub HAT_HOTResponse_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item HAT_HOTExtendedResponse_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for HAT_HOTExtendedResponse data packets.

=cut

sub HAT_HOTExtendedResponse_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item LineOfSightResponse_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for LineOfSightResponse data packets.

=cut

sub LineOfSightResponse_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item LineOfSightExtendedResponse_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for LineOfSightExtendedResponse data packets.

=cut

sub LineOfSightExtendedResponse_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item SensorResponse_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for SensorResponse data packets.

=cut

sub SensorResponse_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item SensorExtendedResponse_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for SensorExtendedResponse data packets.

=cut

sub SensorExtendedResponse_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item PositionResponse_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for PositionResponse data packets.

=cut

sub PositionResponse_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item WeatherConditionsResponse_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for WeatherConditionsResponse data packets.

=cut

sub WeatherConditionsResponse_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item AerosolConcentrationResponse_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for AerosolConcentrationResponse data packets.

=cut

sub AerosolConcentrationResponse_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item MaritimeSurfaceConditionsResponse_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for MaritimeSurfaceConditionsResponse data packets.

=cut

sub MaritimeSurfaceConditionsResponse_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item TerrestrialSurfaceConditionsResponse_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for TerrestrialSurfaceConditionsResponse data packets.

=cut

sub TerrestrialSurfaceConditionsResponse_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item CollisionDetectionSegmentNotification_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for CollisionDetectionSegmentNotification data packets.

=cut

sub CollisionDetectionSegmentNotification_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item CollisionDetectionVolumeNotification_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for CollisionDetectionVolumeNotification data packets.

=cut

sub CollisionDetectionVolumeNotification_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item AnimationStopNotification_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for AnimationStopNotification data packets.

=cut

sub AnimationStopNotification_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item EventNotification_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for EventNotification data packets.

=cut

sub EventNotification_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

=item ImageGeneratorMessage_packet_handler($tag_name, [$attr_name, $attr_val [, $attr_name, $attr_val]...])

Handler for ImageGeneratorMessage data packets.

=cut

sub ImageGeneratorMessage_packet_handler() {
  my ($tag, %attrs) = @_;
  print "    <$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  print " />\n";
}
#==============================================================================

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

1;
__END__
