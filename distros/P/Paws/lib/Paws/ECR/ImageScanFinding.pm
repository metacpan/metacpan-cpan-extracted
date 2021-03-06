package Paws::ECR::ImageScanFinding;
  use Moose;
  has Attributes => (is => 'ro', isa => 'ArrayRef[Paws::ECR::Attribute]', request_name => 'attributes', traits => ['NameInRequest']);
  has Description => (is => 'ro', isa => 'Str', request_name => 'description', traits => ['NameInRequest']);
  has Name => (is => 'ro', isa => 'Str', request_name => 'name', traits => ['NameInRequest']);
  has Severity => (is => 'ro', isa => 'Str', request_name => 'severity', traits => ['NameInRequest']);
  has Uri => (is => 'ro', isa => 'Str', request_name => 'uri', traits => ['NameInRequest']);
1;

### main pod documentation begin ###

=head1 NAME

Paws::ECR::ImageScanFinding

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::ECR::ImageScanFinding object:

  $service_obj->Method(Att1 => { Attributes => $value, ..., Uri => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::ECR::ImageScanFinding object:

  $result = $service_obj->Method(...);
  $result->Att1->Attributes

=head1 DESCRIPTION

Contains information about an image scan finding.

=head1 ATTRIBUTES


=head2 Attributes => ArrayRef[L<Paws::ECR::Attribute>]

  A collection of attributes of the host from which the finding is
generated.


=head2 Description => Str

  The description of the finding.


=head2 Name => Str

  The name associated with the finding, usually a CVE number.


=head2 Severity => Str

  The finding severity.


=head2 Uri => Str

  A link containing additional details about the security vulnerability.



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::ECR>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

