package Net::Proxy::Type;

use strict;
use Exporter;
use Errno qw(EWOULDBLOCK EAGAIN);
use Carp;
use IO::Socket::INET qw(:DEFAULT :crlf);
use IO::Select;

use constant {
	UNKNOWN_PROXY => 4294967296,
	DEAD_PROXY    => 0,
	HTTP_PROXY    => 1,
	SOCKS4_PROXY  => 2,
	SOCKS5_PROXY  => 4,
	HTTPS_PROXY   => 8,
	CONNECT_PROXY => 16,
};

our $VERSION = '0.09';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(HTTP_PROXY HTTPS_PROXY CONNECT_PROXY SOCKS4_PROXY SOCKS5_PROXY UNKNOWN_PROXY DEAD_PROXY);
our %EXPORT_TAGS = (types => [qw(HTTP_PROXY HTTPS_PROXY CONNECT_PROXY SOCKS4_PROXY SOCKS5_PROXY UNKNOWN_PROXY DEAD_PROXY)]);

our $CONNECT_TIMEOUT = 5;
our $WRITE_TIMEOUT = 5;
our $READ_TIMEOUT = 5;
our $URL = 'http://www.google.com/';
our $HTTPS_URL = 'https://www.google.com/';
our $KEYWORD = 'google';
our $HTTPS_KEYWORD = 'google';
our $HTTP_VER = '1.1';
our %NAME = (
	UNKNOWN_PROXY, 'UNKNOWN_PROXY',
	DEAD_PROXY, 'DEAD_PROXY',
	HTTP_PROXY, 'HTTP_PROXY',
	HTTPS_PROXY, 'HTTPS_PROXY',
	CONNECT_PROXY, 'CONNECT_PROXY',
	SOCKS4_PROXY, 'SOCKS4_PROXY',
	SOCKS5_PROXY, 'SOCKS5_PROXY',
);

sub new
{
	my ($class, %opts) = @_;
	my $self = bless {}, $class;
	
	$self->{connect_timeout} = $opts{connect_timeout} || $opts{timeout} || $CONNECT_TIMEOUT;
	$self->{write_timeout} = $opts{write_timeout} || $opts{timeout} || $WRITE_TIMEOUT;
	$self->{read_timeout} = $opts{read_timeout} || $opts{timeout} || $READ_TIMEOUT;
	$self->{http_strict} = $opts{http_strict} || $opts{strict};
	$self->{https_strict} = $opts{https_strict} || $opts{strict};
	$self->{connect_strict} = $opts{connect_strict} || $opts{strict};
	$self->{socks4_strict} = $opts{socks4_strict} || $opts{strict};
	$self->{socks5_strict} = $opts{socks5_strict} || $opts{strict};
	$self->{http_ver} = $opts{http_ver} || $HTTP_VER;
	$self->{keyword} = $opts{keyword} || $KEYWORD;
	$self->{https_keyword} = $opts{https_keyword} || $HTTPS_KEYWORD;
	$self->{noauth} = $opts{noauth};
	$self->url($opts{url} || $URL);
	$self->https_url($opts{https_url} || $HTTPS_URL);
	
	$self;
}

foreach my $key (qw(
	connect_timeout write_timeout read_timeout http_strict https_strict 
	connect_strict socks4_strict socks5_strict keyword https_keyword noauth http_ver
))
{ # generate sub's for get/set object properties using closure
	no strict 'refs';
	*$key = sub
	{
		my $self = shift;
		
		return $self->{$key} = $_[0] if defined $_[0];
		return $self->{$key};
	}
}

sub timeout
{ # set timeout for all operations
	my ($self, $timeout) = @_;
	
	$self->{connect_timeout} = $timeout;
	$self->{write_timeout} = $timeout;
	$self->{read_timeout} = $timeout;
}

sub strict
{ # set strict mode for all proxy types
	my ($self, $strict) = @_;
	
	$self->{http_strict} = $strict;
	$self->{https_strict} = $strict;
	$self->{connect_strict} = $strict;
	$self->{socks4_strict} = $strict;
	$self->{socks5_strict} = $strict;
}

sub url
{ # set or get url
	my $self = shift;
	
	if(defined($_[0])) {
		($self->{host}) = $_[0] =~ m!^http://([^:/]+)!
			or croak('Incorrect url specified. Should be http://[^:/]+');
		return $self->{url} = $_[0];
	}
	
	return $self->{url};
}

sub https_url
{ # set or get https url
	my $self = shift;
	
	if(defined($_[0])) {
		($self->{https_host}, $self->{https_pathquery}) = $_[0] =~ m!^https://([^:/]+)(/.*)?!
			or croak('Incorrect url specified. Should be https://[^:/]+(/.*)?');
		return $self->{https_url} = $_[0];
	}
	
	return $self->{https_url};
}

my @checkers = (
	CONNECT_PROXY, \&is_connect,
	HTTPS_PROXY, \&is_https,
	HTTP_PROXY, \&is_http,
	SOCKS4_PROXY, \&is_socks4,
	SOCKS5_PROXY, \&is_socks5
);

sub _get
{ # base get method
	my $self = shift;
	my $max  = pop;
	my ($proxyaddr, $proxyport, $checkmask);
	my @found;
	
	if (@_ == 3) {
		($proxyaddr, $proxyport, $checkmask) = @_;
	}
	elsif (($proxyaddr, $proxyport) = _parse_proxyaddr($_[0])) {
		$checkmask = $_[1];
	}
	elsif (@_ == 2) {
		($proxyaddr, $proxyport) = @_;
	}
	else {
		push @found, [DEAD_PROXY, 0];
		return \@found;
	}
	
	my ($ok, $con_time);
	for(my $i=0; $i<@checkers; $i+=2) {
		if(defined($checkmask)) {
			unless($checkers[$i] & $checkmask) {
				next;
			}
		}
		
		($ok, $con_time) = $checkers[$i+1]->($self, $proxyaddr, $proxyport);
		
		if($ok) {
			push @found, [$checkers[$i], $con_time];
			last if @found == $max;
		}
		elsif(!defined($ok)) {
			push @found, [DEAD_PROXY, 0];
			last;
		}
	}
	
	unless (@found) {
		push @found, [UNKNOWN_PROXY, $con_time];
	}
	
	return \@found;
}

sub get
{ # get proxy type
	my $self = shift;
	
	my $found = $self->_get(@_, 1);
	return wantarray ? @{$found->[0]} : $found->[0][0];
}

sub get_as_string
{ # same as get(), but return string
	my ($self, $proxyaddr, $proxyport, $checkmask) = @_;
	
	my $type = $self->get($proxyaddr, $proxyport, $checkmask);
	return $NAME{$type};
}

sub get_all
{ # get all proxy types
	my $self = shift;
	
	my $found = $self->_get(@_, 0);
	
	my $types = 0;
	my $con_time = 0;
	
	for my $t (@$found) {
		$types |= $t->[0];
		if ($t->[1] > $con_time) {
			$con_time = $t->[1];
		}
	}
	
	return wantarray ? ($types, $con_time) : $types;
}

sub get_all_as_string
{ # same as get_all(), but return string array
	my $self = shift;
	
	my @names = map { $NAME{$_->[0]} } @{$self->_get(@_, 0)};
	return @names;
}

sub is_http
{ # check is this http proxy
	my ($self, $proxyaddr, $proxyport) = @_;
	
	my ($socket, $con_time) = $self->_create_socket($proxyaddr, $proxyport)
		or return;
	
	# simply do http request
	unless($self->_http_request($socket)) {
		goto IS_HTTP_ERROR;
	}
	
	my ($buf, $rc);
	unless($self->{http_strict}) {
		# simple check. does response begins from `HTTP'?
		$rc = $self->_read_from_socket($socket, $buf, 12);
		my ($code) = $buf =~ /(\d+$)/;
		if ($code == 407 && $self->{noauth}) {
			# proxy auth required
			goto IS_HTTP_ERROR;
		}
		
		if(!$rc || substr($buf, 0, 4) ne 'HTTP') {
			goto IS_HTTP_ERROR;
		}
	}
	else {
		# strict check. does response header contains keyword?
		unless($self->_is_strict_response($socket, $self->{keyword})) {
			goto IS_HTTP_ERROR;
		}
	}
	
	$socket->close();
	return wantarray ? (1, $con_time) : 1;
	
	IS_HTTP_ERROR:
		$socket->close();
		return wantarray ? (0, $con_time) : 0;
}

sub is_connect
{ # check is this conenct proxy
	my ($self, $proxyaddr, $proxyport) = @_;
	
	my ($socket, $con_time) = $self->_create_socket($proxyaddr, $proxyport)
		or return;
	
	$self->_write_to_socket(
		$socket,
		'CONNECT '.$self->{host}.':80 HTTP/1.1'.CRLF.'Host: '.$self->{host}.':80'.CRLF.CRLF
	) or goto IS_CONNECT_ERROR;
	
	$self->_read_from_socket($socket, my $headers, CRLF.CRLF, 2000)
		or goto IS_CONNECT_ERROR;
	my ($code) = $headers =~ m!^HTTP/\d.\d (\d{3})!
		or goto IS_CONNECT_ERROR;
	if ($code == 407 && ($self->{noauth} || $self->{connect_strict})) {
		goto IS_CONNECT_ERROR;
	}
	if (($code < 200 || $code >= 300) && $code != 407) {
		goto IS_CONNECT_ERROR;
	}
	if ($self->{connect_strict}) {
		unless($self->_http_request($socket)) {
			goto IS_CONNECT_ERROR;
		}
		
		unless($self->_is_strict_response($socket, $self->{keyword})) {
			goto IS_CONNECT_ERROR;
		}
	}
	
	$socket->close();
	return wantarray ? (1, $con_time) : 1;
	
	IS_CONNECT_ERROR:
		$socket->close();
		return wantarray() ? (0, $con_time) : 0;
}

sub is_https
{ # check is this https proxy
	my ($self, $proxyaddr, $proxyport) = @_;
	
	my ($socket, $con_time) = $self->_create_socket($proxyaddr, $proxyport)
		or return;
	
	$self->_write_to_socket(
		$socket, 'CONNECT '.$self->{https_host}.':443 HTTP/1.1'.CRLF.'Host: '.$self->{https_host}.':443'.CRLF.CRLF
	) or goto IS_HTTPS_ERROR;
	
	$self->_read_from_socket($socket, my $headers, CRLF.CRLF, 2000)
		or goto IS_HTTPS_ERROR;
	my ($code) = $headers =~ m!^HTTP/\d.\d (\d{3})!
		or goto IS_HTTPS_ERROR;
	if ($code == 407 && ($self->{noauth} || $self->{https_strict})) {
		goto IS_HTTPS_ERROR;
	}
	if (($code < 200 || $code >= 300) && $code != 407) {
		goto IS_HTTPS_ERROR;
	}
	
	if ($self->{https_strict}) {
		require IO::Socket::SSL;
		$socket->blocking(1);
		
		unless (IO::Socket::SSL->start_SSL($socket, Timeout => $self->{read_timeout})) {
			goto IS_HTTPS_ERROR;
		}
		
		$socket->blocking(0);
		$self->_write_to_socket(
			$socket, 
			'GET ' . ($self->{https_pathquery}||'/') . ' HTTP/' . $self->{http_ver} . CRLF . 'Host: ' . $self->{https_host} .
			CRLF . 'User-Agent: Mozilla/5.0'. CRLF . CRLF
		) or goto IS_HTTPS_ERROR;
		
		unless ($self->_is_strict_response($socket, $self->{https_keyword})) {
			goto IS_HTTPS_ERROR;
		}
	}
	
	$socket->close();
	return wantarray ? (1, $con_time) : 1;
	
	IS_HTTPS_ERROR:
		$socket->close();
		return wantarray ? (0, $con_time) : 0;
}

sub is_socks4
{ # check is this socks4 proxy
  # http://ftp.icm.edu.pl/packages/socks/socks4/SOCKS4.protocol
	my ($self, $proxyaddr, $proxyport) = @_;
	
	my ($socket, $con_time) = $self->_create_socket($proxyaddr, $proxyport)
		or return;
		
	unless($self->_write_to_socket($socket, "\x04\x01" . pack('n', 80) . inet_aton($self->{host}) . "\x00")) {
		goto IS_SOCKS4_ERROR;
	}
	
	my ($buf, $rc);
	$rc = $self->_read_from_socket($socket, $buf, 8);
	if(!$rc || substr($buf, 0, 1) ne "\x00" || substr($buf, 1, 1) ne "\x5a") {
		goto IS_SOCKS4_ERROR;
	}
	
	if($self->{socks4_strict}) {
		unless($self->_http_request($socket)) {
			goto IS_SOCKS4_ERROR;
		}
		
		unless($self->_is_strict_response($socket, $self->{keyword})) {
			goto IS_SOCKS4_ERROR;
		}
	}
	
	$socket->close();
	return wantarray ? (1, $con_time) : 1;
	
	IS_SOCKS4_ERROR:
		$socket->close();
		return wantarray ? (0, $con_time) : 0;
}

sub is_socks5
{ # check is this socks5 proxy
  # http://tools.ietf.org/search/rfc1928
	my ($self, $proxyaddr, $proxyport) = @_;
	
	my ($socket, $con_time) = $self->_create_socket($proxyaddr, $proxyport)
		or return;
	
	unless($self->_write_to_socket($socket, "\x05\x01\x00")) {
		goto IS_SOCKS5_ERROR;
	}
	
	my ($buf, $rc);
	$rc = $self->_read_from_socket($socket, $buf, 2);
	unless($rc) {
		goto IS_SOCKS5_ERROR;
	}
	
	my $c = substr($buf, 1, 1);
	if($c eq "\x01" || $c eq "\x02" || $c eq "\xff") {
		# this is socks5 proxy with authentification
		if($self->{noauth} || $self->{socks5_strict}) {
			goto IS_SOCKS5_ERROR;
		}
	}
	else {
		if($c ne "\x00") {
			goto IS_SOCKS5_ERROR;
		}
		
		unless($self->_write_to_socket($socket, "\x05\x01\x00\x01" . inet_aton($self->{host}) . pack('n', 80))) {
			goto IS_SOCKS5_ERROR;
		}
		
		# minimum length of response is 10
		# it is not necessarily to read whole response
		$rc = $self->_read_from_socket($socket, $buf, 10);
		if(!$rc || substr($buf, 1, 1) ne "\x00") {
			goto IS_SOCKS5_ERROR;
		}
		
		if($self->{socks5_strict}) {
			unless($self->_http_request($socket)) {
				goto IS_SOCKS5_ERROR;
			}
		
			unless($self->_is_strict_response($socket, $self->{keyword})) {
				goto IS_SOCKS5_ERROR;
			}
		}
	}
	
	$socket->close();
	return wantarray ? (1, $con_time) : 1;
	
	IS_SOCKS5_ERROR:
		$socket->close();
		return wantarray ? (0, $con_time) : 0;
}

sub _http_request
{ # do http request for some host
	my ($self, $socket) = @_;
	$self->_write_to_socket(
		$socket, 'GET ' . $self->{url} . ' HTTP/' . $self->{http_ver} . CRLF . 'Host: ' . $self->{host} . 
		CRLF . 'User-Agent: Mozilla/5.0' . CRLF . CRLF
	);
}

sub _is_strict_response
{ # to make sure about proxy type we will read response header and try to find keyword
  # without this check most of http servers may be recognized as http proxy, because its response after _http_request() begins from `HTTP'
	my ($self, $socket, $keyword) = @_;
	
	$self->_read_from_socket($socket, my $headers, CRLF.CRLF, 4096)
		or return 0;
	my ($code) = $headers =~ m!HTTP/\d\.\d (\d{3})!
		or return 0;
	if ((caller(1))[3] eq __PACKAGE__.'::is_http' && $code == 407 && $self->{noauth}) {
		return 0;
	}
	
	return index($headers, $keyword) != -1;
}

sub _write_to_socket
{ # write data to non-blocking socket; return 1 on success, 0 on failure (timeout or other error)
	my ($self, $socket, $msg) = @_;
	
	local $SIG{PIPE} = 'IGNORE';
	
	my $selector = IO::Select->new($socket);
	my $start = time();
	while(time() - $start < $self->{write_timeout}) {
		unless($selector->can_write(1)) {
			# socket couldn't accept data for now, check if timeout expired and try again
			next;
		}
		
		my $rc = $socket->syswrite($msg);
		if($rc > 0) {
			# reduce our message
			substr($msg, 0, $rc) = '';
			if(length($msg) == 0) {
				# all data successfully writed
				return 1;
			}
		}
		elsif($! != EWOULDBLOCK && $! != EAGAIN) {
			# some error in the socket; will return false
			last;
		}
	}
	
	return 0;
}

sub _read_from_socket
{ # read $limit bytes from non-blocking socket; return 0 if EOF, undef if error, bytes readed on success ($limit)
	my ($self, $socket) = (shift, shift);
	my $num_limit;
	my $str_limit;
	if (@_ == 2) {
		$num_limit = pop;
	}
	else {
		($str_limit, $num_limit) = @_[1,2];
	}
	
	my $limit_idx;
	my $selector = IO::Select->new($socket);
	my $start = time();
	$_[0] = ''; # clean buffer variable like sysread() do
	
	while(time() - $start < $self->{read_timeout}) {
		unless($selector->can_read(1)) {
			# no data in socket for now, check is timeout expired and try again
			next;
		}
		
		my $rc = $socket->sysread($_[0], $num_limit, length $_[0]);
		if(defined($rc)) {
			# no errors
			if($rc > 0) {
				$num_limit -= $rc;
				
				if ((defined $str_limit && ($limit_idx = index($_[0], $str_limit)) != -1) || $num_limit == 0) {
					if (defined $limit_idx && $limit_idx >= 0) {
						# cut off all after $str_limit
						substr($_[0], $limit_idx+length($str_limit)) = '';
					}
					return length($_[0]);
				}
			}
			else {
				# EOF in the socket
				return 0;
			}
		}
		elsif($! != EWOULDBLOCK && $! != EAGAIN) {
			last;
		}
	}
	
	return undef;
}

sub _create_socket
{ # trying to create non-blocking socket by proxy address; return valid socket on success, 0 or undef on failure
	my ($self, $proxyaddr, $proxyport) = @_;
	
	unless(defined($proxyport)) {
		($proxyaddr, $proxyport) = _parse_proxyaddr($proxyaddr)
			or return 0;
	}
	
	my $conn_start = time();
	my $socket = $self->_open_socket($proxyaddr, $proxyport)
		or return;
	
	return ($socket, time() - $conn_start);
}

sub _open_socket
{ # blocking open for non-blocking socket
	my ($self, $host, $port) = @_;
	my $socket = IO::Socket::INET->new(PeerHost => $host, PeerPort => $port, Timeout => $self->{connect_timeout}, Blocking => 0);
	
	return $socket;
}

sub _parse_proxyaddr
{ # parse proxy address like this one: localhost:8080 -> host=localhost, port=8080
	my ($proxyaddr) = @_;
	my ($host, $port) = $proxyaddr =~ /^([^:]+):(\d+)$/
		or return;
		
	return ($host, $port);
}

1;

__END__

=head1 NAME

Net::Proxy::Type - Get proxy type

=head1 SYNOPSIS

=over

 use strict;
 use Net::Proxy::Type;
 
 # get proxy type and print its name
 my $proxytype = Net::Proxy::Type->new();
 my $type = $proxytype->get('localhost:1111');
 warn 'proxy type is: ', $Net::Proxy::Type::NAME{$type};
 
 # same as
 warn 'proxy type is: ', Net::Proxy::Type->new()->get_as_string('localhost:1111');

=back

=over

 use strict;
 use Net::Proxy::Type ':types'; # import proxy type constants
 
 my $proxytype = Net::Proxy::Type->new(http_strict => 1); # strict check for http proxies - recommended
 my $proxy1 = 'localhost:1080';
 my $proxy2 = 'localhost:8080';
 my $proxy3 = 'localhost:3128';
 
 # check each type separately
 if($proxytype->is_http($proxy1)) {
 	warn "$proxy1 is http proxy";
 }
 elsif($proxytype->is_socks4($proxy1)) {
 	warn "$proxy1 is socks4 proxy";
 }
 elsif($proxytype->is_socks5($proxy1)) {
 	warn "$proxy1 is socks5 proxy";
 }
 else {
 	warn "$proxy1 is unknown proxy";
 }
 
 # get proxy type and do something depending on returned value
 my $type = $proxytype->get($proxy2);
 if ($type == CONNECT_PROXY) {
 	warn "$proxy2 is connect proxy";
 }
 elsif ($type == HTTPS_PROXY) {
 	warn "$proxy2 is https proxy";
 }
 elsif($type == HTTP_PROXY) {
 	warn "$proxy2 is http proxy";
 }
 elsif($type == SOCKS4_PROXY) {
 	warn "$proxy2 is socks4 proxy";
 }
 elsif($type == SOCKS5_PROXY) {
 	warn "$proxy2 is socks5 proxy";
 }
 elsif($type == DEAD_PROXY) {
 	warn "$proxy2 does not work";
 }
 else {
 	warn "$proxy2 is unknown proxy";
 }
 
 # return value of the "checker" methods is: 1 if type corresponds, 0 if not, undef if proxy server not connectable
 my $rv = $proxytype->is_http($proxy3);
 if($rv) {
 	warn "$proxy3 is http proxy";
 }
 elsif(defined($rv)) {
 	warn "$proxy3 is not http proxy, but it is connectable";
 }
 else {
 	warn "can't connect to $proxy3";
 }

=back

=head1 DESCRIPTION

The C<Net::Proxy::Type> is a module which can help you to get proxy type if you know host and port of the proxy server.
Supported proxy types for now are: http proxy, https proxy, connect proxy, socks4 proxy and socks5 proxy.

=head1 METHODS

=over

=item Net::Proxy::Type->new( %options )

This method constructs new C<Net::Proxy::Type> object. Key / value pairs can be passed as an argument
to specify the initial state. The following options correspond to attribute methods described below:

   KEY                  DEFAULT                            
   -----------          -----------------------------------               
   connect_timeout      $Net::Proxy::Type::CONNECT_TIMEOUT
   write_timeout        $Net::Proxy::Type::WRITE_TIMEOUT
   read_timeout         $Net::Proxy::Type::READ_TIMEOUT 
   timeout              undef
   http_strict          undef
   https_strict         undef
   socks4_strict        undef
   socks5_strict        undef
   connect_strict       undef
   strict               undef
   url                  $Net::Proxy::Type::URL
   https_url            $Net::Proxy::Type::HTTPS_URL
   keyword              $Net::Proxy::Type::KEYWORD
   https_keyword        $Net::Proxy::Type::HTTPS_KEYWORD
   noauth               undef
   http_ver             $Net::Proxy::Type::HTTP_VER

Description:

   connect_timeout - maximum number of seconds to wait until connection success
   write_timeout   - maximum number of seconds to wait until write operation success
   read_timeout    - maximum number of seconds to wait until read operation success
   timeout         - set value of all *_timeout options above to this value
   http_strict     - use or not strict method to check http proxies
   https_strict    - use or not strict method to check https proxies
   socks4_strict   - use or not strict method to check socks4 proxies
   socks5_strict   - use or not strict method to check socks5 proxies
   connect_strict  - use or not strict method to check connect proxies
   strict          - set value of all *_strict options above to this value (about strict checking see below)
   url             - url which response header should be checked for keyword when strict mode enabled (for all proxy types excluding HTTPS_PROXY)
   https_url       - url which response header should be checked for https_keyword when strict mode enabled (for HTTPS_PROXY only)
   keyword         - keyword which must be found in the respose header for url (for all types excluding HTTPS_PROXY)
   https_keyword   - keyword which must be found in the respose header for url (for HTTPS_PROXY only)
   noauth          - if proxy works, but authorization required, then false will be returned if noauth has true value
   http_ver        - http version which will be used in http request when strict mode is on (one of 0.9, 1.0, 1.1), default is 1.1

=item $proxytype->get($proxyaddress, $checkmask=undef)

=item $proxytype->get($proxyhost, $proxyport, $checkmask=undef)

Get proxy type. Checkmask allows to check proxy only for specified types, its value can be any 
combination of the valid proxy types constants (HTTPS_PROXY, HTTP_PROXY, CONNECT_PROXY, SOCKS4_PROXY, SOCKS5_PROXY for now),
joined with the binary OR (|) operator. Will check for all types if mask not defined. In scalar
context returned value is proxy type - one of the module constants descibed below. In list context
returned value is an array with proxy type as first element and connect time in seconds as second.

Example:

  # check only for socks type
  # if it is HTTP_PROXY, HTTPS_PROXY or CONNECT_PROXY returned value will be UNKNOWN_PROXY
  # because there is no check for HTTP_PROXY, HTTPS_PROXY and CONNECT_PROXY
  my $type = $proxytype->get('localhost:1080', SOCKS4_PROXY | SOCKS5_PROXY);

=item $proxytype->get_as_string($proxyaddress, $checkmask=undef)

=item $proxytype->get_as_string($proxyhost, $proxyport, $checkmask=undef)

Same as get(), but returns string instead of constant. In all contexts returns only one value.

=item $proxytype->get_all($proxyaddress, $checkmask=undef)

=item $proxytype->get_all($proxyhost, $proxyport, $checkmask=undef)

Same as get(), but will not stop checking after first found result. In scalar context returns integer value
(found proxy types joined with binary OR (|) operator), so you can use binary AND (&) to find is this proxy
of specified type. In list context additionally returns connection time as second element.

    my $type = $proxytype->get_all($host, $port);
    #  my ($type, $con_time) = $proxytype->get_all($host, $port);
    if ($type == DEAD_PROXY || $type == UNKNOWN_PROXY) {
        die "bad proxy";
    }
    
    while (my ($t, $n) = each %Net::Proxy::Type::NAME) {
        next if $t == DEAD_PROXY || $t == UNKNOWN_PROXY;
        if ($type & $t) {
            warn "this is ", $n, "\n";
        }
    }

=item $proxytype->get_all_as_string($proxyaddress, $checkmask=undef)

=item $proxytype->get_all_as_string($proxyhost, $proxyport, $checkmask=undef)

Same as get_all but always returns list with proxy types names.

=item $proxytype->is_http($proxyaddress)

=item $proxytype->is_http($proxyhost, $proxyport)

Check is this is http proxy. Returned value is 1 if it is http proxy, 0 if it is not http proxy
and undef if proxy host not connectable or proxy address is not valid. In list context returns array
where second element is connect time (empty array if proxy not connectable).

=item $proxytype->is_https($proxyaddress)

=item $proxytype->is_https($proxyhost, $proxyport)

Check is this is https proxy (http proxy which accepts CONNECT method). Returned value is 1 if it is https proxy, 0 if
it is not https proxy and undef if proxy host not connectable or proxy address is not valid. In list
context returns array where second element is connect time (empty array if proxy not connectable).

=item $proxytype->is_connect($proxyaddress)

=item $proxytype->is_connect($proxyhost, $proxyport)

Check is this is conenct proxy (http proxy which accepts CONNECT method even for 80 port, so you can make direct traffic transfer).
Returned value is 1 if it is connect proxy, 0 if it is not connect proxy and undef if proxy host not connectable or proxy address
is not valid. In list context returns array where second element is connect time (empty array if proxy not connectable).

=item $proxytype->is_socks4($proxyaddress)

=item $proxytype->is_socks4($proxyhost, $proxyport)

Check is this is socks4 proxy. Returned value is 1 if it is socks4 proxy, 0 if it is not socks4 proxy
and undef if proxy host not connectable or proxy address is not valid. In list context returns array
where second element is connect time (empty array if proxy not connectable).

=item $proxytype->is_socks5($proxyaddress)

=item $proxytype->is_socks5($proxyhost, $proxyport)

Check is this is socks5 proxy. Returned value is 1 if it is socks5 proxy, 0 if it is not socks5 proxy
and undef if proxy host not connectable or proxy address is not valid. In list context returns array
where second element is connect time (empty array if proxy not connectable).

=item $proxytype->timeout($timeout)

Set timeout for all operations. See constructor options description above

=item $proxytype->strict($boolean)

Set or unset strict checking mode. See constructor options description above

=back

Methods below gets or sets corresponding options from the constructor:

=over

=item $proxytype->connect_timeout

=item $proxytype->connect_timeout($timeout)

=item $proxytype->read_timeout

=item $proxytype->read_timeout($timeout)

=item $proxytype->write_timeout

=item $proxytype->write_timeout($timeout)

=item $proxytype->http_strict

=item $proxytype->http_strict($boolean)

=item $proxytype->https_strict

=item $proxytype->https_strict($boolean)

=item $proxytype->connect_strict

=item $proxytype->connect_strict($boolean)

=item $proxytype->socks4_strict

=item $proxytype->socks4_strict($boolean)

=item $proxytype->socks5_strict

=item $proxytype->socks5_strict($boolean)

=item $proxytype->url

=item $proxytype->url($url)

=item $proxytype->https_url

=item $proxytype->https_url($url)

=item $proxytype->keyword

=item $proxytype->keyword($keyword)

=item $proxytype->https_keyword

=item $proxytype->https_keyword($keyword)

=item $proxytype->noauth

=item $proxytype->noauth($boolean)

=item $proxytype->http_ver

=item $proxytype->http_ver($version)

=back

=head2 STRICT CHECKING

How this module works? To check proxy type it simply do some request to the proxy server and checks response. Each proxy
type has its own response type. For socks proxies we can do socks initialize request and response should be as its
described in socks proxy documentation (same for connect and https proxy). For http proxies we can
do http request to some host and check for example if response begins from `HTTP'. Problem is that if we, for example,
will check `yahoo.com:80' for http proxy this way, we will get positive response, but `yahoo.com' is not a proxy it is a
web server. So strict checking helps us to avoid this problems. What we do? We send http request to the server, specified
by the `url' option in the constructor via proxy and checks if response header contains keyword, specified by `keyword' option.
If there is no keyword in the header it means that this proxy is not of the cheking type. This is not best solution, but it works.
So strict mode recommended to check http proxies if you want to cut off such "proxies" as `yahoo.com:80', but you can use it with
other proxy types too.

=head1 PACKAGE CONSTANTS AND VARIABLES

Following proxy type constants available and could be imported separately or together with `:types' tag:

=over

=item UNKNOWN_PROXY

=item DEAD_PROXY

=item HTTP_PROXY

=item HTTPS_PROXY

=item CONNECT_PROXY

=item SOCKS4_PROXY

=item SOCKS5_PROXY

=back

Following variables available (not importable):

=over

=item $CONNECT_TIMEOUT = 5

=item $WRITE_TIMEOUT = 5

=item $READ_TIMEOUT = 5

=item $URL = 'http://www.google.com/'

=item $HTTPS_URL = 'https://www.google.com/'

=item $KEYWORD = 'google'

=item $HTTPS_KEYWORD = 'google'

=item $HTTP_VER = '1.1'

=item %NAME

Dictionary between proxy type constant and proxy type name

=back

=head1 COPYRIGHT

Copyright 2010-2014 Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
