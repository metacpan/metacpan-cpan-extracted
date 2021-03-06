package Paws::AppStream::AccessEndpoint;
  use Moose;
  has EndpointType => (is => 'ro', isa => 'Str', required => 1);
  has VpceId => (is => 'ro', isa => 'Str');
1;

### main pod documentation begin ###

=head1 NAME

Paws::AppStream::AccessEndpoint

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::AppStream::AccessEndpoint object:

  $service_obj->Method(Att1 => { EndpointType => $value, ..., VpceId => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::AppStream::AccessEndpoint object:

  $result = $service_obj->Method(...);
  $result->Att1->EndpointType

=head1 DESCRIPTION

Describes an interface VPC endpoint (interface endpoint) that lets you
create a private connection between the virtual private cloud (VPC)
that you specify and AppStream 2.0. When you specify an interface
endpoint for a stack, users of the stack can connect to AppStream 2.0
only through that endpoint. When you specify an interface endpoint for
an image builder, administrators can connect to the image builder only
through that endpoint.

=head1 ATTRIBUTES


=head2 B<REQUIRED> EndpointType => Str

  The type of interface endpoint.


=head2 VpceId => Str

  The identifier (ID) of the VPC in which the interface endpoint is used.



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::AppStream>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

