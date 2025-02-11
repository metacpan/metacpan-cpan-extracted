#!perl -T

use 5.010;
use Test2::V0;

use String::Compile::Tr;
use Scalar::Util 'tainted';

plan 1;

subtest 'run on tainted' => sub {
    my $tainted = substr $ENV{PATH}, 0, 0;
    my $x = 'abc' . $tainted;
    my $y = '123' . $tainted;
    my $opt = 's' . $tainted;
    my $s = 'eeddccbbaa'. $tainted;
    my $tr;

    plan 6;
    SKIP: {
        my $todo = todo 'should support taint mode';
        ok tainted($x), 'x is tainted';
        ok tainted($opt), 'opt is tainted';
        undef $todo;
        ok lives {$tr = trgen($x, $y, $opt)}, 'compile', $@
            or skip 'gen failed', 3;
        ref_ok $tr, 'CODE', 'is sub' or skip 'no code', 2;
        ok lives {$tr->($s)}, 'call', $@ or skip 'call failed';
        is $s, 'eedd321', 'result';
    }
};
