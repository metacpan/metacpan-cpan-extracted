use Test::More tests => 3;
use Sort::strverscmp;

use strict;
use warnings;

subtest 'strverscmp.c examples' => sub {
    plan tests => 5;
    is(strverscmp('no digit', 'no digit'), 0, q('no digit' == 'no digit'));
    is(strverscmp('item#99', 'item#100'), -1, q('item#99' < 'item#100'));
    is(strverscmp('alpha1', 'alpha001'), 1, q('alpha1' > 'alpha001'));
    is(strverscmp('part1_f012', 'part1_f01'), 1, q('part1_f012' > 'part1_f01'));
    is(strverscmp('foo.009', 'foo.0'), -1, q('foo.009' < 'foo.0'));
};

subtest 'Custom Examples' => sub {
    plan tests => 10;
    is(strverscmp('alpha1', 'beta1'), -1, q('alpha1' < 'beta1'));
    is(strverscmp('g', 'G'), 1, q('g' > 'G'));
    is(strverscmp('1.0.5', '1.0.50'), -1, q('1.0.5' < '1.0.50'));
    is(strverscmp('1.0.5', '1.05'), 1, q('1.0.5' > '1.05'));
    is(strverscmp('hi .2', 'hi 0.2'), -1, q('hi .2' < 'hi 0.2'));
    is(strverscmp('hi .2', 'hi abc'), -1, q('hi .2' < 'hi abc'));
    is(strverscmp('hi 0', 'hi 009'), 1, q('hi 0' > 'hi 009'));
    is(strverscmp('hi.0', 'hi.009'), 1, q('hi.0' > 'hi.009'));
    is(strverscmp('hi-0', 'hi-009'), 1, q('hi-0' > 'hi-009'));
    is(strverscmp('hi-0', 'hi.0'), -1, q('hi-0' < 'hi.0'));
};

subtest 'sort usage' => sub {
    my %cases = (
        'v0.0.0' => [
            [qw(v2.0.0 v0.9.1 v0.10.0 v0.9.0 v1.0.0 v10.0.0)],
            [qw(v0.9.0 v0.9.1 v0.10.0 v1.0.0 v2.0.0 v10.0.0)],
        ],
        '0.0.0' => [
            [qw(2.0.0 0.9.1 0.10.0 0.9.0 1.0.0 10.0.0)],
            [qw(0.9.0 0.9.1 0.10.0 1.0.0 2.0.0 10.0.0)],
        ],
    );
    plan tests => scalar(keys %cases);
    for my $name (keys %cases) {
        my @versions = @{$cases{$name}[0]};
        my @expected_versions = @{$cases{$name}[1]};
        is_deeply [sort strverscmp @versions], \@expected_versions, $name;
    }
};
