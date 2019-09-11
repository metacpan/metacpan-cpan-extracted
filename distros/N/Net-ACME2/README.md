# NAME

Net::ACME2 - Client logic for the ACME (Let's Encrypt) protocol

  

# SYNOPSIS

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

See `/examples` in the distribution for more fleshed-out examples.

To use [Let’s Encrypt](http://letsencrypt.org), see
[Net::ACME2::LetsEncrypt](https://metacpan.org/pod/Net::ACME2::LetsEncrypt).

# DESCRIPTION

This library implements client logic for the
ACME (Automated Certificate Management Environment) protocol, as
standardized in [RFC 8555](https://www.rfc-editor.org/rfc/rfc8555.txt)
and popularized by [Let’s Encrypt](http://letsencrypt.org).

# STATUS

This is a production-grade implementation. While breaking changes at this
point are unlikely, please always check the changelog before upgrading to
a new version of this module.

# FEATURES

- Support for both ECDSA and RSA encrytion.
- Support for http-01, dns-01, and [tls-alpn-01](https://datatracker.ietf.org/doc/draft-ietf-acme-tls-alpn/) challenges.
- Comprehensive error handling with typed, [X::Tiny](https://metacpan.org/pod/X::Tiny)-based exceptions.
- [Retry POST on `badNonce` errors.](https://tools.ietf.org/html/rfc8555#section-6.5)
- This is a pure-Perl solution. Most of its dependencies are
either core modules or pure Perl themselves. XS is necessary to
communicate with the ACME server via TLS; however, most Perl installations
already include the necessary logic (i.e., [Net::SSLeay](https://metacpan.org/pod/Net::SSLeay)) for TLS.

    In short, Net::ACME2 will run anywhere that Perl can speak TLS, which is
    _almost_ everywhere that Perl runs.

# ERROR HANDLING

All thrown exceptions are instances of [Net::ACME2::X::Generic](https://metacpan.org/pod/Net::ACME2::X::Generic).
Specific error classes aren’t yet defined.

# CRYPTOGRAPHY & SPEED

[Crypt::Perl](https://metacpan.org/pod/Crypt::Perl) provides all cryptographic operations that this library
needs using pure Perl. While this satisfies this module’s intent to be
as pure-Perl as possible, there are a couple of significant drawbacks
to this approach: firstly, it’s slower than XS-based code, and secondly,
it loses the security benefits of the vetting that more widely-used
cryptography libraries receive.

To address these problems, Net::ACME2 will, after parsing a key, look
for and prefer the following XS-based libraries for cryptography instead:

- [Crypt::OpenSSL::RSA](https://metacpan.org/pod/Crypt::OpenSSL::RSA) (based on [OpenSSL](http://openssl.org))
- [CryptX](https://metacpan.org/pod/CryptX) (based on [LibTomCrypt](http://www.libtom.net/LibTomCrypt/))

If the above are unavailable to you, then you may be able to speed up
your [Math::BigInt](https://metacpan.org/pod/Math::BigInt) installation; see that module’s documentation
for more details.

# METHODS

## _CLASS_->new( %OPTS )

Instantiates an ACME2 object, which you’ll use for all
interactions with the ACME server. %OPTS is:

- `key` - Required. The private key to associate with the ACME2
user. Anything that `Crypt::Perl::PK::parse_key()` can parse is acceptable.
- `key_id` - Optional. As returned by `key_id()`.
Saves a round-trip to the ACME2 server, so you should give this
if you have it.
- `directory` - Optional. A hash reference to use as the
directory contents. Saves a round-trip to the ACME2 server, but there’s
no built-in logic to determine when the cache goes invalid. Caveat
emptor.

## $id = _OBJ_->key\_id()

Returns the object’s cached key ID, either as given at instantiation
or as fetched in `create_account()`.

## _OBJ_->http\_timeout( \[$NEW\] )

A passthrough interface to the underlying [HTTP::Tiny](https://metacpan.org/pod/HTTP::Tiny) object’s
`timeout()` method.

## $url = _CLASS_->get\_terms\_of\_service()

Returns the URL for the terms of service. Callable as either
a class method or an instance method.

## $created\_yn = _OBJ_->create\_account( %OPTS )

Creates an account using the ACME2 object’s key and the passed
%OPTS, which are as described in the ACME2 spec (cf. `newAccount`).
Boolean values may be given as simple Perl booleans.

Returns 1 if the account is newly created
or 0 if the account already existed.

NB: `create_new_account()` is an alias for this method.

## $order = _OBJ_->create\_order( %OPTS )

Returns a [Net::ACME2::Order](https://metacpan.org/pod/Net::ACME2::Order) object. %OPTS is as described in the
ACME spec (cf. `newOrder`). Boolean values may be given as simple
Perl booleans.

NB: `create_new_order()` is an alias for this method.

## $authz = _OBJ_->get\_authorization( $URL )

Fetches the authorization’s information based on the given $URL
and returns a [Net::ACME2::Authorization](https://metacpan.org/pod/Net::ACME2::Authorization) object.

The URL is as given by [Net::ACME2::Order](https://metacpan.org/pod/Net::ACME2::Order)’s `authorizations()` method.

## $str = _OBJ_->make\_key\_authorization( $CHALLENGE )

Accepts an instance of [Net::ACME2::Challenge](https://metacpan.org/pod/Net::ACME2::Challenge) (probably a subclass
thereof) and returns
a key authorization string suitable for handling the given $CHALLENGE.
See `/examples` in the distribution for example usage.

If you’re using HTTP authorization and are on the same server as the
domains’ document roots, then look at the handler logic in
[Net::ACME2::Challenge::http\_01](https://metacpan.org/pod/Net::ACME2::Challenge::http_01) for a potentially simpler way to
handle HTTP challenges.

## _OBJ_->accept\_challenge( $CHALLENGE )

Signal to the ACME server that the CHALLENGE is ready.

## $status = _OBJ_->poll\_authorization( $AUTHORIZATION )

Accepts a [Net::ACME2::Authorization](https://metacpan.org/pod/Net::ACME2::Authorization) instance and polls the
ACME server for that authorization’s status. The $AUTHORIZATION
object is then updated with the results of the poll.

As a courtesy, this returns the $AUTHORIZATION’s new `status()`.

## $status = _OBJ_->finalize\_order( $ORDER, $CSR )

Finalizes an order and updates the $ORDER object with the returned
status. $CSR may be in either DER or PEM format.

As a courtesy, this returns the $ORDER’s `status()`. If this does
not equal `valid`, then you should probably `poll_order()`
until it does.

## $status = _OBJ_->poll\_order( $ORDER )

Like `poll_authorization()` but handles a
[Net::ACME2::Order](https://metacpan.org/pod/Net::ACME2::Order) object instead.

## $cert = _OBJ_->get\_certificate\_chain( $ORDER )

Fetches the $ORDER’s certificate chain and returns
it in the format implied by the
`application/pem-certificate-chain` MIME type. See the ACME
protocol specification for details about this format.

# TODO

- Add pre-authorization support if there is ever a production
use for it.
- Expose the Retry-After header via the module API.
- There is currently no way to fetch an order or challenge’s
properties via URL. Prior to ACME’s adoption of “POST-as-GET” this was
doable via a plain GET to the URL, but that’s no longer possible.
If there’s a need, I’ll consider adding such logic to Net::ACME2.
(It’s trivial to add; I’d just like to keep things as
simple as possible.)
- Add (more) tests.

# SEE ALSO

[Crypt::LE](https://metacpan.org/pod/Crypt::LE) is another ACME client library.

[Crypt::Perl](https://metacpan.org/pod/Crypt::Perl) provides this library’s default cryptography backend.
See this distribution’s `/examples` directory for sample usage
to generate keys and CSRs.

[Net::ACME](https://metacpan.org/pod/Net::ACME) implements client logic for the variant of this
protocol that Let’s Encrypt first deployed.
