#!perl

use strict;
use warnings;
use Test::More;
use Stacktrace::Configurable;

my $trace = Stacktrace::Configurable->new;
my $res;

my $l1_line = __LINE__;
sub l1 {$res = $trace->get_trace->as_string}
sub l2 {l1}
sub l3 {l2}
sub l4 {l3}
sub l5 {l4}
sub l6 {l5}
sub l7 {l6}
sub l8 {l7}
sub l9 {l8}
sub l10 {l9}

delete $ENV{STACKTRACE_CONFIG};

{
    $trace->format='y%nx';
    l10; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
y1x
y2x
y3x
y4x
y5x
y6x
y7x
y8x
y9x
y10x
EOF

    is $res, $exp, '%n';
}

{
    $trace->format='y%4nx';
    l10; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
y   1x
y   2x
y   3x
y   4x
y   5x
y   6x
y   7x
y   8x
y   9x
y  10x
EOF

    is $res, $exp, '%4n';
}

{
    $trace->format='y%0nx';
    l10; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
y1x
y2x
y3x
y4x
y5x
y6x
y7x
y8x
y9x
y10x
EOF

    is $res, $exp, '%0n';
}

{
    $trace->format='y%-4nx';
    l10; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
y1   x
y2   x
y3   x
y4   x
y5   x
y6   x
y7   x
y8   x
y9   x
y10  x
EOF

    is $res, $exp, '%-4n';
}

{
    $trace->format='y%*nx';
    l10; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
y 1x
y 2x
y 3x
y 4x
y 5x
y 6x
y 7x
y 8x
y 9x
y10x
EOF

    is $res, $exp, '%*n';
}

{
    $trace->format='y%-*nx';
    l10; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
y1 x
y2 x
y3 x
y4 x
y5 x
y6 x
y7 x
y8 x
y9 x
y10x
EOF

    is $res, $exp, '%-*n';
}

done_testing;
