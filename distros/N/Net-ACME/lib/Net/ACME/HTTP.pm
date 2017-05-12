package Net::ACME::HTTP;

=encoding utf-8

=head1 NAME

Net::ACME::HTTP - transport logic for C<Net::ACME>.

=head1 SYNOPSIS

    my $resp = Net::ACME::HTTP->new()->get('https://url/to/endpoint');

    my $http_authn = Net::ACME::HTTP->new( key => $account_key );

    my $post_resp = $http_authn->post(
        'https://url/to/endpoint',
        { foo => 4 },   #i.e., the payload to send
        %opts,          #cf. HTTP::Tiny::request
    );

=head1 DESCRIPTION

This module handles communication with an ACME server at the HTTP level.
It handles the wrapping of POSTs in JWSes (JSON Wed Signatures).

Failure responses prompt exceptions. This includes cases like HTTP 409
from “new-reg”, which maybe isn’t an B<error> case so much as just
something to accommodate.

=cut

use strict;
use warnings;

use JSON ();

use Net::ACME::Crypt          ();
use Net::ACME::Error          ();
use Net::ACME::HTTP_Tiny      ();
use Net::ACME::HTTP::Response ();
use Net::ACME::Utils          ();
use Net::ACME::X              ();

#accessed from tests
our $_NONCE_HEADER = 'replay-nonce';

#Used in testing
our $verify_SSL = 1;

#NB: “key” isn’t needed if we’re just doing GETs.
sub new {
    my ( $class, %opts ) = @_;

    my $ua = Net::ACME::HTTP_Tiny->new( verify_SSL => $verify_SSL );

    my $self = bless {
        _ua       => $ua,
        _acme_key => $opts{'key'} && Net::ACME::Crypt::parse_key($opts{'key'}),
    }, $class;

    return bless $self, $class;
}

#GETs submit no data and thus are not signed.
sub get {
    my ( $self, $url ) = @_;

    return $self->_request_and_set_last_nonce( 'get', $url );
}

#POSTs are signed.
sub post {
    my ( $self, $url, $data, $opts_hr ) = @_;

    die "Constructor needed “key” to do POST! ($url)" if !$self->{'_acme_key'};

    my $jws = $self->_create_jws( JSON->new()->allow_nonref()->encode($data) );

    return $self->_request_and_set_last_nonce(
        'post',
        $url,
        { content => $jws },
        $opts_hr || (),
    );
}

#----------------------------------------------------------------------

sub _ua_request {
    my ( $self, $type, @args ) = @_;

    return $self->{'_ua'}->request( $type, @args );
}

#overridden in tests
sub _request {
    my ( $self, $type, @args ) = @_;

    my $resp;

    #cf. eval_bug.readme
    my $eval_err = $@;

    eval { $resp = $self->_ua_request( $type, @args ); };

    if ($@) {
        my $exc = $@;

        if ( eval { $exc->isa('Net::ACME::X::HTTP::Protocol') } ) {
            my $_nonce_header_lc = $_NONCE_HEADER;
            $_nonce_header_lc =~ tr<A-Z><a-z>;

            my $nonce = $exc->get('headers')->{$_nonce_header_lc};
            $self->{'_last_nonce'} = $nonce if $nonce;

            #If the exception is able to be made into a Net::ACME::Error,
            #then do so to get a nicer error message.
            my $acme_error = eval {
                Net::ACME::Error->new(
                    %{ JSON::decode_json( $exc->get('content') ) },
                );
            };

            my $detail;
            if ($acme_error) {
                $detail = $acme_error->detail();
                my $desc = $acme_error->description();
                if ($desc) {
                    $detail = sprintf "%s (%s)", $detail, $desc;
                }
            }
            else {
                $detail = $exc->get('content');
            }

            die Net::ACME::X::create(
                'Protocol',
                {
                    ( map { $_ => $exc->get($_) } qw( url status reason headers ) ),
                    type => $acme_error ? $acme_error->type() : '(unknown type)',
                    detail => $detail,
                }
            );
        }

        $@ = $exc;
        die;
    }

    $@ = $eval_err;

    return Net::ACME::HTTP::Response->new($resp);
}

sub _request_and_set_last_nonce {
    my ( $self, $type, @args ) = @_;

    my $resp = $self->_request( $type, @args );

    #NB: ACME’s replay protection works thus:
    #   - each server response includes a nonce
    #   - each request must include ONE of the nonces that have been sent
    #   - once used, a nonce can’t be reused
    #
    #This is subtly different from what was originally in mind (i.e., that
    #each request must use the most recently sent nonce). It implies that GETs
    #do not need to send nonces, though each GET will *receive* a nonce that
    #may be used.
    if ( my $nonce = $resp->header($_NONCE_HEADER) ) {
        $self->{'_last_nonce'} = $nonce;
    }

    return $resp;
}

sub _create_jws {
    my ( $self, $msg ) = @_;

    die "Need a nonce before JWS can be created!" if !$self->{'_last_nonce'};

    return Net::ACME::Crypt::create_jwt(
        key           => $self->{'_acme_key'},
        extra_headers => {
            nonce => $self->{'_last_nonce'},
            jwk   => $self->{'_acme_key'}->get_struct_for_public_jwk(),
        },
        payload => $msg,
    );
}

1;
