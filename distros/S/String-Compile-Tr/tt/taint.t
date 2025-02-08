#!perl -T

use 5.006;
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
    ok tainted($x), 'x is tainted';
    ok tainted($opt), 'opt is tainted';
    ok lives {$tr = trgen($x, $y, $opt)}, 'compile', $@;
    ref_ok $tr, 'CODE', 'is sub';
    ok lives {$tr->($s)}, 'call', $@;
    is $s, 'eedd321', 'result';
};
