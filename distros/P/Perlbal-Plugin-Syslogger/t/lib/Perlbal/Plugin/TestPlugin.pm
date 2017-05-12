# simple plugin that hijacks start_http_request and returns 200 OK, issuing
# some log messages on the way

package Perlbal::Plugin::TestPlugin;

use strict;
use warnings;

use Perlbal::Plugin::Syslogger 'send_syslog_msg';
use Perlbal;

sub load { }

sub register {
    my ($class, $svc) = @_;

    # explicit mode
    send_syslog_msg($svc, "registering TestPlugin\n");
    $svc->register_hook('TestPlugin', 'start_http_request' => sub {
        my Perlbal::ClientProxy $cp = shift;
        send_syslog_msg($svc, 'handling request in TestPlugin');
        $cp->send_response(200, "OK\n");
        return 1;
    });

    # implicit mode
    Perlbal::Plugin::Syslogger::replace_perlbal_log($svc);
    Perlbal::log(info => "info message in plugin");
    Perlbal::log(err => "error message in plugin\n");

    # capture mode
    Perlbal::Plugin::Syslogger::capture_std_handles($svc);
    print "printing to stdout\n";
    print STDERR "printing to stderr\n";
}

sub unregister {
    my ($class, $svc) = @_;
    delete $svc->{extra_config}{_syslogger};
    return 1;
}

1;
