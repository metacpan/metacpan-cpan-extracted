package Paws::Kendra::DataSourceSyncJob;
  use Moose;
  has DataSourceErrorCode => (is => 'ro', isa => 'Str');
  has EndTime => (is => 'ro', isa => 'Str');
  has ErrorCode => (is => 'ro', isa => 'Str');
  has ErrorMessage => (is => 'ro', isa => 'Str');
  has ExecutionId => (is => 'ro', isa => 'Str');
  has StartTime => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Str');
1;

### main pod documentation begin ###

=head1 NAME

Paws::Kendra::DataSourceSyncJob

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::Kendra::DataSourceSyncJob object:

  $service_obj->Method(Att1 => { DataSourceErrorCode => $value, ..., Status => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::Kendra::DataSourceSyncJob object:

  $result = $service_obj->Method(...);
  $result->Att1->DataSourceErrorCode

=head1 DESCRIPTION

Provides information about a synchronization job.

=head1 ATTRIBUTES


=head2 DataSourceErrorCode => Str

  If the reason that the synchronization failed is due to an error with
the underlying data source, this field contains a code that identifies
the error.


=head2 EndTime => Str

  The UNIX datetime that the synchronization job was completed.


=head2 ErrorCode => Str

  If the C<Status> field is set to C<FAILED>, the C<ErrorCode> field
contains a the reason that the synchronization failed.


=head2 ErrorMessage => Str

  If the C<Status> field is set to C<ERROR>, the C<ErrorMessage> field
contains a description of the error that caused the synchronization to
fail.


=head2 ExecutionId => Str

  A unique identifier for the synchronization job.


=head2 StartTime => Str

  The UNIX datetime that the synchronization job was started.


=head2 Status => Str

  The execution status of the synchronization job. When the C<Status>
field is set to C<SUCCEEDED>, the synchronization job is done. If the
status code is set to C<FAILED>, the C<ErrorCode> and C<ErrorMessage>
fields give you the reason for the failure.



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::Kendra>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

