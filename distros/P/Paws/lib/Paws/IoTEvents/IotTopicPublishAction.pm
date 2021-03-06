package Paws::IoTEvents::IotTopicPublishAction;
  use Moose;
  has MqttTopic => (is => 'ro', isa => 'Str', request_name => 'mqttTopic', traits => ['NameInRequest'], required => 1);
1;

### main pod documentation begin ###

=head1 NAME

Paws::IoTEvents::IotTopicPublishAction

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::IoTEvents::IotTopicPublishAction object:

  $service_obj->Method(Att1 => { MqttTopic => $value, ..., MqttTopic => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::IoTEvents::IotTopicPublishAction object:

  $result = $service_obj->Method(...);
  $result->Att1->MqttTopic

=head1 DESCRIPTION

Information required to publish the MQTT message via the AWS IoT
message broker.

=head1 ATTRIBUTES


=head2 B<REQUIRED> MqttTopic => Str

  The MQTT topic of the message.



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::IoTEvents>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

