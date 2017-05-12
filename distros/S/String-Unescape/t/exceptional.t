use Test::More;
use Test::Exception;

#use charnames qw(:full);

my @case = (
    ['\Etest\Etest\E', 'unmatched \E'],
    ['test\Utest\Etest\Etest\Utest\Etest', 'unmatched \E with \L, \E'],
    ['\N{NONEXISTENT NAME}', 'nonexistent name', qr/Unknown charname NONEXISTENT NAME/],
    ['\N{U+20FFFF}', 'codepoint over U+10FFFF'],
);

plan tests => 1 + 2 * @case;

use_ok 'String::Unescape';

foreach my $str (@case) {
# At least, perl 5.8.9 requires 'use charnames qw(:full)' in each eval
    if(defined $str->[2]) {
        throws_ok { String::Unescape::unescape($str->[0]); } $str->[2], $str->[1];
        throws_ok { String::Unescape->unescape($str->[0]); } $str->[2], $str->[1];
    } else {
        my $expected = eval "use charnames qw(:full); \"$str->[0]\"";
        my $got = String::Unescape::unescape($str->[0]);
        is($got, $expected, "func: $str->[1]");
        $got = String::Unescape->unescape($str->[0]);
        is($got, $expected, "class method: $str->[1]");
    }
}
