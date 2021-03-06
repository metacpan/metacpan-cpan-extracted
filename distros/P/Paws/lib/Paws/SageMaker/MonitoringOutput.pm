package Paws::SageMaker::MonitoringOutput;
  use Moose;
  has S3Output => (is => 'ro', isa => 'Paws::SageMaker::MonitoringS3Output', required => 1);
1;

### main pod documentation begin ###

=head1 NAME

Paws::SageMaker::MonitoringOutput

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::SageMaker::MonitoringOutput object:

  $service_obj->Method(Att1 => { S3Output => $value, ..., S3Output => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::SageMaker::MonitoringOutput object:

  $result = $service_obj->Method(...);
  $result->Att1->S3Output

=head1 DESCRIPTION

The output object for a monitoring job.

=head1 ATTRIBUTES


=head2 B<REQUIRED> S3Output => L<Paws::SageMaker::MonitoringS3Output>

  The Amazon S3 storage location where the results of a monitoring job
are saved.



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::SageMaker>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

