package Net::ACME2;

use strict;
use warnings;

=encoding utf-8

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

L<Crypt::Perl> provides all cryptographic operations that this library
needs using pure Perl. While this satisfies this module’s intent to be
as pure-Perl as possible, there are a couple of significant drawbacks
to this approach: firstly, it’s slower than XS-based code, and secondly,
it loses the security benefits of the vetting that more widely-used
cryptography libraries receive.

To address these problems, Net::ACME2 will, after parsing a key, look
for and prefer the following XS-based libraries for cryptography instead:

=over

=item * L<Crypt::OpenSSL::RSA> (based on L<OpenSSL|http://openssl.org>)

=item * L<CryptX> (based on L<LibTomCrypt|http://www.libtom.net/LibTomCrypt/>)

=back

If the above are unavailable to you, then you may be able to speed up
your L<Math::BigInt> installation; see that module’s documentation
for more details.

=cut

use Crypt::Format;
use MIME::Base64 ();

use Net::ACME2::AccountKey;

use Net::ACME2::HTTP;
use Net::ACME2::Order;
use Net::ACME2::Authorization;

our $VERSION = '0.35';

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

=cut

sub http_timeout {
    my $self = shift;

    return $self->{'_http'}->timeout(@_);
}

#----------------------------------------------------------------------

=head2 $url = I<CLASS>->get_terms_of_service()

Returns the URL for the terms of service. Callable as either
a class method or an instance method.

=cut

sub get_terms_of_service {
    my ($self) = @_;

    # We want to be able to call this as a class method.
    if (!ref $self) {
        $self = $self->_new_without_key_check();
    }

    my $dir = $self->_get_directory();

    # Exceptions here indicate an ACME violation and should be
    # practically nonexistent.
    my $url = $dir->{'meta'} or _die_generic('No “meta” in directory!');
    $url = $url->{'termsOfService'} or _die_generic('No “termsOfService” in directory metadata!');

    return $url;
}

#----------------------------------------------------------------------

=head2 $created_yn = I<OBJ>->create_account( %OPTS )

Creates an account using the ACME2 object’s key and the passed
%OPTS, which are as described in the ACME2 spec (cf. C<newAccount>).
Boolean values may be given as simple Perl booleans.

Returns 1 if the account is newly created
or 0 if the account already existed.

NB: C<create_new_account()> is an alias for this method.

=cut

sub create_account {
    my ($self, %opts) = @_;

    for my $name (newAccount_booleans()) {
        next if !exists $opts{$name};
        ($opts{$name} &&= JSON::true()) ||= JSON::false();
    }

    my $resp = $self->_post(
        'newAccount',
        \%opts,
    );

    $self->{'_key_id'} = $resp->header('location');

    $self->{'_http'}->set_key_id( $self->{'_key_id'} );

    return 0 if $resp->status() == _HTTP_OK;

    $resp->die_because_unexpected() if $resp->status() != _HTTP_CREATED;

    my $struct = $resp->content_struct();

    if ($struct) {
        for my $name (newAccount_booleans()) {
            next if !exists $struct->{$name};
            ($struct->{$name} &&= 1) ||= 0;
        }
    }

    return 1;
}

#----------------------------------------------------------------------

=head2 $order = I<OBJ>->create_order( %OPTS )

Returns a L<Net::ACME2::Order> object. %OPTS is as described in the
ACME spec (cf. C<newOrder>). Boolean values may be given as simple
Perl booleans.

NB: C<create_new_order()> is an alias for this method.

=cut

sub create_order {
    my ($self, %opts) = @_;

    $self->_require_key_id(\%opts);

    my $resp = $self->_post( 'newOrder', \%opts );

    $resp->die_because_unexpected() if $resp->status() != _HTTP_CREATED;

    return Net::ACME2::Order->new(
        id => $resp->header('location'),
        %{ $resp->content_struct() },
    );
}

#----------------------------------------------------------------------

=head2 $authz = I<OBJ>->get_authorization( $URL )

Fetches the authorization’s information based on the given $URL
and returns a L<Net::ACME2::Authorization> object.

The URL is as given by L<Net::ACME2::Order>’s C<authorizations()> method.

=cut

sub get_authorization {
    my ($self, $id) = @_;

    my $resp = $self->_post_as_get($id);

    return Net::ACME2::Authorization->new(
        id => $id,
        %{ $resp->content_struct() },
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

=head2 I<OBJ>->accept_challenge( $CHALLENGE )

Signal to the ACME server that the CHALLENGE is ready.

=cut

sub accept_challenge {
    my ($self, $challenge_obj) = @_;

    $self->_post_url(
        $challenge_obj->url(),
        {
            keyAuthorization => $self->make_key_authorization($challenge_obj),
        },
    );

    return;
}

#----------------------------------------------------------------------

=head2 $status = I<OBJ>->poll_authorization( $AUTHORIZATION )

Accepts a L<Net::ACME2::Authorization> instance and polls the
ACME server for that authorization’s status. The $AUTHORIZATION
object is then updated with the results of the poll.

As a courtesy, this returns the $AUTHORIZATION’s new C<status()>.

=cut

#This has to handle updates to the authz and challenge objects
*poll_authorization = *_poll_order_or_authz;

#----------------------------------------------------------------------

=head2 $status = I<OBJ>->finalize_order( $ORDER, $CSR )

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

    my $post = $self->_post_url(
        $order_obj->finalize(),
        {
            csr => $csr,
        },
    );

    my $content = $post->content_struct();

    $order_obj->update($content);

    return $order_obj->status();
}

#----------------------------------------------------------------------

=head2 $status = I<OBJ>->poll_order( $ORDER )

Like C<poll_authorization()> but handles a
L<Net::ACME2::Order> object instead.

=cut

*poll_order = *_poll_order_or_authz;

#----------------------------------------------------------------------

=head2 $cert = I<OBJ>->get_certificate_chain( $ORDER )

Fetches the $ORDER’s certificate chain and returns
it in the format implied by the
C<application/pem-certificate-chain> MIME type. See the ACME
protocol specification for details about this format.

=cut

sub get_certificate_chain {
    my ($self, $order) = @_;

    return $self->_post_as_get( $order->certificate() )->content();
}

#----------------------------------------------------------------------

sub _key_thumbprint {
    my ($self) = @_;

    return $self->{'_key_thumbprint'} ||= $self->_key_obj()->get_jwk_thumbprint();
}

sub _get_directory {
    my ($self) = @_;

    $self->{'_directory'} ||= do {
        my $dir_path = $self->DIRECTORY_PATH();
        $self->{'_http'}->get("https://$self->{'_host'}$dir_path")->content_struct();
    };

    my $new_nonce_url = $self->{'_directory'}{'newNonce'} or do {
        _die_generic('Directory is missing “newNonce”.');
    };

    $self->{'_http'}->set_new_nonce_url( $new_nonce_url );

    return $self->{'_directory'};
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

    my $get = $self->_post_as_get( $order_or_authz_obj->id() );

    my $content = $get->content_struct();

    $order_or_authz_obj->update($content);

    return $order_or_authz_obj->status();
}

sub _key_obj {
    my ($self) = @_;

    return $self->{'_key_obj'} ||= Net::ACME2::AccountKey->new($self->{'_key'});
}

sub _set_http {
    my ($self) = @_;

    $self->{'_http'} = Net::ACME2::HTTP->new(
        key => $self->{'_key'} && $self->_key_obj(),
        key_id => $self->{'_key_id'},
    );

    return;
}

our $_POST_METHOD;

sub _post {
    my ( $self, $link_name, $data ) = @_;

    my $post_method;
    $post_method = 'post_full_jwt' if grep { $link_name eq $_ } FULL_JWT_METHODS();

    # Since the $link_name will come from elsewhere in this module
    # there really shouldn’t be an error here, but just in case.
    my $url = $self->_get_directory()->{$link_name} or _die_generic("Unknown link name: “$link_name”");

    return $self->_post_url( $url, $data, $post_method );
}

sub _post_as_get {
    my ( $self, $url ) = @_;

    return $self->_post_url( $url, q<> );
}

sub _post_url {
    my ( $self, $url, $data, $opt_post_method ) = @_;

    #Do this in case we haven’t initialized the directory yet.
    #Initializing the directory is necessary to get a nonce.
    $self->_get_directory();

    my $post_method = $opt_post_method || 'post_key_id';

    return $self->{'_http'}->$post_method( $url, $data );
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

=item * Expose the Retry-After header via the module API.

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

L<Crypt::Perl> provides this library’s default cryptography backend.
See this distribution’s F</examples> directory for sample usage
to generate keys and CSRs.

L<Net::ACME> implements client logic for the variant of this
protocol that Let’s Encrypt first deployed.

=cut
