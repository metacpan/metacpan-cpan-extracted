#!/usr/bin/perl

package Net::SixXS::TIC::Server;

use v5.010;
use strict;
use warnings;

use version; our $VERSION = version->declare("v0.1.1");

use Digest::MD5 'md5_hex';
use Moose;

use Net::SixXS;
use Net::SixXS::Data::Tunnel;

has username => (
	is => 'rw',
	isa => 'Str',
	required => 1,
);

has password => (
	is => 'rw',
	isa => 'Str',
	required => 1,
);

has tunnels => (
	is => 'rw',
	isa => 'HashRef[Net::SixXS::Data::Tunnel]',
	required => 1,
);

has clients => (
	is => 'rw',
	isa => 'HashRef',
	required => 0,
	default => sub { {} },
);

has server_name => (
	is => 'rw',
	isa => 'Str',
	required => 0,
	default => sub { 'Net-SixXS' },
);

has server_version => (
	is => 'rw',
	isa => 'Str',
	required => 0,
	default => sub { "$Net::SixXS::VERSION" },
);

has diag => (
	is => 'rw',
	does => 'Net::SixXS::Diag',
	required => 0,
	default => sub { Net::SixXS::diag },
);

sub greet_client($ $)
{
	my ($self, $client) = @_;

	$self->client_write_line($client,
	    '200 TIC server '.
	    $self->server_name.'/'.$self->server_version.' ready');
}

sub client_write_line($ $ $)
{
	my ($self, $client, $line) = @_;

	die ref($self)."->client_write_line() must be overridden!\n";
}

sub _cmd_client($ $ $ $)
{
	my ($self, $client, $command, $args) = @_;

	if (defined $client->{client}) {
		return $self->client_write_line($client,
		    '500 Client identity already supplied');
	} elsif (!@{$args}) {
		return $self->client_write_line($client,
		    '500 No client identity supplied');
	}

	$client->{client} = join ' ', @{$args};
	return $self->client_write_line($client,
	    '200 Client identity accepted');
}

sub _cmd_quit($ $ $ $)
{
	my ($self, $client, $command, $args) = @_;

	$client->{shutdown} = 1;
	return $self->client_write_line($client,
	    '200 Thanks for stopping by');
}

sub _cmd_username($ $ $ $)
{
	my ($self, $client, $command, $args) = @_;

	if (@{$args} != 1) {
		return $self->client_write_line($client,
		    '500 Exactly one username must be supplied');
	} elsif (!defined $client->{client}) {
		return $self->client_write_line($client,
		    '500 Client identity not supplied yet');
	} elsif (defined $client->{username}) {
		return $self->client_write_line($client,
		    '500 Username already supplied');
	}

	$client->{username} = shift @{$args};
	return $self->client_write_line($client,
	    '200 Choose your authentication type');
}

sub _cmd_challenge($ $ $ $)
{
	my ($self, $client, $command, $args) = @_;

	if (@{$args} != 1) {
		return $self->client_write_line($client,
		    '500 Exactly one challenge type must be supplied');
	} elsif (!defined $client->{client}) {
		return $self->client_write_line($client,
		    '500 Username not supplied yet');
	} elsif (defined $client->{auth_type}) {
		return $self->client_write_line($client,
		    '500 Challenge type already supplied');
	} elsif ($args->[0] ne 'md5') {
		return $self->client_write_line($client,
		    '500 Only md5 authentication accepted');
	}

	# FIXME: replace this with a cryptographically secure one
	my $proto = join ' ', map int 65536 * rand, 1..16;
	my $challenge = md5_hex($proto);
	$client->{auth_type} = shift @{$args};
	$client->{auth_challenge} = $challenge;
	return $self->client_write_line($client,
	    "200 $challenge");
}

sub _cmd_authenticate($ $ $ $)
{
	my ($self, $client, $command, $args) = @_;

	if (@{$args} != 2) {
		return $self->client_write_line($client,
		    '500 Exactly two arguments must be supplied');
	} elsif (!defined $client->{auth_type}) {
		return $self->client_write_line($client,
		    '500 Challenge type not supplied yet');
	} elsif (defined $client->{auth}) {
		return $self->client_write_line($client,
		    '500 Already authenticated');
	} elsif ($args->[0] ne $client->{auth_type}) {
		return $self->client_write_line($client,
		    '500 Challenge type mismatch');
	}

	my $md5pass = md5_hex($self->password);
	my $interm = "$client->{auth_challenge}$md5pass";
	my $md5resp = md5_hex($interm);
	if ($args->[1] ne $md5resp ||
	    $self->username ne $client->{username}) {
		delete $client->{$_} for
		    qw/auth_type auth_challenge username/;
		return $self->client_write_line($client,
		    '500 Authentication failed');
	}
	$client->{auth} = 1;
	return $self->client_write_line($client,
	    '200 Welcome and stuff');
}

sub _cmd_tunnel_list($ $ $ $)
{
	my ($self, $client, $command, $args) = @_;

	if (@{$args}) {
		return $self->client_write_line($client,
		    '500 No arguments to tunnel list');
	} elsif (!defined $client->{auth}) {
		return $self->client_write_line($client,
		    '500 Who are you?');
	}

	$self->client_write_line($client, '201 Listing tunnels');
	for my $t (values %{$self->tunnels}) {
		$self->client_write_line($client,
		    $t->id.' '.$t->ipv6_local);
	}
	$self->client_write_line($client, '202 <id> <endpoint>');
}

sub _cmd_tunnel_show($ $ $ $)
{
	my ($self, $client, $command, $args) = @_;

	if (@{$args} != 1) {
		return $self->client_write_line($client,
		    '500 Exactly one tunnel ID must be supplied');
	} elsif (!defined $client->{auth}) {
		return $self->client_write_line($client,
		    '500 Who are you?');
	}

	my $tid = shift @{$args};
	my $t = $self->tunnels->{$tid};
	if (!defined $t) {
		$self->client_write_line($client, "500 Invalid tunnel $tid");
	} else {
		$self->client_write_line($client, "201 $tid");
		my $h = $t->to_json;
		$self->client_write_line($client, "$_: $h->{$_}") for
		    sort keys %{$h};
		$self->client_write_line($client, "202 That's it");
	}
}

sub _cmd_get_unixtime($ $ $ $)
{
	my ($self, $client, $command, $args) = @_;

	$self->client_write_line($client, "200 ".time);
}

my %cmds = (
	authenticate => \&_cmd_authenticate,
	challenge => \&_cmd_challenge,
	client => \&_cmd_client,
	get => {
		unixtime => \&_cmd_get_unixtime,
	},
	quit => \&_cmd_quit,
	tunnel => {
		list => \&_cmd_tunnel_list,
		show => \&_cmd_tunnel_show,
	},
	username => \&_cmd_username,
);

sub run_command($ $ $)
{
	my ($self, $client, $command) = @_;

	if (!@{$command}) {
		return $self->client_write_line($client,
		    '500 Invalid empty command');
	}

	my $handlers = \%cmds;
	while (1) {
		my $cmd = shift @{$command};
		my $c = $handlers->{$cmd};

		if (!defined $c) {
			return $self->client_write_line($client,
			    '500 Invalid token: '.$cmd);
		} elsif (ref $c eq 'CODE') {
			return $c->($self, $client, $cmd, $command);
		} elsif (ref $c eq 'HASH') {
			if (!@{$command}) {
				return $self->client_write_line($client,
				    '500 Need a subcommand after '.$cmd);
			}
			$handlers = $c;
		} else {
			return $self->client_write_line($client,
			    '500 Internal server error: unexpected handler '.
			    "for '$cmd': ".ref($c));
		}
	}
}

sub debug($ $)
{
	my ($self, $msg) = @_;

	$self->diag->debug($msg) if $self->diag;
}

no Moose;
1;
__END__

=encoding utf-8

=head1 NAME

C<Net::SixXS::TIC::Server> - the core of a Tunnel Information and Control
protocol server

=head1 SYNOPSIS

See the documentation of the descendant classes -
L<Net::SixXS::TIC::Server::AnyEvent> or L<Net::SixXS::TIC::Server::Inetd>.

=head1 DESCRIPTION

The C<Net::SixXS::TIC::Server> class implements the core operation of
a Tunnel Information and Control (TIC) server as used to configure
IPv6-over-IPv4 tunnels using the Anything-In-Anything (AYIYA) protocol.
It may be part of a local testing setup for TIC/AYIYA clients.

The C<Net::SixXS::TIC::Server> class is not a full implementation of
a TIC server; it keeps the necessary amount of state (including tunnel
information), provides methods for executing the TIC protocol commands,
and requires a C<client_write_line()> method to be overridden by
the descendant classes to actually communicate with the client.
For an implementation, see the L<Net::SixXS::TIC::Server::AnyEvent> and
L<Net::SixXS::TIC::Server::Inetd> classes and the L<sixxs-tic-server>
sample script provided with the C<Net-SixXS> distribution.

=head1 ATTRIBUTES

The operation of a C<Net::SixXS::TIC::Server> object is configured by
the following attributes:

=over 4

=item C<username>

The only username that the server will accept for authentication.

=item C<password>

The password that the server will accept for authentication.

=item C<tunnels>

The tunnels that the server will return information for as a hash
reference with tunnel identifiers (e.g. "T22948") as keys and
L<Net::SixXS::Data::Tunnel> objects as values.

=item C<clients>

An internal structure with information about the state of the clients
currently connected to the server.

=item C<server_name>

The text identifier of the TIC server; defaults to "Net-SixXS".

=item C<server_version>

The text string representing the TIC server's version; defaults to
the version of the C<Net-SixXS> distribution.

=item C<diag>

The L<Net::SixXS::Diag> object to send diagnostic messages to;
defaults to the one provided by the C<diag()> function of the L<Net::SixXS>
class.

Note that the C<Net::SixXS::TIC::Server> object obtains the default
value for C<diag> when it is constructed; thus, a program would usually
set the C<Net::SixXS:diag()> logger early, before creating any actual
objects from the C<Net::SixXS> hierarchy

=back

=head1 METHODS

The C<Net::SixXS::TIC::Server> class defines the following methods:

=over 4

=item B<greet_client (client)>

Send the TIC protocol server greeting to the specified client.

=item B<client_write_line (client, line)>

A stub for the actual method that will send a line to the TIC client;
must be overridden by the descendant classes.

=item B<_cmd_authenticate (client, command, args)>

Internal method invoked by C<run_command()>; process the actual TIC
authentication, making sure that the "authenticate" command is
not sent out of sequence, verify the client's username and password
against the C<username> and C<password> attributes and the session
authentication challenge, and send back a TIC success response.

=item B<_cmd_challenge (client, command, args)>

Internal method invoked by C<run_command()>; process the next step of
the TIC authentication, making sure that the "challenge" command is
not sent out of sequence, generate a pseudo-random challenge string,
and send it back in a TIC success response.

=item B<_cmd_client (client, command, args)>

Internal method invoked by C<run_command()>; process a TIC protocol
client greeting with no actual checks, but create an internal record
of the client information and send back a TIC success response.

=item B<_cmd_get_unixtime (client, command, args)>

Internal method invoked by C<run_command()>; send the current Unix time
(the number of seconds from the epoch) to the client.

=item B<_cmd_quit (client, command, args)>

Internal method invoked by C<run_command()>; process a session end
request from the client, set the C<shutdown> flag in the client
structure, and send back a TIC success response.

=item B<_cmd_tunnel_list (client, command, args)>

Internal method invoked by C<run_command()>; make sure that the client
is authenticated and send back a list of the tunnel identifiers in
a multiline TIC success response.

=item B<_cmd_tunnel_show (client, command, args)>

Internal method invoked by C<run_command()>; make sure that the client
is authenticated and send back detailed information about a single tunnel
in a multiline TIC success response.

=item B<_cmd_username (client, command, args)>

Internal method invoked by C<run_command()>; process the start of
the TIC authentication, making sure that the "username" command is
not sent out of sequence, make a note of the client's specified
username, and send back a TIC success response.

=item B<run_command (client, command)>

Handle a text line received from a TIC client; the actual communication
with the client to receive the commands is handled by the descendant
classes which subsequently invoke this method.  Make sure the command
is in a valid format, then invoke the corresponding method (one of
the C<_cmd_*()> ones listed above) to execute the command and send
a response back to the client.

=item B<debug (message)>

Internal method; sends the message to the object's C<diag> logger if
the latter is set.

=back

=head1 SEE ALSO

L<Net::SixXS::Data::Tunnel>, L<Net::SixXS::Diag>, L<Net::SixXS::TIC::Client>,
L<Net::SixXS::TIC::Server::AnyEvent>, L<Net::SixXS::TIC::Server::Inetd>

=head1 LICENSE

Copyright (C) 2015  Peter Pentchev E<lt>roam@ringlet.netE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Peter Pentchev E<lt>roam@ringlet.netE<gt>

=cut
