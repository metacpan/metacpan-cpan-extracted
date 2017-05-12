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
sub Pack::age::l3 {l2}
sub l4 {eval{Pack::age::l3}}
sub l5 {l4}
sub l6 {l5}
sub l7 {eval 'l6'}
sub l8 {l7}
sub l9 {l8}
sub l10 {l9}

delete $ENV{STACKTRACE_CONFIG};

{
    $trace->format='y%sx';
    l10; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
ymain::l1x
ymain::l2x
yPack::age::l3x
y(eval)x
ymain::l4x
ymain::l5x
ymain::l6x
yeval 'l6'x
ymain::l7x
ymain::l8x
ymain::l9x
ymain::l10x
EOF

    $res=~s/'l6\n;'/'l6'/;

    is $res, $exp, '%s';
}

{
    $trace->format='y%[skip_package]sx';
    l10; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
yl1x
yl2x
yl3x
y(eval)x
yl4x
yl5x
yl6x
yeval 'l6'x
yl7x
yl8x
yl9x
yl10x
EOF

    $res=~s/'l6\n;'/'l6'/;

    is $res, $exp, '%[skip_package]s';
}

done_testing;
