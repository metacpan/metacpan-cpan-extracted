#!/usr/local/bin/perl -w
#
# Net::ICB ver 1.6     10/7/98
# John M Vinopal        banshee@resort.com
#
# Copyright (C) 1996-98, John M Vinopal, All Rights Reserved.
# Permission is granted to copy and modify this program for
# non-commercial purposes, so long as this copyright notice is
# preserved.  This software is distributed without warranty.
# Commercial users must contact the author for licensing terms.
#

package Net::ICB;

require 5.004;
use strict;
use Carp;
use IO::Socket;
use vars qw($VERSION);
$VERSION = '1.6';

use vars qw($M_LOGIN $M_LOGINOK $M_OPEN $M_PERSONAL $M_STATUS
		$M_ERROR $M_ALERT $M_EXIT $M_COMMAND $M_CMDOUT $M_PROTO
		$M_BEEP $M_PING $M_PONG $M_OOPEN $M_OPERSONAL);
use vars qw($DEF_HOST $DEF_PORT $DEF_GROUP $DEF_CMD $DEF_USER);

require Exporter;

use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK);
@ISA = qw(Exporter);

%EXPORT_TAGS = ( client => [qw($M_LOGIN $M_LOGINOK $M_OPEN $M_PERSONAL
		$M_STATUS $M_ERROR $M_ALERT $M_EXIT $M_COMMAND $M_CMDOUT
		$M_PROTO $M_BEEP $M_PING)],
		defaults => [qw($DEF_HOST $DEF_PORT $DEF_GROUP $DEF_CMD $DEF_USER)] );

@EXPORT_OK = qw( $M_LOGIN $M_LOGINOK $M_OPEN $M_PERSONAL $M_STATUS $M_ERROR
		$M_ALERT $M_EXIT $M_COMMAND $M_CMDOUT $M_PROTO $M_BEEP $M_PING
		$M_PONG $M_OOPEN $M_OPERSONAL 
		$DEF_HOST $DEF_PORT $DEF_GROUP $DEF_CMD $DEF_USER);

# Default connection values.
# (evolve.icb.net, empire.icb.net, cjnetworks.icb.net, swcp.icb.net)
$DEF_HOST	= "default.icb.net";
$DEF_PORT	= 7326;
$DEF_GROUP	= "1";
$DEF_CMD	= "login";	# cmds are only "login" and "w"
$DEF_USER	= eval { getlogin() } || "user".substr(rand(), 2, 5);

# Protocol definitions: all nice cleartext.
my $DEL = "\001";	# Packet argument delimiter.
$M_LOGIN	= 'a';     # login packet 
$M_LOGINOK	= 'a';     # login response
$M_OPEN		= 'b';     # open msg to group 
$M_PERSONAL	= 'c';     # personal message
$M_STATUS	= 'd';     # group status update message 
$M_ERROR	= 'e';     # error message 
$M_ALERT	= 'f';     # important announcement 
$M_EXIT		= 'g';     # quit packet from server
$M_COMMAND	= 'h';     # send a command from user 
$M_CMDOUT	= 'i';     # output from a command 
$M_PROTO 	= 'j';     # protocol/version information 
$M_BEEP		= 'k';     # beeps 
$M_PING		= 'l';     # ping packet from server
$M_PONG		= 'm';     # return for ping packet 
# Archaic packets: some sort of echo scheme?
$M_OOPEN	= 'n';     # for own open messages 
$M_OPERSONAL	= 'o';     # for own personal messages 

# Create a new fnet object and optionally connect to a server.
# keys: host port user nick group cmd passwd
sub new {
	my	$class = shift;
	my	$self = {};
	bless $self, $class;
	if (!@_ or $self->connect(@_)) {
		return $self;
	}
	carp $self->error();
	return;
}

sub DESTROY {
	my	($self) = @_;
	$self->close();
	undef $self;
}

# Version Checking.
sub version { $VERSION; }

# Error reporting.
sub error { my $self = shift; return $self->{'errstr'}; }
sub clearerr { my $self = shift; delete $self->{'errstr'}; }

# Debugging.
sub debug { my $self = shift; my $level = shift; $self->{'debug'} = $level; }

# Return the object's socket.
sub fd {
	my ($self) = @_;
	return $self->{'socket'};
}

# Open or group wide message.
sub sendopen {
	@_ == 2 && ref($_[0]) or die '$obj->sendopen(string)';
	my	($self, $txt) = @_;
	my	($pbuf) = "$M_OPEN$txt";

	if (eval { $self->_sendpacket($pbuf) }) {
		return 'ok';
	}
	$self->{'errstr'} = $@;
	return;
}

# Private or user-directed message.
sub sendpriv {
	@_ >= 2 && ref($_[0]) or die '$obj->sendpriv(user, string)';
	my	($self, @args) = @_;
	return $self->sendcmd("m", @args);
	# Any $self->{'errstr'} will be set in sendcmd().
}

# Server processed command.
#sub sendcmd(cmd, args)
sub sendcmd {
	@_ >= 2 && ref($_[0]) or die '$obj->sendpriv(cmd, [args])';
	my	($self, $cmd, @args) = @_;
	my	$pbuf = "$M_COMMAND$cmd$DEL@args";

	if (eval { $self->_sendpacket($pbuf) }) {
		return 'ok';
	}
	$self->{'errstr'} = $@;
	return;
}

# Ping reply.
sub sendpong {
	@_ == 1 && ref($_[0]) or die '$obj->sendpong()';
 	my	($self) = shift;
	my	($pbuf) = "$M_PONG";

	if (eval { $self->_sendpacket($pbuf) }) {
		return 'ok';
	}
	$self->{'errstr'} = $@;
	return;
}

# Send a raw packet (ie: don't insert a packet type)
sub sendraw {
	@_ == 2 && ref($_[0]) or die '$obj->sendraw()';
 	my	($self) = shift;
	my	($pbuf) = shift;

	if (eval { $self->_sendpacket($pbuf) }) {
		return 'ok';
	}
	$self->{'errstr'} = $@;
	return;
}

# Read a message from the server and break it into its fields.
# XXX - timeout to prevent sitting on bad socket?
sub readmsg {
	@_ == 1 && ref($_[0]) or die '$obj->readmsg()';
	my	$self = shift;
	my	$msg;

	# Read the waiting packet.
	if (eval { $msg = $self->_recvpacket() }) {
		# Break up the message.
		my ($type, $buf) = unpack("aa*", $msg);
		my @split = split($DEL, $buf);
		# Reply to a ping with a pong.
		# XXX - let client decide about this?
		$self->sendpong() if $type eq $M_PING;
		return ($type, @split);
	}
	$self->{'errstr'} = $@;
	return;
}

# Connect to a server and send our login packet.
# keys: host port user nick group cmd passwd
sub connect {
	my	$self = shift;
	my	%args = @_;

	undef %$self;	# Clear previous values.
	$self->debug(0);
	my $hostname = $args{'host'} || $DEF_HOST;
	my $portnumber = $args{'port'} || $DEF_PORT;
	if (eval { $self->_tcpopen($hostname,$portnumber) }) {
		if (eval { $self->_sendlogin(@_) }) {
			return 'ok';
		}
		undef %$self;
	}
	$self->{'errstr'} = "connect: $@";
	return;
}

sub close {
	my $self = shift;
	if (defined $self->{'socket'}) {
		shutdown($self->{'socket'}, 2);
		CORE::close($self->{'socket'});
	}
	undef %$self;
}

#### Internal Methods for Net::ICB ####

# Sends a login packet to the server.  It specifies our login name,
# nickname, active group, a command "login" or "w", and our passwd.
sub _sendlogin {
	my	$self = shift;
	my	%args = @_;
	my	($user, $nick, $group, $cmd, $passwd);

	$user = $args{'user'} || $DEF_USER;
	$nick = $args{'nick'} || $user;
	$group = $args{'group'} || $DEF_GROUP;
	$cmd = $args{'cmd'} || $DEF_CMD;
	$passwd = $args{'passwd'} || "";

	my	($pbuf) = $M_LOGIN;
	$pbuf .= join($DEL, ($user, $nick, $group, $cmd, $passwd));

	if (eval { $self->_sendpacket($pbuf) }) {
		$self->{'user'} = $user;
		# XXX - wait for protocol and loginok packets?
		return 'ok';
	}
	die "sendlogin: $@";
}

# Send a packet to the server.
sub _sendpacket {
	my	($self, $packet) = @_;
	my	($socket) = $self->fd;
	my	($plen) = length($packet);	# Size plus null.

	print "SEND: ",$plen+1,"b -- $packet\\0" if ($self->{'debug'});
	# Bounds checking to MAXCHAR-1 (terminating null).
	if ($plen > 254) {
		die "send: packet > 255 bytes";
		# XXX - truncate and send instead?
		#$plen = 254;
		#warn "truncated to $plen bytes\n";
		#$packet = substr($packet, 0, $plen);
	}

	# Add the terminating null.
	$packet .= "\0"; $plen++;

	# Add the packet length (<= 255) to the packet head.
	$packet = chr($plen).$packet; $plen++;

	my $wrotelen = send($socket, $packet, 0);
	if (not defined($wrotelen)) {
		die "send: $!";
	} elsif ($wrotelen != $plen) {
		die "send: wrote $wrotelen of $plen: $!";
	} else {
		return 'ok';
	}
	return;
}


# Read a pending packet from the socket.  Will block forever.
sub _recvpacket {
	my	($self) = @_;
	my	($socket) = $self->fd;
	my	($slen, $buffer, $ret);

	# Read a byte of packet length.
	$ret = recv($socket, $slen, 1, 0);
	if (not defined($ret)) {
		die "recv size: $!";
	} elsif (length($slen) != 1) {
		die "recv size != 1: $!";
	} else {
		# Convert char to integer.
		$slen = ord($slen);
		print "RECV: reading $slen" if ($self->{'debug'} > 1);
		while ($slen) {	# Read the entire packet.
			my $pbuf;
			$ret = recv($socket, $pbuf, $slen, 0);
			if (not defined($ret)) {
				die "recv msg: $!";
			} else {
				$slen -= length($pbuf);
				$buffer .= $pbuf;
			}
		}
		print "RECV: ",length($buffer),"b -- $buffer\\0" if ($self->{'debug'});
		# Remove trailing null.
		chop($buffer);
		return($buffer);
	}
	return;
}

#	tcpopen(hostname,portnumber);
#	Returns a connected socket if all goes well.
sub _tcpopen {
	my	($self,$hostname,$portnumber) = @_;

	my $socket = new IO::Socket::INET(
			PeerAddr => $hostname,
			PeerPort => "($portnumber)",
			Proto	 => 'tcp') or die "_tcpopen: $@";

	$self->{'socket'} = $socket;
	$self->{'host'} = $hostname;
	$self->{'port'} = $portnumber;
	return 'ok';
}

1;
__END__

=head1 NAME

Net::ICB -- Object oriented interface to an fnet server.

=head1 SYNOPSIS

	use Net::ICB qw(:client);
        
	$obj = new Net::ICB('user' => "chatter");
	($type, @msg) = $obj->readmsg();
	exit unless ($type eq $M_PROTO);
	($type, @msg) = $obj->readmsg();
	exit unless ($type eq $M_LOGINOK);

	my $msg = "Hello to the group";
	$obj->sendopen($msg);

=head1 DESCRIPTION

C<Net::ICB> provides an object interface to a fnet/icb style chat server.
FNET or ICB is an old chat protocol dating back to 1988.  The original
code was written in fortran on some godforsaken machine at UKY by Sean
Casey.  After the server was rewritten in C, various servers sprung up
and died over the years.  As of 1998, approximately 4 public servers run,
the most popular of which peaks at ~150 people.  See http://www.icb.net/
for more information.

=head1 PROTOCOL

The ICB protocol uses only ascii text.  Packets consist of a single byte
of size, followed by up to 254 bytes of data.  The data block contains
a leading byte describing the data type, the data itself, and a trailing
null.  Multiple fields in the data are delimited by \001.

Turn on debugging and it'll become obvious.

=head1 CLASS METHODS

=over 4

=item B<new> - create a new Net::ICB object.

    my $obj = Net::ICB->new( [host   => $hostname,]
                             [port   => $port,]
                             [user   => $username,]
                             [nick   => $nickname,]
                             [group  => $initialgroup,]
                             [cmd    => $command,]
                             [passwd => $password] );

Constructs a new Net::ICB object.  A new object is returned on success,
null on failure with a C<carp()'ed> error message.

If any arguments are given, then C<new()> calls C<connect()> to establish a
connection to an ICB server.  Also see C<connect()>.  Any missing parameters
are taken from the I<$DEF_*> variables defined in Net::ICB.pm.

=item B<version> - return the module version number.

    my $ver = Net::ICB->version();

    print $obj->version();

Returns the Net::ICB.pm version number.  Also available as a instance method.

=back

=head1 INSTANCE METHODS

=over 4

=item B<connect> - connect to an ICB server.

    $obj->connect( [host   => $hostname,]
                   [port   => $port,]
                   [user   => $username,]
                   [nick   => $nickname,]
                   [group  => $initialgroup,]
                   [cmd    => $command,]
                   [passwd => $password] );

Establishes a connection to an ICB server and sends a login packet.
Any missing parameters are taken from the I<$DEF_*> variables defined
in Net::ICB.pm.

Unlike C<new()>, C<connect()> creates a connection even in the absence
of arguments.  Returns null on failure, check C<error()> for specific
failure code.

=item B<error> - return the internal error string.

    die $obj->error() unless ($obj->connect());

Returns a string pertaining to the last error.  This string is not
cleared between operations: check the return code first.

=item B<clearerr> - clear the internal error string.

    $obj->clearerr();

Clears the internal error string.

=item B<debug> - set and return the internal debug level.

    $obj->debug(1);

    print "Debug: ", $obj->debug(), "\n";

With an argument, C<debug()> sets the internal debug level and returns
the new value.  Without, the current debug level is returned.

=item B<fd> - return socket file descriptor.

    fileno($obj->fd());

Returns the socket associated with the currect connection.

=item B<sendopen> - send an open message to the current group.

    $obj->sendopen($msg);

Sends a public message to the user's current group.  Returns null on
failure, check C<error()> for details.

=item B<sendpriv> - send a private message to a particular user.

    $obj->sendpriv($nickname, $msg);

    $obj->sendpriv("$nickname $msg");

Sends a private message to a named user.  Returns null on
failure, check C<error()> for details.

=item B<sendcmd> - send an arbitrary command to the server.

    $obj->sendcmd("beep", $username);

    $obj->sendcmd("g", $groupname);

Sends an arbitrary command to the server.  Available commands vary by
server but most provide m, w, g, name.  Try "/m server help" or "/s_help".
Returns null on failure, check C<error()> for details.

=back

=head1 EXAMPLES

Alter the default variables from a client.

    use Net::ICB qw(:defaults);
    $DEF_HOST = "myhost.com";
    $DEF_GROUP = "myhost";

Check who is on a server.

    use Net::ICB qw(:client);
    my $who = Net::ICB->new(cmd => 'w');
	die unless $who;
	while (my ($type, @packet) = $who->readmsg()) {
		exit if ($type eq $M_EXIT);
        print "@packet\n";
    }

=head1 AUTHOR

John M Vinopal, banshee@resort.com

=cut
