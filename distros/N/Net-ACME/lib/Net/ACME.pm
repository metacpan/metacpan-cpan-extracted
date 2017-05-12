package Net::ACME;

=encoding utf-8

=head1 NAME

Net::ACME - Client for the ACME protocol (e.g., L<Let’s Encrypt|http://letsencrypt.org>)

=head1 SYNOPSIS

    package MyACME::SomeService;

    sub _HOST { }   #return the name of the ACME host

    #See below for full examples.

=head1 DESCRIPTION

This module implements client logic (including SSL certificate issuance)
for the ACME protocol, the system for automated issuance of SSL
certificates used by Let’s Encrypt.

The methods of this class return objects that correspond to the
respective ACME resource:

=over 4

=item * C<register()>: C<Net::ACME::Registration>

=item * C<start_domain_authz()>: C<Net::ACME::Authorization::Pending>

=item * C<get_certificate()>: C<Net::ACME::Certificate> or C<Net::ACME::Certificate::Pending>

=back

=head1 WHY USE THIS MODULE?

=over 4

=item * Closely based on cPanel’s widely used Let’s Encrypt plugin.

=item * Support for both RSA and ECDSA encryption (via L<Crypt::Perl>).

=item * Thorough error-checking: any deviation from what the ACME protocol
expects is reported immediately via an exception.

=item * Well-defined object system, including typed, queryable exceptions.

=item * Extensive test coverage.

=item * Light memory footprint - no Moose/Moo/etc.

=item * No careless overwriting of globals like C<$@>, C<$!>, and C<$?>.
(Hopefully your code isn’t susceptible to this anyway, but it’s just a good
precaution.)

=item * All dependencies are either core or pure Perl. Net::ACME will run
anywhere that Perl runs!

=back

=head1 STATUS

This module is now well-tested and should be safe for use in your application.

=head1 CUSTOMIZATION

B<HTTPS options>: This module uses C<HTTP::Tiny> for its network operations.
In some instances it is desirable to specify custom C<SSL_options> in that
module’s constructor; to do this, populate
C<@Net::ACME::HTTP_Tiny::SSL_OPTIONS>.

=head1 URI vs. URL

This module uses “uri” for ACME-related objects and “url” for
HTTP-related ones. This apparent conflict is a result of maintaining
consistency with both the ACME specification (“uri”) and L<HTTP::Tiny> (“url”).

=head1 EXAMPLES

See the C<examples> directory in the distribution for complete, interactive
example scripts that also illustrate a bit of how ACME works.

See below for cut-paste-y examples.

=head1 EXAMPLE: REGISTRATION

    my $tos_url = Net::ACME::LetsEncrypt->get_terms_of_service();

    my $acme = Net::ACME::LetsEncrypt->new( key => $reg_rsa_pem );

    #Use this method any time you want to update contact information,
    #not just when you set up a new account.
    my $reg = $acme->register('mailto:me@example.com', 'mailto:who@example.com');

    $acme->accept_tos( $reg->uri(), $tos_url );

=head1 EXAMPLE: DOMAIN AUTHORIZATION & CERTIFICATE PROCUREMENT

    for my $domain (@domains) {
        my $authz_p = $acme->start_domain_authz($domain);

        for my $cmb_ar ( $authz_p->combinations() ) {

            #$cmb_ar is a set of challenges that the ACME server will
            #accept as proof of domain control. As of November 2016, these
            #sets all contain exactly one challenge each: “http-01”, etc.

            #Each member of @$cmb_ar is an instance of
            #Net::ACME::Challenge::Pending--maybe a subclass thereof such as
            #Net::ACME::Challenge::Pending::http_01.

            #At this point, you examine $cmb_ar and determine if this
            #combination is one that you’re interested in. You might try
            #something like:
            #
            #   next if @$cmb_ar > 1;
            #   next if $cmb_ar->[0]->type() ne 'http-01';

            #Once you’ve examined $cmb_ar and set up the appropriate response(s),
            #it’s time to tell the ACME server to send its challenge query.
            $acme->do_challenge($_) for @$cmb_ar;

            while (1) {
                if ( $authz_p->is_time_to_poll() ) {
                    my $poll = $authz_p->poll();

                    last if $poll->status() eq 'valid';

                    if ( $poll->status() eq 'invalid' ) {
                        my @failed = map { $_->error() } $poll->challenges();

                        warn $_->to_string() . $/ for @failed;

                        die "Failed authorization for “$domain”!";
                    }

                }

                sleep 1;
            }
        }
    }

    #Make a key and CSR.
    #Creation of CSRs is well-documented so won’t be discussed here.

    my $cert = $acme->get_certificate($csr_pem);

    #This shouldn’t actually be necessary for Let’s Encrypt,
    #but the ACME protocol describes it.
    while ( !$cert->pem() ) {
        sleep 1;
        next if !$cert->is_time_to_poll();
        $cert = $cert->poll() || $cert;
    }

=head1 TODO

=over 4

=item * Once the L<ACME specification|https://tools.ietf.org/html/draft-ietf-acme-acme>
is finalized, update this module to take advantage of the full specification.
As Let’s Encrypt’s L<Boulder|https://github.com/letsencrypt/boulder> is currently
the only widely-used ACME server, and that software is compatible with
L<the first draft of the ACME spec|https://tools.ietf.org/html/draft-ietf-acme-acme-01>,
there’s little reason to update for the time being.

=back

=head1 THANKS

=over 4

=item * cPanel, Inc. for permission to adapt their ACME framework for
public consumption.

=item * Stephen Ludin for developing and maintaining L<Protocol::ACME>, from which
this module took its inspiration.

=back

=head1 SEE ALSO

I am aware of the following additional CPAN modules that implement this protocol:

=over 4

=item * L<Protocol::ACME>

=item * L<Crypt::LE>

=item * L<WWW::LetsEncrypt>

=item * L<Mojo::ACME>

=back

=head1 REPOSITORY (FEEDBACK/BUGS)

L<https://github.com/FGasper/p5-Net-ACME>

=head1 AUTHOR

Felipe Gasper (FELIPE)

=head1 LICENSE

This module is licensed under the same terms as Perl.

=cut

use strict;
use warnings;

use Crypt::Format     ();
use JSON              ();
use MIME::Base64      ();

use Net::ACME::Authorization::Pending      ();
use Net::ACME::Certificate                 ();
use Net::ACME::Certificate::Pending        ();
use Net::ACME::Constants                   ();
use Net::ACME::Challenge::Pending::http_01 ();
use Net::ACME::HTTP                        ();
use Net::ACME::Registration                ();
use Net::ACME::Utils                       ();
use Net::ACME::X                           ();

our $VERSION;
*VERSION = \$Net::ACME::Constants::VERSION;

*_to_base64url = \&MIME::Base64::encode_base64url;

sub new {
    my ( $class, %opts ) = @_;

    my $self = {
        _host => $class->_HOST(),
        _key  => $opts{'key'},
    };

    bless $self, $class;

    $self->_set_ua();

    return $self;
}

sub _HOST { die 'Not Implemented!' }

sub accept_tos {
    my ( $self, $reg_uri, $tos_url ) = @_;

    my $resp = $self->_post_url(
        $reg_uri,
        {
            resource  => 'reg',
            agreement => $tos_url,
        },
    );

    $resp->die_because_unexpected() if $resp->status() != 202;

    return;
}

#Returns a Net::ACME::Registration instance whose
#terms_of_service() will be current/useful.
sub register {
    my ( $self, @contacts ) = @_;

    my $payload = {
        resource => 'new-reg',
    };

    if (@contacts) {
        $payload->{'contact'} = \@contacts;
    }

    my ( $resp, $reg_uri );

    $resp = $self->_post( 'new-reg', $payload );

    if ( $resp->status() != 201 ) {
        $resp->die_because_unexpected();
    }

    $reg_uri = $resp->header('location');

    #We don’t save the terms-of-service here because the terms
    #of service might be updated between now and the next time we
    #load this data. It’s better to make the caller call
    #get_terms_of_service() each time.
    my @metadata = (
        uri => $reg_uri,
        %{ $resp->content_struct() },
    );

    #Even though we didn’t save the “terms-of-service” URL from
    #this registration object, we might as well hold onto it
    #for the current process to save a call to get_terms_of_service().
    return Net::ACME::Registration->new(
        @metadata,
        terms_of_service => { $resp->links() }->{'terms-of-service'},
    );
}

#NOTE: This doesn’t actually seem to work with Let’s Encrypt.
#The POST keeps coming back with a 202 status rather than 200.
#(Looks like Boulder doesn’t handle this function yet?)
#sub rollover_key {
#    my ($self, $reg_uri) = @_;
#
#    my $new_key = $self->create_key_pem();
#
#    my $sub_payload = {
#        resource => 'reg',
#        oldKey => $self->jwk_thumbprint(),
#    };
#
#    my $resp = $self->_post_url(
#        $reg_uri,
#        {
#            resource => 'reg',
#            newKey => Net::ACME::Utils::get_jws_data(
#                $new_key,
#                undef,
#                JSON::encode_json($sub_payload),
#            ),
#        },
#    );
#
#    if ($resp->status() != 200) {
#        die "Incorrect status: " . $resp->status() . $/ . $resp->content();
#    }
#
#    $self->{'_account_key'} = $new_key;
#    $self->_set_ua();
#
#    return $new_key;
#}

sub start_domain_authz {
    my ( $self, $domain_name ) = @_;

    my $resp = $self->_post(
        'new-authz',
        {
            resource   => 'new-authz',
            identifier => {
                type  => 'dns',
                value => $domain_name,
            },
        },
    );

    $resp->die_because_unexpected() if $resp->status() != 201;

    my $content = $resp->content_struct();

    return Net::ACME::Authorization::Pending->new(
        uri          => $resp->header('location'),
        combinations => $content->{'combinations'},
        challenges   => [
            map {
                my $class = 'Net::ACME::Challenge::Pending';
                if ( $_->{'type'} eq 'http-01' ) {
                    $class .= '::http_01';
                }
                $class->new(%$_);
              } @{ $content->{'challenges'} },
        ],
    );
}

#NOTE: This doesn’t actually work with Boulder (Let’s Encrypt) because
#that server implements acme-01. Deletion of an authz was added in acme-02.
#
#It is critical, though, that when this doesn’t work we still request the
#challenge against the authz so that the LE account doesn’t exceed a rate
#limit. (cf. COBRA-3273)
sub delete_authz {
    my ( $self, $authz ) = @_;

    #sanity
    if ( !Net::ACME::Utils::thing_isa($authz, 'Net::ACME::Authorization::Pending') ) {
        die "Must be a pending authz object, not “$authz”!";
    }

    my $resp = $self->_post_url(
        $authz->uri(),
        {
            resource => 'authz',
            delete   => JSON::true(),
        },
    );

    $resp->die_because_unexpected() if $resp->status() != 200;

    return;
}

sub do_challenge {
    my ( $self, $challenge_obj ) = @_;

    my ( $token, $uri ) = map { $challenge_obj->$_() } qw( token uri );

    my $key_obj = Net::ACME::Crypt::parse_key($self->{'_key'});

    $self->{'_key_jwk'} ||= $key_obj->get_struct_for_public_jwk();

    my $resp = $self->_post_url(
        $uri,
        {
            resource         => 'challenge',
            keyAuthorization => $challenge_obj->make_key_authz( $self->{'_key_jwk'} ),
        },
    );

    $resp->die_because_unexpected() if $resp->status() != 202;

    return;
}

sub get_certificate {
    my ( $self, $csr_pem ) = @_;

    my $csr_der = Crypt::Format::pem2der($csr_pem);

    my $resp = $self->_post(
        'new-cert',
        {
            resource => 'new-cert',
            csr      => _to_base64url($csr_der),
        },
    );

    my $status = $resp->status();

    #NB: Let’s Encrypt doesn’t seem to need this,
    #but per the ACME spec it *could* work this way.
    if ( $status == 202 ) {
        my $pcert = Net::ACME::Certificate::Pending->new(
            uri         => $resp->header('location'),
            retry_after => $resp->header('retry-after'),
        );

        while (1) {
            if ( $pcert->is_time_to_poll() ) {
                my $c = $pcert->poll();
                return $c if $c;
            }
            sleep 1;
        }
    }

    if ( $status == 201 ) {
        return Net::ACME::Certificate->new(
            content         => $resp->content(),
            type            => $resp->header('content-type'),
            issuer_cert_uri => { $resp->links() }->{'up'},
        );
    }

    $resp->die_because_unexpected();

    return;
}

#This isn’t needed yet, nor is it useful because
#Let’s Encrypt (i.e., Boulder) doesn’t support it.
#Once Boulder supports this, we should switch to it
#in favor of the LE-specific logic in LetsEncrypt.pm.
#
#cf. https://ietf-wg-acme.github.io/acme/#rfc.section.6.1.1
#sub get_terms_of_service {
#    my ($self) = @_;
#
#    my $dir = $self->_get_directory();
#    my $url = $self->_get_directory()->{'meta'} or die 'No “meta” in directory!';
#    $url = $url->{'terms-of-service'} or die 'No “terms-of-service” in directory metadata!';
#
#    return $url;
#}

#----------------------------------------------------------------------

sub _set_ua {
    my ($self) = @_;
    $self->{'_ua'} = Net::ACME::HTTP->new(
        key => $self->{'_key'},
    );

    return;
}

#TODO: cache
sub _get_directory {
    my ($self) = @_;

    return $self->{'_directory'} ||= $self->{'_ua'}->get("https://$self->{'_host'}/directory")->content_struct();
}

sub _post {
    my ( $self, $link_name, $data ) = @_;

    my $url = $self->_get_directory()->{$link_name} or die "Unknown link name: “$link_name”";

    return $self->_post_url( $url, $data );
}

#mocked in tests
sub _post_url {
    my ( $self, $url, $data ) = @_;

    #Do this in case we haven’t initialized the directory yet.
    #Initializing the directory is necessary to get a nonce.
    $self->_get_directory();

    return $self->{'_ua'}->post( $url, $data );
}

1;
