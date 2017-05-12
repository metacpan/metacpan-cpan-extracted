package Net::Gnutella::Connection;
use Net::Gnutella::Packet::Ping;
use Net::Gnutella::Packet::Pong;
use Net::Gnutella::Packet::Push;
use Net::Gnutella::Packet::Query;
use Net::Gnutella::Packet::Reply;
use Net::Gnutella::Event;
use HTTP::Request;
use HTTP::Date;
use HTTP::Status;
use LWP::MediaTypes qw(guess_media_type);
use URI::URL;
use IO::File;
use Carp qw(carp croak confess);
use strict;
use vars qw/$VERSION $AUTOLOAD/;

$VERSION = $VERSION = "0.1";

# Use AUTOHANDLER to supply generic attribute methods
#
sub AUTOLOAD {
	my $self = shift;
	my $attr = $AUTOLOAD;
	$attr =~ s/.*:://;
	return unless $attr =~ /[^A-Z]/; # skip DESTROY and all-cap methods
	confess sprintf "invalid attribute method: %s->%s()", ref($self), $attr unless exists $self->{_attr}->{lc $attr};
	$self->{_attr}->{lc $attr} = shift if @_;
	return $self->{_attr}->{lc $attr};
}

sub disconnect {
	my ($self, $type) = @_;

	printf STDERR "+ Disconnecting socket (%s)\n", $type if $self->debug;

	if ($type) {
		my $event = Net::Gnutella::Event->new(
			from => $self,
			type => $type,
		);

		$self->parent->_handler($event);
	}

	$self->parent->_remove_fh($self->socket, "rw");
	$self->readbuf("");
	$self->writebuf("");
	$self->connected(0);
	$self->socket("");
}

# ->forward( PACKET [, REPLY_PATH ] )
#
# Composes the packet and delivers it to all other ESTABLISHED connections
#
sub forward {
	my ($self, $packet, $path) = @_;

	unless ($packet && ref $packet) {
		carp "Invalid argument to Net::Gnutella::Connection->forward";
	}

	my $data = $packet->format;
	my $head = pack("L4CCCL", @{ $packet->msgid }, $packet->function, $packet->ttl, $packet->hops, length $data);

	if ($path) {
		if ($path ne $self) {
			printf STDERR " - Returning down path to %s\n", $path->ip if $self->debug >= 2;

			$path->_write_wrapper($head.$data);
		}
	} else {
		foreach my $conn ($self->parent->connections) {
			next if $conn eq $self;
			next unless $conn->connected;

			printf STDERR " - Forwarding to %s\n", $conn->ip if $self->debug >= 2;

			$conn->_write_wrapper($head.$data);
		}
	}
}

sub is_outgoing    { $_[0]->connected == 1 } # Outgoing
sub is_incoming    { $_[0]->connected == 2 } # Incoming
sub is_established { $_[0]->connected == 3 } # Gnutella DATA Stream
sub is_http        { $_[0]->connected == 4 } # HTTP Serving
sub is_upload      { $_[0]->connected == 5 } # Sending file

sub new {
	my $proto = shift;
	my $parent = shift;
	my %args = @_;

	my $self = {
		_handler => {},
		_attr    => {
			parent    => $parent,
			debug     => $parent->debug,
			timeout   => $parent->timeout,
			socket    => undef,
			ip        => '',
			connected => 0,
			readbuf   => '',
			writebuf  => '',
			error     => '',
			allow     => 0,
			msgid     => [],
		},
		_msgid   => {},
	};

	bless $self, $proto;

	foreach my $key (keys %args) {
		my $lkey = lc $key;

		$self->$lkey($args{$key});
	}

	if ($self->connected and $self->socket) {
		$self->parent->_add_fh($self->socket, $self->can("_read_socket"), "r", $self);
	}

	return $self;
}

sub send_error {
	my ($self, $status, $error) = @_;

	unless ($self->is_http) {
		croak "Invalid state for ->send_error";
	}

	$status ||= RC_BAD_REQUEST;
	$error  ||= "";

	my $message = status_message($status);
	my $CRLF = "\r\n";

	my $ip = "Unknown";
	my $port = "Unknown";

	my $body = <<EOT;
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<HTML><HEAD>
<TITLE>$status $message</TITLE>
</HEAD><BODY>
<H1>$message</H1>
$error<BR><BR>
<ADDRESS><A HREF="http://gnutella.habitue.net">Net::Gnutella</A> $VERSION Server at $ip Port $port</ADDRESS>
</BODY></HTML>
EOT

	my $head;
	$head .= sprintf "%s %s %s%s", "HTTP/1.0", $status, $message, $CRLF;
	$head .= sprintf "Date: %s%s", time2str(time), $CRLF;
	$head .= sprintf "Server: %s/%s%s", "Net-Gnutella", $VERSION, $CRLF;
	$head .= sprintf "Content-Type: %s%s", "text/html", $CRLF;
	$head .= sprintf "Content-Length: %s%s", length($body), $CRLF;
	$head .= sprintf "%s", $CRLF;

	$self->_write_wrapper($head.$body);

	return;
}

sub send_file {
	my ($self, $file, $offset) = @_;

	unless ($self->is_http) {
		croak "Invalid state for ->send_file";
	}

	if (-f $file) {
		my ($ct, $ce) = guess_media_type($file);
		my ($size, $mtime) = (stat _)[7,9];

		my $fh = new IO::File $file or
			return $self->send_error(RC_FORBIDDEN);

		binmode($fh);

		if ($offset && $offset > $size) {
			$offset = 0;
		} elsif ($offset) {
			$fh->seek($offset, 0) or $offset = 0;
		}

		my $status = $offset ? RC_PARTIAL_CONTENT : RC_OK;
		my $message = status_message($status);
		my $CRLF = "\r\n";

		my $head;
		$head .= sprintf "%s %s %s%s", "HTTP/1.0", $status, $message, $CRLF;
		$head .= sprintf "Date: %s%s", time2str(time), $CRLF;
		$head .= sprintf "Server: %s/%s%s", "Net-Gnutella", $VERSION, $CRLF;
		$head .= sprintf "Content-Type: %s%s", $ct, $CRLF;
		$head .= sprintf "Content-Encoding: %s%s", $ce, $CRLF if $ce;
		$head .= sprintf "Content-Length: %d%s", $offset ? $size - $offset : $size, $CRLF if $size;
		$head .= sprintf "Content-Range: bytes %d-%d/%d%s", $offset, $size-1, $size, $CRLF if $offset;
		$head .= sprintf "Last-Modified: %s%s", time2str($mtime), $CRLF if $mtime;
		$head .= sprintf "%s", $CRLF;

		$self->_write_wrapper($head, $fh);
		$self->connected(5);
	} else {
		return $self->send_error(RC_NOT_FOUND);
	}

	return 1;
}

sub send_packet {
	my ($self, $packet) = @_;

	unless ($self->is_established) {
		croak "Invalid state for ->send_packet";
	}

	unless ($packet && ref $packet) {
		carp "Invalid argument to Net::Gnutella::Connection->send_packet";
	}

	printf STDERR "+ Sending packet '%s'\n", ref($packet) if $self->debug >= 2;

	my @msgid = @{ $packet->msgid };

	unless (scalar @msgid) {
		@msgid = $self->_new_msgid;
	}

	my $data = $packet->format;
	my $head = pack("L4CCCL", @msgid, $packet->function, $packet->ttl, $packet->hops, length $data);

	$self->parent->_msgid_source(\@msgid, $self);

	$self->_write_wrapper($head.$data);

	return \@msgid;
}

sub send_page {
	my ($self, $data) = @_;

	unless ($self->is_http) {
		croak "Invalid state in ->send_page";
	}

	my $status = RC_OK;
	my $message = status_message($status);
	my $CRLF = "\r\n";

	my $head;
	$head .= sprintf "%s %s %s%s", "HTTP/1.0", $status, $message, $CRLF;
	$head .= sprintf "Date: %s%s", time2str(time), $CRLF;
	$head .= sprintf "Server: %s/%s%s", "Net-Gnutella", $VERSION, $CRLF;
	$head .= sprintf "Content-Type: %s%s", "text/html", $CRLF;
	$head .= sprintf "Content-Length: %d%s", length($data), $CRLF;
	$head .= sprintf "%s", $CRLF;

	$self->_write_wrapper($head.$data);
}

sub _default {
	my $self = shift;
	my $event = shift;

	my $type = $event->type;
	my $packet = $event->packet;

	printf STDERR "%s->%s: Handling event '%s'\n", ref($self), "_default", $type if $self->debug;

	unless ($packet and ref($packet) =~ /^Net::Gnutella::Packet::/) {
		return 1;
	}

	if ($packet->hops > 7) {
		printf STDERR "+ Not forwarding, large hop count (%s)\n", $packet->hops if $self->debug;
		return 1;
	}

	if ($packet->ttl > 50) {
		printf STDERR "+ Not forwarding, large ttl (%s)\n", $packet->ttl if $self->debug;
		return 1;
	}

	if ($packet->ttl > 7) {
		$packet->ttl(7);
	}

	if ($packet->ttl <= 0) {
		printf STDERR "+ Not forwarding, ttl <= 0 (%s)\n", $packet->ttl if $self->debug;
		return 1;
	} else {
		$packet->ttl($packet->ttl - 1);
		$packet->hops($packet->hops + 1);
	}

	if ($type eq "pong") {
		$self->parent->_host_cache( join(":", $packet->ip_as_string, $packet->port) );
	}

	# Drop any routed replies which we haven't seen
	# Drop any duplicate packets
	#
	if ($type =~ /^(ping|query|push)$/) {
		if ($self->parent->_msgid_source($packet->msgid)) {
			return; # duplicate
		} else {
			$self->parent->_msgid_source($packet->msgid, $self);
		}
	} elsif ($type =~ /^(pong|reply)$/) {
		unless ($self->parent->_msgid_source($packet->msgid)) {
			printf STDERR "+ Not forwarding, unseen msgid to routed type (%s)\n", join(":", @{$packet->msgid}) if $self->debug;
			return;
		}
	}

	# If the packet is a routed reply (pong and reply) and it didn't originate
	# from this connection, forward it to the other connection.
	#
	# Otherwise, throw it at all the connections (broadcast).
	#
	if ($type =~ /^(pong|reply)$/) {
		my $conn = $self->parent->_msgid_source($packet->msgid);

		$self->forward($packet, $conn);
	} elsif ($type =~ /^(ping|push|query)$/) {
		$self->forward($packet);
	}

	return 1;
}

sub _new_msgid {
	my $self = shift;
	my $msgid = $self->msgid;

	if (scalar @$msgid) {
		$self->msgid([ $msgid->[0], $msgid->[1], $msgid->[2], ++$msgid->[3] ]);
	} else {
		$msgid = [ int rand(65536**2), int rand(65536**2), int rand(65536**2), int rand(65536**2) ];

		$self->msgid($msgid);
	}

	return wantarray ? @$msgid : $msgid;
}

sub _read_socket {
	my $self = shift;
	my $buf = $self->readbuf;

	local $SIG{PIPE} = 'IGNORE';

	if ($self->is_outgoing) {
		my $ret = $self->socket->sysread($buf, 13, length $buf);

		if ($ret == 0) {
			$self->disconnect;
			return;
		}

		$self->readbuf($buf);

		if ($buf eq "GNUTELLA OK\n\n") {
			$self->readbuf("");
			$self->connected(3); # ESTABLISHED

			my $event = Net::Gnutella::Event->new(
				from => $self,
				type => "connected",
			);

			$self->parent->_handler($event);

			return;
		}

		if (length $buf >= 13) {
			$self->error("Invalid response");
			$self->disconnect;
			return;
		}
	} elsif ($self->is_incoming) {
		my $ret = $self->socket->sysread($buf, 1, length $buf);

		if ($ret == 0) {
			$self->disconnect;
			return;
		}

		$self->readbuf($buf);

		if ($buf =~ /^\w+[^\012]+HTTP\/\d+\.\d+\015?\012/) {
			if ($buf =~ /\015?\012\015?\012/) {
				unless ($self->allow & 2) {
					$self->disconnect;
					return;
				}

				$self->readbuf("");
				$self->connected(4); # HTTP

				unless ($buf =~ s/^(\w+)[ \t]+(.+)[ \t]+(HTTP\/\d+\.\d+)[^\012]*\012//) {
					$self->send_error(400);  # BAD_REQUEST
					$self->error("Bad request line");
					return;
				}

				my $url = URI::URL->new($2);
				my $request = HTTP::Request->new($1, $url);

				my ($key, $val);

				HEADER: while ($buf =~ s/^([^\012]*)\012//) {
					$_ = $1;
					s/\015$//;

					if (/^([\w\-]+)\s*:\s*(.*)/) {
						$request->push_header($key, $val) if $key;
						($key, $val) = ($1, $2);
					} elsif (/^\s+(.*)/) {
						$val .= " $1";
					} else {
						last HEADER;
					}
				}

				$request->push_header($key, $val) if $key;

				my $event = Net::Gnutella::Event->new(
					from   => $self,
					type   => "download_req",
					packet => $request,
				);

				$self->parent->_handler($event);

				return;
			} elsif (length($buf) > 1*1024) {
				$self->disconnect;
				$self->error("Very long header");
				return;
			}
		} elsif ($buf =~ /^GNUTELLA CONNECT\/(\d+\.\d+)\015?\012\015?\012/) {
			if ($1 le "0.4") {
				unless ($self->allow & 1) {
					$self->disconnect;
					return;
				}

				$self->readbuf("");
				$self->connected(3); # ESTABLISHED

				$self->_write_wrapper("GNUTELLA OK\n\n");

				my $event = Net::Gnutella::Event->new(
					from => $self,
					type => "connected",
				);

				$self->parent->_handler($event);

				return;
			} else {
				$self->disconnect;
				return;
			}
		} elsif (length($buf) > 1*1024) {
			$self->disconnect;
			$self->error("Very long first line");
			return;
		}
	} elsif ($self->is_established) {
		my $ret = $self->socket->sysread($buf, 256, length $buf);

		if ($ret == 0) {
			$self->disconnect("disconnect");
			return;
		}

		$self->readbuf($buf);

		printf STDERR " - Read %d bytes, buffer has %d bytes\n", $ret, length $buf if $self->debug;

		PROCESS: {
			if (length $buf < 23) {
				last PROCESS;
			}

			my @msgid = unpack("L4", substr($buf, 0, 16));
			my $func  = unpack("C",  substr($buf, 16, 1));
			my $ttl   = unpack("C",  substr($buf, 17, 1));
			my $hops  = unpack("C",  substr($buf, 18, 1));
			my $len   = unpack("L",  substr($buf, 19, 4));

			if (length($buf) < 23+$len) {
				last PROCESS;
			}

			my $head = substr($buf, 0, 23, '');
			my $data = substr($buf, 0, $len, '');

			printf STDERR " - Full packet read, %d bytes left\n", length $buf if $self->debug;

			my $class;

			if ($func == 0) {
				goto PROCESS if $len != 0;
				$class = "Net::Gnutella::Packet::Ping";
			} elsif ($func == 1) {
				goto PROCESS if $len != 14;
				$class = "Net::Gnutella::Packet::Pong";
			} elsif ($func == 64) {
				goto PROCESS if $len != 26;
				$class = "Net::Gnutella::Packet::Push";
			} elsif ($func == 128) {
				goto PROCESS if $len >= 257;
				$class = "Net::Gnutella::Packet::Query";
			} elsif ($func == 129) {
				goto PROCESS if $len >= 67_075;
				$class = "Net::Gnutella::Packet::Reply";
			} else {
				goto PROCESS;
			}

			my $packet = $class->new(
				Msgid    => \@msgid,
				Function => $func,
				TTL      => $ttl,
				Hops     => $hops,
				Parse    => $data,
			);

			my $event = Net::Gnutella::Event->new(
				from   => $self,
				type   => $func,
				packet => $packet,
			);

			$self->parent->_handler($event);

			goto PROCESS;
		}

		printf STDERR " - buffer has %d bytes\n\n", length $buf if $self->debug;

		$self->readbuf($buf);
	} else {
		my $ret = $self->socket->sysread($buf, 16*1024, length($buf));

		if ($self->is_upload) {
			$self->disconnect("upload_error");
		} else {
			$self->disconnect;
		}
	}

	return;
}

sub _write_socket {
	my ($self, $sock, $fh) = @_;
	my $buf = $self->writebuf;

	local $SIG{PIPE} = 'IGNORE';

printf STDERR " - Writing to FH, bytes in buffer: %s\n", length($buf) if $self->debug;

	if (length($buf) == 0) {
		return;
	}

	my $len = $self->socket->syswrite($buf, length $buf);

	if ($len == 0) {
		$self->disconnect;
		return;
	}

	substr($buf, 0, $len, '');

printf STDERR " - Wrote %d bytes, %d bytes left\n", $len, length($buf) if $self->debug;

	if ($self->is_upload and defined $fh) {
printf "Buf length %d, pos %d\n", length $buf, tell($fh);
		my $read = sysread($fh, $buf, (16*1024)-length($buf), length($buf));
printf "Reading [%s] [%d] [%d]\n", $fh, $read, tell($fh);
	}

	$self->writebuf($buf);

	if (length($buf)) {
		return;
	}

	$self->parent->_remove_fh($self->socket, "w");

	if ($self->is_upload and $fh and ref($fh) eq "IO::File") {
		$self->disconnect("download_complete");
	} elsif ($self->is_http) {
		$self->disconnect;
	}
}

sub _write_wrapper {
	my ($self, $data, @args) = @_;
	my $buf = $self->writebuf;

	$self->writebuf($buf.$data);
	$self->parent->_add_fh($self->socket, $self->can("_write_socket"), "w", $self, @args);
}

1;
