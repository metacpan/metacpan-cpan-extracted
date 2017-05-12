#!perl

use strict;
use warnings;
use Test::More;
use Log::Log4perl::Layout::PatternLayout::Stacktrace;

use Log::Log4perl::Appender::String;
use Log::Log4perl::Level;

my $l;
my $recurse;

{
    package XX::XX;
    use strict;
    use warnings;
    use overload '""' => \&stringify;
    sub new {my $dummy=$_[1]; bless \$dummy, __PACKAGE__}
    sub stringify {
        $l->debug("here I am") if $recurse;
        'stringified object #'.${$_[0]};
    }
}

# build logger
my $app=Log::Log4perl::Appender->new('Log::Log4perl::Appender::String',
                                     utf8=>1);
my $rlog=Log::Log4perl->get_logger('');
$rlog->level(Log::Log4perl::Level::to_priority 'DEBUG');
$rlog->add_appender($app);
$Log::Log4perl::Logger::INITIALIZED=1;

$l=Log::Log4perl->get_logger('klaus');

note $l;

sub l1 {$l->debug("$_[0]")} my $l1_line=__LINE__;

delete $ENV{L4P_STACKTRACE};
{
    $app->layout(Log::Log4perl::Layout::PatternLayout->new('a%m%S%n'));

    l1 +XX::XX->new(8); my $ln=__LINE__;

    my $exp=<<"EOF";
astringified object #8
    ==== START STACK TRACE ===
    [1] at t/102-l4p_recursion.t line $l1_line
            __ANON__ ($l, "stringified object #8")
    [2] at t/102-l4p_recursion.t line $ln
            l1 (stringified object #8)
    === END STACK TRACE ===
EOF
    my $res=$app->string;

    is $res, $exp, 'should live';
    $app->string('');
}

{
    $app->layout(Log::Log4perl::Layout::PatternLayout->new('a%m%S%n'));

    $recurse=1;
    l1 +XX::XX->new(4); my $ln=__LINE__;

    my $res=$app->string;

    like $res, qr/\(recursion detected\)/, 'recursion is not allowed';
    $app->string('');
}

done_testing;
