#!perl

use Test2::Require::Perl 'v5.14';
use 5.014;
use Test2::V0;

use String::Compile::Tr;

plan 2;

subtest 'non-destructive on arg' => sub {
    my $x = 'abc';
    my $y = '123';
    my $s = 'edcba';
    my $tr;
    my $result;

    plan 5;
    ok lives {$tr = trgen($x, $y, 'r')}, 'compile', $@;
    ref_ok $tr, 'CODE', 'is sub';
    ok lives {$result = $tr->($s)}, 'call', $@;
    is $result, 'ed321', 'result';
    is $s, 'edcba', 'arg not modified';
};

subtest 'non-destructive on default' => sub {
    my $x = 'abc';
    my $y = '123';
    my $s = 'edcba';
    my $tr;
    my $result;

    plan 5;
    ok lives {$tr = trgen($x, $y, 'r')}, 'compile', $@;
    ref_ok $tr, 'CODE', 'is sub';
    ok lives {$result = $tr->()}, 'call', $@ for $s;
    is $result, 'ed321', 'result';
    is $s, 'edcba', 'arg not modified';
};
