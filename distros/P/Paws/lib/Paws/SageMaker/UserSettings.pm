package Paws::SageMaker::UserSettings;
  use Moose;
  has ExecutionRole => (is => 'ro', isa => 'Str');
  has JupyterServerAppSettings => (is => 'ro', isa => 'Paws::SageMaker::JupyterServerAppSettings');
  has KernelGatewayAppSettings => (is => 'ro', isa => 'Paws::SageMaker::KernelGatewayAppSettings');
  has SecurityGroups => (is => 'ro', isa => 'ArrayRef[Str|Undef]');
  has SharingSettings => (is => 'ro', isa => 'Paws::SageMaker::SharingSettings');
  has TensorBoardAppSettings => (is => 'ro', isa => 'Paws::SageMaker::TensorBoardAppSettings');
1;

### main pod documentation begin ###

=head1 NAME

Paws::SageMaker::UserSettings

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::SageMaker::UserSettings object:

  $service_obj->Method(Att1 => { ExecutionRole => $value, ..., TensorBoardAppSettings => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::SageMaker::UserSettings object:

  $result = $service_obj->Method(...);
  $result->Att1->ExecutionRole

=head1 DESCRIPTION

A collection of settings.

=head1 ATTRIBUTES


=head2 ExecutionRole => Str

  The execution role for the user.


=head2 JupyterServerAppSettings => L<Paws::SageMaker::JupyterServerAppSettings>

  The Jupyter server's app settings.


=head2 KernelGatewayAppSettings => L<Paws::SageMaker::KernelGatewayAppSettings>

  The kernel gateway app settings.


=head2 SecurityGroups => ArrayRef[Str|Undef]

  The security groups.


=head2 SharingSettings => L<Paws::SageMaker::SharingSettings>

  The sharing settings.


=head2 TensorBoardAppSettings => L<Paws::SageMaker::TensorBoardAppSettings>

  The TensorBoard app settings.



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::SageMaker>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

