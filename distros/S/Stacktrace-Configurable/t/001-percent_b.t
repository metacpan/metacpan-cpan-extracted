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
    $trace->format='%bx';
    l2; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
 x
 x
EOF

    is $res, $exp, '%b';
}

{
    $trace->format='%2bx';
    l2; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
  x
  x
EOF

    is $res, $exp, '%2b';
}

{
    $trace->format='%0bx';
    l2; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
x
x
EOF

    is $res, $exp, '%0b';
}

{
    $trace->format='y%[n]bx';
    l2; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
y
x
y
x
EOF

    is $res, $exp, '%[n]b';
}

{
    $trace->format='y%[t]bx';
    l2; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
y	x
y	x
EOF

    is $res, $exp, '%[t]b';
}

{
    $trace->format='y%2[s=a b]bx';
    l2; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
ya ba bx
ya ba bx
EOF

    is $res, $exp, '%2[s=a b]b';
}

{
    $trace->format='y%[nr!3,s=the end]bx';
    l6; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
yx
yx
ythe endx
EOF

    is $res, $exp, '%[nr!3,s=the end]b';
}

{
    $trace->format='y%[nr!3,s=]b%[nr=1,s=begin]bx%[nr=$,s=end]bx';
    l6; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
ybeginxx
yxx
yxendx
EOF

    is $res, $exp, '%[nr!3,s=]b%[nr=1,s=begin]bx%[nr=$,s=end]b';
}

{
    $trace->format='%[nr=1,n]b[%n] y%[nr=3,s=--]b%[nr%3=2,s=||]b%[nr%3,s=++]bx';
    l6; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;

[1] yx
[2] y||x
[3] y--++x
[4] yx
[5] y||x
[6] y++x
EOF

    is $res, $exp, '%[nr=1,n]b[%n] y%[nr=3,s=--]b%[nr%3=2,s=||]b%[nr%3,s=++]bx';
}

done_testing;
