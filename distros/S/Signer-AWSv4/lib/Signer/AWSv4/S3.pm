package Signer::AWSv4::S3;
  use Moo;
  use Types::Standard qw/Str/;
  extends 'Signer::AWSv4';

  has bucket => (is => 'ro', isa => Str, required => 1);
  has key => (is => 'ro', isa => Str, required => 1);
  has content_disposition => (is => 'ro', isa => Str);
  has content_type => (is => 'ro', isa => Str);
  has content_encoding => (is => 'ro', isa => Str);
  has content_language => (is => 'ro', isa => Str);
  has cache_control => (is => 'ro', isa => Str);  
  has version_id => (is => 'ro', isa => Str);

  has '+service' => (default => 's3');
  has '+uri' => (init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    sprintf "/%s/%s", $self->bucket, $self->key;
  });

  has bucket_host => (is => 'ro', isa => Str, init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    if ($self->region =~m/us-east-1/i) {
      return 's3.amazonaws.com';
    } else {
      return 's3-' . $self->region . '.amazonaws.com';
    }
  });

  has '+unsigned_payload' => (default => 1);

  sub build_params {
    my $self = shift;
    {
      'X-Amz-Algorithm' => $self->aws_algorithm,
      'X-Amz-Credential' => $self->access_key . "/" . $self->credential_scope,
      'X-Amz-Date' => $self->date_timestamp,
      'X-Amz-Expires' => $self->expires,
      'X-Amz-SignedHeaders' => $self->signed_header_list,
      ('response-content-disposition' => $self->content_disposition) x!! $self->content_disposition,
      ('response-content-type' => $self->content_type) x!! $self->content_type,
      ('response-content-encoding' => $self->content_encoding) x!! $self->content_encoding,
      ('response-content-language' => $self->content_language) x!! $self->content_language,
      ('response-cache-control' => $self->cache_control) x!! $self->cache_control,  
      (versionId => $self->version_id) x!! $self->version_id,
    }
  }

  sub build_headers {
    my $self = shift;
    {
      Host => $self->bucket_host,
    }
  }

  has signed_url => (is => 'ro', isa => Str, init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    return join '', 'https://', $self->bucket_host, $self->uri, '?', $self->signed_qstring;
  });

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Signer::AWSv4::S3 - Implements the AWS v4 signature algorithm

=head1 SYNOPSIS

  use Signer::AWSv4::S3;
  $s3_sig = Signer::AWSv4::S3->new(
    access_key => 'AKIAIOSFODNN7EXAMPLE',
    secret_key => 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    method => 'GET',
    key => 'test.txt',
    bucket => 'examplebucket',
    region => 'us-east-1',
    expires => 86400,
    version_id => '1234561zOnAAAJKHxVKBxxEyuy_78901j',
    content_type => 'text/plain',
    content_disposition => 'inline; filename=New Name.txt',  
  );
  say $s3_sig->signed_url;

=head1 DESCRIPTION

Generates S3 Presigned URLs.

=head1 Request Attributes

This module adds two required attributes in the constructor for obtaining an
S3 Presigned URL:

=head2 key

The name of the object in S3. This should not start with a slash (/)

=head2 bucket

The name of the S3 bucket

=head2 versionId

VersionId used to reference a specific version of the object.

=head1 Overriding Response Header Values

There are times when you want to override certain response header values in a GET response.

=head2 cache_control

Sets the Cache-Control header of the response.

=head2 content_disposition

Sets the Content-Disposition header of the response

=head2 content_encoding

Sets the Content-Encoding header of the response.

=head2 content_language

Sets the Content-Language header of the response.

=head2 content_type

Sets the Content-Type header of the response.

=head1 Signature Attributes

Apart from those in L<Signer::AWSv4>, a convenience attribute is added:

=head2 signed_url

The presigned URL to download the object

=head1 BUGS and SOURCE

The source code is located here: L<https://github.com/pplu/AWSv4Signer>

Please report bugs to: L<https://github.com/pplu/AWSv4Signer/issues>

=head1 AUTHOR

    Jose Luis Martinez
    pplusdomain@gmail.com

=head1 COPYRIGHT and LICENSE

Copyright (c) 2018 by Jose Luis Martinez

This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.

=cut
