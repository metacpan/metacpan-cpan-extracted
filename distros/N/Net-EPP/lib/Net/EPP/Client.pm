package Net::EPP::Client;
use Carp;
use IO::Socket::IP;
use IO::Socket::SSL;
use Net::EPP::Parser;
use Net::EPP::Frame::Response;
use Net::EPP::Protocol;
use bytes;
use strict;
use warnings;

=pod

=head1 NAME

Net::EPP::Client - a client library for the
L<TLS transport|https://www.rfc-editor.org/rfc/rfc5734.html> of the L<Extensible
Provisioning Protocol (EPP)|https://www.rfc-editor.org/info/std69>.

=head1 SYNOPSIS

	#!/usr/bin/perl
	use Net::EPP::Client;
	use strict;

	my $epp = Net::EPP::Client->new('host'  => 'epp.nic.tld');

	my $greeting = $epp->connect;

	$epp->send_frame('login.xml');

	my $answer = $epp->get_frame;

	my $answer = $epp->request('<epp><logout /></epp>');

=head1 DESCRIPTION

L<RFC 5743|https://www.rfc-editor.org/rfc/rfc5734.html> defines a TCP- (and
TLS-) based transport model for EPP, and this module implements a client for
that model. You can establish and manage EPP connections and send and receive
responses over this connection.

C<Net::EPP::Client> is a low-level EPP client. If you are writing applications,
you should use L<Net::EPP::Simple> instead.

=head1 CONSTRUCTOR

	my $epp = Net::EPP::Client->new(%PARAMS);

The constructor method creates a new EPP client object. It accepts a number of
parameters:

=over

=item * C<host>

MANDATORY. Specifies the computer to connect to. This may be a DNS hostname or
an IP address. If a hostname is provided, IPv6 will be used if available.

=item * C<port>

OPTIONAL. Specifies the TCP port to connect to. This defaults to C<700>.

=item * C<ssl>

OPTIONAL. If the value of this parameter is false, then a plaintext
connection will be created. Otherwise, L<IO::Socket::SSL> will be used to
provide an encrypted connection.

=item * C<frames>

DEPRECATED. If the value of this parameter is false, then the C<request()> and
C<get_frame()> methods (see below) will return strings instead of
C<Net::EPP::Frame::Response> objects.

=back

=cut

sub new {
    my ($package, %params) = @_;

    my $self;

    #
    # this is an undocumented and unsupported feature that allows clients to
    # connect to a local Unix socket instead of a TCP service. IIRC the only
    # use case for this was the old Net::EPP::Proxy module which went away 𝑛
    # decades ago, and it will be removed in a future release.
    #
    if (defined($params{'sock'})) {
        $self = {
            'sock' => $params{'sock'},
            'ssl'  => 0,
        };

    } else {
        croak("missing hostname") if (!defined($params{'host'}));

        $self = {
            'host' => $params{'host'},
            'port' => $params{'port'} || 700,

            #
            # since v0.27, TLS is enabled by default and must be explicitly
            # disabled.
            #
            'ssl' => (exists($params{'ssl'}) && !$params{'ssl'} ? 0 : 1),
        };
    }

    #
    # this option will also be removed in a future release.
    #
    $self->{'frames'} = (exists($params{'frames'}) && !$params{'frames'} ? 0 : 1);

    return bless($self, $package);
}

=pod

=head1 METHODS

=head2 CONNECTING TO A SERVER

	my $greeting = $epp->connect(%PARAMS);

This method establishes the TCP connection. You can use the C<%PARAMS> hash to
specify arguments that will be passed on to the constructors for
L<IO::Socket::IP> (such as a timeout) or L<IO::Socket::SSL> (such as
certificate information). Which of these modules will be used is determined by
the C<ssl> parameter that was provided when instantiating the object. See the
relevant manpage for examples.

This method will C<croak()> if connection fails, so be sure to use C<eval()> if
you want to catch the error.

By default, the return value for C<connect()> will be the EPP E<lt>greetingE<gt>
frame returned by the server. Please note that the same caveat about blocking
applies to this method as to C<get_frame()> (see below).

If you want to get the greeting yourself, set C<$params{no_greeting}> to C<1>.

If TLS is enabled, then you can use C<%params> to configure a client certificate
and/or server certificate validation behaviour.

=cut

sub connect {
    my ($self, %params) = @_;

    croak('already connected') if ($self->connected);

    if (defined($self->{'sock'})) {
        $self->_connect_unix(%params);

    } else {
        $self->_connect_tcp(%params);

    }

    return ($params{'no_greeting'} ? 1 : $self->get_frame);
}

sub _connect_tcp {
    my ($self, %params) = @_;

    my $class = ($self->{'ssl'} == 1 ? 'IO::Socket::SSL' : 'IO::Socket::IP');

    $self->{'connection'} = $class->new(
        'PeerAddr' => $self->{'host'},
        'PeerPort' => $self->{'port'},
        'Proto'    => 'tcp',
        'Type'     => SOCK_STREAM,
        %params
    );

    if (!defined($self->{'connection'}) || ($@ && $@ ne '')) {
        chomp($@);
        $@ =~ s/^$class:? ?//;
        croak("Connection to $self->{'host'}:$self->{'port'} failed: $@");
    }

    return 1;
}

sub _connect_unix {
    my ($self, %params) = @_;

    $self->{'connection'} = IO::Socket::UNIX->new(
        'Peer' => $self->{'sock'},
        'Type' => SOCK_STREAM,
        %params
    );

    if (!defined($self->{'connection'}) || ($@ && $@ ne '')) {
        croak("Connection to $self->{'host'}:$self->{'port'} failed: $@");
    }

    return 1;
}

=pod

=head2 COMMUNICATING WITH THE SERVER

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

=head2 GETTING A FRAME FROM THE SERVER

	my $frame = $epp->get_frame;

This method returns an EPP response frame from the server. This will be a
L<Net::EPP::Frame::Response> object unless the C<frames> argument to the
constructor was false, in which case it will be a string containing a blob of
XML.

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
    return $self->parse_response(Net::EPP::Protocol->get_frame($self->connection));
}

sub parse_response {
    my ($self, $xml) = @_;

    my $doc;
    eval { $doc = $self->parser->parse_string($xml) };
    if (!defined($doc) || $@ ne '') {
        chomp($@);
        croak(sprintf("Frame from server wasn't well formed: %s\n\nThe XML looks like this:\n\n%s\n\n", $@, $xml));

    } else {
        return bless($doc, 'Net::EPP::Frame::Response');

    }
}

=pod

=head2 SENDING A FRAME TO THE SERVER

	$epp->send_frame($frame);

This sends a request frame to the server. C<$frame> may be one of:

=over

=item * a scalar containing XML

=item * a scalar containing a filename

=item * an L<XML::LibXML::Document> object (or an instance of a subclass)

=item * an L<XML::DOM::Document> object (or an instance of a subclass)

=back

=cut

sub send_frame {
    my ($self, $frame) = @_;

    my $xml;
    if ($frame->isa('XML::DOM::Document') || $frame->isa('XML::LibXML::Document')) {
        $xml = $frame->toString;

    } elsif ($frame !~ /</ && -e $frame) {
        if (!open(FRAME, $frame)) {
            croak("Couldn't open file '$frame' for reading: $!");

        } else {
            $xml = join('', <FRAME>);
            close(FRAME);

        }

    } else {
        $xml = $frame;

    }

    return Net::EPP::Protocol->send_frame($self->connection, $xml);
}

=pod

=head2 DISCONNECTING FROM THE SERVER

	$epp->disconnect;

This closes the connection. An EPP server should always close a connection after
a E<lt>logoutE<gt> frame has been received and acknowledged; this method
is provided to allow you to clean up on the client side, or close the
connection out of sync with the server.

=cut

sub disconnect {
    my $self = shift;

    if ($self->connected) {
        $self->connection->close;
        delete($self->{'connection'});
    }

    return 1;
}

sub parser {
    my $self = shift;
    $self->{'parser'} = Net::EPP::Parser->new if (!$self->{'parser'});
    return $self->{'parser'};
}

=pod

    $connected = $epp->connected;

Returns a boolean if C<Net::EPP::Simple> has a connection to the server. Note that this
connection might have dropped, use C<ping()> to test it.

=cut

sub connected { defined(shift->connection) }

=pod

    $socket = $epp->connection;

Returns the underlying socket.

=cut

sub connection { shift->{'connection'} }

1;

=pod

=head1 COPYRIGHT

This module is (c) 2008 - 2023 CentralNic Ltd and 2024 Gavin Brown. This module
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut
