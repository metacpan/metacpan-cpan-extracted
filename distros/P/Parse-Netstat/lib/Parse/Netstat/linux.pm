package Parse::Netstat::linux;

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
    summary => 'Parse the output of Linux "netstat" command',
    description => <<'_',

Netstat can be called with `-n` (show raw IP addresses and port numbers instead
of hostnames or port names) or without. It can be called with `-a` (show all
listening and non-listening socket) option or without. And can be called with
`-p` (show PID/program names) or without.

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
        if ($line =~ /^tcp/ && $tcp) {
            #Proto Recv-Q Send-Q Local Address               Foreign Address             State       PID/Program name
            #tcp        0      0 0.0.0.0:8898                0.0.0.0:*                   LISTEN      5566/daemon2.pl [pa
            $line =~ m!^(?P<proto>tcp[46]?) \s+ (?P<recvq>\d+) \s+ (?P<sendq>\d+)\s+
                       (?P<local_host>\S+?):(?P<local_port>\w+)\s+
                       (?P<foreign_host>\S+?):(?P<foreign_port>\w+|\*)\s+
                       (?P<state>\S+) (?: \s+ (?:
                               (?P<pid>\d+)/(?P<program>.+?) |
                               -
                       ))? \s*$!x
                           or return [400, "Can't parse tcp line (#$i): $line"];
            %k = %+;
        } elsif ($line =~ /^udp/ && $udp) {
            #udp        0      0 0.0.0.0:631                 0.0.0.0:*                               2769/cupsd
            $line =~ m!^(?P<proto>udp[46]?) \s+ (?P<recvq>\d+) \s+ (?P<sendq>\d+) \s+
                       (?P<local_host>\S+?):(?P<local_port>\w+|\*)\s+
                       (?P<foreign_host>\S+?):(?P<foreign_port>\w+|\*)
                       (?: \s+
                           (?P<state>\S+)?
                           (?: \s+ (?:
                                   (?P<pid>\d+)/(?P<program>.+?) |
                                   -
                           ))?
                       )? \s*$!x
                           or return [400, "Can't parse udp line (#$i): $line"];
            %k = %+;
        } elsif ($line =~ /^unix/ && $unix) {
            #Proto RefCnt Flags       Type       State         I-Node PID/Program name    Path
            #    unix  2      [ ACC ]     STREAM     LISTENING     650654 30463/gconfd-2      /tmp/orbit-t1/linc-76ff-0-3fc1dd3f2f2
            $line =~ m!^(?P<proto>unix) \s+ (?P<refcnt>\d+) \s+
                       \[\s*(?P<flags>\S*)\s*\] \s+ (?P<type>\S+) \s+
                       (?P<state>\S+|\s+) \s+ (?P<inode>\d+) \s+
                       (?: (?: (?P<pid>\d+)/(?P<program>.+?) | - ) \s+)?
                       (?P<path>.*?)\s*$!x
                           or return [400, "Can't parse unix line (#$i): $line"];
            %k = %+;
        } else {
            next;
        }
        push @conns, \%k;
    }

    [200, "OK", {active_conns => \@conns}];
}

1;
# ABSTRACT: Parse the output of Linux "netstat" command

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Netstat::linux - Parse the output of Linux "netstat" command

=head1 VERSION

This document describes version 0.150 of Parse::Netstat::linux (from Perl distribution Parse-Netstat), released on 2022-12-04.

=head1 SYNOPSIS

 use Parse::Netstat qw(parse_netstat);
 my $res = parse_netstat(output=>join("", `netstat -anp`), flavor=>"linux");

Sample `netstat -anp` output:

 Active Internet connections (servers and established)
 Proto Recv-Q Send-Q Local Address               Foreign Address             State       PID/Program name
 tcp        0      0 127.0.0.1:1027              0.0.0.0:*                   LISTEN      -
 tcp        0      0 builder.localdomain:1028    *:*                         LISTEN
 tcp        0      0 127.0.0.1:58159             0.0.0.0:*                   LISTEN      -
 tcp        0      0 127.0.0.1:58160             0.0.0.0:*                   LISTEN      -
 tcp        0      0 127.0.0.1:7634              0.0.0.0:*                   LISTEN      -
 tcp        0      0 0.0.0.0:22                  0.0.0.0:*                   LISTEN      -
 tcp        0      0 0.0.0.0:631                 0.0.0.0:*                   LISTEN      -
 tcp        0      0 127.0.0.1:25                0.0.0.0:*                   LISTEN      1234/program with space
 tcp        0      0 192.168.0.103:44922         1.2.3.4:143                 ESTABLISHED 25820/thunderbird-b
 tcp6       0      0 ::1:1028                    :::*                        LISTEN      -
 udp        0      0 0.0.0.0:631                 0.0.0.0:*                               -
 udp        0      0 192.168.0.103:56668         0.0.0.0:*                               -
 udp        0      0 192.168.0.103:52753         0.0.0.0:*                               8888/opera
 udp6       0      0 :::42069                    :::*                                    -
 Active UNIX domain sockets (servers and established)
 Proto RefCnt Flags       Type       State         I-Node PID/Program name    Path
 unix  2      [ ]         DGRAM                    6906   -                   /var/spool/postfix/dev/log
 unix  2      [ ACC ]     STREAM     LISTENING     650654 -                   /tmp/orbit-t1/linc-76ff-0-3fc1dd3f2f2
 unix  2      [ ACC ]     STREAM     LISTENING     1121541 16933/kate 123     /tmp/orbit-s1/linc-4225-0-267d23358095e

Sample result:

 [
   200,
   "OK",
   {
     active_conns => [
       {
         foreign_host => "0.0.0.0",
         foreign_port => "*",
         local_host => "127.0.0.1",
         local_port => 1027,
         proto => "tcp",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "builder.localdomain",
         local_port => 1028,
         proto => "tcp",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "0.0.0.0",
         foreign_port => "*",
         local_host => "127.0.0.1",
         local_port => 58159,
         proto => "tcp",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "0.0.0.0",
         foreign_port => "*",
         local_host => "127.0.0.1",
         local_port => 58160,
         proto => "tcp",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "0.0.0.0",
         foreign_port => "*",
         local_host => "127.0.0.1",
         local_port => 7634,
         proto => "tcp",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "0.0.0.0",
         foreign_port => "*",
         local_host => "0.0.0.0",
         local_port => 22,
         proto => "tcp",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "0.0.0.0",
         foreign_port => "*",
         local_host => "0.0.0.0",
         local_port => 631,
         proto => "tcp",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "0.0.0.0",
         foreign_port => "*",
         local_host => "127.0.0.1",
         local_port => 25,
         pid => 1234,
         program => "program with space",
         proto => "tcp",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "1.2.3.4",
         foreign_port => 143,
         local_host => "192.168.0.103",
         local_port => 44922,
         pid => 25820,
         program => "thunderbird-b",
         proto => "tcp",
         recvq => 0,
         sendq => 0,
         state => "ESTABLISHED",
       },
       {
         foreign_host => "::",
         foreign_port => "*",
         local_host => "::1",
         local_port => 1028,
         proto => "tcp6",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "0.0.0.0",
         foreign_port => "*",
         local_host => "0.0.0.0",
         local_port => 631,
         proto => "udp",
         recvq => 0,
         sendq => 0,
         state => "-",
       },
       {
         foreign_host => "0.0.0.0",
         foreign_port => "*",
         local_host => "192.168.0.103",
         local_port => 56668,
         proto => "udp",
         recvq => 0,
         sendq => 0,
         state => "-",
       },
       {
         foreign_host => "0.0.0.0",
         foreign_port => "*",
         local_host => "192.168.0.103",
         local_port => 52753,
         proto => "udp",
         recvq => 0,
         sendq => 0,
         state => "8888/opera",
       },
       {
         foreign_host => "::",
         foreign_port => "*",
         local_host => "::",
         local_port => 42069,
         proto => "udp6",
         recvq => 0,
         sendq => 0,
         state => "-",
       },
       {
         flags  => "",
         inode  => 6906,
         path   => "/var/spool/postfix/dev/log",
         proto  => "unix",
         refcnt => 2,
         state  => " ",
         type   => "DGRAM",
       },
       {
         flags  => "ACC",
         inode  => 650654,
         path   => "/tmp/orbit-t1/linc-76ff-0-3fc1dd3f2f2",
         proto  => "unix",
         refcnt => 2,
         state  => "LISTENING",
         type   => "STREAM",
       },
       {
         flags   => "ACC",
         inode   => 1121541,
         path    => "123     /tmp/orbit-s1/linc-4225-0-267d23358095e",
         pid     => 16933,
         program => "kate",
         proto   => "unix",
         refcnt  => 2,
         state   => "LISTENING",
         type    => "STREAM",
       },
     ],
   },
 ]

=head1 FUNCTIONS


=head2 parse_netstat

Usage:

 parse_netstat(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse the output of Linux "netstat" command.

Netstat can be called with C<-n> (show raw IP addresses and port numbers instead
of hostnames or port names) or without. It can be called with C<-a> (show all
listening and non-listening socket) option or without. And can be called with
C<-p> (show PID/program names) or without.

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
