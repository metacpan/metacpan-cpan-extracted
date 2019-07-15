package Net::ACME2::AccountKey;

use strict;
use warnings;

use Net::ACME2::X ();

use constant {
    _DEBUG => 0,
    _JWK_THUMBPRINT_DIGEST => 'sha256',

    _JWA_ALG => {
        secp256r1 => 'ES256',
        secp384r1 => 'ES384',
        secp521r1 => 'ES521',
    },

    # Shouldn’t be needed?
    # cf. https://github.com/DCIT/perl-CryptX/issues/45
    _JWA_SHA => {
        secp256r1 => 'sha256',
        secp384r1 => 'sha384',
        secp521r1 => 'sha521',
    },

    _TRY_OPENSSL => 1,
    _TRY_CRYPTX => 1,
};

#----------------------------------------------------------------------
# An abstraction that allows use of OpenSSL or CryptX for crypto operations
# as available and useful. Either will be faster than Crypt::Perl.
#----------------------------------------------------------------------

sub new {
    my ($class, $pem_or_der) = @_;

    my ($engine, $obj);

    my $key_type = _guess_at_key_type($pem_or_der);

    if (!$key_type) {
        ($obj, $key_type) = _parse_via_crypt_perl($pem_or_der);
    }

    my $err = $@;

    my %self;

    if ($key_type eq 'rsa') {
        if (_TRY_OPENSSL() && eval { require Crypt::OpenSSL::RSA; require Crypt::OpenSSL::Bignum }) {

            my $pem;
            if (0 == index($pem_or_der, '----')) {
                $pem = $pem_or_der;
            }
            else {
                require Crypt::Format;
                $pem = Crypt::Format::der2pem($pem_or_der, 'RSA PRIVATE KEY');
            }

            $obj = Crypt::OpenSSL::RSA->new_private_key($pem);
            $obj->use_pkcs1_padding();
            $obj->use_sha256_hash();

            $engine = 'crypt_openssl_rsa';
        }
        elsif (_TRY_CRYPTX() && eval { require Crypt::PK::RSA }) {
            $obj = Crypt::PK::RSA->new(\$pem_or_der);
            $engine = 'crypt_pk';
        }
    }
    elsif ($key_type eq 'ecdsa') {
        if (_TRY_CRYPTX() && eval { require Crypt::PK::ECC }) {
            $obj = Crypt::PK::ECC->new(\$pem_or_der);
            $engine = 'crypt_pk';

            $self{'curve_name'} = $obj->key2hash()->{'curve_name'};

            _JWA_ALG()->{ $self{'curve_name'} } or do {
                die Net::ACME2::X->create('Generic', "RFC 7518 does not support ECDSA curve “$self{'curve_name'}”!");
            };
        }
    }

    $@ = $err;

    # If we got PEM in but don’t have an XS library …
    $obj ||= (_parse_via_crypt_perl($pem_or_der))[0];
    $engine ||= 'crypt_perl';

    _DEBUG() && print STDERR "Key backend: $engine/$key_type$/";

    %self = (
        %self,
        engine => $engine,
        key_type => $key_type,
        obj => $obj,
    );

    return bless \%self, $class;
}

sub _parse_via_crypt_perl {
    my ($pem_or_der) = @_;

    require Crypt::Perl::PK;
    my $obj = Crypt::Perl::PK::parse_key($pem_or_der);

    my $key_type;

    if ($obj->isa('Crypt::Perl::RSA::PrivateKey')) {
        $key_type = 'rsa';
    }
    elsif ($obj->isa('Crypt::Perl::ECDSA::PrivateKey')) {
        $key_type = 'ecdsa';
    }
    else {

        # As of this writing, Crypt::Perl only does RSA and ECDSA keys.
        # If we get here, it’s possible that Crypt::Perl now supports
        # an additional key type that this library doesn’t recognize.
        die Net::ACME2::X->create('Generic', "Unrecognized key type: $obj");
    }

    return ($obj, $key_type);
}

sub _guess_at_key_type {
    my ($key_str) = @_;

    # PEM makes it easy …
    return 'rsa' if 0 == index($key_str, '-----BEGIN RSA ');
    return 'ecdsa' if 0 == index($key_str, '-----BEGIN EC ');

    return undef;
}

sub get_type {
    my ($self) = @_;

    return $self->{'key_type'};
}

# Worth submitting this upstream?
sub _build_jwk_thumbprint_for_crypt_openssl_rsa {
    my ($self) = @_;

    my ($n, $e) = $self->_get_crypt_openssl_rsa_n_e_strings();
    my $json = qq<{"e":"$e","kty":"RSA","n":"$n"}>;

    require Digest::SHA;
    my $hash_cr = Digest::SHA->can( _JWK_THUMBPRINT_DIGEST() );
    return MIME::Base64::encode_base64url( $hash_cr->($json) );
}

sub _get_crypt_openssl_rsa_n_e_strings {
    my ($self) = @_;

    my ($n, $e) = $self->{'obj'}->get_key_parameters();

    require MIME::Base64;
    $_ = MIME::Base64::encode_base64url( $_->to_bin() ) for ($n, $e);

    return ($n, $e);
}

#----------------------------------------------------------------------

# for RSA
sub sign_RS256 {
    my ($self, $msg) = @_;

    my $engine = $self->{'engine'};

    if ($engine eq 'crypt_openssl_rsa') {
        return $self->{'obj'}->sign($msg);
    }
    elsif ($engine eq 'crypt_pk') {
        return $self->{'obj'}->sign_message($msg, 'sha256', 'v1.5');
    }
    elsif ($engine eq 'crypt_perl') {
        return $self->{'obj'}->sign_RS256($msg);
    }

    return _die_unknown_engine($engine);
}

# for ECC
sub get_jwa_alg {
    my ($self) = @_;

    my $engine = $self->{'engine'};

    if ($engine eq 'crypt_pk') {
        return _JWA_ALG()->{$self->{'curve_name'}};
    }
    elsif ($engine eq 'crypt_perl') {
        return $self->{'obj'}->get_jwa_alg();
    }

    return _die_unknown_engine($engine);
}

# for ECC
sub sign_jwa {
    my ($self, $msg) = @_;

    my $engine = $self->{'engine'};

    if ($engine eq 'crypt_pk') {

        # This shouldn’t be needed??
        # cf. https://github.com/DCIT/perl-CryptX/issues/45
        my @extra_args = (
            _JWA_SHA()->{$self->{'curve_name'}},
        );

        return $self->{'obj'}->sign_message_rfc7518($msg, @extra_args);
    }
    elsif ($engine eq 'crypt_perl') {
        return $self->{'obj'}->sign_jwa($msg);
    }

    return _die_unknown_engine($engine);
}

sub get_struct_for_public_jwk {
    my ($self) = @_;

    my $engine = $self->{'engine'};

    if ($engine eq 'crypt_openssl_rsa') {
        my ($n, $e) = $self->_get_crypt_openssl_rsa_n_e_strings();

        return {
            e => $e,
            kty => 'RSA',
            n => $n,
        };
    }
    elsif ($engine eq 'crypt_pk') {
        return $self->{'obj'}->export_key_jwk('public', 1);
    }
    elsif ($engine eq 'crypt_perl') {
        return $self->{'obj'}->get_struct_for_public_jwk();
    }

    return _die_unknown_engine($engine);
}

sub get_jwk_thumbprint {
    my ($self) = @_;

    my $engine = $self->{'engine'};

    if ($engine eq 'crypt_openssl_rsa') {
        my $thumbprint = $self->_build_jwk_thumbprint_for_crypt_openssl_rsa();

        _DEBUG() && print STDERR "key thumbprint: $thumbprint$/";

        return $thumbprint;
    }
    elsif ($engine eq 'crypt_pk') {
        return $self->{'obj'}->export_key_jwk_thumbprint( _JWK_THUMBPRINT_DIGEST() );
    }
    elsif ($engine eq 'crypt_perl') {
        return $self->{'obj'}->get_jwk_thumbprint( _JWK_THUMBPRINT_DIGEST() );
    }

    return _die_unknown_engine($engine);
}

sub _die_unknown_engine {
    my ($engine) = @_;

    my $func = (caller 0)[3];
    die "$func: unknown engine “$engine”";
}

1;
