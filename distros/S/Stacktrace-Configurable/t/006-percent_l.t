#!perl

use strict;
use warnings;
use Test::More;
use Stacktrace::Configurable;

use t004_l2;

my $trace = Stacktrace::Configurable->new;
my $res;

my $l1_line = __LINE__;
sub l1 {$res = $trace->get_trace->as_string}
sub l2;

delete $ENV{STACKTRACE_CONFIG};

{
    $trace->format='y%lx';
    l2; my $ln=__LINE__;

    my $exp=<<"EOF"; chomp $exp;
y4x
y${ln}x
EOF

    is $res, $exp, '%l';
}

{
    $trace->format='y%4lx';
    l2; my $ln=sprintf '%4d', __LINE__;

    my $exp=<<"EOF"; chomp $exp;
y   4x
y${ln}x
EOF

    is $res, $exp, '%4l';
}

{
    $trace->format='y%-4lx';
    l2; my $ln=sprintf '%-4d', __LINE__;

    my $exp=<<"EOF"; chomp $exp;
y4   x
y${ln}x
EOF

    is $res, $exp, '%-4l';
}

done_testing;
