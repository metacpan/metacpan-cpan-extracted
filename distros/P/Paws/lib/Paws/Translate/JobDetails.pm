package Paws::Translate::JobDetails;
  use Moose;
  has DocumentsWithErrorsCount => (is => 'ro', isa => 'Int');
  has InputDocumentsCount => (is => 'ro', isa => 'Int');
  has TranslatedDocumentsCount => (is => 'ro', isa => 'Int');
1;

### main pod documentation begin ###

=head1 NAME

Paws::Translate::JobDetails

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::Translate::JobDetails object:

  $service_obj->Method(Att1 => { DocumentsWithErrorsCount => $value, ..., TranslatedDocumentsCount => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::Translate::JobDetails object:

  $result = $service_obj->Method(...);
  $result->Att1->DocumentsWithErrorsCount

=head1 DESCRIPTION

The number of documents successfully and unsuccessfully processed
during a translation job.

=head1 ATTRIBUTES


=head2 DocumentsWithErrorsCount => Int

  The number of documents that could not be processed during a
translation job.


=head2 InputDocumentsCount => Int

  The number of documents used as input in a translation job.


=head2 TranslatedDocumentsCount => Int

  The number of documents successfully processed during a translation
job.



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::Translate>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

