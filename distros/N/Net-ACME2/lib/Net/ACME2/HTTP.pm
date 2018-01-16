package Net::ACME2::HTTP;

=encoding utf-8

=head1 NAME

Net::ACME2::HTTP - transport logic for C<Net::ACME2>.

=head1 SYNOPSIS

    my $resp = Net::ACME2::HTTP->new()->get('https://url/to/endpoint');

    my $http_authn = Net::ACME2::HTTP->new( key => $account_key );

    my $post_resp = $http_authn->post(
        'https://url/to/endpoint',
        { foo => 4 },   #i.e., the payload to send
        %opts,          #cf. HTTP::Tiny::request
    );

=head1 DESCRIPTION

This module handles communication with an ACME server at the HTTP level.
It handles the wrapping of POSTs in JWSes (JSON Web Signatures).

=cut

use strict;
use warnings;

use Crypt::Perl::PK ();
use JSON ();

use Net::ACME2::Error          ();
use Net::ACME2::HTTP_Tiny      ();
use Net::ACME2::HTTP::Response ();
use Net::ACME2::X              ();

#accessed from tests
our $_NONCE_HEADER = 'replay-nonce';

#Used in testing
our $verify_SSL = 1;

#NB: “key” isn’t needed if we’re just doing GETs.
sub new {
    my ( $class, %opts ) = @_;

    die 'need “key”!' if !$opts{'key'};

    my $ua = Net::ACME2::HTTP_Tiny->new( verify_SSL => $verify_SSL );

    my $self = bless {
        _ua       => $ua,
        _acme_key => $opts{'key'},
        _key_id => $opts{'key_id'},
        _jws_format => $opts{'jws_format'},
    }, $class;

    return bless $self, $class;
}

sub set_key_id {
    my ($self, $key_id) = @_;

    $self->{'_key_id'} = $key_id;

    return $self;
}

#GETs submit no data and thus are not signed.
sub get {
    my ( $self, $url ) = @_;

    return $self->_request_and_set_last_nonce( 'GET', $url );
}

sub post_full_jwt {
    my $self = shift;

    return $self->_post( 'create_full_jws', @_ );
}

sub post_key_id {
    my $self = shift;

    return $self->_post(
        'create_key_id_jws',
        @_,
    );
}

#----------------------------------------------------------------------

#POSTs are signed.
sub _post {
    my ( $self, $jwt_method, $url, $data, $opts_hr ) = @_;

    die "Constructor needed “key” to do POST! ($url)" if !$self->{'_acme_key'};

    my $jws = $self->_create_jwt( $jwt_method, $url, $data );

    local $opts_hr->{'headers'}{'Content-Type'} = 'application/jose+json';

    return $self->_request_and_set_last_nonce(
        'POST',
        $url,
        { content => $jws },
        $opts_hr || (),
    );
}

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

    if (ref $@) {
        my $exc = $@;

        if ( eval { $exc->isa('Net::ACME2::X::HTTP::Protocol') } ) {
            my $_nonce_header_lc = $_NONCE_HEADER;
            $_nonce_header_lc =~ tr<A-Z><a-z>;

            my $nonce = $exc->get('headers')->{$_nonce_header_lc};
            $self->{'_last_nonce'} = $nonce if $nonce;

            #If the exception is able to be made into a Net::ACME2::Error,
            #then do so to get a nicer error message.
            my $acme_error = eval {
                Net::ACME2::Error->new(
                    %{ JSON::decode_json( $exc->get('content') ) },
                );
            };

            if ($acme_error) {
                die Net::ACME2::X->create(
                    'ACME',
                    {
                        http => $exc,
                        acme => $acme_error,
                    },
                );
            }
        }

        $@ = $exc;
        die;
    }

    $@ = $eval_err;

    return Net::ACME2::HTTP::Response->new($resp);
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

sub _create_jwt {
    my ( $self, $jwt_method, $url, $data ) = @_;

    die "Need a nonce before JWS can be created!" if !$self->{'_last_nonce'};

    $self->{'_jwt_maker'} ||= do {
        my $class;

        if ($self->{'_acme_key'}->isa('Crypt::Perl::RSA::PrivateKey')) {
            $class = 'Net::ACME2::JWTMaker::RSA';
        }
        elsif ($self->{'_acme_key'}->isa('Crypt::Perl::ECDSA::PrivateKey')) {
            $class = 'Net::ACME2::JWTMaker::ECC';
        }
        else {
            die "Unknown key “$self->{'_acme_key'}”";
        }

        if (!$class->can('new')) {
            require Module::Load;
            Module::Load::load($class);
        }

        $class->new(
            key => $self->{'_acme_key'},
            format => $self->{'_jws_format'},
        );
    };

    return $self->{'_jwt_maker'}->$jwt_method(
        key_id => $self->{'_key_id'},
        payload => $data,
        extra_headers => {
            nonce => $self->{'_last_nonce'},
            url => $url,
        },
    );
}

1;
