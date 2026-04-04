#!perl

use strict;
use warnings;

use Test::More;

use Razor2::String;

# --- hextobase64 / base64tohex round-trip ---

{
    my $hex40 = 'da39a3ee5e6b4b0d3255bfef95601890afd80709';    # SHA1 of ""
    my $b64   = hextobase64($hex40);
    ok( defined $b64 && length($b64) > 0, "hextobase64 produces output" );

    my $hex_back = base64tohex($b64);
    # base64tohex may produce trailing padding; compare the meaningful prefix
    is( substr( $hex_back, 0, length($hex40) ), $hex40,
        "base64tohex(hextobase64(x)) round-trips a 40-char hex string" );
}

{
    my $hex15 = 'da39a3ee5e6b4b0';
    my $b64   = hextobase64($hex15);
    my $hex_back = base64tohex($b64);
    is( substr( $hex_back, 0, length($hex15) ), $hex15,
        "round-trip works for 15-char hex string" );
}

# --- hmac2_sha1 ---

{
    my ( $b64, $hex ) = hmac2_sha1( "test message", "key1", "key2" );
    ok( defined $b64 && length($b64) > 0,  "hmac2_sha1 returns base64 digest" );
    ok( defined $hex && $hex =~ /^[0-9a-f]{40}$/, "hmac2_sha1 returns 40-char hex digest" );

    # Deterministic: same inputs produce same outputs
    my ( $b64_2, $hex_2 ) = hmac2_sha1( "test message", "key1", "key2" );
    is( $hex, $hex_2, "hmac2_sha1 is deterministic" );
}

{
    # Missing arguments return undef
    my $result = hmac2_sha1( "", "key1", "key2" );
    ok( !defined $result, "hmac2_sha1 returns undef for empty text" );

    $result = hmac2_sha1( "text", "", "key2" );
    ok( !defined $result, "hmac2_sha1 returns undef for empty iv1" );
}

# --- hmac_sha1 (wrapper) ---

{
    my $b64 = hmac_sha1( "test", "iv1", "iv2" );
    my ( $expected_b64, undef ) = hmac2_sha1( "test", "iv1", "iv2" );
    is( $b64, $expected_b64, "hmac_sha1 returns the base64 portion of hmac2_sha1" );
}

# --- xor_key ---

{
    my ( $iv1, $iv2 ) = xor_key("secret");
    ok( defined $iv1 && length($iv1) == 64, "xor_key iv1 is 64 bytes" );
    ok( defined $iv2 && length($iv2) == 64, "xor_key iv2 is 64 bytes" );
    isnt( $iv1, $iv2, "iv1 and iv2 differ" );

    # Deterministic
    my ( $iv1_2, $iv2_2 ) = xor_key("secret");
    is( $iv1, $iv1_2, "xor_key is deterministic for iv1" );
    is( $iv2, $iv2_2, "xor_key is deterministic for iv2" );
}

# --- makesis / parsesis ---

{
    my $sis = makesis( p => 0, cf => 95 );
    ok( defined $sis, "makesis produces output" );
    like( $sis, qr/\r\n$/, "makesis ends with CRLF" );

    my %parsed = parsesis($sis);
    is( $parsed{p},  0,  "parsesis recovers p=0" );
    is( $parsed{cf}, 95, "parsesis recovers cf=95" );
}

{
    # makesis with hashref
    my $sis = makesis( { action => 'check', sig => 'abc123' } );
    my %parsed = parsesis($sis);
    is( $parsed{action}, 'check',  "makesis(hashref) works - action" );
    is( $parsed{sig},    'abc123', "makesis(hashref) works - sig" );
}

{
    # URI escaping in makesis/parsesis
    my $sis = makesis( msg => 'hello world&more=stuff' );
    my %parsed = parsesis($sis);
    is( $parsed{msg}, 'hello world&more=stuff',
        "makesis/parsesis correctly round-trips URI-special characters" );
}

{
    # parsesis must not mutate the caller's argument
    my $sis = makesis( p => 0, cf => 95 );
    my $original = $sis;
    my %parsed = parsesis($sis);
    is( $sis, $original, "parsesis does not mutate the input string" );
}

{
    # Values containing '=' after URI-unescaping should round-trip correctly
    my $sis = makesis( token => 'a=b=c' );
    my %parsed = parsesis($sis);
    is( $parsed{token}, 'a=b=c',
        "parsesis preserves values containing '=' via URI escaping" );
}

# --- makesis_nue / parsesis_nue ---

{
    my $sis = makesis_nue( a => '1', b => '2' );
    ok( defined $sis, "makesis_nue produces output" );
    like( $sis, qr/\r\n$/, "makesis_nue ends with CRLF" );

    my %parsed = parsesis_nue($sis);
    is( $parsed{a}, '1', "parsesis_nue recovers a=1" );
    is( $parsed{b}, '2', "parsesis_nue recovers b=2" );
}

{
    # parsesis_nue must not mutate the caller's argument
    my $sis = makesis_nue( x => 'y' );
    my $original = $sis;
    my %parsed = parsesis_nue($sis);
    is( $sis, $original, "parsesis_nue does not mutate the input string" );
}

# --- findsimilar ---

{
    my ( $both, $diff ) = findsimilar(
        { a => 1, b => 2, c => 3 },
        { a => 1, b => 9, c => 3 },
    );
    ok( ref($both) eq 'HASH', "findsimilar returns hash of shared values" );
    ok( ref($diff) eq 'ARRAY', "findsimilar returns array of differing keys" );
    is( $both->{a}, 1,   "shared value a preserved" );
    is( $both->{b}, '?', "differing value b marked as ?" );
    is_deeply( $diff, ['b'], "diff list contains only 'b'" );
}

{
    # Identical hashes
    my @result = findsimilar( { x => 1 }, { x => 1 } );
    is( scalar @result, 1, "findsimilar returns (1) for identical hashes" );
    is( $result[0], 1, "findsimilar returns 1 for identical hashes" );
}

{
    # Different keys
    my @result = findsimilar( { x => 1 }, { y => 2 } );
    is( scalar @result, 0, "findsimilar returns empty for different keys" );
}

# --- randstr ---

{
    my $str = randstr(16);
    is( length($str), 16, "randstr(16) returns 16-char string" );
    like( $str, qr/^[A-Za-z0-9\-_]+$/, "randstr alphanumeric uses base64 alphabet" );

    my $str2 = randstr(16, 0);
    is( length($str2), 16, "randstr(16, 0) returns 16-char string" );
}

# --- round ---

{
    is( round(3.7), 4, "round(3.7) = 4" );
    is( round(3.2), 3, "round(3.2) = 3" );
    is( round(0),   0, "round(0) = 0" );
}

done_testing;
