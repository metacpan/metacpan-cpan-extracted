package Net::ACME2;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::ACME2 - L<IETF|https://www.ietf.org>-standard ACME (Let’s Encrypt) client

X<Lets Encrypt> X<Let's Encrypt> X<letsencrypt>

=head1 SYNOPSIS

    package SomeCA::ACME;

    use parent qw( Net::ACME2 );

    use constant {
        HOST => 'acme.someca.net',
        DIRECTORY_PATH => '/acme-directory',
    };

    package main;

    my $acme = SomeCA::ACME->new(
        key => $account_key_pem_or_der,
        key_id => undef,
    );

    #for a new account
    {
        my $terms_url = $acme->get_terms_of_service();

        $acme->create_new_account(
            termsOfServiceAgreed => 1,
        );
    }

    #Save $acme->key_id() somewhere so you can use it again.

    my $order = $acme->create_new_order(
        identifiers => [
            { type => 'dns', value => '*.example.com' },
        ],
    );

    my $authz = $acme->get_authorization( ($order->authorizations())[0] );

    my @challenges = $authz->challenges();

    # ... Pick a challenge, and satisfy it.

    $acme->accept_challenge($challenge);

    sleep 1 while !$acme->poll_authorization($authz);

    # ... Make a key and CSR for *.example.com

    $acme->finalize_order($order, $csr_pem_or_der);

    while ($order->status() ne 'valid') {
        sleep 1;
        $acme->poll_order($order);
    }

    my $certificate_url = $order->certificate();

    # ... Download your certificate! :)

See F</examples> in the distribution for a more fleshed-out example.

To use L<Let’s Encrypt|http://letsencrypt.org>, see
L<Net::ACME2::LetsEncrypt>.

=head1 DESCRIPTION

This library implements client logic for the L<IETF|https://www.ietf.org>-standard ACME
(Automated Certificate Management Environment) protocol. As of this
writing, that protocol remains in development; the latest draft will
be available from L<https://datatracker.ietf.org/doc/draft-ietf-acme-acme/>.

Net::ACME2 derives from L<Net::ACME>, which implements the
(significantly different) earlier draft of that protocol as initially
deployed by L<Let’s Encrypt|http://letsencrypt.org>.

Net::ACME2 is pure Perl, and all of its dependencies are either pure Perl
or core modules.

=head1 STATUS

This is a “first-stab”, alpha-grade implementation. This
distribution, like the underlying protocol, is very much still
subject to change.

=head1 FEATURES

=over

=item * This is a pure-Perl solution, all of whose dependencies are either
core modules or pure-Perl themselves. Net::ACME2 will run anywhere that Perl
runs. :)

=item * Support for both ECDSA and RSA encrytion.

=item * Comprehensive error handling with typed, L<X::Tiny>-based exceptions.

=back

=head1 ERROR HANDLING

All thrown exceptions are instances of L<Net::ACME2::X::Base>.
Specific error classes aren’t yet defined.

=cut

use Crypt::Format ();
use MIME::Base64 ();
use Types::Serialiser ();

use Net::ACME2::Constants ();
use Net::ACME2::HTTP ();
use Net::ACME2::Order ();
use Net::ACME2::Authorization ();

our $VERSION;
*VERSION = *Net::ACME2::Constants::VERSION;

use constant {
    JWS_FORMAT => undef,

    _JWK_THUMBPRINT_DIGEST => 'sha256',
};

use constant newAccount_booleans => qw(
    termsOfServiceAgreed
    onlyReturnExisting
);

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
user. PEM or DER format.

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

    die 'Need “key”!' if !$opts{'key'};

    my $self = {
        _host => $class->HOST(),
        _key  => $opts{'key'},
        _key_id => $opts{'key_id'},
        _directory => $opts{'directory'},
    };

    bless $self, $class;

    $self->_set_ua();

    return $self;
}

=head2 I<OBJ>->key_id()

Returns the object’s cached key ID, either as given at instantiation
or as fetched in C<create_new_account()>.

=cut

sub key_id {
    my ($self) = @_;

    return $self->{'_key_id'};
}

=head2 I<CLASS_OR_OBJ>->get_terms_of_service()

Callable as either an instance method or a class method.
Returns the URL for the terms of service.

B<NOTE:> For L<Let’s Encrypt|http://letsencrypt.org> you can
unofficially resolve against
L<https://acme-v01.api.letsencrypt.org/terms> to see the terms
of service.

=cut

sub get_terms_of_service {
    my ($self) = @_;

    #We want to be able to call this as a class method.
    if (!ref $self) {
        $self = $self->new();
    }

    my $dir = $self->_get_directory();
    my $url = $self->_get_directory()->{'meta'} or die 'No “meta” in directory!';
    $url = $url->{'termsOfService'} or die 'No “terms-of-service” in directory metadata!';

    return $url;
}

=head2 I<OBJ>->create_new_account( %OPTS )

Creates a new account using the ACME2 object’s key and the passed
%OPTS, which are as described in the ACME2 spec (cf. C<newAccount>).
Boolean values may be given as simple Perl booleans.

Returns 1 if the account is newly created
or 0 if the account already existed.

=cut

sub create_new_account {
    my ($self, %opts) = @_;

    $opts{$_} &&= Types::Serialiser::true() for newAccount_booleans();

    my $resp = $self->_post(
        'newAccount',
        \%opts,
    );

    $self->{'_key_id'} = $resp->header('location');

    $self->{'_ua'}->set_key_id( $self->{'_key_id'} );

    return 0 if $resp->status() == 200;

    $resp->die_because_unexpected() if $resp->status() != 201;

    my $struct = $resp->content_struct();

    if ($struct) {
        $struct->{$_} = !!$struct->{$_} for newAccount_booleans();
    }

    return 1;
}

#sub update_account {
#    my ($self, %opts) = @_;
#
#    $self->_require_key_id(\%opts);
#
#    my $set = $self->_post_url(
#        $opts{'kid'},
#        \%opts,
#    );
#
#    return $set;
#}

=head2 I<OBJ>->create_new_order( %OPTS )

Returns a L<Net::ACME2::Order> object. %OPTS is as described in the
ACME spec (cf. C<newOrder>). Boolean values may be given as simple
Perl booleans.

=cut

sub create_new_order {
    my ($self, %opts) = @_;

    $self->_require_key_id(\%opts);

    my $resp = $self->_post( 'newOrder', \%opts );

    $resp->die_because_unexpected() if $resp->status() != 201;

    return Net::ACME2::Order->new(
        id => $resp->header('location'),
        %{ $resp->content_struct() },
    );
}

=head2 I<OBJ>->get_authorization( URL )

Fetches the authorization’s information based on the given URL
and returns a L<Net::ACME2::Authorization> object.

The URL is as given by L<Net::ACME2::Order>.

=cut

sub get_authorization {
    my ($self, $id) = @_;

    my $resp = $self->{'_ua'}->get($id);

    return Net::ACME2::Authorization->new(
        id => $id,
        %{ $resp->content_struct() },
    );
}

#Server may not support! (Pebble doesn’t, and LE won’t?)
#sub create_new_authorization {
#    my ($self, $type, $value) = @_;
#
#    my %opts = (
#        identifier => { type => $type, value => $value },
#    );
#
#    $self->_require_key_id(\%opts);
#
#    return $self->_post( 'newAuthz', \%opts );
#}

#TODO: separate distribution?
#sub __unix2iso {
#    my ($unix) = @_;
#
#    my (@smhdmy) = gmtime $unix;
#    $smhdmy[5] += 1900;
#    $smhdmy[4]++;
#
#    return join( q<>,
#        join( '-', @smhdmy[ 5, 4, 3 ] ),
#        'T',
#        join( ':', @smhdmy[ 2, 1, 0 ] ),
#        'Z',
#    );
#}

=head2 I<OBJ>->make_key_authorization( CHALLENGE )

Accepts an instance of L<Net::ACME2::Challenge> and returns
a key authorization string suitable for handling the given CHALLENGE.
See F</examples> in the distribution for example usage.

If you’re using HTTP authorization and are on the same server as the
domains’ document roots, then look at the handler logic in
L<Net::ACME2::Challenge::http_01> for a potentially simpler way to
handle HTTP challenges.

=cut

sub make_key_authorization {
    my ($self, $challenge_obj) = @_;

    die 'Need a challenge object!' if !$challenge_obj;

    return $challenge_obj->token() . '.' . $self->_key_thumbprint();
}

=head2 I<OBJ>->accept_challenge( CHALLENGE )

Signal to the ACME server that the CHALLENGE is ready.

=cut

sub accept_challenge {
    my ($self, $challenge_obj) = @_;

    my $post = $self->_post_url(
        $challenge_obj->url(),
        {
            keyAuthorization => $self->make_key_authorization($challenge_obj),
        },
    );

    return;
}

=head2 I<OBJ>->poll_authorization( AUTHORIZATION )

Accepts a L<Net::ACME2::Authorization> instance and polls the
ACME server for that authorization’s status. The AUTHORIZATION
object is then updated with the results of the poll.

=cut

#This has to handle updates to the authz and challenge objects
*poll_authorization = *_poll_order_or_authz;

=head2 I<OBJ>->finalize_order( ORDER, CSR )

Finalizes an order and updates the ORDER object with the returned
status. The CSR may be in either DER or PEM format.

ORDER may have C<status()> of C<valid> after this operation,
or you may need to C<poll_order()>.

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

    return;
}

=head2 I<OBJ>->poll_order( ORDER )

Like C<poll_authorization()> but handles a
L<Net::ACME2::Order> object instead.

=cut

*poll_order = *_poll_order_or_authz;

#----------------------------------------------------------------------

sub _key_thumbprint {
    my ($self) = @_;

    return $self->{'_key_thumbprint'} ||= $self->_key_obj()->get_jwk_thumbprint( _JWK_THUMBPRINT_DIGEST() );
}

sub _get_directory {
    my ($self) = @_;

    return $self->{'_directory'} ||= do {
        my $dir_path = $self->DIRECTORY_PATH();
        $self->{'_ua'}->get("https://$self->{'_host'}$dir_path")->content_struct();
    };
}

sub _require_key_id {
    my ($self, $opts_hr) = @_;

    $opts_hr->{'_key_id'} = $self->{'_key_id'} or do {
        die 'No key ID has been set. Either pass “key_id” to new(), or create_new_account().';
    };

    return
}

sub _poll_order_or_authz {
    my ($self, $order_or_authz_obj) = @_;

    my $get = $self->{'_ua'}->get( $order_or_authz_obj->id() );

    my $content = $get->content_struct();

    $order_or_authz_obj->update($content);

    my $status = $order_or_authz_obj->status();

    return 1 if $status eq 'valid';
    return 0 if $status eq 'pending' || $status eq 'processing';

    use Data::Dumper;
    die Dumper $order_or_authz_obj; #TODO
}

sub _key_obj {
    my ($self) = @_;

    return $self->{'_key_obj'} ||= Crypt::Perl::PK::parse_key($self->{'_key'});
}

sub _set_ua {
    my ($self) = @_;

    $self->{'_ua'} = Net::ACME2::HTTP->new(
        key => $self->_key_obj(),
        key_id => $self->{'_key_id'},
        jws_format => $self->JWS_FORMAT(),
    );

    return;
}

our $_POST_METHOD;

sub _post {
    my ( $self, $link_name, $data ) = @_;

    my $post_method;
    $post_method = 'post_full_jwt' if grep { $link_name eq $_ } FULL_JWT_METHODS();

    my $url = $self->_get_directory()->{$link_name} or die "Unknown link name: “$link_name”";

    return $self->_post_url( $url, $data, $post_method );
}

sub _post_url {
    my ( $self, $url, $data, $opt_post_method ) = @_;

    #Do this in case we haven’t initialized the directory yet.
    #Initializing the directory is necessary to get a nonce.
    $self->_get_directory();

    my $post_method = $opt_post_method || 'post_key_id';

    return $self->{'_ua'}->$post_method( $url, $data );
}

1;

=head1 TODO

=over

=item * Re-evaluate once there is a production server in place.

=item * Add pre-authorization support if there is ever a production
use for it.

=item * Tighten up challenge failure response.

=item * Add (more) tests.

=back

=head1 SEE ALSO

L<Crypt::Perl> provides pure-Perl cryptography for this library. See the
present library distribution’s F</examples> directory for sample usage
to generate CSRs.

=cut
