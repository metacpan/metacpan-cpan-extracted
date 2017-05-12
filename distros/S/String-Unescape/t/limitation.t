use Test::More;

# rt#95224
my @case_rt95224 = (
# Prohibited '\c'.chr(123) => ;
    ['\c'.chr(123), 'control chars with 123'],
);

plan tests => 1 + 2 * @case_rt95224;

use_ok 'String::Unescape';

# Actually not TODO, just a NOTE
TODO: {
    todo_skip 'Only for newer than or equal to Perl 5.19.9', 2 * @case_rt95224 if $^V lt v5.19.9;
    local $TODO = 'Only from Perl 5.19.9, \c cannot accept chr(123) denoting ;';

    foreach my $str (@case_rt95224) {
        my $expected = eval "\"$str->[0]\"";
        diag $@ unless $@ =~ /\QUse ";" instead of "\c{"\E/;
        my $got = String::Unescape::unescape($str->[0]);
        is($got, $expected, "func: $str->[1]");
        $got = String::Unescape->unescape($str->[0]);
        is($got, $expected, "class method: $str->[1]");
    }
}
