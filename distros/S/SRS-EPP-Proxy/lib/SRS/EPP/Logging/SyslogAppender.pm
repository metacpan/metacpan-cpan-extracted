package SRS::EPP::Logging::SyslogAppender;
{
  $SRS::EPP::Logging::SyslogAppender::VERSION = '0.22';
}

# A syslog appender class for log4perl that doesn't suck.

use Carp;
use strict;
use Log::Dispatch::Syslog;

sub new {
    my ($class, $appender_name, $data) = @_;
    my $stderr;

    my @param_names = qw/ident logopt facility socket min_level max_level/;
    my %params;

    foreach my $param (@param_names) {
        my $val = $data->{$param}{value} || $data->{ucfirst $param}{value};
         
        $params{$param} = $val if defined $val;
    }
    
    return Log::Log4perl::Appender->new("Log::Dispatch::Syslog",
        name      => $appender_name,
        ident     => '',
        %params,
    );
}

1;
