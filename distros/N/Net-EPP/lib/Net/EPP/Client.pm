package Net::EPP::Client;
use bytes;
use Net::EPP::Protocol;
use Net::EPP::Parser;
use Carp;
use IO::Socket;
use IO::Socket::SSL;
use vars qw($XMLDOM $EPPFRAME);
use strict;
use warnings;

=pod

=head1 NAME

Net::EPP::Client - a client library for the TCP transport for EPP, the
Extensible Provisioning Protocol.

=head1 SYNOPSIS

	#!/usr/bin/perl
	use Net::EPP::Client;
	use strict;

	my $epp = Net::EPP::Client->new(
		host	=> 'epp.nic.tld',
		port	=> 700,
		ssl	=> 1,
		frames	=> 1,
	);

	my $greeting = $epp->connect;

	$epp->send_frame('login.xml');

	my $answer = $epp->get_frame;

	$epp->send_frame('<epp><logout /></epp>');

	my $answer = $epp->get_frame;

=head1 DESCRIPTION

L<RFC 5743|https://www.rfc-editor.org/rfc/rfc5734.html> defines a TCP based
transport model for EPP, and this module implements a client for that model.
You can establish and manage EPP connections and send and receive responses 
ver this connection.

C<Net::EPP::Client> also provides some time-saving features, such as being
able to provide request and response frames as C<Net::EPP::Frame> objects.

=cut

BEGIN {
	our $XMLDOM   = 0;
	our $EPPFRAME = 0;
	eval {
		require XML::LibXML;
		$XMLDOM = 1;
	};
	eval {
		require Net::EPP::Frame;
		$EPPFRAME = 1;
	};
}

=pod

=head1 CONSTRUCTOR

	my $epp = Net::EPP::Client->new(PARAMS);

The constructor method creates a new EPP client object. It accepts a number of
parameters:

=over

=item * host

C<host> specifies the computer to connect to. This may be a DNS hostname or
an IP address.

=item * port

C<port> specifies the TCP port to connect to. This is usually 700.

=item * ssl

If the C<ssl> parameter is defined, then L<IO::Socket::SSL> will be used to
provide an encrypted connection. If not, then a plaintext connection will be
created.

=item * dom (deprecated)

If the C<dom> parameter is defined, then all response frames will be returned
as L<XML::LibXML::Document> objects.

=item * frames

If the C<frames> parameter is defined, then all response frames will be
returned as L<Net::EPP::Frame> objects (actually, L<XML::LibXML::Document>
objects reblessed as L<Net::EPP::Frame> objects).

=back

=cut

sub new {
	my ($package, %params) = @_;

	my $self;
	if (defined($params{'sock'})) {
		$self = {
			'sock'		=> $params{'sock'},
			ssl		=> 0,
			'dom'		=> (defined($params{'dom'}) ? 1 : 0),
			'frames'	=> (defined($params{'frames'}) ? 1 : 0),
		}
	} else {
		croak("missing hostname")	if (!defined($params{'host'}));
		croak("missing port")		if (!defined($params{'port'}));

		$self = {
			'host'		=> $params{'host'},
			'port'		=> $params{'port'},
			'ssl'		=> (defined($params{'ssl'}) ? 1 : 0),
			'dom'		=> (defined($params{'dom'}) ? 1 : 0),
			'frames'	=> (defined($params{'frames'}) ? 1 : 0),
		};
	}

	if ($self->{'frames'} == 1) {
		if ($EPPFRAME == 0) {
			croak("Frames requested but Net::EPP::Frame isn't available");

		} else {
			$self->{'class'} = 'Net::EPP::Frame';

		}

	} elsif ($self->{'dom'} == 1) {
		if ($XMLDOM == 0) {
			croak("DOM requested but XML::LibXML isn't available");

		} else {
			$self->{'class'} = 'XML::LibXML::Document';

		}

	}

	return bless($self, $package);
}

=pod

=head1 METHODS

=head2 Connecting to a server:

	my $greeting = $epp->connect(%PARAMS);

This method establishes the TCP connection. You can use the C<%PARAMS> hash to
specify arguments that will be passed on to the constructors for
L<IO::Socket::INET> (such as a timeout) or L<IO::Socket::SSL> (such as
certificate information). See the relevant manpage for examples.

This method will C<croak()> if connection fails, so be sure to use C<eval()> if
you want to catch the error.

By default, the return value for C<connect()> will be the EPP E<lt>greetingE<gt>
frame returned by the server. Please note that the same caveat about blocking
applies to this method as to C<get_frame()> (see below).

If you want to get the greeting yourself, set C<$params{no_greeting}>.

=cut

sub connect {
	my ($self, %params) = @_;

	if (defined($self->{'sock'})) {
		$self->_connect_unix(%params);

	} else {
		$self->_connect_tcp(%params);

	}

	return ($params{'no_greeting'} ? 1 : $self->get_frame);

}

sub _connect_tcp {
	my ($self, %params) = @_;

	my $SocketClass = ($self->{'ssl'} == 1 ? 'IO::Socket::SSL' : 'IO::Socket::INET');

	$self->{'connection'} = $SocketClass->new(
		PeerAddr	=> $self->{'host'},
		PeerPort	=> $self->{'port'},
		Proto		=> 'tcp',
		Type		=> SOCK_STREAM,
		%params
	);

	if (!defined($self->{'connection'}) || ($@ && $@ ne '')) {
		chomp($@);
		$@ =~ s/^$SocketClass:? ?//;
		croak("Connection to $self->{'host'}:$self->{'port'} failed: $@")
	};

	return 1;
}

sub _connect_unix {
	my ($self, %params) = @_;

	$self->{'connection'} = IO::Socket::UNIX->new(
		Peer		=> $self->{'sock'},
		Type		=> SOCK_STREAM,
		%params
	);

	croak("Connection to $self->{'host'}:$self->{'port'} failed: $@") if (!defined($self->{'connection'}) || ($@ && $@ ne ''));

	return 1;

}

=pod

=head2 Communicating with the server:

	my $answer = $epp->request($question);

This is a simple wrapper around C<get_frame()> and C<send_frame()> (see below).
This method accepts a "question" frame as an argument, sends it to the server,
and then returns the next frame the server sends back.

=cut

sub request {
	my ($self, $frame) = @_;
	return $self->get_frame if ($self->send_frame($frame));
}

=pod

=head2 Getting a frame from the server:

	my $frame = $epp->get_frame;

This method returns an EPP response frame from the server. This may either be a
scalar filled with XML, an L<XML::LibXML::Document> object (or an
L<XML::DOM::Document> object), depending on whether you defined the C<dom>
parameter to the constructor.

B<Important Note>: this method will block your program until it receives the
full frame from the server. That could be a bad thing for your program, so you
might want to consider using the C<alarm()> function to apply a timeout, like
so:

	my $timeout = 10; # ten seconds

	eval {
		local $SIG{ALRM} = sub { die "alarm\n" };
		alarm($timeout);
		my $frame = $epp->get_frame;
		alarm(0);
	};

	if ($@ ne '') {
		alarm(0);
		print "timed out\n";
	}

If the connection to the server closes before the response can be received, or
the server returned a mal-formed frame, this method will C<croak()>.

=cut

sub get_frame {
	my $self = shift;
	return $self->get_return_value(Net::EPP::Protocol->get_frame($self->{'connection'}));
}

sub get_return_value {
	my ($self, $xml) = @_;

	if (!defined($self->{'class'})) {
		return $xml;

	} else {
		my $document;
		eval { $document = $self->parser->parse_string($xml) };
		if (!defined($document) || $@ ne '') {
			chomp($@);
			croak(sprintf("Frame from server wasn't well formed: %s\n\nThe XML looks like this:\n\n%s\n\n", $@, $xml));
			return undef;

		} else {
			my $class = $self->{'class'};
			return bless($document, $class);

		}
	}
}

=pod

=head2 Sending a frame to the server:

	$epp->send_frame($frame, $wfcheck);

This sends a request frame to the server. C<$frame> may be one of:

=over

=item * a scalar containing XML

=item * a scalar containing a filename

=item * an L<XML::LibXML::Document> object (or an instance of a subclass)

=item * an L<XML::DOM::Document> object (or an instance of a subclass)

=back

Unless C<$wfcheck> is false, the first two of these will be checked for
well-formedness. If the XML data is broken, then this method will croak.

=cut

sub send_frame {
	my ($self, $frame, $wfcheck) = @_;

	my $xml;
	if (ref($frame) ne '' && ($frame->isa('XML::DOM::Document') || $frame->isa('XML::LibXML::Document'))) {
		$xml		= $frame->toString;
		$wfcheck	= 0;

	} elsif ($frame !~ /</ && -e $frame) {
		if (!open(FRAME, $frame)) {
			croak("Couldn't open file '$frame' for reading: $!");

		} else {
			$xml = join('', <FRAME>);
			close(FRAME);
			$wfcheck = 1;

		}

	} else {
		$xml		= $frame;
		$wfcheck	= ($wfcheck ? 1 : 0);

	}

	if ($wfcheck == 1) {
		eval { $self->parser->parse_string($xml) };
		if ($@ ne '') {
			chomp($@);
			croak(sprintf("Frame from server wasn't well formed: %s\n\nThe XML looks like this:\n\n%s\n\n", $@, $xml));
		}
	}

	return Net::EPP::Protocol->send_frame($self->{'connection'}, $xml);
}

=pod

=head2 Disconnecting from the server:

	$epp->disconnect;

This closes the connection. An EPP server should always close a connection after
a E<lt>logoutE<gt> frame has been received and acknowledged; this method
is provided to allow you to clean up on the client side, or close the
connection out of sync with the server.

=cut

sub disconnect {
	my $self = shift;
	$self->{'connection'}->close if ($self->{'connection'});
	return 1;
}

sub parser {
	my $self = shift;
	$self->{'parser'} = Net::EPP::Parser->new if (!$self->{'parser'});
	return $self->{'parser'};
}

1;
