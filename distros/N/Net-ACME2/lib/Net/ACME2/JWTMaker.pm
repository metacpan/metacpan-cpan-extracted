package Net::ACME2::JWTMaker;

#----------------------------------------------------------------------
# This module exists because of a desire to do these computations
# in environments where a compiler may not be available.
# (Otherwise, CryptX would be ideal.)
#----------------------------------------------------------------------

use strict;
use warnings;

use JSON              ();
use MIME::Base64      ();

use Net::ACME2::X ();

BEGIN {
    *_encode_b64u = *MIME::Base64::encode_base64url;
}

sub new {
    my ($class, %opts) = @_;

    die Net::ACME2::X->create('Generic', 'need “key”') if !$opts{'key'};

    return bless \%opts, $class;
}

sub create_full_jws {
    my ($self, %args) = @_;

    local $args{'extra_headers'}{'jwk'} = $self->{'key'}->get_struct_for_public_jwk();

    return $self->_create_jwt(%args);
}

sub create_key_id_jws {
    my ($self, %args) = @_;

    local $args{'extra_headers'}{'kid'} = $args{'key_id'};

    return $self->_create_jwt(%args);
}

#----------------------------------------------------------------------

#expects:
#   payload - unblessed string, arrayref, or hashref
#   extra_headers - hashref
sub _create_jwt {
    my ( $self, %args ) = @_;

    my $alg = $self->_ALG();
    my $signer_cr = $self->_get_signer();

    my $key = $self->{'key'};

    my $payload = $args{payload};

    my $header  = { %{$args{extra_headers}} };

    # serialize payload
    $payload = $self->_payload_enc($payload);

    # encode payload
    my $b64u_payload = _encode_b64u($payload);

    # prepare header
    $header->{alg} = $alg;

    # encode header
    my $json_header = $self->_encode_json($header);
    my $b64u_header = _encode_b64u($json_header);

    my $b64u_signature = _encode_b64u( $signer_cr->("$b64u_header.$b64u_payload") );

    return $self->_encode_json(
        {
            protected => $b64u_header,
            payload => $b64u_payload,
            signature => $b64u_signature,
        }
    );
}

sub _encode_json {
    my ($self, $payload) = @_;

    #Always do a canonical encode so that we can test more easily.
    #Note that JWS itself does NOT require this.
    $self->{'_json'} ||= JSON->new()->canonical(1);

    return $self->{'_json'}->encode($payload);
}

#Derived from Crypt::JWT
sub _payload_enc {
    my ($self, $payload) = @_;

    if (ref($payload) eq 'HASH' || ref($payload) eq 'ARRAY') {
        $payload = $self->_encode_json($payload);
    }
    else {
        utf8::downgrade($payload, 1) or do {
            die Net::ACME2::X->create('Generic', "JWT: payload ($payload) cannot contain wide character");
        };
    }

    return $payload;
}

1;
