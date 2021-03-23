use 5.008001;
use strict;
use warnings;

package Session::Storage::Secure;
# ABSTRACT: Encrypted, expiring, compressed, serialized session data with integrity

our $VERSION = '1.000';

use Carp (qw/croak/);
use Crypt::CBC 3.01 ();
use Crypt::Rijndael ();
use Crypt::URandom          (qw/urandom/);
use Digest::SHA             (qw/hmac_sha256/);
use Math::Random::ISAAC::XS ();
use MIME::Base64 3.12     ();
use Sereal::Encoder 4.005 ();
use Sereal::Decoder 4.005 ();
use String::Compare::ConstantTime qw/equals/;
use namespace::clean;

use Moo;
use MooX::Types::MooseLike::Base 0.16 qw(:all);

#--------------------------------------------------------------------------#
# Attributes
#--------------------------------------------------------------------------#

#pod =attr secret_key (required)
#pod
#pod This is used to secure the session data.  The encryption and message
#pod authentication key is derived from this using a one-way function.  Changing it
#pod will invalidate all sessions.
#pod
#pod =cut

has secret_key => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

#pod =attr default_duration
#pod
#pod Number of seconds for which the session may be considered valid.  If an
#pod expiration is not provided to C<encode>, this is used instead to expire the
#pod session after a period of time.  It is unset by default, meaning that session
#pod expiration is not capped.
#pod
#pod =cut

has default_duration => (
    is        => 'ro',
    isa       => Int,
    predicate => 1,
);

#pod =attr old_secrets
#pod
#pod An optional array reference of strings containing old secret keys no longer
#pod used for encryption but still supported for decrypting session data.
#pod
#pod =cut

has old_secrets => (
    is  => 'ro',
    isa => ArrayRef [Str],
);

#pod =attr separator
#pod
#pod A character used to separate fields.  It defaults to C<~>.
#pod
#pod =cut

has separator => (
    is      => 'ro',
    isa     => Str,
    default => '~',
);

#pod =attr sereal_encoder_options
#pod
#pod A hash reference with constructor arguments for L<Sereal::Encoder>. Defaults
#pod to C<< { snappy => 1, croak_on_bless => 1 } >>.
#pod
#pod =cut

has sereal_encoder_options => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { { snappy => 1, croak_on_bless => 1 } },
);

#pod =attr sereal_decoder_options
#pod
#pod A hash reference with constructor arguments for L<Sereal::Decoder>. Defaults
#pod to C<< { refuse_objects => 1, validate_utf8  => 1 } >>.
#pod
#pod =cut

has sereal_decoder_options => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { { refuse_objects => 1, validate_utf8 => 1 } },
);

#pod =attr transport_encoder
#pod
#pod A code reference to convert binary data elements (the encrypted data and the
#pod MAC) into a transport-safe form.  Defaults to
#pod L<MIME::Base64::encode_base64url|MIME::Base64>.  The output must not include
#pod the C<separator> attribute used to delimit fields.
#pod
#pod =cut

has transport_encoder => (
    is      => 'ro',
    isa     => CodeRef,
    default => sub { \&MIME::Base64::encode_base64url },
);

#pod =attr transport_decoder
#pod
#pod A code reference to extract binary data (the encrypted data and the
#pod MAC) from a transport-safe form.  It must be the complement to C<encode>.
#pod Defaults to L<MIME::Base64::decode_base64url|MIME::Base64>.
#pod
#pod =cut

has transport_decoder => (
    is      => 'ro',
    isa     => CodeRef,
    default => sub { \&MIME::Base64::decode_base64url },
);

#pod =attr protocol_version
#pod
#pod An integer representing the protocol used by C<Session::Storage::Secure>.
#pod Protocol 1 was the initial version, which used a now-deprecated mode of
#pod L<Crypt::CBC>.  Protocol 2 is the current default.
#pod
#pod =cut

has protocol_version => (
    is      => 'ro',
    isa     => Num,
    default => 2,
);

has _encoder => (
    is      => 'lazy',
    isa     => InstanceOf ['Sereal::Encoder'],
    handles => { '_freeze' => 'encode' },
);

sub _build__encoder {
    my ($self) = @_;
    return Sereal::Encoder->new( $self->sereal_encoder_options );
}

has _decoder => (
    is      => 'lazy',
    isa     => InstanceOf ['Sereal::Decoder'],
    handles => { '_thaw' => 'decode' },
);

sub _build__decoder {
    my ($self) = @_;
    return Sereal::Decoder->new( $self->sereal_decoder_options );
}

has _rng => (
    is      => 'lazy',
    isa     => InstanceOf ['Math::Random::ISAAC::XS'],
    handles => { '_irand' => 'irand' },
);

sub _build__rng {
    my ($self) = @_;
    return Math::Random::ISAAC::XS->new( map { unpack( "N", urandom(4) ) } 1 .. 256 );
}

sub BUILD {
    my ($self) = @_;
    $self->_check_version_for( encoding => $self->protocol_version );
}

sub _check_version_for {
    my ( $self, $action, $pv ) = @_;
    if ( $pv < 1 || $pv > 2 ) {
        croak "Invalid protocol version for $action: $pv";
    }
}

sub _get_cbc {
    my ( $self, $pv, $key, $salt ) = @_;

    my $cbc_opts = {
        -key    => $key,
        -cipher => 'Rijndael',
    };

    if ( $pv == 1 ) {
        $cbc_opts->{-pbkdf}       = 'opensslv1';
        $cbc_opts->{-nodeprecate} = 1;
    }
    else {
        $cbc_opts->{-pbkdf}       = 'none';
        $cbc_opts->{-keysize}     = 32;
        $cbc_opts->{-header}      = 'none';
        my $cipher = Crypt::Rijndael->new($key);
        $cbc_opts->{-iv} = substr( $cipher->encrypt($salt), 0, 16 );
    }

    return Crypt::CBC->new(%$cbc_opts);
}

#pod =method encode
#pod
#pod   my $string = $store->encode( $data, $expires );
#pod
#pod The C<$data> argument should be a reference to a data structure.  By default,
#pod it must not contain objects.  (See L</Objects not stored by default> for
#pod rationale and alternatives.) If it is undefined, an empty hash reference will
#pod be encoded instead.
#pod
#pod The optional C<$expires> argument should be the session expiration time
#pod expressed as epoch seconds.  If the C<$expires> time is in the past, the
#pod C<$data> argument is cleared and an empty hash reference is encoded and returned.
#pod If no C<$expires> is given, then if the C<default_duration> attribute is set, it
#pod will be used to calculate an expiration time.
#pod
#pod The method returns a string that securely encodes the session data.  All binary
#pod components are protected via the L</transport_encoder> attribute.
#pod
#pod An exception is thrown on any errors.
#pod
#pod =cut

sub encode {
    my ( $self, $data, $expires ) = @_;
    $data = {} unless defined $data;
    my $sep = $self->separator;

    # If expiration is set, we want to check it and possibly clear data;
    # if not set, we might add an expiration based on default_duration
    if ( defined $expires ) {
        $data = {} if $expires < time;
    }
    else {
        $expires = $self->has_default_duration ? time + $self->default_duration : "";
    }

    # Random salt used to derive unique encryption/MAC key for each cookie
    my $salt;
    if ( $self->protocol_version == 1 ) {
        # numeric salt
        $salt = $self->_irand;
    }
    else {
        # binary salt
        $salt = pack( "N*", map { $self->_irand } 1 .. 8 );
    }

    my $key = hmac_sha256( $salt, $self->secret_key );

    my $cbc = $self->_get_cbc( $self->protocol_version, $key, $salt );

    my ( $ciphertext, $mac );
    eval {
        $ciphertext = $self->transport_encoder->( $cbc->encrypt( $self->_freeze($data) ) );
        $mac = $self->transport_encoder->( hmac_sha256( "$expires$sep$ciphertext", $key ) );
    };
    croak "Encoding error: $@" if $@;

    my $output;
    if ( $self->protocol_version == 1 ) {
        $output = join( $sep, $salt, $expires, $ciphertext, $mac );
    }
    else {
        $salt   = $self->transport_encoder->($salt);
        $output = join( $sep, $salt, $expires, $ciphertext, $mac, $self->protocol_version );
    }
    return $output;
}

#pod =method decode
#pod
#pod   my $data = $store->decode( $string );
#pod
#pod The C<$string> argument must be the output of C<encode>.
#pod
#pod If the message integrity check fails or if expiration exists and is in
#pod the past, the method returns undef or an empty list (depending on context).
#pod
#pod An exception is thrown on any errors.
#pod
#pod =cut

sub decode {
    my ( $self, $string ) = @_;
    return unless length $string;

    # Having a string implies at least salt; expires is optional; rest required
    my $sep = $self->separator;
    my ( $salt, $expires, $ciphertext, $mac, $version ) = split qr/\Q$sep\E/, $string;
    return unless defined($ciphertext) && length($ciphertext);
    return unless defined($mac)        && length($mac);
    $version = 1 unless defined $version;
    $self->_check_version_for( decoding => $version );

    if ( $version == 1 ) {
        # $salt is a decimal
    }
    else {
        # Decode salt to binary
        $salt = $self->transport_decoder->($salt);
    }

    # Try to decode against all known secret keys
    my @secrets = ( $self->secret_key, @{ $self->old_secrets || [] } );
    my $key;
    CHECK: foreach my $secret (@secrets) {
        $key = hmac_sha256( $salt, $secret );
        my $check_mac = eval {
            $self->transport_encoder->( hmac_sha256( "$expires$sep$ciphertext", $key ) );
        };
        last CHECK
          if (
               defined($check_mac)
            && length($check_mac)
            && equals( $check_mac, $mac ) # constant time comparison
          );
        undef $key;
    }

    # Check MAC integrity
    return unless defined($key);

    # Check expiration
    return if length($expires) && $expires < time;

    # Decrypt and deserialize the data
    my $cbc = $self->_get_cbc( $version, $key, $salt );

    my $data;
    eval {
        $self->_thaw( $cbc->decrypt( $self->transport_decoder->($ciphertext) ), $data );
    };
    croak "Decoding error: $@" if $@;

    return $data;
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Session::Storage::Secure - Encrypted, expiring, compressed, serialized session data with integrity

=head1 VERSION

version 1.000

=head1 SYNOPSIS

  my $store = Session::Storage::Secure->new(
    secret_key   => "your pass phrase here",
    default_duration => 86400 * 7,
  );

  my $encoded = $store->encode( $data, $expires );

  my $decoded = $store->decode( $encoded );

=head1 DESCRIPTION

This module implements a secure way to encode session data.  It is primarily
intended for storing session data in browser cookies, but could be used with
other backend storage where security of stored session data is important.

Features include:

=over 4

=item *

Data serialization and compression using L<Sereal>

=item *

Data encryption using AES with a unique derived key per encoded session

=item *

Enforced expiration timestamp (optional)

=item *

Integrity protected with a message authentication code (MAC)

=back

The storage protocol used in this module is based heavily on
L<A Secure Cookie Protocol|http://www.cse.msu.edu/~alexliu/publications/Cookie/Cookie_COMNET.pdf>
by Alex Liu and others.  Liu proposes a session cookie value as follows:

  user|expiration|E(data,k)|HMAC(user|expiration|data|ssl-key,k)

  where

    | denotes concatenation with a separator character
    E(p,q) is a symmetric encryption of p with key q
    HMAC(p,q) is a keyed message hash of p with key q
    k is HMAC(user|expiration, sk)
    sk is a secret key shared by all servers
    ssl-key is an SSL session key

Because SSL session keys are not readily available (and SSL termination
may happen prior to the application server), we omit C<ssl-key>.  This
weakens protection against replay attacks if an attacker can break
the SSL session key and intercept messages.

Using C<user> and C<expiration> to generate the encryption and MAC keys was a
method proposed to ensure unique keys to defeat volume attacks against the
secret key.  Rather than rely on those for uniqueness (with the unfortunate
side effect of revealing user names and prohibiting anonymous sessions), we
replace C<user> with a cryptographically-strong random salt value.

The original proposal also calculates a MAC based on unencrypted data.  We
instead calculate the MAC based on the encrypted data.  This avoids an extra
step decrypting invalid messages.  Because the salt is already encoded into the
key, we omit it from the MAC input.

Therefore, the session storage protocol used by this module is as follows:

  salt|expiration|E(data,k)|HMAC(expiration|E(data,k),k)

  where

    | denotes concatenation with a separator character
    E(p,q) is a symmetric encryption of p with key q
    HMAC(p,q) is a keyed message hash of p with key q
    k is HMAC(salt, sk)
    sk is a secret key shared by all servers

The salt value is generated using L<Math::Random::ISAAC::XS>, seeded from
L<Crypt::URandom>.

The HMAC algorithm is C<hmac_sha256> from L<Digest::SHA>.  Encryption
is done by L<Crypt::CBC> using L<Crypt::Rijndael> (AES).  The ciphertext and
MAC's in the cookie are Base64 encoded by L<MIME::Base64> by default.

During session retrieval, if the MAC does not authenticate or if the expiration
is set and in the past, the session will be discarded.

=head1 ATTRIBUTES

=head2 secret_key (required)

This is used to secure the session data.  The encryption and message
authentication key is derived from this using a one-way function.  Changing it
will invalidate all sessions.

=head2 default_duration

Number of seconds for which the session may be considered valid.  If an
expiration is not provided to C<encode>, this is used instead to expire the
session after a period of time.  It is unset by default, meaning that session
expiration is not capped.

=head2 old_secrets

An optional array reference of strings containing old secret keys no longer
used for encryption but still supported for decrypting session data.

=head2 separator

A character used to separate fields.  It defaults to C<~>.

=head2 sereal_encoder_options

A hash reference with constructor arguments for L<Sereal::Encoder>. Defaults
to C<< { snappy => 1, croak_on_bless => 1 } >>.

=head2 sereal_decoder_options

A hash reference with constructor arguments for L<Sereal::Decoder>. Defaults
to C<< { refuse_objects => 1, validate_utf8  => 1 } >>.

=head2 transport_encoder

A code reference to convert binary data elements (the encrypted data and the
MAC) into a transport-safe form.  Defaults to
L<MIME::Base64::encode_base64url|MIME::Base64>.  The output must not include
the C<separator> attribute used to delimit fields.

=head2 transport_decoder

A code reference to extract binary data (the encrypted data and the
MAC) from a transport-safe form.  It must be the complement to C<encode>.
Defaults to L<MIME::Base64::decode_base64url|MIME::Base64>.

=head2 protocol_version

An integer representing the protocol used by C<Session::Storage::Secure>.
Protocol 1 was the initial version, which used a now-deprecated mode of
L<Crypt::CBC>.  Protocol 2 is the current default.

=head1 METHODS

=head2 encode

  my $string = $store->encode( $data, $expires );

The C<$data> argument should be a reference to a data structure.  By default,
it must not contain objects.  (See L</Objects not stored by default> for
rationale and alternatives.) If it is undefined, an empty hash reference will
be encoded instead.

The optional C<$expires> argument should be the session expiration time
expressed as epoch seconds.  If the C<$expires> time is in the past, the
C<$data> argument is cleared and an empty hash reference is encoded and returned.
If no C<$expires> is given, then if the C<default_duration> attribute is set, it
will be used to calculate an expiration time.

The method returns a string that securely encodes the session data.  All binary
components are protected via the L</transport_encoder> attribute.

An exception is thrown on any errors.

=head2 decode

  my $data = $store->decode( $string );

The C<$string> argument must be the output of C<encode>.

If the message integrity check fails or if expiration exists and is in
the past, the method returns undef or an empty list (depending on context).

An exception is thrown on any errors.

=for Pod::Coverage has_default_duration BUILD

=head1 LIMITATIONS

=head2 Secret key

You must protect the secret key, of course.  Rekeying periodically would
improve security.  Rekeying also invalidates all existing sessions unless the
C<old_secrets> attribute contains old encryption keys still used for
decryption.  In a multi-node application, all nodes must share the same secret
key.

=head2 Session size

If storing the encoded session in a cookie, keep in mind that cookies must fit
within 4k, so don't store too much data.  This module uses L<Sereal> for
serialization and enables the C<snappy> compression option.  Sereal plus Snappy
appears to be one of the fastest and most compact serialization options for
Perl, according to the
L<Sereal benchmarks|https://github.com/Sereal/Sereal/wiki/Sereal-Comparison-Graphs>
page.

However, nothing prevents the encoded output from exceeding 4k.  Applications
must check for this condition and handle it appropriately with an error or
by splitting the value across multiple cookies.

=head2 Objects not stored by default

The default Sereal options do not allow storing objects because object
deserialization can have undesirable side effects, including potentially fatal
errors if a class is not available at deserialization time or if internal class
structures changed from when the session data was serialized to when it was
deserialized.  Applications should take steps to deflate/inflate objects before
storing them in session data.

Alternatively, applications can change L</sereal_encoder_options> and
L</sereal_decoder_options> to allow object serialization or other object
transformations and accept the risks of doing so.

=head1 SECURITY

Storing encrypted session data within a browser cookie avoids latency and
overhead of backend session storage, but has several additional security
considerations.

=head2 Transport security

If using cookies to store session data, an attacker could intercept cookies and
replay them to impersonate a valid user regardless of encryption.  SSL
encryption of the transport channel is strongly recommended.

=head2 Cookie replay

Because all session state is maintained in the session cookie, an attacker
or malicious user could replay an old cookie to return to a previous state.
Cookie-based sessions should not be used for recording incremental steps
in a transaction or to record "negative rights".

Because cookie expiration happens on the client-side, an attacker or malicious
user could replay a cookie after its scheduled expiration date.  It is strongly
recommended to set C<cookie_duration> or C<default_duration> to limit the window of
opportunity for such replay attacks.

=head2 Session authentication

A compromised secret key could be used to construct valid messages appearing to
be from any user.  Applications should take extra steps in their use of session
data to ensure that sessions are authenticated to the user.

One simple approach could be to store a hash of the user's hashed password
in the session on login and to verify it on each request.

  # on login
  my $hashed_pw = bcrypt( $password, $salt );
  if ( $hashed_pw eq $hashed_pw_from_db ) {
    session user => $user;
    session auth => bcrypt( $hashed_pw, $salt ) );
  }

  # on each request
  if ( bcrypt( $hashed_pw_from_db, $salt ) ne session("auth") ) {
    context->destroy_session;
  }

The downside of this is that if there is a read-only attack against the
database (SQL injection or leaked backup dump) and the secret key is compromised,
then an attacker can forge a cookie to impersonate any user.

A more secure approach suggested by Stephen Murdoch in
L<Hardened Stateless Session Cookies|http://www.cl.cam.ac.uk/~sjm217/papers/protocols08cookies.pdf>
is to store an iterated hash of the hashed password in the
database and use the hashed password itself within the session.

  # on login
  my $hashed_pw = bcrypt( $password, $salt );
  if ( bcrypt( $hashed_pw, $salt ) eq $double_hashed_pw_from_db ) {
    session user => $user;
    session auth => $hashed_pw;
  }

  # on each request
  if ( $double_hashed_pw_from_db ne bcrypt( session("auth"), $salt ) ) {
    context->destroy_session;
  }

This latter approach means that even a compromise of the secret key and the
database contents can't be used to impersonate a user because doing so would
requiring reversing a one-way hash to determine the correct authenticator to
put into the forged cookie.

Both methods require an additional database read per request. This diminishes
some of the scalability benefits of storing session data in a cookie, but
the read could be cached and there is still no database write needed
to store session data.

=head1 SEE ALSO

Papers on secure cookies and cookie session storage:

=over 4

=item *

Liu, Alex X., et al., L<A Secure Cookie Protocol|http://www.cse.msu.edu/~alexliu/publications/Cookie/Cookie_COMNET.pdf>

=item *

Murdoch, Stephen J., L<Hardened Stateless Session Cookies|http://www.cl.cam.ac.uk/~sjm217/papers/protocols08cookies.pdf>

=item *

Fu, Kevin, et al., L<Dos and Don'ts of Client Authentication on the Web|http://pdos.csail.mit.edu/papers/webauth:sec10.pdf>

=back

CPAN modules implementing cookie session storage:

=over 4

=item *

L<Catalyst::Plugin::CookiedSession> -- encryption only

=item *

L<Dancer::Session::Cookie> -- Dancer 1, encryption only

=item *

L<Dancer::SessionFactory::Cookie> -- Dancer 2, forthcoming, based on this module

=item *

L<HTTP::CryptoCookie> -- encryption only

=item *

L<Mojolicious::Sessions> -- MAC only

=item *

L<Plack::Middleware::Session::Cookie> -- MAC only

=item *

L<Plack::Middleware::Session::SerializedCookie> -- really just a framework and you provide the guts with callbacks

=back

Related CPAN modules that offer frameworks for serializing and encrypting data,
but without features relevant for sessions like expiration and unique keying.

=over 4

=item *

L<Crypt::Util>

=item *

L<Data::Serializer>

=back

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Petr Písař Tom Hukins

=over 4

=item *

Petr Písař <ppisar@redhat.com>

=item *

Tom Hukins <tom@eborcom.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
