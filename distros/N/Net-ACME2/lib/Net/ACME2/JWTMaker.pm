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

BEGIN {
    *_encode_b64u = *MIME::Base64::encode_base64url;
}

sub new {
    my ($class, %opts) = @_;

    die 'need “key”' if !$opts{'key'};

    $opts{'format'} ||= q<>;

    if ($opts{'format'} && $opts{'format'} ne 'compact') {
        die "Unknown “format”: “$opts{'format'}”";
    }

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
#   key - object
#   payload
#   extra_headers (optional, hashref)
sub _create_jwt {
    my ( $self, %args ) = @_;

    my $alg = $self->_ALG();
    my $signer_cr = $self->_get_signer();

    my $key = $self->{'key'};

    my $payload = $args{payload};

    my $header  = $args{extra_headers} ? { %{$args{extra_headers}} } : {};

    # serialize payload
    $payload = $self->_payload_enc($payload);

    # encode payload
    my $b64u_payload = _encode_b64u($payload);

    # prepare header
    $header->{alg} = $alg;

    # encode header
    my $json_header = $self->_encode_json($header);
    my $b64u_header = _encode_b64u($json_header);

    my $b64u_signature = _encode_b64u( $signer_cr->("$b64u_header.$b64u_payload", $key) );

    if ($self->{'format'} && $self->{'format'} eq 'compact') {
        return join('.', $b64u_header, $b64u_payload, $b64u_signature);
    }

    return <<"END";
{
    "protected": "$b64u_header",
    "payload": "$b64u_payload",
    "signature": "$b64u_signature"
}
END
}

sub _encode_json {
    my ($self, $payload) = @_;

    #Always do a canonical encode so that we can test more easily.
    #Note that JWS itself does NOT require this.
    $self->{'_json'} ||= JSON->new()->canonical(1);

    return $self->{'_json'}->encode($payload);
}

#Taken from Crypt::JWT
sub _payload_enc {
    my ($self, $payload) = @_;

    if (ref($payload) eq 'HASH' || ref($payload) eq 'ARRAY') {
        $payload = $self->_encode_json($payload);
    }
    else {
        utf8::downgrade($payload, 1) or die "JWT: payload cannot contain wide character";
    }

    return $payload;
}

1;
