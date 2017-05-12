package Perlbal::Plugin::Syslogger;

use strict;
use warnings;

our $VERSION = '1.00';

use Log::Syslog::Constants 1.00;
use Log::Syslog::DangaSocket 1.05;
use Log::Syslog::Fast;
use Perlbal;
use Sys::Hostname;

use base 'Exporter';

our @EXPORT_OK = qw/ send_syslog_msg replace_perlbal_log /;

sub load {
    my $class = shift;

    Perlbal::Service::add_tunable(
        syslog_transport => {
            check_role => '*',
            des => "Transport type (udp, tcp, or unix)",
            default => 'udp',
            check_type => sub {
                my ($self, $val, $errref) = @_;
                $val = lc $val;
                return 1 if $val eq 'udp' || $val eq 'tcp' || $val eq 'unix';
                $$errref = "Expecting transport of udp, tcp, or unix";
                return 0;
            },
        }
    );
    Perlbal::Service::add_tunable(
        syslog_host => {
            check_role => '*',
            des => "Host where the syslogd is running (tcp/udp), or log socket (unix).",
            default => '127.0.0.1',
        }
    );
    Perlbal::Service::add_tunable(
        syslog_port => {
            check_role => '*',
            des => "Port on syslog_host where syslogd listens.",
            default => 514,
            check_type => 'int',
        }
    );
    Perlbal::Service::add_tunable(
        syslog_source => {
            check_role => '*',
            des => "Name of the submitting service (gets included in the log message)",
            default => 'Perlbal',
        }
    );
    Perlbal::Service::add_tunable(
        syslog_name => {
            check_role => '*',
            des => "Host of the submitting service (gets included in the log message)",
            default => hostname() || 'localhost',
        }
    );
    Perlbal::Service::add_tunable(
        syslog_facility => {
            check_role => '*',
            des => "Facility to log to; may be named or numeric",
            default => Log::Syslog::Constants::LOG_LOCAL0,
        }
    );
    Perlbal::Service::add_tunable(
        syslog_severity => {
            check_role => '*',
            des => "Severity level to log to; may be named or numeric",
            default => Log::Syslog::Constants::LOG_NOTICE,
        }
    );
}

sub register {
    my ($class, $svc) = @_;

    # stash the object that does all our work within the service configuration
    my $cfg = $svc->{extra_config} ||= {};

    my $facility = $cfg->{syslog_facility};
    if ($facility =~ /\D/) {
        $facility = Log::Syslog::Constants::get_facility($facility);
        die "unknown syslog facility $facility\n" unless defined $facility;
    }

    my $severity = $cfg->{syslog_severity};
    if ($severity =~ /\D/) {
        $severity = Log::Syslog::Constants::get_severity($facility);
        die "unknown syslog severity $severity\n" unless defined $severity;
    }

    my $transport = lc $cfg->{syslog_transport};
    if ($transport eq 'udp') {
        $cfg->{_syslogger} = Log::Syslog::Fast->new(
            Log::Syslog::Fast::LOG_UDP,
            $cfg->{syslog_host},
            $cfg->{syslog_port},
            $facility,
            $severity,
            $cfg->{syslog_source},
            $cfg->{syslog_name}
        );
    }
    elsif ($transport eq 'tcp' || $transport eq 'unix') {
        $cfg->{_syslogger} = Log::Syslog::DangaSocket->new(
            $transport,
            $cfg->{syslog_host},
            $cfg->{syslog_port},
            $cfg->{syslog_source},
            $cfg->{syslog_name},
            $facility,
            $severity,
            1,
        );
    }

    die "couldn't create syslogger: $!\n" unless $cfg->{_syslogger};

    return 1;
}

sub unregister {
    my ($class, $svc) = @_;
    delete $svc->{extra_config}{_syslogger};
    return 1;
}

sub send_syslog_msg {
    $_[0]->{extra_config}{_syslogger}->send($_[1]);
}

sub replace_perlbal_log {
    my $service = shift;
    my $logger = $service->{extra_config}{_syslogger};

    die "need a service with configured syslogger" unless $logger;

    my $old_perlbal_log = \&Perlbal::log;

    no warnings 'redefine';
    *Perlbal::log = sub {
        my ($level, $message) = @_;

        my $severity = Log::Syslog::Constants::get_severity($level);
        return unless defined $severity;

        my $old_severity = $logger->get_severity;

        $logger->set_severity($severity);

        $message .= "\n" unless $message =~ /\n$/;
        $logger->send(@_ ? sprintf($message, @_) : $message);

        $logger->set_severity($old_severity);
    };

    return $old_perlbal_log;
}

sub capture_std_handles {
    my $service = shift;
    my $logger = $service->{extra_config}{_syslogger};

    die "need a service with configured syslogger" unless $logger;

    tie *STDOUT, LineHandler => $logger;
    tie *STDERR, LineHandler => $logger;
}

package LineHandler;

use base 'Tie::Handle';

sub TIEHANDLE {
    my ($class, $logger) = @_;
    return bless \$logger, $class;
}

sub WRITE {
    my $lref = shift;
    my ($buf, $len, $offset) = @_;
    $offset ||= 0;
    $$lref->send(substr $buf, $offset, $len);
}

__END__

=head1 NAME

Perlbal::Plugin::Syslogger - Perlbal plugin that adds low-impact syslog
capabilities to client plugins

=head1 SYNOPSIS

    # plugin
    package Perlbal::Plugin::MyPlugin;

    use Perlbal::Plugin::Syslogger 'send_syslog_msg';

    sub register {
        my ($class, $svc) = @_;

        # explicit mode
        send_syslog_msg($svc, 'Registering MyPlugin');
        $svc->register_hook('MyPlugin', 'start_http_request' => sub {
            send_syslog_msg($svc, 'Handling request in MyPlugin');
        });

        # implicit mode
        Perlbal::Plugin::Syslogger::replace_perlbal_log($svc);
        Perlbal::log(info => "log message");
    }

    # perlbal config
    CREATE SERVICE fakeproxy
        SET role            = reverse_proxy
        SET listen          = 127.0.0.1:8080

        # set these after role/listen and before plugins
        SET syslog_host     = log-host
        SET syslog_port     = 514
        SET syslog_source   = perlbal-host
        SET syslog_name     = perlbal
        SET syslog_facility = 21
        SET syslog_severity = 5

        SET plugins         = Syslogger, MyPlugin
    ENABLE fakeproxy

=head1 FUNCTIONS

There are two (non-exclusive) ways of using the plugin. The explicit mode
requires you to call send_syslog_msg for every log message. The implicit mode
replaces Perlbal's standard Perlbal::log function.

=over 4

=item * send_syslog_msg($svc, $message)

Sends a single message via the transport specified by the service configuration
(see below). The facility and severity cannot be changed.

send_syslog_msg does not append a newline to the message.

=item * replace_perlbal_log($svc)

Replaces the current Perlbal::log with one described below that uses the
service's configured transport. Any future calls to Perlbal::log--even if made
in the context of another service's hook--will go through the provided
service's transport.

Returns a reference to the previous implementation of Perlbal::log.

=item * Perlbal::log($level, $message, [@values])

A non-blocking, compatible replacement for the normal STDOUT or Sys::Syslog
implementation. $level is a string matching a Sys::Syslog severity level like
"info" or "warning". If no @values are provided, $message is just a string. If
@values are provided, $message is a printf format string and the @values are
the printf values to be interpolated. A newline is appended if one is not
present.

This function does not change the severity level used by send_syslog_msg.

=item * capture_std_handles($svc)

Similar to replace_perlbal_log, this redirects all output destined for STDOUT
and STDERR to go through the service's configured transport.

=back

=head1 CONFIGURATION

The following options are configurable with the SET command within the perlbal
configuration file:

=over 4

=item * syslog_transport

Transport type: udp, tcp, or unix. Default udp.

=item * syslog_host

For udp and tcp, host where the syslogd is running. For unix, path to UNIX
socket. Default 127.0.0.1.

=item * syslog_port

Port on syslog_host where syslogd listens. Default 514.

=item * syslog_source

Name of the submitting service. Default "PerlbalSyslogger".

=item * syslog_name

Host of the submitting service. Defaults to the local hostname, or "localhost"
if that can't be determined.

=item * syslog_facility

Numeric facility number to log to. Default LOG_LOCAL0.

=item * syslog_severity

Numeric severity level to log to. Default LOG_NOTICE.

=back

=head1 TRANSPORTS

Although logging calls made with this module are non-blocking with both UDP or
TCP transports, the choice impacts its efficiency and reliability
characteristics.

=over 4

=item * UDP

In UDP mode, speed is emphasized over reliability; errors in sending typically
result in lost messages. A fast XS path (via Log::Syslog::Fast) is used to
construct log messages. Network errors (such as ICMP reject notifications) are
ignored, as are OS errors (such as a filled send buffer).

=item * TCP

In TCP mode, reliability is emphasized over speed. String manipulation is done
in perl. Receipt of the log message by the remote syslogd is ensured by TCP
acknowledgement. If the socket send buffer is full, unsent data will be
buffered until it is writable again.

If the connection to syslogd is lost, the client will attempt to reconnect
automatically. However, log messages which were not flushed before the
connection was lost will not be resent.

=back

=head1 AUTHOR

Adam Thomason, E<lt>athomason@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2010 by Six Apart, E<lt>cpan@sixapart.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
