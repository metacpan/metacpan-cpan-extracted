#!/usr/bin/perl

package Net::SixXS::TIC::Server::AnyEvent;

use v5.010;
use strict;
use warnings;

use version; our $VERSION = version->declare("v0.1.1");

use AnyEvent::Handle;
use AnyEvent::Socket 'tcp_server';
use Moose;

use Net::SixXS;

extends 'Net::SixXS::TIC::Server';

has host => (
	is => 'rw',
	isa => 'Str',
	required => 0,
	default => sub { '0.0.0.0' },
);

has port => (
	is => 'rw',
	isa => 'Int',
	required => 0,
	default => sub { 3874 },
);

has tic_s_asocket => (
	is => 'rw',
	isa => 'Any',
	required => 0,
);

my $client_id = 0;

sub run($)
{
	my ($self) = @_;

	my $s = tcp_server $self->host, $self->port, sub {
		my ($fh, $host, $port) = @_;

		my $id = $client_id++;
		$self->debug("Accepted TIC client $id from $host:$port");
		my $on_eof = sub {
			$self->debug("EOF client $id from $host:$port");
			delete $self->clients->{$id};
		};
		my $ae = AnyEvent::Handle->new(
			fh => $fh,
			on_eof => $on_eof,
			on_error => $on_eof,
		);
		$self->clients->{$id} = { ae => $ae };
		$self->greet_client($self->clients->{$id});
		$self->push_client_read($id);
	} or die ref($self).": could not listen on ".
	    $self->host.":".$self->port.": $!\n";
	$self->tic_s_asocket($s);
}

sub push_client_read($ $)
{
	my ($self, $id) = @_;

	$self->clients->{$id}->{ae}->push_read(line =>
	    sub { $self->client_read($id, $_[0], $_[1], $_[2]) });
}

sub client_read($ $ $ $ $)
{
	my ($self, $id, $handle, $line, $eol) = @_;

	$self->debug("Read a line from client $id: $line");
	my $c = $self->clients->{$id};
	if (!defined $c) {
		$self->debug("The client has gone away, it seems");
		$handle->push_shutdown;
		return;
	}
	
	if ($c->{shutdown}) {
		$self->debug("Not accepting anything more from this client");
	} else {
		$self->run_command($c, [split /\s+/, $line]);
		$handle->push_shutdown if $c->{shutdown};
	}
	$self->push_client_read($id);
}

sub client_write_line($ $ $)
{
	my ($self, $client, $line) = @_;

	$client->{ae}->push_write("$line\n");
}

no Moose;
1;
__END__

=encoding utf-8

=head1 NAME

C<Net::SixXS::TIC::Server::AnyEvent> - a TIC server using the AnyEvent framework

=head1 SYNOPSIS

  use Net::SixXS::Data::Tunnel;
  use Net::SixXS::Server::AnyEvent;

  my %tunnels = (
      T00001 => Net::SixXS::Data::Tunnel->from_json(\%data1),
      T00002 => Net::SixXS::Data::Tunnel->from_json(\%data2),
  );
  my $s = Net::SixXS::Server::AnyEvent->new(username => 'user',
      password => 'secret', tunnels => \%tunnels);
  $s->run;

=head1 DESCRIPTION

The C<Net::SixXS::TIC::Server::AnyEvent> class implements a TIC server
providing the data about one or more IPv6-over-IPv4 tunnels running
the "Anything-In-Anything" (AYIYA) protocol as used by SixXS.  It provides
the communication with the clients - receiving command lines and sending
back the responses - needed by the L<Net::SixXS::TIC::Server> class, and
depends on the latter for the actual implementation of the TIC negotiation.

=head1 ATTRIBUTES

The C<Net::SixXS::TIC::Server::AnyEvent> class defines the following
attributes in addition to the ones provided by L<Net::SixXS::TIC::Server>:

=over 4

=item C<host>

The name or address on which to listen for incoming TIC connections
(defaults to "0.0.0.0").

=item C<port>

The port on which to listen for incoming TIC connections (defaults to 3874).

=item C<tic_s_asocket>

After the C<run()> method is invoked, this is the L<AnyEvent::Socket> that
the server listens on for incoming TIC connections.

=back

=head1 METHODS

The C<Net::SixXS::TIC::Server::AnyEvent> class defines the following
methods in addition to the ones provided by L<Net::SixXS::TIC::Server>:

=over 4

=item B<run ()>

Create an L<AnyEvent::Socket> listening TCP socket on the specified
address and port and prepare to process any incoming connections using
the TIC protocol, calling the methods provided by L<Net::SixXS::TIC::Server>
to handle the actual commands.

=item B<client_write_line (client, line)>

Implement the C<client_write_line()> method required by
L<Net::SixXS::TIC::Server> by pushing the text line into the write buffer of
the L<AnyEvent::Handle> client connection.

=item B<client_read (id, handle, line, eol)>

Internal method; handle an incoming text line from the TIC client by
passing it on to the C<run_command()> method of L<Net::SixXS::TIC::Server>.

=item B<push_client_read (id)>

Internal method; schedule the C<client_read()> method to be invoked for
incoming text lines on the TIC client's L<AnyEvent::Handle> connection.

=back

=head1 SEE ALSO

L<Net::SixXS>, L<Net::SixXS::Data::Tunnel>,
L<Net::SixXS::TIC::Server>, L<Net::SixXS::TIC::Server::Inetd>

=head1 LICENSE

Copyright (C) 2015  Peter Pentchev E<lt>roam@ringlet.netE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Peter Pentchev E<lt>roam@ringlet.netE<gt>

=cut
