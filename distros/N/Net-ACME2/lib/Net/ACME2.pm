package Net::ACME2;

use strict;
use warnings;

our $VERSION;
BEGIN {
    $VERSION = '0.41';
}

=encoding utf-8

=for markdown [![testsuite](https://github.com/cpan-authors/Net-ACME2/actions/workflows/testsuite.yml/badge.svg)](https://github.com/cpan-authors/Net-ACME2/actions/workflows/testsuite.yml)

=head1 NAME

Net::ACME2 - Client logic for the ACME (Let's Encrypt) protocol

X<Lets Encrypt> X<Let's Encrypt> X<letsencrypt>

=head1 SYNOPSIS

    package SomeCA::ACME;

    use parent qw( Net::ACME2 );

    use constant {
        DIRECTORY_PATH => '/acme-directory',
    };

    # %opts are the parameters given to new().
    sub HOST {
        my ($class, %opts) = @_;

        # You can make this depend on the %opts if you want.
        return 'acme.someca.net';
    }

    package main;

    my $acme = SomeCA::ACME->new(
        key => $account_key_pem_or_der,
        key_id => undef,
    );

    #for a new account
    {
        my $terms_url = $acme->get_terms_of_service();

        $acme->create_account(
            termsOfServiceAgreed => 1,
        );
    }

    #Save $acme->key_id() somewhere so you can use it again.

    my $order = $acme->create_order(
        identifiers => [
            { type => 'dns', value => '*.example.com' },
        ],
    );

    my $authz = $acme->get_authorization( ($order->authorizations())[0] );

    my @challenges = $authz->challenges();

    # ... Pick a challenge, and satisfy it.

    $acme->accept_challenge($challenge);

    sleep 1 while 'valid' ne $acme->poll_authorization($authz);

    # ... Make a key and CSR for *.example.com

    $acme->finalize_order($order, $csr_pem_or_der);

    while ($order->status() ne 'valid') {
        sleep 1;
        $acme->poll_order($order);
    }

    # ... and now fetch the certificate chain:

    my $pem_chain = $acme->get_certificate_chain($order);

See F</examples> in the distribution for more fleshed-out examples.

To use L<Let’s Encrypt|http://letsencrypt.org>, see
L<Net::ACME2::LetsEncrypt>.

=head1 DESCRIPTION

This library implements client logic for the
ACME (Automated Certificate Management Environment) protocol, as
standardized in L<RFC 8555|https://www.rfc-editor.org/rfc/rfc8555.txt>
and popularized by L<Let’s Encrypt|http://letsencrypt.org>.

=head1 STATUS

This is a production-grade implementation. While breaking changes at this
point are unlikely, please always check the changelog before upgrading to
a new version of this module.

=head1 FEATURES

=over

=item * Support for both ECDSA and RSA encrytion.

=item * Support for http-01, dns-01, and L<tls-alpn-01|https://datatracker.ietf.org/doc/draft-ietf-acme-tls-alpn/> challenges.

=item * Comprehensive error handling with typed, L<X::Tiny>-based exceptions.

=item * Supports blocking and (experimentally) non-blocking I/O.

=item * L<Account key rollover|https://www.rfc-editor.org/rfc/rfc8555.html#section-7.3.5> via C<change_key()>.

=item * L<Retry POST on C<badNonce> errors.|https://tools.ietf.org/html/rfc8555#section-6.5>

=item * This is a pure-Perl solution. Most of its dependencies are
either core modules or pure Perl themselves. XS is necessary to
communicate with the ACME server via TLS; however, most Perl installations
already include the necessary logic (i.e., L<Net::SSLeay>) for TLS.

In short, Net::ACME2 will run anywhere that Perl can speak TLS, which is
I<almost> everywhere that Perl runs.

=back

=head1 ERROR HANDLING

All thrown exceptions are instances of L<Net::ACME2::X::Generic>.
Specific error classes aren’t yet defined.

=head1 CRYPTOGRAPHY & SPEED

L<CryptX> (based on L<LibTomCrypt|http://www.libtom.net/LibTomCrypt/>)
provides the primary cryptographic backend for key operations (signing,
JWK export, thumbprints). L<Crypt::Perl> is used as a fallback and for
X.509 certificate generation (tls-alpn-01 challenge).

=cut

=head1 EXPERIMENTAL: NON-BLOCKING (ASYNCHRONOUS) I/O

By default, Net::ACME2 uses blocking I/O.

To facilitate asynchronous/non-blocking I/O, you may give an C<async_ua>
to C<new()>. This value must be an object that implements C<request()>.
That method should mimic L<HTTP::Tiny>’s method of the same name
B<except> that, instead of returning a hash reference, it should return
a promise. (à la L<Promise::XS>, L<Promise::ES6>, L<Mojo::Promise>, etc.)
That promise’s resolution should be a single value that mimics
C<HTTP::Tiny::request()>’s return structure.

When a Net::ACME2 instance is created with C<async_ua>, several of the
methods described below return promises. These promises resolve to the values
that otherwise would be returned directly in synchronous mode. Any exception
that would be thrown in synchronous mode is given as the promise’s rejection
value. This document’s convention to indicate a function that, in
asynchronous mode, returns a promise is:

    promise($whatever) = ...

This distribution ships with L<Net::ACME2::Curl>, a wrapper around
L<Net::Curl::Promiser>, which in turns wraps L<Net::Curl::Multi>. This
provides out-of-the-box support for Perl’s most widely-used event interfaces;
see Net::Curl::Promiser’s documentation for more details.

=cut

#----------------------------------------------------------------------

use Crypt::Format;
use Digest::SHA  ();
use MIME::Base64 ();

use Net::ACME2::AccountKey;

use Net::ACME2::HTTP;
use Net::ACME2::Order;
use Net::ACME2::Authorization;
use Net::ACME2::PromiseUtil;

use constant {
    _HTTP_OK => 200,
    _HTTP_CREATED => 201,
};

# accessed from test
use constant newAccount_booleans => qw(
    termsOfServiceAgreed
    onlyReturnExisting
);

# the list of methods that need a “jwk” in their JWS Protected Header
# (cf. section 6.2 of the spec)
use constant FULL_JWT_METHODS => qw(
    newAccount
    revokeCert
);

#----------------------------------------------------------------------

=head1 METHODS

=head2 I<CLASS>->new( %OPTS )

Instantiates an ACME2 object, which you’ll use for all
interactions with the ACME server. %OPTS is:

=over

=item * C<key> - Required. The private key to associate with the ACME2
user. Anything that C<Crypt::Perl::PK::parse_key()> can parse is acceptable.

=item * C<key_id> - Optional. As returned by C<key_id()>.
Saves a round-trip to the ACME2 server, so you should give this
if you have it.

=item * C<directory> - Optional. A hash reference to use as the
directory contents. Saves a round-trip to the ACME2 server, but there’s
no built-in logic to determine when the cache goes invalid. Caveat
emptor.

=item * C<async_ua> - Optional. Provides a custom UA object to facilitate
non-blocking I/O. This object B<MUST> implement the interface described above.

=back

=cut

sub new {
    my ( $class, %opts ) = @_;

    _die_generic('Need “key”!') if !$opts{'key'};

    return $class->_new_without_key_check(%opts);
}

sub _new_without_key_check {
    my ( $class, %opts ) = @_;

    my $self = {
        _host => $class->HOST(%opts),
        _key  => $opts{'key'},
        _key_id => $opts{'key_id'},
        _directory => $opts{'directory'},
        _async_ua => $opts{'async_ua'},
    };

    bless $self, $class;

    $self->_set_http();

    return $self;
}

#----------------------------------------------------------------------

=head2 $id = I<OBJ>->key_id()

Returns the object’s cached key ID, either as given at instantiation
or as fetched in C<create_account()>.

=cut

sub key_id {
    my ($self) = @_;

    return $self->{'_key_id'};
}

#----------------------------------------------------------------------

=head2 I<OBJ>->http_timeout( [$NEW] )

A passthrough interface to the underlying L<HTTP::Tiny> object’s
C<timeout()> method.

Throws an exception if C<async_ua> was given to C<new()>.

=cut

sub http_timeout {
    my $self = shift;

    die 'Don’t call in asynchronous mode!' if $self->{'_async_ua'};

    return $self->{'_http'}->timeout(@_);
}

#----------------------------------------------------------------------

=head2 promise($url) = I<CLASS>->get_terms_of_service()

Returns the URL for the terms of service. Callable as either
a class method or an instance method.

=cut

sub get_terms_of_service {
    my ($self) = @_;

    # We want to be able to call this as a class method.
    if (!ref $self) {
        $self = $self->_new_without_key_check();
    }

    return Net::ACME2::PromiseUtil::then(
        $self->_get_directory(),
        sub {
            my $dir = shift;

            # Exceptions here indicate an ACME violation and should be
            # practically nonexistent.
            my $url = $dir->{'meta'} or _die_generic('No “meta” in directory!');
            $url = $url->{'termsOfService'} or _die_generic('No “termsOfService” in directory metadata!');

            return $url;
        },
    );
}

#----------------------------------------------------------------------

=head2 promise($created_yn) = I<OBJ>->create_account( %OPTS )

Creates an account using the ACME2 object’s key and the passed
%OPTS, which are as described in the ACME2 spec (cf. C<newAccount>).
Boolean values may be given as simple Perl booleans.

Returns 1 if the account is newly created
or 0 if the account already existed.

NB: C<create_new_account()> is an alias for this method.

=head3 External Account Binding (EAB)

Some CAs (e.g., ZeroSSL, Google Trust Services) require external account
binding per RFC 8555 Section 7.3.4. To use EAB, pass the
C<externalAccountBinding> option:

    $acme->create_account(
        termsOfServiceAgreed => 1,
        externalAccountBinding => {
            kid       => $eab_key_id,
            mac_key   => $eab_hmac_key,     # base64url-encoded
            algorithm => 'HS256',            # optional; default HS256
        },
    );

C<kid> and C<mac_key> are provided out-of-band by the CA. C<algorithm>
defaults to C<HS256> and may also be C<HS384> or C<HS512>.

=cut

sub create_account {
    my ($self, %opts) = @_;

    for my $name (newAccount_booleans()) {
        next if !exists $opts{$name};
        ($opts{$name} &&= JSON::true()) ||= JSON::false();
    }

    my $eab = delete $opts{'externalAccountBinding'};

    my $post_promise;

    if ($eab) {
        $post_promise = Net::ACME2::PromiseUtil::then(
            $self->_get_directory(),
            sub {
                my $dir_hr = shift;

                my $url = $dir_hr->{'newAccount'} or _die_generic('No "newAccount" in directory!');

                $opts{'externalAccountBinding'} = $self->_build_eab_jws($eab, $url);

                return $self->_post_url( $url, \%opts, 'post_full_jwt' );
            },
        );
    }
    else {
        $post_promise = $self->_post( 'newAccount', \%opts );
    }

    return Net::ACME2::PromiseUtil::then(
        $post_promise,
        sub {
            my ($resp) = @_;

            $self->{'_key_id'} = $resp->header('location');

            $self->{'_http'}->set_key_id( $self->{'_key_id'} );

            my $is_new;

            if ($resp->status() == _HTTP_OK) {
                $is_new = 0;
            }
            elsif ($resp->status() == _HTTP_CREATED) {
                $is_new = 1;
            }
            else {
                $resp->die_because_unexpected();
            }

            my $struct = $resp->content_struct();

            if ($struct) {
                $self->{'_orders_url'} = $struct->{'orders'} if $struct->{'orders'};

                if ($is_new) {
                    for my $name (newAccount_booleans()) {
                        next if !exists $struct->{$name};
                        ($struct->{$name} &&= 1) ||= 0;
                    }
                }
            }

            return $is_new;
        },
    );
}

#----------------------------------------------------------------------

=head2 promise(@order_urls) = I<OBJ>->get_orders()

Returns a list of order URLs associated with the account. This
corresponds to the C<orders> field of the ACME account object
(RFC 8555, section 7.1.2.1).

Not all ACME servers provide the C<orders> URL (e.g., Let's Encrypt
does not). If the URL is unavailable, this method throws an exception.

=cut

sub get_orders {
    my ($self) = @_;

    my $orders_url = $self->{'_orders_url'} or do {
        _die_generic('No orders URL available. The ACME server may not support this feature (RFC 8555 section 7.1.2.1).');
    };

    return Net::ACME2::PromiseUtil::then(
        $self->_post_as_get($orders_url),
        sub {
            my $resp = shift;

            return @{ $resp->content_struct()->{'orders'} || [] };
        },
    );
}

#----------------------------------------------------------------------

=head2 promise(\%account) = I<OBJ>->update_account( %OPTS )

Updates the account associated with the ACME2 object's key.
%OPTS are as described in RFC 8555 section 7.3.2; in practice
only C<contact> is meaningfully updatable. Example:

    my $acct = $acme->update_account(
        contact => ['mailto:new@example.com'],
    );

Returns a hashref of the updated account object.

=cut

sub update_account {
    my ($self, %opts) = @_;

    my $url = $self->{'_key_id'} or do {
        _die_generic('No key ID has been set. Either pass "key_id" to new(), or create_account().');
    };

    return Net::ACME2::PromiseUtil::then(
        $self->_post_url( $url, \%opts ),
        sub {
            my ($resp) = @_;

            $resp->die_because_unexpected() if $resp->status() != _HTTP_OK;

            return $resp->content_struct();
        },
    );
}

sub _build_eab_jws {
    my ($self, $eab, $url) = @_;

    my $kid = $eab->{'kid'} or _die_generic('EAB requires "kid"');
    my $mac_key_b64u = $eab->{'mac_key'} or _die_generic('EAB requires "mac_key"');
    my $alg = $eab->{'algorithm'} || 'HS256';

    my $mac_key = MIME::Base64::decode_base64url($mac_key_b64u);

    my $jwk = $self->_key_obj()->get_struct_for_public_jwk();

    my $json = JSON->new()->canonical(1);

    my $b64u_payload = MIME::Base64::encode_base64url( $json->encode($jwk) );

    my $header = { alg => $alg, kid => $kid, url => $url };
    my $b64u_header = MIME::Base64::encode_base64url( $json->encode($header) );

    my $signing_input = "$b64u_header.$b64u_payload";

    my $hmac_cr = _eab_hmac_func($alg);
    my $signature = $hmac_cr->($signing_input, $mac_key);
    my $b64u_signature = MIME::Base64::encode_base64url($signature);

    return {
        protected => $b64u_header,
        payload   => $b64u_payload,
        signature => $b64u_signature,
    };
}

my %_EAB_HMAC = (
    HS256 => \&Digest::SHA::hmac_sha256,
    HS384 => \&Digest::SHA::hmac_sha384,
    HS512 => \&Digest::SHA::hmac_sha512,
);

sub _eab_hmac_func {
    my ($alg) = @_;

    return $_EAB_HMAC{$alg} || _die_generic("Unsupported EAB algorithm: \"$alg\"");
}

#----------------------------------------------------------------------

=head2 promise() = I<OBJ>->change_key( $NEW_KEY )

Rolls over the account key per RFC 8555 section 7.3.5. $NEW_KEY is
the new private key in PEM or DER format (anything that
C<Net::ACME2::AccountKey> can parse).

On success, the object's key is updated to the new key so that
subsequent requests use it.

=cut

sub change_key {
    my ($self, $new_key_pem_or_der) = @_;

    _die_generic('Need "new key"!') if !$new_key_pem_or_der;

    $self->_require_key_id({});

    my $new_key_obj = Net::ACME2::AccountKey->new($new_key_pem_or_der);

    return Net::ACME2::PromiseUtil::then(
        $self->_get_directory(),
        sub {
            my $dir_hr = shift;

            my $key_change_url = $dir_hr->{'keyChange'} or _die_generic('Directory lacks "keyChange".');

            my $old_jwk = $self->_key_obj()->get_struct_for_public_jwk();

            my $inner_payload = {
                account => $self->{'_key_id'},
                oldKey  => $old_jwk,
            };

            my $new_jwt_maker = $self->_make_jwt_maker($new_key_obj);

            my $inner_jws = $new_jwt_maker->create_full_jws_for_url(
                payload => $inner_payload,
                url     => $key_change_url,
                extra_headers => {},
            );

            return Net::ACME2::PromiseUtil::then(
                $self->{'_http'}->post_key_change($key_change_url, $inner_jws),
                sub {
                    my $resp = shift;

                    $resp->die_because_unexpected() if $resp->status() != _HTTP_OK;

                    $self->{'_key'} = $new_key_pem_or_der;
                    $self->{'_key_obj'} = $new_key_obj;
                    $self->{'_key_thumbprint'} = undef;
                    $self->{'_http'}->update_key($new_key_obj);

                    return;
                },
            );
        },
    );
}

#----------------------------------------------------------------------

=head2 promise() = I<OBJ>->deactivate_account()

Deactivates the account on the ACME server, as described in
RFC 8555 section 7.3.6. This is permanent: the server will reject
all future requests authorized by this account's key.

Requires that a key ID has been set (via C<create_account()> or
the C<key_id> parameter to C<new()>).

=cut

sub deactivate_account {
    my ($self) = @_;

    $self->_require_key_id({});

    return Net::ACME2::PromiseUtil::then(
        $self->_post_url(
            $self->{'_key_id'},
            { status => 'deactivated' },
        ),
        sub {
            return;
        },
    );
}

#----------------------------------------------------------------------
=head2 promise($order) = I<OBJ>->create_order( %OPTS )

Returns a L<Net::ACME2::Order> object. %OPTS is as described in the
ACME spec (cf. C<newOrder>). Boolean values may be given as simple
Perl booleans.

NB: C<create_new_order()> is an alias for this method.

=cut

sub create_order {
    my ($self, %opts) = @_;

    $self->_require_key_id(\%opts);

    return Net::ACME2::PromiseUtil::then(
        $self->_post( 'newOrder', \%opts ),
        sub {
            my ($resp) = @_;

            $resp->die_because_unexpected() if $resp->status() != _HTTP_CREATED;

            return Net::ACME2::Order->new(
                id => $resp->header('location'),
                %{ $resp->content_struct() },
            );
        },
    );
}

#----------------------------------------------------------------------

=head2 promise($authz) = I<OBJ>->get_authorization( $URL )

Fetches the authorization’s information based on the given $URL
and returns a L<Net::ACME2::Authorization> object.

The URL is as given by L<Net::ACME2::Order>’s C<authorizations()> method.

=cut

sub get_authorization {
    my ($self, $id) = @_;

    return Net::ACME2::PromiseUtil::then(
        $self->_post_as_get($id),
        sub {
            my $resp = shift;

            return Net::ACME2::Authorization->new(
                id => $id,
                %{ $resp->content_struct() },
            );
        },
    );
}

#----------------------------------------------------------------------

=head2 $str = I<OBJ>->make_key_authorization( $CHALLENGE )

Accepts an instance of L<Net::ACME2::Challenge> (probably a subclass
thereof) and returns
a key authorization string suitable for handling the given $CHALLENGE.
See F</examples> in the distribution for example usage.

If you’re using HTTP authorization and are on the same server as the
domains’ document roots, then look at the handler logic in
L<Net::ACME2::Challenge::http_01> for a potentially simpler way to
handle HTTP challenges.

=cut

sub make_key_authorization {
    my ($self, $challenge_obj) = @_;

    _die_generic('Need a challenge object!') if !$challenge_obj;

    return $challenge_obj->token() . '.' . $self->_key_thumbprint();
}

#----------------------------------------------------------------------

=head2 promise() = I<OBJ>->accept_challenge( $CHALLENGE )

Signal to the ACME server that the CHALLENGE is ready.

=cut

sub accept_challenge {
    my ($self, $challenge_obj) = @_;

    return Net::ACME2::PromiseUtil::then(
        $self->_post_url(
            $challenge_obj->url(),
            {
                keyAuthorization => $self->make_key_authorization($challenge_obj),
            },
        ),
        sub { undef },
    );
}

#----------------------------------------------------------------------

=head2 promise($status) = I<OBJ>->poll_authorization( $AUTHORIZATION )

Accepts a L<Net::ACME2::Authorization> instance and polls the
ACME server for that authorization’s status. The $AUTHORIZATION
object is then updated with the results of the poll.

If the server includes a C<Retry-After> header, it is stored on the
$AUTHORIZATION object and accessible via C<< $AUTHORIZATION->retry_after() >>.

As a courtesy, this returns the $AUTHORIZATION’s new C<status()>.

=cut

#This has to handle updates to the authz and challenge objects
*poll_authorization = *_poll_order_or_authz;

#----------------------------------------------------------------------

=head2 promise($status) = I<OBJ>->deactivate_authorization( $AUTHORIZATION )

Deactivates an authorization, as described in RFC 8555 section 7.5.2.

Accepts a L<Net::ACME2::Authorization> instance and asks the ACME server
to deactivate it. The $AUTHORIZATION object is then updated with the
results of the deactivation.

As a courtesy, this returns the $AUTHORIZATION's new C<status()>,
which should be C<deactivated>.

=cut

sub deactivate_authorization {
    my ($self, $authz_obj) = @_;

    return Net::ACME2::PromiseUtil::then(
        $self->_post_url(
            $authz_obj->id(),
            {
                status => 'deactivated',
            },
        ),
        sub {
            my $resp = shift;

            $authz_obj->update( $resp->content_struct() );

            return $authz_obj->status();
        },
    );
}

#----------------------------------------------------------------------

=head2 promise($status) = I<OBJ>->finalize_order( $ORDER, $CSR )

Finalizes an order and updates the $ORDER object with the returned
status. $CSR may be in either DER or PEM format.

As a courtesy, this returns the $ORDER’s C<status()>. If this does
not equal C<valid>, then you should probably C<poll_order()>
until it does.

=cut

sub finalize_order {
    my ($self, $order_obj, $csr) = @_;

    my $csr_der;
    if (index($csr, '-----') == 0) {
        $csr_der = Crypt::Format::pem2der($csr);
    }
    else {
        $csr_der = $csr;
    }

    $csr = MIME::Base64::encode_base64url($csr_der);

    return Net::ACME2::PromiseUtil::then(
        $self->_post_url(
            $order_obj->finalize(),
            {
                csr => $csr,
            },
        ),
        sub {
            my $post = shift;

            my $content = $post->content_struct();

            $order_obj->update($content);

            return $order_obj->status();
        },
    );
}

#----------------------------------------------------------------------

=head2 promise($status) = I<OBJ>->poll_order( $ORDER )

Like C<poll_authorization()> but handles a
L<Net::ACME2::Order> object instead. The C<Retry-After> header,
if present, is accessible via C<< $ORDER->retry_after() >>.

=cut

*poll_order = *_poll_order_or_authz;

#----------------------------------------------------------------------

=head2 promise($cert) = I<OBJ>->get_certificate_chain( $ORDER )

Fetches the $ORDER’s certificate chain and returns
it in the format implied by the
C<application/pem-certificate-chain> MIME type. See the ACME
protocol specification for details about this format.

=cut

sub get_certificate_chain {
    my ($self, $order) = @_;

    my $url = $order->certificate() or _die_generic(
        'Order has no certificate URL (status: ' . $order->status() . '). Poll the order until it reaches "valid" status before fetching the certificate.',
    );

    return Net::ACME2::PromiseUtil::then(
        $self->_post_as_get( $url ),
        sub {
            return shift()->content();
        },
    );
}

#----------------------------------------------------------------------

=head2 promise(\%chains) = I<OBJ>->get_certificate_chains( $ORDER )

Like C<get_certificate_chain()> but also fetches any alternate
certificate chains that the server offers via C<Link> headers with
C<rel="alternate"> (per RFC 8555, section 7.4.2).

Returns a hash reference:

    {
        default    => $pem_chain,
        alternates => [ $alt_pem1, $alt_pem2, ... ],
    }

If the server offers no alternate chains, C<alternates> will be
an empty array reference.

=cut

sub get_certificate_chains {
    my ($self, $order) = @_;

    my $url = $order->certificate() or _die_generic(
        'Order has no certificate URL (status: ' . $order->status() . '). Poll the order until it reaches "valid" status before fetching the certificate.',
    );

    return Net::ACME2::PromiseUtil::then(
        $self->_post_as_get( $url ),
        sub {
            my ($resp) = @_;

            my $default = $resp->content();

            my @alt_urls = _parse_link_alternates($resp);

            if (!@alt_urls) {
                return {
                    default    => $default,
                    alternates => [],
                };
            }

            return $self->_fetch_alternates($default, \@alt_urls);
        },
    );
}

sub _parse_link_alternates {
    my ($resp) = @_;

    my $link_header = $resp->header('link');

    return if !defined $link_header;

    my @links = ref $link_header ? @$link_header : ($link_header);

    my @alt_urls;
    for my $link (@links) {
        if ($link =~ m{<([^>]+)>\s*;\s*rel="alternate"}) {
            push @alt_urls, $1;
        }
    }

    return @alt_urls;
}

sub _fetch_alternates {
    my ($self, $default, $alt_urls) = @_;

    my $result = {
        default    => $default,
        alternates => [],
    };

    my $remaining = [ @$alt_urls ];

    return $self->_fetch_next_alternate($result, $remaining);
}

sub _fetch_next_alternate {
    my ($self, $result, $remaining) = @_;

    if (!@$remaining) {
        return $result;
    }

    my $url = shift @$remaining;

    return Net::ACME2::PromiseUtil::then(
        $self->_post_as_get($url),
        sub {
            push @{ $result->{'alternates'} }, shift()->content();
            return $self->_fetch_next_alternate($result, $remaining);
        },
    );
}

#----------------------------------------------------------------------

=head2 promise() = I<OBJ>->revoke_certificate( $CERT, %OPTS )

Revokes a certificate per RFC 8555 section 7.6.
$CERT may be in PEM or DER format.

%OPTS is:

=over

=item * C<reason> - Optional. An integer revocation reason code per
RFC 5280 section 5.3.1 (e.g., 0 = unspecified, 1 = keyCompromise,
4 = superseded).

=item * C<key> - Optional. A PEM or DER private key to sign the
revocation request. This allows revoking a certificate using the
certificate's own key rather than the account key.

=back

=cut

sub revoke_certificate {
    my ($self, $cert, %opts) = @_;

    _die_generic('Need a certificate!') if !defined $cert || !length $cert;

    my $cert_der;
    if (index($cert, '-----') == 0) {
        $cert_der = Crypt::Format::pem2der($cert);
    }
    else {
        $cert_der = $cert;
    }

    my %payload = (
        certificate => MIME::Base64::encode_base64url($cert_der),
    );

    $payload{'reason'} = $opts{'reason'} if defined $opts{'reason'};

    if ($opts{'key'}) {
        return $self->_revoke_with_key(\%payload, $opts{'key'});
    }

    return Net::ACME2::PromiseUtil::then(
        $self->_post( 'revokeCert', \%payload ),
        sub { undef },
    );
}

sub _revoke_with_key {
    my ($self, $payload_hr, $key) = @_;

    my $key_obj = Net::ACME2::AccountKey->new($key);

    my $temp_http = Net::ACME2::HTTP->new(
        key => $key_obj,
    );

    return Net::ACME2::PromiseUtil::then(
        $self->_get_directory(),
        sub {
            my $dir_hr = shift;

            my $url = $dir_hr->{'revokeCert'} or _die_generic('No "revokeCert" in directory!');

            $temp_http->set_new_nonce_url( $dir_hr->{'newNonce'} );

            return Net::ACME2::PromiseUtil::then(
                $temp_http->post_full_jwt( $url, $payload_hr ),
                sub { undef },
            );
        },
    );
}

#----------------------------------------------------------------------

sub _key_thumbprint {
    my ($self) = @_;

    return $self->{'_key_thumbprint'} ||= $self->_key_obj()->get_jwk_thumbprint();
}

sub _get_directory {
    my ($self) = @_;

    return $self->{'_directory_cache'} ||= do {
        my $dir_path = $self->DIRECTORY_PATH();

        my $http = $self->{'_http'};

        Net::ACME2::PromiseUtil::then(
            $self->{'_http'}->get("https://$self->{'_host'}$dir_path"),
            sub {
                my $dir_hr = shift()->content_struct();

                my $new_nonce_url = $dir_hr->{'newNonce'} or do {
                    _die_generic('Directory lacks “newNonce”.');
                };

                $http->set_new_nonce_url( $new_nonce_url );

                return $dir_hr;
            },
        );
    };
}

sub _require_key_id {
    my ($self, $opts_hr) = @_;

    $opts_hr->{'_key_id'} = $self->{'_key_id'} or do {
        _die_generic('No key ID has been set. Either pass “key_id” to new(), or create_account().');
    };

    return
}

sub _poll_order_or_authz {
    my ($self, $order_or_authz_obj) = @_;

    return Net::ACME2::PromiseUtil::then(
        $self->_post_as_get( $order_or_authz_obj->id() ),
        sub {
            my $get = shift;

            my $content = $get->content_struct();

            $order_or_authz_obj->update($content);

            $order_or_authz_obj->{'_retry_after'} = $get->header('retry-after');

            return $order_or_authz_obj->status();
        },
    );
}

sub _key_obj {
    my ($self) = @_;

    return $self->{'_key_obj'} ||= Net::ACME2::AccountKey->new($self->{'_key'});
}

sub _make_jwt_maker {
    my ($self, $key_obj) = @_;

    my $class;

    my $key_type = $key_obj->get_type();

    if ($key_type eq 'rsa') {
        $class = 'Net::ACME2::JWTMaker::RSA';
    }
    elsif ($key_type eq 'ecdsa') {
        $class = 'Net::ACME2::JWTMaker::ECC';
    }
    else {
        _die_generic("Unrecognized key type: \"$key_type\"");
    }

    if (!$class->can('new')) {
        require Module::Runtime;
        Module::Runtime::use_module($class);
    }

    return $class->new( key => $key_obj );
}

sub _set_http {
    my ($self) = @_;

    $self->{'_http'} = Net::ACME2::HTTP->new(
        key => $self->{'_key'} && $self->_key_obj(),
        key_id => $self->{'_key_id'},
        ua => $self->{'_async_ua'},
    );

    return;
}

our $_POST_METHOD;

sub _post {
    my ( $self, $link_name, $data ) = @_;

    my $post_method;
    $post_method = 'post_full_jwt' if grep { $link_name eq $_ } FULL_JWT_METHODS();

    return Net::ACME2::PromiseUtil::then(
        $self->_get_directory(),
        sub {
            my $dir_hr = shift;

            # Since the $link_name will come from elsewhere in this module
            # there really shouldn’t be an error here, but just in case.
            my $url = $dir_hr->{$link_name} or _die_generic("Unknown link name: “$link_name”");

            return $self->_post_url( $url, $data, $post_method );
        },
    );
}

sub _post_as_get {
    my ( $self, $url ) = @_;

    return $self->_post_url( $url, q<> );
}

sub _post_url {
    my ( $self, $url, $data, $opt_post_method ) = @_;

    my $post_method = $opt_post_method || 'post_key_id';

    my $http = $self->{'_http'};

    #Do this in case we haven’t initialized the directory yet.
    #Initializing the directory is necessary to get a nonce.
    return Net::ACME2::PromiseUtil::then(
        $self->_get_directory(),
        sub {
            return $http->$post_method( $url, $data );
        },
    );
}

sub _die_generic {
    die Net::ACME2::X->create('Generic', @_);
}

#legacy aliases
*create_new_account = *create_account;
*create_new_order = *create_order;

1;

=head1 TODO

=over

=item * Add pre-authorization support if there is ever a production
use for it.

=item * There is currently no way to fetch an order or challenge’s
properties via URL. Prior to ACME’s adoption of “POST-as-GET” this was
doable via a plain GET to the URL, but that’s no longer possible.
If there’s a need, I’ll consider adding such logic to Net::ACME2.
(It’s trivial to add; I’d just like to keep things as
simple as possible.)

=item * Add (more) tests.

=back

=head1 SEE ALSO

L<Crypt::LE> is another ACME client library.

L<CryptX> provides this library’s primary cryptography backend.
L<Crypt::Perl> is used as a fallback and for X.509 operations.
See this distribution’s F</examples> directory for sample usage
to generate keys and CSRs.

L<Net::ACME> implements client logic for the variant of this
protocol that Let’s Encrypt first deployed.

=cut
