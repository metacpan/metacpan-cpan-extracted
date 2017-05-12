use Test::More;
use Test::Exception;

#use charnames qw(:full);

my @cchar =
    $^V lt v5.19.9 ? (0..33,35..127) :
# Excluding ", and ; if necessary, see rt#95224 or gh-6
    $^V lt v5.21.1 ? (0..33,35..122,124..127) :
# Limit ASCII printable characters only, see rt#100840 or gh-8
                     (grep { chr($_) =~ /[[:print:]]/ } (0..33,35..122,124..127));

my @case = (
    ['\t\n\r\f\b\a\e', 'constant one chars'],
    [join('', map { '\c'.chr($_) } @cchar), 'control chars'],
    [join('', map { '\x{'.$_.'}' } qw(A AA AAA AAAA AAAAA AAAAAA AAAAAAA AAAAAAAA AxA)), '\x{}'],
    ['\xA\xa\xq\xAAA\xaaa\x', '\x'],
# TODO: check fatal error case
    ['\0A\128\0128\18\1111\0111', '\0'],
# NOTE: An invalid name/value causes a compilation error
    [join('', map { '\N{'.$_.'}' } ('FIRST QUARTER MOON', 'WHITE SMILING FACE', 'U+263D', 'U+263A')), '\N{}'], 
# [from 5.14]
    [join('', map { '\o{'.$_.'}' } qw(1 11 111 1111 11111 111111 1111111 11111111 1x1)), '\o{}'],
);

plan tests => 1 + 2 * @case;

use_ok 'String::Unescape';

foreach my $str (@case) {
# At least, perl 5.8.9 requires 'use charnames qw(:full)' in each eval
    my $expected = eval "use charnames qw(:full); \"$str->[0]\"";
    diag $@ if $@;
    my $got = String::Unescape::unescape($str->[0]);
    is($got, $expected, "func: $str->[1]");
    $got = String::Unescape->unescape($str->[0]);
    is($got, $expected, "class method: $str->[1]");
}
