
package Paws::CognitoSync::DeleteDataset;
  use Moose;
  has DatasetName => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'DatasetName', required => 1);
  has IdentityId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'IdentityId', required => 1);
  has IdentityPoolId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'IdentityPoolId', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteDataset');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'DELETE');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CognitoSync::DeleteDatasetResponse');
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoSync::DeleteDataset - Arguments for method DeleteDataset on L<Paws::CognitoSync>

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteDataset on the
L<Amazon Cognito Sync|Paws::CognitoSync> service. Use the attributes of this class
as arguments to method DeleteDataset.

You shouldn't make instances of this class. Each attribute should be used as a named argument in the call to DeleteDataset.

=head1 SYNOPSIS

    my $cognito-sync = Paws->service('CognitoSync');
    my $DeleteDatasetResponse = $cognito -sync->DeleteDataset(
      DatasetName    => 'MyDatasetName',
      IdentityId     => 'MyIdentityId',
      IdentityPoolId => 'MyIdentityPoolId',

    );

    # Results:
    my $Dataset = $DeleteDatasetResponse->Dataset;

    # Returns a L<Paws::CognitoSync::DeleteDatasetResponse> object.

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.
For the AWS API documentation, see L<https://docs.aws.amazon.com/goto/WebAPI/cognito-sync/DeleteDataset>

=head1 ATTRIBUTES


=head2 B<REQUIRED> DatasetName => Str

A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9,
'_' (underscore), '-' (dash), and '.' (dot).



=head2 B<REQUIRED> IdentityId => Str

A name-spaced GUID (for example,
us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon
Cognito. GUID generation is unique within a region.



=head2 B<REQUIRED> IdentityPoolId => Str

A name-spaced GUID (for example,
us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon
Cognito. GUID generation is unique within a region.




=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteDataset in L<Paws::CognitoSync>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

