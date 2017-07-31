#!/usr/bin/perl

=head1 NAME

Nagios::NRPE - A Nagios NRPE implementation in pure perl

=head1 SYNOPSIS

 # Executing a check on an NRPE-Server
 use Nagios::NRPE::Client;

 my $client = Nagios::NRPE::Client->new( host => "localhost", check => 'check_cpu');
 my $response = $client->run();
 if(defined $response->{error}) {
   print "ERROR: Couldn't run check ".$client->check()." because of: "$response->{reason}."\n";
 } else {
   print $response->{status}."\n";
 }

 # Reading and Writing Nagios NRPE Packets

 use IO::Socket;
 use IO::Socket::INET;
 # Import necessary constants into Namespace
 use Nagios::NRPE::Packet qw(NRPE_PACKET_VERSION_3
                             NRPE_PACKET_QUERY
                             STATE_UNKNOWN
                             STATE_CRITICAL
                             STATE_WARNING
                             STATE_OK);

 my $packet = Nagios::NRPE::Packet->new();

 my $socket = IO::Socket::INET->new(
                    PeerAddr => $host,
                    PeerPort => $port,
                    Proto    => 'tcp',
                    Type     => SOCK_STREAM) or die "ERROR: $@ \n";

 print $socket $packet->assemble(type => QUERY_PACKET,
                              buffer => "check_load 1 2 3",
                              version => NRPE_PACKET_VERSION_3 );

 my $data = <$socket>
 my $response = $packet->deassemble($data);

 print $response->{buffer};

=head1 DESCRIPTION

This file currently only serves as a stub so Build.PL will find it. For more information on
the submodules please read Nagios::NRPE::Client or Nagios::NRPE::Packet or Nagios::NRPE::Daemon.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the authors (see AUTHORS file).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Nagios::NRPE;

use strict;
use warnings;

our $VERSION = '1.0.2';

1;
