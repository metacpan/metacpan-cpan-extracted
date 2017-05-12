#!perl

use strict;
use warnings;
use Test::More;
use Stacktrace::Configurable;

my $trace = Stacktrace::Configurable->new;
my $res;

my $l1_line = __LINE__ + 1;
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
    l2; my $ln=__LINE__;
    my $exp=<<"EOF";
    ==== START STACK TRACE ===
    [1] at t/000-basic.t line @{[$l1_line+1]}
            l1 ()
    [2] at t/000-basic.t line $ln
            l2 ()
    === END STACK TRACE ===
EOF

    is $res, $exp, 'default format with STACKTRACE_CONFIG=undef';
}

{
    local $ENV{STACKTRACE_CONFIG_MAX}=4;
    l10; my $ln=__LINE__;
    my $exp=<<"EOF";
    ==== START STACK TRACE ===
    [ 1] at t/000-basic.t line @{[$l1_line+1]}
            l1 ()
    [ 2] at t/000-basic.t line @{[$l1_line+2]}
            l2 ()
    [ 3] at t/000-basic.t line @{[$l1_line+3]}
            l3 ()
    [ 4] at t/000-basic.t line @{[$l1_line+4]}
            l4 ()
    ... 6 frames cut off
    === END STACK TRACE ===
EOF

    is $res, $exp, 'default format with STACKTRACE_CONFIG_MAX=4';
}

for my $e (qw/off no 0/) {
    local $ENV{STACKTRACE_CONFIG}=$e;
    l2; my $ln=__LINE__;
    is $res, '', 'default format with STACKTRACE_CONFIG='.$e;
}

for my $e (qw/on yes 1/) {
    local $ENV{STACKTRACE_CONFIG}=$e;

    l2; my $ln=__LINE__;
    my $exp=<<"EOF";
    ==== START STACK TRACE ===
    [1] at t/000-basic.t line @{[$l1_line+1]}
            l1 ()
    [2] at t/000-basic.t line $ln
            l2 ()
    === END STACK TRACE ===
EOF

    is $res, $exp, 'default format with STACKTRACE_CONFIG='.$e;
}

{
    $trace->format('env=XX');
    local $ENV{XX}='%[basename]f(%l)';

    l2; my $ln=__LINE__;
    my $exp=<<"EOF";
000-basic.t(@{[$l1_line+1]})
000-basic.t($ln)
EOF
    chomp $exp;

    is $res, $exp, 'format env=XX';
}

{
    $trace->format('env=XX');
    local $ENV{XX}='env=YY';
    local $ENV{YY}='env=XX';

    l2; my $ln=__LINE__;    my $exp=<<'EOF';
format cycle detected
format cycle detected
EOF
    chomp $exp;

    is $res, $exp, 'format cycle XX => YY => XX';
}

done_testing;
__END__
