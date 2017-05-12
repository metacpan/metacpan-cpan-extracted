package NET::MitM;

=head1 NAME

NET::MitM - Man in the Middle - connects a client and a server, giving visibility of and control over messages passed.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

NET::MitM is designed to be inserted between a client and a server. It proxies all traffic through verbatum, and also copies that same data to a log file and/or a callback function, allowing a data session to be monitored, recorded, even altered on the fly.

MitM acts as a 'man in the middle', sitting between the client and server.  To the client, MitM looks like the server.  To the server, MitM looks like the client.

MitM cannot be used to covertly operate on unsuspecting client/server sessions - it requires that you control either the client or the server.  If you control the client, you can tell it to connect via your MitM.  If you control the server, you can move it to a different port, and put a MitM in its place.  

When started, MitM opens a socket and listens for connections. When that socket is connected to, MitM opens another connection to the server.  Messages from either client or server are passed to the other, and a copy of each message is, potentially, logged.  Alternately, callback methods may be used to add business logic, including potentially altering the messages being passed.

MitM can also be used as a proxy to allow two processes on machines that cannot 'see' each other to communicate via an intermediary machine that is visible to both.

There is an (as yet unreleased) sister module L<NET::Replay> that allows a MitM session to be replayed.

=head3 Usage

Assume the following script is running on the local machine:

    use NET::MitM;
    my $MitM = NET::MitM->new("cpan.org", 80, 10080);
    $MitM->log_file("MitM.log");
    $MitM->go();

A browser connecting to L<http://localhost:10080> will now cause MitM to open a connection to cpan.org, and messages sent by either end will be passed to the other end, and logged to MitM.log.  

For another example, see samples/mitm.pl in the MitM distribution.

=head3 Modifying messages on the fly.

However you deploy MitM, it will be virtually identical to having the client and server talk directly.  The difference will be that either the client and/or server will be at an address other than the one its counterpart believes it to be at.  Most programs ignore this, but sometimes it matters.

For example, HTTP browsers pass a number of parameters, one of which is "Host", the host to which the browser believes it is connecting.  Often, this parameter is unused.  But sometimes, a single HTTP server will be serving content for more than one website.  Such a server generally relies on the Host parameter to know what it is to return.  If the MitM is not on the same host as the HTTP server, the host parameter that the browser passes will cause the HTTP server to fail to serve the desired pages.

Further, HTTP servers typically return URLs containing the host address.  If the browser navigates to a returned URL, it will from that point onwards connect directly to the server in the URL instead of communicating via MitM.

Both of these problems can be worked around by modifying the messages being passed.

For example, assume the following script is running on the local machine:

    use NET::MitM;
    sub send_($) {$_[0] =~ s/Host: .*:\d+/Host: cpan.org/;}
    sub receive($) {$_[0] =~ s/cpan.org:\d+/localhost:10080/g;}
    my $MitM = NET::MitM->new("cpan.org", 80, 10080);
    $MitM->client_to_server_callback(\&send);
    $MitM->server_to_client_callback(\&receive);
    $MitM->log_file("http_MitM.log");
    $MitM->go();

The send callback tells the server that it is to serve cpan.org pages, instead of some other set of pages, while the receive callback tells the browser to access cpan.org URLs via the MitM process, not directly.  The HTTP server will now respond properly, even though the browser sent the wrong hostname, and the browser will now behave as desired and direct future requests via the MitM.

For another example, see samples/http_mitm.pl in the MitM distribution.

A more difficult problem is security aware processes, such as those that use HTTPS based protocols. They are actively hostname aware.  Precisely to defend against a man-in-the-middle attack, they check their counterpart's reported hostname (but not normally the port) against the actual hostname.  Unless client, server and MitM are all on the same host, either the client or the server will notice that the remote hostname is not what it should be, and will abort the connection.  
There is no good workaround for this, unless you can run an instance of MitM on the server, and another on the client - but even if you do, you still have to deal with the communication being encrypted.

=head1 SUBROUTINES/METHODS

=cut

# #######
# Globals
# #######

use 5.002;
use warnings FATAL => 'all';
use Socket;
use FileHandle;
use IO::Handle;
use Carp;
use strict;
eval {use Time::HiRes qw(time)}; # only needed for high precision time_interval - will still work fine even if missing

my $protocol = getprotobyname('tcp'); # TODO: make dynamic?

=head2 new( remote_ip_address, local_port_num, remote_port_num )

Creates a new MitM

=head4 Parameters

=over

=item * remote_ip_address - the remote hostname/IP address of the server 

=item * remote_port_num - the remote port number of the server

=item * local_port_num - the port number to listen on

=item * Returns - a new MitM object

=back

=head4 Usage

To keep a record of all messages sent:

    use NET::MitM;
    my $MitM = NET::MitM->new("www.cpan.org", 80, 10080);
    $MitM->log_file("MitM.log");
    $MitM->go();

=cut 

sub hhmmss();

my $mitm_count=0;

sub _new(){
  my %this;
  $this{verbose} = 1;
  $this{parallel} = 0;
  $this{mydate} = \&hhmmss;
  $this{name} = "MitM".++$mitm_count;
  return \%this;
}

sub new($$;$$$) {
  my $class=shift;
  my $this=_new();
  $this->{remote_ip_address} = shift or croak "remote hostname/ip address missing";
  $this->{remote_port_num} = shift or croak "remote port number missing";
  $this->{local_port_num} = shift || $this->{remote_port_num};
  return bless($this, $class);
}

=head2 go( )

Listen on local_port, accept incoming connections, and forwards messages back and forth.

=head4 Parameters

=over

=item * --none--

=item * Returns --none--

=back

=head4 Usage

When a connection on local_port is received a connect to remote_ip_address:remote_port is created and messages from the client are passed to the server and vice-versa. 

If parallel() was set, which is not the default, there will be a new process created for each such session.

If any callback functions have been set, they will be called before each message is passed.
If logging is on, messages will be logged.

go() does not return. You may want to L<fork> before calling it.  There is no way to stop it from outside except using a signal to interrupt it.  This will probably change in a future release of MitM.

If new_server() was used instead of new(), messages from client are instead passed to the server callback function.

=cut

# Convenience function - intentionally not exposed. If you really want to call it, you can of course. But if you are going to violate encapsulation, why not go directly to the variables?

sub _set($;$) {
  my $this=shift;
  my $key=shift or confess "missing mandatory parameter";
  my $value=shift;
  if(defined $value){
    $this->{$key} = $value;
  }
  return $this->{$key};
}

=head2 name( [name] )

Names the object - will be reported back in logging/debug

=head4 Parameters

=over

=item * name - the new name (default is MitM1, MitM2, ...)

=item * Returns - the current or new setting

=back

=head4 Usage

For a minimal MitM:

    use NET::MitM;
    my $MitM = NET::MitM->new("www.cpan.org", 80, 10080);
    $MitM->go();

=cut 

sub name(;$) {
  my $this=shift;
  my $value=shift;
  return $this->_set("name", $value);
}

=head2 verbose( [level] )

Turns on/off reporting to stdout. 

=head4 Parameters

=over

=item * level - how verbose to be. 0=nothing, 1=normal, 2=debug. The default is 1.

=item * Returns - the current or new setting

=back

=head4 Usage

Setting verbose changes the amount of information printed to stdout.

=cut 

sub verbose(;$) {
  my $this=shift;
  my $verbose=shift;
  #warn "verbose->(",$verbose||"--undef--",")\n";
  return $this->_set("verbose", $verbose);
}

=head2 client_to_server_callback( callback )

Set a callback function to monitor/modify each message sent to server

=head4 Parameters

=over

=item * callback - a reference to a function to be called for each message sent to server

=item * Returns - the current or new setting

=back

=head4 Usage

If client_to_server_callback is set, it will be called with a copy of each message to the server before it is sent.  Whatever the callback returns will be sent.

For example, to modify messages:

    use NET::MitM;
    sub send_($) {$_[0] =~ s/Host: .*:\d+/Host: cpan.org/;}
    sub receive($) {$_[0] =~ s/www.cpan.org(:\d+)?/localhost:10080/g;}
    my $MitM = NET::MitM->new("www.cpan.org", 80, 10080);
    $MitM->client_to_server_callback(\&send);
    $MitM->server_to_client_callback(\&receive);
    $MitM->go();

If the callback is readonly, it should either return a copy of the original message, or undef. Be careful not to accidentally return something else - remember that perl methods implicitly returns the value of the last command executed.

For example, to write messages to a log:

    sub peek($) {my $msg = shift; print LOG; return $msg;}
    my $MitM = NET::MitM->new("www.cpan.org", 80, 10080);
    $MitM->client_to_server_callback(\&peek);
    $MitM->server_to_client_callback(\&peek);
    $MitM->go();

This would also work:
    sub peek($) {my $msg = shift; print LOG; return undef;}
    ...

But this is unlikely to do what you would want:
    sub peek($) {my $msg = shift; print LOG}
    ...

=cut 

sub client_to_server_callback(;$) {
  my $this=shift;
  my $callback=shift;
  return $this->_set("client_to_server_callback", $callback);
}

=head2 server_to_client_callback( [callback] )

Set a callback function to monitor/modify each message received from server

=head4 Parameters

=over

=item * callback - a reference to a function to be called for each inward message

=item * Returns - the current or new setting

=back

=head4 Usage

If server_to_client_callback is set, it will be called with a copy of each message received from the server before it is sent to the client.  Whatever the callback returns will be sent.  

If the callback is readonly, it should either return a copy of the original message, or undef. Be careful not to accidentally return something else - remember that perl methods implicitly returns the value of the last command executed.

=cut 

sub server_to_client_callback(;$) {
  my $this=shift;
  my $callback=shift;
  return $this->_set("server_to_client_callback", $callback);
}

=head2 timer_callback( [interval, callback] )

Set a callback function to be called at regular intervals

=head4 Parameters

=over

=item * interval - how often the callback function is to be called - must be > 0 seconds, may be fractional
=item * callback - a reference to a function to be called every interval seconds

=item * Returns - the current or new setting, as an array

=back

=head4 Usage

If the callback is set, it will be called every interval seconds.   Interval must be > 0 seconds.  It may be fractional.  If interval is passed as 0 it will be reset to 1 second. This is to prevent accidental spin-wait. If you really want to spin-wait, pass an extremely small but non-zero interval.

If the callback returns false, mainloop will exit and return control to the caller.

The time spent in callbacks is not additional to the specified interval - the timer callback will be called every interval seconds, or as close as possible to every interval seconds.  

Please remember that if you have called fork before calling go() that the timer_callback method will be executed in a different process to the parent - the two processes will need to use some form of L<IPC> to communicate.

=cut 

sub timer_callback(;$) {
  my $this=shift;
  my $interval=shift;
  my $callback=shift;
  if(defined $interval && $interval==0){
    $interval=1;
  }
  $interval=$this->_set("timer_interval", $interval);
  $callback=$this->_set("timer_callback", $callback);
  return ($interval, $callback);
}

=head2 parallel( [level] )

Turns on/off running in parallel.

=head4 Parameters

=over

=item * level - 0=serial, 1=parallel. Default is 0 (run in serial).

=item * Returns - the current or new setting

=back

=head4 Usage

If running in parallel, MitM starts a new process for each new connection using L<fork>.

Running in serial still allows multiple clients to run concurrently, as so long as none of them have long-running callbacks.  If they do, they will block other clients from sending/recieving.

=cut 

sub parallel(;$) {
  my $this=shift;
  my $parallel=shift;
  if($parallel){
    $SIG{CLD} = "IGNORE"; 
  }
  return $this->_set("parallel", $parallel);
}

=head2 serial( [level] )

Turns on/off running in serial

=head4 Parameters

=over

=item * level - 0=parallel, 1=serial. Default is 1, i.e. run in serial.  

=item * Returns - the current or new setting

=back

=head4 Usage

Calling this function with level=$l is exactly equivalent to calling parallel with level=!$l.

If running in parallel, MitM starts a new process for each new connection using L<fork>.

Running in serial, which is the default, still allows multiple clients to run concurrently, as so long as none of them have long-running callbacks.  If they do, they will block other clients from sending/recieving.

=cut 

sub serial(;$) {
  my $this=shift;
  my $level=shift;
  my $parallel = $this->parallel(defined $level ? ! $level : undef);
  return $parallel ? 0 : 1;
}

=head2 log_file( [log_file_name] ] )

log_file() sets, or clears, a log file.  

=head4 Parameters

=over

=item * log_file_name - the name of the log file to be appended to. Passing "" disables logging. Passing nothing, or undef, returns the current log filename without change.

=item * Returns - log file name

=back

=head4 Usage 

The log file contains a record of connects and disconnects and messages as sent back and forwards.  Log entries are timestamped.  If the log file already exists, it is appended to.  

The default timestamp is "hh:mm:ss", eg 19:49:43 - see mydate() and hhmmss().

=cut 

sub log_file(;$) {
  my $this=shift;
  my $new_log_file=shift;
  if(defined $new_log_file){
    if(!$new_log_file){
      if($this->{LOGFILE}){
        close($this->{LOGFILE});
        $this->{log_file}=$this->{LOGFILE}=undef;
        print "Logging turned off\n" if $this->{verbose};
      }
    }else{
      my $LOGFILE;
      if( open($LOGFILE, ">>$new_log_file") ) {
        binmode($LOGFILE);
        $LOGFILE->autoflush(1); # TODO make this configurable?
        $this->{log_file}=$new_log_file;
        $this->{LOGFILE}=$LOGFILE;
      }
      else {
        print "Failed to open $new_log_file for logging: $!" if $this->{verbose}; 
      }
      print "Logging to $this->{log_file}\n" if $this->{verbose} && $this->{log_file};
    }
  }
  return $this->{log_file};
}

=head2 defrag_delay( [delay] )

Use a small delay to defragment messages

=head4 Parameters

=over

=item * Delay - seconds to wait - fractions of a second are OK

=item * Returns - the current setting.

=back

=head4 Usage

Under TCPIP, there is always a risk that large messages will be fragmented in transit, and that messages sent close together may be concatenated.

Client/Server programs have to know how to turn a stream of bytes into the messages they care about, either by repeatedly reading until they see an end-of-message (defragmenting), or by splitting the bytes read into multiple messages (deconcatenating).

For our purposes, fragmentation and concatenation can make our logs harder to read.

Without knowning the protocol, it's not possible to tell for sure if a message has been fragmented or concatenated.

A small delay can be used as a way of defragmenting messages, although it increases the risk that separate messages may be concatenated.

Eg:
    $MitM->defrag_delay( 0.1 );

=cut 

sub defrag_delay(;$) {
  my $this=shift;
  my $defrag_delay=shift;
  return $this->_set("defrag_delays",$defrag_delay);
}

=head1 SUPPORTING SUBROUTINES/METHODS

The remaining functions are supplimentary.  new_server() and new_client() provide a simple client and a simple server that may be useful in some circumstances.  The other methods are only likely to be useful if you choose to bypass go() in order to, for example, have more control over messages being received and sent.

=head2 new_server( local_port_num, callback_function )

Returns a very simple server, adequate for simple tasks.

=head4 Parameters

=over

=item * local_port_num - the Port number to listen on

=item * callback_function - a reference to a function to be called when a message arrives - must return a response which will be returned to the client

=item * Returns - a new server

=back

=head4 Usage

  sub do_something($){
    my $in = shift;
    my $out = ...
    return $out;
  }

  my $server = NET::MitM::new_server(8080,\&do_something) || die;
  $server->go();
 
The server returned by new_server has a method, go(), which tells it to start receiving messages (arbitrary strings).  Each string is passed to the callback_function, which is expected to return a single string, being the response to be returned to caller.  If the callback returns undef, the original message will be echoed back to the client.   

go() does not return. You may want to L<fork> before calling it.

See, for another example, samples/echo_server.pl in the MitM distribution.

=cut 

sub new_server($%) {
  my $class=shift;
  my $this=_new();
  $this->{local_port_num} = shift or croak "no port number passed";
  $this->{server_callback} = shift or croak "no callback passed";
  return bless $this;
}

=head2 new_client( remote_host, local_port_num )

new client returns a very simple client, adequate for simple tasks

The server returned has a method, send_and_receive(), which sends a message and receives a response. 

Alternately, send_to_server() may be used to send a message, and read_from_server() may be used to receive a message.

Explicitly calling connect_to_server() is optional, but may be useful if you want to be sure the server is reachable.  If you don't call it explicitly, it will be called the first time a message is sent.

=head4 Parameters

=over

=item * remote_ip_address - the hostname/IP address of the server

=item * remote_port_num - the Port number of the server

=item * Returns - a new client object

=back

=head4 Usage

  my $client = NET::MitM::new_client("localhost", 8080) || die("failed to start test client: $!");
  $client->connect_to_server();
  my $resp = $client->send_and_receive("hello");
  ...

See, for example, samples/client.pl or samples/clients.pl in the MitM distribution.

=cut 

sub new_client($%) {
  my $class=shift;
  my $this=_new();
  $this->{remote_ip_address} = shift or croak "remote hostname/ip address missing";
  $this->{remote_port_num} = shift or croak "remote port number missing";
  return bless $this;
}

=head2 log( string )

log is a convenience function that prefixes output with a timestamp and PID information then writes to log_file.

=head4 Parameters

=over

=item * string(s) - one or more strings to be logged

=item * Returns --none--

=back

=head4 Usage

log is a convenience function that prefixes output with a timestamp and PID information then writes to log_file.

log() does nothing unless log_file is set, which by default, it is not.

=cut 

sub log($@)
{
  my $this=shift;
  printf {$this->{LOGFILE}} "%u/%s %s\n", $$, $this->{mydate}(), "@_" if $this->{LOGFILE};
  return undef;
}

=head2 echo( string(s) )

Prints to stdout and/or the logfile

=head4 Parameters

=over

=item * string(s) - one or more strings to be echoed (printed)

=item * Returns --none--

=back

=head4 Usage

echo() is a convenience function that prefixes output with a timestamp and PID information and prints it to standard out if verbose is set and, if log_file() has been set, logs it to the log file.

=cut 

sub echo($@) 
{
  my $this=shift;
  $this->log("@_");
  return if !$this->{verbose};
  confess "Did not expect not to have a name" if !$this->{name};
  if($_[0] =~ m/^[<>]{3}$/){
    my $prefix=shift;
    my $msg=join "", @_;
    printf("%s: %u/%s %s %d bytes\n", $this->{name}, $$, $this->{mydate}(), $prefix, length($msg));
  }else{
    printf("%s: %u/%s\n", $this->{name}, $$, join(" ", $this->{mydate}(), @_));
  }
  return undef;
}

=head2 send_to_server( string(s) )

send_to_server() sends a message to the server

=head4 Parameters

=over

=item * string(s) - one or more strings to be sent

=item * Return: true if successful

=back

=head4 Usage

If a callback is set, it will be called before the message is sent.

send_to_server() may 'die' if it detects a failure to send.

=cut 

sub _do_callback($$)
{
    my $callback = shift;
    my $msg = shift;
    if($callback){
      my $new_msg = $callback->($msg);
      $msg = $new_msg unless !defined $new_msg;
    }
    return $msg;
}

sub _logmsg
{
  my $this = shift;
  my $direction = shift;
  my $msg = shift;
  if($this->{verbose}>1){
    $this->echo($direction,"(".length($msg)." bytes) {$msg}\n");
  }else{
    # don't print the whole message by default, in case it is either binary &/or long
    $this->echo($direction,"(".length($msg)." bytes)\n");
    $this->log($direction," {{{$msg}}}\n");
  }
}

sub send_to_server($@)
{
    my $this = shift;
    my $msg = shift;
    $this->connect_to_server();
    $this->log("calling server callback ($msg)\n") if $this->{client_to_server_callback} && $this->{verbose}>1;
    $msg = _do_callback( $this->{client_to_server_callback}, $msg );
    $this->_logmsg(">>>",$msg);
    confess "SERVER being null was unexpected" if !$this->{SERVER};
    return print({$this->{SERVER}} $msg) || die "Can't send to server: $?";
}

=head2 send_to_client( string(s) )

Sends a message to the client

=head4 Parameters

=over

=item * string(s) - one or more strings to be sent

=item * Return: true if successful

=back

=head4 Usage

If a callback is set, it will be called before the message is sent.

=cut 

sub send_to_client($@)
{
    my $this = shift;
    my $msg = shift;
    $this->echo("calling client callback ($msg)\n") if $this->{server_to_client_callback} && $this->{verbose}>1;
    $msg = _do_callback( $this->{server_to_client_callback}, $msg );
    $this->_logmsg("<<<",$msg);
    return print({$this->{CLIENT}} $msg);
}

=head2 read_from_server( )

Reads a message from the server

=head4 Parameters

=over

=item * --none--

=item * Returns - the message read, or undef if the server disconnected.  

=back

=head4 Usage

Blocks until a message is received.

=cut 

sub read_from_server()
{
  my $this=shift;
  my $msg;
  sysread($this->{SERVER},$msg,100000);
  if(length($msg) == 0)
  {
    $this->echo("Server disconnected\n");
    return undef;
  }
  return $msg;
}

=head2 send_and_receive( )

Sends a message to the server and receives a response

=head4 Parameters

=over

=item * the message(s) to be sent

=item * Returns - message read, or undef if the server disconnected. 

=back

=head4 Usage

Blocks until a message is received.  If the server does not always return exactly one message for each message it receives, send_and_receive() will either concatenate messages or block forever.

=cut 

sub send_and_receive($)
{
  my $this=shift;
  $this->send_to_server(@_);
  return $this->read_from_server(@_);
}

=head2 connect_to_server( )

Connects to the server

=head4 Parameters

=over

=item * --none--

=item * Returns --none--

=back

=head4 Usage

This method is automatically called when needed. It only needs to be called directly if you want to be sure that the connection to server succeeds before proceeding.

=cut

sub connect_to_server()
{
  my $this=shift;
  return if $this->{SERVER};
  socket($this->{SERVER}, PF_INET, SOCK_STREAM, $protocol) or die "Can't create socket: $!";
  confess "remote_ip_address unexpectedly not known" if !$this->{remote_ip_address};
  my $remote_ip_aton = inet_aton( $this->{remote_ip_address} ) or croak "Fatal: Cannot resolve internet address: '$this->{remote_ip_address}'\n";
  my $remote_port_address = sockaddr_in($this->{remote_port_num}, $remote_ip_aton ) or die "Fatal: Can't get port address: $!"; # TODO Is die the way to go here? Not sure it isn't. Not sure it is.
  $this->echo("Connecting to $this->{remote_ip_address}\:$this->{remote_port_num} [verbose=$this->{verbose}]\n");
  connect($this->{SERVER}, $remote_port_address) or confess "Fatal: Can't connect to $this->{remote_ip_address}:$this->{remote_port_num} using $this->{SERVER}. $!"; # TODO Is die the way to go here? Not sure it isn't. Not sure it is.  TODO document error handling, one way or the other.
  $this->{SERVER}->autoflush(1);
  binmode($this->{SERVER});
  return undef;
}

=head2 disconnect_from_server( )

Disconnects from the server

=head4 Parameters

=over

=item * --none--

=item * Returns --none--

=back

=head4 Usage

Disconnection is normally triggered by the other party disconnecting, not by us. disconnect_from_server() is only useful with new_client(), and not otherwise supported.

=cut

sub disconnect_from_server()
{
  my $this=shift;
  $this->log("initiating disconnect");
  $this->_destroy();
  return undef;
}

sub _pause($){
  select undef,undef,undef,shift;
  return undef;
}

sub _message_from_client_to_server(){ # TODO Too many too similar sub names, some of which maybe should be public
  my $this=shift;
  # optional sleep to reduce risk of split messages
  _pause($this->{defrag_delay}) if $this->{defrag_delay};
  # It would be possible to be more agressive by repeatedly waiting until there is a break, but that would probably err too much towards concatenating seperate messages - especially under load.
  my $msg;
  sysread($this->{CLIENT},$msg,10000);
  # (0 length message means connection closed)
  if(length($msg) == 0) { 
    $this->echo("Client disconnected\n");
    $this->_destroy();
    return;
  }
  # Send message to server, if any. Else 'send' to callback function and return result to client.
  if($this->{SERVER}){
    $this->send_to_server($msg);
  }elsif($this->{server_callback}){
    $this->send_to_client( $this->{server_callback}($msg) );
  }else{
    confess "$this->{name}: Did not expect to have neither a connection to a SERVER nor a server_callback";
  }
  return undef;
}

sub _message_from_server_to_client(){ # TODO Too many too similar sub names
  my $this=shift;
# sleep to avoid splitting messages
  _pause($this->{defrag_delay}) if $this->{defrag_delay};
# Read from SERVER and copy to CLIENT
  my $msg = $this->read_from_server();
  if(!defined $msg){
    $this->echo("Server disconnected\n");
    $this->_destroy();
    return;
  }
  $this->send_to_client($msg);
  return undef;
}

sub _cull_child()
{
  my $this=shift or die;
  my $child=shift or die;
  for my $i (0 .. @{$this->{children}}){
    if($child==$this->{children}[$i]){
      $this->echo("Child $child->{name} is done, cleaning it up") if $this->{verbose}>1;
      splice @{$this->{children}}, $i,1;
      return;
    }
  }
  confess "Child $child->{name} is finished, but I can't find it to clean it up";
}

# _main_loop is called by listeners and by their 'leave-home' children both. When called by listeners, it also includes stay at home children

sub _main_loop()
{
  my $this=shift;
  my $last_time;
  my $target_time;
  if($this->{timer_interval}&&$this->{timer_callback}){
    $last_time=time();
    $target_time=$last_time+$this->{timer_interval};
  }
  # Main Loop
  mainloop: while(1)
  {
    # Build file descriptor list for select call 
    my $rin = "";
    if($this->{LISTEN}){
      confess "LISTEN is unexpectedly not a filehandle" if !fileno($this->{LISTEN});
      vec($rin, fileno($this->{LISTEN}), 1) = 1;
    }
    foreach my $each ($this, @{$this->{children}}) {
      vec($rin, fileno($each->{CLIENT}), 1) = 1 if $each->{CLIENT}; # TODO if no client, child should probably be dead
      vec($rin, fileno($each->{SERVER}), 1) = 1 if $each->{SERVER};
    }
    # and listen...
    my $rout = $rin;
    my $delay;
    if($this->{timer_interval}){
      if(time() > $target_time){
	$this->{timer_callback}() or last;
	$last_time=$target_time;
	$target_time+=$this->{timer_interval};
      }
      $delay=$target_time-time();
      $delay=0 if($delay<0);
      $this->echo("delay=$delay") if $this->{verbose} > 1;
    }else{
      $delay=undef;
    }
    select( $rout, "", "", $delay ); 
    if( $this->{LISTEN} && vec($rout,fileno($this->{LISTEN}),1) ) {
      my $child = $this->_spawn_child();
      push @{$this->{children}}, $child if $child;
      next;
    }
    foreach my $each($this, @{$this->{children}}) {
      confess "We have a child with no CLIENT\n" if !$each->{CLIENT} && $each!=$this;
      if($each->{CLIENT} && vec($rout,fileno($each->{CLIENT}),1) ) {
        $each->_message_from_client_to_server(); # TODO Too many too similar sub names
        if(!$each->{CLIENT}){
          # client has disconnected
          if($each==$this){
            # we are the child - OK to exit
            return; #might be better to die or exit at this point instead?
          }else{
            # we are the parent - clean up child and keep going
            $this->_cull_child($each);
            last; # _cull_child impacts the children array - not safe to continue without regenerating rout
          }
        }
      }
      if($each->{SERVER} && vec($rout,fileno($each->{SERVER}),1) ) {
        $each->_message_from_server_to_client(); # TODO Too many too similar sub names
        if(!$each->{SERVER}){
          # client has disconnected
          if($each==$this){
            # we are the child - OK to exit
            return; #might be better to die or exit at this point instead?
          }else{
            $this->_cull_child($each);
            last; # _cull_child impacts the children array - not safe to continue without regenerating rout
          }
        }
      }
    }
  }
  return undef;
}

=head2 hhmmss( )

The default timestamp function - returns localtime in hh:mm:ss format

=head4 Parameters

=over

=item * --none--

=item * Returns - current time in hh:mm:ss format

=back

=head4 Usage

This function is, by default, called when a message is written to the log file.

It may be overridden by calling mydate().

=cut

sub hhmmss()
{
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  return sprintf "%02d:%02d:%02d",$hour,$min,$sec;
}

=head2 mydate( )

Override the standard hh:mm:ss datestamp

=head4 Parameters

=over

=item * datestamp_callback - a reference to a function that returns a datestamp

=item * Returns - a reference to the current or updated callback function

=back

=head4 Usage

For example:

  sub yymmddhhmmss {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    return sprintf "%02d/%02d/%02d %02d:%02d:%02d", 
      $year+1900,$mon+1,$mday,$hour,$min,$sec;
  }
  mydate(\&yymmddhhmmss);

=cut

sub mydate(;$)
{
  my $this=shift;
  my $mydate=shift||undef;
  if(defined $mydate){
    $this->{mydate} = $mydate;
  }
  return $this->{mydate};
}

=head2 listen( )

Listen on local_port and prepare to accept incoming connections

=head4 Parameters

=over

=item * --none--

=item * Return --none--

=back

=head4 Usage

This method is called by go(). It only needs to be called directly if go() is being bypassed for some reason.

=cut

sub listen()
{
  my $this=shift;
  return if $this->{LISTEN};
  $this->echo(sprintf "Server %u listening on port %d (%s)\n",$$,$this->{local_port_num},$this->{parallel}?"parallel":"serial");
  # open tcp/ip socket - see blue camel book pg 349
  socket($this->{LISTEN}, PF_INET, SOCK_STREAM, $protocol) or die "Fatal: Can't create socket: $!";
  bind($this->{LISTEN}, sockaddr_in($this->{local_port_num}, INADDR_ANY)) or die "Fatal: Can't bind socket $this->{local_port_num}: $!";
  listen($this->{LISTEN},1) or die "Fatal: Can't listen to socket: $!";
  $this->echo("Waiting on port $this->{local_port_num}\n");
  return undef;
}

sub _accept($)
{
  # Accept a new connection 
  my $this=shift;
  my $LISTEN=shift;
  my $client_paddr = accept($this->{CLIENT}, $LISTEN); 
  $this->{CLIENT}->autoflush(1);
  binmode($this->{CLIENT});
  my ($client_port, $client_iaddr) = sockaddr_in( $client_paddr );
  $this->log("Connection accepted from", inet_ntoa($client_iaddr).":$client_port\n"); 
  $this->connect_to_server() if $this->{remote_ip_address};
  return undef;
}

sub _new_child(){
  my $parent=shift;
  my $child=_new();
  my $all_good=1;
  foreach my $key (keys %{$parent}){
    if($key=~m/^(LISTEN|children|connections|name|timer_interval|timer_callback)$/){
      # do nothing - these parameters are not inherited
    }elsif($key =~ m/^(parallel|log_file|verbose|mydate|.*callback|(local|remote)_(port_num|ip_address))$/){
      $child->{$key}=$parent->{$key};
    }elsif($key eq "LOGFILE"){
      # TODO might want to have a different logfile for each child, or at least, an option to do so.
      $child->{$key}=$parent->{$key};
    }else{
      warn "internal error - unexpected attribute: $key = {$parent->$key}\n";
      $all_good=0;
    }
  }
  die "Internal error in _new_child()" unless $all_good;
  return bless $child;
}

sub _spawn_child(){
  my $this=shift;
  my $child = $this->_new_child();
  $child->_accept($this->{LISTEN});
  confess "We have a child with no CLIENT\n" if !$child->{CLIENT};
  # hand-off the connection
  $this->echo("starting connection:",++$this->{connections});
  if(!$this->{parallel}){
    return $child;
  }
  my $pid = fork();
  if(!defined $pid){
    # Error
    $this->echo("Cannot fork!: $!\nNew connection will run in the current thread\n");
    return $child;
  }elsif(!$pid){
    # This is the child process
    $child->echo(sprintf"Running %u",$$) if $child->{verbose}>1;
    confess "We have a child with no CLIENT\n" if !$child->{CLIENT};
    # The active instanct of the parent is in a different process
    # Ideally, we would have the parent go out of scope, but all we can do is clean up the bits that matter
    close $this->{LISTEN};
    $child->_main_loop();
    $child->echo(sprintf"Exiting %u",$$) if $child->{verbose}>1;
    exit;
  }else{
    # This is the parent process.  The active child instance is in its own process, we clean up what we can
    $child->_destroy();
    return undef;
  }
}

sub go()
{
  my $this=shift;
  $this->listen();
  $this->_main_loop();
  return undef;
}

sub _destroy()
{
  my $this=shift;
  close $this->{CLIENT} if($this->{CLIENT});
  close $this->{SERVER} if($this->{SERVER});
  $this->{SERVER}=$this->{CLIENT}=undef;
  return undef;
}

=head1 Exports

MitM does not export any functions or variables.  
If parallel() is turned on, which by default it is not, MitM sets SIGCHD to IGNORE, and as advertised, it calls fork() once for each new connection.

=head1 AUTHOR

Ben AVELING, C<< <ben dot aveling at optusnet dot com dot au> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-NET-MitM at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=NET-MitM>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc NET::MitM

You can also look for information at:

=over

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=NET-MitM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/NET-MitM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/NET-MitM>

=item * Search CPAN

L<http://search.cpan.org/dist/NET-MitM/>

=back

=head1 ACKNOWLEDGEMENTS

I'd like to acknowledge W. Richard Steven's and his fantastic introduction to TCPIP: "TCP/IP Illustrated, Volume 1: The Protocols", Addison-Wesley, 1994. (L<http://www.kohala.com/start/tcpipiv1.html>). 
It got me started. Recommend. RIP.
The Blue Camel Book is also pretty useful, and Langworth & chromatic's "Perl Testing, A Developer's Notebook" is also worth a hat tip.

=head1 ALTERNATIVES

If what you want is a pure proxy, especially if you want an ssh proxy or support for firewalls, you might want to evaluate Philippe "BooK" Bruhat's L<Net::Proxy>.

And if you want a full "portable multitasking and networking framework for any event loop", you may be looking for L<POE>.

=head1 LICENSE AND COPYRIGHT

Copyleft 2013 Ben AVELING.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, have, hold and cherish,
use, offer to use, sell, offer to sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. SO THERE.

=cut

1; # End of NET::MitM
