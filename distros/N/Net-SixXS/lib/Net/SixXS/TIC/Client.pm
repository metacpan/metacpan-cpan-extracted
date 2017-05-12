#!/usr/bin/perl

package Net::SixXS::TIC::Client;

use v5.010;
use strict;
use warnings;

use version; our $VERSION = version->declare("v0.1.1");

use Carp 'croak';
use Digest::MD5 'md5_hex';
use IO::Socket::INET;
use Moose;
use POSIX 'uname';

use Net::SixXS;
use Net::SixXS::Data::Tunnel;

has username => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has password => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has server => (
	is => 'rw',
	isa => 'Str',
	required => 0,
	default => 'tic.sixxs.net',
);

has tic_socket => (
	is => 'rw',
	isa => 'IO::Socket::INET',
	required => 0,
);

has client_name => (
	is => 'rw',
	isa => 'Str',
	required => 0,
	default => sub { 'Net-SixXS' },
);

has client_version => (
	is => 'rw',
	isa => 'Str',
	required => 0,
	default => sub { $Net::SixXS::VERSION.'' },
);

has client_osname => (
	is => 'rw',
	isa => 'Str',
	required => 0,
	default => sub { my ($sysname, undef, $release) = uname; "$sysname/$release" },
);

has diag => (
	is => 'rw',
	does => 'Net::SixXS::Diag',
	required => 0,
	default => sub { Net::SixXS::diag },
);

sub tic_resp_parse($ $)
{
	my ($self, $line) = @_;

	$line =~ s/[\r\n]*$//;
	if ($line !~ /^([0-9][0-9][0-9])\s+(.*)$/) {
		croak "Invalid TIC response line received: $line\n";
	}
	my ($code, $msg) = ($1, $2);
	return {
		success => int($code / 100) == 2,
		code => $code,
		msg => $msg,
	};
}

sub tic_command($ $)
{
	my ($self, $command) = @_;
	my $s = $self->tic_socket;

	$self->debug("TIC: sending $command");
	print $s "$command\n";
	my $line = <$s>;
	my $resp = $self->tic_resp_parse($line);
	$self->debug("TIC: got a response with code $resp->{code} success ".($resp->{success}? 'true': 'false')." msg $resp->{msg}");
	if (!$resp->{success}) {
		croak("The TIC server ".$self->server.
		    " refused the '$command' command: ".$resp->{msg}."\n");
	}

	if ($resp->{code} == 201) {
		my @data;
		while ($line = <$s>) {
			$line =~ s/[\r\n]*$//;
			if ($line =~ /^202\s+(.*)/) {
				$resp->{msg} .= " ... $1";
				last;
			}
			push @data, $line;
		}
		if (!defined $line) {
			die "The TIC server did not complete the response to '$command'\n";
		}
		$self->debug("returning ".scalar(@data)." lines of response");
		$resp->{data} = \@data;
	} elsif ($resp->{success} && $resp->{code} != 200) {
		die "FIXME: unexpected 'success' response from the TIC server: $line\n";
	}
	return $resp;
}

sub connect($)
{
	my ($self) = @_;
	my $server = $self->server;

	$self->disconnect if defined $self->tic_socket;
	$self->debug("TIC: connecting to $server:3874");
	my $s = IO::Socket::INET->new(Proto => 'tcp', PeerHost => $server,
	    PeerPort => 3874) or
	    die "Could not connect to $server:3874: $!\n";
	my $line = <$s>;
	my $resp = $self->tic_resp_parse($line);
	if (!$resp->{success}) {
		croak("The $server TIC server greeted us badly: $resp->{msg}\n");
	}
	$self->server($server);
	$self->tic_socket($s);

	eval {
		$self->tic_command('client TIC/draft-00 '.
		    $self->client_name.'/'.$self->client_version.' '.
		    $self->client_osname);
		$self->tic_command('username '.$self->username);
		$resp = $self->tic_command('challenge md5');
		my $challenge = (split /\s+/, $resp->{msg})[-1];
		$self->debug("Got a TIC challenge $challenge");
		my $md5pass = md5_hex($self->password);
		my $interm = "$challenge$md5pass";
		my $md5resp = md5_hex($interm);
		$self->debug("password '".$self->password."' md5 '$md5pass' intermediate '$interm' response '$md5resp'");
		$self->tic_command("authenticate md5 $md5resp");
		$self->debug("Wheee, it worked!");
	};
	if ($@) {
		my $msg = $@;
		$self->disconnect;
		die $msg;
	}
}

sub disconnect($)
{
	my ($self) = @_;
	my $s = $self->tic_socket;
	
	return unless defined $s;
	close $s or die "Could not close the TIC socket: $!\n";
	$self->{tic_socket} = undef;
}

sub tunnels($)
{
	my ($self) = @_;
	
	my $resp = $self->tic_command('tunnel list');
	my %tunnels;
	for (@{$resp->{data}}) {
		if (!/^(T\w+)\s+(.*)/) {
			die "Invalid 'tunnel list' response from ".
			    "the TIC server: $_\n";
		}
		$tunnels{$1} = $2;
	}
	return \%tunnels;
}

sub tunnel_info($ $)
{
	my ($self, $tunnel) = @_;

	my $resp = $self->tic_command("tunnel show $tunnel");
	my %data;
	for (@{$resp->{data}}) {
		if (!/^(\w[^:]+)\s*:\s*(.*)$/) {
			die "Invalid 'tunnel show' response from ".
			    "the TIC server: $_\n";
		}
		my ($k, $v) = ($1, $2);
		if (exists $data{$k}) {
			die "Duplicate key '$k' in the TIC server's ".
			    "'tunnel show' response: $_\n";
		}
		$data{$k} = $v;
	}
	return Net::SixXS::Data::Tunnel->from_json(\%data);
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

Net::SixXS::TIC::Client - Tunnel Information and Control protocol client

=head1 SYNOPSIS

    use Net::SixXS::TIC::Client;

    my $tic = Net::SixXS::TIC::Client->new(username = 'me', password = 'none');
    $tic->connect;
    say for sort map $_->name, values %{$tic->tunnels};

=head1 DESCRIPTION

The C<Net::SixXS::TIC::Client> class provides an interface to
the Tunnel Information and Control protocol used by SixXS to configure
IPv6-over-IPv4 tunnels using the AYIYA (Anything-In-Anything) protocol.
A C<Net:SixXS::TIC::Client> object takes care of connecting to
the TIC server, authenticating using a challenge/response scheme, then
retrieving information about the tunnels managed by the authenticated
user account.

=head1 ATTRIBUTES

The operation of the C<Net::SixXS::TIC::Client> object is controlled by
the following attributes:

=over 4

=item C<username>

The username of the account to authenticate with.

=item C<password>

The password of the account to authenticate with.

=item C<server>

The hostname or address of the TIC server to connect to; defaults to
"tic.sixxs.net".

=item C<tic_socket>

After the C<connect()> method has been successfully invoked, this is
the L<IO::Socket::INET> object representing the connection to
the TIC server.

=item C<client_name>

The text identifier of the TIC client; defaults to "Net-SixXS".

=item C<client_version>

The text string representing the TIC client's version; defaults to
the version of the C<Net-SixXS> distribution.

=item C<client_osname>

The name of the operating system that the TIC client is running on;
defaults to the system name and the release name separated by a slash,
e.g. "FreeBSD/11.0-CURRENT".

=item C<diag>

The L<Net::SixXS::Diag> object to send diagnostic messages to;
defaults to the one provided by the C<diag()> function of the L<Net::SixXS>
class.

Note that the C<Net::SixXS::TIC::Client> object obtains the default
value for C<diag> when it is constructed; thus, a program would usually
set the C<Net::SixXS:diag()> logger early, before creating any actual
objects from the C<Net::SixXS> hierarchy.

=back

=head1 METHODS

The C<Net::SixXS::TIC::Client> class defines the following methods:

=over 4

=item B<connect ()>

Connects to the TIC server specified by the C<server> attribute,
issues a "client" command identifying the client using the values of
the C<client_name>, C<client_version>, and C<client_osname> attributes,
then authenticates using an MD5 challenge/response with the C<username>
and C<password> attributes.  Dies if the connection cannot be established
or the authentication fails.  On success, sets C<tic_socket> to the new
connection.

=item B<disconnect ()>

If C<tic_socket> is set, breaks a previously established connection.

=item B<tunnels ()>

Obtains a list of the short identifiers (e.g. "T22928") of the tunnels
managed by the authenticated user account.  Returns a reference to a hash
with the tunnel identifiers as keys and a brief text representation of
the tunnel information as values; detailed information is obtained by
invoking the C<tunnel_info()> method.

=item B<tunnel_info (tunnelid)>

Obtains detailed information about the tunnel with the specified identifier
and returns a L<Net::SixXS::Data::Tunnel> object.

=item B<tic_resp_parse (line)>

Internal method; parse a text line received by the TIC server into
a status code, a success flag, and a text message.

=item B<tic_command (command)>

Internal method; issues a command over the connection to the TIC
server, reads a possibly multiline response, and dies if the TIC
server does not return a success response.

=item B<debug (message)>

Internal method; sends the message to the object's C<diag> logger if
the latter is set.

=back

=head1 SEE ALSO

L<Net::SixXS::Data::Tunnel>, L<Net::SixXS::Diag>,
L<Net::SixXS::TIC::Server>

=head1 LICENSE

Copyright (C) 2015  Peter Pentchev E<lt>roam@ringlet.netE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Peter Pentchev E<lt>roam@ringlet.netE<gt>

=cut

