package Net::ACME2::HTTP;

=encoding utf-8

=head1 NAME

Net::ACME2::HTTP - transport logic for C<Net::ACME2>.

=head1 DESCRIPTION

This module handles communication with an ACME server at the HTTP level.
It wraps POSTs in JWSes (JSON Web Signatures) as needed.

There should be no reason to interact with this class in production.

=cut

use strict;
use warnings;

use JSON ();

use Net::ACME2::Error          ();
use Net::ACME2::HTTP_Tiny      ();
use Net::ACME2::HTTP::Response ();
use Net::ACME2::X              ();

use constant _CONTENT_TYPE => 'application/jose+json';

#accessed from tests
our $_NONCE_HEADER = 'replay-nonce';

#Used in testing
our $verify_SSL = 1;

#NB: “key” isn’t needed if we’re just doing GETs.
sub new {
    my ( $class, %opts ) = @_;

    my $ua = Net::ACME2::HTTP_Tiny->new( verify_SSL => $verify_SSL );

    my $self = bless {
        _ua       => $ua,
        _acme_key => $opts{'key'},
        _key_id => $opts{'key_id'},
    }, $class;

    return bless $self, $class;
}

sub set_key_id {
    my ($self, $key_id) = @_;

    $self->{'_key_id'} = $key_id;

    return $self;
}

sub set_new_nonce_url {
    my ($self, $url) = @_;

    $self->{'_nonce_url'} = $url;

    return $self;
}

#GETs submit no data and thus are not signed.
sub get {
    my ( $self, $url ) = @_;

    return $self->_request( 'GET', $url );
}

# ACME spec 6.2: for all requests not signed using an existing account,
# e.g., newAccount
sub post_full_jwt {
    my $self = shift;

    return $self->_post( 'create_full_jws', @_ );
}

# ACME spec 6.2: for all requests signed using an existing account
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

    # Needed now that the constructor allows instantiation
    # without “key”.
    die "Constructor needed “key” to do POST! ($url)" if !$self->{'_acme_key'};

    my $jws = $self->_create_jwt( $jwt_method, $url, $data );

    local $opts_hr->{'headers'}{'Content-Type'} = 'application/jose+json';

    return $self->_request_and_set_last_nonce(
        'POST',
        $url,
        {
            content => $jws,
            headers => {
                'content-type' => _CONTENT_TYPE,
            },
        },
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

    # Check ref() first to avoid potentially running overload.pm’s
    # stringification.
    if (ref($@) || $@) {
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
    my ( $self, $type, $url, @args ) = @_;

    my $resp = $self->_request( $type, $url, @args );

    #NB: ACME’s replay protection works thus:
    #   - each server response includes a nonce
    #   - each request must include ONE of the nonces that have been sent
    #   - once used, a nonce can’t be reused
    #
    #This is subtly different from what was originally in mind (i.e., that
    #each request must use the most recently sent nonce). It implies that GETs
    #do not need to send nonces, though each GET will *receive* a nonce that
    #may be used.
    $self->{'_last_nonce'} = $resp->header($_NONCE_HEADER) or do {
        die Net::ACME2::X->create('Generic', "Received no $_NONCE_HEADER from $url!");
    };

    return $resp;
}

sub _get_first_nonce {
    my ($self) = @_;

    my $url = $self->{'_nonce_url'} or do {

        # Shouldn’t happen unless there’s an errant refactor.
        die Net::ACME2::X->create('Set newNonce URL first!');
    };

    $self->_request_and_set_last_nonce( 'HEAD', $url );

    return;
}

sub _create_jwt {
    my ( $self, $jwt_method, $url, $data ) = @_;

    $self->_get_first_nonce() if !$self->{'_last_nonce'};

    $self->{'_jwt_maker'} ||= do {
        my $class;

        my $key_type = $self->{'_acme_key'}->get_type();

        if ($key_type eq 'rsa') {
            $class = 'Net::ACME2::JWTMaker::RSA';
        }
        elsif ($key_type eq 'ecdsa') {
            $class = 'Net::ACME2::JWTMaker::ECC';
        }
        else {

            # As of this writing, Crypt::Perl only does RSA and ECDSA keys.
            # If we get here, it’s possible that Crypt::Perl now supports
            # an additional key type that this library doesn’t recognize.
            die Net::ACME2::X->create('Generic', "Unrecognized key type: “$key_type”");
        }

        if (!$class->can('new')) {
            require Module::Runtime;
            Module::Runtime::use_module($class);
        }

        $class->new(
            key => $self->{'_acme_key'},
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
