package Parse::Netstat::win32;

our $DATE = '2017-02-10'; # DATE
our $VERSION = '0.14'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parse_netstat);

our %SPEC;

$SPEC{parse_netstat} = {
    v => 1.1,
    summary => 'Parse the output of Windows "netstat" command',
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
    },
};
sub parse_netstat {
    my %args = @_;
    my $output = $args{output} or return [400, "Please specify output"];
    my $tcp    = $args{tcp} // 1;
    my $udp    = $args{udp} // 1;

    my @conns;
    my $i = 0;
    my $cur; # whether we're currently parsing TCP or UDP entry
    my $k;
    for my $line (split /^/, $output) {
        $i++;
        if ($line =~ /^\s*TCP\s/ && $tcp) {
            #  Proto  Local Address          Foreign Address        State           PID
            #  TCP    0.0.0.0:135            0.0.0.0:0              LISTENING       988
            #  c:\windows\system32\WS2_32.dll
            #  C:\WINDOWS\system32\RPCRT4.dll
            #  c:\windows\system32\rpcss.dll
            #  C:\WINDOWS\system32\svchost.exe
            #  -- unknown component(s) --
            #  [svchost.exe]
            #
            $line =~ m!^\s*(?P<proto>TCP6?) \s+
                       (?P<local_host>\S+?):(?P<local_port>\w+)\s+
                       (?P<foreign_host>\S+?):(?P<foreign_port>\w+|\*)\s+
                       (?P<state>\S+) (?: \s+ (?:
                               (?P<pid>\d+)
                       ))? \s*$!x
                           or return [400, "Can't parse tcp line (#$i): $line"];
            $k = { %+ };
            $cur = 'tcp';
            for ($k->{proto}) { $_ = lc }
            push @conns, $k;
        } elsif ($line =~ /^\s*UDP\s/ && $udp) {
            #  UDP    0.0.0.0:500            *:*                                    696
            #  [lsass.exe]
            #
            # XXX state not yet parsed
            $line =~ m!^\s*(?P<proto>UDP6?) \s+
                       (?P<local_host>\S+?):(?P<local_port>\w+)\s+
                       (?P<foreign_host>\S+?):(?P<foreign_port>\w+|\*)\s+
                       (?: \s+ (?:
                               (?P<pid>\d+)
                       ))? \s*$!x
                           or return [400, "Can't parse udp line (#$i): $line"];
            $k = { %+ };
            $cur = 'udp';
            for ($k->{proto}) { $_ = lc }
            push @conns, $k;
        } elsif ($cur) {
            $k->{execs} //= [];
            next if $line =~ /^\s*--/; # e.g. -- unknown component(s) --
            next if $line =~ /^\s*can not/i; # e.g.  Can not obtain ownership information
            push @{ $k->{execs} }, $1 if $line =~ /^\s*(\S.*?)\s*$/;
            next;
        } else {
            # a blank line or headers. ignore.
        }
    }

    [200, "OK", {active_conns => \@conns}];
}

1;
# ABSTRACT: Parse the output of Windows "netstat" command

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Netstat::win32 - Parse the output of Windows "netstat" command

=head1 VERSION

This document describes version 0.14 of Parse::Netstat::win32 (from Perl distribution Parse-Netstat), released on 2017-02-10.

=head1 SYNOPSIS

 use Parse::Netstat qw(parse_netstat);
 my $res = parse_netstat(output=>join("", `netstat -anp`), flavor=>"win32");

Sample `netstat -anp` output:

 Active Connections
 
   Proto  Local Address          Foreign Address        State           PID
   TCP    0.0.0.0:135            0.0.0.0:0              LISTENING       988
   c:\windows\system32\WS2_32.dll
   C:\WINDOWS\system32\RPCRT4.dll
   c:\windows\system32\rpcss.dll
   C:\WINDOWS\system32\svchost.exe
   -- unknown component(s) --
   [svchost.exe]
 
   TCP    0.0.0.0:445            0.0.0.0:0              LISTENING       4
   [System]
 
   TCP    127.0.0.1:1027         0.0.0.0:0              LISTENING       1244
   [alg.exe]
 
   TCP    192.168.0.104:139      0.0.0.0:0              LISTENING       4
   [System]
 
   UDP    0.0.0.0:1025           *:*                                    1120
   C:\WINDOWS\system32\mswsock.dll
   c:\windows\system32\WS2_32.dll
   c:\windows\system32\DNSAPI.dll
   c:\windows\system32\dnsrslvr.dll
   C:\WINDOWS\system32\RPCRT4.dll
   [svchost.exe]
 
   UDP    0.0.0.0:500            *:*                                    696
   [lsass.exe]

Sample result:

 [
   200,
   "OK",
   {
     active_conns => [
       {
         execs => [
           "c:\\windows\\system32\\WS2_32.dll",
           "C:\\WINDOWS\\system32\\RPCRT4.dll",
           "c:\\windows\\system32\\rpcss.dll",
           "C:\\WINDOWS\\system32\\svchost.exe",
           "[svchost.exe]",
         ],
         foreign_host => "0.0.0.0",
         foreign_port => 0,
         local_host => "0.0.0.0",
         local_port => 135,
         pid => 988,
         proto => "tcp",
         state => "LISTENING",
       },
       {
         execs => ["[System]"],
         foreign_host => "0.0.0.0",
         foreign_port => 0,
         local_host => "0.0.0.0",
         local_port => 445,
         pid => 4,
         proto => "tcp",
         state => "LISTENING",
       },
       {
         execs => ["[alg.exe]"],
         foreign_host => "0.0.0.0",
         foreign_port => 0,
         local_host => "127.0.0.1",
         local_port => 1027,
         pid => 1244,
         proto => "tcp",
         state => "LISTENING",
       },
       {
         execs => ["[System]"],
         foreign_host => "0.0.0.0",
         foreign_port => 0,
         local_host => "192.168.0.104",
         local_port => 139,
         pid => 4,
         proto => "tcp",
         state => "LISTENING",
       },
       {
         execs => [
           "C:\\WINDOWS\\system32\\mswsock.dll",
           "c:\\windows\\system32\\WS2_32.dll",
           "c:\\windows\\system32\\DNSAPI.dll",
           "c:\\windows\\system32\\dnsrslvr.dll",
           "C:\\WINDOWS\\system32\\RPCRT4.dll",
           "[svchost.exe]",
         ],
         foreign_host => "*",
         foreign_port => "*",
         local_host => "0.0.0.0",
         local_port => 1025,
         pid => 1120,
         proto => "udp",
       },
       {
         execs => ["[lsass.exe]"],
         foreign_host => "*",
         foreign_port => "*",
         local_host => "0.0.0.0",
         local_port => 500,
         pid => 696,
         proto => "udp",
       },
     ],
   },
 ]

=head1 FUNCTIONS


=head2 parse_netstat

Usage:

 parse_netstat(%args) -> [status, msg, result, meta]

Parse the output of Windows "netstat" command.

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

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Parse-Netstat>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Parse-Netstat>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-Netstat>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
