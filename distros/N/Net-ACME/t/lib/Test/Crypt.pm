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

use Crypt::Perl::PK ();

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

    my $kobj = Crypt::Perl::PK::parse_key($key);

    die "JWT verification failed!" if !$kobj->verify_RS256($message, $signature);

    return;
}

1;
