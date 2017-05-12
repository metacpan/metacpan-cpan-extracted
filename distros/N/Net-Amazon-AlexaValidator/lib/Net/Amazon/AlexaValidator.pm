package Net::Amazon::AlexaValidator;

our $VERSION = "0.01";
$VERSION = eval $VERSION;

use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::VerifyX509;
use Crypt::OpenSSL::X509;
use DateTime::Format::ISO8601;
use DateTime::Format::x509;
use Digest::MD5 qw(md5_hex);
use Digest::SHA1 qw(sha1);
use Encode;
use JSON;
use LWP::Simple;
use MIME::Base64 qw(decode_base64);
use Moo;
use Try::Tiny;
use Types::Standard -types;
use URI;
use URI::Normalize qw( normalize_uri );

# ABSTRACT: Implements all security-related checks required for Amazon Alexa Skills

=head1 NAME

Net::Amazon::AlexaValidator - implements all security-related checks required for
Amazon Alexa Skills.

=head1 SYNOPSIS

  my $alexa_validator = Net::Amazon::AlexaValidator->new({
    application_id => 'my_application_id_from_amazon_dev_site',
    echo_domain    => 'DNS:echo-api.amazon.com',
    cert_dir       => '/tmp/',
    });
  my $request = $c->req; # Requires a L<Catalyst::Request> object
  my $ret = $alexa_validator->validate_request($request);

=head1 DESCRIPTION

Highlights of the validation include:

=over

=item *

Verifies the Signature Certificate URL. Amazon's requirements are listed here: L<https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/developing-an-alexa-skill-as-a-web-service#h2_verify_sig_cert>

=item * 

Downloads the PEM-encoded X.509 certificate chain that Alexa used to sign the message as specified by the SignatureCertChainUrl header value on the request.

=item *

Validates that the signing certificate has not expired (examine both the Not Before and Not After dates).

=item *

Validates that the domain echo-api.amazon.com is present in the Subject Alternative Names (SANs) section of the signing certificate.

=item *

Validates that all certificates in the chain combine to create a chain of trust to a trusted root CA certificate.

=item *

Base64-decodes the Signature header value on the request to obtain the encrypted signature.

=item *

Uses the public key extracted from the signing certificate to decrypt the encrypted signature to produce the asserted hash value. Generates a SHA-1 hash value from the full HTTPS request body to produce the derived hash value, and compares the asserted hash value and derived hash values to ensure that they match.

=item *

Checks the request timestamp to ensure that the request is not an old request being sent as part of a "replay" attack.

=over

=back

=back

=head1 Configuration options

=over

=back

=head2 echo_domain

The echo domain that must be present in the Subject Alternative Names (SANs) section of the signing certificate

=cut

has 'echo_domain' => (
  is      => 'rw',
  isa     => Str,
  );

=head2 application_id

Application ID from your app's Amazon Alexa App settings

=cut

has 'application_id' => (
  is      => 'rw',
  isa     => Maybe[Str],
  );


=head2 cert_dir

Directory in which to store your Alexa certificate, once validated

=cut

has 'cert_dir' => (
  is      => 'rw',
  isa     => Maybe[Str],
  );

=head1 Subroutines

=over

=back

=head2 validate_request

Verifies this is a valid Amazon Alexa request. Checks things like application_id, certificates, timestamp.

returns { success, error_msg }

=cut

sub validate_request {
  my ($self, $request) = @_;


  my $raw_request;

  my $body_fh = $request->body;
  # Read in the raw request exactly as Amazon sent it (Catalyst will sometimes reorder the request fields)
  # request->body is an IO::Handle that can be read exactly like any filehandle. Grab all the data from that file.
  unless(seek $body_fh, 0, 0) {
    return { success => 0, error_msg => "Could not read catalyst request FH. Seek failed: $!" };
  }
  $raw_request = do { local $/; <$body_fh> }; # slurp the raw request

  # Validate application ID: must match the one we specified in the Alexa App settings
  my $alexa_msg = $request->body_data;
  unless($alexa_msg->{session}->{application}->{applicationId} eq $self->application_id) {
    return { success => 0, error_msg => "Invalid Application ID" };
  }

  # Validate timestamp: must be in the last 150 seconds.
  my $ts = $alexa_msg->{request}->{timestamp};
  my $msg_time = DateTime::Format::ISO8601->parse_datetime($ts);
  my $diff = DateTime->now() - $msg_time;
  unless($diff->seconds < 150) {
    return { success => 0, error_msg => "Invalid Amazon Alexa timestamp: $ts" };
  }

  # It's possible we've already downloaded and validated Amazon's request signature. If that's the case, we'll have
  # a file with the same md5-hashed name.
  my $cert_chain_url = $request->headers->header('signaturecertchainurl');
  my $primary_cert_filename = $self->cert_dir . md5_hex($cert_chain_url) . "_primary.pem";
  my $secondary_cert_filename = $self->cert_dir . md5_hex($cert_chain_url) . "_secondary.pem";

  my $decoded_cert;
  if (-f $primary_cert_filename && -f $secondary_cert_filename) {
    # If the file already exists, we've validated it during a previous Alexa interaction. Unless the $cert_chain_url
    # has changed (in which case, the file name changes), we can go ahead and consider it validated.
    # Primary certificate is already validated...just read it from file.
    $decoded_cert = Crypt::OpenSSL::X509->new_from_file( $primary_cert_filename );
  }
  else {
    # Validate the URI of the certificate chain
    my $keychain_invalid = $self->_invalid_keychain_uri($cert_chain_url);
    if($keychain_invalid) {
      return { success => 0, error_msg => sprintf("Invalid Amazon Alexa keychain URI (%s): %s", $cert_chain_url, $keychain_invalid) };
    }
    # URI of the certificate appears valid, so go ahead and download it
    my $cert = get($cert_chain_url);

    # $cert actually contains TWO certificates. Use the first one.
    my @two_certs = split(/(-----BEGIN CERTIFICATE-----)/, $cert);

    unless((scalar @two_certs) > 2) {
      return { success => 0, error_msg => "Invalid Amazon Certificate file" };
    }

    # Split the certificate up into two parts and save both to file.
    my $primary_cert   = $two_certs[1] . $two_certs[2]; # grab and use the primary certificate
    my $secondary_cert = $two_certs[3] . $two_certs[4]; # grab the secondary certificate
    open(my $primary_cert_fh, '>', $primary_cert_filename ) or
      return { success => 0, error_msg => "Could not open file $primary_cert_filename" };
    print $primary_cert_fh $primary_cert;
    close $primary_cert_fh;
    open(my $secondary_cert_fh, '>', $secondary_cert_filename ) or
      return { success => 0, error_msg => "Could not open file $secondary_cert_filename" };
    print $secondary_cert_fh $secondary_cert;
    close $secondary_cert_fh;

    $decoded_cert = Crypt::OpenSSL::X509->new_from_string( $primary_cert );

    # Ensure that the echo domain is present in the Subject Alternative Names (SANs) section of the signing certificate
    my $exts = $decoded_cert->extensions_by_name();
    my $san_ext = $exts->{subjectAltName};
    unless ($san_ext->to_string() eq $self->echo_domain) {
      unlink $primary_cert_filename;
      unlink $secondary_cert_filename;
      return { success => 0, error_msg => sprintf("Amazon Alexa certificate failed SANs validation: %s", $san_ext) };
    }

    # Ensure that all certificates in the chain combine to create a chain of trust to a trusted root CA certificate
    # Compare the asserted hash value and derived hash values to ensure that they match.
    my $openssl_verify = "openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt -untrusted $secondary_cert_filename $primary_cert_filename";
    my $valid;

    open my $check, "-|", $openssl_verify or ( log_error({user => 'ssiegal', message => "Cannot run OpenSSL"}) && return 0 );
    if (do { local $/; <$check> } =~ /\bOK\b/) {
      $valid = 1;
    }
    close $check or ( log_error({user => 'ssiegal', message => "Cannot run OpenSSL"}) && return 0 );

    unless($valid) {
      unlink $primary_cert_filename;
      unlink $secondary_cert_filename;
      return { success => 0, error_msg => "Amazon Alexa cert failed openssl verification" };
    }
  }

  # At this point we should have a decoded certificate.
  unless($decoded_cert) {
    unlink $primary_cert_filename;
    unlink $secondary_cert_filename;
    return { success => 0, error_msg => "Could not read primary certificate from file $primary_cert_filename" };
  }

  # Ensure that the signing certificate has not expired (examine both the Not Before and Not After dates)
  my $not_before = DateTime::Format::x509->parse_datetime($decoded_cert->notBefore);
  my $not_after  = DateTime::Format::x509->parse_datetime($decoded_cert->notAfter);
  my $now = DateTime->now();
  unless($now >= $not_before && $now <= $not_after) {
    unlink $primary_cert_filename;
    unlink $secondary_cert_filename;
    return { success => 0, error_msg => sprintf("Amazon Alexa certificate failed before/after timestamp validation (%s/%s)", $not_before, $not_after) };
  }

  # Once you have determined that the signing certificate is valid, extract the public key from it.
  my $pub_key = Crypt::OpenSSL::RSA->new_public_key($decoded_cert->pubkey());

  # Base64-decode the Signature header value on the request to obtain the encrypted signature.
  my $signature = decode_base64($request->headers->header('signature'));

  my $valid;
  try {
    $valid = $pub_key->verify($raw_request, $signature);
  } catch {
    return { success => 0, error_msg => "Amazon Alexa certificate failed public key validation: $_" };
  };

  unless($valid) {
    unlink $primary_cert_filename;
    unlink $secondary_cert_filename;
    return { success => 0, error_msg => "Amazon Alexa cert failed public key verification" };
  }

  # If we're here, we've passed all the checks. FULL SPEED AHEAD!
  return { success => 1, error_msg => "" };
}

# Validate keychain uri from Amazon is proper. undef indicates no errors found.
# Example URI: https://s3.amazonaws.com/echo.api/echo-api-cert-3.pem
sub _invalid_keychain_uri {
  my ($self, $keychain_uri) = @_;

  # Normalize the URI first
  my $uri = normalize_uri( $keychain_uri );

  my $error_msg = undef;

  unless(lc($uri->host) eq 's3.amazonaws.com') {
    $error_msg = 'The host for the Certificate provided in the header is invalid';
  }

  unless($uri->path =~ m{^/echo.api/}) {
    $error_msg = 'The URL path for the Certificate provided in the header is invalid';
  }

  unless(lc($uri->scheme) eq 'https') {
    $error_msg = 'The URL is using an unsupported scheme. Should be https';
  }

  if ($uri->port && $uri->port != 443) {
    $error_msg = 'The URL is using an unsupported https port';
  }

  return $error_msg;
}

1;
