#!perl

use strict;
use warnings;
use Test::More;
use Log::Log4perl::Layout::PatternLayout::Stacktrace;

use Log::Log4perl::Appender::String;
use Log::Log4perl::Level;

# build logger
my $app=Log::Log4perl::Appender->new('Log::Log4perl::Appender::String',
                                     utf8=>1);
my $rlog=Log::Log4perl->get_logger('');
$rlog->level(Log::Log4perl::Level::to_priority 'DEBUG');
$rlog->add_appender($app);
$Log::Log4perl::Logger::INITIALIZED=1;

my $l=Log::Log4perl->get_logger('klaus');

note $l;

sub l1 {$l->debug('msg')} my $l1_line=__LINE__;
sub l2 {l1}
sub l3 {l2}
sub l4 {l3}
sub l5 {l4}
sub l6 {l5}
sub l7 {l6}
sub l8 {l7}
sub l9 {l8}
sub l10 {l9}

delete $ENV{L4P_STACKTRACE};
{
    $app->layout(Log::Log4perl::Layout::PatternLayout->new('a%m%S%n'));

    l1; my $ln=__LINE__;

    my $exp=<<"EOF";
amsg
    ==== START STACK TRACE ===
    [1] at t/100-l4p.t line $l1_line
            __ANON__ ($l, "msg")
    [2] at t/100-l4p.t line $ln
            l1 ()
    === END STACK TRACE ===
EOF
    my $res=$app->string;

    is $res, $exp, 'default format with L4P_STACKTRACE=undef';
    $app->string('');
}

{
    local $ENV{L4P_STACKTRACE_MAX}=4;
    $app->layout(Log::Log4perl::Layout::PatternLayout->new('a%m%S%n'));

    l10; my $ln=__LINE__;

    my $exp=<<"EOF";
amsg
    ==== START STACK TRACE ===
    [ 1] at t/100-l4p.t line $l1_line
            __ANON__ ($l, "msg")
    [ 2] at t/100-l4p.t line @{[$l1_line+1]}
            l1 ()
    [ 3] at t/100-l4p.t line @{[$l1_line+2]}
            l2 ()
    [ 4] at t/100-l4p.t line @{[$l1_line+3]}
            l3 ()
    ... 7 frames cut off
    === END STACK TRACE ===
EOF
    my $res=$app->string;

    is $res, $exp, 'default format with L4P_STACKTRACE_MAX=4';
    $app->string('');
}

for my $e (qw/off no 0/) {
    local $ENV{L4P_STACKTRACE}=$e;
    $app->layout(Log::Log4perl::Layout::PatternLayout->new('a%m%Sb'));

    $l->debug('msg');

    is $app->string, 'amsgb', 'default format with L4P_STACKTRACE='.$e;
    $app->string('');
}

for my $e (qw/on yes 1/) {
    local $ENV{L4P_STACKTRACE}=$e;
    $app->layout(Log::Log4perl::Layout::PatternLayout->new('a%m%S%n'));

    l1; my $ln=__LINE__;

    my $exp=<<"EOF";
amsg
    ==== START STACK TRACE ===
    [1] at t/100-l4p.t line $l1_line
            __ANON__ ($l, "msg")
    [2] at t/100-l4p.t line $ln
            l1 ()
    === END STACK TRACE ===
EOF
    my $res=$app->string;

    is $res, $exp, 'default format with L4P_STACKTRACE='.$e;
    $app->string('');
}

{
    local $ENV{L4P_STACKTRACE_A}='dump=CODE, deparse, multiline=12';
    $app->layout(Log::Log4perl::Layout::PatternLayout->new('a%m%S%n'));

    l1 sub {1+1}; my $ln=__LINE__;

    my $sub_deparsed = Data::Dumper->new([sub{2}])->Useqq(1)->Terse(1)
                                   ->Deparse(1)->Indent(0)->Dump;

    my $exp=<<"EOF";
amsg
    ==== START STACK TRACE ===
    [1] at t/100-l4p.t line $l1_line
            __ANON__ (
                $l,
                "msg"
            )
    [2] at t/100-l4p.t line $ln
            l1 (
                $sub_deparsed
            )
    === END STACK TRACE ===
EOF
    my $res=$app->string;

    is $res, $exp, 'default format with L4P_STACKTRACE_A="dump=CODE, deparse, multiline"';
    $app->string('');
}

{
    $app->layout(Log::Log4perl::Layout::PatternLayout->new
                 ('a%m%S{%[nr=1,n]b   [%n] %[basename]f (%l)}%n'));

    l2; my $ln=__LINE__;

    my $exp=<<"EOF";
amsg
   [1] 100-l4p.t ($l1_line)
   [2] 100-l4p.t (@{[$l1_line+1]})
   [3] 100-l4p.t ($ln)
EOF
    my $res=$app->string;

    is $res, $exp, 'format in curlies';
    $app->string('');
}

{
    local $ENV{ENVVAR}='%[nr=1,n]b   {%n} %[basename]f (%l)';
    $app->layout(Log::Log4perl::Layout::PatternLayout->new
                 ('a%m%S{env=ENVVAR}%n'));

    l2; my $ln=__LINE__;

    my $exp=<<"EOF";
amsg
   {1} 100-l4p.t ($l1_line)
   {2} 100-l4p.t (@{[$l1_line+1]})
   {3} 100-l4p.t ($ln)
EOF
    my $res=$app->string;

    is $res, $exp, 'format read from ENVVAR';
    $app->string('');
}

done_testing;
