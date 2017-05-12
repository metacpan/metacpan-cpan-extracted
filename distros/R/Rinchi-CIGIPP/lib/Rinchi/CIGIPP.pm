package Rinchi::CIGIPP;

use 5.006;
use strict;
use warnings;
use Carp;
use IO::Select;
use IO::Socket;

use Rinchi::CIGIPP::IGControl;
use Rinchi::CIGIPP::EntityControl;
use Rinchi::CIGIPP::ConformalClampedEntityControl;
use Rinchi::CIGIPP::ComponentControl;
use Rinchi::CIGIPP::ShortComponentControl;
use Rinchi::CIGIPP::ArticulatedPartControl;
use Rinchi::CIGIPP::ShortArticulatedPartControl;
use Rinchi::CIGIPP::RateControl;
use Rinchi::CIGIPP::CelestialSphereControl;
use Rinchi::CIGIPP::AtmosphereControl;
use Rinchi::CIGIPP::EnvironmentalRegionControl;
use Rinchi::CIGIPP::WeatherControl;
use Rinchi::CIGIPP::MaritimeSurfaceConditionsControl;
use Rinchi::CIGIPP::WaveControl;
use Rinchi::CIGIPP::TerrestrialSurfaceConditionsControl;
use Rinchi::CIGIPP::ViewControl;
use Rinchi::CIGIPP::SensorControl;
use Rinchi::CIGIPP::MotionTrackerControl;
use Rinchi::CIGIPP::EarthReferenceModelDefinition;
use Rinchi::CIGIPP::TrajectoryDefinition;
use Rinchi::CIGIPP::ViewDefinition;
use Rinchi::CIGIPP::CollisionDetectionSegmentDefinition;
use Rinchi::CIGIPP::CollisionDetectionVolumeDefinition;
use Rinchi::CIGIPP::HAT_HOTRequest;
use Rinchi::CIGIPP::LineOfSightSegmentRequest;
use Rinchi::CIGIPP::LineOfSightVectorRequest;
use Rinchi::CIGIPP::PositionRequest;
use Rinchi::CIGIPP::EnvironmentalConditionsRequest;
use Rinchi::CIGIPP::SymbolSurfaceDefinition;
use Rinchi::CIGIPP::SymbolTextDefinition;
use Rinchi::CIGIPP::SymbolCircleDefinition;
#use Rinchi::CIGIPP::SymbolCircle;
use Rinchi::CIGIPP::SymbolLineDefinition;
#use Rinchi::CIGIPP::SymbolLineVertex;
use Rinchi::CIGIPP::SymbolClone;
use Rinchi::CIGIPP::SymbolControl;
use Rinchi::CIGIPP::ShortSymbolControl;
use Rinchi::CIGIPP::StartOfFrame;
use Rinchi::CIGIPP::HAT_HOTResponse;
use Rinchi::CIGIPP::HAT_HOTExtendedResponse;
use Rinchi::CIGIPP::LineOfSightResponse;
use Rinchi::CIGIPP::LineOfSightExtendedResponse;
use Rinchi::CIGIPP::SensorResponse;
use Rinchi::CIGIPP::SensorExtendedResponse;
use Rinchi::CIGIPP::PositionResponse;
use Rinchi::CIGIPP::WeatherConditionsResponse;
use Rinchi::CIGIPP::AerosolConcentrationResponse;
use Rinchi::CIGIPP::MaritimeSurfaceConditionsResponse;
use Rinchi::CIGIPP::TerrestrialSurfaceConditionsResponse;
use Rinchi::CIGIPP::CollisionDetectionSegmentNotification;
use Rinchi::CIGIPP::CollisionDetectionVolumeNotification;
use Rinchi::CIGIPP::AnimationStopNotification;
use Rinchi::CIGIPP::EventNotification;
use Rinchi::CIGIPP::ImageGeneratorMessage;

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

our $VERSION = '0.02';

our %Handler_Setters = (
    StartOfMessage                        => \&SetStartOfMessageHandler,
    EndOfMessage                          => \&SetEndOfMessageHandler,
    IGControl                             => \&SetIGControlHandler,
    EntityControl                         => \&SetEntityControlHandler,
    ConformalClampedEntityControl         => \&SetConformalClampedEntityControlHandler,
    ComponentControl                      => \&SetComponentControlHandler,
    ShortComponentControl                 => \&SetShortComponentControlHandler,
    ArticulatedPartControl                => \&SetArticulatedPartControlHandler,
    ShortArticulatedPartControl           => \&SetShortArticulatedPartControlHandler,
    RateControl                           => \&SetRateControlHandler,
    CelestialSphereControl                => \&SetCelestialSphereControlHandler,
    AtmosphereControl                     => \&SetAtmosphereControlHandler,
    EnvironmentalRegionControl            => \&SetEnvironmentalRegionControlHandler,
    WeatherControl                        => \&SetWeatherControlHandler,
    MaritimeSurfaceConditionsControl      => \&SetMaritimeSurfaceConditionsControlHandler,
    WaveControl                           => \&SetWaveControlHandler,
    TerrestrialSurfaceConditionsControl   => \&SetTerrestrialSurfaceConditionsControlHandler,
    ViewControl                           => \&SetViewControlHandler,
    SensorControl                         => \&SetSensorControlHandler,
    MotionTrackerControl                  => \&SetMotionTrackerControlHandler,
    EarthReferenceModelDefinition         => \&SetEarthReferenceModelDefinitionHandler,
    TrajectoryDefinition                  => \&SetTrajectoryDefinitionHandler,
    ViewDefinition                        => \&SetViewDefinitionHandler,
    CollisionDetectionSegmentDefinition   => \&SetCollisionDetectionSegmentDefinitionHandler,
    CollisionDetectionVolumeDefinition    => \&SetCollisionDetectionVolumeDefinitionHandler,
    HAT_HOTRequest                        => \&SetHAT_HOTRequestHandler,
    LineOfSightSegmentRequest             => \&SetLineOfSightSegmentRequestHandler,
    LineOfSightVectorRequest              => \&SetLineOfSightVectorRequestHandler,
    PositionRequest                       => \&SetPositionRequestHandler,
    EnvironmentalConditionsRequest        => \&SetEnvironmentalConditionsRequestHandler,
    SymbolSurfaceDefinition               => \&SetSymbolSurfaceDefinitionHandler,
    SymbolTextDefinition                  => \&SetSymbolTextDefinitionHandler,
    SymbolCircleDefinition                => \&SetSymbolCircleDefinitionHandler,
    SymbolCircle                          => \&SetSymbolCircleHandler,
    SymbolLineDefinition                  => \&SetSymbolLineDefinitionHandler,
    SymbolLineVertex                      => \&SetSymbolLineVertexHandler,
    SymbolClone                           => \&SetSymbolCloneHandler,
    SymbolControl                         => \&SetSymbolControlHandler,
    ShortSymbolControl                    => \&SetShortSymbolControlHandler,
    StartOfFrame                          => \&SetStartOfFrameHandler,
    HAT_HOTResponse                       => \&SetHAT_HOTResponseHandler,
    HAT_HOTExtendedResponse               => \&SetHAT_HOTExtendedResponseHandler,
    LineOfSightResponse                   => \&SetLineOfSightResponseHandler,
    LineOfSightExtendedResponse           => \&SetLineOfSightExtendedResponseHandler,
    SensorResponse                        => \&SetSensorResponseHandler,
    SensorExtendedResponse                => \&SetSensorExtendedResponseHandler,
    PositionResponse                      => \&SetPositionResponseHandler,
    WeatherConditionsResponse             => \&SetWeatherConditionsResponseHandler,
    AerosolConcentrationResponse          => \&SetAerosolConcentrationResponseHandler,
    MaritimeSurfaceConditionsResponse     => \&SetMaritimeSurfaceConditionsResponseHandler,
    TerrestrialSurfaceConditionsResponse  => \&SetTerrestrialSurfaceConditionsResponseHandler,
    CollisionDetectionSegmentNotification => \&SetCollisionDetectionSegmentNotificationHandler,
    CollisionDetectionVolumeNotification  => \&SetCollisionDetectionVolumeNotificationHandler,
    AnimationStopNotification             => \&SetAnimationStopNotificationHandler,
    EventNotification                     => \&SetEventNotificationHandler,
    ImageGeneratorMessage                 => \&SetImageGeneratorMessageHandler,
);

our @opcode_list = (
  [1, 'IGControl',],
  [2, 'EntityControl',],
  [3, 'ConformalClampedEntityControl',],
  [4, 'ComponentControl',],
  [5, 'ShortComponentControl',],
  [6, 'ArticulatedPartControl',],
  [7, 'ShortArticulatedPartControl',],
  [8, 'RateControl',],
  [9, 'CelestialSphereControl',],
  [10, 'AtmosphereControl',],
  [11, 'EnvironmentalRegionControl',],
  [12, 'WeatherControl',],
  [13, 'MaritimeSurfaceConditionsControl',],
  [14, 'WaveControl',],
  [15, 'TerrestrialSurfaceConditionsControl',],
  [16, 'ViewControl',],
  [17, 'SensorControl',],
  [18, 'MotionTrackerControl',],
  [19, 'EarthReferenceModelDefinition',],
  [20, 'TrajectoryDefinition',],
  [21, 'ViewDefinition',],
  [22, 'CollisionDetectionSegmentDefinition',],
  [23, 'CollisionDetectionVolumeDefinition',],
  [24, 'HAT_HOTRequest',],
  [25, 'LineOfSightSegmentRequest',],
  [26, 'LineOfSightVectorRequest',],
  [27, 'PositionRequest',],
  [28, 'EnvironmentalConditionsRequest',],
  [29, 'SymbolSurfaceDefinition',],
  [30, 'SymbolTextDefinition',],
  [31, 'SymbolCircleDefinition',],
  [32, 'SymbolLineDefinition',],
  [33, 'SymbolClone',],
  [34, 'SymbolControl',],
  [35, 'ShortSymbolControl',],
  [101, 'StartOfFrame',],
  [102, 'HAT_HOTResponse',],
  [103, 'HAT_HOTExtendedResponse',],
  [104, 'LineOfSightResponse',],
  [105, 'LineOfSightExtendedResponse',],
  [106, 'SensorResponse',],
  [107, 'SensorExtendedResponse',],
  [108, 'PositionResponse',],
  [109, 'WeatherConditionsResponse',],
  [110, 'AerosolConcentrationResponse',],
  [111, 'MaritimeSurfaceConditionsResponse',],
  [112, 'TerrestrialSurfaceConditionsResponse',],
  [113, 'CollisionDetectionSegmentNotification',],
  [114, 'CollisionDetectionVolumeNotification',],
  [115, 'AnimationStopNotification',],
  [116, 'EventNotification',],
  [117, 'ImageGeneratorMessage',],
);

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Rinchi::CIGIPP - Perl extension for the Common Image Generator Interface.

=head1 SYNOPSIS

  use Rinchi::CIGIPP;
  use Rinchi::CIGIPP::DefaultHandler;

  my $cigi = Rinchi::CIGIPP->new();
  my $hdlr = Rinchi::CIGIPP::DefaultHandler->new();
  my @hp = %{$hdlr->get_handlers()};
  $cigi->setHandlers(@hp);

  my @message;

  my $ig_ctl = Rinchi::CIGIPP::IGControl->new();
  push @message,$ig_ctl;

  my $ent_ctl = Rinchi::CIGIPP::EntityControl->new();
  push @message,$ent_ctl;

  my $ccent_ctl = Rinchi::CIGIPP::ConformalClampedEntityControl->new();
  push @message,$ccent_ctl;

  my $cmp_ctl = Rinchi::CIGIPP::ComponentControl->new();
  push @message,$cmp_ctl;

  my $scmp_ctl = Rinchi::CIGIPP::ShortComponentControl->new();
  push @message,$scmp_ctl;

  my $ap_ctl = Rinchi::CIGIPP::ArticulatedPartControl->new();
  push @message,$ap_ctl;

  my $sap_ctl = Rinchi::CIGIPP::ShortArticulatedPartControl->new();
  push @message,$sap_ctl;

  my $rate_ctl = Rinchi::CIGIPP::RateControl->new();
  push @message,$rate_ctl;

  my $sky_ctl = Rinchi::CIGIPP::CelestialSphereControl->new();
  push @message,$sky_ctl;

  my $atmos_ctl = Rinchi::CIGIPP::AtmosphereControl->new();
  push @message,$atmos_ctl;

  my $env_ctl = Rinchi::CIGIPP::EnvironmentalRegionControl->new();
  push @message,$env_ctl;

  my $wthr_ctl = Rinchi::CIGIPP::WeatherControl->new();
  push @message,$wthr_ctl;

  my $msc_ctl = Rinchi::CIGIPP::MaritimeSurfaceConditionsControl->new();
  push @message,$msc_ctl;

  my $wave_ctl = Rinchi::CIGIPP::WaveControl->new();
  push @message,$wave_ctl;

  my $tsc_ctl = Rinchi::CIGIPP::TerrestrialSurfaceConditionsControl->new();
  push @message,$tsc_ctl;

  my $view_ctl = Rinchi::CIGIPP::ViewControl->new();
  push @message,$view_ctl;

  my $sensor_ctl = Rinchi::CIGIPP::SensorControl->new();
  push @message,$sensor_ctl;

  my $mt_ctl = Rinchi::CIGIPP::MotionTrackerControl->new();
  push @message,$mt_ctl;

  my $erm_def = Rinchi::CIGIPP::EarthReferenceModelDefinition->new();
  push @message,$erm_def;

  my $traj_def = Rinchi::CIGIPP::TrajectoryDefinition->new();
  push @message,$traj_def;

  my $view_def = Rinchi::CIGIPP::ViewDefinition->new();
  push @message,$view_def;

  my $cds_def = Rinchi::CIGIPP::CollisionDetectionSegmentDefinition->new();
  push @message,$cds_def;

  my $cdv_def = Rinchi::CIGIPP::CollisionDetectionVolumeDefinition->new();
  push @message,$cdv_def;

  my $hgt_rqst = Rinchi::CIGIPP::HAT_HOTRequest->new();
  push @message,$hgt_rqst;

  my $loss_rqst = Rinchi::CIGIPP::LineOfSightSegmentRequest->new();
  push @message,$loss_rqst;

  my $losv_rqst = Rinchi::CIGIPP::LineOfSightVectorRequest->new();
  push @message,$losv_rqst;

  my $pos_rqst = Rinchi::CIGIPP::PositionRequest->new();
  push @message,$pos_rqst;

  my $ec_rqst = Rinchi::CIGIPP::EnvironmentalConditionsRequest->new();
  push @message,$ec_rqst;

  my $sym_surf = Rinchi::CIGIPP::SymbolSurfaceDefinition->new();
  push @message,$sym_surf;

  my $sym_text = Rinchi::CIGIPP::SymbolTextDefinition->new();
  push @message,$sym_text;

  my $sym_circ = Rinchi::CIGIPP::SymbolCircleDefinition->new();
  push @message,$sym_circ;

  my $circle0 = Rinchi::CIGIPP::SymbolCircle->new();
  $sym_circ->circle(0, $circle0);

  my $circle1 = Rinchi::CIGIPP::SymbolCircle->new();
  $sym_circ->circle(1, $circle1);

  my $sym_line = Rinchi::CIGIPP::SymbolLineDefinition->new();
  push @message,$sym_line;

  my $vertex0 = Rinchi::CIGIPP::SymbolVertex->new();
  $sym_line->vertex(0, $vertex0);

  my $vertex1 = Rinchi::CIGIPP::SymbolVertex->new();
  $sym_line->vertex(1, $vertex1);

  my $vertex2 = Rinchi::CIGIPP::SymbolVertex->new();
  $sym_line->vertex(2, $vertex2);

  my $vertex3 = Rinchi::CIGIPP::SymbolVertex->new();
  $sym_line->vertex(3, $vertex3);

  my $sym_clone = Rinchi::CIGIPP::SymbolClone->new();
  push @message,$sym_clone;

  my $sym_ctl = Rinchi::CIGIPP::SymbolControl->new();
  push @message,$sym_ctl;

  my $ssym_ctl = Rinchi::CIGIPP::ShortSymbolControl->new();
  push @message,$ssym_ctl;

  my $start_of_frame = Rinchi::CIGIPP::StartOfFrame->new();
  push @message,$start_of_frame;

  my $hgt_resp = Rinchi::CIGIPP::HAT_HOTResponse->new();
  push @message,$hgt_resp;

  my $hgt_xresp = Rinchi::CIGIPP::HAT_HOTExtendedResponse->new();
  push @message,$hgt_xresp;

  my $los_resp = Rinchi::CIGIPP::LineOfSightResponse->new();
  push @message,$los_resp;

  my $los_xresp = Rinchi::CIGIPP::LineOfSightExtendedResponse->new();
  push @message,$los_xresp;

  my $sensor_resp = Rinchi::CIGIPP::SensorResponse->new();
  push @message,$sensor_resp;

  my $sensor_xresp = Rinchi::CIGIPP::SensorExtendedResponse->new();
  push @message,$sensor_xresp;

  my $pos_resp = Rinchi::CIGIPP::PositionResponse->new();
  push @message,$pos_resp;

  my $wthr_resp = Rinchi::CIGIPP::WeatherConditionsResponse->new();
  push @message,$wthr_resp;

  my $ac_resp = Rinchi::CIGIPP::AerosolConcentrationResponse->new();
  push @message,$ac_resp;

  my $msc_resp = Rinchi::CIGIPP::MaritimeSurfaceConditionsResponse->new();
  push @message,$msc_resp;

  my $tsc_resp = Rinchi::CIGIPP::TerrestrialSurfaceConditionsResponse->new();
  push @message,$tsc_resp;

  my $cds_ntc = Rinchi::CIGIPP::CollisionDetectionSegmentNotification->new();
  push @message,$cds_ntc;

  my $cdv_ntc = Rinchi::CIGIPP::CollisionDetectionVolumeNotification->new();
  push @message,$cdv_ntc;

  my $stop_ntc = Rinchi::CIGIPP::AnimationStopNotification->new();
  push @message,$stop_ntc;

  my $evt_ntc = Rinchi::CIGIPP::EventNotification->new();
  push @message,$evt_ntc;

  my $ig_msg = Rinchi::CIGIPP::ImageGeneratorMessage->new();
  push @message,$ig_msg;

  my $msg_no = 1;
  $cigi->write_message_to_file(\@message,"message$msg_no.cigi");
  $cigi->dispatch_packets(\@message,1);
  my $messages = $cigi->scan_file("message$msg_no.cigi");
  foreach $message (@{$messages}) {
    $msg_no++;
    $cigi->write_message_to_file($message,"message$msg_no.cigi");
    $cigi->dispatch_packets($message,$msg_no);
  }
  $msg_no++;
  $cigi->write_messages_to_file($messages,"message$msg_no.cigi");

=head1 DESCRIPTION

This module provides an interface between an image generator and host computer 
that is compliant with the CIGI ICD version 3.3. 

=head2 EXPORT

None by default.

=head1 METHODS

=over 4

#==============================================================================

=item new

Constructor for Rinchi::CIGIPP.

=cut

sub new {
  my ($class, %args) = @_;
  my $self = bless \%args, $class;
  $args{'_State_'} = 0;
  $args{'Context'} = [];
  $args{'ErrorMessage'} ||= '';
  $args{'_Setters'} = \%Handler_Setters;
  $args{'_Handlers'} = {};

  return $self;
}

#==============================================================================

=item setHandlers(TYPE, HANDLER [, TYPE, HANDLER [...]])

This method registers handlers for the various events.

Setting a handler to something that evaluates to false unsets that
handler.

This method returns a list of type, handler pairs corresponding to the
input. The handlers returned are the ones that were in effect before the
call to setHandlers.

The recognized events and the parameters passed to the corresponding
handlers are:

=over 4

IGControl                             (PacketType, [, Attr, Val [,...]])

This event is generated when an IGControl data packet is recognized. PacketType 
is the numeric packet type (1) of the IGControl data packet as defined by the 
CIGI ICD. The Attr and Val pairs are generated for each attribute in the data packet.

EntityControl                         (PacketType, [, Attr, Val [,...]])

This event is generated when an EntityControl data packet is recognized. 
PacketType is the numeric packet type (2) of the EntityControl data packet as 
defined by the CIGI ICD. The Attr and Val pairs are generated for each 
attribute in the data packet.

ConformalClampedEntityControl         (PacketType, [, Attr, Val [,...]])

This event is generated when a ConformalClampedEntityControl data packet is 
recognized. PacketType is the numeric packet type (3) of the 
ConformalClampedEntityControl data packet as defined by the CIGI ICD. The Attr 
and Val pairs are generated for each attribute in the data packet.

ComponentControl                      (PacketType, [, Attr, Val [,...]])

This event is generated when a ComponentControl data packet is recognized. 
PacketType is the numeric packet type (4) of the ComponentControl data packet 
as defined by the CIGI ICD. The Attr and Val pairs are generated for each 
attribute in the data packet.

ShortComponentControl                 (PacketType, [, Attr, Val [,...]])

This event is generated when a ShortComponentControl data packet is recognized. 
PacketType is the numeric packet type (5) of the ShortComponentControl data 
packet as defined by the CIGI ICD. The Attr and Val pairs are generated for 
each attribute in the data packet.

ArticulatedPartControl                (PacketType, [, Attr, Val [,...]])

This event is generated when an ArticulatedPartControl data packet is 
recognized. PacketType is the numeric packet type (6) of the 
ArticulatedPartControl data packet as defined by the CIGI ICD. The Attr and Val 
pairs are generated for each attribute in the data packet.

ShortArticulatedPartControl           (PacketType, [, Attr, Val [,...]])

This event is generated when a ShortArticulatedPartControl data packet is 
recognized. PacketType is the numeric packet type (7) of the 
ShortArticulatedPartControl data packet as defined by the CIGI ICD. The Attr 
and Val pairs are generated for each attribute in the data packet.

RateControl                           (PacketType, [, Attr, Val [,...]])

This event is generated when a RateControl data packet is recognized. 
PacketType is the numeric packet type (8) of the RateControl data packet as 
defined by the CIGI ICD. The Attr and Val pairs are generated for each 
attribute in the data packet.

CelestialSphereControl                (PacketType, [, Attr, Val [,...]])

This event is generated when a CelestialSphereControl data packet is 
recognized. PacketType is the numeric packet type (9) of the 
CelestialSphereControl data packet as defined by the CIGI ICD. The Attr and Val 
pairs are generated for each attribute in the data packet.

AtmosphereControl                     (PacketType, [, Attr, Val [,...]])

This event is generated when an AtmosphereControl data packet is recognized. 
PacketType is the numeric packet type (10) of the AtmosphereControl data packet 
as defined by the CIGI ICD. The Attr and Val pairs are generated for each 
attribute in the data packet.

EnvironmentalRegionControl            (PacketType, [, Attr, Val [,...]])

This event is generated when an EnvironmentalRegionControl data packet is 
recognized. PacketType is the numeric packet type (11) of the 
EnvironmentalRegionControl data packet as defined by the CIGI ICD. The Attr and 
Val pairs are generated for each attribute in the data packet.

WeatherControl                        (PacketType, [, Attr, Val [,...]])

This event is generated when a WeatherControl data packet is recognized. 
PacketType is the numeric packet type (12) of the WeatherControl data packet as 
defined by the CIGI ICD. The Attr and Val pairs are generated for each 
attribute in the data packet.

MaritimeSurfaceConditionsControl      (PacketType, [, Attr, Val [,...]])

This event is generated when a MaritimeSurfaceConditionsControl data packet is 
recognized. PacketType is the numeric packet type (13) of the 
MaritimeSurfaceConditionsControl data packet as defined by the CIGI ICD. The 
Attr and Val pairs are generated for each attribute in the data packet.

WaveControl                           (PacketType, [, Attr, Val [,...]])

This event is generated when a WaveControl data packet is recognized. 
PacketType is the numeric packet type (14) of the WaveControl data packet as 
defined by the CIGI ICD. The Attr and Val pairs are generated for each 
attribute in the data packet.

TerrestrialSurfaceConditionsControl   (PacketType, [, Attr, Val [,...]])

This event is generated when a TerrestrialSurfaceConditionsControl data packet 
is recognized. PacketType is the numeric packet type (15) of the 
TerrestrialSurfaceConditionsControl data packet as defined by the CIGI ICD. The 
Attr and Val pairs are generated for each attribute in the data packet.

ViewControl                           (PacketType, [, Attr, Val [,...]])

This event is generated when a ViewControl data packet is recognized. 
PacketType is the numeric packet type (16) of the ViewControl data packet as 
defined by the CIGI ICD. The Attr and Val pairs are generated for each 
attribute in the data packet.

SensorControl                         (PacketType, [, Attr, Val [,...]])

This event is generated when a SensorControl data packet is recognized. 
PacketType is the numeric packet type (17) of the SensorControl data packet as 
defined by the CIGI ICD. The Attr and Val pairs are generated for each 
attribute in the data packet.

MotionTrackerControl                  (PacketType, [, Attr, Val [,...]])

This event is generated when a MotionTrackerControl data packet is recognized. 
PacketType is the numeric packet type (18) of the MotionTrackerControl data 
packet as defined by the CIGI ICD. The Attr and Val pairs are generated for 
each attribute in the data packet.

EarthReferenceModelDefinition         (PacketType, [, Attr, Val [,...]])

This event is generated when an EarthReferenceModelDefinition data packet is 
recognized. PacketType is the numeric packet type (19) of the 
EarthReferenceModelDefinition data packet as defined by the CIGI ICD. The Attr 
and Val pairs are generated for each attribute in the data packet.

TrajectoryDefinition                  (PacketType, [, Attr, Val [,...]])

This event is generated when a TrajectoryDefinition data packet is recognized. 
PacketType is the numeric packet type (20) of the TrajectoryDefinition data 
packet as defined by the CIGI ICD. The Attr and Val pairs are generated for 
each attribute in the data packet.

ViewDefinition                        (PacketType, [, Attr, Val [,...]])

This event is generated when a ViewDefinition data packet is recognized. 
PacketType is the numeric packet type (21) of the ViewDefinition data packet as 
defined by the CIGI ICD. The Attr and Val pairs are generated for each 
attribute in the data packet.

CollisionDetectionSegmentDefinition   (PacketType, [, Attr, Val [,...]])

This event is generated when a CollisionDetectionSegmentDefinition data packet 
is recognized. PacketType is the numeric packet type (22) of the 
CollisionDetectionSegmentDefinition data packet as defined by the CIGI ICD. The 
Attr and Val pairs are generated for each attribute in the data packet.

CollisionDetectionVolumeDefinition    (PacketType, [, Attr, Val [,...]])

This event is generated when a CollisionDetectionVolumeDefinition data packet 
is recognized. PacketType is the numeric packet type (23) of the 
CollisionDetectionVolumeDefinition data packet as defined by the CIGI ICD. The 
Attr and Val pairs are generated for each attribute in the data packet.

HAT_HOTRequest                        (PacketType, [, Attr, Val [,...]])

This event is generated when a HAT_HOTRequest data packet is recognized. 
PacketType is the numeric packet type (24) of the HAT_HOTRequest data packet as 
defined by the CIGI ICD. The Attr and Val pairs are generated for each 
attribute in the data packet.

LineOfSightSegmentRequest             (PacketType, [, Attr, Val [,...]])

This event is generated when a LineOfSightSegmentRequest data packet is 
recognized. PacketType is the numeric packet type (25) of the 
LineOfSightSegmentRequest data packet as defined by the CIGI ICD. The Attr and 
Val pairs are generated for each attribute in the data packet.

LineOfSightVectorRequest              (PacketType, [, Attr, Val [,...]])

This event is generated when a LineOfSightVectorRequest data packet is 
recognized. PacketType is the numeric packet type (26) of the 
LineOfSightVectorRequest data packet as defined by the CIGI ICD. The Attr and 
Val pairs are generated for each attribute in the data packet.

PositionRequest                       (PacketType, [, Attr, Val [,...]])

This event is generated when a PositionRequest data packet is recognized. 
PacketType is the numeric packet type (27) of the PositionRequest data packet 
as defined by the CIGI ICD. The Attr and Val pairs are generated for each 
attribute in the data packet.

EnvironmentalConditionsRequest        (PacketType, [, Attr, Val [,...]])

This event is generated when an EnvironmentalConditionsRequest data packet is 
recognized. PacketType is the numeric packet type (28) of the 
EnvironmentalConditionsRequest data packet as defined by the CIGI ICD. The Attr 
and Val pairs are generated for each attribute in the data packet.

SymbolSurfaceDefinition               (PacketType, [, Attr, Val [,...]])

This event is generated when a SymbolSurfaceDefinition data packet is 
recognized. PacketType is the numeric packet type (29) of the 
SymbolSurfaceDefinition data packet as defined by the CIGI ICD. The Attr and 
Val pairs are generated for each attribute in the data packet.

SymbolTextDefinition                  (PacketType, [, Attr, Val [,...]])

This event is generated when a SymbolTextDefinition data packet is recognized. 
PacketType is the numeric packet type (30) of the SymbolTextDefinition data 
packet as defined by the CIGI ICD. The Attr and Val pairs are generated for 
each attribute in the data packet.

SymbolCircleDefinition                (PacketType, Circles, [, Attr, Val [,...]])

This event is generated when a SymbolCircleDefinition data packet is 
recognized. PacketType is the numeric packet type (31) of the 
SymbolCircleDefinition data packet as defined by the CIGI ICD. The Attr and Val 
pairs are generated for each attribute in the data packet.

SymbolCircle                          (Index, [, Attr, Val [,...]])

This event is generated for each circle when a SymbolCircleDefinition data 
packet is recognized. Index is the 0-based position of the circle in the
SymbolCircleDefinition data packet as defined by the CIGI ICD. The Attr and Val 
pairs are generated for each attribute in the circle.

SymbolLineDefinition                  (PacketType, Vertices, [, Attr, Val [,...]])

This event is generated when a SymbolLineDefinition data packet is recognized. 
PacketType is the numeric packet type (32) of the SymbolLineDefinition data 
packet as defined by the CIGI ICD. The Attr and Val pairs are generated for 
each attribute in the data packet.

SymbolLineVertex                      (Index, [, Attr, Val [,...]])

This event is generated for each vertex when a SymbolLineDefinition data packet 
is recognized. Index is the 0-based position of the vertex in the 
SymbolLineDefinition data packet as defined by the CIGI ICD. The Attr and Val 
pairs are generated for each attribute in the vertex.

SymbolClone                           (PacketType, [, Attr, Val [,...]])

This event is generated when a SymbolClone data packet is recognized. 
PacketType is the numeric packet type (33) of the SymbolClone data packet as 
defined by the CIGI ICD. The Attr and Val pairs are generated for each 
attribute in the data packet.

SymbolControl                         (PacketType, [, Attr, Val [,...]])

This event is generated when a SymbolControl data packet is recognized. 
PacketType is the numeric packet type (34) of the SymbolControl data packet as 
defined by the CIGI ICD. The Attr and Val pairs are generated for each 
attribute in the data packet.

ShortSymbolControl                    (PacketType, [, Attr, Val [,...]])

This event is generated when a ShortSymbolControl data packet is recognized. 
PacketType is the numeric packet type (35) of the ShortSymbolControl data 
packet as defined by the CIGI ICD. The Attr and Val pairs are generated for 
each attribute in the data packet.

StartOfFrame                          (PacketType, [, Attr, Val [,...]])

This event is generated when a StartOfFrame data packet is recognized. 
PacketType is the numeric packet type (101) of the StartOfFrame data packet as 
defined by the CIGI ICD. The Attr and Val pairs are generated for each 
attribute in the data packet.

HAT_HOTResponse                       (PacketType, [, Attr, Val [,...]])

This event is generated when a HAT_HOTResponse data packet is recognized. 
PacketType is the numeric packet type (102) of the HAT_HOTResponse data packet 
as defined by the CIGI ICD. The Attr and Val pairs are generated for each 
attribute in the data packet.

HAT_HOTExtendedResponse               (PacketType, [, Attr, Val [,...]])

This event is generated when a HAT_HOTExtendedResponse data packet is 
recognized. PacketType is the numeric packet type (103) of the 
HAT_HOTExtendedResponse data packet as defined by the CIGI ICD. The Attr and 
Val pairs are generated for each attribute in the data packet.

LineOfSightResponse                   (PacketType, [, Attr, Val [,...]])

This event is generated when a LineOfSightResponse data packet is recognized. 
PacketType is the numeric packet type (104) of the LineOfSightResponse data 
packet as defined by the CIGI ICD. The Attr and Val pairs are generated for 
each attribute in the data packet.

LineOfSightExtendedResponse           (PacketType, [, Attr, Val [,...]])

This event is generated when a LineOfSightExtendedResponse data packet is 
recognized. PacketType is the numeric packet type (105) of the 
LineOfSightExtendedResponse data packet as defined by the CIGI ICD. The Attr 
and Val pairs are generated for each attribute in the data packet.

SensorResponse                        (PacketType, [, Attr, Val [,...]])

This event is generated when a SensorResponse data packet is recognized. 
PacketType is the numeric packet type (106) of the SensorResponse data packet 
as defined by the CIGI ICD. The Attr and Val pairs are generated for each 
attribute in the data packet.

SensorExtendedResponse                (PacketType, [, Attr, Val [,...]])

This event is generated when a SensorExtendedResponse data packet is 
recognized. PacketType is the numeric packet type (107) of the 
SensorExtendedResponse data packet as defined by the CIGI ICD. The Attr and Val 
pairs are generated for each attribute in the data packet.

PositionResponse                      (PacketType, [, Attr, Val [,...]])

This event is generated when a PositionResponse data packet is recognized. 
PacketType is the numeric packet type (108) of the PositionResponse data packet 
as defined by the CIGI ICD. The Attr and Val pairs are generated for each 
attribute in the data packet.

WeatherConditionsResponse             (PacketType, [, Attr, Val [,...]])

This event is generated when a WeatherConditionsResponse data packet is 
recognized. PacketType is the numeric packet type (109) of the 
WeatherConditionsResponse data packet as defined by the CIGI ICD. The Attr and 
Val pairs are generated for each attribute in the data packet.

AerosolConcentrationResponse          (PacketType, [, Attr, Val [,...]])

This event is generated when an AerosolConcentrationResponse data packet is 
recognized. PacketType is the numeric packet type (110) of the 
AerosolConcentrationResponse data packet as defined by the CIGI ICD. The Attr 
and Val pairs are generated for each attribute in the data packet.

MaritimeSurfaceConditionsResponse     (PacketType, [, Attr, Val [,...]])

This event is generated when a MaritimeSurfaceConditionsResponse data packet is 
recognized. PacketType is the numeric packet type (111) of the 
MaritimeSurfaceConditionsResponse data packet as defined by the CIGI ICD. The 
Attr and Val pairs are generated for each attribute in the data packet.

TerrestrialSurfaceConditionsResponse  (PacketType, [, Attr, Val [,...]])

This event is generated when a TerrestrialSurfaceConditionsResponse data packet 
is recognized. PacketType is the numeric packet type (112) of the 
TerrestrialSurfaceConditionsResponse data packet as defined by the CIGI ICD. 
The Attr and Val pairs are generated for each attribute in the data packet.

CollisionDetectionSegmentNotification (PacketType, [, Attr, Val [,...]])

This event is generated when a CollisionDetectionSegmentNotification data 
packet is recognized. PacketType is the numeric packet type (113) of the 
CollisionDetectionSegmentNotification data packet as defined by the CIGI ICD. 
The Attr and Val pairs are generated for each attribute in the data packet.

CollisionDetectionVolumeNotification  (PacketType, [, Attr, Val [,...]])

This event is generated when a CollisionDetectionVolumeNotification data packet 
is recognized. PacketType is the numeric packet type (114) of the 
CollisionDetectionVolumeNotification data packet as defined by the CIGI ICD. 
The Attr and Val pairs are generated for each attribute in the data packet.

AnimationStopNotification             (PacketType, [, Attr, Val [,...]])

This event is generated when an AnimationStopNotification data packet is 
recognized. PacketType is the numeric packet type (115) of the 
AnimationStopNotification data packet as defined by the CIGI ICD. The Attr and 
Val pairs are generated for each attribute in the data packet.

EventNotification                     (PacketType, [, Attr, Val [,...]])

This event is generated when an EventNotification data packet is recognized. 
PacketType is the numeric packet type (116) of the EventNotification data 
packet as defined by the CIGI ICD. The Attr and Val pairs are generated for 
each attribute in the data packet.

ImageGeneratorMessage                 (PacketType, [, Attr, Val [,...]])

This event is generated when an ImageGeneratorMessage data packet is 
recognized. PacketType is the numeric packet type (117) of the 
ImageGeneratorMessage data packet as defined by the CIGI ICD. The Attr and Val 
pairs are generated for each attribute in the data packet.

=back

=cut

sub setHandlers {
  my ($self, @handler_pairs) = @_;

  croak("Uneven number of arguments to setHandlers method")
    if (int(@handler_pairs) & 1);

  my @ret;

  while (@handler_pairs) {
    my $type = shift @handler_pairs;
    my $handler = shift @handler_pairs;
   croak "Handler for $type not a Code ref"
     unless (! defined($handler) or ! $handler or ref($handler) eq 'CODE');

    my $hndl = $self->{'_Setters'}->{$type};

    unless (defined($hndl)) {
      my @types = sort keys %{$self->{'_Setters'}};
      croak("Unknown handler type: $type\n Valid types: @types");
    }

    $self->{'_Handlers'}->{$type} = $handler;
  }

}

#==============================================================================

=item sub dispatch_packets($packets)

  $cigi->dispatch_packets($packets);

Where $packets is a reference to an array of packets to be dispatched.

=cut

sub dispatch_packets($$) {
  my ($self, $packets, $msg_no) = @_;
  my @args = ($msg_no);

  $self->{'_Handlers'}{'StartOfMessage'}(@args);
  foreach my $packet (@{$packets}) {
    my @pcl = split('::',ref($packet));
    my $pclass = pop @pcl;
    @args = ($pclass);
    if ($pclass eq 'SymbolCircleDefinition') {
      my $circles = [];
      push @args,$circles;
      foreach my $circle (@{$packet->{'_circle'}}) {
        my $circ = ['SymbolCircle'];
        push @{$circles},$circ;
        foreach my $key (sort keys %{$circle}) {
          if (($key =~ /^[a-z]/) and ! ($key =~ /^_unused/)) {
            push @{$circ},$key;
            push @{$circ},$circle->{$key};
          }
        }
        $self->{'_Handlers'}{'SymbolCircle'}(@{$circ});
      }
    }
    elsif ($pclass eq 'SymbolLineDefinition') {
      my $vertices = [];
      push @args,$vertices;
      foreach my $vertex (@{$packet->{'_vertex'}}) {
        my $vert = ['SymbolLineVertex'];
        push @{$vertices},$vert;
        foreach my $key (sort keys %{$vertex}) {
          if (($key =~ /^[a-z]/) and ! ($key =~ /^_unused/)) {
            push @{$vert},$key;
            push @{$vert},$vertex->{$key};
          }
        }
        $self->{'_Handlers'}{'SymbolLineVertex'}(@{$vert});
      }
    }
    foreach my $key (sort keys %{$packet}) {
      if (($key =~ /^[a-z]/) and ! ($key =~ /^_unused/)) {
        push @args,$key;
        push @args,$packet->{$key};
      }
    }
    $self->{'_Handlers'}{$pclass}(@args);
#    print "$pclass\n";
  }
  @args = ($msg_no);

  $self->{'_Handlers'}{'EndOfMessage'}(@args);
}

#==============================================================================

=item sub scan_file($path)

  $cigi->scan_file('some_file');

Where $path is the path to the file to be scanned.

Scan the given file for data packets. Returns a reference to an array of 
CIGI messages in the order of occurrence in the file scanned. Each message is
represented by an array of references to the data packets in order of occurrence.  

=cut

sub scan_file($) {
  my ($self, $path) = @_;

  my $hdr;
  my $bdy;
  my $success=1;
  my $packets;
  my $messages = [];
  my $byteswap = 0;
  
  open (CIGI,'<',$path) or $success = 0;
  return 0 unless ($success);
  binmode CIGI;
  while (read (CIGI, $hdr, 2)) {
    my ($tp,$sz) = CORE::unpack('CC',$hdr);
    read (CIGI, $bdy, $sz-2);
    my $packet;
    if ($tp == 1) {
      $packet = Rinchi::CIGIPP::IGControl->new();
    }
    elsif ($tp == 2) {
      $packet = Rinchi::CIGIPP::EntityControl->new();
    }
    elsif ($tp == 3) {
      $packet = Rinchi::CIGIPP::ConformalClampedEntityControl->new();
    }
    elsif ($tp == 4) {
      $packet = Rinchi::CIGIPP::ComponentControl->new();
    }
    elsif ($tp == 5) {
      $packet = Rinchi::CIGIPP::ShortComponentControl->new();
    }
    elsif ($tp == 6) {
      $packet = Rinchi::CIGIPP::ArticulatedPartControl->new();
    }
    elsif ($tp == 7) {
      $packet = Rinchi::CIGIPP::ShortArticulatedPartControl->new();
    }
    elsif ($tp == 8) {
      $packet = Rinchi::CIGIPP::RateControl->new();
    }
    elsif ($tp == 9) {
      $packet = Rinchi::CIGIPP::CelestialSphereControl->new();
    }
    elsif ($tp == 10) {
      $packet = Rinchi::CIGIPP::AtmosphereControl->new();
    }
    elsif ($tp == 11) {
      $packet = Rinchi::CIGIPP::EnvironmentalRegionControl->new();
    }
    elsif ($tp == 12) {
      $packet = Rinchi::CIGIPP::WeatherControl->new();
    }
    elsif ($tp == 13) {
      $packet = Rinchi::CIGIPP::MaritimeSurfaceConditionsControl->new();
    }
    elsif ($tp == 14) {
      $packet = Rinchi::CIGIPP::WaveControl->new();
    }
    elsif ($tp == 15) {
      $packet = Rinchi::CIGIPP::TerrestrialSurfaceConditionsControl->new();
    }
    elsif ($tp == 16) {
      $packet = Rinchi::CIGIPP::ViewControl->new();
    }
    elsif ($tp == 17) {
      $packet = Rinchi::CIGIPP::SensorControl->new();
    }
    elsif ($tp == 18) {
      $packet = Rinchi::CIGIPP::MotionTrackerControl->new();
    }
    elsif ($tp == 19) {
      $packet = Rinchi::CIGIPP::EarthReferenceModelDefinition->new();
    }
    elsif ($tp == 20) {
      $packet = Rinchi::CIGIPP::TrajectoryDefinition->new();
    }
    elsif ($tp == 21) {
      $packet = Rinchi::CIGIPP::ViewDefinition->new();
    }
    elsif ($tp == 22) {
      $packet = Rinchi::CIGIPP::CollisionDetectionSegmentDefinition->new();
    }
    elsif ($tp == 23) {
      $packet = Rinchi::CIGIPP::CollisionDetectionVolumeDefinition->new();
    }
    elsif ($tp == 24) {
      $packet = Rinchi::CIGIPP::HAT_HOTRequest->new();
    }
    elsif ($tp == 25) {
      $packet = Rinchi::CIGIPP::LineOfSightSegmentRequest->new();
    }
    elsif ($tp == 26) {
      $packet = Rinchi::CIGIPP::LineOfSightVectorRequest->new();
    }
    elsif ($tp == 27) {
      $packet = Rinchi::CIGIPP::PositionRequest->new();
    }
    elsif ($tp == 28) {
      $packet = Rinchi::CIGIPP::EnvironmentalConditionsRequest->new();
    }
    elsif ($tp == 29) {
      $packet = Rinchi::CIGIPP::SymbolSurfaceDefinition->new();
    }
    elsif ($tp == 30) {
      $packet = Rinchi::CIGIPP::SymbolTextDefinition->new();
    }
    elsif ($tp == 31) {
      $packet = Rinchi::CIGIPP::SymbolCircleDefinition->new();
    }
    elsif ($tp == 32) {
      $packet = Rinchi::CIGIPP::SymbolLineDefinition->new();
    }
    elsif ($tp == 33) {
      $packet = Rinchi::CIGIPP::SymbolClone->new();
    }
    elsif ($tp == 34) {
      $packet = Rinchi::CIGIPP::SymbolControl->new();
    }
    elsif ($tp == 35) {
      $packet = Rinchi::CIGIPP::ShortSymbolControl->new();
    }
    elsif ($tp == 101) {
      $packet = Rinchi::CIGIPP::StartOfFrame->new();
    }
    elsif ($tp == 102) {
      $packet = Rinchi::CIGIPP::HAT_HOTResponse->new();
    }
    elsif ($tp == 103) {
      $packet = Rinchi::CIGIPP::HAT_HOTExtendedResponse->new();
    }
    elsif ($tp == 104) {
      $packet = Rinchi::CIGIPP::LineOfSightResponse->new();
    }
    elsif ($tp == 105) {
      $packet = Rinchi::CIGIPP::LineOfSightExtendedResponse->new();
    }
    elsif ($tp == 106) {
      $packet = Rinchi::CIGIPP::SensorResponse->new();
    }
    elsif ($tp == 107) {
      $packet = Rinchi::CIGIPP::SensorExtendedResponse->new();
    }
    elsif ($tp == 108) {
      $packet = Rinchi::CIGIPP::PositionResponse->new();
    }
    elsif ($tp == 109) {
      $packet = Rinchi::CIGIPP::WeatherConditionsResponse->new();
    }
    elsif ($tp == 110) {
      $packet = Rinchi::CIGIPP::AerosolConcentrationResponse->new();
    }
    elsif ($tp == 111) {
      $packet = Rinchi::CIGIPP::MaritimeSurfaceConditionsResponse->new();
    }
    elsif ($tp == 112) {
      $packet = Rinchi::CIGIPP::TerrestrialSurfaceConditionsResponse->new();
    }
    elsif ($tp == 113) {
      $packet = Rinchi::CIGIPP::CollisionDetectionSegmentNotification->new();
    }
    elsif ($tp == 114) {
      $packet = Rinchi::CIGIPP::CollisionDetectionVolumeNotification->new();
    }
    elsif ($tp == 115) {
      $packet = Rinchi::CIGIPP::AnimationStopNotification->new();
    }
    elsif ($tp == 116) {
      $packet = Rinchi::CIGIPP::EventNotification->new();
    }
    elsif ($tp == 117) {
      $packet = Rinchi::CIGIPP::ImageGeneratorMessage->new();
    }
    if (defined($packet)) {
      $packet->unpack($hdr . $bdy);
      if ($tp == 1 or $tp == 101) {
        $byteswap = ($packet->magic_number == 0x80);
        $packets = [];
        push @{$messages},$packets;
      }
      $packet->byte_swap if($byteswap);
      push @{$packets},$packet;
    } else {
      print "$tp, $sz\n";
    }
  }
  close CIGI;
  return $messages;
}

#==============================================================================

=item sub wait_for_message($port)

  \@message = $cigi->wait_for_message(4321);

Where $port is the port to which to listen for messages.

Listen to the given port and scan the UDP messages that arrive. Returns a 
reference to an array of data packets in the order of occurrence in the
message received. 

=cut

sub wait_for_message($) {
  my ($self, $port) = @_;

  my $hdr;
  my $pkt;
  my $success=1;
  my @message;
  my $byteswap = 0;
  
  my $recv_socket = IO::Socket::INET->new(
    'Proto' =>  'udp',
    'LocalPort' => $port,
  );

  my $text;
  $recv_socket->recv($text, 1472);

  while (length($text) >= 8 ) {
    $hdr = substr($text,0,2);
    my ($tp,$sz) = CORE::unpack('CC',$hdr);
    $pkt = substr($text,0,$sz);
    my $packet;
    if ($tp == 1) {
      $packet = Rinchi::CIGIPP::IGControl->new();
    }
    elsif ($tp == 2) {
      $packet = Rinchi::CIGIPP::EntityControl->new();
    }
    elsif ($tp == 3) {
      $packet = Rinchi::CIGIPP::ConformalClampedEntityControl->new();
    }
    elsif ($tp == 4) {
      $packet = Rinchi::CIGIPP::ComponentControl->new();
    }
    elsif ($tp == 5) {
      $packet = Rinchi::CIGIPP::ShortComponentControl->new();
    }
    elsif ($tp == 6) {
      $packet = Rinchi::CIGIPP::ArticulatedPartControl->new();
    }
    elsif ($tp == 7) {
      $packet = Rinchi::CIGIPP::ShortArticulatedPartControl->new();
    }
    elsif ($tp == 8) {
      $packet = Rinchi::CIGIPP::RateControl->new();
    }
    elsif ($tp == 9) {
      $packet = Rinchi::CIGIPP::CelestialSphereControl->new();
    }
    elsif ($tp == 10) {
      $packet = Rinchi::CIGIPP::AtmosphereControl->new();
    }
    elsif ($tp == 11) {
      $packet = Rinchi::CIGIPP::EnvironmentalRegionControl->new();
    }
    elsif ($tp == 12) {
      $packet = Rinchi::CIGIPP::WeatherControl->new();
    }
    elsif ($tp == 13) {
      $packet = Rinchi::CIGIPP::MaritimeSurfaceConditionsControl->new();
    }
    elsif ($tp == 14) {
      $packet = Rinchi::CIGIPP::WaveControl->new();
    }
    elsif ($tp == 15) {
      $packet = Rinchi::CIGIPP::TerrestrialSurfaceConditionsControl->new();
    }
    elsif ($tp == 16) {
      $packet = Rinchi::CIGIPP::ViewControl->new();
    }
    elsif ($tp == 17) {
      $packet = Rinchi::CIGIPP::SensorControl->new();
    }
    elsif ($tp == 18) {
      $packet = Rinchi::CIGIPP::MotionTrackerControl->new();
    }
    elsif ($tp == 19) {
      $packet = Rinchi::CIGIPP::EarthReferenceModelDefinition->new();
    }
    elsif ($tp == 20) {
      $packet = Rinchi::CIGIPP::TrajectoryDefinition->new();
    }
    elsif ($tp == 21) {
      $packet = Rinchi::CIGIPP::ViewDefinition->new();
    }
    elsif ($tp == 22) {
      $packet = Rinchi::CIGIPP::CollisionDetectionSegmentDefinition->new();
    }
    elsif ($tp == 23) {
      $packet = Rinchi::CIGIPP::CollisionDetectionVolumeDefinition->new();
    }
    elsif ($tp == 24) {
      $packet = Rinchi::CIGIPP::HAT_HOTRequest->new();
    }
    elsif ($tp == 25) {
      $packet = Rinchi::CIGIPP::LineOfSightSegmentRequest->new();
    }
    elsif ($tp == 26) {
      $packet = Rinchi::CIGIPP::LineOfSightVectorRequest->new();
    }
    elsif ($tp == 27) {
      $packet = Rinchi::CIGIPP::PositionRequest->new();
    }
    elsif ($tp == 28) {
      $packet = Rinchi::CIGIPP::EnvironmentalConditionsRequest->new();
    }
    elsif ($tp == 29) {
      $packet = Rinchi::CIGIPP::SymbolSurfaceDefinition->new();
    }
    elsif ($tp == 30) {
      $packet = Rinchi::CIGIPP::SymbolTextDefinition->new();
    }
    elsif ($tp == 31) {
      $packet = Rinchi::CIGIPP::SymbolCircleDefinition->new();
    }
    elsif ($tp == 32) {
      $packet = Rinchi::CIGIPP::SymbolLineDefinition->new();
    }
    elsif ($tp == 33) {
      $packet = Rinchi::CIGIPP::SymbolClone->new();
    }
    elsif ($tp == 34) {
      $packet = Rinchi::CIGIPP::SymbolControl->new();
    }
    elsif ($tp == 35) {
      $packet = Rinchi::CIGIPP::ShortSymbolControl->new();
    }
    elsif ($tp == 101) {
      $packet = Rinchi::CIGIPP::StartOfFrame->new();
    }
    elsif ($tp == 102) {
      $packet = Rinchi::CIGIPP::HAT_HOTResponse->new();
    }
    elsif ($tp == 103) {
      $packet = Rinchi::CIGIPP::HAT_HOTExtendedResponse->new();
    }
    elsif ($tp == 104) {
      $packet = Rinchi::CIGIPP::LineOfSightResponse->new();
    }
    elsif ($tp == 105) {
      $packet = Rinchi::CIGIPP::LineOfSightExtendedResponse->new();
    }
    elsif ($tp == 106) {
      $packet = Rinchi::CIGIPP::SensorResponse->new();
    }
    elsif ($tp == 107) {
      $packet = Rinchi::CIGIPP::SensorExtendedResponse->new();
    }
    elsif ($tp == 108) {
      $packet = Rinchi::CIGIPP::PositionResponse->new();
    }
    elsif ($tp == 109) {
      $packet = Rinchi::CIGIPP::WeatherConditionsResponse->new();
    }
    elsif ($tp == 110) {
      $packet = Rinchi::CIGIPP::AerosolConcentrationResponse->new();
    }
    elsif ($tp == 111) {
      $packet = Rinchi::CIGIPP::MaritimeSurfaceConditionsResponse->new();
    }
    elsif ($tp == 112) {
      $packet = Rinchi::CIGIPP::TerrestrialSurfaceConditionsResponse->new();
    }
    elsif ($tp == 113) {
      $packet = Rinchi::CIGIPP::CollisionDetectionSegmentNotification->new();
    }
    elsif ($tp == 114) {
      $packet = Rinchi::CIGIPP::CollisionDetectionVolumeNotification->new();
    }
    elsif ($tp == 115) {
      $packet = Rinchi::CIGIPP::AnimationStopNotification->new();
    }
    elsif ($tp == 116) {
      $packet = Rinchi::CIGIPP::EventNotification->new();
    }
    elsif ($tp == 117) {
      $packet = Rinchi::CIGIPP::ImageGeneratorMessage->new();
    }
    if (defined($packet)) {
      $packet->unpack($pkt);
      $byteswap = ($packet->magic_number == 0x80) if ($tp == 1 or $tp == 101);
      $packet->byte_swap if($byteswap);
      push @message,$packet;
    } else {
      print "Unrecognized data packet: Type $tp, Size $sz\n";
    }
    $text = substr($text,$sz);
  }
  return \@message;
}

#==============================================================================

=item sub write_message_to_file(\@message,$path)

  $cigi->write_message_to_file(\@message,'some_path');

Where $packets is a reference to an array of CIGI data packets and $path is a path 
to the file to be written.

=cut

sub write_message_to_file() {
  my ($self, $msg, $path) = @_;

  if(ref($msg) eq 'ARRAY') {
    foreach my $pkt (@{$msg}) {
      my $obj_cls = ref($pkt);
      unless ($obj_cls =~ /Rinchi::CIGIPP::/) {
        carp "I don't know what to do with an object of class $obj_cls";
        return 0;
      }
    }
  } else {
    carp 'First argument must be an array reference';
    return 0;
  }
  my $success=1;
  open (CIGI,'>',$path) or $success = 0;
  return 0 unless ($success);
  binmode CIGI;

  foreach my $pkt (@{$msg}) {
    print CIGI $pkt->pack();
  }
  close CIGI;
  
  return 1;
}

#==============================================================================

=item sub write_messages_to_file(\@messages,$path)

  $cigi->write_messages_to_file(\@messages,'some_path');

Where $messages is a reference to an array of CIGI messages and $path is a path 
to the file to be written.

=cut

sub write_messages_to_file() {
  my ($self, $messages, $path) = @_;

  if(ref($messages) eq 'ARRAY') {
    foreach my $msg (@{$messages}) {
      if(ref($msg) eq 'ARRAY') {
        foreach my $pkt (@{$msg}) {
          my $obj_cls = ref($pkt);
          unless ($obj_cls =~ /Rinchi::CIGIPP::/) {
            carp "I don't know what to do with an object of class $obj_cls";
            return 0;
          }
        }
      } else {
        carp 'Each message must be an array reference';
        return 0;
      }
    }
  } else {
    carp 'First argument must be an array reference';
    return 0;
  }
  my $success=1;
  open (CIGI,'>',$path) or $success = 0;
  return 0 unless ($success);
  binmode CIGI;

  foreach my $msg (@{$messages}) {
    foreach my $pkt (@{$msg}) {
      print CIGI $pkt->pack();
    }
  }
  close CIGI;
  
  return 1;
}

#==============================================================================

=item sub send_message(\@message, $ip_addr, $port)

  $cigi->send_message(\@message,'172.0.0.1',4321);

Where \@message is a reference to an array containing the data packets to send, 
and $ip_addr and $port identify the destination.

=cut

sub send_message() {
  my ($self, $msg, $ip_addr, $port) = @_;

  if(ref($msg) eq 'ARRAY') {
    foreach my $pkt (@{$msg}) {
      my $obj_cls = ref($pkt);
      unless ($obj_cls =~ /Rinchi::CIGIPP::/) {
        carp "I don't know what to do with an object of class $obj_cls";
        return 0;
      }
    }
  } else {
    carp 'First argument must be an array reference';
    return 0;
  }
  my $buffer='';
  foreach my $pkt (@{$msg}) {
    $buffer .= $pkt->pack();
  }
  my $socket = IO::Socket::INET->new(
    'Proto' =>  'udp',
    'PeerPort' => $port,
    'PeerAddr' => $ip_addr
  );

  $socket->send($buffer);
}

#==============================================================================

=item sub byte_swap(\@message)

  $cigi->byte_swap(\@message);

Where \@message is a reference to an array containing the data packets to swap. 

=cut

sub byte_swap() {
  my ($self, $msg, $ip_addr, $port) = @_;

  if(ref($msg) eq 'ARRAY') {
    foreach my $pkt (@{$msg}) {
      my $obj_cls = ref($pkt);
      unless ($obj_cls =~ /Rinchi::CIGIPP::/) {
        carp "I don't know what to do with an object of class $obj_cls";
        return 0;
      }
    }
  } else {
    carp 'First argument must be an array reference';
    return 0;
  }
  my $buffer='';
  foreach my $pkt (@{$msg}) {
    $pkt->byte_swap();
  }
}

#==============================================================================

=head1 ENUMERATIONS

The following literals may be used in place of numeric values as defined by the 
CIGI ICD. Slight modifications have be made to create global uniqueness.

=item AnimationDirection

  Forward                                    0,
  Backward                                   1,

=item AnimationLoopMode

  OneShot                                    0,
  Continuous                                 1,

=item AnimationState

  Stop                                       0,
  Pause                                      1,
  Play                                       2,
  Continue                                   3,

=item AttachState

  Detach                                     0,
  Attach                                     1,

=item AttachType

  EntityAT                                   0,
  ViewAT                                     1,

=item Billboard

  NonBillboard                               0,
  Billboard                                  1,

=item Boolean

  False                                      0,
  True                                       1,

=item BreakerType

  Plunging                                   0,
  Spilling                                   1,
  Surging                                    2,

=item CloudType

  None                                       0,
  Altocumulus                                1,
  Altostratus                                2,
  Cirrocumulus                               3,
  Cirrostratus                               4,
  Cirrus                                     5,
  Cumulonimbus                               6,
  Cumulus                                    7,
  Nimbostratus                               8,
  Stratocumulus                              9,
  Stratus                                    10,
  Other1                                     11,
  Other2                                     12,
  Other3                                     13,
  Other4                                     14,
  Other5                                     15,

=item CollisionType

  CollisionNonEntity                         0,
  CollisionEntity                            1,

=item ComponentClass

  EntityCC                                   0,
  ViewCC                                     1,
  ViewGroupCC                                2,
  SensorCC                                   3,
  RegionalSeaSurfaceCC                       4,
  RegionalTerrainSurfaceCC                   5,
  RegionalLayeredWeatherCC                   6,
  GlobalSeaSurfaceCC                         7,
  GlobalTerrainSurfaceCC                     8,
  GlobalLayeredWeatherCC                     9,
  AtmosphereCC                               10,
  CelestialSphereCC                          11,
  EventCC                                    12,
  SystemCC                                   13,
  SymbolSurfaceCC                            14,
  SymbolCC                                   15,

=item DOFSelect

  NotUsed                                    0,
  XOffset                                    1,
  YOffset                                    2,
  ZOffset                                    3,
  Yaw                                        4,
  Pitch                                      5,
  Roll                                       6,

=item DrawingStyle

  DrawingStyleLine                           0,
  DrawingStyleFill                           1,

=item EarthReferenceModel

  WGS84                                      0,
  HostDefined                                1,

=item Enable

  Disable                                    0,
  Enable                                     1,

=item Enabled

  Disabled                                   0,
  Enabled                                    1,

=item EntityState

  EntityInactive                             0,
  EntityStandby                              1,
  EntityActive                               1,
  EntityDestroyed                            2,

=item EnvironmentalConditionsResponseType

  MaritimeSurfaceConditions                  1,
  TerrestrialSurfaceConditions               2,
  WeatherConditions                          4,
  AerosolConcentrations                      8,

=item FlashControl

  ContinueFlash                              0,
  RestartFlash                               1,

=item FontIdent

  IGDefault                                  0,
  ProportionalSansSerif                      1,
  ProportionalSanSerifBold                   2,
  ProportionalSansSerifItalic                3,
  ProportionalSansSerifBoldItalic            4,
  ProportionalSerif                          5,
  ProportionalSerifBold                      6,
  ProportionalSerifItalic                    7,
  ProportionalSerifBoldItalic                8,
  MonospaceSansSerif                         9,
  MonospaceSansSerifBold                     10,
  MonospaceSansSerifItalic                   11,
  MonospaceSansSerifBoldItalic               12,
  MonospaceSerif                             13,
  MonospaceSerifBold                         14,
  MonospaceSerifItalic                       15,
  MonospaceSerifBoldItalic                   16,

=item GroundOceanClamp

  NoClamp                                    0,
  NonConformal                               1,
  Conformal                                  2,

=item HAT_HOT_CS

  GeodeticCS                                 0,
  EntityCS                                   1,

=item HAT_HOT_RST

  HeightAboveTerrain                         0,
  HeightOfTerrain                            1,

=item HAT_HOT_RT

  HeightAboveTerrain                         0,
  HeightOfTerrain                            1,
  Extended                                   2,

=item IGMode

  Reset                                      0,
  Standby                                    1,
  Operate                                    1,
  Debug                                      2,
  OfflineMaintenance                         3,

=item Inherited

  NotInherited                               0,
  Inherited                                  1,

=item LOS_CS

  GeodeticCS                                 0,
  EntityCS                                   1,

=item LOS_RT

  BasicLOS                                   0,
  ExtendedLOS                                1,

=item LOS_Visible

  Occluded                                   0,
  Visible                                    1,

=item LinePrimitiveType

  Point                                      0,
  Line                                       1,
  LineStrip                                  2,
  LineLoop                                   3,
  Triangle                                   4,
  TriangleStrip                              5,
  TriangleFan                                6,

=item MSCScope

  GlobalScope                                0,
  RegionalScope                              1,
  EntityScope                                2,

=item Merge

  UseLast                                    0,
  Merge                                      1,

=item MirrorMode

  None                                       0,
  Horizontal                                 1,
  Vertical                                   2,
  HorizontalAndVertical                      3,

=item ObjectClass

  EntityOC                                   0,
  ArticulatedPartOC                          1,
  ViewOC                                     2,
  ViewGroupOC                                3,
  MotionTrackerOC                            4,

=item PacketType

  IG_CONTROL                                 1,
  ENTITY_CONTROL                             2,
  CONFORMAL_CLAMPED_ENTITY_CONTROL           3,
  COMPONENT_CONTROL                          4,
  SHORT_COMPONENT_CONTROL                    5,
  ARTICULATED_PART_CONTROL                   6,
  SHORT_ARTICULATED_PART_CONTROL             7,
  RATE_CONTROL                               8,
  CELESTIAL_SPHERE_CONTROL                   9,
  ATMOSPHERE_CONTROL                         10,
  ENVIRONMENTAL_REGION_CONTROL               11,
  WEATHER_CONTROL                            12,
  MARITIME_SURFACE_CONDITIONS_CONTROL        13,
  WAVE_CONTROL                               14,
  TERRESTRIAL_SURFACE_CONDITIONS_CONTROL     15,
  VIEW_CONTROL                               16,
  SENSOR_CONTROL                             17,
  MOTION_TRACKER_CONTROL                     18,
  EARTH_REFERENCE_MODEL_DEFINITION           19,
  TRAJECTORY_DEFINITION                      20,
  VIEW_DEFINITION                            21,
  COLLISION_DETECTION_SEGMENT_DEFINITION     22,
  COLLISION_DETECTION_VOLUME_DEFINITION      23,
  HAT_HOT_REQUEST                            24,
  LINE_OF_SIGHT_SEGMENT_REQUEST              25,
  LINE_OF_SIGHT_VECTOR_REQUEST               26,
  POSITION_REQUEST                           27,
  ENVIRONMENTAL_CONDITIONS_REQUEST           28,
  SYMBOL_SURFACE_DEFINITION                  29,
  SYMBOL_TEXT_DEFINITION                     30,
  SYMBOL_CIRCLE_DEFINITION                   31,
  SYMBOL_LINE_DEFINITION                     32,
  SYMBOL_CLONE                               33,
  SYMBOL_CONTROL                             34,
  SHORT_SYMBOL_CONTROL                       35,
  START_OF_FRAME                             101,
  HAT_HOT_RESPONSE                           102,
  HAT_HOT_EXTENDED_RESPONSE                  103,
  LINE_OF_SIGHT_RESPONSE                     104,
  LINE_OF_SIGHT_EXTENDED_RESPONSE            105,
  SENSOR_RESPONSE                            106,
  SENSOR_EXTENDED_RESPONSE                   107,
  POSITION_RESPONSE                          108,
  WEATHER_CONDITIONS_RESPONSE                109,
  AEROSOL_CONCENTRATION_RESPONSE             110,
  MARITIME_SURFACE_CONDITIONS_RESPONSE       111,
  TERRESTRIAL_SURFACE_CONDITIONS_RESPONSE    112,
  COLLISION_DETECTION_SEGMENT_NOTIFICATION   113,
  COLLISION_DETECTION_VOLUME_NOTIFICATION    114,
  ANIMATION_STOP_NOTIFICATION                115,
  EVENT_NOTIFICATION                         116,
  IMAGE_GENERATOR_MESSAGE                    117,

=item PixelRpMode

  None                                       0,
  Replicate1x2                               1,
  Replicate2x1                               2,
  Replicate2x2                               3,

=item Polarity

  WhiteHot                                   0,
  BlackHot                                   1,

=item PositionCS

  GeodeticCS                                 0,
  ParentEntityCS                             1,
  SubmodelCS                                 2,

=item ProjectnTyp

  Perspective                                0,
  OrthographicParallel                       1,

=item RateControlCoordinateSystem

  World_Parent                               0,
  Local                                      1,

=item RegionState

  Inactive                                   0,
  Active                                     1,
  Destroyed                                  2,

=item ResponseTyp

  NormalSRT                                  0,
  ExtendedSRT                                1,

=item SensorOnOff

  Off                                        0,
  On                                         1,

=item SensorStatus

  Searching                                  0,
  Tracking                                   1,
  ImpendingBreaklock                         2,
  Breaklock                                  3,

=item SourceType

  Symbol                                     0,
  SymbolTemplate                             1,

=item SurfaceState

  ActiveSS                                   0,
  DestroyedSS                                1,

=item SymbolAttribute

  None                                       0,
  SurfaceIdent                               1,
  ParentSymbolIdent                          2,
  Layer                                      3,
  FlashDutyCycle                             4,
  FlashPeriod                                5,
  PositionU                                  6,
  PositionV                                  7,
  Rotation                                   8,
  Color                                      9,
  ScaleU                                     10,
  ScaleV                                     11,

=item SymbolState

  Hidden                                     0,
  Visible                                    1,
  Destroyed                                  2,

=item TSCScope

  GlobalScope                                0,
  RegionalScope                              1,
  EntityScope                                2,

=item TextAlignment

  TopLeft                                    0,
  TopCenter                                  1,
  TopRight                                   2,
  CenterLeft                                 3,
  Center                                     4,
  CenterRight                                5,
  BottomLeft                                 6,
  BottomCenter                               7,
  BottomRight                                8,

=item TextDirection

  LeftToRight                                0,
  TopToBottom                                1,
  RightToLeft                                2,
  BottomToTop                                3,

=item TrackMode

  Off                                        0,
  ForceCorrelate                             1,
  Scene                                      2,
  Target                                     3,
  Ship                                       4,
  IGDefined3                                 5,
  IGDefined2                                 6,
  IGDefined1                                 7,

=item TrackWhtBlk

  White                                      0,
  Black                                      1,

=item Valid

  Invalid                                    0,
  Valid                                      1,

=item ValidNot

  NotValid                                   0,
  Valid                                      1,

=item ViewReorder

  NoReorder                                  0,
  BringToTop                                 1,

=item VolumeType

  Sphere                                     0,
  Cuboid                                     1,

=item VwGrpSelect

  View                                       0,
  ViewGroup                                  1,

=item WaveScope

  GlobalScope                                0,
  RegionalScope                              1,
  EntityScope                                2,

=item WeatherLayer

  GroundFog                                  0,
  CloudLayer1                                1,
  CloudLayer2                                2,
  CloudLayer3                                3,
  Rain                                       4,
  Snow                                       5,
  Sleet                                      6,
  Hail                                       7,
  Sand                                       8,
  Dust                                       9,

=item WthrScope

  GlobalScope                                0,
  RegionalScope                              1,
  EntityScope                                2,

=cut

#==============================================================================

BEGIN {
  my %symbols = (
# AnimationDirection
  'Forward'                                  => 0,
  'Backward'                                 => 1,
# AnimationLoopMode
  'OneShot'                                  => 0,
  'Continuous'                               => 1,
# AnimationState
  'Stop'                                     => 0,
  'Pause'                                    => 1,
  'Play'                                     => 2,
  'Continue'                                 => 3,
# AttachState
  'Detach'                                   => 0,
  'Attach'                                   => 1,
# AttachType
  'EntityAT'                                 => 0,
  'ViewAT'                                   => 1,
# Billboard
  'NonBillboard'                             => 0,
  'Billboard'                                => 1,
# Boolean
  'False'                                    => 0,
  'True'                                     => 1,
# BreakerType
  'Plunging'                                 => 0,
  'Spilling'                                 => 1,
  'Surging'                                  => 2,
# CloudType
  'None'                                     => 0,
  'Altocumulus'                              => 1,
  'Altostratus'                              => 2,
  'Cirrocumulus'                             => 3,
  'Cirrostratus'                             => 4,
  'Cirrus'                                   => 5,
  'Cumulonimbus'                             => 6,
  'Cumulus'                                  => 7,
  'Nimbostratus'                             => 8,
  'Stratocumulus'                            => 9,
  'Stratus'                                  => 10,
  'Other1'                                   => 11,
  'Other2'                                   => 12,
  'Other3'                                   => 13,
  'Other4'                                   => 14,
  'Other5'                                   => 15,
# CollisionType
  'CollisionNonEntity'                       => 0,
  'CollisionEntity'                          => 1,
# ComponentClass
  'EntityCC'                                 => 0,
  'ViewCC'                                   => 1,
  'ViewGroupCC'                              => 2,
  'SensorCC'                                 => 3,
  'RegionalSeaSurfaceCC'                     => 4,
  'RegionalTerrainSurfaceCC'                 => 5,
  'RegionalLayeredWeatherCC'                 => 6,
  'GlobalSeaSurfaceCC'                       => 7,
  'GlobalTerrainSurfaceCC'                   => 8,
  'GlobalLayeredWeatherCC'                   => 9,
  'AtmosphereCC'                             => 10,
  'CelestialSphereCC'                        => 11,
  'EventCC'                                  => 12,
  'SystemCC'                                 => 13,
  'SymbolSurfaceCC'                          => 14,
  'SymbolCC'                                 => 15,
# DOFSelect
  'NotUsed'                                  => 0,
  'XOffset'                                  => 1,
  'YOffset'                                  => 2,
  'ZOffset'                                  => 3,
  'Yaw'                                      => 4,
  'Pitch'                                    => 5,
  'Roll'                                     => 6,
# DrawingStyle
  'DrawingStyleLine'                         => 0,
  'DrawingStyleFill'                         => 1,
# EarthReferenceModel
  'WGS84'                                    => 0,
  'HostDefined'                              => 1,
# Enable
  'Disable'                                  => 0,
  'Enable'                                   => 1,
# Enabled
  'Disabled'                                 => 0,
  'Enabled'                                  => 1,
# EntityState
  'EntityInactive'                           => 0,
  'EntityStandby'                            => 1,
  'EntityActive'                             => 1,
  'EntityDestroyed'                          => 2,
# EnvironmentalConditionsResponseType
  'MaritimeSurfaceConditions'                => 1,
  'TerrestrialSurfaceConditions'             => 2,
  'WeatherConditions'                        => 4,
  'AerosolConcentrations'                    => 8,
# FlashControl
  'ContinueFlash'                            => 0,
  'RestartFlash'                             => 1,
# FontIdent
  'IGDefault'                                => 0,
  'ProportionalSansSerif'                    => 1,
  'ProportionalSanSerifBold'                 => 2,
  'ProportionalSansSerifItalic'              => 3,
  'ProportionalSansSerifBoldItalic'          => 4,
  'ProportionalSerif'                        => 5,
  'ProportionalSerifBold'                    => 6,
  'ProportionalSerifItalic'                  => 7,
  'ProportionalSerifBoldItalic'              => 8,
  'MonospaceSansSerif'                       => 9,
  'MonospaceSansSerifBold'                   => 10,
  'MonospaceSansSerifItalic'                 => 11,
  'MonospaceSansSerifBoldItalic'             => 12,
  'MonospaceSerif'                           => 13,
  'MonospaceSerifBold'                       => 14,
  'MonospaceSerifItalic'                     => 15,
  'MonospaceSerifBoldItalic'                 => 16,
# GroundOceanClamp
  'NoClamp'                                  => 0,
  'NonConformal'                             => 1,
  'Conformal'                                => 2,
# HAT_HOT_CS
  'GeodeticCS'                               => 0,
  'EntityCS'                                 => 1,
# HAT_HOT_RST
  'HeightAboveTerrain'                       => 0,
  'HeightOfTerrain'                          => 1,
# HAT_HOT_RT
  'HeightAboveTerrain'                       => 0,
  'HeightOfTerrain'                          => 1,
  'Extended'                                 => 2,
# IGMode
  'Reset'                                    => 0,
  'Standby'                                  => 0,
  'Operate'                                  => 1,
  'Debug'                                    => 2,
  'OfflineMaintenance'                       => 3,
# Inherited
  'NotInherited'                             => 0,
  'Inherited'                                => 1,
# LOS_CS
  'GeodeticCS'                               => 0,
  'EntityCS'                                 => 1,
# LOS_RT
  'BasicLOS'                                 => 0,
  'ExtendedLOS'                              => 1,
# LOS_Visible
  'Occluded'                                 => 0,
  'Visible'                                  => 1,
# LinePrimitiveType
  'Point'                                    => 0,
  'Line'                                     => 1,
  'LineStrip'                                => 2,
  'LineLoop'                                 => 3,
  'Triangle'                                 => 4,
  'TriangleStrip'                            => 5,
  'TriangleFan'                              => 6,
# MSCScope
  'GlobalScope'                              => 0,
  'RegionalScope'                            => 1,
  'EntityScope'                              => 2,
# Merge
  'UseLast'                                  => 0,
  'Merge'                                    => 1,
# MirrorMode
  'None'                                     => 0,
  'Horizontal'                               => 1,
  'Vertical'                                 => 2,
  'HorizontalAndVertical'                    => 3,
# ObjectClass
  'EntityOC'                                 => 0,
  'ArticulatedPartOC'                        => 1,
  'ViewOC'                                   => 2,
  'ViewGroupOC'                              => 3,
  'MotionTrackerOC'                          => 4,
# PacketType
  'IG_CONTROL'                               => 1,
  'ENTITY_CONTROL'                           => 2,
  'CONFORMAL_CLAMPED_ENTITY_CONTROL'         => 3,
  'COMPONENT_CONTROL'                        => 4,
  'SHORT_COMPONENT_CONTROL'                  => 5,
  'ARTICULATED_PART_CONTROL'                 => 6,
  'SHORT_ARTICULATED_PART_CONTROL'           => 7,
  'RATE_CONTROL'                             => 8,
  'CELESTIAL_SPHERE_CONTROL'                 => 9,
  'ATMOSPHERE_CONTROL'                       => 10,
  'ENVIRONMENTAL_REGION_CONTROL'             => 11,
  'WEATHER_CONTROL'                          => 12,
  'MARITIME_SURFACE_CONDITIONS_CONTROL'      => 13,
  'WAVE_CONTROL'                             => 14,
  'TERRESTRIAL_SURFACE_CONDITIONS_CONTROL'   => 15,
  'VIEW_CONTROL'                             => 16,
  'SENSOR_CONTROL'                           => 17,
  'MOTION_TRACKER_CONTROL'                   => 18,
  'EARTH_REFERENCE_MODEL_DEFINITION'         => 19,
  'TRAJECTORY_DEFINITION'                    => 20,
  'VIEW_DEFINITION'                          => 21,
  'COLLISION_DETECTION_SEGMENT_DEFINITION'   => 22,
  'COLLISION_DETECTION_VOLUME_DEFINITION'    => 23,
  'HAT_HOT_REQUEST'                          => 24,
  'LINE_OF_SIGHT_SEGMENT_REQUEST'            => 25,
  'LINE_OF_SIGHT_VECTOR_REQUEST'             => 26,
  'POSITION_REQUEST'                         => 27,
  'ENVIRONMENTAL_CONDITIONS_REQUEST'         => 28,
  'SYMBOL_SURFACE_DEFINITION'                => 29,
  'SYMBOL_TEXT_DEFINITION'                   => 30,
  'SYMBOL_CIRCLE_DEFINITION'                 => 31,
  'SYMBOL_LINE_DEFINITION'                   => 32,
  'SYMBOL_CLONE'                             => 33,
  'SYMBOL_CONTROL'                           => 34,
  'SHORT_SYMBOL_CONTROL'                     => 35,
  'START_OF_FRAME'                           => 101,
  'HAT_HOT_RESPONSE'                         => 102,
  'HAT_HOT_EXTENDED_RESPONSE'                => 103,
  'LINE_OF_SIGHT_RESPONSE'                   => 104,
  'LINE_OF_SIGHT_EXTENDED_RESPONSE'          => 105,
  'SENSOR_RESPONSE'                          => 106,
  'SENSOR_EXTENDED_RESPONSE'                 => 107,
  'POSITION_RESPONSE'                        => 108,
  'WEATHER_CONDITIONS_RESPONSE'              => 109,
  'AEROSOL_CONCENTRATION_RESPONSE'           => 110,
  'MARITIME_SURFACE_CONDITIONS_RESPONSE'     => 111,
  'TERRESTRIAL_SURFACE_CONDITIONS_RESPONSE'  => 112,
  'COLLISION_DETECTION_SEGMENT_NOTIFICATION' => 113,
  'COLLISION_DETECTION_VOLUME_NOTIFICATION'  => 114,
  'ANIMATION_STOP_NOTIFICATION'              => 115,
  'EVENT_NOTIFICATION'                       => 116,
  'IMAGE_GENERATOR_MESSAGE'                  => 117,
# PixelRpMode
  'None'                                     => 0,
  'Replicate1x2'                             => 1,
  'Replicate2x1'                             => 2,
  'Replicate2x2'                             => 3,
# Polarity
  'WhiteHot'                                 => 0,
  'BlackHot'                                 => 1,
# PositionCS
  'GeodeticCS'                               => 0,
  'ParentEntityCS'                           => 1,
  'SubmodelCS'                               => 2,
# ProjectnTyp
  'Perspective'                              => 0,
  'OrthographicParallel'                     => 1,
# RateControlCoordinateSystem
  'World_Parent'                             => 0,
  'Local'                                    => 1,
# RegionState
  'Inactive'                                 => 0,
  'Active'                                   => 1,
  'Destroyed'                                => 2,
# ResponseTyp
  'NormalSRT'                                => 0,
  'ExtendedSRT'                              => 1,
# SensorOnOff
  'Off'                                      => 0,
  'On'                                       => 1,
# SensorStatus
  'Searching'                                => 0,
  'Tracking'                                 => 1,
  'ImpendingBreaklock'                       => 2,
  'Breaklock'                                => 3,
# SourceType
  'Symbol'                                   => 0,
  'SymbolTemplate'                           => 1,
# SurfaceState
  'ActiveSS'                                 => 0,
  'DestroyedSS'                              => 1,
# SymbolAttribute
  'None'                                     => 0,
  'SurfaceIdent'                             => 1,
  'ParentSymbolIdent'                        => 2,
  'Layer'                                    => 3,
  'FlashDutyCycle'                           => 4,
  'FlashPeriod'                              => 5,
  'PositionU'                                => 6,
  'PositionV'                                => 7,
  'Rotation'                                 => 8,
  'Color'                                    => 9,
  'ScaleU'                                   => 10,
  'ScaleV'                                   => 11,
# SymbolState
  'Hidden'                                   => 0,
  'Visible'                                  => 1,
  'Destroyed'                                => 2,
# TSCScope
  'GlobalScope'                              => 0,
  'RegionalScope'                            => 1,
  'EntityScope'                              => 2,
# TextAlignment
  'TopLeft'                                  => 0,
  'TopCenter'                                => 1,
  'TopRight'                                 => 2,
  'CenterLeft'                               => 3,
  'Center'                                   => 4,
  'CenterRight'                              => 5,
  'BottomLeft'                               => 6,
  'BottomCenter'                             => 7,
  'BottomRight'                              => 8,
# TextDirection
  'LeftToRight'                              => 0,
  'TopToBottom'                              => 1,
  'RightToLeft'                              => 2,
  'BottomToTop'                              => 3,
# TrackMode
  'Off'                                      => 0,
  'ForceCorrelate'                           => 1,
  'Scene'                                    => 2,
  'Target'                                   => 3,
  'Ship'                                     => 4,
  'IGDefined3'                               => 5,
  'IGDefined2'                               => 6,
  'IGDefined1'                               => 7,
# TrackWhtBlk
  'White'                                    => 0,
  'Black'                                    => 1,
# Valid
  'Invalid'                                  => 0,
  'Valid'                                    => 1,
# ValidNot
  'NotValid'                                 => 0,
  'Valid'                                    => 1,
# ViewReorder
  'NoReorder'                                => 0,
  'BringToTop'                               => 1,
# VolumeType
  'Sphere'                                   => 0,
  'Cuboid'                                   => 1,
# VwGrpSelect
  'View'                                     => 0,
  'ViewGroup'                                => 1,
# WaveScope
  'GlobalScope'                              => 0,
  'RegionalScope'                            => 1,
  'EntityScope'                              => 2,
# WeatherLayer
  'GroundFog'                                => 0,
  'CloudLayer1'                              => 1,
  'CloudLayer2'                              => 2,
  'CloudLayer3'                              => 3,
  'Rain'                                     => 4,
  'Snow'                                     => 5,
  'Sleet'                                    => 6,
  'Hail'                                     => 7,
  'Sand'                                     => 8,
  'Dust'                                     => 9,
# WthrScope
  'GlobalScope'                              => 0,
  'RegionalScope'                            => 1,
  'EntityScope'                              => 2,
  );
  no strict 'refs';       # Allow symbolic references
  for my $name (sort keys %symbols) {
    my $value = $symbols{$name};
    *$name = sub { $value };
  }
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
