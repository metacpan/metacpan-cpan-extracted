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
use Net::ACME2::HTTP::Response ();
use Net::ACME2::PromiseUtil    ();
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

    $opts{'ua'} ||= do {
        require Net::ACME2::HTTP_Tiny;
        Net::ACME2::HTTP_Tiny->new( verify_SSL => $verify_SSL );
    };

    my $self = bless {
        _ua       => $opts{'ua'},
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

# promise
#GETs submit no data and thus are not signed.
sub get {
    my ( $self, $url ) = @_;

    return $self->_request( 'GET', $url );
}

# promise
# ACME spec 6.2: for all requests not signed using an existing account,
# e.g., newAccount
sub post_full_jwt {
    my $self = shift;

    return $self->_post( 'create_full_jws', @_ );
}

# promise
# ACME spec 6.2: for all requests signed using an existing account
sub post_key_id {
    my $self = shift;

    return $self->_post(
        'create_key_id_jws',
        @_,
    );
}

# promise
# ACME spec 7.3.5: key change uses a pre-built inner JWS as payload
sub post_key_change {
    my ($self, $url, $inner_jws) = @_;

    return $self->_post( 'create_key_id_jws', $url, $inner_jws );
}

sub update_key {
    my ($self, $new_key_obj) = @_;

    $self->{'_acme_key'} = $new_key_obj;
    delete $self->{'_jwt_maker'};

    return $self;
}

#----------------------------------------------------------------------

# promise
# POSTs are signed.
sub _post {
    my ( $self, $jwt_method, $url, $data, $opts_hr ) = @_;

    die Net::ACME2::X->create('Generic', "Need JWT method!") if !$jwt_method;

    # Needed now that the constructor allows instantiation
    # without “key”.
    die Net::ACME2::X->create('Generic', "Constructor needed \"key\" to do POST! ($url)") if !$self->{'_acme_key'};

    return Net::ACME2::PromiseUtil::then(
        $self->_create_jwt( $jwt_method, $url, $data ),
        sub {
            my $jws = shift;

            return Net::ACME2::PromiseUtil::do_then_catch(
                sub {
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
                    ),
                },
                sub {
                    $self->{'_retries_left'} = $_MAX_RETRIES;

                    return shift;
                },
                sub {
                    my ($err) = @_;

                    my $resp;

                    # NB: We mutate $self->{'_retries_left'} rather than
                    # using local() because this code may run inside a
                    # promise chain where local's dynamic scope doesn't
                    # extend across async callbacks.
                    if ( eval { $err->get('acme')->type() =~ m<:badNonce\z> } ) {
                        if (!$self->{'_retries_left'}) {
                            warn( "$url: Received “badNonce” error, and no retries left!\n" );
                        }
                        elsif ($self->{'_last_nonce'}) {

                            # This scenario seems worth a warn() because even if the
                            # retry succeeds, something probably went awry somewhere.

                            warn( "$url: Received “badNonce” error! Retrying ($self->{'_retries_left'} left) …\n" );

                            $self->{'_retries_left'}--;

                            # NB: The success of this depends on our having recorded
                            # the Replay-Nonce from the last response.
                            return $self->_post( $jwt_method, $url, $data, $opts_hr );
                        }
                        else {
                            warn( "$url: Received “badNonce” without a Replay-Nonce! (Server violates RFC 8555/6.5!) Cannot retry …" );
                        }
                    }

                    $self->{'_retries_left'} = $_MAX_RETRIES;

                    die $err;
                },
            );
        },
    );
}

# promise
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

sub _xform_http_error {
    my ($self, $exc) = @_;

    if ( eval { $exc->isa('Net::ACME2::X::HTTP::Protocol') } ) {

        $self->_consume_nonce_in_headers( $exc->get('headers') );

        #If the exception is able to be made into a Net::ACME2::Error,
        #then do so to get a nicer error message.
        my $acme_error = eval {
            Net::ACME2::Error->new(
                %{ JSON::decode_json( $exc->get('content') ) },
            );
        };
        my $json_parse_err = $@;

        if ($acme_error) {
            die Net::ACME2::X->create(
                'ACME',
                {
                    http => $exc,
                    acme => $acme_error,
                },
            );
        }

        if ($json_parse_err) {
            my $content = $exc->get('content');

            die Net::ACME2::X->create(
                'Generic',
                "Failed to decode ACME error ($json_parse_err); HTTP status ${\$exc->get('status')}: $content",
                { http => $exc },
            );
        }
    }

    die $exc;
}

# promise
# overridden in tests
sub _request {
    my ( $self, $type, @args ) = @_;

    return Net::ACME2::PromiseUtil::do_then_catch(
        sub { $self->_ua_request( $type, @args ) },
        sub {
            return Net::ACME2::HTTP::Response->new($_[0]);
        },
        sub { $self->_xform_http_error(@_) },
    );
}

# promise
sub _request_and_set_last_nonce {
    my ( $self, $type, $url, @args ) = @_;

    return Net::ACME2::PromiseUtil::then(
        $self->_request( $type, $url, @args ),
        sub {
            my ($resp) = @_;

            # NB: ACME’s replay protection works thus:
            #   - each server response includes a nonce
            #   - each request must include ONE of the nonces that have been sent
            #   - once used, a nonce can’t be reused
            #
            # This is subtly different from what was originally in mind (i.e., that
            # each request must use the most recently sent nonce). It implies that
            # GETs do not need to send nonces, though each GET will *receive* a
            # nonce that may be used.
            $self->{'_last_nonce'} = $resp->header($_NONCE_HEADER) or do {
                die Net::ACME2::X->create('Generic', "Received no $_NONCE_HEADER from $url!");
            };

            return $resp;
        },
    );
}

# promise
sub _get_first_nonce {
    my ($self) = @_;

    my $url = $self->{'_nonce_url'} or do {

        # Shouldn’t happen unless there’s an errant refactor.
        die Net::ACME2::X->create('Generic', 'Set newNonce URL first!');
    };

    return $self->_request_and_set_last_nonce( 'HEAD', $url );
}

# promise OR JWS itself.
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

    # In sync mode, we just throw away this value.
    # In async mode the undef is ignored, and a promise is honored.
    my $maybe_promise = $self->{'_last_nonce'} ? undef : $self->_get_first_nonce();

    return Net::ACME2::PromiseUtil::then(
        $maybe_promise,
        sub {

            # Ideally we’d wait until we’ve confirmed that this JWT reached
            # the server to delete the local nonce, but at this point a
            # failure to reach the server seems pretty edge-case-y. Even if
            # that happens, we’ll just request another nonce next time,
            # so no big deal.
            my $nonce = delete $self->{'_last_nonce'} or do {
                die "No nonce even after _get_first_nonce()!";
            };

            return $self->{'_jwt_maker'}->$jwt_method(
                key_id => $self->{'_key_id'},
                payload => $data,
                extra_headers => {
                    nonce => $nonce,
                    url => $url,
                },
            );
        },
    );
}

1;
