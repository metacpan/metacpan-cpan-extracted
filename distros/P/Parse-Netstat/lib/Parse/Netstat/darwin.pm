package Parse::Netstat::darwin;

our $DATE = '2017-02-10'; # DATE
our $VERSION = '0.14'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parse_netstat);

our %SPEC;

require Parse::Netstat::freebsd;

$SPEC{parse_netstat} = do {
    my $meta = { %{ $Parse::Netstat::freebsd::SPEC{parse_netstat} } };
    $meta->{summary} = 'Parse the output of Mac OS X "netstat" command',
    $meta->{description} = <<'_';

Netstat can be called with `-n` (show raw IP addresses and port numbers instead
of hostnames or port names) or without. It can be called with `-a` (show all
listening and non-listening socket) option or without.

_
    $meta;
};
sub parse_netstat {
    Parse::Netstat::freebsd::parse_netstat(@_);
}
1;
# ABSTRACT: Parse the output of Mac OS X "netstat" command

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Netstat::darwin - Parse the output of Mac OS X "netstat" command

=head1 VERSION

This document describes version 0.14 of Parse::Netstat::darwin (from Perl distribution Parse-Netstat), released on 2017-02-10.

=head1 SYNOPSIS

 use Parse::Netstat qw(parse_netstat);
 my $res = parse_netstat(output=>join("", `netstat -an`), flavor=>"darwin");

Sample `netstat -an` output:

 Active Internet connections (including servers)
 Proto Recv-Q Send-Q  Local Address          Foreign Address        (state)
 tcp4       0      0  10.8.0.6.54433         1.2.3.4.443            ESTABLISHED
 tcp46      0      0  *.80                   *.*                    LISTEN
 tcp6       0      0  *.88                   *.*                    LISTEN
 udp4       0      0  *.*                    *.*
 udp6       0      0  *.52919                *.*
 udp46      0      0  *.*                    *.*
 Active Multipath Internet connections
 Proto/ID  Flags      Local Address          Foreign Address        (state)
 Active LOCAL (UNIX) domain sockets
 Address          Type   Recv-Q Send-Q            Inode             Conn             Refs          Nextref Addr
 4f1eb4c58685585f stream      0      0                0 4f1eb4c5868572ef                0                0 /var/run/mDNSResponder
 4f1eb4c5868572ef stream      0      0                0 4f1eb4c58685585f                0                0
 4f1eb4c578f0c92f stream      0      0                0 4f1eb4c578f0c2ef                0                0
 4f1eb4c58bd4e227 stream      0      0 4f1eb4c5891011b7                0                0                0 /var/run/vmnat.40388
 Registered kernel control modules
 id       flags    pcbcount rcvbuf   sndbuf   name
        1        9        0   131072   131072 com.apple.flow-divert
        2        1        1    16384     2048 com.apple.nke.sockwall
        3        9        0   524288   524288 com.apple.content-filter
        4        9        0     8192     2048 com.apple.packet-mangler
        5        1        3    65536    65536 com.apple.net.necp_control
        6        1       10    65536    65536 com.apple.net.netagent
        7        9        5   524288   524288 com.apple.net.utun_control
        8        1        0    65536    65536 com.apple.net.ipsec_control
        9        0       39     8192     2048 com.apple.netsrc
        a       18        4     8192     2048 com.apple.network.statistics
        b        5        0     8192     2048 com.apple.network.tcp_ccdebug
        c        1        1     8192     2048 com.apple.network.advisory
        d        1        1     8192     2048 com.vmware.kext.vmci
        e        1        9   229376   229376 com.vmware.kext.vmnet
        f        1      168     8192     2048 com.vmware.kext.vmx86
 Active kernel event sockets
 Proto Recv-Q Send-Q vendor  class subcla
 kevt       0      0      1      1     11
 kevt       0      0      1      1      7
 kevt       0      0      1      1      1
 kevt       0      0      1      4      0
 kevt       0      0      1      6      1
 kevt       0      0      1      6      1
 kevt       0      0      1      1      2
 kevt       0      0      1      6      1
 kevt       0      0      1      6      1
 kevt       0      0      1      1     10
 kevt       0      0   1001      5     11
 kevt       0      0      1      6      1
 kevt       0      0      1      6      1
 kevt       0      0      1      6      1
 kevt       0      0      1      6      1
 kevt       0      0      1      6      1
 kevt       0      0      1      6      1
 kevt       0      0      1      1      2
 kevt       0      0      1      1      2
 kevt       0      0      1      6      1
 kevt       0      0      1      1      0
 Active kernel control sockets
 Proto Recv-Q Send-Q   unit     id name
 kctl       0      0      1      2 com.apple.nke.sockwall
 kctl       0      0      1      5 com.apple.net.necp_control
 kctl       0      0      2      5 com.apple.net.necp_control
 kctl       0      0      3      5 com.apple.net.necp_control
 kctl       0      0      1      6 com.apple.net.netagent
 kctl       0      0      2      6 com.apple.net.netagent
 kctl       0      0      3      6 com.apple.net.netagent
 kctl       0      0      4      6 com.apple.net.netagent
 kctl       0      0      5      6 com.apple.net.netagent
 kctl       0      0      6      6 com.apple.net.netagent
 kctl       0      0      7      6 com.apple.net.netagent
 kctl       0      0      8      6 com.apple.net.netagent
 kctl       0      0     10      6 com.apple.net.netagent
 kctl       0      0     11      6 com.apple.net.netagent
 kctl       0      0      1      7 com.apple.net.utun_control
 kctl       0      0      2      7 com.apple.net.utun_control
 kctl       0      0      3      7 com.apple.net.utun_control
 kctl       0      0      4      7 com.apple.net.utun_control
 kctl       0      0      5      7 com.apple.net.utun_control
 kctl       0      0      1      9 com.apple.netsrc
 kctl       0      0      2      9 com.apple.netsrc
 kctl       0      0      3      9 com.apple.netsrc
 kctl       0      0      4      9 com.apple.netsrc
 kctl       0      0      5      9 com.apple.netsrc
 kctl       0      0      6      9 com.apple.netsrc
 kctl       0      0      7      9 com.apple.netsrc
 kctl       0      0      9      9 com.apple.netsrc
 kctl       0      0     10      9 com.apple.netsrc
 kctl       0      0     11      9 com.apple.netsrc
 kctl       0      0     12      9 com.apple.netsrc
 kctl       0      0     13      9 com.apple.netsrc
 kctl       0      0     14      9 com.apple.netsrc
 kctl       0      0     15      9 com.apple.netsrc
 kctl       0      0     16      9 com.apple.netsrc
 kctl       0      0     17      9 com.apple.netsrc
 kctl       0      0     18      9 com.apple.netsrc
 kctl       0      0     19      9 com.apple.netsrc
 kctl       0      0     20      9 com.apple.netsrc
 kctl       0      0     21      9 com.apple.netsrc
 kctl       0      0     22      9 com.apple.netsrc
 kctl       0      0     23      9 com.apple.netsrc
 kctl       0      0     24      9 com.apple.netsrc
 kctl       0      0     25      9 com.apple.netsrc
 kctl       0      0     26      9 com.apple.netsrc
 kctl       0      0     27      9 com.apple.netsrc
 kctl       0      0     28      9 com.apple.netsrc
 kctl       0      0     29      9 com.apple.netsrc
 kctl       0      0     30      9 com.apple.netsrc
 kctl       0      0     31      9 com.apple.netsrc
 kctl       0      0     32      9 com.apple.netsrc
 kctl       0      0     33      9 com.apple.netsrc
 kctl       0      0     34      9 com.apple.netsrc
 kctl       0      0     35      9 com.apple.netsrc
 kctl       0      0     36      9 com.apple.netsrc
 kctl       0      0     38      9 com.apple.netsrc
 kctl       0      0     41      9 com.apple.netsrc
 kctl       0      0     43      9 com.apple.netsrc
 kctl       0      0     44      9 com.apple.netsrc
 kctl       0      0      1     10 com.apple.network.statistics
 kctl       0      0      2     10 com.apple.network.statistics
 kctl       0      0      3     10 com.apple.network.statistics
 kctl       0      0      4     10 com.apple.network.statistics
 kctl       0      0      1     12 com.apple.network.advisory
 kctl       0      0      1     13 com.vmware.kext.vmci
 kctl       0      0      1     14 com.vmware.kext.vmnet
 kctl       0      0      2     14 com.vmware.kext.vmnet
 kctl       0      0      3     14 com.vmware.kext.vmnet
 kctl       0      0      4     14 com.vmware.kext.vmnet
 kctl       0      0      5     14 com.vmware.kext.vmnet
 kctl       0      0      6     14 com.vmware.kext.vmnet
 kctl       0      0      7     14 com.vmware.kext.vmnet
 kctl       0      0      8     14 com.vmware.kext.vmnet
 kctl       0      0      9     14 com.vmware.kext.vmnet
 kctl       0      0      1     15 com.vmware.kext.vmx86

Sample result:

 [
   200,
   "OK",
   {
     active_conns => [
       {
         foreign_host => "1.2.3.4",
         foreign_port => 443,
         local_host => "10.8.0.6",
         local_port => 54433,
         proto => "tcp4",
         recvq => 0,
         sendq => 0,
         state => "ESTABLISHED",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 80,
         proto => "tcp46",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => 88,
         proto => "tcp6",
         recvq => 0,
         sendq => 0,
         state => "LISTEN",
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
         local_port => 52919,
         proto => "udp6",
         recvq => 0,
         sendq => 0,
       },
       {
         foreign_host => "*",
         foreign_port => "*",
         local_host => "*",
         local_port => "*",
         proto => "udp46",
         recvq => 0,
         sendq => 0,
       },
       {},
       {},
       {
         addr    => "/var/run/mDNSResponder",
         address => "4f1eb4c58685585f",
         conn    => "4f1eb4c5868572ef",
         inode   => 0,
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         address => "4f1eb4c5868572ef",
         conn    => "4f1eb4c58685585f",
         inode   => 0,
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         address => "4f1eb4c578f0c92f",
         conn    => "4f1eb4c578f0c2ef",
         inode   => 0,
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {
         addr    => "/var/run/vmnat.40388",
         address => "4f1eb4c58bd4e227",
         conn    => 0,
         inode   => "4f1eb4c5891011b7",
         nextref => 0,
         proto   => "unix",
         recvq   => 0,
         refs    => 0,
         sendq   => 0,
         type    => "stream",
       },
       {},
     ],
   },
 ]

=head1 FUNCTIONS


=head2 parse_netstat

Usage:

 parse_netstat(%args) -> [status, msg, result, meta]

Parse the output of Mac OS X "netstat" command.

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
