#!perl

use strict;
use warnings;
use Test::More;
use Stacktrace::Configurable;

my $trace = Stacktrace::Configurable->new;
my $res;

my $l1_line = __LINE__;
sub l1 {$res = $trace->get_trace->as_string}
sub l2 {@_=l1}
sub l3 {$_=l2}
sub l4 {l3}

delete $ENV{STACKTRACE_CONFIG};

{
    $trace->format='y%cx';
    l4; my $ln=__LINE__;

    my $exp=<<"EOF"; chomp $exp;
ylistx
yscalarx
yvoidx
yvoidx
EOF

    is $res, $exp, '%c';
}

done_testing;
