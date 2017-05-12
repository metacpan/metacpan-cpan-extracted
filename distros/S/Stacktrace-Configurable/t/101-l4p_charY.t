#!perl

use strict;
use warnings;
use Test::More;
use Log::Log4perl::Layout::PatternLayout::Stacktrace -char=>'Y';

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

sub l1 {$l->debug('msg')} my $l1_line=__LINE__;

delete $ENV{L4P_STACKTRACE};
{
    $app->layout(Log::Log4perl::Layout::PatternLayout->new('a%m%Y%n'));

    l1; my $ln=__LINE__;

    my $exp=<<"EOF";
amsg
    ==== START STACK TRACE ===
    [1] at t/101-l4p_charY.t line $l1_line
            __ANON__ ($l, "msg")
    [2] at t/101-l4p_charY.t line $ln
            l1 ()
    === END STACK TRACE ===
EOF
    my $res=$app->string;

    is $res, $exp, 'default format with L4P_STACKTRACE=undef';
    $app->string('');
}

done_testing;
