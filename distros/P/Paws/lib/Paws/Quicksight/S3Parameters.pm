package Paws::Quicksight::S3Parameters;
  use Moose;
  has ManifestFileLocation => (is => 'ro', isa => 'Paws::Quicksight::ManifestFileLocation', required => 1);
1;

### main pod documentation begin ###

=head1 NAME

Paws::Quicksight::S3Parameters

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::Quicksight::S3Parameters object:

  $service_obj->Method(Att1 => { ManifestFileLocation => $value, ..., ManifestFileLocation => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::Quicksight::S3Parameters object:

  $result = $service_obj->Method(...);
  $result->Att1->ManifestFileLocation

=head1 DESCRIPTION

S3 parameters.

=head1 ATTRIBUTES


=head2 B<REQUIRED> ManifestFileLocation => L<Paws::Quicksight::ManifestFileLocation>

  Location of the Amazon S3 manifest file. This is NULL if the manifest
file was uploaded in the console.



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::Quicksight>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

