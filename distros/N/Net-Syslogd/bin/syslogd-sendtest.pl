#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case); #bundling
use Pod::Usage;

use Sys::Hostname;
use Socket qw(AF_INET);

my $AF_INET6 = eval { Socket::AF_INET6() };

my $HAVE_IO_Socket_IP = 0;
eval "use IO::Socket::IP -register";
if(!$@) {
    $HAVE_IO_Socket_IP = 1;
} else {
    eval "use IO::Socket::INET";
}

my %opt;
my ($opt_help, $opt_man);

GetOptions(
  '4!'           => \$opt{4},
  '6!'           => \$opt{6},
  'datagram=s'   => \$opt{datagram},
  'facility=s'   => \$opt{facility},
  'h|hostname=s' => \$opt{hostname},
  'm|message=s'  => \$opt{message},
  'msec!'        => \$opt{msec},
  'severity=s'   => \$opt{severity},
  'year!'        => \$opt{year},
  'help!'        => \$opt_help,
  'man!'         => \$opt_man
) or pod2usage(-verbose => 0);

pod2usage(-verbose => 1) if defined $opt_help;
pod2usage(-verbose => 2) if defined $opt_man;

# Default to IPv4
my $family = AF_INET;
if ($opt{6}) {
    $family = $AF_INET6
}

if (!$HAVE_IO_Socket_IP && ($family == $AF_INET6)) {
    print "IO::Socket::IP required for IPv6\n";
    exit 1
}

#   Strict RFC 3164
# "<174>Dec 11 12:31:15 192.168.200.1 " . $0 . "[" . $$ . "]: Strict RFC 3164 format",
#   Net::Syslog
# "<182>" . $0 . "[" . $$ . "]: Net::Syslog format",
#   Cisco
# "<190>62: *Dec  4 12:31:15.087: %SYS-5-CONFIG_I: Cisco format"

### Syslog message
my $message;
if (defined($opt{datagram})) {
    $message = $opt{datagram}
} else {
    my %SYSLOG_FAC=(
        kernel    => 0,
        user      => 1,
        mail      => 2,
        system    => 3,
        security  => 4,
        internal  => 5,
        printer   => 6,
        news      => 7,
        uucp      => 8,
        clock     => 9,
        security2 => 10,
        ftp       => 11,
        ntp       => 12,
        audit     => 13,
        alert     => 14,
        clock2    => 15,
        local0    => 16,
        local1    => 17,
        local2    => 18,
        local3    => 19,
        local4    => 20,
        local5    => 21,
        local6    => 22,
        local7    => 23
    );

    my %SYSLOG_SEV=(
        emergency     => 0,
        alert         => 1,
        critical      => 2,
        error         => 3,
        warning       => 4,
        notice        => 5,
        informational => 6,
        debug         => 7
    );

    my @month = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

    $opt{facility} = $opt{facility} || 'local7';
    $opt{severity} = $opt{severity} || 'informational';
    ### Priority
    # Facility
    my $facility = $SYSLOG_FAC{$opt{facility}};
    # Severity
    my $severity = $SYSLOG_SEV{$opt{severity}};
    $facility = $facility || 23;
    $severity = $severity || 6;
    # Priority
    my $priority = (($facility<<3)|($severity));

    ### Timestamp
    my @time      = localtime();
    my $timestamp = $month[$time[4]] . " " . (($time[3] < 10)?(" " . $time[3]):$time[3]) . " ";
    if (defined($opt{year})) {
        $timestamp .= $time[5] + 1900 . " ";
    }
    $timestamp .= (($time[2] < 10)?("0" . $time[2]):$time[2]) . ":" . (($time[1] < 10)?("0" . $time[1]):$time[1]) . ":" . (($time[0] < 10)?("0" . $time[0]):$time[0]);
    if (defined($opt{msec})) {
        $timestamp .= "." . "123";
    }

    ### Hostname
    if (!defined($opt{hostname})) {
        $opt{hostname} = 'localhost'
    }

    ### Message
    my $msg = $opt{message} || "Message from $0";

    $message = "<$priority>$timestamp $opt{hostname} $0\[$$\]: $msg"
}

my $sock;
if ($HAVE_IO_Socket_IP) {
    $sock = IO::Socket::IP->new(
        PeerHost => $ARGV[0] || 'localhost',
        PeerPort => 514,
        Family   => $family,
        Proto    => 'udp'
    ) or die "Error: creating Syslog sender - $!\n";
} else {
    $sock = IO::Socket::INET->new(
        PeerHost => $ARGV[0] || 'localhost',
        PeerPort => 514,
        Proto    => 'udp'
    ) or die "Error: creating Syslog sender - $!\n";
}

$sock->send($message);
$sock->close();

__END__

=head1 NAME

SYSLOGD-SENDTEST - Syslog Message Tests

=head1 SYNOPSIS

 syslod-sendtest [options] [host]

=head1 DESCRIPTION

Sends sample Syslog messages.

=head1 OPTIONS

 host           The host to send to.
                DEFAULT:  (or not specified) localhost.

 -4               Force IPv4.
 -6               Force IPv6 (overrides -4).

 -d datagram      Entire Syslog datagram.  Use double-quotes to delimit.
 --datagram       Overrides all other options except 'host'.
                  Example:
                    "<190>Jan 01 00:00:00 host syslog.pl[123]: Message"

                  DEFAULT:  (or not specified) [build from user input]

 -f facility      Syslog facility.  Valid facility:
 --facility         kernel, user, mail, system, security, internal,
                    printer, news, uucp, clock, security2, ftp, ntp,
                    audit, alert, clock2, local0, local1, local2,
                    local3, local4, local5, local6, local7
                  DEFAULT:  (or not specified) [local7]

 -h name|IP[v6]   Hostname.
 --hostname       DEFAULT:  (or not specified) localhost


 -m message       Syslog message.  Use double-quotes to delimit
 --message        if spaces are used.
                  DEFAULT:  (or not specified) ["Message from ..."]

 -ms              Include milliseconds in timestamp.
 --msec           Not RFC 3164 compliant.
                  DEFAULT:  (or not specified) [do not include]

 -s severity      Syslog severity.  Valid severity:
  --severity        emergency, alert, critical, error,
                    warning, notice, informational, debug
                  DEFAULT:  (or not specified) [informational]

 -y               Include year in timestamp.
 --year           Not RFC 3164 compliant.
                  DEFAULT:  (or not specified) [do not include]

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2010

L<http://www.VinsWorld.com>

All rights reserved

=cut
