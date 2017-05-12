package Mojar::Auth::Jwt;
use Mojo::Base -base;

our $VERSION = 0.032;

use Carp 'croak';
use Crypt::OpenSSL::RSA ();
use MIME::Base64 ();
use Mojar::ClassShare 'have';
use Mojo::JSON 'encode_json', 'decode_json';

# Attributes

# JWT Header
has typ => 'JWT';
has alg => 'RS256';

# JWT Claim Set
has 'iss';
has scope => sub { q{https://www.googleapis.com/auth/analytics.readonly} };
has aud => q{https://accounts.google.com/o/oauth2/token};
has iat => sub { time };
has duration => 60*60;  # 1 hour
has exp => sub { time + $_[0]->duration };

# JWT Signature
has 'private_key';

# Mogrified chunks

sub header {
  my $self = shift;

  if (@_ == 0) {
    my @h = map +( ($_, $self->$_) ), qw(typ alg);
    return $self->{header} = $self->mogrify( { @h } );
  }
  else {
    %$self = ( %$self, @_ );
  }
  return $self;
}

sub body {
  my $self = shift;

  if (@_ == 0) {
    foreach (qw(iss scope)) {
      croak "Missing required field ($_)" unless defined $self->$_;
    }
    $self->{scope} = join ' ', @{$self->{scope}} if ref $self->{scope};
    my @c = map +( ($_, $self->$_) ), qw(iss scope aud exp iat);
    return $self->{body} = $self->mogrify( { @c } );
  }
  else {
    %$self = ( %$self, @_ );
  }
  return $self;
}

sub signature {
  my $self = shift;

  if (@_ == 0) {
    croak 'Unrecognised algorithm (not RS256)' unless $self->alg eq 'RS256';
    my $input = $self->header .q{.}. $self->body;

    return $self->{signature} = MIME::Base64::encode_base64url(
      $self->cipher->sign($input)
    );
  }
  else {
    %$self = ( %$self, @_ );
  }
  return $self;
}

has cipher => sub {
  my $self = shift;
  foreach ('private_key') {
    croak qq{Missing required field ($_)} unless defined $self->$_;
  }

  my $cipher = Crypt::OpenSSL::RSA->new_private_key($self->private_key);
  $cipher->use_pkcs1_padding;
  $cipher->use_sha256_hash;  # Requires openssl v0.9.8+
  return $cipher;
};

# Public methods

sub reset {
  my ($self) = @_;
  delete @$self{qw(iat exp body signature)};
  return;
}

sub encode {
  my $self = shift;
  if (ref $self) {
    # Encoding an existing object
    %$self = (%$self, @_) if @_;
  }
  else {
    # Class method => create object
    $self = $self->new(@_);
  }
  return join q{.}, $self->header, $self->body, $self->signature;
}

sub decode {
  my ($self, $triplet) = @_;
  my ($header, $body, $signature) = split /\./, $triplet;

  my %param = %{ $self->demogrify($header) };
  %param = ( %param, %{ $self->demogrify($body) } );
  return $self->new(%param);
}

sub verify_signature {
  my $self = shift;
  my $plaintext = $self->header .q{.}. $self->body;
  my $plainsign = MIME::Base64::decode_base64url( $self->signature );
  return $self->cipher->verify($plaintext, $plainsign);
}

sub mogrify {
  my ($self, $hashref) = @_;
  return '' unless ref $hashref && ref $hashref eq 'HASH';
  return MIME::Base64::encode_base64url(encode_json $hashref);
}

sub demogrify {
  my ($self, $safestring) = @_;
  return {} unless defined $safestring && length $safestring;
  return decode_json(MIME::Base64::decode_base64url($safestring));
}

package Mojo::JSON;
# Need json keys to be sorted => s/keys/sort keys/
no warnings 'redefine';
sub _encode_object {
  my $object = shift;
  my @pairs = map { _encode_string($_) . ':' . _encode_value($object->{$_}) }
    sort keys %$object;
  return '{' . join(',', @pairs) . '}';
};

1;
__END__

=head1 NAME

Mojar::Auth::Jwt - JWT authentication for Google services

=head1 SYNOPSIS

  use Mojar::Auth::Jwt;
  $jwt = Mojar::Auth::Jwt->new(
    iss => $auth_user,
    private_key => $private_key
  );
  $tx = $ua->post_form($jwt->aud, 'UTF-8', {
    grant_type => $grant_type,
    assertion => $jwt->encode
  });
  $token = $_->json->{access_token}
    if $_ = $tx->success;

=head1 DESCRIPTION

This class implements JSON Web Token (JWT) authentication (v3) for accessing
L<googleapis.com> from a service application.  If your application impersonates
users (to access/manipulate their data) then you need something else instead.

=head1 ATTRIBUTES

=over 4

=item typ

Type; only supported (tested) value is C<JWT>.

=item alg

Algorithm; only supported (tested) value is C<RS256>.

=item iss

JWT username.  For example, Google Analytics reporting users have
C<...@developer.gserviceaccount.com>.

=item scope

C<https://www.googleapis.com/auth/analytics.readonly>.

=item aud

C<https://accounts.google.com/o/oauth2/token>.

=item iat

Start of validity (epoch seconds).  Defaults to now.

=item duration

Length of validity period.  Defaults to an hour.

=item exp

Expiry time (epoch seconds).  Defaults to now + duration.

=item private_key

Private key.

=item header

JWT header.

=item body

JWT content.

=item signature

Signed encapsulation of header + body

=item cipher

Cipher object, built from Crypt::OpenSSL::RSA.  Before accessing, ensure
C<private_key> has been set.

=back

=head1 METHODS

=over 4

=item new

Constructor; typically only C<iss> and C<private_key> are needed.

=item reset

Clear out stale fields.

=item encode

Encode header and body and sign with a signature.  Either ensure header and body
are already set or pass them as parameters.

  $jwt->header(...)
      ->body(...);
  $encoded = $jwt->encode;

or

  $encoded = $jwt->encode(header => q{...}, body => q{...});

=item decode

Create a new JWT object by deconstructing encoded strings.

  $new_jwt = $jwt->decode($encoded_string);

=item verify_signature

Verify existing signature is valid with respect to header and body.  (Mainly
used in unit tests.)

=item mogrify

Encode a hashref.

  $encoded_string = $jwt->mogrify($hashref);

=item demogrify

Decode a hashref.

  $hashref = $jwt->demogrify($encoded_string);

=back

=head1 CONFIGURATION AND ENVIRONMENT

You need to create a low-privilege user within your GA account, granting them
access to an appropriate profile.  Then register your application for unattended
access.  That results in a username and private key that your application uses
for access.

=head1 RATIONALE

As far as I know this class has only been used for accessing Google Analytics
services so far.  I am expecting it to be useful for other services that use
JWT.

=head1 SUPPORT

See L<Mojar>.

=head1 SEE ALSO

L<Acme::JWT> is less Google-centric.
