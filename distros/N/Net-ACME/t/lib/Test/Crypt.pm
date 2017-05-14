package Test::Crypt;

#----------------------------------------------------------------------
# To avoid needing Crypt::JWT for tests.
#----------------------------------------------------------------------

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use Carp;

use Call::Context ();
use File::Temp ();
use JSON ();
use MIME::Base64 ();

#A stripped-down copy of Crypt::JWT::decode_jwt() that only knows
#how to do RSA SHA256, compact form.
sub decode_jwt {
    my (%opts) = @_;

    Call::Context::must_be_list();

    $opts{'token'} =~ m<\A ( ([^.]+) \. ([^.]+) ) \. ([^.]+) \z>x or die "Bad token: “$opts{'token'}”";

    my ($signed, @parts) = ( $1, $2, $3, $4 );

    $_ = MIME::Base64::decode_base64url($_) for @parts;

    my ($header, $payload, $signature) = @parts;

    verify_rs256( $opts{'key'}, $signed, $signature );

    $payload = JSON::decode_json($payload) if $payload =~ m<\A[ \[ \{ ]>x;

    return JSON::decode_json($header), $payload;
}

sub verify_rs256 {
    my ($key, $message, $signature) = @_;

    confess "No key!" if !$key;

    my $ok;

    #cf. eval_bug.readme
    my $eval_err = $@;

    if ( eval { require Crypt::OpenSSL::RSA } ) {
        my $rsa = Crypt::OpenSSL::RSA->new_private_key($key);
        $rsa->use_sha256_hash();
        $ok = $rsa->verify($message, $signature);
    }
    else {
        my ($mfh, $mpath) = File::Temp::tempfile( CLEANUP => 1 );
        print {$mfh} $message or die $!;
        close $mfh;

        my ($sfh, $spath) = File::Temp::tempfile( CLEANUP => 1 );
        print {$sfh} $signature or die $!;
        close $sfh;

        my ($kfh, $kpath) = File::Temp::tempfile( CLEANUP => 1 );
        print {$kfh} $key or die $!;
        close $kfh;

        #Works across exec().
        local $?;

        my $out = qx/openssl dgst -sha256 -signature $spath -prverify $kpath $mpath/;
        die if $?;

        #OpenSSL seems to have changed the actual phrase that gets sent.
        $ok = ($out =~ m<Verif.*OK>);

        warn $out if !$ok;
    }

    die "JWT verification failed!" if !$ok;

    $@ = $eval_err;

    return;
}

1;
