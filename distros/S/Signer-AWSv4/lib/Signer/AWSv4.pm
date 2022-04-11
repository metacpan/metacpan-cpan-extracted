package Signer::AWSv4;
  use Moo;
  use Types::Standard qw/Str Int HashRef Bool InstanceOf ArrayRef/;
  use Time::Piece;
  use Digest::SHA qw//;
  use URI::Escape qw//;

  our $VERSION = '0.08';

  has access_key => (is => 'ro', isa => Str, required => 1);
  has secret_key => (is => 'ro', isa => Str, required => 1);
  has session_token => (is => 'ro', isa => Str);
  has method => (is => 'ro', isa => Str, required => 1);
  has uri => (is => 'ro', isa => Str, required => 1);
  has region => (is => 'ro', isa => Str, required => 1);
  has service => (is => 'ro', isa => Str, required => 1);

  has expires => (is => 'ro', isa => Int, required => 1);

  # build_params and build_headers have to be implemented in subclasses to include
  # the query string parameters (params) and the headers for the request
  has params  => (is => 'ro', isa => HashRef, lazy => 1, builder => 'build_params');
  has headers => (is => 'ro', isa => HashRef, lazy => 1, builder => 'build_headers');
  has content => (is => 'ro', isa => Str, default => '');
  has unsigned_payload => (is => 'ro', isa => Bool, default => 0);

  has time => (is => 'ro', isa => InstanceOf['Time::Piece'], default => sub {
    gmtime;
  });

  has date => (is => 'ro', isa => Str, init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    $self->time->ymd('');
  });

  has date_timestamp => (is => 'ro', isa => Str, init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    $self->time->ymd('') . 'T' . $self->time->hms('') . 'Z';
  });

  has canonical_qstring => (is => 'ro', isa => Str, lazy => 1, default => sub {
    my $self = shift;
    join '&', map { $_ . '=' . URI::Escape::uri_escape($self->params->{ $_ }) } sort keys %{ $self->params };
  });

  has header_list => (is => 'ro', isa => ArrayRef, init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    [ sort keys %{ $self->headers } ];
  });

  has canonical_headers => (is => 'ro', isa => Str, lazy => 1, default => sub {
    my $self = shift;
    join '', map { lc( $_ ) . ":" . $self->headers->{ $_ } . "\n" } @{ $self->header_list };
  });

  has hashed_payload => (is => 'ro', isa => Str, init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    return ($self->unsigned_payload) ? 'UNSIGNED-PAYLOAD' : Digest::SHA::sha256_hex($self->content);
  });

  has signed_header_list => (is => 'ro', isa => Str, init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    join ';', map { lc($_) } @{ $self->header_list };
  });

  has canonical_request => (is => 'ro', isa => Str, lazy => 1, default => sub {
    my $self = shift;
    join "\n", $self->method,
               $self->uri,
               $self->canonical_qstring,
               $self->canonical_headers,
               $self->signed_header_list,
               $self->hashed_payload;
  });

  has credential_scope => (is => 'ro', isa => Str, init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    join '/', $self->date, $self->region, $self->service, 'aws4_request';
  });

  has aws_algorithm => (is => 'ro', isa => Str, init_arg => undef, default => 'AWS4-HMAC-SHA256');

  has string_to_sign => (is => 'ro', isa => Str, init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    join "\n", $self->aws_algorithm,
               $self->date_timestamp,
               $self->credential_scope,
               Digest::SHA::sha256_hex($self->canonical_request);
  });

  has signing_key => (is => 'ro', isa => Str, init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    my $kSecret = "AWS4" . $self->secret_key;
    my $kDate = Digest::SHA::hmac_sha256($self->date, $kSecret);
    my $kRegion = Digest::SHA::hmac_sha256($self->region, $kDate);
    my $kService = Digest::SHA::hmac_sha256($self->service, $kRegion);
    return Digest::SHA::hmac_sha256("aws4_request", $kService);
  });

  has signature => (is => 'ro', isa => Str, init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    Digest::SHA::hmac_sha256_hex($self->string_to_sign, $self->signing_key);
  });

  has signed_qstring => (is => 'ro', isa => Str, init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    $self->canonical_qstring . '&X-Amz-Signature=' . $self->signature;
  });

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Signer::AWSv4 - Implements the AWS v4 signature algorithm

=head1 DESCRIPTION

Yet Another module to sign requests to Amazon Web Services APIs 
with the AWSv4 signing algorithm. This module has a different twist. The
rest of modules out there are tied to signing HTTP::Request objects, but 
AWS uses v4 signatures in other places: IAM user login to MySQL RDSs, EKS, 
S3 Presigned URLs, etc. When building authentication modules for these services, 
I've had to create artificial HTTP::Request objects, just for a signing module
to sign them, and then retrieve the signature. This module solves that problem,
not being tied to any specific object to sign.

Signer::AWSv4 is a base class that implements the main v4 Algorithm. You're supposed
L<https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html>
to subclass and override attributes to adjust how you want the signature to
be built.

It's attributes let you inspect the entire signing process (making the string to
sign, the signature, etc available for inspection)

=head1 Specialized Signers

L<Signer::AWSv4::S3> - Build presigned S3 URLs

L<Signer::AWSv4::EKS> - Login to EKS clusters

L<Signer::AWSv4::RDS> - Login to MySQL RDS servers with IAM credentials

=head1 Request Attributes

=head2 access_key

Holds the AWS Access Key to sign with. Please don't hardcode your credentials. Get them
from some AWS authentication readers like L<Net::Amazon::Config>, L<Config::AWS>, 
L<AWS::CLI::Config>, One of L<Paws::Credential> subclasses.

=head2 secret_key String

Holds the AWS Secret Key

=head2 session_token String

Optional. The session token when using STS temporary credentials. Some services
may not support authenticating with temporary credentials.

=head2 method String

The method to sign with. This can be overwritten by subclasses to provide an
appropiate default for a specific service. 

=head2 uri String

The uri to sign with. This can be overwritten by subclasses to provide an
appropiate default for a specific service

=head2 region String

The uri to sign with. This can be overwritten by subclasses to provide an
appropiate default for a specific service

=head2 service String

The service to sign with. This can be overwritten by subclasses to provide an
appropiate default for a specific service

=head2 expires Integer

The time for which the signature will be valid. This may be defaulted in 
subclasses so the user doesn't have to specify it.

=head2 params HashRef of Strings

The query parameters to sign. Subclasses must implement a build_params method
that sets the query parameters to sign appropiately.

=head2 headers HashRef of Strings

The headers to sign. Subclasses must implement a build_headers method that sets
the headers to sign appropiately.

=head2 content String

The content of the request to be signed.

=head2 unsigned_payload Bool

Indicates wheather the payload (content) should be signed or not.

=head1 Signature Attributes

Attributes for obtaining the final signature

=head1 signature

The final signature. Just a hexadecimal string with the result of signing the request

=head1 signed_qstring

The query string that should be added to a URL to obtain a signed URL (some subclasses
use this signed query string internally)

=head1 Internal Attributes

The computation of the signature is heald in a series of attributes that are 
built for dumping, diagnosing and controlling the signature process

=head2 time

A L<Time::Piece> object that holds the time for the signature. Defaulted to "now"

=head2 date, date_timestamp

Values used in intermediate parts of the signature process. Derived from time.
  
=head2 canonical_qstring

The Canonical Query String to be used in the signature process.

=head2 header_list

The list of headers to sign. Defaults to all headers in the headers attribute

=head2 canonical_headers

The cannonical list of headers to use in the signature process. Depends on header_list

=head2 hashed_payload

The hashed payload of the request

=head2 signed_header_list

The list of signed headers, ready for inclusion in the canonical request

=head2 canonical_request

The canonical request that will be signed. Brings together the method, uri, 
canonical_qstring, canonical_headers, signed_header_list and hashed_payload

=head2 credential_scope

The credential scope to be used to sign the request

=head2 aws_algorithm

The string that identifies the signing algorithm version. Defaults to C<AWS4-HMAC-SHA256>

=head2 string_to_sign

The string to sign

=head2 signing_key

The signing key

These internal concepts can be found in L<https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html>, that describes the signature process.

=head1 TODO

Implement a signer for the AWS ElasticSearch service

Implement a generic "sign an HTTP::Request" signer

Pass the same test suite that L<Net::Amazon::Signature::V4> has

=head1 SEE ALSO

L<AWS::Signature4>

L<Net::Amazon::Signature::V4>

L<WebService::Amazon::Signature::v4>

L<https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html>

=head1 CONTRIBUTIONS

manwar: specify missing prereqs

mschout: add version support to S3

lucas1: add overriding response headers

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
