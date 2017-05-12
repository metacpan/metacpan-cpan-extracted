#
# RTSP-Lite.pm 0.1
#   Lightweight RTSP implementation
#   http://www.kosho.org/tools/rtsp-lite/
#

package RTSP::Lite;

use vars qw($VERSION);
use strict qw(vars);

$VERSION = "0.1";
my $BLOCKSIZE = 65536;
my $CRLF = "\r\n";
my $FH;

# Required modules for Network I/O
use Socket 1.3;
use Fcntl;
use Errno qw(EAGAIN);

# Forward declarations
sub rtsp_write;
sub rtsp_readline;
sub rtsp_read;
sub rtsp_readbytes;

sub new 
{
    my $self = {};
    bless $self;
    $self->initialize();
    return $self;
}

sub initialize
{
    my $self = shift;
    $self->{timeout} = 120;
    $self->{DEBUG} = 0;
    $self->{cseq} = 0;
    $self->{user_agent} = "RTSP::Lite 0.1";
    $self->reset;
}

sub local_addr
{
    my $self = shift;
    my $val = shift;
    my $oldval = $self->{'local_addr'};
    if (defined($val)) {
	$self->{'local_addr'} = $val;
    }
    return $oldval;
}

sub local_port
{
    my $self = shift;
    my $val = shift;
    my $oldval = $self->{'local_port'};
    if (defined($val)) {
	$self->{'local_port'} = $val;
    }
    return $oldval;
}

sub method
{
    my $self=shift;
    my $method = shift;
    my $method = uc($method);
    $self->{method} = $method;
}

sub user_agent
{
    my $self=shift;
    my $user_agent = shift;
    $self->{user_agent} = $user_agent;
}

sub debug
{
    my $self = shift;
    my $debug = shift;
    $self->{DEBUG} = $debug;
}

sub DEBUG
{
    my $self = shift;
    if ($self->{DEBUG}) {
	print STDERR join(" ", @_),"\n";
    }
}

sub all_reset
{
	
}

sub reset
{
    my $self = shift;
    foreach my $var ("body", "request", "content", "status", "error-message",
		     "resp-headers", "headers","headermap","CBARGS",
		     "callback_function", "callback_params")
    {
	delete($self->{$var});
    }

    $self->{RTSPReadBuffer} = "";
    $self->{method} = "DESCRIBE";
}


# URL-encode data
sub escape 
{
    my $toencode = shift;
    $toencode=~s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
    return $toencode;
}

sub set_callback
{
    my ($self, $callback, @callbackparams) = @_;
    $self->{'callback_function'} = $callback;
    $self->{'callback_params'} = [ @callbackparams ];
}

sub open
{
    my ($self, $host,$port) = @_;

    if (!defined($port)) {
	$port = 554;
    }

    # Setup the connection
    my $proto = getprotobyname('tcp');

    socket(FH, PF_INET, SOCK_STREAM, $proto);

    my $addr = inet_aton($host);
    if (!$addr) {
	close(FH);
	return undef;
    }

    # choose local port and address
    my $local_addr = INADDR_ANY; 
    my $local_port = "0";
    if (defined($self->{'local_addr'})) {
	$local_addr = $self->{'local_addr'};
	if ($local_addr eq "0.0.0.0" || $local_addr eq "0") {
	    $local_addr = INADDR_ANY;
	} else {
	    $local_addr = inet_aton($local_addr);
	}
    }
    if (defined($self->{'local_port'})) {
	$local_port = $self->{'local_port'};
    }
    my $paddr = pack_sockaddr_in($local_port, $local_addr); 
    bind(FH, $paddr) || return undef;  # Failing to bind is fatal.

    my $sin = sockaddr_in($port,$addr);
    connect(FH, $sin) || return undef;

    # Set nonblocking IO on the handle to allow timeouts

    if ( $^O ne "MSWin32" ) {
	fcntl(FH, F_SETFL, O_NONBLOCK);
    }
	
}

sub close
{
    close FH;
}

sub request
{
    my ($self, $url, $data_callback, $cbargs) = @_;
  
    my $method = $self->{method};

    if (defined($cbargs)) {
	$self->{CBARGS} = $cbargs;
    }

    $self->{cseq}++;

    my $callback_func = $self->{'callback_function'};
    my $callback_params = $self->{'callback_params'};

    my $object = "$url";

    if (defined($callback_func)) {
	&$callback_func($self, "connect", undef, @$callback_params);
    }  

    # Add some required headers

    $self->add_req_header("CSEQ", $self->{cseq});    

    if (!($self->get_req_header("User-Agent"))) {
	$self->add_req_header("User-Agent",$self->{user_agent});
    }

    # Start the request 

    $self->rtsp_write(*FH, "$method $object RTSP/1.0$CRLF");
  
    # Output headers
    foreach my $header ($self->enum_req_headers())
    {
	my $value = $self->get_req_header($header);

	$self->rtsp_write(*FH, $header.": ".$value."$CRLF");

    }
  
    my $content_length;
    if (defined($self->{content}))
    {
	$content_length = length($self->{content});
    }
    if (defined($callback_func)) {
	my $ncontent_length = &$callback_func($self, "content-length", undef, @$callback_params);
	if (defined($ncontent_length)) {
	    $content_length = $ncontent_length;
	}
    }  

#  if ($content_length) {
#    rtsp_write(*FH, "Content-Length: $content_length$CRLF");
#  }
  
    if (defined($callback_func)) {
	&$callback_func($self, "done-headers", undef, @$callback_params);
    }  
    # End of headers
    $self->rtsp_write(*FH, "$CRLF");

  
    my $content_out = 0;
    if (defined($callback_func)) {
	while (my $content = &$callback_func($self, "content", undef, @$callback_params)) {
	    $self->rtsp_write(*FH, $content);
	    $content_out++;
	}
    } 
  
    # Output content, if any
    if (!$content_out && defined($self->{content}))
    {
	$self->rtsp_write(*FH, $self->{content});
    }
  
    if (defined($callback_func)) {
	&$callback_func($self, "content-done", undef, @$callback_params);
    }  

    # Read response from server
    my $headmode=1;
    my $chunkmode=0;
    my $chunksize=0;
    my $chunklength=0;
    my $chunk;
    my $line = 0;
    my $data;

    while ($data = $self->rtsp_read(*FH,$headmode,$chunkmode,$chunksize))
    {
	if ($self->{DEBUG}>1) {
	    $self->DEBUG("reading: $chunkmode, $chunksize, ".
			 "$chunklength, $headmode, ".length($self->{'body'}));
	    foreach my $var ("body", "request", "content", "status",
			     "error-message","resp-headers",
			     "CBARGS", "RTSPReadBuffer") 
	    {
		$self->DEBUG("state $var ".length($self->{$var}));
	    }
	}
	$line++;

	# Response Line;
	if ($line == 1) {
	    my ($proto,$status,$message) = split(' ', $$data, 3);
	    ($self->{DEBUG}>1) && $self->DEBUG("header $$data");
	    $self->{status}=$status;
	    $self->{'error-message'}=$message;
	    next;
	} 

	# after a blank line, its a body
	if (($headmode || $chunkmode eq "entity-header") &&
	    $$data =~ /^[\r\n]*$/) {
	    if ($chunkmode)  {
		$chunkmode = 0;
	    }
	    $headmode = 0;
      
	    #oops, [0] is not good
	    # in case of no body, Content-Length is not sent by server;
			
	    my $cl = $self->get_header('Content-Length');
	    if (defined($cl)) {
		$chunksize = @$cl[0];
		if ($chunksize>0) {
		    $chunkmode = "chunk";
		}
	    } else {
		return $self->{status};				
	    }

#      # Check for Transfer-Encoding (RTSP does not define it. Comment out)
#
#      my $te = $self->get_header("Transfer-Encoding");
#      if (defined($te)) {
#        my $header = join(' ',@{$te});
#        if ($header =~ /chunked/i)
#        {
#          $chunkmode = "chunksize";
#        }
#      }
	    next;
	}

	# Parse the entity-header

	if ($headmode || $chunkmode eq "entity-header") {
	    my ($var,$datastr) = $$data =~ /^([^:]*):\s*(.*)$/;
	    if (defined($var)) {
		$datastr =~s/[\r\n]$//g;
		$var = lc($var);
		$var =~ s/^(.)/&upper($1)/ge;
		$var =~ s/(-.)/&upper($1)/ge;
		my $hr = ${$self->{'resp-headers'}}{$var};
	    if (!ref($hr)) {
		$hr = [ $datastr ];
	    } else {
		push @{ $hr }, $datastr;
	    }
	    ${$self->{'resp-headers'}}{$var} = $hr;
        }
    } elsif ($chunkmode) {
	if ($chunkmode eq "chunksize")	{
	    $chunksize = $$data;
	    $chunksize =~ s/^\s*|;.*$//g;
	    $chunksize =~ s/\s*$//g;
	    my $cshx = $chunksize;
	    if (length($chunksize) > 0) {
		# read another line
		if ($chunksize !~ /^[a-f0-9]+$/i) {
		    ($self->{DEBUG}>1) &&
			$self->DEBUG("chunksize not a hex string");
		}
		$chunksize = hex($chunksize);
		($self->{DEBUG}>1) &&
		    $self->DEBUG("chunksize was $chunksize (HEX was $cshx)");
		if ($chunksize == 0)
		{
		    $chunkmode = "entity-header";
		} else {
		    $chunkmode = "chunk";
		    $chunklength = 0;
		}
	    } else {
		($self->{DEBUG}>1) &&
		    $self->DEBUG("chunksize empty string, checking next line!");
	    }
	} elsif ($chunkmode eq "chunk") {
	    $chunk .= $$data;
	    $chunklength += length($$data);
	    if ($chunklength >= $chunksize) {
		$chunkmode = "chunksize";
		if ($chunklength > $chunksize) {
		    $chunk = substr($chunk,0,$chunksize);
		} elsif ($chunklength == $chunksize && $chunk !~ /$CRLF$/) {
		    # chunk data is exactly chunksize -- need CRLF still
		    $chunkmode = "ignorecrlf";
		}
		$self->add_to_body(\$chunk, $data_callback);
		$chunk="";
		$chunklength = 0;
		$chunksize = "";
	    }
	    return $self->{status};

	} elsif ($chunkmode eq "ignorecrlf") {
	    $chunkmode = "chunksize";
	}
    } else {
	$self->add_to_body($data, $data_callback);
    }
  }
  if (defined($callback_func)) {
    &$callback_func($self, "done", undef, @$callback_params);
  }
  close(FH);
  return $self->{status};
}

sub add_to_body
{
    my $self = shift;
    my ($dataref, $data_callback) = @_;
  
    my $callback_func = $self->{'callback_function'};
    my $callback_params = $self->{'callback_params'};

    if (!defined($data_callback) && !defined($callback_func)) {
	($self->{DEBUG}>1) && $self->DEBUG("no callback");
	$self->{'body'}.=$$dataref;
    } else {
	my $newdata;
	if (defined($callback_func)) {
	    $newdata = &$callback_func($self, "data", $dataref, @$callback_params);
	} else {
	    $newdata = &$data_callback($self, $dataref, $self->{CBARGS});
	}
	if ($self->{DEBUG}>1) {
	    $self->DEBUG("callback got back a ".ref($newdata));
	    if (ref($newdata) eq "SCALAR") {
		$self->DEBUG("callback got back ".length($$newdata)." bytes");
	    }
	}
	if (defined($newdata) && ref($newdata) eq "SCALAR") {
	    $self->{'body'} .= $$newdata;
	}
    }
}

sub add_req_header
{
    my $self = shift;
    my ($header, $value) = @_;
  
    my $lcheader = lc($header);
    ($self->{DEBUG}>1) && $self->DEBUG("add_req_header $header $value");
    ${$self->{headers}}{$lcheader} = $value;
    ${$self->{headermap}}{$lcheader} = $header;
}

sub get_req_header
{
    my $self = shift;
    my ($header) = @_;
  
    return $self->{headers}{lc($header)};
}

sub delete_req_header
{
    my $self = shift;
    my ($header) = @_;
  
    my $exists;
    if ($exists=defined(${$self->{headers}}{lc($header)})) {
        delete ${$self->{headers}}{lc($header)};
        delete ${$self->{headermap}}{lc($header)};
    }
    return $exists;
}

sub enum_req_headers
{
    my $self = shift;
    my ($header) = @_;
  
    my $exists;
    return keys %{$self->{headermap}};
}

sub body
{
    my $self = shift;
    return $self->{'body'};
}

sub status
{
    my $self = shift;
    return $self->{status};
}


sub status_message
{
    my $self = shift;
    return $self->{'error-message'};
}


sub headers_array
{
    my $self = shift;
  
    my @array = ();
  
    foreach my $header (keys %{$self->{'resp-headers'}}) {
	my $aref = ${$self->{'resp-headers'}}{$header};
        foreach my $value (@$aref) {
	    push @array, "$header: $value";
	}
    }
    return @array;
}

sub headers_string
{
    my $self = shift;
  
    my $string = "";
  
    foreach my $header (keys %{$self->{'resp-headers'}}) {
	my $aref = ${$self->{'resp-headers'}}{$header};
        foreach my $value (@$aref) {
	    $string .= "$header: $value\n";
	}
    }
    return $string;
}

sub get_header
{
    my $self = shift;
    my $header = shift;

    return $self->{'resp-headers'}{$header};
}

sub rtsp_write
{
    my $self = shift;
    my ($fh,$line) = @_;

    my $size = length($line);

    $self->{DEBUG} && print STDERR ("write: $line");

    my $bytes = syswrite($fh, $line, $size, 0 );

    while ( ($size - $bytes) > 0) {
	$bytes += syswrite($fh, $line, 4096, $bytes );
    }
}
 
sub rtsp_read
{
    my $self = shift;
    my ($fh,$headmode,$chunkmode,$chunksize) = @_;

    ($self->{DEBUG}>1) &&
	$self->DEBUG("read handle=$fh, headm=$headmode, chunkm=$chunkmode, chunksize=$chunksize");

    my $res;
    if (($headmode == 0 && $chunkmode eq "0") || ($chunkmode eq "chunk")) {
	my $bytes_to_read = $chunkmode eq "chunk" ?
	    ($chunksize < $BLOCKSIZE ? $chunksize : $BLOCKSIZE) :
	    $BLOCKSIZE;
	$res = $self->rtsp_readbytes($fh,$self->{timeout},$bytes_to_read);
    } else {
	$res = $self->rtsp_readline($fh,$self->{timeout});
    }

    if ($res) {
	if ($self->{DEBUG}) {
	    if ($self->{DEBUG}>1) {
		$self->DEBUG("read got ".length($$res)." bytes");
	    }
	    my $str = $$res;
	    $str =~ s{([\x00-\x1F\x7F-\xFF])}{.}g;
	    $self->DEBUG("read: ".$str);
	}
    }
    return $res;
}

sub rtsp_readline
{
    my $self = shift;
    my ($fh, $timeout) = @_;
    my $EOL = "\n";

    ($self->{DEBUG}>1) &&
	$self->DEBUG("readline handle=$fh, timeout=$timeout");
  
    # is there a line in the buffer yet?
    while ($self->{RTSPReadBuffer} !~ /$EOL/) {
	# nope -- wait for incoming data
	my ($inbuf,$bits,$chars) = ("","",0);
	vec($bits,fileno($fh),1)=1;
	my $nfound = select($bits, undef, $bits, $timeout);
	if ($nfound == 0) {
	    # Timed out
	    return undef;
	} else {
	    # Get the data
	    $chars = sysread($fh, $inbuf, $BLOCKSIZE);
	    ($self->{DEBUG}>1) && $self->DEBUG("sysread $chars bytes");
	}
	# End of stream?
	if ($chars <= 0 && !$!{EAGAIN}) {
	    last;
	}
	# tag data onto end of buffer
	$self->{RTSPReadBuffer}.=$inbuf;
    }
    # get a single line from the buffer
    my $nlat = index($self->{RTSPReadBuffer}, $EOL);
    my $newline;
    my $oldline;
    if ($nlat > -1) {
	$newline = substr($self->{RTSPReadBuffer},0,$nlat+1);
	$oldline = substr($self->{RTSPReadBuffer},$nlat+1);
    } else {
	$newline = substr($self->{RTSPReadBuffer},0);
	$oldline = "";
    }
    # and update the buffer
    $self->{RTSPReadBuffer}=$oldline;
    return length($newline) ? \$newline : 0;
}

sub rtsp_readbytes
{
    my $self = shift;
    my ($fh, $timeout, $bytes) = @_;
    my $EOL = "\n";

    ($self->{DEBUG}>1) &&
	$self->DEBUG("readbytes handle=$fh, timeout=$timeout, bytes=$bytes");
  
    # is there enough data in the buffer yet?
    while (length($self->{RTSPReadBuffer}) < $bytes) {
	# nope -- wait for incoming data
	my ($inbuf,$bits,$chars) = ("","",0);
	vec($bits,fileno($fh),1)=1;
	my $nfound = select($bits, undef, $bits, $timeout);
	if ($nfound == 0) {
	    # Timed out
	    return undef;
	} else {
	    # Get the data
	    $chars = sysread($fh, $inbuf, $BLOCKSIZE);
	    $self->{DEBUG} && $self->DEBUG("sysread $chars bytes");
	}
	# End of stream?
	if ($chars <= 0 && !$!{EAGAIN}) {
	    last;
	}
	# tag data onto end of buffer
	$self->{RTSPReadBuffer}.=$inbuf;
    }

    my $newline;
    my $buflen;
    if (($buflen=length($self->{RTSPReadBuffer})) >= $bytes) {
	$newline = substr($self->{RTSPReadBuffer},0,$bytes+1);
	if ($bytes+1 < $buflen) {
	    $self->{RTSPReadBuffer} = substr($self->{RTSPReadBuffer},$bytes+1);
	} else {
	    $self->{RTSPReadBuffer} = "";
	}
    } else {
	$newline = substr($self->{RTSPReadBuffer},0);
	$self->{RTSPReadBuffer} = "";
    }
    return length($newline) ? \$newline : 0;
}

sub upper
{
    my ($str) = @_;
    if (defined($str)) {
	return uc($str);
    } else {
	return undef;
    }
}

1;

__END__

=pod

=head1 NAME

RTSP::Lite - Lightweight RTSP implementation

=head1 SYNOPSIS

  use RTSP::Lite;
  $rtsp = new RTSP::Lite;
  $rtsp->open("192.168.0.1",554);
  $rtsp->method("DESCRIBE");
  $rtsp->request("rtsp://192.168.0.1/realqt.mov");
  $status_code = $rtsp->status();
  $status_message = $rtsp->status_message();
  print "$status_code $status_message\n";
  print $rtsp->body();

=head1 DESCRIPTION

RTSP::Lite is a stand-alone lightweight RTSP/1.0 module for Perl. It
is based on Roy Hooper's HTTP::Lite (RTSP protocol is very similar to
HTTP protocol. I simply modified it to support RTSP).

The main focus of the module is to help you write simple RTSP clients
for monitoring and debugging streaming server. So far, full streaming
clients that need RTP handling are out of my scope.

The main modifications from the HTTP::Lite 2.1.4 are: 
 + Supports continuous requests. Therefore explicit open operation is
 now required.
 + Supports multiple debug level.
 + Callback function is not supported.
 + Deletes http style proxy support. Because RTSP requests to proxy
 are the same style of  requests to server. 

=head1 METHODS

=item B<debug ( $level)>

Set the debug level. 
  0: no debug message (default), 
  1: display all network write and read
  2: display all debug message

=item B<open ( $host, $port )>

Open a connection to $host:$port.  $port can be left out.

=item B<method ( $method )>

Set the method name (OPTIONS, DESCRIBE, PLAY, ...). 

=item B<add_req_header ( $header, $value )>

=item B<get_req_header ( $header )>

=item B<delete_req_header ( $header )>

Add, Delete, or  get RTSP header(s) for the request. 

=item B<user_agent( $agent_name)>

Set the agent name (Default is "RTSP::Lite 0.1"). 

=item B<request ( $url )>

Send a request to the connected host. If an I/O error is encountered,
it returns undef, otherwise RTSP status code is returned. 

Note: user-agent and cseq headers are automatically added. If user
agent header is specified by add_req_header (), it overwrites the
user_agent () variable;

=item B<body ()>

Returns the body of the response. 

=item B<status ()>

Returns the status code received from the RTSP server

=item B<status_message ()>

Returns the textual description of the status code received from the
RTSP server.

=item B<headers_array ()>

Returns an array of the RTSP headers received from the RTSP server.

=item B<headers_string>

Returns a string representation of the RTSP headers received from the
RTSP server.

=item B<get_header ( $header )>

Returns an array of values for the received response. 

=item B<reset ()>

You must call this prior to re-using an RTSP::Lite file handle,
otherwise the results are undefined.

=item B<local_addr ( $ip )>

=item B<local_port ( $port )>

Explicitly select the local IP address (default 0.0.0.0) and the local port (default 0: automatic selected by system).

=head1 EXAMPLES

rtsp-request: command line RTSP request tool
(http://www.kosho.org/tools/rtsp-request/).

sample scripts that included in the distribution file
  describe.pl
  play.pl

SETUP & PLAY sample
  #!/usr/bin/perl
  use RTSP::Lite;
  $url = "rtsp://192.168.0.1/realqt.mov";
  $rtsp = new RTSP::Lite;
  ## open the connection
  $req = $rtsp->open("192.168.0.1",554) or   die "Unable to open: $!";

  ## SETUP
  $rtsp->method("SETUP");
  $rtsp->add_req_header("Transport","RTP/AVP;unicast;client_port=6970-6971");
  $req = $rtsp->request($url."/streamid=0");

  my $se = $rtsp->get_header("Session");
  $session = @$se[0];
  print $rtsp->status_message();
  print_headers();
  ## Play
  $rtsp->reset();
  $rtsp->method("PLAY");
  $rtsp->add_req_header("Session","$session");
  $rtsp->add_req_header("Range","npt=0.000000-5.200000");
  $req = $rtsp->request($url);
  print $rtsp->status_message();
  print_headers();
  ## You will get RTP/RTCP packets, you need to have codes for them.
  exit;
  sub print_headers {
    my @headers = $rtsp->headers_array();
    my $body = $rtsp->body();
    foreach $header (@headers) {
      print "$header\n";
    }
  }

=head1 AUTHOR

Masaaki NABESHIMA <http://www.kosho.org/>

=head1 SEE ALSO

 RFC 2326 - Real Time Streaming Protocol (RTSP)
 HTTP::Lite module (http://www.thetoybox.org/http-lite/)

=head1 ACKNOWLEDGEMENTS

This module is a deviation of HTTP::Lite, maintained by Roy
Hooper. Without it this module never exist.

=head1 COPYRIGHT

Copyright (c) 2003, Masaaki NABESHIMA. 
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 AVAILABILITY

The latest version of this module is available at: 
http://www.kosho.org/tools/rtsp-lite/

=cut
