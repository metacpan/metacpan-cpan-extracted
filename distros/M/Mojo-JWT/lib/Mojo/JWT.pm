package Mojo::JWT;

use Mojo::Base -base;

our $VERSION = '1.01';
$VERSION = eval $VERSION;

use Scalar::Util ();
use List::Util ();
use Mojo::JSON ();

use CryptX;
use Crypt::Misc ();

use Carp ();

my $isa = sub { Scalar::Util::blessed $_[0] && $_[0]->isa($_[1]) };

has header => sub { {} };
has algorithm => 'HS256';
has [qw/allow_none set_iat/] => 0;
has claims => sub { {} };
has jwks => sub { [] };
has [qw/expires not_before/];
has [qw/public secret/] => '';

my $re_hs = qr/^HS(\d+)$/;
my $re_rs = qr/^RS(\d+)$/;

sub add_jwkset {
  my ($self, $jwkset) = @_;
  if (ref $jwkset eq 'HASH') {
    push @{ $self->jwks }, @{ $jwkset->{keys} };
  }
  if (ref $jwkset eq 'ARRAY') {
    push @{ $self->jwks }, @{ $jwkset };
  }
  return $self;
}

sub decode {
  my ($self, $token, $peek) = @_;
  $self->{token} = $token;

  # reset
  $self->algorithm(undef);
  delete $self->{$_} for qw/claims expires not_before header/;

  my ($hstring, $cstring, $signature) = split /\./, $token;
  my $header = Mojo::JSON::decode_json Crypt::Misc::decode_b64u($hstring);
  my $claims = Mojo::JSON::decode_json Crypt::Misc::decode_b64u($cstring);
  $signature = Crypt::Misc::decode_b64u $signature;

  # typ header is only recommended and is ignored
  # https://tools.ietf.org/html/rfc7519#section-5.1
  delete $header->{typ};
  Carp::croak 'Required header field "alg" not specified'
    unless my $algo = $self->algorithm(delete $header->{alg})->algorithm;
  $self->header($header);

  $self->_try_jwks($algo, $header);

  $self->$peek($claims) if $peek;

  # check signature
  my $payload = "$hstring.$cstring";
  if ($algo eq 'none') {
    Carp::croak 'Algorithm "none" is prohibited'
      unless $self->allow_none;
  } elsif ($algo =~ $re_rs) {
    Carp::croak 'Failed RS validation'
      unless $self->verify_rsa($1, $payload, $signature);
  } elsif ($algo =~ $re_hs) {
    Carp::croak 'Failed HS validation'
      unless $signature eq $self->sign_hmac($1, $payload);
  } else {
    Carp::croak 'Unsupported signing algorithm';
  }

  # check timing
  my $now = $self->now;
  if (defined(my $exp = $claims->{exp})) {
    Carp::croak 'JWT has expired' if $now > $exp;
    $self->expires($exp);
  }
  if (defined(my $nbf = $claims->{nbf})) {
    Carp::croak 'JWT is not yet valid' if $now < $nbf;
    $self->not_before($nbf);
  }

  return $self->claims($claims)->claims;
}

sub _try_jwks {
  my ($self, $algo, $header) = @_;
  return unless @{$self->jwks} && $header->{kid};

  # Check we have the JWK for this JWT
  my $jwk = List::Util::first { exists $header->{kid} && $_->{kid} eq $header->{kid} } @{$self->jwks};
  return unless $jwk;

  if ($algo =~ $re_rs) {
    require Crypt::PK::RSA;
    my $pubkey = Crypt::PK::RSA->new($jwk);
    $self->public($pubkey);
  } elsif ($algo =~ $re_hs) {
    $self->secret( Crypt::Misc::decode_b64u $jwk->{k} )
  }
}

sub encode {
  my $self = shift;
  delete $self->{token};

  my $claims = $self->claims;
  if ($self->set_iat) { $claims->{iat} = $self->now }
  if (defined(my $exp = $self->expires))    { $claims->{exp} = $exp }
  if (defined(my $nbf = $self->not_before)) { $claims->{nbf} = $nbf }

  my $header  = { %{ $self->header }, typ => 'JWT', alg => $self->algorithm };
  my $hstring = Crypt::Misc::encode_b64u Mojo::JSON::encode_json($header);
  my $cstring = Crypt::Misc::encode_b64u Mojo::JSON::encode_json($claims);
  my $payload = "$hstring.$cstring";
  my $signature;
  my $algo = $self->algorithm;
  if ($algo eq 'none') {
    $signature = '';
  } elsif ($algo =~ $re_rs) {
    $signature = $self->sign_rsa($1, $payload);
  } elsif ($algo =~ $re_hs) {
    $signature = $self->sign_hmac($1, $payload);
  } else {
    Carp::croak 'Unknown algorithm';
  }

  return $self->{token} = "$payload." . Crypt::Misc::encode_b64u $signature;
}

sub now { time }

sub sign_hmac {
  my ($self, $size, $payload) = @_;
  Carp::croak 'symmetric secret not specified' unless my $secret = $self->secret;
  Carp::croak 'Unsupported HS signing algorithm' unless $size == 256 || $size == 384 || $size == 512;
  require Crypt::Mac::HMAC;
  return Crypt::Mac::HMAC::hmac("SHA$size", $secret, $payload);
}

sub sign_rsa {
  my ($self, $size, $payload) = @_;
  Carp::croak 'Unsupported RS signing algorithm' unless $size == 256 || $size == 384 || $size == 512;
  Carp::croak 'secret key not specified' unless my $secret = $self->secret;
  my $crypt = _inflate_rsa_key($secret);
  return $crypt->sign_message($payload, "SHA$size", 'v1.5');
}

sub token { shift->{token} }

sub verify_rsa {
  my ($self, $size, $payload, $signature) = @_;
  Carp::croak 'Unsupported RS verification algorithm' unless $size == 256 || $size == 384 || $size == 512;
  Carp::croak 'public key not specified' unless my $public = $self->public;
  my $crypt = _inflate_rsa_key($public);
  return $crypt->verify_message($signature, $payload, "SHA$size", 'v1.5');
}

sub _inflate_rsa_key {
  my ($key) = @_;
  require Crypt::PK::RSA;
  return $key if $key->$isa('Crypt::PK::RSA');
  if ($key->$isa('Crypt::OpenSSL::RSA')) {
    $key = $key->is_private ? $key->get_private_key_string : $key->get_public_key_string;
  }
  return Crypt::PK::RSA->new(\$key);
}

1;

=head1 NAME

Mojo::JWT - JSON Web Token the Mojo way

=head1 SYNOPSIS

  my $jwt = Mojo::JWT->new(claims => {...}, secret => 's3cr3t')->encode;
  my $claims = Mojo::JWT->new(secret => 's3cr3t')->decode($jwt);

=head1 DESCRIPTION

JSON Web Token is described in L<https://tools.ietf.org/html/rfc7519>.
L<Mojo::JWT> implements that standard with an API that should feel familiar to L<Mojolicious> users (though of course it is useful elsewhere).
Indeed, JWT is much like L<Mojolicious::Sessions> except that the result is a url-safe text string rather than a cookie.

In JWT, the primary payload is called the C<claims>, and a few claims are reserved, as seen in the IETF document.
The header and the claims are signed when stringified to guard against tampering.
Note that while signed, the data is not encrypted, so don't use it to send secrets over clear channels.

=head1 ATTRIBUTES

L<Mojo::JWT> inherits all of the attributes from L<Mojo::Base> and implements the following new ones.

=head2 algorithm

The algorithm to be used to sign a JWT during encoding or else the algorithm that was used for the most recent decoding.
Defaults to C<HS256> until a decode is performed.

C<none> is an acceptable encoding algorithm, however for it to be used to decode, L</allow_none> must be set.

=head2 allow_none

To prevent spoofing attacks, C<allow_none> must be explicitly set to a true value otherwise decoding a JWT which specifies the C<none> algorithm will result in an exception.
The default is of course false.

=head2 claims

The payload to be encoded or else the claims from the most recent decoding.
This must be a hash reference, array references are not allowed as the top-level JWT claims.

=head2 expires

The epoch time value after which the JWT value should not be considered valid.
This value (if set and not undefined) will be used as the C<exp> key in the claims or was extracted from the claims during the most recent decoding.

=head2 header

You may set your own headers when encoding the JWT bypassing a hash reference to the L</header> attribute. Please note that there are two default headers set. B<alg> is set to the value of L</algorithm> or 'HS256' and B<typ> is set to 'JWT'. These cannot be overridden.

=head2 not_before

The epoch time value before which the JWT value should not be considered valid.
This value (if set and not undefined) will be used as the C<nbf> key in the claims or was extracted from the claims during the most recent decoding.

=head2 public

The public key to be used in decoding an asymmetrically signed JWT (eg. RSA).
This can be any public key in a string format accepted by L<Crypt::PK::RSA> or a L<Crypt::PK::RSA> object (if used a L<Crypt::OpenSSL::RSA> object will be converted).

=head2 secret

The symmetric secret (eg. HMAC) or else the private key used in encoding an asymmetrically signed JWT (eg. RSA).
Symmetric secrets should be a string.
A private key can be in a string format accepted by L<Crypt::PK::RSA> or a L<Crypt::PK::RSA> object (if used a L<Crypt::OpenSSL::RSA> object will be converted).

=head2 set_iat

If true (false by default), then the C<iat> claim will be set to the value of L</now> during L</encode>.

=head2 jwks

An arrayref of JWK objects used by C<decode> to verify the input token when matching with the JWTs C<kid> field.

    my $jwks = Mojo::UserAgent->new->get('https://example.com/oidc/jwks.json')->result->json('/keys');
    my $jwt = Mojo::JWT->new(jwks => $jwks);
    $jwk->decode($token);

=head1 METHODS

L<Mojo::JWT> inherits all of the methods from L<Mojo::Base> and implements the following new ones.

=head2 add_jwkset

    my $jwkset = Mojo::UserAgent->new->get('https://example.com/oidc/jwks.json')->result->json;
    my $jwt = Mojo::JWT->new->add_jwkset($jwksset);
    $jwk->decode($token);

Helper for appending a jwkset to the L</jwks>.
Accepts a hashref with a C<keys> field that is an arrayref of jwks and also an arrayref directly.
Appends the JWKs to L</jwks>.
Returns the instance.

=head2 decode

  my $claims = $jwt->decode($token);

  my $peek = sub { my ($jwt, $claims) = @_; ... };
  my $claims = $jwt->decode($token, $peek);

Decode and parse a JSON Web Token string and return the claims hashref.
Calling this function immediately sets the L</token> to the passed in token.
It also sets L</algorithm> to C<undef> and unsets L</claims>, L</expires> and L</not_before>.
These values are then set as part of the parsing process.

Parsing occurs as follows

=over

=item *

The L</algorithm> is extracted from the header and set, if not present or permissible an exception is thrown

=item *

Any JWKs in C</jwks> are checked against the headers and if one is found then it is set in L</public> or L</secret> as appropriate to the L</algorithm>

=item *

If a C<$peek> callback is provided, it is called with the instance and claims as arguments

=item *

The signature is verified or an exception is thrown

=item *

The timing claims (L</expires> and L</not_before>), if present, are evaluated, failures result in exceptions. On success the values are set in the relevant attributes

=item *

The L</claims> attribute is set and the claims are returned.

=back

Note that when the C<$peek> callback is invoked, the claims have not yet been verified.
This callback is most likely to be used to inspect the C<iss> or issuer claim to determine a secret or key for decoding.
The return value is ignored, changes should be made to the instances attributes directly.
Since the L</algorithm> has already been parsed, it is available via the instance attribute as well.

=head2 encode

  my $token = $jwt->encode;

Encode the data expressed in the instance attributes: L</algorithm>, L</claims>, L</expires>, L</not_before>.
Note that if the timing attributes are given, they override existing keys in the L</claims>.
Calling C<encode> immediately clears the L</token> and upon completion sets it to the result as well as returning it.

Note also that due to Perl's hash randomization, repeated encoding is not guaranteed to result in the same encoded string.
However any encoded string will survive an encode/decode roundtrip.

=head2 header

  my $header = $jwt->header;

Returns a hash reference representing the JWT header, constructed from instance attributes (see L</algorithm>).

=head2 now

  my $time = $jwt->now;

Returns the current time, currently implemented as the core C<time> function.

=head2 sign_hmac

  my $signature = $jwt->sign_hmac($size, $payload);

Returns the HMAC SHA signature for the given size and payload.
The L</secret> attribute is used as the symmetric key.
The result is not yet base64 encoded.
This method is provided mostly for the purposes of subclassing.

=head2 sign_rsa

  my $signature = $jwt->sign_rsa($size, $payload);

Returns the RSA signature for the given size and payload.
The L</secret> attribute is used as the private key.
The result is not yet base64 encoded.
This method is provided mostly for the purposes of subclassing.

=head2 token

The most recently encoded or decoded token.
Note that any attribute modifications are not taken into account until L</encode> is called again.

=head2 verify_rsa

  my $bool = $jwt->verify_rsa($size, $payload, $signature);

Returns true if the given RSA size algorithm validates the given payload and signature.
The L</public> attribute is used as the public key.
This method is provided mostly for the purposes of subclassing.

=head1 SEE ALSO

=over

=item L<Acme::JWT>

=item L<JSON::WebToken>

=item L<http://jwt.io/>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojo-JWT>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 CONTRIBUTORS

Christopher Raa (mishanti1)

Cameron Daniel (ccakes)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by L</AUTHOR> and L</CONTRIBTORS>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

