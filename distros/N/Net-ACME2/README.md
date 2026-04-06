[![testsuite](https://github.com/cpan-authors/Net-ACME2/actions/workflows/testsuite.yml/badge.svg)](https://github.com/cpan-authors/Net-ACME2/actions/workflows/testsuite.yml)

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
[Net::ACME2::LetsEncrypt](https://metacpan.org/pod/Net%3A%3AACME2%3A%3ALetsEncrypt).

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
- Comprehensive error handling with typed, [X::Tiny](https://metacpan.org/pod/X%3A%3ATiny)-based exceptions.
- Supports blocking and (experimentally) non-blocking I/O.
- [Account key rollover](https://www.rfc-editor.org/rfc/rfc8555.html#section-7.3.5) via `change_key()`.
- [Retry POST on `badNonce` errors.](https://tools.ietf.org/html/rfc8555#section-6.5)
- This is a pure-Perl solution. Most of its dependencies are
either core modules or pure Perl themselves. XS is necessary to
communicate with the ACME server via TLS; however, most Perl installations
already include the necessary logic (i.e., [Net::SSLeay](https://metacpan.org/pod/Net%3A%3ASSLeay)) for TLS.

    In short, Net::ACME2 will run anywhere that Perl can speak TLS, which is
    _almost_ everywhere that Perl runs.

# ERROR HANDLING

All thrown exceptions are instances of [Net::ACME2::X::Generic](https://metacpan.org/pod/Net%3A%3AACME2%3A%3AX%3A%3AGeneric).
Specific error classes aren’t yet defined.

# CRYPTOGRAPHY & SPEED

[CryptX](https://metacpan.org/pod/CryptX) (based on [LibTomCrypt](http://www.libtom.net/LibTomCrypt/))
provides the primary cryptographic backend for key operations (signing,
JWK export, thumbprints). [Crypt::Perl](https://metacpan.org/pod/Crypt%3A%3APerl) is used as a fallback and for
X.509 certificate generation (tls-alpn-01 challenge).

# EXPERIMENTAL: NON-BLOCKING (ASYNCHRONOUS) I/O

By default, Net::ACME2 uses blocking I/O.

To facilitate asynchronous/non-blocking I/O, you may give an `async_ua`
to `new()`. This value must be an object that implements `request()`.
That method should mimic [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny)’s method of the same name
**except** that, instead of returning a hash reference, it should return
a promise. (à la [Promise::XS](https://metacpan.org/pod/Promise%3A%3AXS), [Promise::ES6](https://metacpan.org/pod/Promise%3A%3AES6), [Mojo::Promise](https://metacpan.org/pod/Mojo%3A%3APromise), etc.)
That promise’s resolution should be a single value that mimics
`HTTP::Tiny::request()`’s return structure.

When a Net::ACME2 instance is created with `async_ua`, several of the
methods described below return promises. These promises resolve to the values
that otherwise would be returned directly in synchronous mode. Any exception
that would be thrown in synchronous mode is given as the promise’s rejection
value. This document’s convention to indicate a function that, in
asynchronous mode, returns a promise is:

    promise($whatever) = ...

This distribution ships with [Net::ACME2::Curl](https://metacpan.org/pod/Net%3A%3AACME2%3A%3ACurl), a wrapper around
[Net::Curl::Promiser](https://metacpan.org/pod/Net%3A%3ACurl%3A%3APromiser), which in turns wraps [Net::Curl::Multi](https://metacpan.org/pod/Net%3A%3ACurl%3A%3AMulti). This
provides out-of-the-box support for Perl’s most widely-used event interfaces;
see Net::Curl::Promiser’s documentation for more details.

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
- `async_ua` - Optional. Provides a custom UA object to facilitate
non-blocking I/O. This object **MUST** implement the interface described above.

## $id = _OBJ_->key\_id()

Returns the object’s cached key ID, either as given at instantiation
or as fetched in `create_account()`.

## _OBJ_->http\_timeout( \[$NEW\] )

A passthrough interface to the underlying [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny) object’s
`timeout()` method.

Throws an exception if `async_ua` was given to `new()`.

## promise($url) = _CLASS_->get\_terms\_of\_service()

Returns the URL for the terms of service. Callable as either
a class method or an instance method.

## promise($created\_yn) = _OBJ_->create\_account( %OPTS )

Creates an account using the ACME2 object’s key and the passed
%OPTS, which are as described in the ACME2 spec (cf. `newAccount`).
Boolean values may be given as simple Perl booleans.

Returns 1 if the account is newly created
or 0 if the account already existed.

NB: `create_new_account()` is an alias for this method.

### External Account Binding (EAB)

Some CAs (e.g., ZeroSSL, Google Trust Services) require external account
binding per RFC 8555 Section 7.3.4. To use EAB, pass the
`externalAccountBinding` option:

    $acme->create_account(
        termsOfServiceAgreed => 1,
        externalAccountBinding => {
            kid       => $eab_key_id,
            mac_key   => $eab_hmac_key,     # base64url-encoded
            algorithm => 'HS256',            # optional; default HS256
        },
    );

`kid` and `mac_key` are provided out-of-band by the CA. `algorithm`
defaults to `HS256` and may also be `HS384` or `HS512`.

## promise(@order\_urls) = _OBJ_->get\_orders()

Returns a list of order URLs associated with the account. This
corresponds to the `orders` field of the ACME account object
(RFC 8555, section 7.1.2.1).

Not all ACME servers provide the `orders` URL (e.g., Let's Encrypt
does not). If the URL is unavailable, this method throws an exception.

## promise(\\%account) = _OBJ_->update\_account( %OPTS )

Updates the account associated with the ACME2 object's key.
%OPTS are as described in RFC 8555 section 7.3.2; in practice
only `contact` is meaningfully updatable. Example:

    my $acct = $acme->update_account(
        contact => ['mailto:new@example.com'],
    );

Returns a hashref of the updated account object.

## promise() = _OBJ_->change\_key( $NEW\_KEY )

Rolls over the account key per RFC 8555 section 7.3.5. $NEW\_KEY is
the new private key in PEM or DER format (anything that
`Net::ACME2::AccountKey` can parse).

On success, the object's key is updated to the new key so that
subsequent requests use it.

## promise() = _OBJ_->deactivate\_account()

Deactivates the account on the ACME server, as described in
RFC 8555 section 7.3.6. This is permanent: the server will reject
all future requests authorized by this account's key.

Requires that a key ID has been set (via `create_account()` or
the `key_id` parameter to `new()`).

## promise($order) = _OBJ_->create\_order( %OPTS )

Returns a [Net::ACME2::Order](https://metacpan.org/pod/Net%3A%3AACME2%3A%3AOrder) object. %OPTS is as described in the
ACME spec (cf. `newOrder`). Boolean values may be given as simple
Perl booleans.

NB: `create_new_order()` is an alias for this method.

## promise($authz) = _OBJ_->get\_authorization( $URL )

Fetches the authorization’s information based on the given $URL
and returns a [Net::ACME2::Authorization](https://metacpan.org/pod/Net%3A%3AACME2%3A%3AAuthorization) object.

The URL is as given by [Net::ACME2::Order](https://metacpan.org/pod/Net%3A%3AACME2%3A%3AOrder)’s `authorizations()` method.

## $str = _OBJ_->make\_key\_authorization( $CHALLENGE )

Accepts an instance of [Net::ACME2::Challenge](https://metacpan.org/pod/Net%3A%3AACME2%3A%3AChallenge) (probably a subclass
thereof) and returns
a key authorization string suitable for handling the given $CHALLENGE.
See `/examples` in the distribution for example usage.

If you’re using HTTP authorization and are on the same server as the
domains’ document roots, then look at the handler logic in
[Net::ACME2::Challenge::http\_01](https://metacpan.org/pod/Net%3A%3AACME2%3A%3AChallenge%3A%3Ahttp_01) for a potentially simpler way to
handle HTTP challenges.

## promise() = _OBJ_->accept\_challenge( $CHALLENGE )

Signal to the ACME server that the CHALLENGE is ready.

## promise($status) = _OBJ_->poll\_authorization( $AUTHORIZATION )

Accepts a [Net::ACME2::Authorization](https://metacpan.org/pod/Net%3A%3AACME2%3A%3AAuthorization) instance and polls the
ACME server for that authorization’s status. The $AUTHORIZATION
object is then updated with the results of the poll.

If the server includes a `Retry-After` header, it is stored on the
$AUTHORIZATION object and accessible via `$AUTHORIZATION->retry_after()`.

As a courtesy, this returns the $AUTHORIZATION’s new `status()`.

## promise($status) = _OBJ_->deactivate\_authorization( $AUTHORIZATION )

Deactivates an authorization, as described in RFC 8555 section 7.5.2.

Accepts a [Net::ACME2::Authorization](https://metacpan.org/pod/Net%3A%3AACME2%3A%3AAuthorization) instance and asks the ACME server
to deactivate it. The $AUTHORIZATION object is then updated with the
results of the deactivation.

As a courtesy, this returns the $AUTHORIZATION's new `status()`,
which should be `deactivated`.

## promise($status) = _OBJ_->finalize\_order( $ORDER, $CSR )

Finalizes an order and updates the $ORDER object with the returned
status. $CSR may be in either DER or PEM format.

As a courtesy, this returns the $ORDER’s `status()`. If this does
not equal `valid`, then you should probably `poll_order()`
until it does.

## promise($status) = _OBJ_->poll\_order( $ORDER )

Like `poll_authorization()` but handles a
[Net::ACME2::Order](https://metacpan.org/pod/Net%3A%3AACME2%3A%3AOrder) object instead. The `Retry-After` header,
if present, is accessible via `$ORDER->retry_after()`.

## promise($cert) = _OBJ_->get\_certificate\_chain( $ORDER )

Fetches the $ORDER’s certificate chain and returns
it in the format implied by the
`application/pem-certificate-chain` MIME type. See the ACME
protocol specification for details about this format.

## promise(\\%chains) = _OBJ_->get\_certificate\_chains( $ORDER )

Like `get_certificate_chain()` but also fetches any alternate
certificate chains that the server offers via `Link` headers with
`rel="alternate"` (per RFC 8555, section 7.4.2).

Returns a hash reference:

    {
        default    => $pem_chain,
        alternates => [ $alt_pem1, $alt_pem2, ... ],
    }

If the server offers no alternate chains, `alternates` will be
an empty array reference.

## promise() = _OBJ_->revoke\_certificate( $CERT, %OPTS )

Revokes a certificate per RFC 8555 section 7.6.
$CERT may be in PEM or DER format.

%OPTS is:

- `reason` - Optional. An integer revocation reason code per
RFC 5280 section 5.3.1 (e.g., 0 = unspecified, 1 = keyCompromise,
4 = superseded).
- `key` - Optional. A PEM or DER private key to sign the
revocation request. This allows revoking a certificate using the
certificate's own key rather than the account key.

# TODO

- Add pre-authorization support if there is ever a production
use for it.
- There is currently no way to fetch an order or challenge’s
properties via URL. Prior to ACME’s adoption of “POST-as-GET” this was
doable via a plain GET to the URL, but that’s no longer possible.
If there’s a need, I’ll consider adding such logic to Net::ACME2.
(It’s trivial to add; I’d just like to keep things as
simple as possible.)
- Add (more) tests.

# SEE ALSO

[Crypt::LE](https://metacpan.org/pod/Crypt%3A%3ALE) is another ACME client library.

[CryptX](https://metacpan.org/pod/CryptX) provides this library’s primary cryptography backend.
[Crypt::Perl](https://metacpan.org/pod/Crypt%3A%3APerl) is used as a fallback and for X.509 operations.
See this distribution’s `/examples` directory for sample usage
to generate keys and CSRs.

[Net::ACME](https://metacpan.org/pod/Net%3A%3AACME) implements client logic for the variant of this
protocol that Let’s Encrypt first deployed.
