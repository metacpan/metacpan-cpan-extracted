# -*- perl -*-
#
#  Net::Server::Log::Sys::Syslog - Net::Server Logging module
#
#  $Id$
#
#  Copyright (C) 2012
#
#    Paul Seamons
#    paul@seamons.com
#
#  This package may be distributed under the terms of either the
#  GNU General Public License
#    or the
#  Perl Artistic License
#
################################################################

package Net::Server::Log::Sys::Syslog;

use strict;
use warnings;
use Sys::Syslog qw(setlogsock openlog syslog);;

our %syslog_map = (0 => 'err', 1 => 'warning', 2 => 'notice', 3 => 'info', 4 => 'debug');

sub initialize {
    my ($class, $server) = @_;
    my $prop = $server->{'server'};

    $server->configure({
        syslog_logsock  => \$prop->{'syslog_logsock'},
        syslog_ident    => \$prop->{'syslog_ident'},
        syslog_logopt   => \$prop->{'syslog_logopt'},
        syslog_facility => \$prop->{'syslog_facility'},
    });

    if (ref($prop->{'syslog_logsock'}) eq 'ARRAY') {
        # do nothing - assume they have what they want
    } else {
        if (! defined $prop->{'syslog_logsock'}) {
            $prop->{'syslog_logsock'} = ($Sys::Syslog::VERSION < 0.15) ? 'unix' : '';
        }
        if ($prop->{'syslog_logsock'} =~ /^(|native|tcp|udp|unix|inet|stream|console)$/) {
            $prop->{'syslog_logsock'} = $1;
        } else {
            $prop->{'syslog_logsock'} = ($Sys::Syslog::VERSION < 0.15) ? 'unix' : '';
        }
    }

    my $ident = defined($prop->{'syslog_ident'}) ? $prop->{'syslog_ident'} : 'net_server';
    $prop->{'syslog_ident'} = ($ident =~ /^([\ -~]+)$/) ? $1 : 'net_server';

    my $opt = defined($prop->{'syslog_logopt'}) ? $prop->{'syslog_logopt'} : $Sys::Syslog::VERSION ge '0.15' ? 'pid,nofatal' : 'pid';
    $prop->{'syslog_logopt'} = ($opt =~ /^( (?: (?:cons|ndelay|nowait|pid|nofatal) (?:$|[,|]) )* )/x) ? $1 : 'pid';

    my $fac = defined($prop->{'syslog_facility'}) ? $prop->{'syslog_facility'} : 'daemon';
    $prop->{'syslog_facility'} = ($fac =~ /^((\w+)($|\|))*/) ? $1 : 'daemon';

    if ($prop->{'syslog_logsock'}) {
        setlogsock($prop->{'syslog_logsock'}) || die "Syslog err [$!]";
    }
    if (! openlog($prop->{'syslog_ident'}, $prop->{'syslog_logopt'}, $prop->{'syslog_facility'})) {
        die "Couldn't open syslog [$!]" if $prop->{'syslog_logopt'} ne 'ndelay';
    }

    return sub {
        my ($level, $msg) = @_;
        $level = $syslog_map{$level} || $level if $level =~ /^\d+$/;
        syslog($level, '%s', $msg);
    };
}

sub handle_log_error {
    my ($class, $server, $err, $info) = @_;
    return $server->handle_syslog_error($err, $info);
}

1;

__END__

=head1 NAME

Net::Server::Log::Sys::Syslog - log via Syslog

=head1 SYNOPSIS

    use base qw(Net::Server::PreFork);

    __PACKAGE__->run(
        log_file => 'Sys::Syslog',
        syslog_ident => 'myapp',
    );

=head1 DESCRIPTION

This module provides Sys::Syslog logging to the Net::Server system.

=head1 CONFIGURATION

=over 4

=item log_file

To begin using Sys::Syslog logging, simply set the Net::Server
log_file configuration parameter to "Sys::Syslog".

If the magic name "Sys::Syslog" is used, all logging will take place
via the Sys::Syslog module.  If syslog is used the parameters
C<syslog_logsock>, C<syslog_ident>, and C<syslog_logopt>,and
C<syslog_facility> may also be defined.

=item syslog_logsock

Only available if C<log_file> is equal to "Sys::Syslog".  May be
either unix, inet, native, console, stream, udp, or tcp, or an
arrayref of the types to try.  Default is "unix" if the version of
Sys::Syslog < 0.15 - otherwise the default is to not call setlogsock.

See L<Sys::Syslog>.

=item syslog_ident

Only available if C<log_file> is equal to "Sys::Syslog".  Id to
prepend on syslog entries.  Default is "net_server".  See
L<Sys::Syslog>.

=item syslog_logopt

Only available if C<log_file> is equal to "Sys::Syslog".  May be
either zero or more of "pid","cons","ndelay","nowait".  Default is
"pid".  See L<Sys::Syslog>.

=item syslog_facility

Only available if C<log_file> is equal to "Sys::Syslog".  See
L<Sys::Syslog> and L<syslog>.  Default is "daemon".

=back

=head1 DEFAULT ARGUMENTS FOR Net::Server

The following arguments are available in the default C<Net::Server> or
C<Net::Server::Single> modules.  (Other personalities may use
additional parameters and may optionally not use parameters from the
base class.)

    Key               Value                    Default

    ## syslog parameters (if log_file eq Sys::Syslog)
    syslog_logsock    (native|unix|inet|udp
                       |tcp|stream|console)    unix (on Sys::Syslog < 0.15)
    syslog_ident      "identity"               "net_server"
    syslog_logopt     (cons|ndelay|nowait|pid) pid
    syslog_facility   \w+                      daemon

=head1 METHODS

=over 4

=item C<initialize>

This method is called during the initilize_logging method of
Net::Server.  It returns a single code ref that will be stored under
the log_function property of the Net::Server object.  That code ref
takes log_level and message as arguments and calls the initialized
log4perl system.

=item C<handle_log_error>

This method is called if the log_function fails for some reason.  It
is passed the Net::Server object, the error that occurred while
logging and an arrayref containing the log level and the message.  In
turn, this calls the legacy Net::Server::handle_syslog_error method.

=back

=head1 LICENCE

Distributed under the same terms as Net::Server

=cut
