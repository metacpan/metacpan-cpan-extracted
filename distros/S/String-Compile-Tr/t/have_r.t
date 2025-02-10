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
    SKIP: {
        ok lives {$tr = trgen($x, $y, 'r')}, 'compile', $@
            or skip 'gen failed', 4;
        ref_ok $tr, 'CODE', 'is sub' or skip 'no code', 3;
        ok lives {$result = $tr->($s)}, 'call', $@ or skip 'call failed', 2;
        is $result, 'ed321', 'result';
        is $s, 'edcba', 'arg not modified';
    }
};

subtest 'non-destructive on default' => sub {
    my $x = 'abc';
    my $y = '123';
    my $s = 'edcba';
    my $tr;
    my $result;

    plan 5;
    SKIP: {
        ok lives {$tr = trgen($x, $y, 'r')}, 'compile', $@
            or skip 'gen failed', 4;
        ref_ok $tr, 'CODE', 'is sub' or skip 'no code', 3;
        ok lives {$result = $tr->()}, 'call', $@ or skip 'call failed', 2
            for $s;
        is $result, 'ed321', 'result';
        is $s, 'edcba', 'arg not modified';
    }
};
