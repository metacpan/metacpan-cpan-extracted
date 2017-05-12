package Net::FreeDB2::Connection::CDDBP;

# Copyright 2002, Vincenzo Zocca.

# See LICENSE section for usage and distribution rights.

require 5.005_62;
use strict;
use warnings;
use Error qw (:try);

require Exporter;
use AutoLoader qw(AUTOLOAD);

#our @ISA = qw(Net::FreeDB2::Connection Exporter);
use base qw(Net::FreeDB2::Connection Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::FreeDB2::Connection::CDDBP ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our ( $VERSION ) = '$Revision: 0.8.2.4 $ ' =~ /\$Revision:\s+([^\s]+)/;

my $FINAL_EOL_RX = '[\r\n]';
my $FINAL_DOT_RX = '[\r\n]\.[\r\n]';

sub new {
	# Call constructor of super class
	my $self = &Net::FreeDB2::Connection::new (@_);

	# Shift out this class specification
	shift;

	# Return object
	return ($self);
}

sub _initialize {
	my $self = shift;

	# Get options
	my $opt = shift || {};

	# Proxy on CDDBP not yet defined
	defined ($opt->{proxy_host}) &&
		throw Error::Simple ("ERROR: Net::FreeDB2::Connection::CDDBP::_initialize, CDDBP access through proxy not (yet) implemented.");

	# Initialize super class
	return ($self->SUPER::_initialize ($opt));
}

sub connect {
	my $self = shift;

	# Make socket connection
	use IO::Socket::INET;
	my $connection = IO::Socket::INET->new (
		PeerAddr => $self->getFreeDBHost (),
		PeerPort => $self->getFreeDBPort () || 8880,
	);
	defined ($connection) || throw Error::Simple ('ERROR: Net::FreeDB2::Connection::CDDBP::connect, Failed to instanciate an \'IO::Socket::INET\' object.');

	# Set the connection
	$self->setConnection ($connection);

	# Send command and wait for reply
	my $content_ref = $self->waitCommandReply (undef, {
		200 => $FINAL_EOL_RX,
		201 => $FINAL_EOL_RX,
		432 => $FINAL_EOL_RX,
		433 => $FINAL_EOL_RX,
		434 => $FINAL_EOL_RX,
	});

	# Parse the result and store it
	use Net::FreeDB2::Response::SignOn;
	$self->setSignOnResponse (Net::FreeDB2::Response::SignOn->new ({
		content_ref => $content_ref
	}));

	# Send a hello
	my $res = $self->hello ();

	# Disconnect and throw exception if error
	if ($res->hasError ()) {
		$self->setConnection ();
		throw Error::Simple ('ERROR: Net::FreeDB2::Connection::CDDBP::connect, handshake failed.');
	}
}

sub lscat {
	my $self = shift;

	# Send command and wait for reply
	my $content_ref = $self->waitCommandReply ('cddb lscat', {
		210 => $FINAL_DOT_RX,
	});

	# Parse the result
	my @content = split (/[\n\r]+/, ${$content_ref});
	shift (@content);
	my @cat = ();
	foreach my $cat (@content) {
		last if ($cat eq '.');
		push (@cat, $cat);
	}
	return (@cat);
}

sub query {
	my $self = shift;
	my $entity = shift;

	# Send command and wait for reply
	my $cmd = 'cddb query ' . $entity->mkQuery ();
	my $content_ref = $self->waitCommandReply ($cmd, {
		200 => $FINAL_EOL_RX,
		211 => $FINAL_DOT_RX,
		202 => $FINAL_EOL_RX,
		403 => $FINAL_EOL_RX,
		409 => $FINAL_EOL_RX,
	});

	# Parse the result
	use Net::FreeDB2::Response::Query;
	return Net::FreeDB2::Response::Query->new ({
		content_ref => $content_ref,
	});
}

sub read {
	my $self = shift;
	my $match = shift;

	# Send command and wait for reply
	my $cmd = 'cddb read ' . $match->getCateg () . ' '  . $match->getDiscid ();
	my $content_ref = $self->waitCommandReply ($cmd, {
		210 => $FINAL_DOT_RX,
		401 => $FINAL_EOL_RX,
		402 => $FINAL_EOL_RX,
		403 => $FINAL_EOL_RX,
		409 => $FINAL_EOL_RX,
	});

	# Parse the result
	use Net::FreeDB2::Response::Read;
	return Net::FreeDB2::Response::Read->new ({
		content_ref => $content_ref,
	});
}

sub write {
	throw Error::Simple ("ERROR: Net::FreeDB2::Connection::CDDBP::write, to be implemented.");
}

sub log {
	throw Error::Simple ("ERROR: Net::FreeDB2::CDDBP::log, to be implemented.");
}

sub motd {
	my $self = shift;

	# Send command and wait for reply
	my $content_ref = $self->waitCommandReply ('motd', {
		210 => $FINAL_DOT_RX,
		401 => $FINAL_EOL_RX,
	});

	# Parse the result
	my @content = split (/[\n\r]+/, ${$content_ref});
	my $head = shift (@content);
	my @motd = ();
	foreach my $motd (@content) {
		last if ($motd eq '.');
		push (@motd, $motd);
	}
	return (@motd);
}

sub discid {
	my $self = shift;
	my $entity = shift;

	# Send command and wait for reply
	my $cmd = 'discid ' . $entity->mkQuery ();
	my $content_ref = $self->waitCommandReply ($cmd, {
		200 => $FINAL_EOL_RX,
		500 => $FINAL_EOL_RX,
	});

	# Parse the result
	my @content = split (/[\n\r]+/, ${$content_ref});
	my $head = shift (@content);
	my ($code) = $head =~ /^\s*(\d{3})\s+/;
	$code == 500 && throw Error::Simple ("ERROR: Net::FreeDB2::Connection::CDDBP::discid, Command Syntax error.");
	my @head = split (/\s+/, $head);
	return ($head[4]);
}

sub proto {
	throw Error::Simple ("ERROR: Net::FreeDB2::CDDBP::proto, to be implemented.");
}

sub sites {
	my $self = shift;

	# Send command and wait for reply
	my $content_ref = $self->waitCommandReply ('sites', {
		210 => $FINAL_DOT_RX,
		401 => $FINAL_EOL_RX,
	});

	# Parse the result
	use Net::FreeDB2::Response::Sites;
	return Net::FreeDB2::Response::Sites->new ({
		content_ref => $content_ref,
	});
}

sub stat {
	throw Error::Simple ("ERROR: Net::FreeDB2::CDDBP::stat, to be implemented.");
}

sub ver {
	throw Error::Simple ("ERROR: Net::FreeDB2::CDDBP::ver, to be implemented.");
}

sub update {
	throw Error::Simple ("ERROR: Net::FreeDB2::CDDBP::update, to be implemented.");
}

sub whom {
	throw Error::Simple ("ERROR: Net::FreeDB2::CDDBP::whom, to be implemented.");
}

sub setSignOnResponse {
	my $self = shift;

	# Set FreeDB/CDDB sign-on response
	$self->{Net_FreeDB2_Connection_CDDBP}{sign_on_response} = shift;
}

sub getSignOnResponse {
	my $self = shift;

	# Return FreeDB/CDDB sign-on response
	return ($self->{Net_FreeDB2_Connection_CDDBP}{sign_on_response});
}

sub hello {
	my $self = shift;

	# Send command and wait for reply
	my $cmd = 'cddb ' . $self->mkHello ();
	my $content_ref = $self->waitCommandReply ($cmd, {
		200 => $FINAL_EOL_RX,
		431 => $FINAL_EOL_RX,
		402 => $FINAL_EOL_RX,
	});

	# Parse the result and return it
	use Net::FreeDB2::Response::Hello;
	return (Net::FreeDB2::Response::Hello->new ({
		content_ref => $content_ref
	}));
}

sub quit {
	my $self = shift;

	# Send command and wait for reply
	my $content_ref = $self->waitCommandReply ('quit', {
		230 => $FINAL_EOL_RX,
	});

	# Disconnect
	$self->setConnection ();
}

sub waitCommandReply {
	my $self = shift;
	my $cmd = shift;
	my $rx = shift;

	# Check if connection is defined
	defined ($self->getConnection ()) || throw Error::Simple ('ERROR: Net::FreeDB2::Connection::CDDBP::waitCommandReply, no connection available.');

	# Set blocking
	$self->getConnection->blocking (1);

	# Send command
	defined ($cmd) && $self->getConnection ()->write ($cmd . "\r\n");

	# Wait for code
	$self->getConnection->read (my $head, 5);
	$head =~ s/^\s+//;
	my ($code) = $head =~ /(\d{3})/;
	exists ($rx->{$code}) || throw Error::Simple ("ERROR: Net::FreeDB2::Connection::CDDBP::waitCommandReply, unknown code '$code' returned.");

	# Wait for the final DOT or EOL
	my $content .= $head;
	$self->getConnection->blocking (0);
	while (1) {
		$self->getConnection->read (my $rest, 1024);
		$content .= $rest;
		$content =~ /$rx->{$code}/ && last;
		sleep (1);
	}

	# Return the content reference
	return (\$content);
}

sub mkHello {
	my $self = shift;

	defined ($self->getClientName ()) || throw Error::Simple ('ERROR: Net::FreeDB2::Connection::CDDBP::mkHello, \'client_name\' not set.');
	defined ($self->getClientVersion ()) || throw Error::Simple ('ERROR: Net::FreeDB2::Connection::CDDBP::mkHello, \'client_version\' not set.');
	defined ($self->getClientHost ()) || throw Error::Simple ('ERROR: Net::FreeDB2::Connection::CDDBP::mkHello, \'client_host\' not set.');
	defined ($self->getClientUser ()) || throw Error::Simple ('ERROR: Net::FreeDB2::Connection::CDDBP::mkHello, \'client_user\' not set.');

	return ('hello ' . join (' ',
		$self->getClientUser (),
		$self->getClientHost (),
		$self->getClientName (),
		$self->getClientVersion (),
		)
	);
}

1;
__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Net::FreeDB2::Connection::CDDBP - FreeDB/CDDB concrete connection class using the CDDBP protocol

=head1 SYNOPSIS
 
See L<Net::FreeDB2>.

=head1 DESCRIPTION

C<Net::FreeDB2::Connection::CDDBP> is an implementation of the abstract C<FreeDB/CDDB> connection class. It uses the CDDBP protocol to connect to C<FreeDB/CDDB> servers.

=head1 CONSTRUCTOR

=over

=item new (OPT_HASH_REF)

Implementation of C<Net::FreeDB2::Connection::new>.

Restriction: proxy_host may not be specified as CDDBP access through proxy is not (yet) implemented.

Throws a C<Error::Simple> exception if a mandatory option is missing and passes exceptions from C<connect ()>.

=back

=head1 METHODS

=over 

=item connect ()

Implementation of C<Net::FreeDB2::Connection::connect>. Stores a signo on response using C<setSignOnResponse ()>.

=item lscat ()

Implementation of C<Net::FreeDB2::Connection::lscat>.

=item query (ENTRY)

Implementation of C<Net::FreeDB2::Connection::query>.

=item read (MATCH)

Implementation of C<Net::FreeDB2::Connection::read>.

=item write (ENTITY)

Implementation of C<Net::FreeDB2::Connection::write>.

=item log ()

Implementation of C<Net::FreeDB2::Connection::log>.

=item motd ()

Implementation of C<Net::FreeDB2::Connection::motd>.

=item discid (ENTRY)

Implementation of C<Net::FreeDB2::Connection::discid>.

=item proto ()

Implementation of C<Net::FreeDB2::Connection::proto>.

=item sites ()

Implementation of C<Net::FreeDB2::Connection::sites>.

=item stat ()

Implementation of C<Net::FreeDB2::Connection::stat>.

=item ver ()

Implementation of C<Net::FreeDB2::Connection::ver>.

=item update ()

Implementation of C<Net::FreeDB2::Connection::update>.

=item whom ()

Implementation of C<Net::FreeDB2::Connection::whom>.

=item setSignOnResponse (VALUE)

Set the FreeDB/CDDB sign-on response. C<VALUE> is the value.

=item getSignOnResponse ()

Returns the FreeDB/CDDB sign-on response.

=item setProxyHost (VALUE)

Implementation of C<Net::FreeDB2::Connection::setProxyHost>. Throws an exception because proxy_host may not be specified as CDDBP access through proxy is not (yet) implemented.

=item hello ()

B<PRIVATE METHOD>. Sends the C<hello> to C<FreeDB/CDDB> server.

=item quit ()

B<PRIVATE METHOD>. Sends the C<quit> to C<FreeDB/CDDB> server.

=item waitCommandReply (CMD, CODE_RX)

B<PRIVATE METHOD>. Executes command in C<CMD> and waits for a reply. C<CODE_RX> specifies 1) the allowed FreeDB/CDDB codes and 2) the regular expression that determins the termination of the returned output.

=item mkHello ()

B<PRIVATE METHOD>. Makes the a FreeDB/CDDB CDDBP hello string.

=back

=head1 EXCEPTIONS

FreeDB/CDDB command methods C<lscat ()>, C<query ()>, C<read ()>, C<write ()>, C<log ()>, C<motd ()>, C<discid ()>, C<proto ()>, C<sites ()>, C<stat ()>, C<ver ()>, C<update ()> and C<whom ()> throw an C<Error::Simple> exception in cases of connection errors and unexpected situations in the data format.

=head1 SEE ALSO

L<Net::FreeDB2::Entry>, L<Net::FreeDB2::Match>, L<Net::FreeDB2::Response>, L<Net::FreeDB2::Response::Query> and L<Net::FreeDB2::Response::Read>

=head1 BUGS

Not all FreeDB/CDDB commands are implemented (yet).

=head1 HISTORY

First development: September 2002

=head1 AUTHOR

Vincenzo Zocca E<lt>Vincenzo@Zocca.comE<gt>

=head1 COPYRIGHT

Copyright 2002, Vincenzo Zocca.

=head1 LICENSE

This file is part of the C<Net::FreeDB2> module hierarchy for Perl by
Vincenzo Zocca.

The Net::FreeDB2 module hierarchy is free software; you can redistribute it
and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2 of
the License, or (at your option) any later version.

The Net::FreeDB2 module hierarchy is distributed in the hope that it will
be useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the Net::FreeDB2 module hierarchy; if not, write to
the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111-1307 USA

=cut

