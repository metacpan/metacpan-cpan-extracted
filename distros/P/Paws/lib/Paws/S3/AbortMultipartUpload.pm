
package Paws::S3::AbortMultipartUpload;
  use Moose;
  has Bucket => (is => 'ro', isa => 'Str', uri_name => 'Bucket', traits => ['ParamInURI'], required => 1);
  has Key => (is => 'ro', isa => 'Str', uri_name => 'Key', traits => ['ParamInURI'], required => 1);
  has RequestPayer => (is => 'ro', isa => 'Str', header_name => 'x-amz-request-payer', traits => ['ParamInHeader']);
  has UploadId => (is => 'ro', isa => 'Str', query_name => 'uploadId', traits => ['ParamInQuery'], required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AbortMultipartUpload');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/{Bucket}/{Key+}');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'DELETE');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::S3::AbortMultipartUploadOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
  
1;

### main pod documentation begin ###

=head1 NAME

Paws::S3::AbortMultipartUpload - Arguments for method AbortMultipartUpload on L<Paws::S3>

=head1 DESCRIPTION

This class represents the parameters used for calling the method AbortMultipartUpload on the
L<Amazon Simple Storage Service|Paws::S3> service. Use the attributes of this class
as arguments to method AbortMultipartUpload.

You shouldn't make instances of this class. Each attribute should be used as a named argument in the call to AbortMultipartUpload.

=head1 SYNOPSIS

    my $s3 = Paws->service('S3');
    my $AbortMultipartUploadOutput = $s3->AbortMultipartUpload(
      Bucket       => 'MyBucketName',
      Key          => 'MyObjectKey',
      UploadId     => 'MyMultipartUploadId',
      RequestPayer => 'requester',             # OPTIONAL
    );

    # Results:
    my $RequestCharged = $AbortMultipartUploadOutput->RequestCharged;

    # Returns a L<Paws::S3::AbortMultipartUploadOutput> object.

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.
For the AWS API documentation, see L<https://docs.aws.amazon.com/goto/WebAPI/s3/AbortMultipartUpload>

=head1 ATTRIBUTES


=head2 B<REQUIRED> Bucket => Str

The bucket name to which the upload was taking place.

When using this API with an access point, you must direct requests to
the access point hostname. The access point hostname takes the form
I<AccessPointName>-I<AccountId>.s3-accesspoint.I<Region>.amazonaws.com.
When using this operation using an access point through the AWS SDKs,
you provide the access point ARN in place of the bucket name. For more
information about access point ARNs, see Using Access Points
(https://docs.aws.amazon.com/AmazonS3/latest/dev/using-access-points.html)
in the I<Amazon Simple Storage Service Developer Guide>.



=head2 B<REQUIRED> Key => Str

Key of the object for which the multipart upload was initiated.



=head2 RequestPayer => Str



Valid values are: C<"requester">

=head2 B<REQUIRED> UploadId => Str

Upload ID that identifies the multipart upload.




=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AbortMultipartUpload in L<Paws::S3>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

