package Paws::SecurityHub::AwsLambdaFunctionEnvironment;
  use Moose;
  has Error => (is => 'ro', isa => 'Paws::SecurityHub::AwsLambdaFunctionEnvironmentError');
  has Variables => (is => 'ro', isa => 'Paws::SecurityHub::FieldMap');
1;

### main pod documentation begin ###

=head1 NAME

Paws::SecurityHub::AwsLambdaFunctionEnvironment

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::SecurityHub::AwsLambdaFunctionEnvironment object:

  $service_obj->Method(Att1 => { Error => $value, ..., Variables => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::SecurityHub::AwsLambdaFunctionEnvironment object:

  $result = $service_obj->Method(...);
  $result->Att1->Error

=head1 DESCRIPTION

A function's environment variable settings.

=head1 ATTRIBUTES


=head2 Error => L<Paws::SecurityHub::AwsLambdaFunctionEnvironmentError>

  An C<AwsLambdaFunctionEnvironmentError> object.


=head2 Variables => L<Paws::SecurityHub::FieldMap>

  Environment variable key-value pairs.



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::SecurityHub>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

