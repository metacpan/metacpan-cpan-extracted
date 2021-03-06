package Paws::WorkDocs::UploadMetadata;
  use Moose;
  has SignedHeaders => (is => 'ro', isa => 'Paws::WorkDocs::SignedHeaderMap');
  has UploadUrl => (is => 'ro', isa => 'Str');
1;

### main pod documentation begin ###

=head1 NAME

Paws::WorkDocs::UploadMetadata

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::WorkDocs::UploadMetadata object:

  $service_obj->Method(Att1 => { SignedHeaders => $value, ..., UploadUrl => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::WorkDocs::UploadMetadata object:

  $result = $service_obj->Method(...);
  $result->Att1->SignedHeaders

=head1 DESCRIPTION

Describes the upload.

=head1 ATTRIBUTES


=head2 SignedHeaders => L<Paws::WorkDocs::SignedHeaderMap>

  The signed headers.


=head2 UploadUrl => Str

  The URL of the upload.



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::WorkDocs>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

