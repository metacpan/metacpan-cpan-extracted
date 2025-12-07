package Mojo::UserAgent::Role::AWSSignature4;
use Mojo::Base -role, -signatures;

use Digest::SHA;
use Mojo::Collection;
use Time::Piece;

our $VERSION = '0.01';

has access_key       => sub { $ENV{AWS_ACCESS_KEY} or die 'missing "access_key"' };
has aws_algorithm    => 'AWS4-HMAC-SHA256';
has content          => undef;
has debug            => 0;
has expires          => 86_400;
has region           => 'us-east-1';
has secret_key       => sub { $ENV{AWS_SECRET_KEY} or die 'missing "secret_key"' };
has service          => sub { die 'missing "service"' };
has session_token    => sub { $ENV{AWS_SESSION_TOKEN} || undef };
has unsigned_payload => 0;
has _tx              => sub {die};

around build_tx => sub ($orig, $self, @args) {
  $self->transactor->add_generator(
    awssig4 => sub {
      my ($transactor, $tx, $config) = @_;
      my $aws = $self->new({%$config, _tx => $tx});
      $tx->req->content->asset(Mojo::Asset::File->new(path => $aws->content)) if $aws->content;
      $tx->req->headers->host($tx->req->url->host || 'localhost');
      $tx->req->headers->header('X-Amz-Date'           => $aws->date_timestamp);
      $tx->req->headers->header('X-Amz-Content-Sha256' => $aws->hashed_payload);
      $tx->req->headers->header('X-Amz-Expires'        => $aws->expires) if $aws->expires;
      $tx->req->headers->authorization($aws->authorization);
    }
  );
  $orig->($self, @args);
};

sub authorization ($self) {
  sprintf '%s Credential=%s/%s, SignedHeaders=%s, Signature=%s', $self->aws_algorithm, $self->access_key,
    $self->credential_scope, $self->signed_header_list, $self->signature;
}

sub canonical_headers ($self) {
  join '', map { lc($_) . ":" . $self->_tx->req->headers->to_hash->{$_} . "\n" } @{$self->header_list};
}

sub canonical_qstring { shift->_tx->req->url->query->to_string }

sub canonical_request ($self) {
  Mojo::Collection->new(
    $self->_tx->req->method,
    $self->_tx->req->url->path->to_abs_string,
    $self->canonical_qstring, $self->canonical_headers, $self->signed_header_list, $self->hashed_payload
  )->tap(sub {
    warn $_->map(sub {"CR:$_"})->join("\n") if $self->debug;
  })->join("\n");
}

sub credential_scope ($self) {
  join '/', $self->date, $self->region, $self->service, 'aws4_request';
}

sub date { shift->time->ymd('') }

sub date_timestamp { $_[0]->time->ymd('') . 'T' . $_[0]->time->hms('') . 'Z' }

sub hashed_payload ($self) {
  $self->unsigned_payload ? 'UNSIGNED-PAYLOAD' : Digest::SHA::sha256_hex($self->_tx->req->body);
}

sub header_list { [sort keys %{shift->_tx->req->headers->to_hash}] }

sub signature ($self) {
  Digest::SHA::hmac_sha256_hex($self->string_to_sign, $self->signing_key);
}

sub signed_header_list {
  join ';', map { lc($_) } @{shift->header_list};
}

sub signed_qstring ($self) {
  $self->_tx->req->url->query(['X-Amz-Signature' => $self->signature]);
}

sub signing_key ($self) {
  my $kSecret  = "AWS4" . $self->secret_key;
  my $kDate    = Digest::SHA::hmac_sha256($self->date,    $kSecret);
  my $kRegion  = Digest::SHA::hmac_sha256($self->region,  $kDate);
  my $kService = Digest::SHA::hmac_sha256($self->service, $kRegion);
  Digest::SHA::hmac_sha256("aws4_request", $kService);
}

sub string_to_sign ($self) {
  Mojo::Collection->new($self->aws_algorithm, $self->date_timestamp, $self->credential_scope,
    Digest::SHA::sha256_hex($self->canonical_request))->tap(sub {
    warn $_->map(sub {"STS:$_"})->join("\n") if $self->debug;
    })->join("\n");
}

sub time {gmtime}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::UserAgent::Role::AWSSignature4 - Add AWS Signature Version 4 to Mojo::UserAgent requests

=head1 VERSION

0.01

=head1 SYNOPSIS

  use Mojo::Base -strict;
  use Mojo::UserAgent;
  my $ua = Mojo::UserAgent->with_roles('+AWSSignature4')->new;
  my $url = 'https://my-bucket.s3.us-east-1.amazonaws.com/my-object.txt';
  $ua->put($url => awssig4 => {service => 's3'})->result;

=head1 DESCRIPTION

This role adds AWS Signature Version 4 capabilities to L<Mojo::UserAgent> HTTP requests. It signs requests using the
AWS Signature Version 4 signing process, which is required for authenticating requests to AWS services. It supports
setting various parameters such as access key, secret key, region, service, and expiration time. Additionally, it can
handle unsigned payloads and debug mode for troubleshooting.

This role is useful for developers who need to interact with AWS services using L<Mojolicious> and want to ensure
their requests are properly signed according to AWS security standards.

Note that this module can be used with any service that requires AWS Signature Version 4 signing, not just AWS services.

A C<Mojo::UserAgent::Transactor> generator named C<awssig4> is added to handle the signing process. To use it, simply
specify C<awssig4> as a generator when making requests with the user agent and specify the required configuration
options as a hash reference.

=head1 GENERATORS

These content generators are available by default.

=head2 awssig4

  $t->tx(POST => $url => awssig4 => {service => 's3'});

Generate AWS Signature Version 4 signed content. See L<ATTRIBUTES> for options. L<service> is the only required
option.

The following request headers are added, in order, during signing:

- B<Host>: Transaction request URL host, or 'localhost' if not present

- B<X-Amz-Date>: The date and time of the request, in compact ISO 8601 format with UTC timezone

- B<X-Amz-Content-Sha256>: Hashed payload of the content being sent, or C<UNSIGNED-PAYLOAD> if C<unsigned_payload> is set

- B<X-Amz-Expires>: Expiration time in seconds (if C<expires> is set)

- B<Authorization>: AWS Signature Version 4 authorization (see L<authorization> method)

=head1 ATTRIBUTES

L<Mojo::UserAgent::Role::AWSSignature4> adds the following attributes:

=head2 access_key

The AWS access key ID used for signing requests.

Defaults to C<$ENV{AWS_ACCESS_KEY}>. 

=head2 aws_algorithm

The AWS signing algorithm used.

Defaults to C<'AWS4-HMAC-SHA256'>.

=head2 content

Path to a file containing the request payload to be signed.  Will be read and used as the request body during signing.

The value is provided as the L<Mojo::Asset::File/"path"> attribute to create a L<Mojo::Asset::File> object and set
as the L<Mojo::Content::Single/"asset">.

No default value (i.e. C<undef>).

=head2 debug

Enables debug mode for signing process.

Defaults to C<0>.

=head2 expires

The expiration time for the signed request in seconds.

Defaults to C<86_400> (24 hours).

=head2 region

The AWS region for the request.

Defaults to C<'us-east-1'>.

=head2 secret_key

The AWS secret access key used for signing requests.

Defaults to C<$ENV{AWS_SECRET_KEY}>.

=head2 service

The AWS service name for the request.

Has no default value and must be provided; dies if not set.

=head2 session_token

The AWS session token for temporary credentials.

Defaults to C<$ENV{AWS_SESSION_TOKEN}>.

=head2 unsigned_payload

Indicates whether to use an unsigned payload.

Defaults to C<0>.

=head1 METHODS

L<Mojo::UserAgent::Transactor> inherits all methods from L<Mojo::Base> and implements the following new ones.

=head2 authorization

AWS Signature Version 4 authorization header value, in the format:

  AWS4-HMAC-SHA256 Credential=ACCESS_KEY/DATE/REGION/SERVICE/aws4_request, SignedHeaders=SIGNED_HEADER_LIST, Signature=SIGNATURE

=head2 canonical_headers

AWS Signature Version 4 canonical sorted headers string, in the format:

  header1:value1\nheader2:value2\n...

=head2 canonical_qstring

Adds the X-Amz-Signature parameter to the query string.

=head2 canonical_request

AWS Signature Version 4 canonical request string, in the format:

  HTTP_METHOD\nCANONICAL_URI\nCANONICAL_QUERY_STRING\nCANONICAL_HEADERS\nSIGNED_HEADER_LIST\nHASHED_PAYLOAD

Will warn debug information if C<debug> is enabled.

=head2 credential_scope

AWS Signature Version 4 credential scope string, in the format:

  DATE/REGION/SERVICE/aws4_request

=head2 date

Returns the current date in YYYYMMDD format.

=head2 date_timestamp

Returns the current date and time in YYYYMMDD'T'HHMMSS'Z' format.

=head2 hashed_payload

Returns the SHA256 hash of the request payload, or C<UNSIGNED-PAYLOAD> if C<unsigned_payload> is set.

=head2 header_list

Returns a sorted array reference of the request header names.

=head2 signature

Calculates and returns the AWS Signature Version 4 signature.

=head2 signed_header_list

Returns a semicolon-separated list of signed header names.

=head2 signed_qstring

Adds the X-Amz-Signature parameter to the query string.

=head2 signing_key

Calculates and returns the AWS Signature Version 4 signing key.

=head2 string_to_sign

AWS Signature Version 4 string to sign, in the format:

  AWS4-HMAC-SHA256\nDATE_TIMESTAMP\nCREDENTIAL_SCOPE\nHASHED_CANONICAL_REQUEST

Will warn debug information if C<debug> is enabled.

=head2 time

Returns the current time as a Time::Piece object in UTC.

=head1 SEE ALSO

L<Mojolicious::UserAgent>, L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=head1 AUTHOR

Stefan Adams <sadams@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025+ by Stefan Adams <sadams@cpan.org>. This is free software; you can redistribute
it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
