#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256 hmac_sha256);
use MIME::Base64 ();
use Punk::Challenge::Token ();

# The bundled hashes against Digest::SHA, which is the oracle and not a
# constant remembered from somewhere: a "published" vector from memory fails
# wrongly or passes vacuously.
#
# The inputs are chosen to SELECT each branch of the block handling, not for
# volume: the empty message, one short block, and every length around the
# 56- and 64-byte padding boundaries where a wrong tail shows.

my @lengths = (0, 1, 3, 31, 55, 56, 57, 63, 64, 65, 119, 120, 121, 127, 128,
               129, 200, 1000, 4097);

sub bytes_of { my $n = shift; join '', map { chr(($_ * 7 + 3) % 256) } 0 .. $n - 1 }

for my $n (@lengths) {
    my $m = bytes_of($n);
    is(Punk::Challenge::Token::_sha256($m), sha256($m), "sha256 over $n bytes");
}

is(Punk::Challenge::Token::_sha256('abc'), sha256('abc'), 'sha256("abc")');

# HMAC: key lengths around the block size, where a key is padded, or hashed
# first when it is longer than a block.
for my $kl (0, 1, 16, 32, 63, 64, 65, 100, 200) {
    my $k = bytes_of($kl);
    for my $ml (0, 1, 55, 56, 64, 100) {
        my $m = bytes_of($ml);
        is(Punk::Challenge::Token::_hmac_sha256($k, $m), hmac_sha256($m, $k),
           "hmac key $kl bytes, message $ml bytes");
    }
}

# A string with the UTF-8 flag on but only narrow characters is bytes.
{
    my $s = "caf\x{e9}";
    utf8::upgrade($s);
    my $b = "caf\xe9";
    is(Punk::Challenge::Token::_sha256($s), sha256($b),
       'an upgraded narrow string hashes as its bytes');
}

# A wide character cannot be bytes, and says so.
{
    local $@;
    eval { Punk::Challenge::Token::_sha256("\x{263a}") };
    like($@, qr/Wide character/, 'a wide character croaks rather than hashing something');
}

# base64url against MIME::Base64 with the two substitutions and no padding.
sub b64url_ref {
    my $e = MIME::Base64::encode_base64($_[0], '');
    $e =~ tr{+/}{-_};
    $e =~ s/=+\z//;
    return $e;
}

for my $n (0, 1, 2, 3, 4, 5, 6, 16, 32, 33, 34, 100) {
    my $m = bytes_of($n);
    is(Punk::Challenge::Token::_b64url($m), b64url_ref($m), "base64url over $n bytes");
}
is(Punk::Challenge::Token::_b64url("\xfb\xff\xbf"), '-_-_',
   'the two url-safe characters are the ones used');

# Constant-time compare: equal, one byte off, different lengths, empty.
ok( Punk::Challenge::Token::_ct_eq('abcdef', 'abcdef'), 'equal strings compare equal');
ok(!Punk::Challenge::Token::_ct_eq('abcdef', 'abcdeg'), 'a last-byte difference is unequal');
ok(!Punk::Challenge::Token::_ct_eq('bbcdef', 'abcdef'), 'a first-byte difference is unequal');
ok(!Punk::Challenge::Token::_ct_eq('abcdef', 'abcde'),  'a shorter string is unequal');
ok(!Punk::Challenge::Token::_ct_eq('abcde',  'abcdef'), 'a longer string is unequal');
ok(!Punk::Challenge::Token::_ct_eq('abcabc', 'abc'),    'a repeated prefix is not equality');
ok(!Punk::Challenge::Token::_ct_eq('',       ''),       'two empty strings are not a match');
ok(!Punk::Challenge::Token::_ct_eq('a',      ''),       'nothing against something is unequal');

# Leading zero bits, which is what a solution is judged on.
is(Punk::Challenge::Token::_zero_bits("\x80"),           0,   'a set top bit is zero bits');
is(Punk::Challenge::Token::_zero_bits("\x01"),           7,   'seven leading zeros in one byte');
is(Punk::Challenge::Token::_zero_bits("\x00\x0f"),       12,  'a zero byte then four');
is(Punk::Challenge::Token::_zero_bits("\x00\x00\x01\xff"), 23, 'two zero bytes then seven');
is(Punk::Challenge::Token::_zero_bits("\x00" x 32),      256, 'an all-zero digest is 256');
is(Punk::Challenge::Token::_zero_bits(''),               0,   'nothing has no zero bits');

done_testing;
