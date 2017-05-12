#!/usr/bin/perl

=head1 NAME

Nagios::NRPE::Client - A Nagios NRPE client

=head1 SYNOPSIS

 use Nagios::NRPE::Client;

 my $client = Nagios::NRPE::Client->new( host => "localhost", check => 'check_cpu');
 my $response = $client->run();
 if(defined $response->{error}) {
   print "ERROR: Couldn't run check ".$client->check()." because of: "$response->{reason}."\n";
 } else {
   print $response->{status}."\n";
 }

=head1 DESCRIPTION

This Perl Module implements Version 2 of the NRPE-Protocol. With this module you can execute 

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andreas Marschke <andreas.marschke@googlemail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Nagios::NRPE::Client;

our $VERSION = '0.003';

use 5.010_000;

use strict;
use warnings;

use Data::Dumper;
use Carp;
use IO::Socket;
use IO::Socket::INET;
use Nagios::NRPE::Packet qw(NRPE_PACKET_VERSION_2
			    NRPE_PACKET_QUERY
			    MAX_PACKETBUFFER_LENGTH
			    STATE_UNKNOWN
			    STATE_CRITICAL
			    STATE_WARNING
			    STATE_OK);

=head1 SUBROUTINES

=over 2

=item new()

Constructor for the Nagios::NRPE::Client Object

 example

 my $client = Nagios::NRPE::Client->new( host => "localhost", check => 'check_cpu');

Takes a hash of options:

=item host => <hostname or IP>

The hostname or IP on which the NRPE-Server is running

=item port => <Portnumber>

The port number at which the NRPE-Server is listening

=item timeout => <number in seconds>

Timeout for TCP/IP communication

=item arglist => ["arg","uments"]

List of arguments attached to the check

=item check => "check_command"

Command defined in the nrpe.cfg on the NRPE-Server

=item ssl => 0,1

Use or don't use SSL

=back

=cut

sub new {
  my ($class,%hash) = @_;
  my $self = {};
  $self->{host} = delete $hash{host} || "localhost";
  $self->{port} = delete $hash{port} || 5666;
  $self->{timeout} = delete $hash{timeout} || 30;
  $self->{arglist} = delete $hash{arglist} || [];
  $self->{check} = delete $hash{check} || "";
  $self->{ssl} = delete  $hash{ssl} || 0;
  bless $self,$class;
}

=over 2

=item run()

Runs the communication to the server and returns a hash of the form:

  my $response = $client->run();

The output should be a hashref of this form:

  {
    version => NRPE_VERSION,
    type => RESPONSE_TYPE,
    crc32 => CRC32_CHECKSUM,
    code => RESPONSE_CODE,
    buffer => CHECK_OUTPUT
  }

=back

=cut

sub run {
  my $self = shift;
  my $check;
  if (scalar @{$self->{arglist}} == 0) {
    $check = $self->{check};
  } else {
    $check = join '!',$self->{check},@{$self->{arglist}};
  }

  my $socket;
  if($self->{ssl}) {
    eval {
        # required for new IO::Socket::SSL versions
        require IO::Socket::SSL;
        IO::Socket::SSL->import();
        IO::Socket::SSL::set_ctx_defaults( SSL_verify_mode => 0 );
    };
    $socket = IO::Socket::SSL->new($self->{host}.':'.$self->{port})
                    or die(IO::Socket::SSL::errstr());
  } else {
    $socket = IO::Socket::INET->new(
                    PeerAddr => $self->{host},
                    PeerPort => $self->{port},
                    Proto    => 'tcp',
                    Type     => SOCK_STREAM) or die "ERROR: $@ \n";
  }

  my $packet = Nagios::NRPE::Packet->new();
  my $response;
  print $socket $packet->assemble(type => NRPE_PACKET_QUERY,
				  check => $check,
				  version => NRPE_PACKET_VERSION_2 );

  while (<$socket>) {
    $response .= $_;
  }
  close($socket);

  return $packet->deassemble($response);
}

1;
