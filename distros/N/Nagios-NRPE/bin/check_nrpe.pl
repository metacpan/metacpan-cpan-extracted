#!/usr/bin/perl

=head1 NAME

check_nrpe.pl - An implemetation of the check_nrpe command in pure perl

=head1 SYNOPSIS

 Usage: check_nrpe -H <host> -c <command> [ -b <bindaddr> ] [-4] [-6] [-n] [-u] [-p <port>] [-t <timeout>] [-a <arglist...>]

 Options:
 -4            = use ipv4 only
 -6            = use ipv6 only
 -H <host>     = The address of the host running the NRPE daemon
 -b <bindaddr> = bind to local address
 -c command    = The name of the command that the remote daemon should run
 -n            = Do no use SSL
 -p [port]     = The port on which the daemon is running (default=5666)
 -t [timeout]  = Number of seconds before connection times out (default=10)
 -u            = Make socket timeouts return an UNKNOWN state instead of CRITICAL
 -a [arglist]  = Optional arguments that should be passed to the command.  Multiple
                 arguments should be separated by a space.  If provided, this must be
                 the last option supplied on the command line.

=head1 DESCRIPTION

Using this script you can request the current status of checks on your remote hosts

It takes the following options

=head2 -4

Use ipv4 only

=head2 -6

Use ipv6 only

=head2 -H -host <some host>

The remote host running NRPE-Server (default localhost)

=head2 -b --bindaddr <some local address>

Bind to this local address

=head2 -p --port <some port>

The remote port on which the NRPE-server listens

=head2 -n --nossl

Don't use SSL

=head2 -c --command <some command> (--check is deprecated)

The check command defined in the nrpe.cfg file you would like to trigger

=head2 -h --help

This help.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the authors (see AUTHORS file).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.010_000;

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Data::Dumper;
use Nagios::NRPE::Client;

our $VERSION = '1.0.3';

my (
    $arglist, $bindaddr, $check, $host,    $ipv4,
    $ipv6,    $port,     $ssl,   $timeout, $unknown
);

Getopt::Long::Configure('no_ignore_case');
my $result = GetOptions(
    "4"                 => \$ipv4,
    "6"                 => \$ipv6,
    "H|host=s"          => \$host,
    "a|arglist"         => \$arglist,
    "b|bindadr=s"       => \$bindaddr,
    "c|command|check=s" => \$check,
    "n|nossl"           => \$ssl,
    "p|port=s"          => \$port,
    "t|timeout=i"       => \$timeout,
    "u|unknown"         => \$unknown,
    "h|help"            => sub {
        pod2usage(
            -exitval   => 0,
            -verbose   => 99,
            -noperldoc => 1
        );
    }
);

if ($ssl) {
    $ssl = 0;
}
else {
    $ssl = 1;
}
$bindaddr = 0           unless defined $bindaddr;
$ipv4     = 0           unless defined $ipv4;
$ipv6     = 0           unless defined $ipv6;
$unknown  = 0           unless defined $unknown;
$host     = "localhost" unless defined $host;
$port     = 5666        unless defined $port;
$timeout  = 20          unless defined $timeout;

die "Error: No check was given" unless defined $check;
my $client = Nagios::NRPE::Client->new(
    arglist  => \@ARGV,
    bindaddr => $bindaddr,
    check    => $check,
    host     => $host,
    ipv4     => $ipv4,
    ipv6     => $ipv6,
    port     => $port,
    ssl      => $ssl,
    timeout  => $timeout,
    unknown  => $unknown
);
my $response = $client->run();

if ( $response->{error} ) {
    if ($unknown) {
        print "Socket error: $response->{reason}\n";
        exit 3;
    }
    print "Socket error: $response->{reason}\n";
    exit 2;
}
print $response->{buffer} . "\n";
exit $response->{result_code};
