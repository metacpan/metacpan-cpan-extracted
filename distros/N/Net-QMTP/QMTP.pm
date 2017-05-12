package Net::QMTP;

require 5.001;
use strict;

use IO::Socket;
use Carp;
use Text::Netstring qw(netstring_encode netstring_decode netstring_read
		netstring_verify);

#
# Copyright (c) 2003 James Raftery <james@now.ie>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
# Please submit bug reports, patches and comments to the author.
# Latest information at http://romana.now.ie/#net-qmtp
#
# $Id: QMTP.pm,v 1.22 2004/11/02 14:56:18 james Exp $
#
# This module is an object interface to the Quick Mail Transfer Protocol
# (QMTP). QMTP is a replacement for the Simple Mail Transfer Protocol
# (SMTP). It offers increased speed, especially over high latency
# links, pipelining, 8-bit data transmission and predeclaration of
# line-ending encoding.
#
# See the Net::QMTP man page that was installed with this module for
# information on how to use the module. You require version 0.04 or
# later of the Text::Netstring module.
#

use vars qw($VERSION);
$VERSION = "0.06";

sub new {
	my $proto = shift or croak;
	my $class = ref($proto) || $proto;
	my $server = shift or croak "No server specified in constructor";
	my %args;

	%args = @_ if @_;
	my $self = {
		SENDER		=> undef,
		RECIPIENTS	=> [],
		MESSAGE		=> undef,
		MSGFILE		=> undef,
		ENCODING	=> undef,
		SOCKET		=> undef,
		SERVER		=> undef,
		PORT		=> 209,
		DEBUG		=> undef,
		TIMEOUT		=> undef,	# use IO::Socket default
		CONNECTTIME	=> undef,
		SESSIONLIMIT	=> 3600,	# 1 hour
	};
	if ($args{'Debug'}) {
		$self->{DEBUG} = 1;
		warn "debugging on; Version: $VERSION; RCS " .
			qq$Revision: 1.22 $ . "\n";
	}
	$self->{SERVER} = $server or croak "Constructor server failed";
	warn "server set to '$server'\n" if $self->{DEBUG};
	bless($self, $class);
	unless ($self->encoding("__GUESS__")) {
		carp "Constructor encoding() failed";
		return undef;
	}
	if ($args{'ConnectTimeout'}) {
		$self->{TIMEOUT} = $args{'ConnectTimeout'};
		warn "timeout ".$self->{TIMEOUT}."\n" if $self->{DEBUG};
	}
	if ($args{'Port'}) {
		$self->{PORT} = $args{'Port'};
		warn "port set to ".$self->{PORT}."\n" if $self->{DEBUG};
	}
	unless ($args{'DeferConnect'}) {
		warn "calling reconnect()\n" if $self->{DEBUG};
		$self->reconnect() or return undef;
	}
	warn "constructor finished\n" if $self->{DEBUG};
	return $self;
}

sub reconnect {
	my $self = shift;
	ref($self) or croak;

	my $sock = $self->{SOCKET};

	# if have a socket, disconnect first
	if (defined($sock)) {
		#carp "Socket is already defined";
		#return undef;
		$self->disconnect() or return undef;
	}

	# Applying timeout() to socket seems to fail. Hmm.
	warn "opening socket to " . $self->{SERVER} . "\n" if $self->{DEBUG};
	if ($self->{TIMEOUT}) {
		warn "socket timeout ".$self->{TIMEOUT}."\n" if $self->{DEBUG};
		$sock = IO::Socket::INET->new(
				PeerAddr	=> $self->{SERVER},
				PeerPort	=> $self->{PORT},
				Timeout		=> $self->{TIMEOUT},
				Proto		=> 'tcp') or return undef;
	} else {
		warn "socket default timeout\n" if $self->{DEBUG};
		$sock = IO::Socket::INET->new(
				PeerAddr	=> $self->{SERVER},
				PeerPort	=> $self->{PORT},
				Proto		=> 'tcp') or return undef;
	}

	binmode($sock);
	$self->{SOCKET} = $sock;
	$sock->autoflush();
	warn "socket opened to " . $sock->peerhost() . "\n" if $self->{DEBUG};
	$self->{CONNECTTIME} = time;
	warn "connected at " . $self->{CONNECTTIME} . "\n" if $self->{DEBUG};
	return $self->{SOCKET};
}

sub disconnect {
	my $self = shift;
	ref($self) or croak;

	my $sock = $self->{SOCKET};

	# can't disconnect if no socket
	if (!defined($sock)) {
		carp "Socket is not defined";
		return undef;
	}

	##
	## Only on newer perls
	##
	### can't disconnect if not connected
	##if (!$sock->connected()) {
	##	carp "Socket is not connected";
	##	$self->{SOCKET} = undef;
	##	return undef;
	##}

	warn "closing socket to " . $sock->peerhost() . "\n" if $self->{DEBUG};
	unless (close $sock) {
		carp "Cannot close socket: $!";
		return undef;
	}
	$self->{SOCKET} = undef;
	warn "socket closed (was open for " . (time - $self->{CONNECTTIME}) .
				"s)\n" if $self->{DEBUG};
	return 1;
}

sub encoding {
	my $self = shift;
	ref($self) or croak;
	my $e = shift or return $self->{ENCODING};

	# guess from input record seperator
	if ($e eq "__GUESS__") {
		warn "guessing encoding\n" if $self->{DEBUG};
		if ($/ eq "\015\012") {		# CRLF: Dos/Win
			$self->{ENCODING} = "\015";
			warn "guessed carraige-return encoding\n" if $self->{DEBUG};
		} else {			# LF: Unix-like
			$self->{ENCODING} = "\012";
			warn "guessed line-feed encoding\n" if $self->{DEBUG};
		}

	# specific encoding requested
	} elsif ($e eq "dos") {
		$self->{ENCODING} = "\015";
		warn "set carraige-return encoding\n" if $self->{DEBUG};
	} elsif ($e eq "unix") {
		$self->{ENCODING} = "\012";
		warn "set line-feed encoding\n" if $self->{DEBUG};
	} else {
		croak "Unknown encoding: '$e'";
		$self->{ENCODING} = undef;	
	}

	return $self->{ENCODING};
}

sub server {
	my $self = shift;
	ref($self) or croak;
	$self->{SERVER} = shift if @_;
	warn "server is " . $self->{SERVER} . "\n" if $self->{DEBUG};
	return $self->{SERVER};
}

sub sender {
	my $self = shift;
	ref($self) or croak;
	$self->{SENDER} = shift if @_;
	warn "sender is " . $self->{SENDER} . "\n" if $self->{DEBUG};
	return $self->{SENDER};
}

sub recipient {
	my $self = shift;
	ref($self) or croak;
	push(@{$self->{RECIPIENTS}}, shift) if @_;
	warn "recipients are ". join(",", @{$self->{RECIPIENTS}}) .
			"\n" if $self->{DEBUG};
	return $self->{RECIPIENTS};
}

sub message {
	my $self = shift;
	ref($self) or croak;
	warn "message() started\n" if $self->{DEBUG};
	if ($self->{MSGFILE}) {
		carp "Message already created by message_from_file()";
		return undef;
	}
	$self->{MESSAGE} .= shift if @_;
	warn "message text appended (is now " . length($self->{MESSAGE}) .
				" bytes)\n" if $self->{DEBUG};
	return $self->{MESSAGE};
}

sub message_from_file {
	my $self = shift;
	ref($self) or croak;
	warn "message_from_file() started\n" if $self->{DEBUG};
	if (defined($self->{MESSAGE})) {
		carp "Message already created by message()";
		return undef;
	}
	my $f = shift or return $self->{MSGFILE};
	#
	# This is permitted in case the file needs to be created/modified
	# by some subsequent process
	## -f $f or return undef;
	#
	warn "message_from_file file is '$f'\n" if $self->{DEBUG};
	$self->{MSGFILE} = $f;
	return $self->{MSGFILE};
}

sub new_message {
	my $self = shift;
	ref($self) or croak;

	$self->{MESSAGE} = undef;
	$self->{MSGFILE} = undef;
	warn "message reset\n" if $self->{DEBUG};
	return 1;
}

sub new_envelope {
	my $self = shift;
	ref($self) or croak;

	$self->{SENDER} = undef;
	$self->{RECIPIENTS} = [];
	warn "envelope reset\n" if $self->{DEBUG};
	return 1;
}

sub _send_file {
	my $self = shift;
	ref($self) or die;
	my $f = $self->{MSGFILE};
	my $sock = $self->{SOCKET};

	warn "_send_file starting\n" if $self->{DEBUG};
	unless (open(FILE, $f)) {
		carp "Cannot open file '$f': $!";
		return undef;
	}
	my $size = (stat(FILE))[7];
	binmode(FILE);
	#carp "File '$f' is empty" if $size == 0;
	if ($size < 0) {
		carp "File '$f' has negative size";
		return undef;
	}

	my $len;
	print $sock ($size+1) . ":" . $self->{ENCODING} or return undef;
	while (<FILE>) { print $sock $_ or return undef; $len += length($_) };

	if ($size != $len) {
		warn "File '$f' should be $size but we read $len\n";
		return undef;
	}
	print $sock "," or return undef;
	unless (close FILE) {
		carp "Cannot close file '$f': $!";
		return undef;
	}
	warn "_send_file finished\n" if $self->{DEBUG};
	return 1;
}

sub send {
	my $self = shift;
	ref($self) or croak;

	warn "send() running sanity checks\n" if $self->{DEBUG};
	$self->_ready_to_send() or return undef;
	##$self->_session_notexpired() or return undef;
	my $sock = $self->{SOCKET};

	if ($self->{MSGFILE}) {
		warn "calling _send_file for " . $self->{MSGFILE} .
				"\n" if $self->{DEBUG};
		$self->_send_file() or return undef;
	} else {
		warn "sending message data\n" if $self->{DEBUG};
		print $sock netstring_encode($self->{ENCODING} .
			$self->{MESSAGE}) or return undef;
	}

	my($s, %r);

	$s = netstring_encode($self->{SENDER});
	warn "sending envelope sender $s\n" if $self->{DEBUG};
	print $sock $s or return undef;

	$s = netstring_encode(scalar netstring_encode($self->{RECIPIENTS}));
	warn "sending envelope recipient(s) $s\n" if $self->{DEBUG};
	print $sock $s or return undef;
	
	$s = undef;
	foreach (@{$self->{RECIPIENTS}}) {
		warn "read response\n" if $self->{DEBUG};
		$s = $self->_read_netstring();
		warn "parse response: $s\n" if $self->{DEBUG};
		CASE: {
			$s =~ s/^K/success: / and last CASE;
			$s =~ s/^Z/deferral: / and last CASE;
			$s =~ s/^D/failure: / and last CASE;
			_badproto();
		}
		$r{$_} = $s;
	}

	warn "finished send()\n" if $self->{DEBUG};
	return \%r;
}

sub _ready_to_send {
	my $self = shift;
	ref($self) or die;

	warn "_ready_to_send() starting\n" if $self->{DEBUG};
	# need defined sender (don't need true; empty string valid),
	# recipient(s), defined message, socket and an encoding
	return (defined($self->{SENDER}) and scalar(@{$self->{RECIPIENTS}}) and
		(defined($self->{MESSAGE}) or $self->{MSGFILE}) and
		$self->{SOCKET} and $self->{ENCODING});
}

sub _session_notexpired {
	my $self = shift;
	ref($self) or die;

	if (time - $self->{CONNECTTIME} > $self->{SESSIONLIMIT}) {
		carp "Session has expired";
		$self->disconnect();	# what about failure?
		return undef;
	}
	return 1;
}

sub _read_netstring {
	my $self = shift;
	ref($self) or die;
	my $sock = $self->{SOCKET};

	my $s = netstring_read($sock);

	if (defined $s and netstring_verify($s)) {
		return netstring_decode($s);
	}
	return "";
}

sub _badproto {
	confess "Protocol violation\n";
}

sub _badresources {
	confess "Excessive resources requested\n";
}

sub DESTROY {
	my $self = shift;
	ref($self) or die;
	$self->disconnect() if $self->{SOCKET};	# don't care about failure
}

1;

__END__

=head1 NAME

Net::QMTP - Quick Mail Transfer Protocol (QMTP) client

=head1 SYNOPSIS

 use Net::QMTP;

 $qmtp = Net::QMTP->new('mail.example.org');

 $qmtp->sender('sender@example.org');
 $qmtp->recipient('foo@example.org');
 $qmtp->recipient('bar@example.org');

 $qmtp->message($datatext);

 $qmtp->encoding('unix');
 $qmtp->message_from_file($filename);

 $qmtp->server('server.example.org');
 $qmtp->new_envelope();
 $qmtp->new_message();

 $qmtp->reconnect()
 $qmtp->send();
 $qmtp->disconnect()

=head1 DESCRIPTION

This module implements an object orientated interface to a Quick Mail
Transfer Protocol (QMTP) client, which enables a perl program to send
email by QMTP.

=head2 CONSTRUCTOR

=over 4

=item new(HOST [, OPTIONS])

The new() constructor creates a new Net::QMTP object and returns a
reference to it if successful, undef otherwise. C<HOST> is the FQDN or
IP address of the QMTP server to connect to and it is mandatory. By
default, the TCP session is established when the object is created but
it may be brought down and up at will by the disconnect() and
reconnect() methods.

C<OPTIONS> is an optional list of hash key/value pairs from the
following list:

B<DeferConnect> - set to 1 to disable automatic connection to the server
when an object is created by new(). If you do this you must explicitly
call reconnect() when you want to connect.

B<ConnectTimeout> - change the default connection timeout associated
with the C<IO::Socket> socket used. Specify this value in seconds.

B<Port> - connect to the specified port on the QMTP server. The
default is to connect to port 209.

B<Debug> - set to 1 to enable debugging output.

See L<"EXAMPLES">.

=back

=head2 METHODS

=over 4

=item sender(ADDRESS) sender()

Return the envelope sender for this object if called with no argument,
or set it to the supplied C<ADDRESS>. Returns undef if the sender is not
yet defined. An empty envelope sender is quite valid. If you want this,
be sure to call sender() with an argument of an empty string.

=item recipient(ADDRESS) recipient()

If supplied, add C<ADDRESS> to the list of envelope recipients. If not,
return a reference to the current list of recipients. Returns a
reference to an empty list if recipients have not yet been defined.

=item server(HOST) server()

If supplied, set C<HOST> as the QMTP server this object will connect to.
If not, return the current server or undef if one is not set. You will
need to call reconnect() to give effect to your change.

=item message(TEXT) message()

If supplied, append C<TEXT> to the message data. If not, return the
current message data. It is the programmer's responsibility to create a
valid message including appropriate RFC 2822/822 header lines. An empty
message is quite valid. If you want this, be sure to call message() with
an argument of an empty string.

This method cannot be used on a object which has had message data
created by the message_from_file() method. Use new_message() to erase
the current message contents.

=item message_from_file(FILE)

Use the contents of C<FILE> as the message data. It is the programmer's
responsibility to create a valid message in C<FILE> including
appropriate RFC 2822/822 header lines.

This method cannot be used on a object which has had message data
created by message(). Use new_message() to erase the current message
contents.

=item encoding(TYPE) encoding()

Set the line-ending encoding for this object to the specified C<TYPE>,
which is one of:

B<unix> - Unix-like line ending; lines are delimited by a line-feed
character.

B<dos> - DOS/Windows line ending; lines are delimited by a
carraige-return line-feed character pair.

The constructor will make a guess at which encoding to use based on
the value of $/. Call encoding() without an argument to get the
current line-encoding. It will return a line-feed for C<unix>, a
carraige-return for C<dos> or undef if the encoding couldn't be set.

Be sure the messages you create with message() and
message_from_file() have appropriate line-endings.

=item send()

Send the message. It returns a reference to a hash or undef if the
operation failed. The hash is keyed by recipient address. The value for
each key is the response from the QMTP server, prepended with one of:

B<success:> - the message was accepted for delivery

B<deferral:> - temporary failure. The client should try again later

B<failure:> - permanent failure. The message was not accepted and should
not be tried again

See L<"EXAMPLES">.

You almost certainly want to use reconnect() if send() fails as the QMTP
server will be in an undetermined state and probably won't be able to
accept a new message over the existing connection. The protocol allows a
client to close the connection early; the server will discard the data
already sent without attempting delivery.

=item new_envelope()

Reset the object's envelope information; sender and recipients. Does
not affect the message data.

=item new_message()

Reset the object's message information; message text or message file.
Does not affect the envelope.

=item disconnect()

Close the network connection to the object's server. Returns undef if
this fails. The object's destructor will call disconnect() to be sure
any open socket is closed cleanly when the object is destroyed.

=item reconnect()

Reestablish a network connection to the object's server, disconnecting
the current connection if present. Returns undef if the operation could
not be completed.

=back

=head1 EXAMPLES

 use Net::QMTP;
 my $qmtp = Net::QMTP->new('server.example.org', Debug => 1) or die;

 $qmtp->sender('sender@example.org');
 $qmtp->recipient('joe@example.org');
 $qmtp->message('From: sender@example.org' . "\n" .
 		'To: joe@example.org' . "\n" .
		"Subject: QMTP test\n\n" .
		"Hi Joe!\nThis message was sent over QMTP");

 my $response = $qmtp->send() or die;
 foreach (keys %{ $response }) {
	 print $_ . ": " . ${$response}{$_} . "\n";
 }
 $qmtp->disconnect();

=head1 SEE ALSO

L<qmail-qmtpd(8)>, L<maildirqmtp(1)>, L<IO::Socket(3)>,
L<Text::Netstring(3)>.

=head1 NOTES

The QMTP protocol is described in http://cr.yp.to/proto/qmtp.txt

QMTP is a replacement for SMTP and, similarly, requires a QMTP server
for to a QMTP client to communicate with. The qmail MTA includes a QMTP
server; qmail-qmtpd. Setting up the server is outside the scope of the
module's documentation. See http://www.qmail.org/ for more QMTP
information.

This module requires version 0.04 or later of the Text::Netstring
module.

=head1 CAVEATS

Be aware of your line endings! C<\n> means different things on different
platforms.

If, on a Unix system, you say:

 $qmtp->encoding("dos");

with the intention of later supplying a DOS formatted file, don't make
the mistake of substituting message_from_file() with something like:

 $qmtp->message($lineone . "\n" . $linetwo);

On Unix systems C<\n> is (only) a line-feed. You should either
explicitly change the encoding back to C<unix> or supply your text with
the proper encoding:

 $qmtp->message($lineone . "\r\n" . $linetwo);

=head1 BUGS

Also known as the TODO list:

=over 4

=item *

how to report an error message? An error() method?

=item *

message data can't be created from message() and message_from_file()

=item *

socket timeout granularity? we don't handle a timeout well
read timeout? alarm, SIG{ALRM} w/anon. sub to undef SOCKET?

=item *

client does NOT need to wait for a server response before sending
another package (sec. 2) client's responsibility to avoid deadlock;
if it sends a package before receiving all expected server responses,
it must continuously watch for those responses (sec. 2)

=item *

we should write more tests

=item *

server is permitted to close the connection at any time. Any response
not received by the client indicates a temp. failure (sec. 2)

=item *

a QMTP session should take at most 1 hour (sec. 2)

=back

=head1 AUTHOR

James Raftery <james@now.ie>.

=cut
