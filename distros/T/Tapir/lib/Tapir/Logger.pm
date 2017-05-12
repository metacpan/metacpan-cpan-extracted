package Tapir::Logger;

use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);
use Log::Log4perl::Appender;
use Log::Log4perl::Layout;
#use Log::Dispatch::Syslog;

sub new {
    my ($class, %args) = @_;

    if (! grep { defined $args{$_} } qw(screen syslog file)) {
        print STDERR "No log destination found in args ('screen', 'syslog' or 'file').  Defaulting to 'screen'\n";
        $args{screen} = 1;
    }

    my $logger = Log::Log4perl->get_logger($class);
    $logger->level($DEBUG);

    if ($args{screen}) {
        my $appender = Log::Log4perl::Appender->new(
            'Log::Log4perl::Appender::Screen',
            name => 'screenlog',
            stderr => 1,
        );
        $appender->layout( Log::Log4perl::Layout::PatternLayout->new("[\%d] \%P \%p: \%m\%n") );
        $appender->threshold($args{debug} || $args{screen_debug} ? $DEBUG : $INFO);
        $logger->add_appender($appender);
    }
    if ($args{syslog}) {
        my $appender = Log::Log4perl::Appender->new(
            'Log::Dispatch::Syslog',
            name => 'syslog',
            ident => $class,
            logopt => 'pid',
            min_level => 'info',
            facility => 'local4',
        );
        $appender->layout( Log::Log4perl::Layout::PatternLayout->new("\%m\%n") );
        $appender->threshold($args{debug} || $args{sysdebug} ? $DEBUG : $INFO);
        $logger->add_appender($appender);
    }
    if ($args{file}) {
        my $appender = Log::Log4perl::Appender->new(
            'Log::Log4perl::Appender::File',
            name => 'filelog',
            mode => 'append',
            filename => $args{file},
        );
        $appender->layout( Log::Log4perl::Layout::PatternLayout->new("[\%d] \%P \%p: \%m\%n") );
        $appender->threshold($args{debug} || $args{file_debug} ? $DEBUG : $INFO);
        $logger->add_appender($appender);
    }

    return $logger;
}

1;
