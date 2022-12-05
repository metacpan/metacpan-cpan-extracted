package Parse::Netstat::solaris;

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
    summary => 'Parse the output of Solaris "netstat" command',
    description => <<'_',

Netstat can be called with `-n` (show raw IP addresses and port numbers instead
of hostnames or port names) or without. It can be called with `-a` (show all
listening and non-listening socket) option or without.

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

    my $proto = '';
    my @conns;
    my $i = 0;
    for my $line (split /^/, $output) {
        $i++;
        my %k;
        if ($line =~ /^UDP: IPv([46])/) {
            $proto = "udp$1";
        } elsif ($line =~ /^TCP: IPv([46])/) {
            $proto = "tcp$1";
        } elsif ($line =~ /^Active UNIX domain sockets/) {
            $proto = "unix";
        } elsif ($proto =~ /udp/ && $udp) {
            #UDP: IPv4
            #   Local Address        Remote Address      State
            #-------------------- -------------------- ----------
            #8.8.17.4.15934   8.8.7.7.53       Connected
            $line =~ /^\s*$/ and next; # blank line
            $line =~ /^\s+/ and next; # header
            $line =~ /^[- ]+$/ and next; # separator
            $line =~ m!^(?P<local_host>\S+?)\.(?P<local_port>\w+)\s+
                       (?P<foreign_host>\S+?)\.(?P<foreign_port>\w+|\*)\s+
                       (?P<state>\S+)
                       \s*$!x
                           or return [400, "Can't parse udp line (#$i): $line"];
            %k = %+;
            $k{proto} = $proto;
        } elsif ($proto =~ /tcp/ && $tcp) {
            #TCP: IPv4
            #   Local Address        Remote Address    Swind Send-Q Rwind Recv-Q    State
            #-------------------- -------------------- ----- ------ ----- ------ -----------
            #8.8.17.4.1337    8.8.213.120.65472 262140      0 1049920      0 ESTABLISHED
            $line =~ /^\s*$/ and next; # blank line
            $line =~ /^\s+/ and next; # header
            $line =~ /^[- ]+$/ and next; # separator
            $line =~ m!^(?P<local_host>\S+?)\.(?P<local_port>\w+)\s+
                       (?P<foreign_host>\S+?)\.(?P<foreign_port>\w+|\*)\s+
                       (?P<swind>\d+) \s+
                       (?P<sendq>\d+) \s+
                       (?P<rwind>\d+) \s+
                       (?P<recvq>\d+) \s+
                       (?P<state>\S+)
                       \s*$!x
                           or return [400, "Can't parse tcp line (#$i): $line"];
            %k = %+;
            $k{proto} = $proto;
        } elsif ($proto eq 'unix' && $unix) {
            #Active UNIX domain sockets
            #Address  Type          Vnode     Conn  Local Addr      Remote Addr
            #30258256428 stream-ord 00000000 00000000
            $line =~ /^\s*$/ and next; # blank line
            $line =~ /^Address\s/ and next; # header
            #$line =~ /^[- ]+$/ and next; # separator
            $line =~ m!^(?P<address>[0-9a-f]+)\s+
                       (?P<type>\S+)\s+
                       (?P<vnode>[0-9a-f]+)\s+
                       (?P<conn>[0-9a-f]+)\s+
                       (?:
                           (?P<local_addr>\S+)\s+
                           (?:
                               (?P<remote_addr>\S+)\s+
                           )?
                       )?
                       \s*$!x
                           or return [400, "Can't parse unix line (#$i): $line"];
            %k = %+;
            $k{proto} = $proto;
        } else {
            # XXX error? because there are no other lines
            next;
        }
        push @conns, \%k;
    }

    [200, "OK", {active_conns => \@conns}];
}

1;
# ABSTRACT: Parse the output of Solaris "netstat" command

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Netstat::solaris - Parse the output of Solaris "netstat" command

=head1 VERSION

This document describes version 0.150 of Parse::Netstat::solaris (from Perl distribution Parse-Netstat), released on 2022-12-04.

=head1 SYNOPSIS

 use Parse::Netstat qw(parse_netstat);
 my $res = parse_netstat(output=>join("", `netstat -n`), flavor=>"solaris");

Sample `netstat -n` output:

 UDP: IPv4
    Local Address        Remote Address      State
 -------------------- -------------------- ----------
 8.8.17.4.15934   8.8.7.7.53       Connected
 127.0.0.1.32859      127.0.0.1.514        Connected
 127.0.0.1.32860      127.0.0.1.514        Connected
 
 TCP: IPv4
    Local Address        Remote Address    Swind Send-Q Rwind Recv-Q    State
 -------------------- -------------------- ----- ------ ----- ------ -----------
 8.8.17.4.1337    8.8.213.120.65472 262140      0 1049920      0 ESTABLISHED
 8.8.17.4.44306   8.8.17.4.111     57304      0 1055220      0 TIME_WAIT
 8.8.17.4.44064   8.8.17.4.32774   57260      0 1055220      0 TIME_WAIT
 8.8.17.4.44308   8.8.17.4.32774   57260      0 1055220      0 TIME_WAIT
 8.8.17.4.44066   8.8.17.4.111     57304      0 1055220      0 TIME_WAIT
 8.8.17.4.44310   8.8.17.4.111     57304      0 1055220      0 TIME_WAIT
 
 Active UNIX domain sockets
 Address  Type          Vnode     Conn  Local Addr      Remote Addr
 30258256428 stream-ord 00000000 00000000                               
 30575aa2b38 stream-ord 00000000 00000000                               
 305744acaf8 stream-ord 00000000 00000000                               
 30575aa3b88 stream-ord 00000000 00000000                               
 3013c427d68 stream-ord 00000000 00000000                               
 303b66230f8 stream-ord 00000000 00000000                               
 3042fbbb228 stream-ord 30b59894f40 00000000 /tmp/ssh-MyY25402/agent.25402                
 30186d43d70 stream-ord 00000000 00000000                               
 303e8e332f8 stream-ord 00000000 00000000                               
 3049e75ece0 stream-ord 302d8344500 00000000 /var/tmp/amavisd-new/abgeber/amavisd.sock                
 3049e75f250 stream-ord 00000000 00000000                               

Sample result:

 [
   200,
   "OK",
   {
     active_conns => [
       {},
       {
         foreign_host => "8.8.7.7",
         foreign_port => 53,
         local_host => "8.8.17.4",
         local_port => 15934,
         proto => "udp4",
         state => "Connected",
       },
       {
         foreign_host => "127.0.0.1",
         foreign_port => 514,
         local_host => "127.0.0.1",
         local_port => 32859,
         proto => "udp4",
         state => "Connected",
       },
       {
         foreign_host => "127.0.0.1",
         foreign_port => 514,
         local_host => "127.0.0.1",
         local_port => 32860,
         proto => "udp4",
         state => "Connected",
       },
       {},
       {
         foreign_host => "8.8.213.120",
         foreign_port => 65472,
         local_host => "8.8.17.4",
         local_port => 1337,
         proto => "tcp4",
         recvq => 0,
         rwind => 1049920,
         sendq => 0,
         state => "ESTABLISHED",
         swind => 262140,
       },
       {
         foreign_host => "8.8.17.4",
         foreign_port => 111,
         local_host => "8.8.17.4",
         local_port => 44306,
         proto => "tcp4",
         recvq => 0,
         rwind => 1055220,
         sendq => 0,
         state => "TIME_WAIT",
         swind => 57304,
       },
       {
         foreign_host => "8.8.17.4",
         foreign_port => 32774,
         local_host => "8.8.17.4",
         local_port => 44064,
         proto => "tcp4",
         recvq => 0,
         rwind => 1055220,
         sendq => 0,
         state => "TIME_WAIT",
         swind => 57260,
       },
       {
         foreign_host => "8.8.17.4",
         foreign_port => 32774,
         local_host => "8.8.17.4",
         local_port => 44308,
         proto => "tcp4",
         recvq => 0,
         rwind => 1055220,
         sendq => 0,
         state => "TIME_WAIT",
         swind => 57260,
       },
       {
         foreign_host => "8.8.17.4",
         foreign_port => 111,
         local_host => "8.8.17.4",
         local_port => 44066,
         proto => "tcp4",
         recvq => 0,
         rwind => 1055220,
         sendq => 0,
         state => "TIME_WAIT",
         swind => 57304,
       },
       {
         foreign_host => "8.8.17.4",
         foreign_port => 111,
         local_host => "8.8.17.4",
         local_port => 44310,
         proto => "tcp4",
         recvq => 0,
         rwind => 1055220,
         sendq => 0,
         state => "TIME_WAIT",
         swind => 57304,
       },
       {},
       {
         address => 30258256428,
         conn    => "00000000",
         proto   => "unix",
         type    => "stream-ord",
         vnode   => "00000000",
       },
       {
         address => "30575aa2b38",
         conn    => "00000000",
         proto   => "unix",
         type    => "stream-ord",
         vnode   => "00000000",
       },
       {
         address => "305744acaf8",
         conn    => "00000000",
         proto   => "unix",
         type    => "stream-ord",
         vnode   => "00000000",
       },
       {
         address => "30575aa3b88",
         conn    => "00000000",
         proto   => "unix",
         type    => "stream-ord",
         vnode   => "00000000",
       },
       {
         address => "3013c427d68",
         conn    => "00000000",
         proto   => "unix",
         type    => "stream-ord",
         vnode   => "00000000",
       },
       {
         address => "303b66230f8",
         conn    => "00000000",
         proto   => "unix",
         type    => "stream-ord",
         vnode   => "00000000",
       },
       {
         address    => "3042fbbb228",
         conn       => "00000000",
         local_addr => "/tmp/ssh-MyY25402/agent.25402",
         proto      => "unix",
         type       => "stream-ord",
         vnode      => "30b59894f40",
       },
       {
         address => "30186d43d70",
         conn    => "00000000",
         proto   => "unix",
         type    => "stream-ord",
         vnode   => "00000000",
       },
       {
         address => "303e8e332f8",
         conn    => "00000000",
         proto   => "unix",
         type    => "stream-ord",
         vnode   => "00000000",
       },
       {
         address    => "3049e75ece0",
         conn       => "00000000",
         local_addr => "/var/tmp/amavisd-new/abgeber/amavisd.sock",
         proto      => "unix",
         type       => "stream-ord",
         vnode      => "302d8344500",
       },
       {
         address => "3049e75f250",
         conn    => "00000000",
         proto   => "unix",
         type    => "stream-ord",
         vnode   => "00000000",
       },
     ],
   },
 ]

=head1 FUNCTIONS


=head2 parse_netstat

Usage:

 parse_netstat(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse the output of Solaris "netstat" command.

Netstat can be called with C<-n> (show raw IP addresses and port numbers instead
of hostnames or port names) or without. It can be called with C<-a> (show all
listening and non-listening socket) option or without.

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
