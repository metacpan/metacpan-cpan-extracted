package Net::ACME::Crypt::RSA;

use strict;
use warnings;

use MIME::Base64 ();

use Crypt::Perl::RSA::Parse ();

*_encode_b64u = \&MIME::Base64::encode_base64url;

my $_C_O_R_failed;

#$key is PEM or DER
sub sign_RS256 {
    my ($msg, $key) = @_;

    #OpenSSL will do this faster.
    if ( !$_C_O_R_failed && _try_to_load_module('Crypt::OpenSSL::RSA') ) {
        my $rsa = Crypt::OpenSSL::RSA->new_private_key($key);
        $rsa->use_sha256_hash();
        return $rsa->sign($msg);
    }

    #No use in continuing to try.
    $_C_O_R_failed = 1;

#    elsif ( !$_no_openssl_bin ) {
#
#
#        $OPENSSL_BIN_PATH ||= File::Which::which('openssl');
#        if ($OPENSSL_BIN_PATH) {
#            return _sign_with_key_via_openssl_binary($msg, $key);
#        }
#    }

    return Crypt::Perl::RSA::Parse::private($key)->sign_RS256($msg);
}

sub get_public_jwk {
    my ($pem_or_der) = @_;

    my $rsa = Crypt::Perl::RSA::Parse::private($pem_or_der);

    my $n = $rsa->modulus()->as_bytes();
    my $e = $rsa->publicExponent()->as_bytes();

    my %jwk = (
        kty => 'RSA',
        n => _encode_b64u($n),
        e => _encode_b64u($e),
    );

    return \%jwk;
}

sub get_jwk_thumbprint {
    my ($pem_or_der_or_jwk) = @_;

    if ('HASH' ne ref $pem_or_der_or_jwk) {
        $pem_or_der_or_jwk = get_public_jwk($pem_or_der_or_jwk);
    }

    my $jwk_hr = $pem_or_der_or_jwk;

    #Since these will always be base64url values, it’s safe to hard-code.
    my $json = qq[{"e":"$jwk_hr->{'e'}","kty":"$jwk_hr->{'kty'}","n":"$jwk_hr->{'n'}"}];

    return _encode_b64u( Digest::SHA::sha256($json) );
}

sub _try_to_load_module {
    my ($module) = @_;

    my $eval_err = $@;

    #It’ll only try once, so the slowness is no big deal.
    my $ok = eval "require $module";

    $@ = $eval_err;

    return $ok;
}

#sub _sign_with_key_via_openssl_binary {
#    my ($msg, $key) = @_;
#
#    require File::Temp;
#
#    my ($fh, $path) = File::Temp::tempfile( CLEANUP => 1 );
#    print {$fh} $key or die "write($path): $!";
#    close $fh;
#
#    my ($d_fh, $d_path) = File::Temp::tempfile( CLEANUP => 1 );
#    print {$d_fh} $msg or die "write($d_path): $!";
#    close $d_fh;
#
#    #Works across exec().
#    local $?;
#
#    my $sig = qx/$OPENSSL_BIN_PATH dgst -sha256 -sign $path $d_path/;
#    die if $?;
#
#    return $sig;
#}

1;
