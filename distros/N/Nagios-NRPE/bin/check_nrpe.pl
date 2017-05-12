#!/usr/bin/perl

=head1 NAME

check_nrpe.pl - An implemetation of the check_nrpe command in pure perl

=head1 SYNOPSIS

  check_nrpe.pl -H localhost -p 5666 -c check_users -w 50 -c 100

=head1 DESCRIPTION

Using this script you can request the current status of checks on your remote hosts

It takes the following options

=head2 -H -host <somehost>

The remote host running NRPE-Server (default localhost)

=head2 -p --port <someport>

The remote port on which the NRPE-server listens

=head2 -s --ssl

Use SSL or don't use SSL (not yet implemented)

=head2 -c --check <somecheck>

The check command defined in the nrpe.cfg file you would like to trigger

=head2 -h --help

This help.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andreas Marschke <andreas.marschke@googlemail.com>.

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

our $VERSION = '';

my ($host,$port,$check,$ssl,$timeout);

Getopt::Long::Configure('no_ignore_case');
my $result = GetOptions (
  "H|host=s"  => \$host,
  "p|port=s"  => \$port,
  "c|check=s" => \$check,
  "s|ssl"     => \$ssl,
  "h|help"    => sub { pod2usage(-exitval   => 0,
                                 -verbose   => 99,
                                 -noperldoc => 1)
                     });


$ssl  = 0           unless defined $ssl;
$host = "localhost" unless defined $host;
$port = 5666        unless defined $port;

die "Error: No check was given" unless defined $check;

my $client = Nagios::NRPE::Client->new(
                host => $host,
                port => $port,
                ssl => $ssl,
                timeout => 20,
                arglist => \@ARGV,
                check => $check
             );
my $response = $client->run();

print $response->{buffer}."\n";
