#!/usr/bin/perl

package NetServer::Generic;

use Carp;
use Data::Dumper;
use Exporter;
use Fcntl;
use IO::File;
use IO::Socket;
use IO::Handle;
use IO::Select;
use IO::Pipe;
use POSIX qw(mkfifo BUFSIZ EWOULDBLOCK WNOHANG);
use Socket;
use Time::HiRes qw(gettimeofday tv_interval);
use Tie::RefHash;

BEGIN {
    if  (! eval "require Thread") {
        # want warnings? uncomment the next line
        # warn "Could not import Thread.pm: $@\n";
	$MAIN::no_thread = 1;
    } else {
        Thread->import();
    }
}

@ISA = (qw(NetServer));

$VERSION = "1.03";

use strict;


=pod

=head1 NAME

Server - generic TCP/IP server class

=head1 SYNOPSIS

  my $server_cb = sub  {
                         my ($s) = shift ;
                         print STDOUT "Echo server: type bye to quit, exit ",
                                      "to kill the server.\n\n" ;
                         while (defined ($tmp = <STDIN>)) {
                             return if ($tmp =~ /^bye/i);
                             $s->quit() if ($tmp =~ /^exit/i);
                             print STDOUT "You said:>$tmp\n";
                       }                            
  my ($foo) = new NetServer::Generic;
  $foo->port(9000);
  $foo->callback($server_cb);
  $foo->mode("forking");
  print "Starting server\n";
  $foo->run();

=head1 DESCRIPTION

C<NetServer::Generic> provides a (very) simple server daemon for TCP/IP
processes. It is intended to free the programmer from having to think
too hard about networking issues so that they can concentrate on 
doing something useful.

The C<NetServer::Generic> object accepts the following methods, which 
configure various aspects of the new server:

=over 4

=item port

The port to listen on.

=item hostname

The local address to bind to. If no address is specified, listens for
any connection on the designated port.

=item listen

Queue size for listen.

=item proto

Protocol we're listening to (defaults to tcp)

=item timeout

Timeout value (see L<IO::Socket::INET>)

=item allowed

list of IP addresses or hostnames that are explicitly allowed to connect
to the server. If empty, the default policy is to allow connections from
anyone not in the 'forbidden' list.

NOTE: IP addresses or hostnames may be specified as perl regular
expressions; for example 154\.153\.4\..* matches any IP address
beginning with '154.153.4.';
.*antipope\.org matches any hostname in the antipope.org domain.

=item forbidden

list of IP addresses or hostnames that are refused permission to
connect to the server. If empty, the default policy is to refuse
connections from anyone not in the 'allowed' list (unless the
allowed list is empty, in which case anyone may connect).

=item callback

Coderef to a subroutine which handles incoming connections (called
with one parameter -- a C<NetServer::Generic> object which can be used 
to shut down the session).

=item mode

Can be one of B<forking>, B<select>, B<select_fast>, B<client>, 
B<threaded>, or B<prefork>.

By default, B<forking> mode is selected.

B<forking> mode is selected, the server handles requests by forking a
child process to service them. If B<select> mode is selected, the server
uses the C<IO::Select> class to implement a simple non-forking server.

The select-based server may block on i/o on a heavily-loaded system. If
you need to do non-blocking i/o you should look at NetServer::FastSelect.

The B<client> mode is special; it indicates that rather than sitting
around waiting for an incoming connection, the server is itself a
TCP/IP client. In client mode, C<hostname> is the B<remote> host to
connect to and C<port> is the remote port to open. The callback
routine is used, as elsewhere, but it should be written as for a
client -- i.e. it should issue a request or command, then read.
An additional method exists for client mode: C<trigger>. C<trigger>
expects a coderef as a parameter. This coderef is executed
before the client-mode server spawns a child; if it returns a non-zero
value the child is forked and opens a client connection to the target
host, otherwise the server exits. The trigger method may be used to
sleep for a random interval then return 1 (so that repeated clients
are spawned at random intervals), or fork several children (on a one-
time-only basis) then work as above (so that several clients poke at
the target server on a random basis). The default trigger method 
returns 1 immediately the first time it is called, then returns 0 --
this means that the client makes a single connection to the target
host, invokes the callback routine, then exits. (See the test examples
which come with this module for examples of how to use client mode.) 

Note that client mode relies on the fork() system call.

The B<threaded> mode indicates that multithreading will be used to
service requests. This feature requires Perl 5.005 or higher and a
native threads library to run, so it's not 100% portable). Moreover,
it's unreliable! Don't use this mode unless you're prepared to do some
debugging.

The B<prefork> mode indicates that the server will bind to the
designated port, then fork repeatedly up to C<$start_servers> times
(where C<start_servers> is a scalar parameter to C<NetServer::Generic>).
Each child then enters a select-based loop. (i.e. run_select), but exits
after handling C<$server_lifespan> transactions (where C<server_lifespan>
is another parameter to C<NetServer::Generic>).  Every time a child
handles a transaction it writes its PID and generation number down a pipe
to the parent process, with a message when it exits.  The parent keeps
track of how many servers are in use and fires up extra children (up to
C<$max_servers>) if the number in use leaves less than C<$min_spare_servers>
free. See the example B<preforked-shttpd> for a minimal HTTP 0.9 server
implemented using the B<prefork> mode.


=back

Of these, the C<callback> method is most important; it specifies
a reference to a subroutine which effectively does whatever the
server does.

A callback subroutine is a normal Perl subroutine. It is invoked
with STDIN and STDOUT attached to an C<IO::Socket::INET> object,
so that reads from STDIN get information from the client, and writes
to STDOUT send information to the client. Note that both STDIN and
STDOUT are unbuffered. In addition, a C<NetServer::Generic> object is 
passed as an argument (but the C<callback> is free to ignore it).

Your server reads and writes data via the socket as if it is the
standard input and standard output filehandles; for example:

  while (defined ($tmp = <STDIN>)) {  # read a line from the socket

  print STDOUT "You said: $tmp\n";    # print something to the socket

(See C<IO::Handle> and C<IO::Socket> for more information on this.)

If you're not familiar with sockets, don't get too fresh and try to 
close or seek on STDIN or STDOUT; just treat them like a file.

The server object is not strictly necessary in the callback, but comes
in handy: you can shut down the server completely by calling the 
C<quit()> method.
 
When writing a callback subroutine, remember to define some condition under 
which you return! 

Here's a slightly more complex server example:


 # minimal http server (HTTP/0.9):
 # this is a REALLY minimal HTTP server. It only understands GET
 # requests, does no header parsing whatsoever, and doesn't understand
 # relative addresses! Nor does it understand CGI scripts. And it ain't
 # suitable as a replacement for Apache (at least, not any time soon :).
 # The base directory for the server and the default
 # file name are defined in B<url_to_file()>, which maps URLs to
 # absolute pathnames. The server code itself is defined in the
 # closure B<$http>, which shows how simple it is to write a server
 # using this module.

 sub url_to_file($) {
   # for a given URL, turn it into an absolute pathname
   my ($u) = shift ;  # incoming URL fragment from GET request
   my ($f) = "";      # file pathname to return
   my ($htbase) = "/usr/local/etc/httpd/docs/";
   my ($htdefault) = "index.html";
   chop $u;
   if ($u eq "/") {
       $f = $htbase . $htdefault;
       return $f;
   } else {
       if ($u =~ m|^/.+|) {
           $f = $htbase;  chop $f;
           $f .= $u;
       } elsif ($u =~ m|[^/]+|) {
           $f = $htbase . $u;
       }
       if ($u =~ m|.+/$|) {
           $f .= $htdefault;
       }
       if ($f =~ /\.\./) {
           my (@path) = split("/", $f);
           my ($buff, $acc) = "";
           shift @path;
           while ($buff = shift @path) {
               my ($tmp) = shift @path;
               if ($tmp ne '..') {
                   unshift @path, $tmp;
                   $acc .= "/$buff";
               }
           }
           $f = $acc;
       }
   }
   return $f;
 }

 my ($http) = sub {
    my ($fh) = shift ;
    while (defined ($tmp = <STDIN>)) {
        chomp $tmp;
        if ($tmp =~ /^GET\s+(.*)$/i) {
            $getfile = $1;
            $getfile = url_to_file($getfile);
            print STDERR "Sending $getfile\n";
            my ($in) = new IO::File();
            if ($in->open("<$getfile") ) {
                $in->autoflush(1);
                print STDOUT "Content-type: text/html\n\n";
                while (defined ($line = <$in>)) {
                    print STDOUT $line;
                }
            } else {
                print STDOUT "404: File not found\n\n";
            }
        }
        return 0;
    }
 };                           

 # main program starts here

 my (%config) =  ("port"     => 9000, 
                  "callback" => $http, 
                  "hostname" => "public.antipope.org");

 my ($allowed) = ['.*antipope\.org', 
                  '.*localhost.*'];

 my ($forbidden) = [ '194\.205\.10\.2'];

 my ($foo) = new Server(%config); # create new http server bound to port 
                                  # 9000 of public.antipope.org
 $foo->allowed($allowed);         # who is allowed to connect to us
 $foo->forbidden($forbidden);     # who is refused access
 print "Starting http server on port 9000\n";
 $foo->run();                     
 exit 0;


=head2 Additional methods

C<NetServer::Generic> provides a couple of extra methods.

=over 4

=item peer()

The B<peer()> method returns a reference to a two-element list containing 
the hostname and IP address of the host at the other end of the socket.
If called before a connection has been received, its value will be undefined.
(Don't try to assign values via B<peer> unless you want to confuse the 
allowed/forbidden checking code!)

=item quit()

The B<quit()> method attempts to shut down a server. If running as a forking
service, it does so by sending a kill -15 to the parent process. If running
as a select-based service it returns from B<run()>.

=item start_servers()

In B<prefork> mode, specifies how many child servers to start up.

=item max_servers()

In B<prefork> mode, specifies the maximum number of children to spawn
under load.

=item min_spare_servers()

In B<prefork> mode, specifies a number of spare (inactive) child
servers; if we drop below this level (due to load), the parent will spawn
additional children (up to a maximum of B<max_servers>) until we go back
over B<min_spare_servers>.

=item server_lifespan()

In B<prefork> server mode, child servers run as select servers. After
B<server_lifespan> connections they will commit suicide and be replaced by
the parent. If B<server_lifespan> is set to 1, children will effectively
run once then exit (like a forking server). For purposes of insanity,
a lifespan of 0 is treated like a lifespan of 1.

=item servername()

In the B<prefork> server, unless you I<explicitly> tell the server to bind
to a named host, it will accept all incoming connections. Within a client, 
you may need to know what local IP address an incoming connection was 
intended for. The C<servername()> method can be invoked within the child
server's callback and returns a two-element arrayref containing the port
and IP address that the connection came in on. For example, in the client:

  my $callback = sub {
    my $server = shift;
    my ($server_port, $server_addr) = @{ $server->servername() };
    print "Connection on $server_addr:$server_port\n";


=back

=head2 Types of server

A full discussion of internet servers is well beyond the scope of this man
page. Beginners may want to start with a source like L<Beginning Linux 
Programming> (which provides a simple, lucid discussion); more advanced
readers may find Stevens' L<Advanced Programming in the UNIX environment>
useful.

In general, on non-threaded systems, a forking server is slightly less
efficient than a select-based server (and uses up lots of PIDs). On the other
hand, a select-based server is not a good solution to high workloads or
time-consuming processes such as providing an NNTP news feed to an online
newsreader.

A major issue with the select-based server code in this release is that
the IO::Select based server cannot know that a socket is ready until some 
data is received over it. (It calls B<can_read()> to detect sockets waiting
to be read from.) Thus, it is not suitable for writing servers like
which emit status information without first reading a request.


=head1 SEE ALSO

L<IO::Handle>,
L<IO::Socket>,
L<LWP>,
L<perlfunc>,
L<perlop/"I/O Operators">

=head1 BUGS

There are two bugs lurking in NetServer::Generic. Or maybe they're 
design flaws. I don't have time to fix them right now, but maybe
you'd like to contribute an hour or two and get your name in the
credits?

Bug the first:

NetServer::Generic attempts to make it easy to write a server by letting
the programmer concentrate on reading from STDIN and writing to STDOUT.
However, this form of i/o is line oriented.  NetServer::Generic relies
on the buffering and i/o capabilities provided by Perl and IO::Socket
respectively. It doesn't buffer its own input.

This means that in principle a malicious attacker (or just a badly-
written client program) can write a stream of bytes to a
NetServer::Generic application and, as long as those bytes don't
include a "\n", Perl will keep gobbling it up until it runs out of
virtual memory.

This can be fixed by replacing the globbed IO::Socket::INET that is
attached to STDIN with something else -- probably an object that presents
itself as an IO::Stringy but that does its own buffering, so that it
will return I<either> a line, or some sort of error message in $! if
it sees something undigestible in its input stream. (If anyone wants
to contribute a patch that fixes this, please feel free; this is an open
source project, after all ...)

Bug the second:

The select-based server was originally written because I wanted to
share state information between some forking servers and I couldn't
use System V shared memory (the application had to be portable to a 
flavour of UNIX that didn't support it). 

It works okay, up to a point, but under heavy load on Linux it can run
into major problems. Partly this may be attributable to deficiencies
in the way Linux handles the select() system call (or so Stephen
Tweedie keeps telling me), but the result is that the select-based
server tends to drop some connections when it's under stress: if 
two connections come in while it's serving another, the first may
never get processed before a timeout occurs.

A somewhat worse problem is that IO::Select doesn't do buffered (line-
oriented) input; it just checks to see if one or more bytes are
waiting to be read from one of the file handles it's got hold of. It
is possible for a couple of bytes to come in (but not a whole line),
so that the select-based server merrily tries to process a transaction
and blocks until the rest of the input arrives -- thus ensuring that
the server is bottlenecked by the speed of the slowest client connection.

Suggestion: if you need to serve lots of connections using select(),
look at the eventserver module instead. If you're a bit more
ambitious, the defect in NetServer::Generic is fixable by writing a
module with a similar API to IO::Select, but which provides buffering
for the file handles under its control and which only returns
something in response to can_read() when one of the buffers has a 
complete line of input waiting.

=head1 AUTHOR

Charlie Stross (charle@antipope.org). With thanks for bugfixes and
patches to Marius Kjeldahl I<marius@ace.funcom.com>, Art Sackett 
I<asackett@artsackett.com>, Claudio Garcia I<cgarcia@dbitech.com>,
Claudio Calvelli I<lunatic@assurdo.com>, Martin Waite
I<Martin.Waite@montgomery134.freeserve.co.uk>. Debian package
contributed by Jon Middleton, I<jjm@datacash.com>.

=head1 HISTORY

=over 4

=item Version 0.1 

Based on the simple forking server in Chapter 10 of "Advanced Perl 
Programming" by Sriram Srinivasan, with a modular wrapper to make 
it easy to use and configure, and a rudimentary access control system.

=item Version 0.2

Added the B<peer()> method to provide peer information.

Bugfix to B<ok_to_serve> from Marius Kjeldahl I<marius@ace.funcom.com>.

Added select-based server code, B<mode> method to switch between forking
and selection server modes.

Updated test code (should do something now!)

Added example: fortune server and client code.

Supports NetServer::SMTP (and, internally, NetServer::vTID).

=item Version 0.3

fixed test failure.

=item Version 1.0

Added alpha-ish prefork server mode.

Added alpha-ish multithreaded mode (UNSTABLE)

Modified IP address filtering to cope with regexps 
(suggested by Art Sackett I<asackett@artsackett.com>)

Modified select() server to do non-blocking writes via a

Non-blocking-socket class tied to STDIN/STDOUT

Option to log new connection peer addresses via STDERR

Extra test scripts

Updated documentation                                                 

=item 1.01

Fix so it works on installations with no threading support (duh). Tested
on Solaris, too.

=item 1.02

Bugfixes to the preforked mode (thanks to Art Sackett for detecting
them). Bugfix to ok_to_serve() (thanks to Claudio Garcia,
cgarcia@dbitech.com). Some notes on the two known bugs (related
to buffering).

=item 1.03

Signal handling code was fixed to avoid leaving zombie processes
(thanks to Luis Munoz, lem@cantv.net)

=back


=cut

# NetServer::FieldTypes contains a hash of autoload method names, and the 
# type of parameter they expect. For example, NetServer->callback() takes
# a coderef as a parameter; AUTOLOAD needs to know this so it can whine
# about incorrect parameter types.

$NetServer::FieldTypes = {
                         "port"              => "scalar",
                         "callback"          => "code",
                         "listen"            => "scalar",
                         "proto"             => "scalar",
                         "hostname"          => "scalar",
                         "timeout"           => "scalar",
                         "root_pid"          => "scalar",
                         "allowed"           => "array",
                         "forbidden"         => "array",
                         "peer"              => "array",
                         "mode"              => "scalar",
                         "trigger"           => "code",
                         "sock"              => "IO::Socket::INET",
                         "tags"              => "hash",
                         "my_age"            => "scalar",
                         "start_servers"     => "scalar",
                         "min_spare_servers" => "scalar",
                         "max_servers"       => "scalar",
                         "server_lifespan"   => "scalar",
                         "fifo"              => "scalar",
                         "read_pipe"         => "scalar",
                         "write_pipe"        => "scalar",
                         "handle"            => "IO::File",
                         "scoreboard"        => "hash",
                         "servername"        => "array",
                         "parent_callback"   => "code",
                         "ante_parent_callback"   => "code",
                      };

# $NetServer::Debug; if non-zero, emit some debugging info on STDERR

$NetServer::Debug = 0;

# here is a default callback routine. It basically echoes back anything
# you sent to the server, unless the line begins with quit, bye, or
# exit -- in which case it kills the server (rather than simply exiting).

$NetServer::default_cb = sub  {
                             my ($s) = shift;
                             my ($tmp) = "";
                             print STDOUT "Echo server: type bye to quit, ",
                                          "exit to kill the server.\n\n" ;
                             while (defined ($tmp = <STDIN>)) {
                                 return if ($tmp =~ /^bye/i);
                                 $s->quit() if ($tmp =~ /^exit/i);
                                 print STDOUT "You said:>$tmp\n";
                             }                            
                          };
# Methods

sub new {
    $NetServer::Debug && print STDERR "[", join("][", @_), "]\n";
    my ($class) = shift if @_;
    my ($self) = {"listen" => 5,
                  "timeout" => 60,
                  "hostname" => "localhost",
                  "proto" => "tcp",
                  "callback" => $NetServer::default_cb,
                  "version" => $NetServer::Generic::VERSION,
                 };
    $self->{tags} = $NetServer::FieldTypes;
    bless $self, ($class or "Server");
    if (@_) {
        my (%tmp) = @_; my ($field) = "";
        foreach $field (keys %tmp) {
            $self->$field($tmp{$field});
        }
    }
    return $self;
}

sub VERSION {
    my $self = shift;
    return $self->{version};
}

sub run_prefork {
    my $self = shift;
    # get preforking parameters or adopt sensible default values
    my $start_servers   = ($self->start_servers()     or 5    );
    my $spare_servers   = ($self->min_spare_servers() or 1    );
    my $max_servers     = ($self->max_servers()       or 10   );
    my $server_lifespan = ($self->server_lifespan()   or 1000 );

    # Create socket and bind, then Fork repeatedly up to $start_servers times.
    # Once in each child, do a select-based loop. i.e. run_select, but exit 
    # after handling $server_lifespan transactions. 
    # Every time we do a task we write our PID and generation number down a 
    # pipe to the parent process, with a message when we exit.
    #
    # In the parent, keep track of how many servers are in use 
    #   and fire up extra children (up to $max_servers) if the number in
    #   use leaves less than $spare_servers free.
    my %init =  (
                  LocalPort => $self->port(),
                  Listen    => $self->listen(),
                  Proto     => $self->proto(),
                  Reuse     => 1
                );
    if ($self->hostname() ne "") {
         $init{LocalAddr} = $self->hostname();
    }
    my ($main_sock) = new IO::Socket::INET(%init);
    if (! $main_sock) {
        print STDERR "$$:run_select(): could not create socket: $!\n";
        exit 0;
    }
    $self->sock($main_sock);
    $NetServer::Debug && print STDERR 
          "Created socket(port => ", $self->port(), "\n",
          " " x 15, "hostname => ", $self->hostname(), ")\n";
    my $scoreboard = {}; 
    $self->scoreboard($scoreboard);
    # set up named pipe -- children will write, parent will read
    #my $fifo = $self->_new_fifo();
    #$self->fifo($fifo);
    # switch to using a pipe instead
    pipe(READ_PIPE, WRITE_PIPE);
    $self->{read_pipe} = *READ_PIPE;
    $self->{write_pipe} = *WRITE_PIPE;
    $self->root_pid($$);  # set server root PID
    # now create lots of spawn
    for (my $i = 0; $i < $start_servers; $i++) {
        my $pid = fork();
        die "Cannot fork: $!\n" unless defined ($pid);
        if ($pid == 0) {
            # child
            $self->_do_preforked_child();
            $NetServer::Debug && print STDERR "$0:$$: end of transaction\n";
            exit 0;
        } else {
            # parent
            $scoreboard->{$pid} = "idle";
            $NetServer::Debug && print STDERR "$0:$$: forked $pid\n";
        }
    }
    # we have no forked $start_servers children that are 
    # in _do_preforked_child().
    $self->scoreboard($scoreboard);
    $self->_do_preforked_parent();
    return;
}

sub reap_child {
    do {} while waitpid(-1, WNOHANG) > 0;
}

sub _do_preforked_parent {
    my $self = shift;
    # we are a parent process to a bunch of raucous kiddies. We have an 
    # IO::Pipe called $self->reader() that we read status from and stick 
    # in a scoreboard. As processes die, we replace them. As the scoreboard 
    # fills up, we add extra  servers. NB: when we fork, we replicate 
    # self->reader() and self->writer().

    my $n = "_do_preforked_adult($$)"; # for reporting status
    my $start_servers   = ( $self->start_servers()     or 5     );
    my $spare_servers   = ( $self->min_spare_servers() or 1     );
    my $max_servers     = ( $self->max_servers()       or 10    );
    my $scoreboard      = ( $self->scoreboard()        or {}    );
    $SIG{CHLD} = \&reap_child;
    my @buffer = ();
    my $buffer = "";
    $NetServer::Debug && print STDERR "$n: About to loop on scoreboard file\n";
    my $loopcnt = 0;
    my $busycnt = 0;
    my @busyvec = ();
    #while(@buffer = $self->_read_fifo()) {
    *READ_PIPE = $self->read_pipe();
    while($buffer = <READ_PIPE>) {
        $NetServer::Debug 
           && print STDERR "busyvec: [", join("][", @busyvec), "]\n";
        $loopcnt++;
        $NetServer::Debug 
            && print STDERR "$n: in pipe read loop $loopcnt\n";
        $buffer =~ tr/ //;
        chomp $buffer;
        $NetServer::Debug 
            && print STDERR "$n: buffer: $buffer\n";
        my ($child_pid, $status) = split(/:/, $buffer);
        # kids write $$:busy or $$:idle into the pipe whenever 
        # they change state.
        if ($status eq "exit") {
            # a child just exited on us
            $NetServer::Debug 
               && print STDERR "$n: child $child_pid just died\n";
            delete($scoreboard->{$child_pid});
        } elsif ($status eq "busy") {
            $scoreboard->{$child_pid} = "busy";
            push(@busyvec, $child_pid);
            $busycnt++;
        } elsif ($status eq "idle") {
            $scoreboard->{$child_pid} = "idle";
            @busyvec = grep(!/$child_pid/, @busyvec);
            $busycnt--;
        } elsif ($status eq "start") {
            $scoreboard->{$child_pid} = "idle";
        }
        $NetServer::Debug && print STDERR "$n: $child_pid has status [",
                             $scoreboard->{$child_pid}, "]\n",
                             "$n: got ", scalar(@busyvec), " busy kids\n";
        $busycnt = scalar(@busyvec);
        my $all_kids  = scalar keys %$scoreboard;
        $NetServer::Debug && 
            print STDERR "$n: $busycnt children busy of $all_kids total\n";
        # busy_kids is number of kids currently busy; all_kids is number of kids
        if ((($all_kids - $busycnt) < $spare_servers) and 
            ($all_kids <= $max_servers)) {
            my $kids_to_launch = ($spare_servers - ($all_kids - $busycnt)) +1;
            $NetServer::Debug && 
                 print STDERR "spare servers: $spare_servers, ",
                         "all kids: $all_kids, ",
                         "busycnt: $busycnt\n", 
                         "kids to launch = spares - (all - busy) +1 ",
                         " => $kids_to_launch\n";
                         
            # launch new children
            for (my ($i) = 0; $i < $kids_to_launch; $i++) {
                my $pid = fork();
                if ($pid == 0) {
                    # new child
                    $NetServer::Debug && 
                        print STDERR "spawned child\n";
                    $self->_do_preforked_child();
                    exit 0;
                } else {
                    # parent
                    $NetServer::Debug && print STDERR  
                         "$n: spawned new child $pid\n";
                    $scoreboard->{$pid} = "idle";
                }
            }
        } # end of child launch cycle
        $NetServer::Debug 
            && print STDERR "$n: scoreboard: \n", Dumper $scoreboard;
    } 
    print STDERR "exited getline loop\n";
}

sub _do_preforked_child {
    my $self = shift;
    # we are a preforked child process. We have an IO::Pipe called 
    # $self->writer() that we write strange things to. Each "strange thing" 
    # consists of a line containing our PID, a colon, and one of three strings:
    # busy, idle, or exit.  We run like a run_select server, except that we 
    # write a busy line whenever we accept a connection, an idle line whenever 
    # we finish handling a connection, and an exit line when our age exceeds 
    # $self->server_lifespan() and we suicide.
    #
    my $n = "_do_preforked_child($$)"; # for reporting status
    my $server_lifespan = ( $self->server_lifespan() or 1000  );
    my $my_age          = ( $self->my_age()          or 0     );
    my $main_sock       = $self->sock();
    my $LOCK_SH = 1;
    my $LOCK_EX = 2;
    my $LOCK_NB = 4;
    my $LOCK_UN = 8;
    my $rh              = new IO::Select($main_sock);
    $NetServer::Debug && print STDERR "$n: Created IO::Select()\n";
    *WRITE_PIPE = $self->{write_pipe};
    $NetServer::Debug 
        && print WRITE_PIPE "$$:start\n";
    my (@ready, @err) = ();
    $NetServer::Debug 
        && print STDERR "$n: about to call IO::Select->can_read()\n";
    SELECT:
    while (@ready = $rh->can_read() or @err = $rh->has_error(0)) { 
        if (scalar(@err) > 0) {
            foreach my $s (@err) {
                if ($NetServer::Debug > 0) {
                    print STDERR "Sock err: ", $s->error(), "\n";
                }
                if ($s->eof()) {
                    $rh->remove($s);
                    $s->close();
                } else {
                    $s->clearerr();
                }
            }
            @err = ();
            next SELECT;
        }
        $NetServer::Debug && print STDERR "$n: got a connection\n";
        foreach my $sock (@ready) {
            $NetServer::Debug && print STDERR "$n: got a socket\n";
            if ($sock == $main_sock) {
                flock($sock, $LOCK_EX) or do {
                    print STDERR "+++ flock LOCK_EX failed on parent socket: ",
                                 "$!\n";
                };
                my ($new_sock) = $sock->accept();
                flock $sock, $LOCK_UN;
                $new_sock->autoflush(1);
                $rh->add($new_sock);
                if (! $self->ok_to_serve($new_sock)) {
                    $rh->remove($sock);
                    close($sock);
                }
            } else {
                if (! eof($sock)) {
                    $my_age++;
                    $NetServer::Debug 
                       && print STDERR "$n: print WRITE_PIPE ($$:busy)\n";
                    print WRITE_PIPE "$$:busy\n";
                    $NetServer::Debug 
                       && print STDERR "$n: serving connection\n";
                    $sock->autoflush(1);
                    my ($in_port, $in_addr) = sockaddr_in($sock->sockname());
                    $self->servername([$in_port, $in_addr]);
                    my ($code) = $self->callback();
                    $self->sock($sock);
                    *OLD_STDIN = *STDIN;
                    *OLD_STDOUT = *STDOUT;
                    *STDIN = $sock;
                    *STDOUT = $sock;
                    select STDIN; $| = 1;
                    select STDOUT; $| = 1;
                    &$code($self);
                    *STDIN = *OLD_STDIN;
                    *STDOUT = *OLD_STDOUT;
                    $NetServer::Debug && do { 
                            print STDERR "$n: print WRITE_PIPE $$:idle\n",
                                         "$n: served $my_age calls\n";
                    };                
                    print WRITE_PIPE "$$:idle\n$$:idle\n";
                    $rh->remove($sock);
                    close $sock;
                } else {
                    $rh->remove($sock);
                    close($sock);
                }
            }
        }
        $NetServer::Debug && print STDERR "$n: checking age $my_age ",
                                          "against lifespan $server_lifespan\n";
        if ($my_age >= $server_lifespan) {
            $NetServer::Debug 
                && print STDERR "$n: time to live exceeded\n",
                                "$n: print WRITE_PIPE $$:exit\n";
            #$self->_write_fifo("$$:exit\n");
            print WRITE_PIPE "$$:exit\n";
            exit 0;
        }
    }
    $NetServer::Debug 
        && print STDERR "Warning! Should never reach this point:",
                        join("\n", caller()), "\n";
    print WRITE_PIPE "$$:exit\n";
    exit 0;
}


sub run_select {
    my $self = shift;
    my ($main_sock) = 
        new IO::Socket::INET( # LocalAddr => $self->hostname(),
                              LocalPort => $self->port(),
                              Listen    => $self->listen(),
                              Proto     => $self->proto(),
                              Reuse     => 1
                            );
    # die "$$:run_select(): could not create socket: $!\n" unless ($main_sock);
    if (! $main_sock) {
        print STDERR "$$:run_select(): could not create socket: $!\n";
        exit 0;
    }
    $NetServer::Debug && print STDERR "Created socket\n";
    my $rh = new IO::Select($main_sock);
    $NetServer::Debug && print STDERR "Created IO::Select()\n";
    my (@ready) = ();
    while (@ready = $rh->can_read() ) {
        $NetServer::Debug && print STDERR 
                     "NetServer::Generic::run_select(): got ",  
                     scalar(@ready), " handles at ", 
                     scalar(localtime(time)), "\n";
        my ($sock) = "";
        foreach $sock (@ready) {
            if ($sock == $main_sock) {
                my ($new_sock) = $sock->accept();
                $new_sock->autoflush(1);
                $rh->add($new_sock);
                if (! $self->ok_to_serve($new_sock)) {
                    $rh->remove($sock);
                    close($sock);
                }
            } else {
                if (! eof($sock)) {
                    $sock->autoflush(1);
                    my ($code) = $self->callback();
                    $self->sock($sock);
                    *STDIN = $sock;
                    *STDOUT = $sock;
                    select STDIN; $| = 1;
                    select STDOUT; $| = 1;
                    &$code($self);
                    $rh->remove($sock);
                    close $sock;
                    # shutdown($sock, 2);
                } else {
                    $rh->remove($sock);
                    close($sock);
                }
            }
        }
    }
}

sub run_thread {
    # first pass at multithreaded execution -- as for fork() except we use 
    # threads. This is ugly -- may want to bodge it up to see if the 
    # run_select_fast method is a better model?
    my ($self) = shift ;
    if ($MAIN::no_thread == 1) {
        warn "Warning: Threading not supported!\n";
	return;
    }
    my %init =  (
                  LocalPort => $self->port(),
                  Listen    => $self->listen(),
                  Proto     => $self->proto(),
                  Reuse     => 1
                );
    if ($self->hostname() ne "") {
         $init{LocalAddr} = $self->hostname();
    }
    my ($main_sock) = new IO::Socket::INET(%init);
    
    die "Socket could not be created: $!\n" unless ($main_sock);

    # we need to trap SIGKILL and SIGINT. If no traps are already
    # defined by the user, add some default ones.
    if (! exists $SIG{INT}) {
       $SIG{INT} = sub { 
                          print STDERR "\nSIGINT: server $$ ",
                                       "shutting down \n"; 
                          exit 0;
                       };
    }
    # and make sure we wait() on children

    # now loop, forking whenever a new connection arrives on the listener

  $NetServer::Debug && print STDERR "Created socket\n";
    my $rh = new IO::Select($main_sock);
  $NetServer::Debug && print STDERR "Created IO::Select()\n";
    my (@ready) = ();
    while (@ready = $rh->can_read()) {
        $NetServer::Debug && print STDERR 
            "NetServer::Generic::run_select(): got ",  
            scalar(@ready), " handles at ", scalar(localtime(time)), "\n";
        my ($sock) = "";
        foreach $sock (@ready) {
            if ($sock == $main_sock) {
                my ($new_sock) = $sock->accept();
                $new_sock->autoflush(1);
                $rh->add($new_sock);
                if (! $self->ok_to_serve($new_sock)) {
                    $rh->remove($sock);
                    close($sock);
                }
            } else {
                if (! eof($sock)) {
                    $sock->autoflush(1);
                    my ($code) = $self->callback();
                    $self->sock($sock);
                    *STDIN = $sock;
                    *STDOUT = $sock;
                    select STDIN; $| = 1;
                    select STDOUT; $| = 1;
                    my $t = new Thread &$code($self) ;
                    $t->detach();
                    #&$code($self);
                    $rh->remove($sock);
                    close $sock;
                    # shutdown($sock, 2);
                } else {
                    $rh->remove($sock);
                    close($sock);
                }
            }
        }
    }
}

sub _thread {
    # handle socket setup inside a thread
    # args: IO::Socket::INET object, NetServer::Generic object
    my $sock = shift;
    my $self = shift;
print STDERR "self is a ", (ref($self) or " kangaroo "), "\n";
    if ($self->ok_to_serve($sock)) {
        $sock->autoflush(1);
        my ($code) = $self->callback();
        *STDIN = $sock;
        *STDOUT = $sock;
        select STDIN; $| = 1;
        select STDOUT; $| = 1;
        $self->sock($sock);
        &$code($self);
    }
    shutdown($sock, 2);
    return;
}

sub run_fork {
    my ($self) = shift ;
    my %init =  (
                  LocalPort => $self->port(),
                  Listen    => $self->listen(),
                  Proto     => $self->proto(),
                  Reuse     => 1
                );
    if ($self->hostname() ne "") {
         $init{LocalAddr} = $self->hostname();
    }
    my ($main_sock) = new IO::Socket::INET(%init);

    die "Socket could not be created: $!\n" unless ($main_sock);


    # we need to trap SIGKILL and SIGINT. If no traps are already
    # defined by the user, add some default ones.
    if (! exists $SIG{INT}) {
       $SIG{INT} = sub { 
                          print STDERR "\nSIGINT: server $$ ",
                                       "shutting down \n"; 
                          exit 0;
                       };
    }
    # and make sure we wait() on children
    $SIG{CHLD} = \&reap_child;
    my $parent_callback = $self->parent_callback();
    my $ante_fork_callback = $self->ante_fork_callback();                       

    # now loop, forking whenever a new connection arrives on the listener
    $self->root_pid($$);  # set server root PID
    while (my ($new_sock) = $main_sock->accept()) {
        &$ante_fork_callback($self) if ( defined $ante_fork_callback );
        my $x_time = [ gettimeofday ]; # millisecond timer to track duration
        my $pid = fork();
        die "Cannot fork: $!\n" unless defined ($pid);
        if ($pid == 0) {
            # child
            if ($NetServer::Debug != 0) { 
                my ($peeraddr) = join(".", unpack("C4", $new_sock->peeraddr()));
                print STDERR "$$ : ", scalar(localtime(time)), " : ", 
                             "incoming connection from $peeraddr\n";
            }
            if ($self->ok_to_serve($new_sock)) {
                $NetServer::Debug 
                    && print STDERR $$, " : ", scalar(localtime(time)), " : ", 
                                    "processing connection\n";
                $new_sock->autoflush(1);
                my ($code) = $self->callback();
                *STDIN = $new_sock;
                *STDOUT = $new_sock;
                select STDIN; $| = 1;
                select STDOUT; $| = 1;
                $self->sock($new_sock);
		&$code($self);
            } else {
                if ($NetServer::Debug) { 
                    print STDERR $$, " : ", scalar(localtime(time)), " : ", 
                                 "rejecting unauthed connection\n"; 
                }
            }
            $NetServer::Debug && print STDERR "$0:$$: end of transaction\n";
            shutdown($new_sock, 2);
            $NetServer::Debug && print STDERR $$, " : ", 
                                              scalar(localtime(time)), " : ",
                                              "took ", tv_interval($x_time),
                                              " seconds\n";
            exit 0;
        } else {
            # parent
            $NetServer::Debug && print STDERR "$0:$$: forked $pid\n";
            if ( defined $parent_callback ) {
                 &$parent_callback($self);
            } 
        }
    }
}

sub run_client {
    my ($self) = shift ;
    $SIG{CHLD} = \&reap_child;
    
    # despatcher is a routine that dictates how often and how fast the
    # server forks and execs the test callback. The default sub (below)
    # returns immediately but is only true once, so the test is executed
    # immediately one time only. More realistic despatchers may sleep for
    # a random interval or even pre-fork themselves (for added chaos).
    my $despatcher = $self->trigger()  || 
          sub { $NetServer::Generic::default_trigger++; 
                return(($NetServer::Generic::default_trigger > 1) ? 0 : 1 );
              };

    my $code = $self->callback();      # sub to call in child process
    $self->root_pid($$);               # set server root PID
    my $triggerval = &$despatcher;
    while (($triggerval ne "") && ($triggerval ne "0")) {
        # loop, forking to create new client sessions
        my $pid = fork();
        die "Cannot fork: $!\n" unless defined ($pid);
        if ($pid == 0) {
            # child
            if ($NetServer::Debug != 0) {
                print STDERR "[$$] about to call new ",
                             "IO::Socket::INET(\n\t\t\t\t",
                             "PeerAddr => ", $self->hostname(), 
                             "\n\t\t\t\tPeerPort => ", $self->port(),
                             "\n\t\t\t\tProto     => ", $self->proto(), 
                             "\n)\n";
            }
            my ($sock) = 
                new IO::Socket::INET( PeerAddr => $self->hostname(),
                                      PeerPort => $self->port(),
                                      Proto     => $self->proto(),
                                    );
            die "Socket could not be created: $!\n" unless ($sock);
            *STDIN = $sock;
            *STDOUT = $sock;
            select STDIN; $| = 1;
            select STDOUT; $| = 1;
            &$code($self, $triggerval);
            shutdown($sock, 2);
            exit 0;
        } else {
            # in parent
            $NetServer::Debug && print STDERR "$0:$$: forked $pid\n";
            $triggerval = &$despatcher;
        }
    }
    wait; # for last child
    return;
}

sub run {
    my $self = shift;
    $NetServer::Debug && print STDERR "run() ...\n";
    if ( (! defined ($self->mode())) || (lc($self->mode()) eq "forking")) {
        $self->run_fork();
    } elsif ( lc($self->mode()) eq "select") {
        $self->run_select();
    } elsif ( lc($self->mode()) eq "select_fast") {
        $self->run_select_fast();
    } elsif ( lc($self->mode()) eq "client") {
        $self->run_client();
    } elsif ( lc($self->mode()) eq "threaded") {
        $self->run_thread();
    } elsif ( lc($self->mode()) eq "prefork") {
        $self->run_prefork();
    } else {
        my $aargh = "Unknown mode: " . $self->mode() . "\n";
        die $aargh;
    }
    return;
}

sub ok_to_serve($$) {
    # internal sub. Given a ref to a Server object, and an IO::Socket::INET,
    # see if we are allowed to serve the request. Return 1 if it's okay, 0
    # otherwise.
    my ($self, $new_sock) = @_;
    my ($junk, $peerp) = unpack_sockaddr_in($new_sock->peername());
    my ($peername) = gethostbyaddr($peerp, AF_INET);
    my ($peeraddr) = join(".", unpack("C4", $new_sock->peeraddr()));
    $self->peer([ $peername, $peeraddr]);
    $NetServer::Debug &&
        print STDERR "$0:$$: request from ", join(" ", @{$self->peer()}), "\n"; 
    return 1 if ((! defined($self->forbidden())) && 
                 (! defined($self->allowed())));
    # if we got here, forbidden or allowed are not undef, 
    # so we have to do some checking
    # Now we have the originator's hostname and IP address, we check
    # them against the allowed list and the forbidden list. 
    my ($found_allowed, $found_banned) = 0;
    if(defined ($self->allowed())) {
        ALLOWED:
        foreach (@{ $self->allowed() }) {
            next if (! defined($_));
            if (($peername =~ /^$_$/i) || ($peeraddr =~ /^$_$/i)) {
                $found_allowed++;
                $NetServer::Debug && 
                    print STDERR "allowed: $_ matched $peername or $peeraddr\n";
                last ALLOWED;
            }
        }
    }
    if(defined ($self->forbidden())) { 
        FORBIDDEN:
        foreach (@{ $self->forbidden() } ) {
            next if (! defined($_));
            if (($peername =~ /^$_$/i) || ($peeraddr =~ /^$_$/i)) {
                $found_banned++;
                $NetServer::Debug && 
                    print STDERR "forbidden: $_ matched $peername ",
                                 "or $peeraddr\n";
                last FORBIDDEN;
            }
        }
    }
    ($found_banned && ! $found_allowed) && return 0;
    ($found_allowed && ! $found_banned) && return 1;
    ($found_allowed && $found_banned)   && return 0;
    return 0;
}

#sub _new_fifo {
#    my $self = shift;
#    # create a new named pipe. Return its filename. This is used by 
#    # the preforked server for children to send information back to their
#    # parent.
#    my $fname = "/tmp/fifo.$$";
#    my $mode = 666;
#    umask(0777); # possible security hole
#    mkfifo($fname, $mode) or die "Unable to mkfifo(): $!\n";
#    return $fname;
#}
#
#sub _read_fifo { # Blocking read
#    my $self = shift;
#    # read a line from the designated fifo named $self->fifo()
#    my $handle = $self->fifo();
#    $SIG{ALRM} = sub { close FIFO };
#    open(FIFO, "<$handle") or die "Can't open $handle: $!\n";
#    alarm(1);
#    my @buffer = (<FIFO>);
#    alarm(0);
#    close FIFO;
#    return @buffer;
#}
#
#sub _write_fifo { # Non-blocking write
#    my $self = shift;
#    my @args = @_;
#    my $handle = $self->fifo();
#    $SIG{ALRM} = sub { close FIFO };
#    open(FIFO, "+>$handle")  or die "Can't open $handle: $!\n";
#    alarm(1);
#    print FIFO @_;
#    alarm(0);
#    close FIFO;
#    return; 
#}

sub quit {
    my ($self) = shift;
    $NetServer::Debug && print STDERR "called shutdown(): root_pid is ", 
                           $self->root_pid(), "\n";
    kill 15, $self->root_pid();
    exit;
}

sub AUTOLOAD {
    my ($self) = shift;
    my ($name) = $NetServer::Generic::AUTOLOAD;
    $name =~ s/.*://;
    if (@_) {
        my ($val) = shift;
        # rudimentary type checking
        my ($r) = (ref($val) || "scalar");
        if (! exists ($self->{tags}->{$name})) {
            warn "\tno such method: $name\n";
            return undef;
        }
        if ($r !~ /$self->{tags}->{$name}/i) {
            warn "\t", ref($val), ": expecting a ", $self->{tags}->{$name}, "\n", "\tgot [", join("][", @_), "]\n";
            return undef;
        }
        return $self->{$name} = $val;
    } else {
        return $self->{$name};
    }
}


1;

