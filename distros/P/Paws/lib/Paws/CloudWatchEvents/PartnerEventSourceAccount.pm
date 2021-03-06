package Paws::CloudWatchEvents::PartnerEventSourceAccount;
  use Moose;
  has Account => (is => 'ro', isa => 'Str');
  has CreationTime => (is => 'ro', isa => 'Str');
  has ExpirationTime => (is => 'ro', isa => 'Str');
  has State => (is => 'ro', isa => 'Str');
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchEvents::PartnerEventSourceAccount

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::CloudWatchEvents::PartnerEventSourceAccount object:

  $service_obj->Method(Att1 => { Account => $value, ..., State => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::CloudWatchEvents::PartnerEventSourceAccount object:

  $result = $service_obj->Method(...);
  $result->Att1->Account

=head1 DESCRIPTION

The AWS account that a partner event source has been offered to.

=head1 ATTRIBUTES


=head2 Account => Str

  The AWS account ID that the partner event source was offered to.


=head2 CreationTime => Str

  The date and time when the event source was created.


=head2 ExpirationTime => Str

  The date and time when the event source will expire if the AWS account
doesn't create a matching event bus for it.


=head2 State => Str

  The state of the event source. If it's C<ACTIVE>, you have already
created a matching event bus for this event source, and that event bus
is active. If it's C<PENDING>, either you haven't yet created a
matching event bus, or that event bus is deactivated. If it's
C<DELETED>, you have created a matching event bus, but the event source
has since been deleted.



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::CloudWatchEvents>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

