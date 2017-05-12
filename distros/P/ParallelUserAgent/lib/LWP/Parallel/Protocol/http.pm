# -*- perl -*-
# $Id: http.pm,v 1.13 2003/03/11 16:49:35 langhein Exp $
# derived from: http10.pm,v 1.1 2001/10/26 17:27:19 gisle Exp $

package LWP::Parallel::Protocol::http;

use strict;

require LWP::Debug;
require HTTP::Response;
require HTTP::Status;
require Net::HTTP;
require IO::Socket;
require IO::Select;
use Carp ();

use vars qw(@ISA @EXTRA_SOCK_OPTS);

require LWP::Parallel::Protocol;
require LWP::Protocol::http; # until i figure out gisle's http1.1 stuff!
@ISA = qw(LWP::Parallel::Protocol LWP::Protocol::http);

my $CRLF         = "\015\012";     # how lines should be terminated;
				   # "\r\n" is not correct on all systems, for
				   # instance MacPerl defines it to "\012\015"

# The following 4 methods are more or less a simple breakdown of the
# original $http->request method:
=item ($socket, $fullpath) = $prot->handle_connect ($req, $proxy, $timeout);

This method connects with the server on the machine and port specified
in the $req object. If a $proxy is given, it will translate the
request into an appropriate proxy-request and return the new URL in
the $fullpath argument.

$socket is either an IO::Socket object (in parallel mode), or a
LWP::Socket object (when used via Std. non-parallel modules, such as
LWP::UserAgent) 

=cut

sub handle_connect {
    my ($self, $request, $proxy, $timeout, $nonblock) = @_;

    # check method
    my $method = $request->method;
    unless ($method =~ /^[A-Za-z0-9_!\#\$%&\'*+\-.^\`|~]+$/) {  # HTTP token
	return (undef, new HTTP::Response &HTTP::Status::RC_BAD_REQUEST,
				  'Library does not allow method ' .
				  "$method for 'http:' URLs");
    }

    my $url = $request->url;
    my($host, $port, $fullpath) = $self->get_address ($proxy, $url, $method);

   # connect to remote site
    my $socket = $self->_connect ($host, $port, $timeout, $nonblock);

#  LWP::Debug::debug("Socket is $socket");

# get LINGER get it!
#    my $data = $socket->sockopt(13);  #define SO_LINGER = 13
#    my @a_data = unpack ("ii",$data);
#    $a_data[0] = 1; $a_data[1] = 0;
#    $data = pack ("ii",@a_data);
#
#    $socket->sockopt(13, $data);  #define SO_LINGER = 13    
#    my $newdata = $socket->sockopt(13);  #define SO_LINGER = 13    
#    @a_data = unpack ("ii",$newdata);
#
#    print "Socket $socket: SO_LINGER (", $a_data[0],", ",$a_data[1],")\n";
# got Linger got it!


    ($socket, $fullpath);
}

sub get_address {
    my ($self, $proxy, $url,$method) = @_;
    my($host, $port, $fullpath);

    # Check if we're proxy'ing
    if (defined $proxy) {
	# $proxy is an URL to an HTTP server which will proxy this request
	$host = $proxy->host;
	$port = $proxy->port;
	$fullpath = $method && ($method eq "CONNECT") ?
                    ($url->host . ":" . $url->port) :
                     $url->as_string;
    }
    else {
	$host = $url->host;
	$port = $url->port;
	$fullpath = $url->path_query;
	$fullpath = "/" unless length $fullpath;
    }
    ($host, $port, $fullpath);
}

sub _connect { # renamed to make clear that this is private sub
    my ($self, $host, $port, $timeout, $nonblock) = @_;
    my ($socket); 
    unless ($nonblock) { 
      # perform good ol' blocking behavior
      # 
      # this method inherited from LWP::Protocol::http
      $socket = $self->_new_socket($host, $port, $timeout);
      # currently empty function in LWP::Protocol::http
      # $self->_check_sock($request, $socket);
    } else { 
      # new non-blocking behavior
      #
      # thanks to http://www.en-directo.net/mail/kirill.html
      use Socket();
      use POSIX();
      $socket = 
        IO::Socket::INET->new(Proto => 'tcp', # Timeout => $timeout,
	                      $self->_extra_sock_opts ($host, $port));

      die "Can't create socket for $host:$port ($@)" unless $socket;
      unless ( defined $socket->blocking (0) )
      {
	# IO::Handle::blocking doesn't (yet?) work on Win32 (ActiveState port)
	# The following happens to work though.
	# See also: perlport manpage, POE::Kernel, POE::Wheel::SocketFactory,
	#   Winsock2.h
	if ( $^O eq 'MSWin32' )
	{
	  my $set_it = "1";
	  my $ioctl_val = 0x80000000 | (4 << 16) | (ord('f') << 8) | 126;
  	  $ioctl_val = ioctl ($socket, $ioctl_val, $set_it);
#	warn 'Win32 ioctl returned ' . (defined $ioctl_val ? $ioctl_val : '[undef]') . "\n";
#	warn "Win32 ioctlsocket failed\n" unless $ioctl_val;
	}
      }
      my $rhost = Socket::inet_aton ($host);
      die "Bad hostname $host" unless defined $rhost;
      unless ( $socket->connect ($port, $rhost) )
      {
	my $err = $! + 0;
	# More trouble with ActiveState: EINPROGRESS and EWOULDBLOCK
	# are missing from POSIX.pm. See Microsoft's Winsock2.h
	my ($einprogress, $ewouldblock) = $^O eq 'MSWin32' ?
		(10036, 10035) : (POSIX::EINPROGRESS(), POSIX::EWOULDBLOCK());
	die "Can't connect to $host:$port ($@)"
		if $err and $err != $einprogress and $err != $ewouldblock;
      } 
    }
    LWP::Debug::debug("Socket is $socket");
    $socket;
}

sub write_request {
  my ($self, $request, $socket, $fullpath, $arg, $timeout, $proxy) = @_;

  my $method = $request->method;
  my $url    = $request->url;

 LWP::Debug::trace ("write_request (".
		    (defined $request ? $request : '[undef]').
		    ", ". (defined $socket ? $socket : '[undef]').
		    ", ". (defined $fullpath ? $fullpath : '[undef]').
		    ", ". (defined $arg ? $arg : '[undef]').
		    ", ". (defined $timeout ? $timeout : '[undef]'). 
		    ", ". (defined $proxy ? $proxy : '[undef]'). ")");

  my $sel = IO::Select->new($socket) if $timeout;

  my $request_line = "$method $fullpath HTTP/1.0$CRLF";
  
  my $h = $request->headers->clone;
  my $cont_ref = $request->content_ref;
  $cont_ref = $$cont_ref if ref($$cont_ref);
  my $ctype = ref($cont_ref);

  # If we're sending content we *have* to specify a content length
  # otherwise the server won't know a messagebody is coming.
  if ($ctype eq 'CODE') {
    die 'No Content-Length header for request with dynamic content'
      unless defined($h->header('Content-Length')) ||
	$h->content_type =~ /^multipart\//;
    # For HTTP/1.1 we could have used chunked transfer encoding...
  } 
  else {
    $h->header('Content-Length' => length $$cont_ref)
      if defined($$cont_ref) && length($$cont_ref);
  }  
    
  $self->_fixup_header($h, $url, $proxy);

  my $buf = $request_line . $h->as_string($CRLF) . $CRLF;
  my $n;  # used for return value from syswrite/sysread
  my $length;
  my $offset;

  # die's will be caught if user specified "use_eval".

  # syswrite $buf
  $length = length($buf);
  $offset = 0;
  while ( $offset < $length ) {
	die "write timeout" if $timeout && !$sel->can_write($timeout);
	$n = $socket->syswrite($buf, $length-$offset, $offset );
	die $! unless defined($n);
	$offset += $n;
  }
 
  LWP::Debug::conns($buf);
  
  if ($ctype eq 'CODE') {
    while ( ($buf = &$cont_ref()), defined($buf) && length($buf)) {
      # syswrite $buf
      $length = length($buf);
      $offset = 0;
      while ( $offset < $length ) {
	die "write timeout" if $timeout && !$sel->can_write($timeout);
	$n = $socket->syswrite($buf, $length-$offset, $offset );
	die $! unless defined($n);
	$offset += $n;
      }
      LWP::Debug::conns($buf);
    }
  } 
  elsif (defined($$cont_ref) && length($$cont_ref)) {
    # syswrite $$cont_ref
    $length = length($$cont_ref);
    $offset = 0;
    while ( $offset < $length ) {
      die "write timeout" if $timeout && !$sel->can_write($timeout);
      $n = $socket->syswrite($$cont_ref, $length-$offset, $offset );
      die $! unless defined($n);
      $offset += $n;
    }
    LWP::Debug::conns($buf);
  }
  
  # For an HTTP request, the 'command' socket is the same as the
  # 'listen' socket, so we just return the socket here.
  # (In the ftp module, we usually have one socket being the command
  # socket, and another one being the read socket, so that's why we
  # have this overhead here)
  return $socket;
}

# whereas 'handle_connect' (with its submethods 'get_address' and
# 'connect') and 'write_request' mainly just encapsulate different
# parts of the old http->request method, 'read_chunk' has an added
# level of complexity. This is because we have to be content with
# whatever data is available, and somehow 'save' our current state
# between multiple calls.

# To faciliate things later, when we need redirects and
# authentication, we insist that we _always_ have a response object
# available, which is generated outside and initialized with bogus
# data (code = 0). Also, we can then save ourselves the trouble of
# using a call-by-variable for $response in order to return a freshly
# generated $response-object.

# We have to provide IO::Socket-objects with a pushback mechanism,
# which comes pretty handy in case we can't use all the information read
# so far. Instead of changing the IO::Socket code, we just have our own
# little pushback buffer, $pushback, indexed by $socket object here.

my %pushback;

sub read_chunk {
  my ($self, $response, $socket, $request, $arg, $size, 
      $timeout, $entry) = @_;

 LWP::Debug::trace ("read_chunk (".
		    (defined $response ? $response : '[undef]').
		    ", ". (defined $socket ? $socket : '[undef]').
		    ", ". (defined $request ? $request : '[undef]').
		    ", ". (defined $arg ? $arg : '[undef]').
		    ", ". (defined $size ? $size : '[undef]').
		    ", ". (defined $timeout ? $timeout : '[undef]').
		    ", ". (defined $entry ? $entry : '[undef]'). ")");

  # hack! Can we just generate a new Select object here? Or do we
  # have to take the one we created in &write_request?!?
  my $sel = IO::Select->new($socket) if $timeout;

  LWP::Debug::debug('reading response ('. 
    (defined($pushback{$socket})?length($pushback{$socket}):0) .' buffered)');

  my $buf = "";
  # read one chunk at a time from $socket
  
  if ( $timeout && !$sel->can_read($timeout) ) {
      $response->message("Read Timeout");
      $response->code(&HTTP::Status::RC_REQUEST_TIMEOUT);
      $response->request($request);
      return 0; # EOF
  };
  my $n = $socket->sysread($buf, $size, length($buf));
  unless (defined ($n)) {
      $response->message("Sysread Error: $!"); 
      $response->code(&HTTP::Status::RC_SERVICE_UNAVAILABLE);
      $response->request($request);
      return 0; # EOF
  };
  # need our own EOF detection here
  unless ( $n ) {
      unless ($response  and  $response->code) {
	  $response->message("Unexpected EOF while reading response");
	  $response->code(&HTTP::Status::RC_BAD_GATEWAY);
	  $response->request($request);
	  return 0; # EOF
      }
  }

  # prepend contents of unprocessed buffer content from last read
  $buf = $pushback{$socket} . $buf if $pushback{$socket};
  LWP::Debug::conns("Buffer contents between dashes -->\n==========\n$buf==========");
  
  # determine Protocol type and create response object
  unless ($response  and  $response->code) {
    if ($buf =~ s/^(HTTP\/\d+\.\d+)[ \t]+(\d+)[ \t]*([^\012]*)\012//) { #1.39
      # HTTP/1.0 response or better
      my($ver,$code,$msg) = ($1, $2, $3);
      $msg =~ s/\015$//;
      LWP::Debug::debug("Identified HTTP Protocol: $ver $code $msg");
      $response->code($code);
      $response->message($msg);
      $response->protocol($ver);
      # store $request info in $response object
      $response->request($request);
    } 
    elsif ((length($buf) >= 5 and $buf !~ /^HTTP\//) or
	     $buf =~ /\012/ ) {
      # HTTP/0.9 or worse
      LWP::Debug::debug("HTTP/0.9 assume OK");
      $response->code(&HTTP::Status::RC_OK);
      $response->message("OK");
      $response->protocol('HTTP/0.9');
      # store $request info in $response object
      $response->request($request);
    } 
    else {
      # need more data
      LWP::Debug::debug("need more data to know which protocol");
    }
  }
  
  # if we have a protocol, read headers if neccessary
  if ( $response && !&headers($response) ) {
    # ensure that we have read all headers.  The headers will be
    # terminated by two blank lines
    unless ($buf =~ /^\015?\012/ || $buf =~ /\015?\012\015?\012/) {
      # must read more if we can...
      LWP::Debug::debug("need more data for headers");
    } else {
      # now we start parsing the headers.  The strategy is to
      # remove one line at a time from the beginning of the header
      # buffer ($buf).
      my($key, $val);

      while ($buf =~ s/([^\012]*)\012//) {
	my $line = $1;

	# if we need to restore as content when illegal headers
	# are found.
	my $save = "$line\012"; 
	
	$line =~ s/\015$//;
	last unless length $line;
	
	if ($line =~ /^([a-zA-Z0-9_\-.]+)\s*:\s*(.*)/) {
	  $response->push_header($key, $val) if $key;
	  ($key, $val) = ($1, $2);
	} elsif ($line =~ /^\s+(.*)/ && $key) {
	  $val .= " $1"; 
	} else {
	    $response->push_header("Client-Bad-Header-Line" =>
			           $line);
	}
      }
      $response->push_header($key, $val) if $key;

      # check to see if we have any header at all
      unless (&headers($response)) {
	# we need at least one header to go on
        LWP::Debug::debug("no headers found, inserting Client-Date");
	$response->header ("Client-Date" => 
			   HTTP::Date::time2str(time));
      }
    } # of if then else
  } # of if $response
  
  # if we have both a response AND the headers, start parsing the rest
  if ( $response && &headers($response) && length($buf)) {
    $self->_get_sock_info($response, $socket); 
    # the CONNECT method does not need to read content
    if ($request->method eq "CONNECT") { # from LWP 5.48's Protocol/http.pm
	$response->{client_socket} = $socket;  # so it can be picked up
    }  
    else {
      # all other methods want to read content, I guess...
      # Note that we can't use $self->collect, since we don't want to give
      # up control (by letting Protocol::collect use a $collector callback)
      if (my @te = $response->remove_header('Transfer-Encoding')) {
        $response->push_header('Client-Transfer-Encoding', \@te);
      }
      my $retval = $self->receive($arg, $response, \$buf, $entry);
      # update pushback buffer (receive handles _all_ of current buffer)
      $pushback{$socket} = '';
      # return length of response read (or value of $retval, if any, which
      # could be one of C_LASTCON, C_ENDCON, or C_ENDALL)
      return (defined $retval? $retval : length($buf));
    }
  }
  
  $pushback{$socket} = $buf;
  return $n;
}

# This function indicates if we have already parsed the headers.  In
# case of HTTP/0.9 we (obviously?!) don't have any (which means that
# we already 'parsed' them, so return 'true' no matter what)

sub headers {
    my ($response) = @_;

    return 1  if $response->protocol eq 'HTTP/0.9';

    ($response->headers_as_string ? 1 : 0);
}

sub close_connection {
  my ($self, $response, $listen_socket, $request, $cmd_socket) = @_;
#  print "Closing socket $listen_socket\n";
#  $listen_socket->close;
#  $cmd_socket->close;
}

# the old (single request) frontend, defunct.
sub request {
    die "LWP::Parallel::Protocol::http does not support single requests\n";
}


#-----------------------------------------------------------
# copied from LWP::Protocol::http (v1.63 in LWP5.64)
#-----------------------------------------------------------
package LWP::Parallel::Protocol::http::SocketMethods;

sub sysread {
    my $self = shift;
    if (my $timeout = ${*$self}{io_socket_timeout}) {
	die "read timeout" unless $self->can_read($timeout);
    }
    else {
	# since we have made the socket non-blocking we
	# use select to wait for some data to arrive
	$self->can_read(undef) || die "Assert";
    }
    sysread($self, $_[0], $_[1], $_[2] || 0);
}

sub can_read {
    my($self, $timeout) = @_;
    my $fbits = '';
    vec($fbits, fileno($self), 1) = 1;
    my $nfound = select($fbits, undef, undef, $timeout);
    die "select failed: $!" unless defined $nfound;
    return $nfound > 0;
}

sub ping {
    my $self = shift;
    !$self->can_read(0);
}

sub increment_response_count {
    my $self = shift;
    return ++${*$self}{'myhttp_response_count'};
}

#-----------------------------------------------------------
package LWP::Parallel::Protocol::http::Socket;
use vars qw(@ISA);
@ISA = qw(LWP::Parallel::Protocol::http::SocketMethods Net::HTTP);

#-----------------------------------------------------------
# ^^^ copied from LWP::Protocol::http (v1.63 in LWP5.64)
#-----------------------------------------------------------


1;
