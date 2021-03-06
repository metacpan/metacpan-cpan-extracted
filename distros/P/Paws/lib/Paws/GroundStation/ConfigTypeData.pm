package Paws::GroundStation::ConfigTypeData;
  use Moose;
  has AntennaDownlinkConfig => (is => 'ro', isa => 'Paws::GroundStation::AntennaDownlinkConfig', request_name => 'antennaDownlinkConfig', traits => ['NameInRequest']);
  has AntennaDownlinkDemodDecodeConfig => (is => 'ro', isa => 'Paws::GroundStation::AntennaDownlinkDemodDecodeConfig', request_name => 'antennaDownlinkDemodDecodeConfig', traits => ['NameInRequest']);
  has AntennaUplinkConfig => (is => 'ro', isa => 'Paws::GroundStation::AntennaUplinkConfig', request_name => 'antennaUplinkConfig', traits => ['NameInRequest']);
  has DataflowEndpointConfig => (is => 'ro', isa => 'Paws::GroundStation::DataflowEndpointConfig', request_name => 'dataflowEndpointConfig', traits => ['NameInRequest']);
  has TrackingConfig => (is => 'ro', isa => 'Paws::GroundStation::TrackingConfig', request_name => 'trackingConfig', traits => ['NameInRequest']);
  has UplinkEchoConfig => (is => 'ro', isa => 'Paws::GroundStation::UplinkEchoConfig', request_name => 'uplinkEchoConfig', traits => ['NameInRequest']);
1;

### main pod documentation begin ###

=head1 NAME

Paws::GroundStation::ConfigTypeData

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::GroundStation::ConfigTypeData object:

  $service_obj->Method(Att1 => { AntennaDownlinkConfig => $value, ..., UplinkEchoConfig => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::GroundStation::ConfigTypeData object:

  $result = $service_obj->Method(...);
  $result->Att1->AntennaDownlinkConfig

=head1 DESCRIPTION

Object containing the parameters of a C<Config>.

See the subtype definitions for what each type of C<Config> contains.

=head1 ATTRIBUTES


=head2 AntennaDownlinkConfig => L<Paws::GroundStation::AntennaDownlinkConfig>

  Information about how AWS Ground Station should configure an antenna
for downlink during a contact.


=head2 AntennaDownlinkDemodDecodeConfig => L<Paws::GroundStation::AntennaDownlinkDemodDecodeConfig>

  Information about how AWS Ground Station should congure an antenna for
downlink demod decode during a contact.


=head2 AntennaUplinkConfig => L<Paws::GroundStation::AntennaUplinkConfig>

  Information about how AWS Ground Station should congure an antenna for
uplink during a contact.


=head2 DataflowEndpointConfig => L<Paws::GroundStation::DataflowEndpointConfig>

  Information about the dataflow endpoint C<Config>.


=head2 TrackingConfig => L<Paws::GroundStation::TrackingConfig>

  Object that determines whether tracking should be used during a contact
executed with this C<Config> in the mission profile.


=head2 UplinkEchoConfig => L<Paws::GroundStation::UplinkEchoConfig>

  Information about an uplink echo C<Config>.

Parameters from the C<AntennaUplinkConfig>, corresponding to the
specified C<AntennaUplinkConfigArn>, are used when this
C<UplinkEchoConfig> is used in a contact.



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::GroundStation>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

