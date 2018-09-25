package Signer::AWSv4::EKS;
  use Moo;
  extends 'Signer::AWSv4';
  use Types::Standard qw/Str/;

  use JSON::MaybeXS qw//;
  use MIME::Base64 qw//;

  has prefix => (is => 'ro', init_arg => undef, isa => Str, default => 'k8s-aws-v1');
  has sts_url => (is => 'ro', init_arg => undef, isa => Str, default => 'https://sts.amazonaws.com/');

  has cluster_id => (is => 'ro', isa => Str, required => 1);

  has '+expires' => (default => 60);
  has '+region' => (default => 'us-east-1');
  has '+service' => (default => 'sts');
  has '+method' => (default => 'GET');
  has '+uri' => (default => '/');

  sub build_params {
    my $self = shift;
    {
      'Action' => 'GetCallerIdentity',
      'Version' => '2011-06-15',
      'X-Amz-Algorithm' => $self->aws_algorithm,
      'X-Amz-Credential' => $self->access_key . "/" . $self->credential_scope,
      'X-Amz-Date' => $self->date_timestamp,
      'X-Amz-Expires' => $self->expires,
      'X-Amz-SignedHeaders' => $self->signed_header_list,
      (defined $self->session_token) ? ('X-Amz-Security-Token' => $self->session_token) : (),
    }
  }

  sub build_headers {
    my $self = shift;
    {
      Host => 'sts.amazonaws.com',
     'x-k8s-aws-id' => $self->cluster_id,
    }
  }

  has qstring_64 => (is => 'ro', isa => Str, init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    MIME::Base64::encode_base64url($self->signed_qstring);
  });

  has token => (is => 'ro', isa => Str, init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    $self->prefix . '.' . MIME::Base64::encode_base64url($self->sts_url) . '_' . $self->qstring_64;
  });

  has k8s_json => (is => 'ro', isa => Str, init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    JSON::MaybeXS::encode_json({
      kind => 'ExecCredential',
      apiVersion => 'client.authentication.k8s.io/v1alpha1',
      spec => {},
      status => {
        token => $self->token,
      }
    });
  });

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Signer::AWSv4::EKS - Generate tokens for logging in to EKS Kubernetes clusters

=head1 SYNOPSIS

  use Signer::AWSv4::EKS;
  my $signer = Signer::AWSv4::EKS->new(
    access_key => 'AKIAIOSFODNN7EXAMPLE',
    secret_key => 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    cluster_id => 'eks_cluster_name',
  );
  my $token = $signer->signed_qstring;

=head1 DESCRIPTION

Generate tokens for logging in to EKS Kubernetes clusters. This implements the same algorithm that the Heptio autheticator does. L<https://github.com/kubernetes-sigs/aws-iam-authenticator>

=head1 Request Attributes

This module adds one required attributee in the constructor for obtaining a token

=head2 cluster_id String

The name of the EKS cluster in AWS

=head1 Signature Attributes

=head2 token

The authentication token to be passed to the Kubernetes cluster (via Authorization header or kubectl --token)

=head2 k8s_json

This wraps the token in the appropiate JSON output for using the token as kubectl pluggable 
authentication module

=head1 SEE ALSO

L<https://github.com/kubernetes-sigs/aws-iam-authenticator>

=head1 BUGS and SOURCE

The source code is located here: L<https://github.com/pplu/AWSv4Signer>

Please report bugs to: L<https://github.com/pplu/AWSv4Signer/issues>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2018 by CAPSiDE

This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.

=cut
