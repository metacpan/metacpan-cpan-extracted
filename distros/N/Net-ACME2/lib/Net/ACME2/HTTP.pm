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

my $_MAX_RETRIES = 5;

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

        _retries_left => $_MAX_RETRIES,
    }, $class;

    return bless $self, $class;
}

sub timeout {
    my $self = shift;

    return $self->{'_ua'}->timeout(@_);
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

    my $pre_err = $@;

    my $resp = eval {
        $self->_request_and_set_last_nonce(
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
    };

    my $err;

    if (!defined $resp) {
        $err = $@;

        if ( eval { $err->get('acme')->type() =~ m<:badNonce\z> } ) {
            if (!$self->{'_retries_left'}) {
                warn( "$url: Received “badNonce” error, and no retries left!\n" );
            }
            elsif ($self->{'_last_nonce'}) {

                # This scenario seems worth a warn() because even if the
                # retry succeeds, something probably went awry somewhere.

                warn( "$url: Received “badNonce” error! Retrying ($self->{'_retries_left'} left) …\n" );

                local $self->{'_retries_left'} = $self->{'_retries_left'} - 1;

                # NB: The success of this depends on our having recorded
                # the Replay-Nonce from the last response.
                $resp = $self->_post(@_[ 1 .. $#_ ]);
            }
            else {
                warn( "$url: Received “badNonce” without a Replay-Nonce! (Server violates RFC 8555/6.5!) Cannot retry …" );
            }
        }
    }

    if (!defined $resp) {
        $@ = $err;
        die;
    }

    $@ = $pre_err;

    return $resp;
}

sub _ua_request {
    my ( $self, $type, @args ) = @_;

    return $self->{'_ua'}->request( $type, @args );
}

sub _consume_nonce_in_headers {
    my ($self, $headers_hr) = @_;

    my $_nonce_header_lc = $_NONCE_HEADER;
    $_nonce_header_lc =~ tr<A-Z><a-z>;

    my $nonce = $headers_hr->{$_nonce_header_lc};

    $self->{'_last_nonce'} = $nonce if $nonce;

    return;
}

#overridden in tests
sub _request {
    my ( $self, $type, @args ) = @_;

    my $resp;

    #cf. eval_bug.readme
    my $eval_err = $@;

    eval { $resp = $self->_ua_request( $type, @args ); 1 } or do {
        my $exc = $@;

        if ( eval { $exc->isa('Net::ACME2::X::HTTP::Protocol') } ) {

            $self->_consume_nonce_in_headers( $exc->get('headers') );

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
    };

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
        die Net::ACME2::X->create('Generic', 'Set newNonce URL first!');
    };

    $self->_request_and_set_last_nonce( 'HEAD', $url );

    return;
}

sub _create_jwt {
    my ( $self, $jwt_method, $url, $data ) = @_;

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

    $self->_get_first_nonce() if !$self->{'_last_nonce'};

    # Ideally we’d wait until we’ve confirmed that this JWT reached the
    # server to delete the local nonce, but at this point a failure to
    # reach the server seems pretty edge-case-y. Even if that happens,
    # we’ll just request another nonce next time, so no big deal.
    my $nonce = delete $self->{'_last_nonce'};

    # For testing badNonce retry:
    # $nonce = reverse($nonce) if $self->{'_retries_left'};
    # $nonce = reverse($nonce);

    return $self->{'_jwt_maker'}->$jwt_method(
        key_id => $self->{'_key_id'},
        payload => $data,
        extra_headers => {
            nonce => $nonce,
            url => $url,
        },
    );
}

1;
