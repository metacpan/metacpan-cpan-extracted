#!perl

use strict;
use warnings;
use Test::More;
use Stacktrace::Configurable;

use t005_l2;

my $trace = Stacktrace::Configurable->new;
my $res;

my $l1_line = __LINE__;
sub l1 {$res = $trace->get_trace->as_string}

delete $ENV{STACKTRACE_CONFIG};

{
    $trace->format='y%px';
    t005_l2::l2; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
yt005_l2x
ymainx
EOF

    is $res, $exp, '%p';
}

{
    $trace->format='y%3px';
    t005_l2::l2; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
yt00...x
ymai...x
EOF

    is $res, $exp, '%3p';
}

{
    $trace->format='y%-3px';
    t005_l2::l2; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
y..._l2x
y...ainx
EOF

    is $res, $exp, '%-3ps';
}

{
    $trace->format='y%[skip_prefix=t]px';
    t005_l2::l2; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
y005_l2x
ymainx
EOF

    is $res, $exp, '%[skip_prefix=t]p';
}

done_testing;
