package Parse::Netstat::freebsd;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-12-04'; # DATE
our $DIST = 'Parse-Netstat'; # DIST
our $VERSION = '0.150'; # VERSION

our @EXPORT_OK = qw(parse_netstat);

our %SPEC;

$SPEC{parse_netstat} = {
    v => 1.1,
    summary => 'Parse the output of FreeBSD "netstat" command',
    description => <<'_',

Netstat can be called with `-n` (show raw IP addresses and port numbers instead
of hostnames or port names) or without. It can be called with `-a` (show all
listening and non-listening socket) option or without.

Tested with FreeBSD 10.1's netstat.

_
    args => {
        output => {
            summary => 'Output of netstat command',
            schema => 'str*',
            req => 1,
        },
        tcp => {
            summary => 'Whether to parse TCP (and TCP6) connections',
            schema  => [bool => default => 1],
        },
        udp => {
            summary => 'Whether to parse UDP (and UDP6) connections',
            schema  => [bool => default => 1],
        },
        unix => {
            summary => 'Whether to parse Unix socket connections',
            schema  => [bool => default => 1],
        },
    },
};
sub parse_netstat {
    my %args = @_;
    my $output = $args{output} or return [400, "Please specify output"];
    my $tcp    = $args{tcp} // 1;
    my $udp    = $args{udp} // 1;
    my $unix   = $args{unix} // 1;

    my $in_unix;
    my $in_unix_header;
    my @conns;
    my $i = 0;
    for my $line (split /^/, $output) {
        $i++;
        my %k;
        if ($line =~ /^Registered kernel control modules/) {
            $in_unix = 0;
        } elsif ($line =~ /^tcp/ && $tcp) {
            #Proto Recv-Q Send-Q Local Address               Foreign Address             State       PID/Program name
            #tcp4       0      0 192.168.1.33.632       192.168.1.10.2049      CLOSED
            $line =~ m!^(?P<proto>tcp(?:4|6|46)?) \s+ (?P<recvq>\d+) \s+ (?P<sendq>\d+)\s+
                       (?P<local_host>\S+?)[:.](?P<local_port>\w+)\s+
                       (?P<foreign_host>\S+?)[:.](?P<foreign_port>\w+|\*)\s+
                       (?P<state>\S+) (?: \s+ (?:
                               (?P<pid>\d+)/(?P<program>.+?) |
                               -
                       ))? \s*$!x
                           or return [400, "Can't parse tcp line (#$i): $line"];
            %k = %+;
        } elsif ($line =~ /^udp/ && $udp) {
            #Proto Recv-Q Send-Q Local Address          Foreign Address        (state)
            #udp4       0      0 *.879                  *.*
            $line =~ m!^(?P<proto>udp(?:4|6|46)?) \s+ (?P<recvq>\d+) \s+ (?P<sendq>\d+) \s+
                       (?P<local_host>\S+?)[:.](?P<local_port>\w+|\*)\s+
                       (?P<foreign_host>\S+?)[:.](?P<foreign_port>\w+|\*)
                       (?: \s+
                           (?P<state>\S+)?
                           (?: \s+ (?:
                                   (?P<pid>\d+)/(?P<program>.+?) |
                                   -
                           ))?
                       )? \s*$!x
                           or return [400, "Can't parse udp line (#$i): $line"];
            %k = %+;
        } elsif ($in_unix && $unix) {
            #Address  Type   Recv-Q Send-Q    Inode     Conn     Refs  Nextref Addr
            #fffffe00029912d0 stream      0      0 fffffe0002d8abd0        0        0        0 /tmp/ssh-zwZwlpzaip/agent.1089
            $line =~ m!^(?P<address>\S+) \s+ (?P<type>\S+) \s+
                       (?P<recvq>\d+) \s+ (?P<sendq>\d+) \s+ (?P<inode>[0-9a-f]+) \s+ (?P<conn>[0-9a-f]+) \s+
                       (?P<refs>[0-9a-f]+) \s+ (?P<nextref>[0-9a-f]+)
                       (?:
                           \s+
                           (?P<addr>.+)
                       )?
                       \s*$!x
                           or return [400, "Can't parse unix/freebsd line (#$i): $line"];
            %k = %+;
            $k{proto} = 'unix';
        } elsif ($in_unix_header) {
            $in_unix_header = 0;
            $in_unix++;
        } elsif ($line =~ /^Active (UNIX|LOCAL \(UNIX\)) domain sockets/) {
            $in_unix_header++;
        } else {
            next;
        }
        push @conns, \%k;
    }

    [200, "OK", {active_conns => \@conns}];
}

1;
# ABSTRACT: Parse the output of FreeBSD "netstat" command

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Netstat::freebsd - Parse the output of FreeBSD "netstat" command

=head1 VERSION

This document describes version 0.150 of Parse::Netstat::freebsd (from Perl distribution Parse-Netstat), released on 2022-12-04.

=head1 SYNOPSIS

 use Parse::Netstat qw(parse_netstat);
 my $res = parse_netstat(output=>join("", `netstat -an`), flavor=>"freebsd");

Sample `netstat -an` output:

 Active Internet connections (including servers)
 Proto Recv-Q Send-Q Local Address          Foreign Address        (state)
 tcp4       0      0 192.168.1.33.780       192.168.1.10.2049      CLOSE_WAIT
 tcp4       0      0 192.168.1.33.632       192.168.1.10.2049      CLOSED
 tcp4       0      0 127.0.0.1.6012         *.*                    LISTEN
 tcp6       0      0 ::1.6012               *.*                    LISTEN
 tcp4       0     52 192.168.1.33.22        192.168.1.10.41487     ESTABLISHED
 tcp4       0      0 127.0.0.1.6011         *.*                    LISTEN
 tcp6       0      0 ::1.6011               *.*                    LISTEN
 tcp4       0      0 192.168.1.33.22        192.168.1.10.61223     ESTABLISHED
 tcp4       0      0 127.0.0.1.6010         *.*                    LISTEN
 tcp6       0      0 ::1.6010               *.*                    LISTEN
 tcp4       0      0 192.168.1.33.22        192.168.1.10.18499     ESTABLISHED
 tcp4       0      0 192.168.1.33.22        192.168.1.10.30712     ESTABLISHED
 tcp4       0      0 127.0.0.1.25           *.*                    LISTEN
 tcp4       0      0 *.22                   *.*                    LISTEN
 tcp6       0      0 *.22                   *.*                    LISTEN
 tcp4       0      0 *.4949                 *.*                    LISTEN
 tcp6       0      0 *.4949                 *.*                    LISTEN
 tcp4       0      0 *.667                  *.*                    LISTEN
 tcp6       0      0 *.896                  *.*                    LISTEN
 tcp4       0      0 *.879                  *.*                    LISTEN
 tcp6       0      0 *.879                  *.*                    LISTEN
 tcp4       0      0 *.111                  *.*                    LISTEN
 tcp6       0      0 *.111                  *.*                    LISTEN
 udp4       0      0 *.682                  *.*
 udp6       0      0 *.726                  *.*
 udp6       0      0 *.948                  *.*
 udp4       0      0 *.*                    *.*
 udp4       0      0 *.879                  *.*
 udp6       0      0 *.879                  *.*
 udp6       0      0 *.*                    *.*
 udp4       0      0 *.755                  *.*
 udp4       0      0 *.111                  *.*
 udp6       0      0 *.932                  *.*
 udp6       0      0 *.111                  *.*
 udp4       0      0 *.514                  *.*
 udp6       0      0 *.514                  *.*
 Active UNIX domain sockets
 Address  Type   Recv-Q Send-Q    Inode     Conn     Refs  Nextref Addr
 fffff80057aa11e0 stream      0      0        0        0        0        0
 fffff80057aa12d0 stream      0      0        0        0        0        0
 fffff8001b0bc5a0 stream      0      0 fffff80011150938        0        0        0 /tmp/ssh-52dQiqRzC4/agent.35116
 fffff8001b0bc780 stream      0      0        0 fffff8001b0bcc30        0        0
 fffff8001b0bcc30 stream      0      0        0 fffff8001b0bc780        0        0
 fffff80002ad85a0 stream      0      0 fffff80030dfd760        0        0        0 /tmp/ssh-ZPrtis6Qgb/agent.21969
 fffff8001b0bc2d0 stream      0      0        0 fffff80057aa10f0        0        0
 fffff80057aa10f0 stream      0      0        0 fffff8001b0bc2d0        0        0
 fffff80002ad82d0 stream      0      0        0 fffff80002ad84b0        0        0
 fffff80002ad84b0 stream      0      0        0 fffff80002ad82d0        0        0
 fffff800028b3960 stream      0      0 fffff800354e3588        0        0        0 /var/run/dbus/system_bus_socket
 fffff80002ad8a50 stream      0      0        0 fffff80002ad8c30        0        0
 fffff80002ad8c30 stream      0      0        0 fffff80002ad8a50        0        0
 fffff80002ad91e0 stream      0      0 fffff80002f5b1d8        0        0        0 /tmp/ssh-EXvnWwxbk4/agent.750
 fffff80002ad93c0 stream      0      0        0 fffff80002ad90f0        0        0
 fffff80002ad90f0 stream      0      0        0 fffff80002ad93c0        0        0
 fffff80002ad9780 stream      0      0 fffff800029db000        0        0        0 /var/run/rpcbind.sock
 fffff80002ad9b40 stream      0      0 fffff800029a4000        0        0        0 /var/run/devd.pipe
 fffff80002ad80f0 dgram       0      0        0 fffff80002ad9960        0 fffff80002ad94b0
 fffff80002ad9000 dgram       0      0        0 fffff80002ad9870        0 fffff80002ad92d0
 fffff80002ad94b0 dgram       0      0        0 fffff80002ad9960        0        0
 fffff80002ad92d0 dgram       0      0        0 fffff80002ad9870        0 fffff80002ad9690
 fffff80002ad9690 dgram       0      0        0 fffff80002ad9870        0 fffff80002ad95a0
 fffff80002ad95a0 dgram       0      0        0 fffff80002ad9870        0        0
 fffff80002ad9870 dgram       0      0 fffff80002b3e938        0 fffff80002ad9000        0 /var/run/logpriv
 fffff80002ad9960 dgram       0      0 fffff80002b3eb10        0 fffff80002ad80f0        0 /var/run/log
 fffff80002ad9a50 seqpac      0      0 fffff80002947ce8        0        0        0 /var/run/devd.seqpacket.pipe

Sample result:

 [
   200,
   "OK",
   {
     active_conns => [
       {
         foreign_host => "192.168.1.10",
         foreign_port => 2049,
         local_host => "192.168.1.33",
         local_port => 780,
         proto => "tcp4",
         recvq => 0,
         sendq => 0,
         state => "CLOSE_WAIT",
       },
       {
         foreign_host => "192.168.1.10",
         foreign_port => 2049,
         local_host => "192.168.1.33",
         local_port => 632,
         proto => "tcp4",
         recvq => 0,
         sendq => 0,
         state => "CLOSED",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "127.0.0.1",
         local_port => 6012,
         proto => "tcp4",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "::1",
         local_port => 6012,
         proto => "tcp6",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "192.168.1.10",
         foreign_port => 41487,
         local_host => "192.168.1.33",
         local_port => 22,
         proto => "tcp4",
         recvq => 0,
         sendq => 52,
         state => "ESTABLISHED",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "127.0.0.1",
         local_port => 6011,
         proto => "tcp4",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "::1",
         local_port => 6011,
         proto => "tcp6",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "192.168.1.10",
         foreign_port => 61223,
         local_host => "192.168.1.33",
         local_port => 22,
         proto => "tcp4",
         recvq => 0,
         sendq => 0,
         state => "ESTABLISHED",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "127.0.0.1",
         local_port => 6010,
         proto => "tcp4",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "::1",
         local_port => 6010,
         proto => "tcp6",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "192.168.1.10",
         foreign_port => 18499,
         local_host => "192.168.1.33",
         local_port => 22,
         proto => "tcp4",
         recvq => 0,
         sendq => 0,
         state => "ESTABLISHED",
       },
       {
         foreign_host => "192.168.1.10",
         foreign_port => 30712,
         local_host => "192.168.1.33",
         local_port => 22,
         proto => "tcp4",
         recvq => 0,
         sendq => 0,
         state => "ESTABLISHED",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "127.0.0.1",
         local_port => 25,
         proto => "tcp4",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 22,
         proto => "tcp4",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 22,
         proto => "tcp6",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 4949,
         proto => "tcp4",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 4949,
         proto => "tcp6",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 667,
         proto => "tcp4",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 896,
         proto => "tcp6",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 879,
         proto => "tcp4",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 879,
         proto => "tcp6",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 111,
         proto => "tcp4",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 111,
         proto => "tcp6",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 682,
         proto => "udp4",
         recvq => 0,
         sendq => 0,
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 726,
         proto => "udp6",
         recvq => 0,
         sendq => 0,
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 948,
         proto => "udp6",
         recvq => 0,
         sendq => 0,
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => "*",
         proto => "udp4",
         recvq => 0,
         sendq => 0,
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 879,
         proto => "udp4",
         recvq => 0,
         sendq => 0,
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 879,
         proto => "udp6",
         recvq => 0,
         sendq => 0,
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => "*",
         proto => "udp6",
         recvq => 0,
         sendq => 0,
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 755,
         proto => "udp4",
         recvq => 0,
         sendq => 0,
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 111,
         proto => "udp4",
         recvq => 0,
         sendq => 0,
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 932,
         proto => "udp6",
         recvq => 0,
         sendq => 0,
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 111,
         proto => "udp6",
         recvq => 0,
         sendq => 0,
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 514,
         proto => "udp4",
         recvq => 0,
         sendq => 0,
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 514,
         proto => "udp6",
         recvq => 0,
         sendq => 0,
       },
       {},
       {},
       {
         address => "fffff80057aa11e0",
         conn    => 0,
         inode   => 0,
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         address => "fffff80057aa12d0",
         conn    => 0,
         inode   => 0,
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         addr    => "/tmp/ssh-52dQiqRzC4/agent.35116",
         address => "fffff8001b0bc5a0",
         conn    => 0,
         inode   => "fffff80011150938",
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         address => "fffff8001b0bc780",
         conn    => "fffff8001b0bcc30",
         inode   => 0,
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         address => "fffff8001b0bcc30",
         conn    => "fffff8001b0bc780",
         inode   => 0,
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         addr    => "/tmp/ssh-ZPrtis6Qgb/agent.21969",
         address => "fffff80002ad85a0",
         conn    => 0,
         inode   => "fffff80030dfd760",
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         address => "fffff8001b0bc2d0",
         conn    => "fffff80057aa10f0",
         inode   => 0,
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         address => "fffff80057aa10f0",
         conn    => "fffff8001b0bc2d0",
         inode   => 0,
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         address => "fffff80002ad82d0",
         conn    => "fffff80002ad84b0",
         inode   => 0,
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         address => "fffff80002ad84b0",
         conn    => "fffff80002ad82d0",
         inode   => 0,
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         addr    => "/var/run/dbus/system_bus_socket",
         address => "fffff800028b3960",
         conn    => 0,
         inode   => "fffff800354e3588",
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         address => "fffff80002ad8a50",
         conn    => "fffff80002ad8c30",
         inode   => 0,
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         address => "fffff80002ad8c30",
         conn    => "fffff80002ad8a50",
         inode   => 0,
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         addr    => "/tmp/ssh-EXvnWwxbk4/agent.750",
         address => "fffff80002ad91e0",
         conn    => 0,
         inode   => "fffff80002f5b1d8",
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         address => "fffff80002ad93c0",
         conn    => "fffff80002ad90f0",
         inode   => 0,
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         address => "fffff80002ad90f0",
         conn    => "fffff80002ad93c0",
         inode   => 0,
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         addr    => "/var/run/rpcbind.sock",
         address => "fffff80002ad9780",
         conn    => 0,
         inode   => "fffff800029db000",
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         addr    => "/var/run/devd.pipe",
         address => "fffff80002ad9b40",
         conn    => 0,
         inode   => "fffff800029a4000",
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         address => "fffff80002ad80f0",
         conn    => "fffff80002ad9960",
         inode   => 0,
         nextref => "fffff80002ad94b0",
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "dgram",
       },
       {
         address => "fffff80002ad9000",
         conn    => "fffff80002ad9870",
         inode   => 0,
         nextref => "fffff80002ad92d0",
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "dgram",
       },
       {
         address => "fffff80002ad94b0",
         conn    => "fffff80002ad9960",
         inode   => 0,
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "dgram",
       },
       {
         address => "fffff80002ad92d0",
         conn    => "fffff80002ad9870",
         inode   => 0,
         nextref => "fffff80002ad9690",
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "dgram",
       },
       {
         address => "fffff80002ad9690",
         conn    => "fffff80002ad9870",
         inode   => 0,
         nextref => "fffff80002ad95a0",
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "dgram",
       },
       {
         address => "fffff80002ad95a0",
         conn    => "fffff80002ad9870",
         inode   => 0,
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "dgram",
       },
       {
         addr    => "/var/run/logpriv",
         address => "fffff80002ad9870",
         conn    => 0,
         inode   => "fffff80002b3e938",
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => "fffff80002ad9000",
         sendq   => 0,
         type    => "dgram",
       },
       {
         addr    => "/var/run/log",
         address => "fffff80002ad9960",
         conn    => 0,
         inode   => "fffff80002b3eb10",
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => "fffff80002ad80f0",
         sendq   => 0,
         type    => "dgram",
       },
       {
         addr    => "/var/run/devd.seqpacket.pipe",
         address => "fffff80002ad9a50",
         conn    => 0,
         inode   => "fffff80002947ce8",
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "seqpac",
       },
     ],
   },
 ]

=head1 FUNCTIONS


=head2 parse_netstat

Usage:

 parse_netstat(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse the output of FreeBSD "netstat" command.

Netstat can be called with C<-n> (show raw IP addresses and port numbers instead
of hostnames or port names) or without. It can be called with C<-a> (show all
listening and non-listening socket) option or without.

Tested with FreeBSD 10.1's netstat.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<output>* => I<str>

Output of netstat command.

=item * B<tcp> => I<bool> (default: 1)

Whether to parse TCP (and TCP6) connections.

=item * B<udp> => I<bool> (default: 1)

Whether to parse UDP (and UDP6) connections.

=item * B<unix> => I<bool> (default: 1)

Whether to parse Unix socket connections.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Parse-Netstat>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Parse-Netstat>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2017, 2015, 2014, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-Netstat>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
