package Signer::AWSv4::S3;
  use Moo;
  use Types::Standard qw/Str/;
  extends 'Signer::AWSv4';

  has bucket => (is => 'ro', isa => Str, required => 1);
  has key => (is => 'ro', isa => Str, required => 1);

  has '+service' => (default => 's3');
  has '+uri' => (init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    sprintf "/%s/%s", $self->bucket, $self->key;
  });

  has bucket_host => (is => 'ro', isa => Str, init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    's3-' . $self->region . '.amazonaws.com';
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

=head1 Signature Attributes

Apart from those in L<Signer::AWSv4>, a convenience attribute is added:

=head2 signed_url

The presigned URL to download the object

=head1 BUGS and SOURCE

The source code is located here: L<https://github.com/pplu/AWSv4Signer>

Please report bugs to: L<https://github.com/pplu/AWSv4Signer/issues>

=head1 AUTHOR

    Jose Luis Martinez
    CAPSiDE
    jlmartinez@capside.com

=head1 COPYRIGHT and LICENSE

Copyright (c) 2018 by CAPSiDE

This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.

=cut
