package Net::UPnP::HTTP;

#-----------------------------------------------------------------
# Net::UPnP::HTTP
#-----------------------------------------------------------------

use strict;
use warnings;

use Socket;
use IO::Select;
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use Errno qw(EINPROGRESS EWOULDBLOCK EAGAIN EINTR);
use POSIX qw(_exit isfinite);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);
use Carp qw(croak);

use Net::UPnP;
use Net::UPnP::HTTPResponse;

use vars qw($STATUS_CODE $STATUS $HEADER $CONTENT $POST $GET);

$POST = 'POST';
$GET = 'GET';

$STATUS_CODE = 'status_code';
$STATUS = 'status';
$HEADER = 'header';
$CONTENT = 'content';

#------------------------------
# new
#------------------------------

sub new {
	my($class) = shift;
	my($this) = { timeout => 10, max_header_bytes => 65536,
		max_line_bytes => 8192, max_body_bytes => 16 * 1024 * 1024, @_ };
	foreach my $key (qw(timeout max_header_bytes max_line_bytes max_body_bytes)) {
		croak "Invalid HTTP $key" unless defined($this->{$key})
			&& $this->{$key} =~ ($key eq 'timeout' ? qr/\A\d+(?:\.\d+)?\z/ : qr/\A\d+\z/)
			&& isfinite(0 + $this->{$key}) && $this->{$key} > 0;
	}
	if (exists $this->{deadline}) {
		croak 'Invalid HTTP deadline' unless defined($this->{deadline})
			&& $this->{deadline} =~ /\A\d+(?:\.\d+)?\z/ && isfinite(0 + $this->{deadline});
	}
	$this->{allowed_addresses} = _address_list($this->{allowed_addresses})
		if exists $this->{allowed_addresses};
	bless $this, $class;
}

# Only caller-supplied numeric IPv4 addresses may expand a discovery policy.
sub _address_list {
	my ($addresses) = @_;
	croak 'Invalid allowed_addresses' unless ref($addresses) eq 'ARRAY';
	my @copy;
	foreach my $address (@$addresses) {
		croak 'Invalid allowed IPv4 address' unless defined($address)
			&& $address =~ /\A(?:\d{1,3}\.){3}\d{1,3}\z/;
		my @octets = split(/\./, $address);
		croak 'Invalid allowed IPv4 address' if grep { $_ > 255 } @octets;
		push @copy, inet_ntoa(pack('C4', @octets));
	}
	return \@copy;
}

sub _now { clock_gettime(CLOCK_MONOTONIC) }

sub geterror { $_[0]->{error} || '' }

sub _wait {
	my ($fh, $write, $deadline) = @_;
	my $select = IO::Select->new($fh);
	while (1) {
		my $remaining = $deadline - _now();
		die "HTTP deadline exceeded\n" if $remaining <= 0;
		$! = 0;
		my @ready = $write ? $select->can_write($remaining) : $select->can_read($remaining);
		next if !@ready && $! == EINTR;
		die "HTTP deadline exceeded\n" unless @ready && _now() < $deadline;
		return;
	}
}

# Resolve in a child so a blocking system resolver cannot outlive the request.
# The pipe carries exactly four address bytes, never executable input.
sub _resolve {
	my ($host, $deadline) = @_;
	if ($host =~ /\A(?:\d{1,3}\.){3}\d{1,3}\z/) {
		my @octets = split(/\./, $host);
		die "Invalid IPv4 address\n" if grep { $_ > 255 } @octets;
		return pack('C4', @octets);
	}
	pipe(my $reader, my $writer) or die "Resolver pipe failed: $!\n";
	my $pid = fork();
	unless (defined $pid) {
		close($reader); close($writer);
		die "Resolver fork failed: $!\n";
	}
	if (!$pid) {
		close($reader);
		my $address = inet_aton($host);
		syswrite($writer, $address) if defined $address;
		close($writer);
		_exit(0);
	}
	close($writer);
	my $address = '';
	my $ok = eval {
		_wait($reader, 0, $deadline);
		my $n = sysread($reader, $address, 4);
		die "Host resolution failed\n" unless defined($n) && $n == 4;
		1;
	};
	my $error = $@;
	close($reader);
	# The child is still ours until waitpid; terminate before reaping so even
	# a resolver stuck after writing cannot extend the transaction deadline.
	kill 'KILL', $pid;
	waitpid($pid, 0);
	die $error unless $ok;
	return $address;
}

sub _fill {
	my ($state, $deadline, $limit) = @_;
	while (1) {
		_wait($state->{socket}, 0, $deadline);
		my $data = '';
		my $size = $limit < 16384 ? $limit : 16384;
		my $n = sysread($state->{socket}, $data, $size);
		next if !defined($n) && ($! == EINTR || $! == EAGAIN || $! == EWOULDBLOCK);
		die "HTTP read failed: $!\n" unless defined $n;
		$state->{buffer} .= $data;
		return $n;
	}
}

sub _line {
	my ($state, $deadline, $limit) = @_;
	while (1) {
		my $end = index($state->{buffer}, "\n");
		if ($end >= 0) {
			die "HTTP line limit exceeded\n" if $end + 1 > $limit;
			return substr($state->{buffer}, 0, $end + 1, '');
		}
		die "HTTP line limit exceeded\n" if length($state->{buffer}) >= $limit;
		die "Incomplete HTTP line\n"
			unless _fill($state, $deadline, $limit - length($state->{buffer}));
	}
}

sub _exact {
	my ($state, $deadline, $length) = @_;
	my $data = '';
	while (length($data) < $length) {
		my $needed = $length - length($data);
		if (length($state->{buffer})) {
			$data .= substr($state->{buffer}, 0, $needed, '');
			next;
		}
		die "Incomplete HTTP body\n" unless _fill($state, $deadline, $needed);
	}
	return $data;
}

sub _exchange {
	my ($this, $state, $deadline, $address, $port, $request) = @_;
	my $resolved = _resolve($address, $deadline);
	if (exists $this->{allowed_addresses}) {
		my $actual = inet_ntoa($resolved);
		die "HTTP destination not permitted\n"
			unless grep { $_ eq $actual } @{$this->{allowed_addresses}};
	}
	socket(my $socket, PF_INET, SOCK_STREAM, getprotobyname('tcp'))
		or die "HTTP socket failed: $!\n";
	$state->{socket} = $socket;
	my $flags = fcntl($socket, F_GETFL, 0);
	die "HTTP nonblocking setup failed: $!\n"
		unless defined($flags) && defined(fcntl($socket, F_SETFL, $flags | O_NONBLOCK));
	unless (connect($socket, sockaddr_in($port, $resolved))) {
		die "HTTP connect failed: $!\n"
			unless $! == EINPROGRESS || $! == EWOULDBLOCK || $! == EINTR;
		_wait($socket, 1, $deadline);
		my $error = getsockopt($socket, SOL_SOCKET, SO_ERROR);
		die "HTTP connect failed\n" unless defined($error) && unpack('i', $error) == 0;
	}
	my $offset = 0;
	while ($offset < length($request)) {
		_wait($socket, 1, $deadline);
		my $n = syswrite($socket, $request, length($request) - $offset, $offset);
		next if !defined($n) && ($! == EINTR || $! == EAGAIN || $! == EWOULDBLOCK);
		die "HTTP write failed: $!\n" unless defined($n) && $n > 0;
		$offset += $n;
	}
	my $header_bytes = 0;
	my $next_header = sub {
		my $remaining = $this->{max_header_bytes} - $header_bytes;
		die "HTTP header limit exceeded\n" if $remaining <= 0;
		my $limit = $remaining < $this->{max_line_bytes} ? $remaining : $this->{max_line_bytes};
		my $line = _line($state, $deadline, $limit);
		$header_bytes += length($line);
		return $line;
	};
	my $status = $next_header->();
	die "Invalid HTTP status\n" unless $status =~ /\AHTTP\/\d+\.\d+\s+(\d{3})\b/;
	my $status_code = $1;
	my ($headers, $length, $encoding) = ('', undef, '');
	while (1) {
		my $line = $next_header->();
		last if $line =~ /\A\r?\n\z/;
		$headers .= $line;
		if ($line =~ /\AContent-Length\s*:\s*(.*?)\s*\r?\n\z/i) {
			my $value = $1;
			die "Invalid HTTP content length\n" unless $value =~ /\A\d+\z/;
			die "HTTP body limit exceeded\n" if $value > $this->{max_body_bytes};
			die "Conflicting HTTP content lengths\n" if defined($length) && $length != $value;
			$length = 0 + $value;
		}
		if ($line =~ /\ATransfer-Encoding\s*:\s*(.*?)\s*\r?\n\z/i) {
			die "Unsupported HTTP transfer encoding\n" if length($encoding) || lc($1) ne 'chunked';
			$encoding = lc($1);
		}
	}
	die "Ambiguous HTTP framing\n" if length($encoding) && defined($length);
	my $body = '';
	if (_bodyless($status_code, $request)) {
		# HEAD and status codes without message bodies complete at the headers.
	}
	elsif ($encoding eq 'chunked') {
		while (1) {
			my $line = _line($state, $deadline, $this->{max_line_bytes});
			die "Invalid HTTP chunk size\n" unless $line =~ /\A([0-9a-f]+)(?:;[^\r\n]*)?\r?\n\z/i;
			my $digits = $1;
			$digits =~ s/\A0+//;
			# Bound the conversion before hex(), as well as the decoded total.
			die "HTTP body limit exceeded\n" if length($digits) > length(sprintf('%x', $this->{max_body_bytes}));
			my $chunk = length($digits) ? hex($digits) : 0;
			die "HTTP body limit exceeded\n" if $chunk > $this->{max_body_bytes} - length($body);
			if (!$chunk) {
				while (1) {
					my $trailer = $next_header->();
					last if $trailer =~ /\A\r?\n\z/;
				}
				last;
			}
			$body .= _exact($state, $deadline, $chunk);
			die "Invalid HTTP chunk terminator\n" unless _exact($state, $deadline, 2) eq "\r\n";
		}
	}
	elsif (defined $length) {
		$body = _exact($state, $deadline, $length);
	}
	else {
		while (1) {
			die "HTTP body limit exceeded\n" if length($body) + length($state->{buffer}) > $this->{max_body_bytes};
			$body .= $state->{buffer};
			$state->{buffer} = '';
			last unless _fill($state, $deadline, $this->{max_body_bytes} - length($body) + 1);
		}
	}
	my $res = Net::UPnP::HTTPResponse->new();
	$res->setstatus($status); $res->setheader($headers); $res->setcontent($body);
	return $res;
}

sub _bodyless {
	my ($status, $request) = @_;
	return $request =~ /\AHEAD / || $status == 204 || $status == 304;
}

#------------------------------
# post
#------------------------------

sub post {
	my($this) = shift;
	if (@_ <  6) {
		return "";
	}
	my ($post_addr, $post_port, $method, $path, $add_header, $req_content) = @_;
	my (
		$post_sockaddr,
		$req_content_len,
		$add_header_name,
		$add_header_value,
		$req_header,
		$res_status,
		$res_header_cnt,
		$res_header,
		$res_content_len,
		$res_content,
		$res,
		);

	# Thanks for miz <miz999 at gmail.com> (2009/02/13)
	$req_content =~ s/\r//g;
	$req_content =~ s/\n/\r\n/g;
	
	$req_content_len = length($req_content);
	
$req_header = <<"REQUEST_HEADER";
$method $path HTTP/1.0
Host: $post_addr:$post_port
Content-Length: $req_content_len
REQUEST_HEADER

	#print "header = " . %{$add_header} . "\n";
	#%add_header = %{$add_header_ref};
        my $has_connection_header;
	if (ref $add_header) {
                $has_connection_header = 1 if( defined ${$add_header}{'Connection'} );
		while ( ($add_header_name, $add_header_value) =  each %{$add_header}) {
			$req_header .= "$add_header_name: $add_header_value\n";
		}
	}

	$req_header .= "Connection: close\n" unless( $has_connection_header );
	$req_header .= "\n";
	$req_header =~ s/\r//g;
	$req_header =~ s/\n/\r\n/g;

	$this->{error} = '';
	my $deadline = _now() + $this->{timeout};
	$deadline = $this->{deadline} if defined($this->{deadline}) && $this->{deadline} < $deadline;
	my $state = { buffer => '' };
	local $SIG{PIPE} = 'IGNORE';
	my $ok = eval {
		die "Invalid HTTP port\n" unless defined($post_port) && $post_port =~ /\A\d+\z/
			&& $post_port > 0 && $post_port <= 65535;
		$res = $this->_exchange($state, $deadline, $post_addr, $post_port, $req_header . $req_content);
		1;
	};
	my $error = $@;
	close($state->{socket}) if $state->{socket};
	unless ($ok) {
		$this->{error} = $error || 'HTTP request failed';
		print $this->{error} if $Net::UPnP::DEBUG;
		return '';
	}
	return $res;
}

#------------------------------
# postsoap
#------------------------------

sub postsoap {
	my($this) = shift;
	my ($post_addr, $post_port, $path, $action_name, $action_content) = @_;
	my (
		%soap_header,
		$name,
		$value
	);
	
	%soap_header = (
		'Content-Type' => "text/xml; charset=\"utf-8\"",
		'SOAPACTION' => $action_name,
	);
	
	$this->post($post_addr, $post_port, $Net::UPnP::HTTP::POST, $path, \%soap_header, $action_content);
}

#------------------------------
# xmldecode
#------------------------------

sub xmldecode {
	my (
		$str
	);
	if (ref $_[0]) {
		$str = $_[1];
	}
	else {
		$str = $_[0];
	}
	$str =~ s/\&gt;/>/g;
	$str =~ s/\&lt;/</g;
	$str =~ s/\&quot;/\"/g;
	$str =~ s/\&amp;/\&/g;
	$str;
}

1;

__END__

=head1 NAME

Net::UPnP::HTTP - Perl extension for UPnP.

=head1 DESCRIPTION

The package is a inside module.

=head1 AUTHOR

Satoshi Konno
skonno@cybergarage.org

CyberGarage
http://www.cybergarage.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Satoshi Konno

It may be used, redistributed, and/or modified under the terms of BSD License.

=cut
