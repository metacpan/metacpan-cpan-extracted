# Copyright (c) 2010 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# 
# $Id: Proxy.pm,v 1.13 2007/12/03 11:44:19 gavin Exp $
package Net::EPP::Proxy;
use Carp;
use Digest::SHA1 qw(sha1_hex);
use Net::EPP::Simple;
use Net::EPP::Protocol;
use POSIX qw(strftime);
use Time::HiRes qw(time);
use XML::LibXML;
use bytes;
use base qw(Net::Server::Multiplex);
use constant EPP_XMLNS	=> 'urn:ietf:params:xml:ns:epp-1.0';
use vars qw($VERSION);
use strict;

our $VERSION = '0.04';

sub new {
	my $package = shift;
	my $self = $package->SUPER::new;
	$self->{epp} = {parser => XML::LibXML->new};
	bless($self, $package);
	return $self;
}

sub init {
	my ($self, %params) = @_;

	$self->{epp}->{host}		= $params{remote_host};
	$self->{epp}->{port}		= $params{remote_port};
	$self->{epp}->{ssl}		= $params{ssl};
	$self->{epp}->{timeout}		= (int($params{req_timeout}) > 0 ? int($params{req_timeout}) : 5);
	$self->{epp}->{clid}		= $params{clid};
	$self->{epp}->{pw}		= $params{pw};
	$self->{epp}->{svcs}		= $params{svcs};
	$self->{epp}->{debug}		= $params{debug};

	# connect to the server:
	my ($code, $msg) = $self->epp_connect;

	# check the response:
	if ($code != 1000) {
		carp('Unable to log into to server using supplied credentials: '.$msg);
		return undef;
	}

	# run the main server loop:
	return $self->run(%params);
}

sub epp_connect {
	my $self = shift;

	# build our EPP client:
	$self->{epp}->{client} = Net::EPP::Simple->new(
		host	=> $self->{epp}->{host},
		port	=> $self->{epp}->{port},
		user	=> $self->{epp}->{user},
		pass	=> $self->{epp}->{pass},
		ssl	=> $self->{epp}->{ssl},
		timeout	=> $self->{epp}->{timeout},
		debug	=> $self->{epp}->{debug},
		dom	=> 1,
	);

	if (!$self->{epp}->{client}) {
		carp("Error connecting: $Net::EPP::Simple::Error");
		return ($Net::EPP::Simple::Code, "Error connecting: $Net::EPP::Simple::Error");
	}

	$self->{epp}->{greeting} = $self->{epp}->{client}->{greeting};

	return ($Net::EPP::Simple::Code, $Net::EPP::Simple::Message);
}

# new connection, send the greeting:
sub mux_connection {
	my ($self, $mux, $peer) = @_;
	print Net::EPP::Protocol->prep_frame($self->{net_server}->{epp}->{greeting}->toString);
}

# a request frame was received, transmit to remote server and return response to client:
sub mux_input {
	my ($self, $mux, $peer, $input) = @_;

	my $hdr		= substr(${$input}, 0, 4);
	my $length	= unpack('N', $hdr) - 4;
	my $question	= substr(${$input}, 4, $length);

	my $oldsig = $SIG{PIPE};
	$SIG{PIPE} = 'IGNORE';
	my $answer;
	eval {
		local $SIG{ALRM} = sub { die("timed out") };
		alarm($self->{net_server}->{epp}->{timeout});
		$answer = $self->{net_server}->{epp}->{client}->request($question);
		alarm(0);
	};
	$SIG{PIPE} = $oldsig;

	# initialise some things:
	my $err = '';
	my $fatal = 0;

	if ($@ ne '') {
		$err = sprintf('error getting answer from remote server: %s timeout %ds)', $@, $self->{net_server}->{epp}->{timeout});

	} elsif (length($answer->toString) < 1) {
		$err = sprintf('error getting answer from remote server: answer was %d bytes long', length($answer));

	} elsif ($self->get_result_code($answer) =~ /^(2500|2501|2502)$/) {
		$err = sprintf('session error at remote server (code %d)', $self->get_result_code($answer));

	}

	if ($err ne '') {
		$answer = $self->create_error_frame($question, $err);
		$self->debug("Fatal error from remote server: $err");
		$fatal = 1;
	}

	# send answer to client:
	print Net::EPP::Protocol->prep_frame($answer->toString);

	# clean up:
	$self->server_close if ($err ne '' && $fatal == 1);

	# clear the buffer:
	${$input} = '';

	return 1;
}

sub create_error_frame {
	my ($self, $question, $err) = @_;
	my $frame = Net::EPP::Frame::Response->new;

	my $clTRID;
	eval {
		my $doc = $self->{epp}->{parser}->parse_string($question);
		my $nodes = $doc->getElementsByTagNameNS(EPP_XMLNS, 'clTRID');
		my $node = $nodes->shift;
		my $text = ($node->getChildNodes)[0];
		$clTRID = $text->data;
		print STDERR $question;
	};

	my $msg = $frame->createElement('msg');
	$msg->appendText($err);

	$frame->clTRID->appendText($clTRID);
	$frame->svTRID->appendText(sha1_hex(ref($self).time().$$));

	$frame->result->setAttribute('code', 2500);
	$frame->result->appendChild($msg);

	return $frame;
}

sub get_result_code {
	my ($self, $doc) = @_;
	my $els = $doc->getElementsByTagNameNS(EPP_XMLNS, 'result');
	if (defined($els)) {
		my $el = $els->shift;
		if (defined($el)) {
			return $el->getAttribute('code');
		}
	}
	return 2400;
}

sub get_result_message {
	my ($self, $doc) = @_;
	my $els = $doc->getElementsByTagNameNS(EPP_XMLNS, 'msg');
	if (defined($els)) {
		my $el = $els->shift;
		if (defined($el)) {
			my @children = $el->getChildNodes;
			if (defined($children[0])) {
				my $txt = $children[0];
				return $txt->data if (ref($txt) eq 'XML::LibXML::Text');
			}
		}
	}
	return 'Unknown message';
}

1;

__END__
=pod

=head1 NAME

Net::EPP::Proxy - a proxy server for the EPP protocol.

=head1 SYNOPSIS

Construct your server process like so:

	#!/usr/bin/perl
	use Net::EPP::Proxy;
	use Net::EPP::Frame::ObjectSpec;
	use strict;

	my $proxy = Net::EPP::Proxy->new;

	$proxy->init(
		# EPP-specific params:
		remote_host	=> 'epp.nic.tld',
		remote_port	=> 700,
		ssl		=> 1,
		clid		=> $CLID,
		pw		=> $PW,

		# Net::Server params:
		host		=> 'localhost',
		port		=> 7000,
		log_level	=> 0,
		max_servers	=> 10,
		min_servers	=> 5,
	);

Then, in your client processes:

	my $client = Net::EPP::Client->new(
		host	=> 'localhost',
		port	=> 7000,
		ssl	=> undef,
	);

	print $client->connect;

=head1 DESCRIPTION

EPP is the Extensible Provisioning Protocol. EPP (defined in RFC 4930) is an
application layer client-server protocol for the provisioning and management of
objects stored in a shared central repository. Specified in XML, the protocol
defines generic object management operations and an extensible framework that
maps protocol operations to objects. As of writing, its only well-developed
application is the provisioning of Internet domain names, hosts, and related
contact details.

RFC 4934 defines a TCP based transport model for EPP, and this module
implements a proxy server for this model. You can use it to construct a daemon
that maintains a single connection to the EPP server that can be used by many
local clients, thereby reducing the overhead for each transaction.

Net::EPP::Proxy is based on the L<Net::Server> framework and
L<Net::EPP::Client>, which it uses to communicate with the server.

When a Net::EPP::Proxy server is started, it creates a connection to a single
remote EPP server using the supplied credentials. Each proxy can connect to a
single remote server - if you want to proxy for multiple servers you should
create a proxy server for each, perhaps listening on a different TCP port.

	+---+				+---+
	| C |<-----------//------------>|   |	In this model, each client must
	+---+				|   |   establish a session with the
					| S |   server, increasing the time and
	+---+				| E |	bandwidth overheard associated
	| C |<-----------//------------>| R |   with sending transactions to
	+---+				| V |   the server, especially if the
					| E |   client is a CGI or PHP script
	+---+				| R |	that must create a new
	| C |<-----------//------------>|   |	connection each time.
	+---+				+---+

	Figure 1 - multiple clients connecting to a remote server


	+---+		+---+		+---+
	| C |<--------->|   |		|   |	In this model, the proxy server
	+---+		|   |		|   |	maintains a single connection
			| P |		| S |	to the server on behalf of a
	+---+		| R |		| E |	number of clients, reducing
	| C |<--------->| O |<----//--->| R |	the time and bandwidth overhead
	+---+		| X |		| V |	associated with sending
			| Y |		| E |	transactions to the server.
	+---+		|   |		| R |
	| C |<--------->|   |		|   |
	+---+		+---+		+---+

	Figure 2 - multiple clients connecting to a proxy

When a local client connects to the proxy, it is immediately sent the EPP
C<E<lt>greetingE<gt>> frame the proxy server received from the remote server.
The client can then send EPP frames to the proxy, which passes these frames
on to the server within the context of its own connection, and returns the
remote servers' response to the client. A single connection to the remote
server can thereby be shared among a large number of local clients without
the need to connect and authenticate each client.

The proxy "speaks" the same protocol as an EPP server (XML payloads prefixed
by 4 bytes containing the payload's length, sent over TCP), so any client
capable of using the EPP protocol can use the proxy I<(eg, the
L<Net::EPP::Client> module, the Net_EPP_Client PHP class, etc)>.

=head1 USAGE

To start an EPP proxy server instance, use the following syntax:

	my $proxy = Net::EPP::Proxy->new;

	$proxy->init(%PARAMS);

The C<%PARAMS> hash contain any of the configuration variables allowed by
L<Net::Server>, plus the following:

=over

=item C<remote_host>

The hostname of the remote EPP server to connect to.

=item C<remote_port>

The TCP port number of the remote EPP server to connect to (usually 700).

=item C<ssL>

Whether to use SSL to connect to the remote server (usually true).

=item C<clid>

The client ID to use to authenticate.

=item C<pw>

The password to use to authenticate.

=item C<req_timeout>

The amount of time in seconds to wait for a response from the remote server.
If there is a network outage or some other undefined error, the server will
send an error frame to the local client and then shut down, so you may
want to have your invocation script try to re-establish the connection.

=head2 Object Services

Versions of I<Net::EPP::Proxy> prior to 0.03 required that you manually
specify any service URIs required. As of Version 0.03, the services are
automatically populated from the C<E<lt>svcMenuE<gt>> element in the
C<E<lt>greetingE<gt>> received from the remote server.

=back

If the proxy is unable to authenticate with the remote EPP server then
the I<init()> method will I<carp()> and then return undef.

=head1 LOGGING, CONFIGURATION AND PERFORMANCE TUNING

See the documentation for L<Net::Server> for information about configuring the
server to do logging, and tweaking performance values.

Note that there is a fundamental limitation on performance due to the proxy
server blocking while waiting for the remote server to respond. If you find
that this becomes problematic, consider running multiple proxy server instances
and distributing client connections between them.

=head1 AUTHOR

CentralNic Ltd (L<http://www.centralnic.com/>).

=head1 COPYRIGHT

This module is (c) 2010 CentralNic Ltd. This module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item * L<Net::EPP::Client>

=item * L<Net::EPP::Frame>

=item * L<Net::EPP::Proxy>

=item * L<Net::Server>

=item * L<IO::Multiplex>

=item * RFCs 4930 and RFC 4934, available from L<http://www.ietf.org/>.

=item * The CentralNic EPP site at L<http://www.centralnic.com/resellers/epp>.

=back

=cut
